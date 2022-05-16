package Dancer2::Plugin::Auth::Extensible::Provider::DBIxClass;
use Modern::Perl;
our $VERSION = '0.0900'; # VERSION
our $AUTHORITY = 'cpan:GEEKRUTH'; # AUTHORITY
# ABSTRACT: authenticate via the Dancer2::Plugin::DBIx:Class plugin
use Carp;
use Dancer2::Core::Types qw/Bool Int Str/;
use DateTime;
use DBIx::Class::ResultClass::HashRefInflator;
use Scalar::Util qw(blessed);
use String::CamelCase qw(camelize);

use Moo;
with 'Dancer2::Plugin::Auth::Extensible::Role::Provider';
use namespace::clean;


sub deprecated_setting {
   my ( $setting, $replacement ) = @_;
   carp __PACKAGE__, " config setting \"$setting\" is deprecated.",
       " Use \"$replacement\" instead.";
}

sub BUILDARGS {
   my $class = shift;
   my %args  = ref( $_[0] ) eq 'HASH' ? %{ $_[0] } : @_;

   my $app = $args{plugin}->app;

   # backwards compat

   # deprecate the *_source settings, but don't change anything yet
   deprecated_setting( 'users_source', 'users_resultset' )
       if $args{users_source};

   deprecated_setting( 'roles_source', 'roles_resultset' )
       if $args{roles_source};

   deprecated_setting( 'user_roles_source', 'user_roles_resultset' )
       if $args{user_roles_source};

   # deprecate the *_table settings and move them into source, which
   # will be used in the lazy build for the correct *_resultset settings
   if ( $args{users_table} ) {
      deprecated_setting( 'users_table', 'users_resultset' );
      $args{users_source} = delete $args{users_table}
          if !$args{users_source};
   }

   if ( $args{roles_table} ) {
      deprecated_setting( 'roles_table', 'roles_resultset' );
      $args{roles_source} = delete $args{roles_table}
          if !$args{roles_source};
   }

   if ( $args{user_roles_table} ) {
      deprecated_setting( 'user_roles_table', 'user_roles_resultset' );
      $args{user_roles_source} = delete $args{user_roles_table}
          if !$args{user_roles_source};
   }

   return \%args;
}


has user_as_object => (
   is      => 'ro',
   isa     => Bool,
   default => 0,
);

has dancer2_plugin_dbic => (
   is       => 'ro',
   lazy     => 1,
   default  => sub { $_[0]->plugin->app->with_plugin('Dancer2::Plugin::DBIx::Class') },
   handles  => { dbic_schema => 'schema' },
   init_arg => undef,
);

has schema_name => ( is => 'ro', );

has schema => (
   is      => 'ro',
   lazy    => 1,
   default => sub {
      my $self = shift;
      $self->schema_name
          ? $self->dbic_schema( $self->schema_name )
          : $self->dbic_schema;
   },
);

has password_expiry_days => (
   is  => 'ro',
   isa => Int,
);

has roles_key => ( is => 'ro', );

has roles_resultset => (
   is      => 'ro',
   lazy    => 1,
   default => sub { camelize( $_[0]->roles_source ) },
);

has roles_role_column => (
   is      => 'ro',
   default => 'role',
);

has roles_source => (
   is      => 'ro',
   default => 'role',
);

has users_resultset => (
   is      => 'ro',
   lazy    => 1,
   default => sub { camelize( $_[0]->users_source ) },
);

has users_source => (
   is      => 'ro',
   default => 'user',
);

has users_lastlogin_column => (
   is      => 'ro',
   default => 'lastlogin',
);

has users_password_column => (
   is      => 'ro',
   default => 'password',
);

has users_pwchanged_column => ( is => 'ro', );

has users_pwresetcode_column => (
   is      => 'ro',
   default => 'pw_reset_code',
);

has users_password_check => ( is => 'ro', );

has users_username_column => (
   is      => 'ro',
   default => 'username',
);

has user_user_roles_relationship => (
   is      => 'ro',
   lazy    => 1,
   default => sub { $_[0]->_build_user_roles_relationship('user') },
);

has user_roles_resultset => (
   is      => 'ro',
   lazy    => 1,
   default => sub { camelize( $_[0]->user_roles_source ) },
);

has user_roles_source => (
   is      => 'ro',
   default => 'user_roles',
);

has user_valid_conditions => (
   is      => 'ro',
   default => sub { {} },
);

has role_user_roles_relationship => (
   is      => 'ro',
   lazy    => 1,
   default => sub { $_[0]->_build_user_roles_relationship('role') },
);

has user_roles_result_class => (
   is      => 'ro',
   lazy    => 1,
   default => sub {
      my $self = shift;

      # undef if roles are disabled
      return undef if $self->plugin->disable_roles;
      return $self->schema->resultset( $self->user_roles_resultset )
          ->result_source->result_class;
   },
);

sub _build_user_roles_relationship {
   my ( $self, $name ) = @_;

   return undef if $self->plugin->disable_roles;

   # Introspect result sources to find relationships

   my $user_roles_class =
       $self->schema->resultset( $self->user_roles_resultset )->result_source->result_class;

   my $resultset_name = "${name}s_resultset";

   my $result_source = $self->schema->resultset( $self->$resultset_name )->result_source;

   foreach my $relname ( $result_source->relationships ) {
      my $rel_info = $result_source->relationship_info($relname);

      # just check for a simple equality join condition. It could be other
      # things (e.g. code ref) but for now this is unsupported.
      next unless ref $rel_info->{cond} eq 'HASH';
      my %cond = %{ $rel_info->{cond} };
      if (  $rel_info->{class} eq $user_roles_class
         && $rel_info->{attrs}->{accessor} eq 'multi'
         && $rel_info->{attrs}->{join_type} eq 'LEFT'
         && scalar keys %cond == 1 )
      {
         return $relname;
      }
   }
}

has role_relationship => (
   is      => 'ro',
   lazy    => 1,
   default => sub { $_[0]->_build_relationship('role') },
);

has user_relationship => (
   is      => 'ro',
   lazy    => 1,
   default => sub { $_[0]->_build_relationship('user') },
);

sub _build_relationship {
   my ( $self, $name ) = @_;

   return undef if $self->plugin->disable_roles;

   # Introspect result sources to find relationships

   my $user_roles_class =
       $self->schema->resultset( $self->user_roles_resultset )->result_source->result_class;

   my $resultset_name = "${name}s_resultset";

   my $result_source = $self->schema->resultset( $self->$resultset_name )->result_source;

   my $user_roles_relationship = "${name}_user_roles_relationship";

   my ($relationship) =
       keys %{ $result_source->reverse_relationship_info( $self->$user_roles_relationship ) };

   return $relationship;
}

# Returns a DBIC rset for the user
sub _user_rset {
   my ( $self, $column, $value, $options ) = @_;
   my $username_column       = $self->users_username_column;
   my $user_valid_conditions = $self->user_valid_conditions;

   my $search_column =
         $column eq 'username'      ? $username_column
       : $column eq 'pw_reset_code' ? $self->users_pwresetcode_column
       :                              $column;

   # Search based on standard username search, plus any additional
   # conditions in ignore_user
   my $search = { %$user_valid_conditions, 'me.' . $search_column => $value };

   # Look up the user
   $self->schema->resultset( $self->users_resultset )->search( $search, $options );
}

sub authenticate_user {
   my ( $self, $username, $password, %options ) = @_;
   croak 'username and password must be defined'
       unless defined $username && defined $password;

   my ($user) = $self->_user_rset( 'username', $username )->all;
   return unless $user;

   if ( my $password_check = $self->users_password_check ) {

      # check password via result class method
      return $user->$password_check($password);
   }

   # OK, we found a user, let match_password (from our base class) take care of
   # working out if the password is correct
   my $password_column = $self->users_password_column;

   if ( my $match = $self->match_password( $password, $user->$password_column ) ) {
      if ( $options{lastlogin} ) {
         if ( my $lastlogin = $user->lastlogin ) {
            if ( ref($lastlogin) eq '' ) {

               # not inflated to DateTime
               my $db_parser = $self->schema->storage->datetime_parser;
               $lastlogin = $db_parser->parse_datetime($lastlogin);
            }

            # Stash in session as epoch since we don't want to have to mess
            # with with stringified data or perhaps session engine barfing
            # when trying to serialize DateTime object.
            $self->plugin->app->session->write( $options{lastlogin} => $lastlogin->epoch );
         }
         $self->set_user_details( $username, $self->users_lastlogin_column => DateTime->now, );
      }
      return $match;
   }
   return;                                      # Make sure we return nothing
}

sub set_user_password {
   my ( $self, $username, $password ) = @_;
   croak 'username and password must be defined'
       unless defined $username && defined $password;

   my $encrypted       = $self->encrypt_password($password);
   my $password_column = $self->users_password_column;
   my %update          = ( $password_column => $encrypted );
   if ( my $pwchanged = $self->users_pwchanged_column ) {
      $update{$pwchanged} = DateTime->now;
   }
   $self->set_user_details( $username, %update );
}

# Return details about the user.  The user's row in the users table will be
# fetched and all columns returned as a hashref.
sub get_user_details {
   my ( $self, $username ) = @_;
   croak 'username must be defined'
       unless defined $username;

   # Look up the user
   my $users_rs = $self->_user_rset( username => $username );

   # Inflate to a hashref, otherwise it's returned as a DBIC rset
   $users_rs->result_class('DBIx::Class::ResultClass::HashRefInflator')
       unless $self->user_as_object;

   my ($user) = $users_rs->all;

   if ( !$user ) {
      $self->plugin->app->log( 'debug', "No such user $username" );
      return;
   }

   if ( !$self->user_as_object ) {
      if ( my $roles_key = $self->roles_key ) {
         my @roles = @{ $self->get_user_roles($username) };
         my %roles = map { $_ => 1 } @roles;
         $user->{$roles_key} = \%roles;
      }
   }
   return $user;
}

# Find a user based on a password reset code
sub get_user_by_code {
   my ( $self, $code ) = @_;
   croak 'code needs to be specified'
       unless $code && $code ne '';

   my ($user) = $self->_user_rset( pw_reset_code => $code )->all;
   return unless $user;

   my $username_column = $self->users_username_column;
   return $user->$username_column;
}

sub create_user {
   my ( $self, %user ) = @_;
   my $username_column = $self->users_username_column;
   my $username        = delete $user{username};         # Prevent attempt to update wrong key
   croak 'Username not supplied in args'
       unless defined $username && $username ne '';

   $self->schema->resultset( $self->users_resultset )->create(
      {
         $username_column => $username
      }
   );
   $self->set_user_details( $username, %user );
}

# Update a user. Username is provided in the update details
sub set_user_details {
   my ( $self, $username, %update ) = @_;

   croak 'Username to update needs to be specified'
       unless $username;

   # Look up the user
   my ($user) = $self->_user_rset( username => $username )->all;
   $user or return;

   # Are we expecting a user_roles key?
   if ( my $roles_key = $self->roles_key ) {
      if ( my $new_roles = delete $update{$roles_key} ) {

         my $roles_role_column     = $self->roles_role_column;
         my $users_username_column = $self->users_username_column;

         my @all_roles = $self->schema->resultset( $self->roles_resultset )->all;
         my %existing_roles =
             map { $_ => 1 } @{ $self->get_user_roles($username) };

         foreach my $role (@all_roles) {
            my $role_name = $role->$roles_role_column;

            if ( $new_roles->{$role_name}
               && !$existing_roles{$role_name} )
            {
               # Needs to be added
               $self->schema->resultset( $self->user_roles_resultset )->create(
                  {
                     $self->user_relationship => {
                        $users_username_column => $username,
                        %{ $self->user_valid_conditions }
                     },
                     $self->role_relationship => {
                        $roles_role_column => $role_name
                     },
                  }
               );
            } elsif ( !$new_roles->{$role_name}
               && $existing_roles{$role_name} )
            {
               # Needs to be removed
               $self->schema->resultset( $self->user_roles_resultset )->search(
                  {
                     $self->user_relationship . ".$users_username_column" => $username,
                     $self->role_relationship . ".$roles_role_column"     => $role_name,
                  },
                  {
                     join => [ $self->user_relationship, $self->role_relationship ],
                  }
               )->delete;
            }
         }
      }
   }

   # Move password reset code between keys if required
   if ( my $users_pwresetcode_column = $self->users_pwresetcode_column ) {
      if ( exists $update{pw_reset_code} ) {
         my $pw_reset_code = delete $update{pw_reset_code};
         $update{$users_pwresetcode_column} = $pw_reset_code;
      }
   }
   $user->update( {%update} );

   # Update $username if it was submitted in update
   $username = $update{username} if $update{username};
   return $self->get_user_details($username);
}

sub get_user_roles {
   my ( $self, $username ) = @_;
   croak 'username must be defined'
       unless defined $username;

   my $role_relationship            = $self->role_relationship;
   my $user_user_roles_relationship = $self->user_user_roles_relationship;
   my $roles_role_column            = $self->roles_role_column;

   my $options = { prefetch => { $user_user_roles_relationship => $role_relationship } };

   my ($user) = $self->_user_rset( username => $username, $options )->all;

   if ( !$user ) {
      $self->plugin->app->log( 'debug', "No such user $username when looking for roles" );
      return;
   }

   my @roles;
   foreach my $ur ( $user->$user_user_roles_relationship ) {
      my $role = $ur->$role_relationship->$roles_role_column;
      push @roles, $role;
   }

   \@roles;
}

sub password_expired {
   my ( $self, $user ) = @_;
   croak 'user must be specified'
       unless defined $user
       && ( ref($user) eq 'HASH'
      || ( blessed($user) && $user->isa('DBIx::Class::Row') ) );

   my $expiry = $self->password_expiry_days or return 0;    # No expiry set

   if ( my $pwchanged = $self->users_pwchanged_column ) {
      my $last_changed = $self->user_as_object ? $user->$pwchanged : $user->{$pwchanged};

      # If not changed then report expired
      return 1 unless $last_changed;

      if ( ref($last_changed) ne 'DateTime' ) {

         # not inflated to DateTime by schema so do it now
         my $db_parser = $self->schema->storage->datetime_parser;
         $last_changed = $db_parser->parse_datetime($last_changed);
      }
      my $duration = $last_changed->delta_days( DateTime->now );
      $duration->in_units('days') > $expiry ? 1 : 0;
   } else {
      croak 'users_pwchanged_column not configured';
   }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::Auth::Extensible::Provider::DBIxClass - authenticate via the Dancer2::Plugin::DBIx:Class plugin

=head1 VERSION

version 0.0900

=head1 DESCRIPTION

This class is an authentication provider designed to authenticate users against
a database, using L<Dancer2::Plugin::DBIx::Class> to access a database.

See L<Dancer2::Plugin::DBIx::Class> for how to configure a database connection
appropriately; see the L</CONFIGURATION> section below for how to configure this
authentication provider with database details.

See L<Dancer2::Plugin::Auth::Extensible> for details on how to use the
authentication framework.

=head1 NAME 

Dancer2::Plugin::Auth::Extensible::Provider::DBIxClass - authenticate via the
L<Dancer2::Plugin::DBIx:Class> plugin

=head1 CONFIGURATION

This provider tries to use sensible defaults, in the same manner as
L<Dancer2::Plugin::Auth::Extensible::Provider::Database>, so you may not need
to provide much configuration if your database tables look similar to those.

The most basic configuration, assuming defaults for all options, and defining a
single authentication realm named 'users':

    plugins:
        Auth::Extensible:
            realms:
                users:
                    provider: 'DBIxClass'  # Note--no dash or '::' here!

You would still need to have provided suitable database connection details to
L<Dancer2::Plugin::DBIx::Class>, of course;  see the docs for that plugin for full
details, but it could be as simple as, e.g.:

    plugins:
        Auth::Extensible:
            realms:
                users:
                    provider: 'DBIxClass'   # Note--no dash or '::' here!
                    users_resultset: 'User'
                    roles_resultset: Role
                    user_roles_resultset: UserRole
        DBIx::Class:
            default:
                dsn: dbi:mysql:database=mydb;host=localhost
                schema_class: MyApp::Schema
                user: user
                password: secret

A full example showing all options:

    plugins:
        Auth::Extensible:
            realms:
                users:
                    provider: 'DBIxClass'   # Note--no dash or '::' here!

                    # Should get_user_details return an inflated DBIC row
                    # object? Defaults to false which will return a hashref
                    # inflated using DBIx::Class::ResultClass::HashRefInflator
                    # instead. This also affects what `logged_in_user` returns.
                    user_as_object: 1

                    # Optionally specify the DBIC resultset names if you don't
                    # use the defaults (as shown). These and the column names are the
                    # only settings you might need. The relationships between
                    # these resultsets is automatically introspected by
                    # inspection of the schema.
                    users_resultset: User
                    roles_resultset: Role
                    user_roles_resultset: UserRole

                    # optionally set the column names
                    users_username_column: username
                    users_password_column: password
                    roles_role_column: role

                    # This plugin supports the DPAE record_lastlogin functionality.
                    # Optionally set the column name:
                    users_lastlogin_column: lastlogin

                    # Optionally set columns for user_password functionality in
                    # Dancer2::Plugin::Auth::Extensible
                    users_pwresetcode_column: pw_reset_code
                    users_pwchanged_column:   # Time of reset column. No default.

                    # Days after which passwords expire. See logged_in_user_password_expired
                    # functionality in Dancer2::Plugin::Auth::Extensible
                    password_expiry_days:       # No default

                    # Optionally set the name of the DBIC schema
                    schema_name: myschema

                    # Optionally set additional conditions when searching for the
                    # user in the database. These are the same format as required
                    # by DBIC, and are passed directly to the DBIC resultset search
                    user_valid_conditions:
                        deleted: 0
                        account_request:
                            "<": 1

                    # Optionally specify a key for the user's roles to be returned in.
                    # Roles will be returned as role_name => 1 hashref pairs
                    roles_key: roles

                    # Optionally specify the algorithm when encrypting new passwords
                    encryption_algorithm: SHA-512

                    # Optional: To validate passwords using a method called
                    # 'check_password' in users_resultset result class
                    # which takes the password to check as a single argument:
                    users_password_check: check_password

=head2 But what about the C<::>?

L<Dancer2::Plugin::Auth::Extensible> insists that you either give it just the provider
name--which must be a single "word", not containing C<::>, or the full name of the module.
As module names cannot contain dashes, I chose C<DBIxClass> for the provider name; aren't
you glad I didn't make you type C<Dancer2::Plugin::Auth::Extensible::Provider::DBIx::Class>?

=over

=item user_as_object

Defaults to false.

By default a row object is returned as a simple hash reference using
L<DBIx::Class::ResultClass::HashRefInflator>. Setting this to true
causes normal row objects to be returned instead.

=item users_resultset

Defaults to C<User>.

Specifies the L<DBIx::Class::ResultSet> that contains the users.
The relationship to user_roles_source will be introspected from the schema.

=item roles_resultset

Defaults to C<Roles>.

Specifies the L<DBIx::Class::ResultSet> that contains the roles.
The relationship to user_roles_source will be introspected from the schema.

=item user_roles_resultset

Defaults to C<User>.

Specifies the L<DBIx::Class::ResultSet> that contains the user_roles joining table.
The relationship to the user and role source will be introspected from the schema.

=item users_username_column

Specifies the column name of the username column in the users table

=item users_password_column

Specifies the column name of the password column in the users table

=item roles_role_column

Specifies the column name of the role name column in the roles table

=item schema_name

Specfies the name of the L<Dancer2::Plugin::DBIx::Class> schema to use. If not
specified, will default in the same manner as the DBIx::Class plugin.

=item user_valid_conditions

Specifies additional search parameters when looking up a user in the users table.
For example, you might want to exclude any account this is flagged as deleted
or disabled.

The value of this parameter will be passed directly to DBIC as a search condition.
It is therefore possible to nest parameters and use different operators for the
condition. See the example config above for an example.

=item roles_key

Specifies a key for the returned user hash to also return the user's roles in.
The value of this key will contain a hash ref, which will contain each
permission with a value of 1. In your code you might then have:

    my $user = logged_in_user;
    return foo_bar($user);

    sub foo_bar
    {   my $user = shift;
        if ($user->{roles}->{beer_drinker}) {
           ...
        }
    }

This isn't intended to replace the L<Dancer2::Plugin::Auth::Extensible/user_has_role>
keyword. Instead it is intended to make it easier to access a user's roles if the
user hash is being passed around (without requiring access to the user_has_role
keyword in other modules).

=back

=head1 DEPRECATED SETTINGS

=over

=item user_source

=item user_table

Specifies the source name that contains the users. This will be camelized to generate
the resultset name. The relationship to user_roles_source will be introspected from
the schema.

=item role_source

=item role_table

Specifies the source name that contains the roles. This will be camelized to generate
the resultset name. The relationship to user_roles_source will be introspected from
the schema.

=item user_roles_source

=item user_roles_table

=back

Specifies the source name that contains the user_roles joining table. This will be
camelized to generate the resultset name. The relationship to the user and role
source will be introspected from the schema.

=head1 SUGGESTED SCHEMA

If you use a schema similar to the examples provided here, you should need minimal 
configuration to get this authentication provider to work for you.  The examples 
given here should be MySQL-compatible; minimal changes should be required to use 
them with other database engines.

=head2 user Table

You'll need a table to store user accounts in, of course. A suggestion is something 
like:

     CREATE TABLE user (
         id int(11) NOT NULL AUTO_INCREMENT,
		 username varchar(32) NOT NULL,
         password varchar(40) DEFAULT NULL,
         name varchar(128) DEFAULT NULL,
         email varchar(255) DEFAULT NULL,
         deleted tinyint(1) NOT NULL DEFAULT '0',
         lastlogin datetime DEFAULT NULL,
         pw_changed datetime DEFAULT NULL,
         pw_reset_code varchar(255) DEFAULT NULL,
         PRIMARY KEY (id)
     );

All columns from the users table will be returned by the C<logged_in_user> keyword 
for your convenience.

=head2 role Table

You'll need a table to store a list of available groups in.

	 CREATE TABLE role (
         id int(11) NOT NULL AUTO_INCREMENT,
         role varchar(32) NOT NULL,
         PRIMARY KEY (id)
     );

=head2 user_role Table

Also requred is a table mapping the users to the roles.

     CREATE TABLE user_role (
         user_id int(11) NOT NULL,
         role_id int(11) NOT NULL,
         PRIMARY KEY (user_id, role_id),
         FOREIGN KEY (user_id) REFERENCES user(id),
         FOREIGN KEY (role_id) REFERENCES role(id)
     );

=head1 SEE ALSO

L<Dancer2::Plugin::Auth::Extensible>

L<Dancer2::Plugin::DBIx::Class>

L<Dancer2::Plugin::Auth::Extensible::Provider::Database>

=head1 PRIOR WORK

This plugin is a fork of L<Dancer2::Plugin::Auth::Extensible::Provider::DBIC>, authored
by Andrew Beverley C<< <a.beverley@ctrlo.com> >>, with a rewrite for Plugin2 by
Peter Mottram, C<< <peter@sysnix.com> >>.

Forked by, and this fork maintained by:

D Ruth Holloway C<< <ruth@hiruthie.me> >>

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
