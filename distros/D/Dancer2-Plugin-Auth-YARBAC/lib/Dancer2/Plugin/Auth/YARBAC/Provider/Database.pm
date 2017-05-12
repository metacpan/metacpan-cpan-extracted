package Dancer2::Plugin::Auth::YARBAC::Provider::Database;

use strict;
use warnings;

use Moo;
use namespace::clean;
use Dancer2;
use Dancer2::Plugin::Database;
use Carp;
use Try::Tiny;
use Data::Dumper;

extends 'Dancer2::Plugin::Auth::YARBAC::Provider::Base';

our $VERSION = '0.011';

has users_table        => ( is => 'ro', default => \&_users_table, lazy => 1 );
has id_column          => ( is => 'ro', default => \&_id_column, lazy => 1 );
has username_column    => ( is => 'ro', default => \&_username_column, lazy => 1 );
has password_column    => ( is => 'ro', default => \&_password_column, lazy => 1 );
has db_connection_name => ( is => 'ro', default => \&_db_connection_name, lazy => 1 );

sub _users_table
{
    my $self = shift;

    return ( defined $self->settings->{users_table} )
           ? $self->settings->{users_table}
           : 'users';
}

sub _id_column
{
    my $self = shift;

    return ( defined $self->settings->{users_id_column} )
           ? $self->settings->{users_id_column}
           : 'id';
}

sub _username_column
{
    my $self = shift;

    return ( defined $self->settings->{users_username_column} )
           ? $self->settings->{users_username_column}
           : 'username';
}

sub _password_column
{
    my $self = shift;

    return ( defined $self->settings->{users_password_column} )
           ? $self->settings->{users_password_column}
           : 'password';
}

sub _db_connection_name
{
    my $self = shift;

    # undef will mean it'll try the default connection
    return ( defined $self->settings->{db_connection_name} )
           ? $self->settings->{db_connection_name}
           : undef;
}

sub db
{
    my $self = shift;
    my $db;

    try
    {
        $db = database( $self->db_connection_name );
    }
    catch
    {
        croak "Database connection failed: $_";
    };

    return $db;
}

sub authenticate_user
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{username} || ! defined $params->{password} );

    my $user = $self->retrieve_user( $params );

    return $self->validate_password( { hash => $user->{password}, password => $params->{password} } );
}

sub retrieve_user
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{username} );

    my $user = $self->db->quick_select( $self->users_table, { $self->username_column => $params->{username} } );

    if ( defined $opts->{expand} && defined $user->{ $self->id_column } )
    {
        my $roles  = $self->user_roles( { username => $user->{ $self->username_column } } );
        my $groups = $self->user_groups( { username => $user->{ $self->username_column } } );

        my @user_roles;
        my @user_groups;

        for my $group ( @{ $groups } )
        {
            my $permissions = $self->group_permissions( { group_name => $group->{group_name} } ); 
            $group->{permissions} = $permissions;
            push ( @user_groups, $group );
        }

        for my $role ( @{ $roles } )
        {
            my @role_groups;

            for my $group ( @user_groups )
            {
                my $check = $self->role_has_group( { role_name => $role->{role_name}, group_name => $group->{group_name} } );

                if ( $check && $role->{id} )
                {
                    push( @role_groups, $group ); 
                }
            }

            $role->{groups} = \@role_groups;

            push ( @user_roles, $role );
        }

        $user->{yarbac}->{roles} = \@user_roles;

        return $user;
    }
    else
    {
        return $user;
    }
}

sub retrieve_role
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{role_name} );

    return $self->db->quick_select( 'yarbac_roles', { role_name => $params->{role_name} } );
}

sub retrieve_group
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{group_name} );

    return $self->db->quick_select( 'yarbac_groups', { group_name => $params->{group_name} } );
}

sub retrieve_permission
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{permission_name} );

    return $self->db->quick_select( 'yarbac_permissions', { permission_name => $params->{permission_name} } );
}

sub user_roles
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{username} );

    my $user    = $self->retrieve_user( $params );
    my $user_id = $user->{ $self->id_column };

    return if ( ! defined $user_id );

    my $sql  = 'SELECT yarbac_roles.id, yarbac_roles.role_name, yarbac_roles.description '
               . 'FROM yarbac_user_roles JOIN yarbac_roles ON yarbac_roles.id = '
               . 'yarbac_user_roles.role_id WHERE yarbac_user_roles.user_id = ?';
    my $sth  = $self->db->prepare( $sql );
    my @roles;

    $sth->execute( $user_id );

    while ( my $role = $sth->fetchrow_hashref )
    {
        push ( @roles, $role );
    }

    return \@roles;
}

sub user_groups
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{username} );

    my $user    = $self->retrieve_user( $params );
    my $user_id = $user->{ $self->id_column };

    return if ( ! defined $user_id );
 
    my $roles = $self->user_roles( $params );
    my @groups;

    for my $role ( @{ $roles } )
    {
        next if ( ! defined $role->{id} );

        my $sql  = 'SELECT yarbac_groups.id, yarbac_groups.group_name, yarbac_groups.description '
                   . 'FROM yarbac_role_groups JOIN yarbac_groups ON yarbac_groups.id = '
                   . 'yarbac_role_groups.group_id WHERE yarbac_role_groups.role_id = ?';
        my $sth  = $self->db->prepare( $sql );

        $sth->execute( $role->{id} );

        while ( my $group = $sth->fetchrow_hashref )
        {
            push ( @groups, $group );
        }
    }

    return \@groups;
}

sub user_has_role
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{username} || ! defined $params->{role_name} );

    my $roles = $self->user_roles( $params );

    for my $role ( @{ $roles } )
    {
        if ( defined $role->{role_name} && $params->{role_name} eq $role->{role_name} )
        {
            return 1;
        }
    }

    return;
}

sub user_has_any_role
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{username} || ! defined $params->{role_names} || ! ( ref( $params->{role_names} ) eq 'ARRAY' ) );

    my $roles = $self->user_roles( $params );

    for my $role ( @{ $roles } )
    {
        map { return 1 if ( $_ eq $role->{role_name} ) } @{ $params->{role_names} };
    }

    return;
}

sub user_has_all_roles
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{username} || ! defined $params->{role_names} || ! ( ref( $params->{role_names} ) eq 'ARRAY' ) );

    my $roles             = $self->user_roles( $params );
    my $user_role_count   = @{ $roles };
    my $params_role_count = @{ $params->{role_names} };
    my $user_role_match   = 0;

    return if ( ! $user_role_count );

    for my $role ( @{ $roles } )
    {
        map { $user_role_match++ if ( $_ eq $role->{role_name} ); } @{ $params->{role_names} };
    }

    return ( $params_role_count == $user_role_match ) ? 1 : 0;
}

sub user_has_group
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{username} || ! defined $params->{group_name} );

    my $groups = $self->user_groups( $params );

    for my $group ( @{ $groups } )
    {
        if ( $params->{group_name} eq $group->{group_name} )
        {
            return 1;
        }
    }

    return;
}

sub user_has_any_group
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{username} || ! defined $params->{group_names} || ! ( ref( $params->{group_names} ) eq 'ARRAY' ) );

    my $groups = $self->user_groups( $params );

    for my $group ( @{ $groups } )
    {
        map { return 1 if ( $_ eq $group->{group_name} ) } @{ $params->{group_names} };
    }

    return;
}

sub user_has_all_groups
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{username} || ! defined $params->{group_names} || ! ( ref( $params->{group_names} ) eq 'ARRAY' ) );

    my $groups             = $self->user_groups( $params );
    my $user_group_count   = @{ $groups };
    my $params_group_count = @{ $params->{group_names} };
    my $user_group_match   = 0;

    return if ( ! $user_group_count );

    for my $group ( @{ $groups } )
    {
        map { $user_group_match++ if ( $_ eq $group->{group_name} ); } @{ $params->{group_names} };
    }

    return ( $params_group_count == $user_group_match ) ? 1 : 0;
}

sub user_has_group_permission
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{username} || ! defined $params->{group_name} || ! defined $params->{permission_name} );

    my $has_group = $self->user_has_group( $params );

    if ( $has_group )
    {
        return $self->group_has_permission( $params );
    }

    return;
}

sub user_has_group_with_any_permission
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{username} || ! defined $params->{group_name} || ! defined $params->{permission_names} || ! ( ref( $params->{permission_names} ) eq 'ARRAY' ) );

    for my $permission_name ( @{ $params->{permission_names} } )
    {
        if ( $self->group_has_permission( { group_name => $params->{group_name}, permission_name => $permission_name } ) )
        {
            return 1;
        }
    }

    return;
}

sub user_has_group_with_all_permissions
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{username} || ! defined $params->{group_name} || ! defined $params->{permission_names} || ! ( ref( $params->{permission_names} ) eq 'ARRAY' ) );

    my $params_permission_count = @{ $params->{permission_names} };
    my $user_permission_match   = 0;

    for my $permission_name ( @{ $params->{permission_names} } )
    {
        if ( $self->group_has_permission( { group_name => $params->{group_name}, permission_name => $permission_name } ) )
        {
            $user_permission_match++;
        }
    }

    return ( $params_permission_count == $user_permission_match ) ? 1 : 0;
}

sub role_has_group
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{role_name} || ! defined $params->{group_name} );

    my $role  = $self->retrieve_role( $params );
    my $group = $self->retrieve_group( $params );

    return $self->db->quick_count( 'yarbac_role_groups', { role_id => $role->{id}, group_id => $group->{id} } );
}

sub role_groups
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{role_name} );

    my $role  = $self->retrieve_role( $params );
    my @groups;

    return if ( ! defined $role->{id} );

    my $sql  = 'SELECT yarbac_groups.id, yarbac_groups.group_name, yarbac_groups.description '
               . 'FROM yarbac_role_groups JOIN yarbac_groups ON yarbac_groups.id = '
               . 'yarbac_role_groups.group_id WHERE yarbac_role_groups.role_id = ?';
    my $sth  = $self->db->prepare( $sql );

    $sth->execute( $role->{id} );

    while ( my $group = $sth->fetchrow_hashref )
    {
        push ( @groups, $group );
    }

    return \@groups;
}

sub group_permissions
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{group_name} );

    my $group = $self->retrieve_group( $params );

    return if ( ! defined $group->{id} );

    my $sql   = 'SELECT yarbac_permissions.id, yarbac_permissions.permission_name, yarbac_permissions.description '
                . 'FROM yarbac_permissions JOIN yarbac_group_permissions ON yarbac_permissions.id = '
                . 'yarbac_group_permissions.permission_id WHERE yarbac_group_permissions.group_id = ?';
    my $sth  = $self->db->prepare( $sql );

    $sth->execute( $group->{id} );

    my @permissions;

    while ( my $permission = $sth->fetchrow_hashref )
    {
        push ( @permissions, $permission );
    }

    return \@permissions;
}

sub group_has_permission
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{group_name} || ! defined $params->{permission_name} );

    my $group_permissions = $self->group_permissions( $params );

    for my $group_permission ( @{ $group_permissions } )
    {
        if ( $params->{permission_name} eq $group_permission->{permission_name} )
        {
            return 1;
        }
    }

    return;
}

sub create_user
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! $params->{username} || ! $params->{password} );

    $params = $self->_sanitize_user_params( $params );

    $params->{ $self->password_column } = $self->generate_hash( { password => $params->{ $self->password_column } } );

    return $self->db->quick_insert( $self->users_table, $params );
}

sub create_role
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{role_name} );

    my $role = $self->retrieve_role( $params );

    if ( ! defined $role->{id} )
    {
        if ( defined $params->{description} )
        {
            $self->db->quick_insert( 'yarbac_roles', { role_name => $params->{role_name}, description => $params->{description} } );
        }
        else
        {
            $self->db->quick_insert( 'yarbac_roles', { role_name => $params->{role_name} } );
        }

        return 1;
    }

    $self->dsl->debug( 'YARBAC ========> Looks like that role name already exists.' );

    return;
}

sub create_group
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{group_name} );

    my $group = $self->retrieve_group( $params );

    if ( ! defined $group->{id} )
    {
        if ( defined $params->{description} )
        {
            $self->db->quick_insert( 'yarbac_groups', { group_name => $params->{group_name}, description => $params->{description} } );
        }
        else
        {
            $self->db->quick_insert( 'yarbac_groups', { group_name => $params->{group_name} } );
        }

        return 1;
    }

    $self->dsl->debug( 'YARBAC ========> Looks like that group name already exists.' );

    return;
}

sub create_permission
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{permission_name} );

    my $permission = $self->retrieve_permission( $params );

    if ( ! defined $permission->{id} )
    {
        if ( defined $params->{description} )
        {
            $self->db->quick_insert( 'yarbac_permissions', { permission_name => $params->{permission_name}, description => $params->{description} } );
        }
        else
        {
            $self->db->quick_insert( 'yarbac_permissions', { permission_name => $params->{permission_name} } );
        }

        return 1;
    }

    $self->dsl->debug( 'YARBAC ========> Looks like that permission name already exists.' );

    return;
}

sub assign_user_role
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{username} || ! defined $params->{role_name} );

    my $user    = $self->retrieve_user( $params );
    my $role    = $self->retrieve_role( $params );
    my $user_id = $user->{ $self->id_column };

    if ( defined $user_id && defined $role->{id} )
    {
        my $check = $self->db->quick_select( 'yarbac_user_roles', { user_id => $user_id, role_id => $role->{id} } );
        
        if ( ! defined $check->{user_id} )
        {
            $self->db->quick_insert( 'yarbac_user_roles', { user_id => $user_id, role_id => $role->{id} } );
        }

        return 1;
    }

    $self->dsl->debug( 'YARBAC ========> Looks like either the user or the role does not exist.' );

    return;
}

sub assign_role_group
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{role_name} || ! defined $params->{group_name} );

    my $role  = $self->retrieve_role( $params );
    my $group = $self->retrieve_group( $params );

    if ( defined $role->{id} && defined $group->{id} )
    {
        my $check = $self->db->quick_select( 'yarbac_role_groups', { role_id => $role->{id}, group_id => $group->{id} } );

        if ( ! defined $check->{role_id} )
        {
            $self->db->quick_insert( 'yarbac_role_groups', { role_id => $role->{id}, group_id => $group->{id} } );
        }

        return 1;
    }

    $self->dsl->debug( 'YARBAC ========> Looks like either the role or the group does not exist.' );

    return;
}

sub assign_group_permission
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{group_name} || ! defined $params->{permission_name} );

    my $group      = $self->retrieve_group( $params );
    my $permission = $self->retrieve_permission( $params );

    if ( defined $group->{id} && defined $permission->{id} )
    {
        my $check = $self->db->quick_select( 'yarbac_group_permissions', { group_id => $group->{id}, permission_id => $permission->{id} } );

        if ( ! defined $check->{group_id} )
        {
            $self->db->quick_insert( 'yarbac_group_permissions', { group_id => $group->{id}, permission_id => $permission->{id} } );
        }

        return 1;
    }

    $self->dsl->debug( 'YARBAC ========> Looks like either the group or the permission does not exist.' );

    return;
}

sub revoke_user_role
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{username} || ! defined $params->{role_name} );

    my $user    = $self->retrieve_user( $params );
    my $role    = $self->retrieve_role( $params );
    my $user_id = $user->{ $self->id_column };

    if ( defined $user_id && $role->{id} )
    {
        $self->db->quick_delete( 'yarbac_user_roles', { user_id => $user_id, role_id => $role->{id} } );

        return 1;
    }

    $self->dsl->debug( 'YARBAC ========> Looks like either the user or the role does not exist.' );

    return;
}

sub revoke_role_group
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{role_name} || ! defined $params->{group_name} );

    my $role  = $self->retrieve_role( $params );
    my $group = $self->retrieve_group( $params );

    if ( defined $role->{id} && defined $group->{id} )
    {
        $self->db->quick_delete( 'yarbac_role_groups', { role_id => $role->{id}, group_id => $group->{id} } );

        return 1;
    }

    $self->dsl->debug( 'YARBAC ========> Looks like either the role or the group does not exist.' );

    return;
}

sub revoke_group_permission
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{group_name} || ! defined $params->{permission_name} );

    my $group      = $self->retrieve_group( $params );
    my $permission = $self->retrieve_permission( $params );

    if ( defined $group->{id} && defined $permission->{id} )
    {
        $self->db->quick_delete( 'yarbac_group_permissions', { group_id => $group->{id}, permission_id => $permission->{id} } );

        return 1;
    }

    $self->dsl->debug( 'YARBAC ========> Looks like either the group or the permission does not exist.' );

    return;
}

sub modify_user
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $opts->{id} && ! defined $opts->{username} );

    $params = $self->_sanitize_user_params( $params );

    if ( defined $params->{password} )
    {
        my $pw_clear = $params->{password};

        delete $params->{password};
        $params->{ $self->password_column } = $self->generate_hash( { password => $pw_clear } );
    }

    if ( defined $opts->{id} )
    {
        return $self->db->quick_update( $self->users_table, { $self->id_column => $opts->{id} }, $params );
    }
    else
    {
        return $self->db->quick_update( $self->users_table, { $self->username_column => $opts->{username} }, $params );
    }
}

sub modify_role
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $opts->{id} && ! defined $opts->{role_name} );

    my $modified = 0;
    my $update   = ( defined $opts->{id} ) ? { id => $opts->{id} } : { role_name => $opts->{role_name} };

    if ( defined $params->{role_name} && ! defined $params->{description} )
    {
        $self->db->quick_update( 'yarbac_roles', $update, { role_name => $params->{role_name} } );
        $modified++;
    }

    if ( defined $params->{description} && ! defined $params->{role_name} )
    {
        $self->db->quick_update( 'yarbac_roles', $update, { description => $params->{description} } );
        $modified++;
    }

    if ( defined $params->{role_name} && defined $params->{description} )
    {
        $self->db->quick_update( 'yarbac_roles', $update, { role_name => $params->{role_name}, description => $params->{description} } );
        $modified++;
    }

    return ( $modified ) ? 1 : 0;
}

sub modify_group
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $opts->{id} && ! defined $opts->{group_name} );

    my $modified = 0;
    my $update   = ( defined $opts->{id} ) ? { id => $opts->{id} } : { group_name => $opts->{group_name} };

    if ( defined $params->{group_name} && ! defined $params->{description} )
    {
        $self->db->quick_update( 'yarbac_groups', $update, { group_name => $params->{group_name} } );
        $modified++;
    }

    if ( defined $params->{description} && ! defined $params->{group_name} )
    {
        $self->db->quick_update( 'yarbac_groups', $update, { description => $params->{description} } );
        $modified++;
    }

    if ( defined $params->{group_name} && defined $params->{description} )
    {
        $self->db->quick_update( 'yarbac_groups', $update, { group_name => $params->{group_name}, description => $params->{description} } );
        $modified++;
    }

    return ( $modified ) ? 1 : 0;
}

sub modify_permission
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $opts->{id} && ! defined $opts->{permission_name} );

    my $modified = 0;
    my $update   = ( defined $opts->{id} ) ? { id => $opts->{id} } : { permission_name => $opts->{permission_name} };

    if ( defined $params->{permission_name} && ! defined $params->{description} )
    {
        $self->db->quick_update( 'yarbac_permissions', $update, { permission_name => $params->{permission_name} } );
        $modified++;
    }

    if ( defined $params->{description} && ! defined $params->{permission_name} )
    {
        $self->db->quick_update( 'yarbac_permissions', $update, { description => $params->{description} } );
        $modified++;
    }

    if ( defined $params->{permission_name} && defined $params->{description} )
    {
        $self->db->quick_update( 'yarbac_permissions', $update, { permission_name => $params->{permission_name}, description => $params->{description} } );
        $modified++;
    }
   
    return ( $modified ) ? 1 : 0;
}

sub delete_user
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{username} );

    my $user  = $self->retrieve_user( $params );
    my $roles = $self->user_roles( $params );

    for my $role ( @{ $roles } )
    {
        $self->revoke_user_role( { username => $params->{username}, role_name => $role->{role_name} } );
    }

    return $self->db->quick_delete( $self->users_table, { $self->username_column => $params->{username} } );
}

sub delete_role
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{role_name} );

    my $role = $self->retrieve_role( $params );

    if ( defined $role->{id} )
    {
        $self->db->quick_delete( 'yarbac_role_groups', { role_id => $role->{id} } );
        $self->db->quick_delete( 'yarbac_user_roles', { role_id => $role->{id} } );
        $self->db->quick_delete( 'yarbac_roles', { id => $role->{id} } );
    }

    return 1;
}

sub delete_group
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{group_name} );

    my $group = $self->retrieve_group( $params );

    if ( defined $group->{id} )
    {
        $self->db->quick_delete( 'yarbac_group_permissions', { group_id => $group->{id} } );
        $self->db->quick_delete( 'yarbac_role_groups', { group_id => $group->{id} } );
        $self->db->quick_delete( 'yarbac_groups', { id => $group->{id} } );
    }

    return 1;
}

sub delete_permission
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{permission_name} );

    my $permission = $self->retrieve_permission( $params );

    if ( defined $permission->{id} )
    {
        $self->db->quick_delete( 'yarbac_group_permissions', { permission_id => $permission->{id} } );
        $self->db->quick_delete( 'yarbac_permissions', { id => $permission->{id} } );
    }

    return 1;
}

sub _sanitize_user_params
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    if ( defined $params->{id} && defined $params->{ $self->id_column } && $self->id_column ne 'id' )
    {
        $params->{ $self->id_column } = $params->{id};
        delete $params->{id};
    }

    if ( defined $params->{username} && defined $params->{ $self->username_column } && $self->username_column ne 'username' )
    {
        $params->{ $self->username_column } = $params->{username};
        delete $params->{username};
    }

    if ( defined $params->{password} && defined $params->{ $self->password_column } && $self->password_column ne 'password' )
    {
        $params->{ $self->password_column } = $params->{password};
        delete $params->{password};
    }

    my $sql = 'SELECT * FROM users LIMIT 0';
    my $sth = $self->db->prepare( $sql );

    $sth->execute();

    my $columns = $sth->{'NAME'};

    for my $key ( keys %{ $params } )
    {
        my $match = 0;

        map { $match = 1 if ( $key eq $_ ) } ( @{ $columns } );

        if ( ! $match )
        {
            delete $params->{ $key };
        }
    }

    return $params;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::Auth::YARBAC::Provider::Database - Yet Another Role Based Access Control Framework

=head1 VERSION

version 0.011

=head1 SYNOPSIS

Configure the plugin to use the Database provider class:

  plugins:
  Auth::YARBAC:
    # Set redirect page after user logs out
    after_logout: '/login'
    # Set default redirect page after user logs in
    after_login: '/'
    # Set default redirect page if user fails login attempt
    login_denied: '/login'
    # Specify URL's that do not require authentication
    no_login_required: '^/login|/denied|/css|/images|/generate_hash'
    # Set your realms, one realm is required but you can have many
    realms:
      # Realm name
      test:
        # Our backend provider
        provider: 'Database'
        # Set the users table name (required by Database, default: users)
        users_table: 'users'
        # Set the users id column name (required by Database, default: id)
        users_id_column: 'id'
        # Set the users username column name (Database, default: username)
        users_username_column: 'username'
        # Set the users username column name (Database, default: password)
        users_password_column: 'password'
        # Password strength options optionally allows a check password strength
        password_strength:
           # Set the required minimum password score
          required_score: 25
          # Set minimum password length
          min_length: 6
          # Set maximum password length (good idea to avoid DDOS attacks)
          max_length: 32
          # If true, password must contain special characters
          special_characters: 1
          # If true, password must contain control characters
          control_characters: 1
          # If true, password must not be a repeating character
          no_repeating: 1
          # If true, password must contain a uppercase character
          upper_case: 1
          # If true, password must contain a lowercase character
          lower_case: 1
          # If true, password must contain a number
          numbers: 1

Next, setup your database tables.

This backend provider requires that your app is configured to 
use L<Dancer2::Plugin::Database>.
This provider is flexible with the naming convention
of your users table. In your apps config settings you
can set your users table name with the 'users_table' option
but the default expected is 'users'.
You can set your user 'id' column name with the
'users_id_column' option but the default expected is 'id'. 
You can set your user 'username' column name with the
'users_username_column' config option but the default
expected is 'username'. You can set your 'password' 
column name with the 'users_password_column' config 
option but the default expected is 'password'. 
However this provider inists on the other
table names to be named as displayed in this
documentation. All static table names are prefixed 
with 'yarbac_' in order to stay out of your way.

=over

=item SQLITE EXAMPLE SCHEMA

  CREATE TABLE users (
    id       INTEGER     PRIMARY KEY,
    username VARCHAR(32) NOT NULL UNIQUE,
    password TEXT NOT NULL
  );
    
  CREATE TABLE yarbac_roles (
    id   INTEGER     PRIMARY KEY,
    role_name VARCHAR(32) NOT NULL UNIQUE,
    description TEXT NULL
  );
    
  CREATE TABLE yarbac_groups (
    id   INTEGER     PRIMARY KEY,
    group_name VARCHAR(32) NOT NULL UNIQUE,
    description TEXT NULL
  );
    
  CREATE TABLE yarbac_permissions (
    id   INTEGER     PRIMARY KEY,
    permission_name VARCHAR(32) NOT NULL UNIQUE,
    description TEXT NULL
  );
    
  CREATE TABLE yarbac_user_roles (
    user_id  INTEGER  NOT NULL,
    role_id  INTEGER  NOT NULL
  );
  CREATE UNIQUE INDEX user_role on yarbac_user_roles (user_id, role_id);
    
  CREATE TABLE yarbac_role_groups (
    role_id  INTEGER  NOT NULL,
    group_id INTEGER  NOT NULL
  );
  CREATE UNIQUE INDEX group_role on yarbac_role_groups (role_id, group_id);
    
  CREATE TABLE yarbac_group_permissions (
    group_id      INTEGER  NOT NULL,
    permission_id INTEGER  NOT NULL
  );
  CREATE UNIQUE INDEX group_permissions on yarbac_group_permissions (group_id, permission_id);

=item MYSQL EXAMPLE SCHEMA

  CREATE TABLE users (
    id       INTEGER AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(32) NOT NULL UNIQUE KEY,
    password TEXT NOT NULL
  );
   
  CREATE TABLE yarbac_roles (
    id   INTEGER AUTO_INCREMENT PRIMARY KEY,
    role_name    VARCHAR(32) NOT NULL UNIQUE KEY,
    description TEXT NULL
  );
     
  CREATE TABLE yarbac_groups (
    id   INTEGER AUTO_INCREMENT PRIMARY KEY,
    group_name   VARCHAR(32) NOT NULL UNIQUE KEY,
    description TEXT NULL
  );
     
  CREATE TABLE yarbac_permissions (
    id   INTEGER    AUTO_INCREMENT PRIMARY KEY,
    permission_name VARCHAR(32) NOT NULL UNIQUE KEY,
    description TEXT NULL
  );
    
  CREATE TABLE yarbac_user_roles (
    user_id  INTEGER NOT NULL,
    role_id  INTEGER NOT NULL,
    UNIQUE KEY user_role (user_id, role_id)
  );
    
  CREATE TABLE yarbac_role_groups (
    role_id  INTEGER NOT NULL,
    group_id INTEGER NOT NULL,
    UNIQUE KEY group_role (role_id, group_id)
  );
     
  CREATE TABLE yarbac_group_permissions (
    group_id      INTEGER NOT NULL,
    permission_id INTEGER NOT NULL,
    UNIQUE KEY group_permissions (group_id, permission_id)
  );

=back

=head1 DESCRIPTION

This module is the base provier for the YARBAC framework.
See L<Dancer2::Plugin::Auth::YARBAC> for full documentation
showing the usage of this backend provider.

=head1 AUTHOR

Sarah Fuller <sarah@averna.id.au>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Sarah Fuller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Yet Another Role Based Access Control Framework

