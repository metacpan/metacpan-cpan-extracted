package Catalyst::Authentication::Store::Jifty::DBI;

use strict;
use warnings;
use base qw( Class::Accessor::Fast );
use Catalyst::Utils;

our $VERSION = '0.03';

BEGIN { __PACKAGE__->mk_accessors(qw( config )); }

sub new {
  my ($class, $config, $app) = @_;

  $config->{store_user_class} ||= __PACKAGE__.'::User';

  Catalyst::Utils::ensure_class_loaded( $config->{store_user_class} );
  bless { config => $config }, $class;
}

sub _new_user {
  my ($self, $c) = @_;

  my $user_class = $self->config->{store_user_class};
     $user_class->new( $self->config, $c );
}

sub from_session {
  my ($self, $c, $frozen_user) = @_;

  my $user_class = $self->config->{store_user_class};
  my $user       = $user_class->new( $self->config, $c );

  return $user->from_session( $frozen_user, $c );
}

sub for_session {
  my ($self, $c, $user) = @_;

  return $user->for_session($c);
}

sub find_user {
  my ($self, $auth_info, $c) = @_;

  my $user_class = $self->config->{store_user_class};
  my $user       = $user_class->new( $self->config, $c );

  return $user->load( $auth_info, $c );
}

sub user_supports {
  my $self = shift;

  $self->config->{store_user_class}->supports(@_);
}

sub auto_create_user {
  my ($self, $auth_info, $c) = @_;

  my $user_class = $self->config->{store_user_class};
  my $user       = $user_class->new( $self->config, $c );

  return $user->auto_create( $auth_info, $c );
}

sub auto_update_user {
  my ($self, $auth_info, $c, $user) = @_;

  $user->auto_update( $auth_info, $c );

  return $user;
}

1;

__END__

=head1 NAME

Catalyst::Authentication::Store::Jifty::DBI - A storage class for Catalyst Authentication using Jifty::DBI

=head1 SYNOPSIS

    use Catalyst qw( Authentication Authorization::Roles );

    __PACKAGE__->config->{authentication} = {
      default_realm => 'members',
      realms => {
        members => {
          credential => {
            class          => 'Password',
            password_field => 'password',
            password_type  => 'clear',
          },
          store => {
            class         => 'Jifty::DBI',
            user_class    => 'MyDB::User',
            role_relation => [qw( roles role_map role )],
          },
        },
      },
    };

    sub login : Global {
      my ($self, $c) = @_;

      $c->authenticate({
        username => $c->req->params->{username},
        password => $c->req->params->{password},
        status   => [ 'registered', 'loggedin', 'active' ],
      });
    }

    sub edit : Path {
      my ($self, $c) = @_;

      # verify a role
      if ( $c->check_user_roles('editor') ) {
        # do some editorial things
      }
    }

=head1 DESCRIPTION

This Jifty::DBI store class is a rough port of Catalyst::Authentication::Store::DBIx::Class. See L<Catalyst::Authentication::Store::DBIx::Class> and L<Catalyst::Plugin::Authentication> for what I'm too lazy to explain.

=head1 CONFIGURATION

Almost the same as ::Store::DBIx::Class, with a few changes. See SYNOPSIS for common usage. To activate this authentication store, set B<class> element in the store config to 'Jifty::DBI'.

    __PACKAGE__->config->{authentication} = {
      default_realm => 'members',
      realms => {
        members => {
          credential => {
            # ...
          },
          store => {
            class         => 'Jifty::DBI',
            user_class    => 'MyDB::User',
            role_relation => [qw( roles link_to_role role )],
          },
        },
      },
    };

There are several configurable options:

=over 4

=item class

should be set to 'Jifty::DBI' to activate this store.

=item user_class

must contain the moniker (the class name which would be passed to $c->model(...) ) to retrieve user information. You can set either the one for a record or the one for a collection (both of which would be converted internally). If you dare, you also can set I<record_class> and/or I<collection_class> as you wish.

=item role_column

If your role information is stored in the same table as the rest of your user information, set this to show which column contains your role information. The value in this column is expected to be a series of role names separated by some combination of white spaces, commas, or pipe characters.

=item role_relation

NOTE: this option is different from the one of L<Catalyst::Authentication::Store::DBIx::Class>. 

If your role information is stored in a separate table, set this to an array reference of the method chain to retrieve role information from a user record. That means: if your user class has a 'roles' collection, and each of whose record is linked to your role class via 'link_to_role' column, and your role class has a 'role' column, then set this as shown above.

=item use_userdata_from_session

If this flag is set to true, the data for the user object is retrieved from a restored hash (instead of the user table in the database).

=back

=head1 USAGE

Normally, all you need to do is pass enough pairs of column/value to $c->authenticate() to find an (rather, the only one) appropriate user. All the conditions should be satisfied ("and" conditions).

  if (
    $c->authenticate({
      username => $c->req->params->{username},
      password => $c->req->params->{password},
      status   => [ 'registered', 'active', 'loggedin' ],
    })
  ) {
    # ... authenticated user code here
  }

If you want finer control, namely when you want "or" conditions, you can pass either of the extra (advanced) arguments. These advanced arguments should be placed under the "jifty_dbi" key for this purpose.

You can put arbitrary arguments (an array reference of hash references) under the "limit_args", each of which would then be passed to $user_collection->limit(). Use "subclause" for "or" conditions. See L<Jifty::Manual::Cookbook> for details.

  if (
    # this makes "WHERE (username = ?) or (email = ?)" kind of clause

    $c->authenticate({
      password  => $c->req->params->{password},
      jifty_dbi => {
        limit_args => [{
          column    => 'username',
          value     => $c->req->params->{username},
          subclause => 'or_condition',
        },
        {
          column    => 'email',
          value     => $c->req->params->{email},
          subclause => 'or_condition',
        }],
      }
    })
  ) {
    # ... authenticated user code here
  }

If you want much finer control, you can pass pre-configured collection object.

  my $collection = $c->model('MyDB::User');

  # do whatever you want with this $collection

  if (
    $c->authenticate({
      password  => $c->req->params->{password},
      jifty_dbi => { collection => $collection },
    })
  ) {
    # ... authenticated user code here
  }

NOTE: When multiple users are found, $c->user holds the "first" one (retrieved by $collection->first).

=head1 METHODS

Most of these are used internally while authenticating/authorizing and usually you don't need to care.

=head2 new

creates a store object.

=head2 find_user

finds a user with provided auth information.

=head2 from_session

revives a user from the session.

=head2 for_session

stores a user for the session.

=head2 user_supports

shows what this store supports.

=head2 auto_create_user

will be called if you set the realm's "auto_update_user" setting.

=head2 auto_update_user

will be called if you set the realm's "auto_create_user" setting.

=head1 SEE ALSO

L<Catalyst::Plugin::Authentication>,
L<Catalyst::Authentication::Store::DBIx::Class>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
