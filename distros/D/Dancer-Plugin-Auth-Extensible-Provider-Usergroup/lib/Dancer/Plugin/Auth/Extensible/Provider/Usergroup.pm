package Dancer::Plugin::Auth::Extensible::Provider::Usergroup;

use 5.014; # use strict
use warnings;
use Dancer qw(:syntax);
use base 'Dancer::Plugin::Auth::Extensible::Provider::Base';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Passphrase;

our $VERSION = '0.21';

=head1 NAME 

Dancer::Plugin::Auth::Extensible::Provider::Usergroup - authenticate as a member of a group


=head1 SYNOPSIS

Define that a user must be logged in and have the proper permissions to 
access a route:

    get '/unsubscribe' => require_role Forum => sub { ... };


=head1 DESCRIPTION

This class is an authentication provider designed to authenticate users against
a DBIC schema, using L<Dancer::Plugin::DBIC> to access a database.

L<Dancer::Plugin::Passphrase> is used to handle hashed passwords securely; you wouldn't
want to store plain text passwords now, would you?  (If your answer to that is
yes, please reconsider; you really don't want to do that, when it's so easy to
do things right!)

See L<Dancer::Plugin::DBIC> for how to configure a database connection
appropriately; see the L</CONFIGURATION> section below for how to configure this
authentication provider with database details.

See L<Dancer::Plugin::Auth::Extensible> for details on how to use the
authentication framework, including how to use "require_login" and "require_role".


=head1 CONFIGURATION

This provider tries to use sensible defaults, so you may not need to provide
much configuration if your database tables look similar to those in the
L</SUGGESTED SCHEMA> section below.

The most basic configuration, assuming defaults for all options, and defining a
single authentication realm named 'usergroup':

    plugins:
        Auth::Extensible:
            realms:
                usergroup:
                    provider: 'Usergroup'

You would still need to have provided suitable database connection details to
L<Dancer::Plugin::DBIC>, of course;  see the docs for that plugin for full
details, but it could be as simple as, e.g.:

    plugins:
        Auth::Extensible:
            realms:
                usergroup:
                    provider: 'Usergroup'
                    schema_name: 'usergroup'
        DBIC:
            usergroup:
                chema_class: Usergroup::Schema
                dsn: "dbi:SQLite:dbname=/path/to/usergroup.db"


A full example showing all options:

    plugins:
        Auth::Extensible:
            realms:
                usergroup:
                    provider: 'Usergroup'
                    
                    # optional schema name for DBIC (default 'default')
                    schema_name: 'usergroup'

                    # optionally specify names of result sets if they're not the defaults
                    # (defaults are 'User' and 'Role')
                    user_rset: 'User'
                    user_role_rset: 'Role'

                    # optionally set the column names (see the SUGGESTED SCHEMA
                    # section below for the default names; if you use them, they'll
                    # Just Work)
                    user_login_name_column: 'login_name'
                    user_passphrase_column: 'passphrase'
                    user_role_column: 'role'
                    
                    # optionally set a column name that makes a user useable
                    # (not all login names can be used to login)
                    user_activated_column: 'activated'

See the main L<Dancer::Plugin::Auth::Extensible> documentation for how to
configure multiple authentication realms.

=head1 SUGGESTED SCHEMA

If you use a schema similar to the examples provided here, you should need
minimal configuration to get this authentication provider to work for you.

The examples given here should be SQLite-compatible; minimal changes should be
required to use them with other database engines.

=head2 user table

You'll need a table to store user accounts in, of course.  A suggestion is
something like:

    CREATE TABLE users (
        id INTEGER PRIMARY KEY,
        login_name TEXT UNIQUE NOT NULL,
        passphrase TEXT NOT NULL,
        activated INTEGER
    );

You will quite likely want other fields to store e.g. the user's name, email
address, etc; all columns from the users table will be returned by the
C<logged_in_user> keyword for your convenience.

=head2 group table

You'll need a table to store a list of available groups in.

    CREATE TABLE groups (
        id INTEGER PRIMARY KEY,
        group_name TEXT UNIQUE NOT NULL
    );

=head2 membership table

To make users a member you'll need a table to store
user <-> group mappings.

    CREATE TABLE memberships (
        id INTEGER PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users (id),
        group_id INTEGER NOT NULL REFERENCES groups (id)
      );

=head2 role view

Map the user role by name.

    CREATE VIEW roles AS
    SELECT login_name, group_name AS role
        FROM users
        LEFT JOIN membership ON users.id = memberships.user_id
        LEFT JOIN groups ON groups.id = memberships.group_id
    ;

=head2 indexes

You want your data quickly.

    CREATE UNIQUE INDEX login_name ON users (login_name);
    CREATE UNIQUE INDEX group_name ON groups (group_name);
    CREATE UNIQUE INDEX user_group ON memberships (user_id, group_id);
    CREATE INDEX member_user ON memberships (user_id);
    CREATE INDEX member_group ON memberships (group_id);

=head1 INTERNALS

=head4 get_user_details

Used by L<Dancer::Plugin::Auth::Extensible>

=cut

sub get_user_details {
    my ($self, $login_name) = @_;
    return unless defined $login_name;

    my $settings = $self->realm_settings;

    # Get our schema name and find out the object and attribute names:
    my $schema = schema($settings->{schema_name} || 'default')
        or die "No DBIC schema connection";

    my $user_rset_name = $settings->{user_rset} || 'User';
    my $login_name_column = $settings->{user_login_name_column} || 'login_name';

    # Look up the user 
    my $user_rset = $schema->resultset($user_rset_name)
        ->search({ $login_name_column => $login_name });
    
    my $user_row;
    unless ($user_row = $user_rset->next) {
        debug("No such user $login_name");
        return;
    }

    my %user = $user_row->get_columns;
    
    # Get the roles, if any
    my $user_role_rset = $settings->{user_role_rset} || 'Role';
    my $user_role_column = $settings->{user_role_column} || 'role';
    my @roles = $schema->resultset($user_role_rset)
        ->search({ $login_name_column => $login_name })
        ->get_column($user_role_column)
        ->all;
    
    $user{roles} = \@roles;

    return \%user; 
}

=head4 match_password

Used by L<Dancer::Plugin::Auth::Extensible>

=cut


sub match_password {
    my ($self, $given, $correct) = @_;
    
    if ($correct =~ /^\{.+}/) {
        # Looks like a crypted password
        return passphrase($given)->matches($correct);
    }
    
    #not crypted?
    return $given eq $correct;
}

=head4 authenticate_user

Used by L<Dancer::Plugin::Auth::Extensible>

=cut

sub authenticate_user {
    my ($self, $username, $password) = @_;

    # Look up the user:
    my $user = $self->get_user_details($username);
    return unless $user;

    my $settings = $self->realm_settings;
    
    my $must_be_activated = $settings->{user_activated_column};
    if ($must_be_activated) {
        unless ($user->{$must_be_activated}) {
            debug("User $username not activated");
            return;
        }        
    }

    # OK, we found a user, let match_password take care of
    # working out if the password is correct

    my $passphrase_column = $settings->{user_passphrase_column} || 'passphrase';
    return $self->match_password($password, $user->{$passphrase_column});
}

=head4 get_user_roles

Used by L<Dancer::Plugin::Auth::Extensible>

=cut

sub get_user_roles {
    my ($self, $login_name) = @_;

    # Get details of the user, including the roles
    my $user = $self->get_user_details($login_name)
        or return;

    return $user->{roles};

}

=head1 COPYRIGHT

Copyright (c) 2013 Henk van Oers

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut

1;
