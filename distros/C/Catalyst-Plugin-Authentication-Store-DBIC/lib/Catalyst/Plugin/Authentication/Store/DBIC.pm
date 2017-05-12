package Catalyst::Plugin::Authentication::Store::DBIC;

use strict;
use warnings;

our $VERSION = '0.11';

use Catalyst::Plugin::Authentication::Store::DBIC::Backend;
use Catalyst::Utils ();

sub setup {
    my $c = shift;

    $c->log->warn('Authentication::Store::DBIC is deprecated!')
      unless $c->config->{authentication}{dbic}{no_deprecation_warning};

    # default values
    $c->config->{authentication}{dbic}{user_field}     ||= 'user';
    $c->config->{authentication}{dbic}{password_field} ||= 'password';
    $c->config->{authentication}{dbic}{catalyst_user_class} ||=
        'Catalyst::Plugin::Authentication::Store::DBIC::User';        

    $c->default_auth_store(
        Catalyst::Plugin::Authentication::Store::DBIC::Backend->new( {
            auth  => $c->config->{authentication}{dbic},
            authz => $c->config->{authorization}{dbic}
        } )
    );

    $c->NEXT::setup(@_);
}

sub setup_finished {
    my $c = shift;

    return $c->NEXT::setup_finished unless @_;

    my $config = $c->default_auth_store;
    if (my $user_class = $config->{auth}{user_class}) {
        $config->{auth}{user_class} = _get_instance( $c, $user_class );

        if ($config->{auth}{user_class}->isa('Class::DBI') and
            $config->{auth}{catalyst_user_class} eq 'Catalyst::Plugin::Authentication::Store::DBIC::User')
        {
            my $uc = 'Catalyst::Plugin::Authentication::Store::DBIC::User::CDBI';
            eval "require $uc";
            die $@ if $@;
            $config->{auth}{catalyst_user_class} = $uc;
        }

    }
    else {
        Catalyst::Exception->throw( message => "You must provide a user_class" );
    }

    if (my $role_class = $config->{authz}{role_class}) {
        $config->{authz}{role_class} = _get_instance( $c, $role_class );
    }

    if (my $user_role_class = $config->{authz}{user_role_class}) {
        $config->{authz}{user_role_class} = _get_instance( $c, $user_role_class );
    }

    $c->NEXT::setup_finished(@_);
}

sub _get_instance {
    my( $c, $class ) = @_;

    # first see if there's a component already loaded. this means the user
    # specified the full component name (MyApp::Model::Foo::Bar)
    my $comp;
    if( $comp = $c->components->{ $class } ) {
        return $comp if ref $comp;
    }

    # second check to see if model() or comp() gives us something. this means
    # the user specified the part after MyApp::Model only
    my $model = $c->model($class) || $c->comp($class);

    return $model if ref $model;

    # now we're on to class names only

    # if a component wasn't found, perhaps it's not been loaded yet.
    if( !$comp ) {
        eval { Catalyst::Utils::ensure_class_loaded( $class ); };
    }

    # if the class existed, check to see if it's a dbic class and return a
    # resultset instance
    if( $comp || !$@ ){
        if( $class->can('resultset_instance') ) {
            return $class->resultset_instance;
        }
        return $class;
    }

    # last case where the model gave us a non-ref which could be an old dbic
    # class-data style setup
    if( $model->can('resultset_instance') ) {
        return $model->resultset_instance;
    }

    return $model;
}

sub user_object {
    my $c = shift;

    return ( $c->user_exists ) ? $c->user->obj : undef;
}

1;
__END__

=pod

=head1 NAME

Catalyst::Plugin::Authentication::Store::DBIC - **DEPRECATED** Authentication and authorization against a DBIx::Class or Class::DBI model.

=head1 DEPRECATED

This store has been deprecated in favour of 
L<Catalyst::Authentication::Store::DBIx::Class>. Please do not use 
this plugin for new development.

=head1 SYNOPSIS

    use Catalyst qw/
        Authentication
        Authentication::Store::DBIC
        Authentication::Credential::Password
        Authorization::Roles                                # if using roles
        /;

    # Authentication
    __PACKAGE__->config->{authentication}{dbic} = {
        user_class         => 'DB::User',
        user_field         => 'username',
        password_field     => 'password',
        password_type      => 'hashed',
        password_hash_type => 'SHA-1',
    };

    # Authorization using a many-to-many role relationship
    # For more detailed instructions on setting up role-based auth, please
    # see the section below titled L<Roles>.
    __PACKAGE__->config->{authorization}{dbic} = {
        role_class           => 'DB::Role',
        role_field           => 'role',
        role_rel             => 'map_user_role',                # DBIx::Class only
        user_role_user_field => 'user',
        user_role_class      => 'DB::UserRole',   # Class::DBI only
        user_role_role_field => 'role',                         # Class::DBI only
    };

    # log a user in
    sub login : Global {
        my ( $self, $c ) = @_;

        $c->login( $c->req->param("email"), $c->req->param("password"), );
    }

    # verify a role
    if ( $c->check_user_roles( 'admin' ) ) {
        $model->delete_everything;
    }

=head1 DESCRIPTION

This plugin uses a DBIx::Class (or Class::DBI) object to authenticate a user.

=head1 AUTHENTICATION CONFIGURATION

Authentication is configured by setting an authentication->{dbic} hash
reference in your application's config method.  The following configuration
options are supported.

=head2 user_class

The name of the class that represents a user object. Can be the full class
name, or just the model name (i.e. the part after C<MyApp::Model>). If it is a
DBIC class, will automatically save and use the resultset from the DBIC schema.

=head2 user_field

The name of the column holding the user identifier (defaults to C<user>)

=head2 password_field

The name of the column holding the user's password (defaults to C<password>)

=head2 password_type

The type of password your user object stores. One of: clear, crypted,
hashed, or salted_hash. Defaults to clear.

=head2 password_hash_type

If using a password_type of hashed, this option specifies the hashing method
being used. Any hashing method supported by the L<Digest> module may be used.

=head2 password_pre_salt

Use this option if your passwords are hashed with a prefix salt value.

=head2 password_post_salt

Use this option if your passwords are hashed with a postfix salt value.

=head2 password_salt_len

Use this option to specify the salt length for salted_hash passwords (defaults to 0).

=head2 auto_create_user

If this option is set, when a user is not found, an C<auto_create> method will be
called on your C<user_class> with the arguments that were passed to
L<Catalyst::Plugin::Authentication::Store::DBIC::Backend/get_user>.
If it returns true, it is assumed that a user corresponding to the arguments has
been created, and the user will be looked up again.

=head2 session_data_field

This option should be set to the name of an accessor in your model class which can
store and retreive a hashref. If this option is set, the user object will advertise
that it supports the feature C<session_data>, and other code will be able to use the
C<< $c->session_data >> accessor. This can be used in combination with other plugins
that can make use of the C<session_data> feature, like
L<Catalyst::Plugin::Session::PerUser>. See the documentation for one of those modules
to see how to use this functionality from a controller.

You can set up automatic inflation and deflation for the chosen field to deal with
the hash reference. Here's an example of how to do that in DBIC with a C<TEXT>
column, L<MIME::Base64>, and L<Storable>:

  package MySchema::Users;
  use base qw/DBIx::Class/;
  use Storable qw/freeze thaw/;
  use MIME::Base64;

  # define table, columns, primary key, etc. here

  __PACKAGE__->inflate_column(
      session_data => {
          inflate => sub { thaw(decode_base64(shift)) },
          deflate => sub { encode_base64(freeze(shift)) },
      }
  );

=head2 catalyst_user_class

If using a plain model class which has username and password fields is not working
for you, because you have more complex objects, or you need to do something else
odd to fetch those values or your role fields, you can subclass
L<Catalyst::Plugin::Authentication::Store::DBIC::User>, and supply your class
name here.

=head1 AUTHORIZATION CONFIGURATION

Role-based authorization is configured by setting an authorization->{dbic}
hash reference in your application's config method.  The following options
are supported.  For more detailed instructions on setting up roles, please
see the section below titled L<Roles>.

=head2 role_class

The name of the class that contains the list of roles. Can be the full class
name, or just the model name (i.e. the part after C<MyApp::Model>). If it is a
DBIC class, will automatically save and use the resultset from the DBIC schema.

=head2 role_field

The name of the field in L<role_class> that contains the role name. The role
name is typically a text value like C<admin>.

=head2 role_rel

DBIx::Class models only. This field specifies the name of the
relationship in L<role_class> that refers to the mapping table between
users and roles. Using this relationship, DBIx::Class models can retrieve
the list of roles for a user in a single SQL statement using a join.

=head2 user_role_class

Class::DBI models only. The name of the class for the many-to-many
linking table between users and roles.

=head2 user_role_user_field

The name of the field in L<user_role_class> that contains the user id.
This is required for both DBIx::Class and Class::DBI.

=head2 user_role_role_field

Class::DBI models only. The name of the field in L<user_role_class> that
contains the role id, which is a foreign key referencing the primary key
of the table corresponding to C<role_class>.

=head1 METHODS

=head2 obj

You can get the DBIx::Class or Class::DBI row object corresponding to the
current user by calling C<< $c->user->obj >>. You can also get the value
of an individual column with C<< $c->user->column_name >>, assuming it does
not conflict with an existing method in
L<<Catalyst::Plugin::Authentication::Store::DBIC>.

Note: The earlier methods of C<< $c->user_object >> and C<< $c->user->user >>
still work, but are no longer recommended. The new API is cleaner and easier
to use.

=head1 INTERNAL METHODS

=head2 setup

=head2 setup_finished

Finalizes the setup of the plugin by filling in the C<user_class> and
C<role_class> config values with the appropriate DBIx::Class resultsets.
Does nothing if you are using Class::DBI.

=head1 ROLES

This section attempts to provide detailed instructions for configuring
role-based authorization in your application.

=head2 Database Schema

The basic database structure for roles consists of the following 3 tables.
This syntax is for SQLite, but can be easily adapted to other databases.

    CREATE TABLE user (
        id       INTEGER PRIMARY KEY,
        username TEXT,
        password TEXT
    );

    CREATE TABLE role (
        id   INTEGER PRIMARY KEY,
        role TEXT
    );

    # DBIx::Class can handle multiple primary keys
    CREATE TABLE user_role (
        user INTEGER REFERENCES user,
        role INTEGER REFERENCES role,
        PRIMARY KEY (user, role)
    );

    # Class::DBI may need the following user_role table
    CREATE TABLE user_role (
        id   INTEGER PRIMARY KEY,
        user INTEGER REFERENCES user,
        role INTEGER REFERENCES role,
        UNIQUE (user, role)
    );

=head2 DBIx::Class

For best performance when using roles, DBIx::Class models are recommended.
By using DBIx::Class you will benefit from optimized SQL using joins that
can retrieve roles for a user with a single SQL statement.

The steps for setting up roles with DBIx::Class are:

=head3 1. Create Model classes and define relationships

    package MyApp::Model::DB;
    use strict;
    use base 'Catalyst::Model::DBIC::Schema';
    __PACKAGE__->config(
        schema_class => 'MyApp::Schema',
        connect_info => [ ... ],
    );

    1;

    package MyApp::Schema;
    use strict;
    use base 'DBIx::Class::Schema';

    __PACKAGE__->load_classes;

    1;

    package MyApp::Schema::User;
    use strict;
    use base 'DBIx::Class';

    __PACKAGE__->load_components( qw/ Core / );
    __PACKAGE__->table( 'user' );
    __PACKAGE__->add_columns( qw/id username password/ );
    __PACKAGE__->set_primary_key( 'id' );

    __PACKAGE__->has_many(
        map_user_role => 'MyApp::Schema::UserRole' => 'user' );

    1;

    package MyApp::Schema::Role;
    use strict;
    use base 'DBIx::Class';

    __PACKAGE__->load_components( qw/ Core / );
    __PACKAGE__->table( 'role' );
    __PACKAGE__->add_columns( qw/id role/ );
    __PACKAGE__->set_primary_key( 'id' );

    __PACKAGE__->has_many(
        map_user_role => 'MyApp::Schema::UserRole' => 'role' );

    1;

    package MyApp::Schema::UserRole;
    use strict;
    use base 'DBIx::Class';

    __PACKAGE__->load_components( qw/ Core / );
    __PACKAGE__->table( 'user_role' );
    __PACKAGE__->add_columns( qw/user role/ );
    __PACKAGE__->set_primary_key( qw/user role/ );

    1;

=head3 2. Specify authorization configuration settings

For the above DBIx::Class model classes, the configuration would look like
this:

    __PACKAGE__->config->{authorization}{dbic} = {
        role_class           => 'DB::Role',
        role_field           => 'role',
        role_rel             => 'map_user_role',
        user_role_user_field => 'user',
    };

=head2 Class::DBI

Class::DBI models are also supported but require slightly more configuration.
Performance will also suffer as more SQL statements must be run to retrieve
all roles for a user.

The steps for setting up roles with Class::DBI are:

=head3 1. Create Model classes

    package MyApp::Model::DB;
    use strict;
    use base 'Class::DBI';
    __PACKAGE__->connection(...);

    package MyApp::Model::DB::User;
    use strict;
    use base 'MyApp::Model::DB';

    __PACKAGE__->table  ( 'user' );
    __PACKAGE__->columns( Primary   => qw/id/ );
    __PACKAGE__->columns( Essential => qw/username password/ );

    1;

    package MyApp::Model::DB::Role;
    use strict;
    use base 'MyApp::Model::DB';

    __PACKAGE__->table  ( 'role' );
    __PACKAGE__->columns( Primary   => qw/id/ );
    __PACKAGE__->columns( Essential => qw/role/ );

    1;

    package MyApp::Model::DB::UserRole;
    use strict;
    use base 'MyApp::Model::DB';

    __PACKAGE__->table  ( 'user_role' );
    __PACKAGE__->columns( Primary   => qw/id/ );
    __PACKAGE__->columns( Essential => qw/user role/ );

    1;

=head3 2. Specify authorization configuration settings

For the above Class::DBI model classes, the configuration would look like
this:

    __PACKAGE__->config->{authorization}{dbic} = {
        role_class           => 'DB::Role',
        role_field           => 'role',
        user_role_class      => 'DB::UserRole',
        user_role_user_field => 'user',
        user_role_role_field => 'role',
    };

=head1 SEE ALSO

L<Catalyst::Plugin::Authentication>, L<Catalyst::Plugin::Authorization::Roles>

=head1 AUTHORS

David Kamholz, <dkamholz@cpan.org>

Andy Grundman

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
