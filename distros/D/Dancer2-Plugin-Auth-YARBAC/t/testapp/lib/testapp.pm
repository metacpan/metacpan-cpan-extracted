package testapp;

use Dancer2;
use Dancer2::Session::Cookie;
use Dancer2::Plugin::Database;
use Dancer2::Plugin::Auth::YARBAC;
use Template;
use DBD::SQLite;
use Data::Dumper;

our $VERSION = '0.1';

hook before => hook_before_require_login sub
{

};

get '/' => sub 
{
    my $logged_in_user = Dumper ( logged_in_user );

    template 'index', { logged_in_user => $logged_in_user };
};

get '/login' => sub
{
    template 'login';
};

get '/auth/user' => sub
{
    return Dumper( authenticate_user( { username => params->{username}, password => params->{password} }, { realm => params->{realm} } ) );
};

post '/login' => sub
{
    return login( { username => params->{username}, password => params->{password} }, { realm => params->{realm} } );
};

get '/password_strength' => require_login sub
{
    template 'password_strength', {};
};

post '/password_strength' => sub
{
    my $strength = Dumper ( password_strength( { password => params->{password} } ) );

    template 'password_strength', { password_strength => $strength }; 
};

get '/generate_hash' => sub
{
    my $hash = generate_hash( { password => params->{password} }, { realm => 'test' } );

    template 'hash', { hash => $hash };
};

get '/user' => sub
{
    my $user = Dumper ( retrieve_user( { username => params->{username} }, { expand => 1 } ) );

    template 'user', { user => $user };
};

get '/role' => sub
{
    my $role = Dumper ( retrieve_role( { role_name => params->{role} } ) );

    return $role;
};

get '/group' => sub
{
    my $group = Dumper ( retrieve_group( { group_name => params->{group} } ) );

    return $group;
};

get '/role/groups' => sub
{
    my $groups = Dumper ( role_groups( { role_name => params->{role} } ) );

    return $groups;
};

get '/group/permissions' => sub
{
    my $permissions = Dumper ( group_permissions( { group_name => params->{group} } ) );

    return $permissions;
};

get '/permission' => sub
{
    my $permission = Dumper ( retrieve_permission( { permission_name => params->{permission} } ) );

    return $permission;
};

get '/user/roles' => sub
{
    my $role = Dumper ( user_roles( { username => params->{username} } ) );

    template 'role', { role => $role }; 
};

get '/user/groups' => sub
{
    my $groups = Dumper ( user_groups( { username => params->{username} } ) );

    template 'groups', { groups => $groups };
};

get '/user/has/role' => sub
{
    my $has_role = user_has_role( { role_name => params->{role}, username => params->{username} } );

    return ( $has_role ) ? 'yes' : 'no';
};

get '/user/has/group' => sub
{
    my $has_group = user_has_group( { group_name => params->{group}, username => params->{username} } );

    return ( $has_group ) ? 'yes' : 'no';
};

get '/user/has/any/role' => sub
{
    my @roles     = qw(admin dummy nope);
    my $has_roles = user_has_any_role( { role_names => \@roles, username => params->{username} } );

    return ( $has_roles ) ? 'yes' : 'no';
};

get '/user/has/all/roles' => sub
{
    my @roles     = qw(admin dummy);
    my $has_roles = user_has_all_roles( { role_names => \@roles, username => params->{username} } );

    return ( $has_roles ) ? 'yes' : 'no';
};

get '/user/has/any/group' => sub
{
    my @groups     = qw(nope no cs);
    my $has_groups = user_has_any_group( { group_names => \@groups, username => params->{username} } );

    return ( $has_groups ) ? 'yes' : 'no';
};

get '/user/has/all/groups' => sub
{
    my @groups     = qw(cs ops devops);
    my $has_groups = user_has_all_groups( { group_names => \@groups, username => params->{username} } );

    return ( $has_groups ) ? 'yes' : 'no';
};

get '/user/has/group/permission' => sub
{
    my $has_group_permission = user_has_group_permission( { group_name => params->{group}, permission_name => params->{permission} } );

    return ( $has_group_permission ) ? 'yes' : 'no';
};

get '/user/has/group/with/any/permission' => sub
{
    my $perms = [ 'no', 'read' ];
    my $has_group_permission = user_has_group_with_any_permission( { group_name => 'cs', permission_names => $perms } );

    ( $has_group_permission ) ? 'yes' : 'no';
};

get '/user/has/group/with/all/permissions' => sub
{
    my $perms                 = [ 'read' ];
    my $has_group_permissions = user_has_group_with_all_permissions( { group_name => 'cs', permission_names => $perms } );

    ( $has_group_permissions ) ? 'yes' : 'no';
};

get '/role/has/group' => sub
{
    my $has_group = role_has_group( { role_name => params->{role}, group_name => params->{group} } );

    return ( $has_group ) ? 'yes' : 'no';
};

get '/group/has/permission' => sub
{
    my $has_permission = group_has_permission( { group_name => params->{group}, permission_name => params->{permission} } );

    return ( $has_permission ) ? 'yes' : 'no';
};

get '/create/user' => sub
{
    my $create = create_user( { username => params->{username}, password => params->{password} }, { realm => 'test' } );

    return ( $create ) ? 'yes' : 'no';
};

get '/create/role' => sub
{
    my $create = create_role( { role_name => params->{role}, description => params->{description} } );

    return ( $create ) ? 'yes' : 'no';
};

get '/create/group' => sub
{
    my $create = create_group( { group_name => params->{group}, description => params->{description} } );

    return ( $create ) ? 'yes' : 'no';
};

get '/create/permission' => sub
{
    my $create = create_permission( { permission_name => params->{permission}, description => params->{description} } );

    return ( $create ) ? 'yes' : 'no';
};

get '/assign/user/role' => sub
{
    my $assign = assign_user_role( { username => params->{username}, role_name => params->{role} } );

    return ( $assign ) ? 'yes' : 'no';
};

get '/assign/role/group' => sub
{
    my $assign = assign_role_group( { role_name => params->{role}, group_name => params->{group} } );

    return ( $assign ) ? 'yes' : 'no';
};

get '/assign/group/permission' => sub
{
    my $assign = assign_group_permission( { group_name => params->{group}, permission_name => params->{permission} } );

    return ( $assign ) ? 'yes' : 'no';
};

get '/revoke/user/role' => sub
{
    my $revoke = revoke_user_role( { username => params->{username}, role_name => params->{role} } );

    return ( $revoke ) ? 'yes' : 'no';
};

get '/revoke/role/group' => sub
{
    my $revoke = revoke_role_group( { role_name => params->{role}, group_name => params->{group} } );

    return ( $revoke ) ? 'yes' : 'no';
};

get '/revoke/group/permission' => sub
{
    my $revoke = revoke_group_permission( { group_name => params->{group}, permission_name => params->{permission} } );

    return ( $revoke ) ? 'yes' : 'no';
};

get '/modify/user' => sub
{
    my $modify = modify_user( { username => params->{username}, password => params->{password} }, {  id => params->{id} } );

    return ( $modify ) ? 'yes' : 'no';
};

get '/modify/role' => sub
{
    my $modify = modify_role( { role_name => params->{role}, description => params->{description} }, { id => params->{id} } );

    return ( $modify ) ? 'yes' : 'no';
};

get '/modify/group' => sub
{
    my $modify = modify_group( { group_name => params->{group}, description => params->{description} }, { id => params->{id} } );

    return ( $modify ) ? 'yes' : 'no';
};

get '/modify/permission' => sub
{
    my $modify = modify_permission( { permission_name => params->{permission}, description => params->{description} }, { id => params->{id} } );

    return ( $modify ) ? 'yes' : 'no';
};

get '/delete/user' => sub
{
    my $delete = delete_user( { username => params->{username} } );

    return ( $delete ) ? 'yes' : 'no';
};

get '/delete/role' => sub
{
    my $delete = delete_role( { role_name => params->{role} } );

    return ( $delete ) ? 'yes' : 'no';
};

get '/delete/group' => sub
{
    my $delete = delete_group( { group_name => params->{group} } );

    return ( $delete ) ? 'yes' : 'no';
};

get '/delete/permission' => sub
{
    my $delete = delete_permission( { permission_name => params->{permission} } );

    return ( $delete ) ? 'yes' : 'no';
};

get '/provider' => sub
{
    my $provider = provider();

    return Dumper $provider;
};

get '/logout' => sub 
{ 
    return logout;
};

get '/denied' => sub
{
    return '<h1>DENIED</h1>';
};

true;
