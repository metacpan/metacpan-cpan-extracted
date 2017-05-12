package Dancer::Plugin::Auth::Extensible::Provider::DBIC;
BEGIN {
  $Dancer::Plugin::Auth::Extensible::Provider::DBIC::AUTHORITY = 'cpan:YANICK';
}
{
  $Dancer::Plugin::Auth::Extensible::Provider::DBIC::VERSION = '0.1.3';
}
# ABSTRACT: authenticate via DBIx::Class

use strict;
use base 'Dancer::Plugin::Auth::Extensible::Provider::Base';
use Dancer::Plugin::DBIC;
use Dancer qw(:syntax);




sub authenticate_user {
    my ($self, $username, $password) = @_;

    # Look up the user:
    my $user = $self->get_user_details($username) or return;

    return $self->match_password($password, $user);
}

sub match_password {
    my( $self, $password, $user ) = @_;

    my $settings = $self->realm_settings;
    my $password_check = $settings->{password_check}  || 'check_password';

    return $user->$password_check( $password );
}


# Return details about the user.  The user's row in the users table will be
# fetched and all columns returned as a hashref.
sub get_user_details {
    my ($self, $username) = @_;

    return unless defined $username;

    my $settings = $self->realm_settings;

    # Get our database handle and find out the table and column names:
    my $database = schema($settings->{db_connection_name})
        or die "No database connection";

    my $users_table     = $settings->{users_resultset} || 'User';
    my $username_column = $settings->{username_column} || 'username';

    # Look up the user, 
    my $user = $database->resultset($users_table)->find({
            $username_column => $username
    }) or debug("No such user $username");

    return $user;
}

sub get_user_roles {
    my ($self, $username) = @_;

    my $settings = $self->realm_settings;

    # Get details of the user first; both to check they exist, and so we have
    # their ID to use.
    my $user = $self->get_user_details($username)
        or return;

    my $roles = $settings->{roles_relationship} || 'roles';
    my $role_column = $settings->{role_column} || 'role';

    return [ $user->$roles->get_column( $role_column )->all ];
}

1;

__END__

=pod

=head1 NAME

Dancer::Plugin::Auth::Extensible::Provider::DBIC - authenticate via DBIx::Class

=head1 VERSION

version 0.1.3

=head1 DESCRIPTION

This class is an authentication provider designed to authenticate users against
a database using L<Dancer::Plugin::DBIC> within the
L<Dancer::Plugin::Auth::Extensible> framework.

See L<Dancer::Plugin::DBIC> for how to configure a database connection
appropriately; see the L</CONFIGURATION> section below for how to configure this
authentication provider with database details.

See L<Dancer::Plugin::Auth::Extensible> for details on how to use the
authentication framework, including how to pick a more useful authentication
provider.

=head1 CONFIGURATION

This provider tries to use sensible defaults, so you may not need to provide
much configuration if your database tables look similar to those in the
L</SUGGESTED SCHEMA> section below.

The most basic configuration, assuming defaults for all options, and defining a
single authentication realm named 'users':

    plugins:
        Auth::Extensible:
            realms:
                users:
                    provider: 'DBIC'

You would still need to have provided suitable database connection details to
L<Dancer::Plugin::Database>, of course;  see the docs for that plugin for full
details, but it could be as simple as, e.g.:

    plugins:
        Auth::Extensible:
            realms:
                users:
                    provider: 'DBIC'
        DBIC:
            default:
                dsn:          'dbi:SQLite:mydb.sqlite'
                schema_class: My::Schema

A full example showing all options:

    plugins:
        Auth::Extensible:
            realms:
                users:
                    provider: 'DBIC'
                    # optionally set DB connection name to use (see named 
                    # connections in Dancer::Plugin::Database docs)
                    db_connection_name: 'foo'

                    # Optionally disable roles support, if you only want to check
                    # for successful logins but don't need to use role-based access:
                    disable_roles: 1

                    # optionally specify names of the table, relationship and
                    # columns (the values given below are the defaults)
                    users_resultset:     User
                    roles_relationship:  roles
                    role_column:         role
                    username_column:     username
                        # function in the user resultset 
                        # taking the submitted password
                        # and returning true if it matches
                        # the user's
                    password_check:      check_password

See the main L<Dancer::Plugin::Auth::Extensible> documentation for how to
configure multiple authentication realms.

=head1 SUGGESTED SCHEMA

If you use a DBIx::Class schema similar to the examples provided here, you should need
minimal configuration to get this authentication provider to work for you.

=head2 users class

    package My::Schema::Result::User;

    use strict;
    use warnings;

    use base qw/ DBIx::Class::Core /;

    __PACKAGE__->load_components(qw/EncodedColumn Core/);

    __PACKAGE__->table('Users');

    __PACKAGE__->add_columns(
        user_id => {
            data_type => 'INTEGER',
            is_auto_increment => 1,
            is_nullable => 0,
        },
        username => {
            data_type => 'VARCHAR',
            size => 32,
            is_nullable => 0,
        },
        password => {
            data_type => 'VARCHAR',
            size => 40,
            is_nullable => 0,
            encode_column => 1,
            encode_class  => 'Digest',
            encode_args   => { 
                algorithm => 'SHA-1', 
                format => 'hex',
            },
            encode_check_method => 'check_password',
        },
    );

    __PACKAGE__->set_primary_key( 'user_id' );
    __PACKAGE__->add_unique_constraint( 'username' => [ 'username' ] );

    __PACKAGE__->has_many( 
        user_roles => 'My::Schema::Result::UserRole', 'user_id' 
    );

    __PACKAGE__->many_to_many( 
        roles => 'user_roles', 'role'
    );

    1;

You will quite likely want other fields to store e.g. the user object
will be returned by the C<logged_in_user> keyword for your convenience.

=head2 roles class

You'll need a table to store a list of available roles in (unless you're not
using roles - in which case, disable role support (see the L</CONFIGURATION>
section).

    package My::Schema::Result::Role;

    use strict;
    use warnings;

    use base qw/ DBIx::Class::Core /;

    __PACKAGE__->table('Roles');

    __PACKAGE__->add_columns(
        role_id => {
            data_type => 'INTEGER',
            is_auto_increment => 1,
            is_nullable => 0,
        },
        role => {
            data_type => 'VARCHAR',
            size => 32,
            is_nullable => 0,
        },
    );

    __PACKAGE__->set_primary_key( 'role_id' );
    __PACKAGE__->add_unique_constraint( 'role' => [ 'role' ] );

    __PACKAGE__->has_many( 
        user_roles => 'My::Schema::Result::UserRole', 'role_id' 
    );

    __PACKAGE__->many_to_many( 
        users => 'user_roles', 'user'
    );

    1;

=head2 user_roles class

Finally, (unless you've disabled role support)  you'll need a table to store
user <-> role mappings (i.e. one row for every role a user has; so adding 
extra roles to a user consists of adding a new role to this table). 

    package My::Schema::Result::UserRole;

    use strict;
    use warnings;

    use base qw/ DBIx::Class::Core /;

    __PACKAGE__->table('UserRoles');

    __PACKAGE__->add_columns(
        user_id => {
            data_type => 'INTEGER',
            is_foreign_key => 1,
            is_nullable => 0,
        },
        role_id => {
            data_type => 'INTEGER',
            is_foreign_key => 1,
            is_nullable => 0,
        },
    );

    __PACKAGE__->set_primary_key( 'user_id', 'role_id' );

    __PACKAGE__->belongs_to( 
        user => 'My::Schema::Result::User', 'user_id' 
    );
    __PACKAGE__->belongs_to( 
        role => 'My::Schema::Result::Role', 'role_id' 
    );

    1;

=head1 SEE ALSO

L<Dancer::Plugin::Auth::Extensible>

L<Dancer::Plugin::DBIC>

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
