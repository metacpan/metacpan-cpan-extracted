package Dancer2::Plugin::Auth::Extensible::Provider::Database;

use Carp;
use Moo;
with "Dancer2::Plugin::Auth::Extensible::Role::Provider";
use namespace::clean;

our $VERSION = '0.630';

=head1 NAME 

Dancer2::Plugin::Auth::Extensible::Provider::Database - authenticate via a database


=head1 DESCRIPTION

This class is an authentication provider designed to authenticate users against
a database, using L<Dancer2::Plugin::Database> to access a database.

L<Crypt::SaltedHash> is used to handle hashed passwords securely; you wouldn't
want to store plain text passwords now, would you?  (If your answer to that is
yes, please reconsider; you really don't want to do that, when it's so easy to
do things right!)

See L<Dancer2::Plugin::Database> for how to configure a database connection
appropriately; see the L</CONFIGURATION> section below for how to configure this
authentication provider with database details.

See L<Dancer2::Plugin::Auth::Extensible> for details on how to use the
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
                    provider: 'Database'

You would still need to have provided suitable database connection details to
L<Dancer2::Plugin::Database>, of course;  see the docs for that plugin for full
details, but it could be as simple as, e.g.:

    plugins:
        Auth::Extensible:
            realms:
                users:
                    provider: 'Database'
        Database:
            driver: 'SQLite'
            database: 'test.sqlite'
            on_connect_do: ['PRAGMA foreign_keys = ON']
            dbi_params:
                PrintError: 0
                RaiseError: 1


A full example showing all options:

    plugins:
        Auth::Extensible:
            realms:
                users:
                    provider: 'Database'
                    # optionally set DB connection name to use (see named
                    # connections in Dancer2::Plugin::Database docs)
                    db_connection_name: 'foo'

                    # Optionally disable roles support, if you only want to check
                    # for successful logins but don't need to use role-based access:
                    disable_roles: 1

                    # optionally specify names of tables if they're not the defaults
                    # (defaults are 'users', 'roles' and 'user_roles')
                    users_table: 'users'
                    roles_table: 'roles'
                    user_roles_table: 'user_roles'

                    # optionally set the column names (see the SUGGESTED SCHEMA
                    # section below for the default names; if you use them, they'll
                    # Just Work)
                    users_id_column: 'id'
                    users_username_column: 'username'
                    users_password_column: 'password'
                    roles_id_column: 'id'
                    roles_role_column: 'role'
                    user_roles_user_id_column: 'user_id'
                    user_roles_role_id_column: 'roles_id'

See the main L<Dancer2::Plugin::Auth::Extensible> documentation for how to
configure multiple authentication realms.

=head1 SUGGESTED SCHEMA

If you use a schema similar to the examples provided here, you should need
minimal configuration to get this authentication provider to work for you.

The examples given here should be MySQL-compatible; minimal changes should be
required to use them with other database engines.

=head2 users table

You'll need a table to store user accounts in, of course.  A suggestion is
something like:

    CREATE TABLE users (
        id       INTEGER     AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(32) NOT NULL       UNIQUE KEY,
        password VARCHAR(40) NOT NULL
    );

You will quite likely want other fields to store e.g. the user's name, email
address, etc; all columns from the users table will be returned by the
C<logged_in_user> keyword for your convenience.

=head2 roles table

You'll need a table to store a list of available roles in (unless you're not
using roles - in which case, disable role support (see the L</CONFIGURATION>
section).

    CREATE TABLE roles (
        id    INTEGER     AUTO_INCREMENT PRIMARY KEY,
        role  VARCHAR(32) NOT NULL
    );

=head2 user_roles table

Finally, (unless you've disabled role support)  you'll need a table to store
user <-> role mappings (i.e. one row for every role a user has; so adding 
extra roles to a user consists of adding a new role to this table).  It's 
entirely up to you whether you use an "id" column in this table; you probably
shouldn't need it.

    CREATE TABLE user_roles (
        user_id  INTEGER  NOT NULL,
        role_id  INTEGER  NOT NULL,
        UNIQUE KEY user_role (user_id, role_id)
    );

If you're using InnoDB tables rather than the default MyISAM, you could add a
foreign key constraint for better data integrity; see the MySQL documentation
for details, but a table definition using foreign keys could look like:

    CREATE TABLE user_roles (
        user_id  INTEGER, FOREIGN KEY (user_id) REFERENCES users (id),
        role_id  INTEGER, FOREIGN KEY (role_id) REFERENCES roles (id),
        UNIQUE KEY user_role (user_id, role_id)
    ) ENGINE=InnoDB;

=head1 ATTRIBUTES

=head2 dancer2_plugin_database

Lazy-loads the correct instance of L<Dancer2::Plugin::Database> which handles
the following methods:

=over

=item * plugin_database

This corresponds to the C<database> keyword from L<Dancer2::Plugin::Database>.

=back

=cut

has dancer2_plugin_database => (
    is   => 'ro',
    lazy => 1,
    default =>
      sub { $_[0]->plugin->app->with_plugin('Dancer2::Plugin::Database') },
    handles  => { plugin_database => 'database' },
    init_arg => undef,
);

=head2 database

The connected L</plugin_database> using L</db_connection_name>.

=cut

has database => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        $self->plugin_database($self->db_connection_name);
    },
);

=head2 db_connection_name

Optional.

=cut

has db_connection_name => (
    is => 'ro',
);

=head2 users_table

Defaults to 'users'.

=cut

has users_table => (
    is      => 'ro',
    default => 'users',
);

=head2 users_id_column

Defaults to 'id'.

=cut

has users_id_column => (
    is      => 'ro',
    default => 'id',
);

=head2 users_username_column

Defaults to 'username'.

=cut

has users_username_column => (
    is      => 'ro',
    default => 'username',
);

=head2 users_password_column

Defaults to 'password'.

=cut

has users_password_column => (
    is      => 'ro',
    default => 'password',
);

=head2 roles_table

Defaults to 'roles'.

=cut

has roles_table => (
    is      => 'ro',
    default => 'roles',
);

=head2 roles_id_column

Defaults to 'id'.

=cut

has roles_id_column => (
    is      => 'ro',
    default => 'id',
);

=head2 roles_role_column

Defaults to 'role'.

=cut

has roles_role_column => (
    is      => 'ro',
    default => 'role',
);

=head2 user_roles_table

Defaults to 'user_roles'.

=cut

has user_roles_table => (
    is      => 'ro',
    default => 'user_roles',
);

=head2 user_roles_user_id_column

Defaults to 'user_id'.

=cut

has user_roles_user_id_column => (
    is      => 'ro',
    default => 'user_id',
);

=head2 user_roles_role_id_column

Defaults to 'role_id'.

=cut

has user_roles_role_id_column => (
    is      => 'ro',
    default => 'role_id',
);

=head1 METHODS

=head2 authenticate_user $username, $password

=cut

sub authenticate_user {
    my ($self, $username, $password) = @_;
    croak "Both of username and password must be defined"
      unless defined $username && defined $password;

    # Look up the user:
    my $user = $self->get_user_details($username);
    return unless $user;

    # OK, we found a user, let match_password (from our base class) take care of
    # working out if the password is correct

    my $correct = $user->{ $self->users_password_column };

    # do NOT authenticate when password is empty/undef
    return undef unless ( defined $correct && $correct ne '' );

    return $self->match_password( $password, $correct );
}

=head2 create_user

=cut

sub create_user {
    my ( $self, %options ) = @_;

    # Prevent attempt to update wrong key
    my $username = delete $options{username}
      or croak "username needs to be specified for create_user";

    # password column might not be nullable so set to empty since we fail
    # auth attempts for empty passwords anyway
    my $ret = $self->database->quick_insert( $self->users_table,
        { $self->users_username_column => $username, password => '', %options }
    );
    return $ret ? $self->get_user_details($username) : undef;
}

=head2 get_user_details $username

=cut

# Return details about the user.  The user's row in the users table will be
# fetched and all columns returned as a hashref.
sub get_user_details {
    my ($self, $username) = @_;
    croak "username must be defined"
      unless defined $username;

    # Get our database handle and find out the table and column names:
    my $database = $self->database;

    # Look up the user, 
    my $user = $database->quick_select(
        $self->users_table, { $self->users_username_column => $username }
    );
    if (!$user) {
        $self->plugin->app->log("debug", "No such user $username");
        return;
    } else {
        return $user;
    }
}

=head2 get_user_roles $username

=cut

sub get_user_roles {
    my ($self, $username) = @_;

    my $database = $self->database;

    # Get details of the user first; both to check they exist, and so we have
    # their ID to use.
    my $user = $self->get_user_details($username)
        or return;

    # Right, fetch the roles they have.  There's currently no support for
    # JOINs in Dancer2::Plugin::Database, so we'll need to do this query
    # ourselves - so we'd better take care to quote the table & column names, as
    # we're going to have to interpolate them.  (They're coming from our config,
    # so should be pretty trustable, but they might conflict with reserved
    # identifiers or have unacceptable characters to not be quoted.)
    # Because I've tried to be so flexible in allowing the user to configure
    # table names, column names, etc, this is going to be fucking ugly.
    # Seriously ugly.  Clear bag of smashed arseholes territory.


    my $roles_table = $database->quote_identifier(
        $self->roles_table
    );
    my $roles_role_id_column = $database->quote_identifier(
        $self->roles_id_column
    );
    my $roles_role_column = $database->quote_identifier(
        $self->roles_role_column
    );

    my $user_roles_table = $database->quote_identifier(
        $self->user_roles_table
    );
    my $user_roles_user_id_column = $database->quote_identifier(
        $self->user_roles_user_id_column
    );
    my $user_roles_role_id_column = $database->quote_identifier(
        $self->user_roles_role_id_column
    );

    # Yes, there's SQL interpolation here; yes, it makes me throw up a little.
    # However, all the variables used have been quoted appropriately above, so
    # although it might look like a camel's arsehole, at least it's safe.
    my $sql = <<QUERY;
SELECT $roles_table.$roles_role_column
FROM $user_roles_table
JOIN $roles_table 
  ON $roles_table.$roles_role_id_column 
   = $user_roles_table.$user_roles_role_id_column
WHERE $user_roles_table.$user_roles_user_id_column = ?
QUERY

    my $sth = $database->prepare($sql)
        or croak "Failed to prepare query - error: " . $database->err_str;

    $sth->execute($user->{$self->users_id_column});

    my @roles;
    while (my($role) = $sth->fetchrow_array) {
        push @roles, $role;
    }

    return \@roles;

    # If you read through this, I'm truly, truly sorry.  This mess was the price
    # of making things so configurable.  Send me your address, and I'll send you
    # a complementary fork to remove your eyeballs with as way of apology.
    # If I can bear to look at this code again, I think I might seriously
    # refactor it and use Template::Tiny or something on it.  Or Acme::Bleach.
}

=head2 set_user_details

=cut

sub set_user_details {
    my ($self, $username, %update) = @_;

    croak "Username to update needs to be specified" unless $username;

    my $user = $self->get_user_details($username) or return;

    my $ret = $self->database->quick_update( $self->users_table,
        { $self->users_username_column => $username }, \%update );
    return $ret ? $self->get_user_details($username) : undef;
}

=head2 set_user_password

=cut

sub set_user_password {
    my ( $self, $username, $password ) = @_;
    my $encrypted = $self->encrypt_password($password);
    my %update = ( $self->users_password_column => $encrypted );
    $self->set_user_details( $username, %update );
};

=head1 COOKBOOK

=head2 Handle locked or disabled user accounts

I<(contributed by PerlDuck, Borodin and simbabque
L<via Stack Overflow|https://stackoverflow.com/questions/46746864>)>

It's a good practice to not delete certain data, like user accounts. But what
do you do when you want to get rid of a user? Maybe an employee left or was
temporary suspended, or a user did not pay their subscription fee. In those cases you
would want the user data to stay around, but they should not be able to log in
any more.

Let's say there is a column C<disabled> in an already existing user table.
It might hold a timestamp for when the user was disabled, and be C<NULL> if the
user is active. By default, L<Dancer2::Plugin::Auth::Extensible> will give you this
information as part of the user data, but to check if the user is allowed to proceed
would happen after the password has been checked and they have already been logged
in.

The following sections will describe two different ways of implementing this. The
first one is easier to implement, but only allows read operations on the user
table, while the second one requires a little more effort, but will allow almost
all operations to work. If you need even more flexibility you will have to subclass
and add a bit more logic.

=head3 ... without changing any code

An easy way to achieve this is by adding a new view to your database that only
shows active users. Let's look at the following example database.

    -- user table
    CREATE TABLE users (
        id       INTEGER     PRIMARY KEY AUTOINCREMENT,
        username VARCHAR(32) NOT NULL UNIQUE,
        password VARCHAR(40) NOT NULL,
        disabled TIMESTAMP   NULL
    );

    -- active user view
    CREATE VIEW active_users (id, username, password) AS
        SELECT id, username, password FROM users WHERE disabled IS NULL;

    -- some data
    INSERT INTO users ( username, password, disabled )
    VALUES  ( 'Alice', 'test', null),
            ( 'Bob', 'test', '2017-10-01 10:10:10');

Now all you need to do is change the L</users_table> setting to point
to C<active_users> instead of C<users>.

    # config.yml
    plugins:
        Auth::Extensible:
            realms:
                users:
                    provider: 'Database'
                    users_table: 'active_users'

That's it. Your application will now only let active users log in, because it
has no way of knowing about the others. Only I<Alice> will be able to log in,
but I<Bob> has been disabled and the application will not allow him to log in.

But be aware that this comes with a few drawbacks. If you want to use
L<Dancer2::Plugin::Auth::Extensible> to also update user information, this is
now no longer possible because in most database engines you cannot write data
into a view.

=head3 ... by creating a subclass of this database provider

The alternative is to subclass this provider to add a little bit of logic.
You can add code to exclude users directly when the user data is fetched, even
before L<Dancer2::Plugin::Auth::Extensible> verifies the password. This way,
inactive users can easily be discarded.

The following code is an example implementation specifically for the user table
outlined in the alternative solution above.

    package Provider::Database::ActiveOnly;

    use Moo;
    extends 'Dancer2::Plugin::Auth::Extensible::Provider::Database';

    around 'get_user_details' => sub {
        my $orig = shift;
        my $self = shift;

        # do nothing if we there was no user
        my $user = $self->$orig(@_) or return;

        # do nothing if the user is disabled
        return if $user->{disabled};

        return $user;
    };

    1;

The code uses an L<C<around> modifier from Moo|Moo/around> to influence
the L<get_user_details> method, so users that are disabled are never
found.

To enable this new provider, you need to change the C<provider> setting
in your configuration.

    # config.yml
    plugins:
        Auth::Extensible:
            realms:
                users:
                    provider: 'Provider::Database::ActiveOnly'
                    users_table: 'users'  # this is the default

With this custom subclass your application will be able to perform write
operations on active users, including making them inactive. However, inactive
users will be invisible to L<Dancer2::Plugin::Auth::Extensible>, so you
cannot use this to turn inactive users back on.

If you want that functionality, you will have to add a bit more logic to
your subclass. A possible approach could be to replace the L</authenticate_user>
method.

=head1 AUTHOR

David Precious, C<< <davidp at preshweb.co.uk> >>

Dancer2 port of Dancer::Plugin::Auth::Extensible by:

Stefan Hornburg (Racke), C<< <racke at linuxia.de> >>

Conversion to Dancer2's new plugin system in 2016 by:

Peter Mottram (SysPete), C<< <peter at sysnix.com> >>

=head1 BUGS / FEATURE REQUESTS

This is an early version; there may still be bugs present or features missing.

This is developed on GitHub - please feel free to raise issues or pull requests
against the repo at:
L<https://github.com/PerlDancer/Dancer2-Plugin-Auth-Extensible-Provider-Database>

=head1 ACKNOWLEDGEMENTS

From L<Dancer2::Plugin::Auth::Extensible>:

Valuable feedback on the early design of this module came from many people,
including Matt S Trout (mst), David Golden (xdg), Damien Krotkine (dams),
Daniel Perrett, and others.

Configurable login/logout URLs added by Rene (hertell)

Regex support for require_role by chenryn

Support for user_roles looking in other realms by Colin Ewen (casao)

LDAP provider added by Mark Meyer (ofosos)

Documentation fix by Vince Willems.

Henk van Oers (GH #8, #13).

Andrew Beverly (GH #6, #7, #10, #17, #22, #24, #25, #26).
This includes support for creating and editing users and manage user passwords.

Gabor Szabo (GH #11, #16, #18).

Evan Brown (GH #20, #32).

Jason Lewis (Unix provider problem, typo fix).

Yanick Champoux (typo fix).

=head1 LICENSE AND COPYRIGHT

Copyright 2012-16 David Precious.
Copyright 2017-19 Stefan Hornburg (Racke).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
