package Catalyst::Authentication::FromSub::User::Object;
our $VERSION = '0.01';

use strict;
use warnings;
use base qw/Catalyst::Authentication::User Class::Accessor::Fast/;

BEGIN {
    __PACKAGE__->mk_accessors(qw/config _user _roles _storage/);
}

sub new {
    my ( $class, $opts, $c ) = @_;

    my $self = {
        _storage => $opts->{storage},
        _user    => $opts->{user},
        _roles   => undef,
    };

    bless $self, $class;
}

my %features = ( session => 1, roles => { self_check => 0 } );

sub supported_features {
    my $self = shift;
    return \%features;
}

sub for_session {
    my $self = shift;

    my $config = $self->_storage->{config};
    my $id_field = $config->{id_field} || 'id';
    return { $id_field => $self->_user->$id_field };
}

sub from_session {
    my ( $self, $frozenuser, $c ) = @_;

    my $config = $self->_storage->{config};

    my $id;
    if ( ref($frozenuser) eq 'HASH' ) {
        $id = $frozenuser->{ $config->{'id_field'} };
    }
    else {
        $id = $frozenuser;
    }

    $self->_storage->find_user( { $config->{'id_field'} => $id }, $c );
}

sub get {
    my ( $self, $field ) = @_;

    if ( $self->_user->can($field) ) {
        return $self->_user->$field;
    }
    else {
        return undef;
    }
}

sub get_object {
    my ($self) = @_;
    return $self->_user;
}

sub obj {
    my $self = shift;
    return $self->get_object(@_);
}

sub AUTOLOAD {
    my $self = shift;

    ( my $method ) = ( our $AUTOLOAD =~ /([^:]+)$/ );

    return if $method eq "DESTROY";

    confess(
        "Could not call method $method on class " . blessed( $self->_user ) )
      unless $self->_user->can($method);
    $self->_user->$method;
}

1;
__END__

=head1 NAME

Catalyst::Authentication::FromSub::User::Object

=head1 VERSION

version 0.01

=head1 AUTHOR

  Fayland Lam <fayland@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.
