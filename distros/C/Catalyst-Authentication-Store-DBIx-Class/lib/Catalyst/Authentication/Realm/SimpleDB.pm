package Catalyst::Authentication::Realm::SimpleDB;

use strict;
use warnings;
use Catalyst::Exception;
use base qw/Catalyst::Authentication::Realm/;

sub new {
    my ($class, $realmname, $config, $app) = @_;

    my $newconfig = {
        credential => {
            class => 'Password',
            password_type => 'clear'
        },
        store => {
            class => 'DBIx::Class',
            role_relation => 'roles',
            role_field => 'role',
            use_userdata_from_session => '1'
        }
    };

    if (!defined($config->{'user_model'})) {
	    Catalyst::Exception->throw("Unable to initialize authentication, no user_model specified in SimpleDB config.");
   	}


    ## load any overrides for the credential
    foreach my $key (qw/ password_type password_field password_hash_type/) {
        if (exists($config->{$key})) {
            $newconfig->{credential}{$key} = $config->{$key};
        }
    }

    ## load any overrides for the store
    foreach my $key (qw/ user_model role_relation role_field role_column use_userdata_from_session/) {
        if (exists($config->{$key})) {
            $newconfig->{store}{$key} = $config->{$key};
        }
    }
    if (exists($newconfig->{'store'}{'role_column'})) {
        delete $newconfig->{'store'}{'role_relation'};
        delete $newconfig->{'store'}{'role_field'};
    }

    return $class->SUPER::new($realmname, $newconfig, $app);
}

1;
__END__

=head1 NAME

Catalyst::Authentication::Realm::SimpleDB - A simplified Catalyst authentication configurator.

=head1 SYNOPSIS

    use Catalyst qw/
        Authentication
    /;

    __PACKAGE__->config->{'Plugin::Authentication'} =
        {
            default => {
                class      => 'SimpleDB',
                user_model => 'MyApp::Schema::Users',
            }
        }

    # later on ...
    $c->authenticate({ username => 'myusername',
                       password => 'mypassword' });

    my $age = $c->user->get('age');

    $c->logout;


=head1 DESCRIPTION

The Catalyst::Authentication::Realm::SimpleDB provides a simple way to configure Catalyst Authentication
when using the most common configuration of a password protected user retrieved from an SQL database.

=head1 CONFIGURATION

The SimpleDB Realm class configures the Catalyst authentication system based on the following:

=over

=item *
Your user data is stored in a table that is accessible via $c->model($cfg->{user_model});

=item *
Your passwords are stored in the 'password' field in your users table and are not encrypted.

=item *
Your roles for users are stored in a separate table and are directly
accessible via a DBIx::Class relationship called 'roles' and the text of the
role is stored in a field called 'role' within the role table.

=item *
Your user information is stored in the session once the user is authenticated.

=back

For the above usage, only one configuration option is necessary, 'user_model'.
B<user_model> should contain the B<class name of your user class>. See the
L</PREPARATION> section for info on how to set up your database for use with
this module.

If your system differs from the above, some minor configuration may be
necessary. The options available are detailed below. These options match the
configuration options used by the underlying credential and store modules.
More information on these options can be found in
L<Catalyst::Authentication::Credential::Password> and
L<Catalyst::Authentication::Store::DBIx::Class>.

=over

=item user_model

Contains the class name (as passed to $c->model() ) of the DBIx::Class schema
to use as the source for user information.  This config item is B<REQUIRED>.

=item password_field

If your password field is not 'password' set this option to the name of your password field.  Note that if you change this
to, say 'users_password' you will need to use that in the authenticate call:

    $c->authenticate({ username => 'bob', users_password => 'foo' });

=item password_type

If the password is not stored in plaintext you will need to define what format the password is in.  The common options are
B<crypted> and B<hashed>.  Crypted uses the standard unix crypt to encrypt the password.  Hashed uses the L<Digest> modules to
perform password hashing.

=item password_hash_type

If you use a hashed password type - this defines the type of hashing. See L<Catalyst::Authentication::Credential::Password>
for more details on this setting.

=item role_column

If your users roles are stored directly in your user table, set this to the column name that contains your roles.  For
example, if your user table contains a field called 'permissions', the value of role_column would be 'permissions'.
B<NOTE>: If multiple values are stored in the role column, they should be space or pipe delimited.

=item role_relation and role_field

These define an alternate role relationship name and the column that holds the role's name in plain text.  See
L<Catalyst::Authentication::Store::DBIx::Class/CONFIGURATION> for more details on these settings.

=item use_userdata_from_session

This is a simple 1 / 0 setting which determines how a user's data is saved / restored from the session.  If
it is set to 1, the user's complete information (at the time of authentication) is cached between requests.
If it is set to 0, the users information is loaded from the database on each request.

=back


=head1 PREPARATION

This module makes several assumptions about the structure of your database.
Below is an example of a table structure which will function with this module
in it's default configuration. You can use this table structure as-is or add
additional fields as necessary. B<NOTE> that this is the default SimpleDB
configuration only. Your table structure can differ significantly from this
when using the L<DBIx::Class
Store|Catalyst::Authentication::Store::DBIx::Class/> directly.


    --
    -- note that you can add any additional columns you require to the users table.
    --
    CREATE TABLE users (
            id            INTEGER PRIMARY KEY,
            username      TEXT,
            password      TEXT,
    );

    CREATE TABLE roles (
            id   INTEGER PRIMARY KEY,
            role TEXT
    );
    CREATE TABLE user_roles (
            user_id INTEGER,
            role_id INTEGER,
            PRIMARY KEY (user_id, role_id)
    );

Also, after you have loaded this table structure into your DBIx::Class schema,
please be sure that you have a many_to_many DBIx::Class relationship defined
for the users to roles relation. Your schema files should contain something
along these lines:

C<lib/MyApp/Schema/Users.pm>:

    __PACKAGE__->has_many(map_user_role => 'MyApp::Schema::UserRoles', 'user_id');
    __PACKAGE__->many_to_many(roles => 'map_user_role', 'role');

C<lib/MyApp/Schema/UserRoles.pm>:

    __PACKAGE__->belongs_to(role => 'MyApp::Schema::Roles', 'role_id');

=head1 MIGRATION

If and when your application becomes complex enough that you need more features
than SimpleDB gives you access to, you can migrate to a standard Catalyst
Authentication configuration fairly easily.  SimpleDB simply creates a standard
Auth config based on the inputs you give it.  The config SimpleDB creates by default
looks like this:

    MyApp->config('Plugin::Authentication') = {
        default => {
            credential => {
                class => 'Password',
                password_type => 'clear'
            },
            store => {
                class => 'DBIx::Class',
                role_relation => 'roles',
                role_field => 'role',
                use_userdata_from_session => '1',
                user_model => $user_model_from_simpledb_config
	        }
	    }
    };


=head1 SEE ALSO

This module relies on a number of other modules to do it's job.  For more information
you can refer to the following:

=over

=item *
L<Catalyst::Manual::Tutorial>

=item *
L<Catalyst::Plugin::Authentication>

=item *
L<Catalyst::Authentication::Credential::Password>

=item *
L<Catalyst::Authentication::Store::DBIx::Class>

=item *
L<Catalyst::Plugin::Authorization::Roles>

=back

=cut

