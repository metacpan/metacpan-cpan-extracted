package Catalyst::Authentication::Store::Jifty::DBI::User;

use strict;
use warnings;
use Carp;
use base qw( Catalyst::Authentication::User );
use Scalar::Util qw( blessed );

BEGIN { __PACKAGE__->mk_accessors(qw( config _user _roles )); }

sub new {
  my ($class, $config, $c) = @_;

  my $user_class = $config->{user_class}
       or croak "user_class is missing";
     $user_class =~ s/Collection$//;

  $config->{record_class}     ||= $user_class;
  $config->{collection_class} ||= $user_class.'Collection';

  my $self = bless {
    config => $config,
    _roles => undef,
    _user  => undef,
  }, $class;
}

sub load {
  my ($self, $auth_info, $c) = @_;

  my $jdbi_conf = {};
  if ( exists $auth_info->{jifty_dbi} ) {
    $jdbi_conf = $auth_info->{jifty_dbi};
  }

  my $collection;
  if ( $jdbi_conf->{collection} ) {
    $collection = $jdbi_conf->{collection};
  }
  elsif ( my $args = $jdbi_conf->{limit_args} ) {
    $collection = $c->model( $self->config->{collection_class} );
    if ( ref $args eq 'HASH' ) {
      $args = [ $args ];
    }
    foreach my $arg ( @{ $args } ) {
      $collection->limit( %{ $arg } );
    }
  }
  else {
    $collection = $c->model( $self->config->{collection_class} );
    foreach my $column ( keys %{ $auth_info } ) {
      next unless defined $auth_info->{$column};
      next if     blessed $auth_info->{$column}; # relationship
      $collection->limit(
        column => $column,
        value  => $auth_info->{$column},
      );
    }
  }
  return unless $collection;

  my $user = $collection->first;

  $self->_user( $user ) if blessed $user;

  return $self->get_object ? $self : undef;
}

sub supported_features {
  my $self = shift;

  return {
    session => 1,
    roles   => 1,
  };
}

sub roles {
  my $self = shift;

  if ( ref $self->_roles eq 'ARRAY' ) {
    return @{ $self->_roles };
  }

  my @roles;
  if ( $self->config->{role_column} ) {
    my $role_data = $self->get( $self->config->{role_column} );
    if ( $role_data ) {
      @roles = split /[ ,\|]+/, $role_data;
    }
    $self->_roles( \@roles );
    return @roles;
  }
  elsif ( ref $self->config->{role_relation} eq 'ARRAY' ) {
    my @columns = @{ $self->config->{role_relation} };
    if ( @columns == 3 ) {
      my ($roles_column, $link_column, $role_column) = @columns;
      eval {
        my $collection = $self->_user->$roles_column;
        while ( my $record = $collection->next ) {
          push @roles, $record->$link_column->$role_column;
        }
        $self->_roles( \@roles );
      };
      croak "illegal role_relation configuration: $@" if $@;
      return @roles;
    }
  }

  croak "illegal role configuration";
}

sub for_session {
  my $self = shift;

  my %user_data = $self->_user->as_hash;
  return \%user_data;
}

sub from_session {
  my ($self, $frozen_user, $c) = @_;

  if ( $self->config->{use_userdata_from_session} ) {
    my $user = $c->model( $self->config->{record_class} );
       $user->load_from_hash( %{ $frozen_user } );
    $self->_user( $user );

    return $self;
  }
  else {
    return $self->load( $frozen_user, $c );
  }
}

sub get {
  my ($self, $field) = @_;

  return $self->_user ? $self->_user->_value( $field ) : undef;
}

sub get_object {
  my ($self, $force) = @_;

  $self->_user;
}

sub obj {
  my ($self, $force) = @_;

  $self->get_object( $force );
}

sub auto_create {
  my ($self, $auth_info, $c) = @_;

  my $user = $c->model( $self->config->{record_class} );
     $user->create( %{ $auth_info } );
  $self->_user( $user );

  return $self;
}

sub auto_update {
  my ($self, $auth_info, $c) = @_;

  my $user = $self->_user;

  $user->_handle->begin_transaction;
  eval {
    foreach my $column ( keys %{ $auth_info } ) {
      next unless defined $auth_info->{$column};
      next if     blessed $auth_info->{$column}; # relationship
      $user->_set( column => $column, value => $auth_info->{$column} );
    }
  };
  $@ ? $user->_handle->rollback : $user->_handle->commit;
}

sub AUTOLOAD {
  my $self = shift;
  my ($method) = (our $AUTOLOAD =~ /([^:]+)$/);
  return if $method eq 'DESTROY';

  $self->_user->$method(@_);
}

1;

__END__

=head1 NAME

Catalyst::Authentication::Store::Jifty::DBI::User

=head1 DESCRIPTION

Used internally to do the actual tasks to retrieve/store information.

=head1 METHODS

=head2 new

creates an object.

=head2 load

retrieves a user from storage with the provided information.

=head2 supported_features

shows the supported features, currently Roles and Session.

=head2 roles

returns an array of roles associated with the user.

=head2 from_session

restores the user from a hash reference from the session

=head2 for_session

returns a hash reference of the user data to store.

=head2 get

returns the value of the given column.

=head2 get_object, obj

returns the user object.

=head2 auto_create

creates a user automatically from the auth_info.

=head2 auto_update

updates the user automatically from the auth_info.

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
