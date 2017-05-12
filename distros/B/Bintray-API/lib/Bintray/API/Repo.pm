package Bintray::API::Repo;

#######################
# LOAD CORE MODULES
#######################
use strict;
use warnings FATAL => 'all';
use Carp qw(croak carp);

#######################
# VERSION
#######################
our $VERSION = '1.0.2';

#######################
# LOAD CPAN MODULES
#######################
use Params::Validate qw(validate_with :types);

use Object::Tiny qw(
  name
  session
  subject
);

#######################
# LOAD DIST MODULES
#######################
use Bintray::API::Package;
use Bintray::API::Session;

#######################
# PUBLIC METHODS
#######################

## Constructor
sub new {
    my ( $class, @args ) = @_;

    my %opts = validate_with(
        params => [@args],
        spec   => {
            session => {
                type => OBJECT,
                isa  => 'Bintray::API::Session',
            },
            name => {
                type => SCALAR,
            },
            subject => {
                type => OBJECT,
                isa  => 'Bintray::API::Subject',
            },
        },
    );

  return $class->SUPER::new(%opts);
} ## end sub new

## Package Object
sub package {
    my ( $self, @args ) = @_;

    my %opts = validate_with(
        params => [@args],
        spec   => {
            name => {
                type => SCALAR,
            },
        },
    );

  return Bintray::API::Package->new(
        session => $self->session(),
        repo    => $self,
        name    => $opts{name},
    );
} ## end sub package

#######################
# API METHODS
#######################

## Repo Info
sub info {
    my ( $self, @args ) = @_;
  return $self->session()->talk(
        path => join( '/', 'repos', $self->subject()->name(), $self->name() ),
        anon => 1,
    );
} ## end sub info

## Packages
sub packages {
    my ( $self, @args ) = @_;

    my %opts = validate_with(
        params => [@args],
        spec   => {
            prefix => {
                type    => SCALAR,
                default => '',
            },
        },
    );

  return $self->session()->talk(
        path => join( '/',
            'repos', $self->subject()->name(),
            $self->name(), 'packages' ),
        anon => 1, (
            $opts{prefix}
            ? ( query => [ { start_name => $opts{prefix} } ] )
            : (),
        ),
    );
} ## end sub packages

## Create Package
sub create_package {
    my ( $self, @args ) = @_;

    my %opts = validate_with(
        params => [@args],
        spec   => {
            details => {
                type => HASHREF,
            },
        },
    );

    # Create JSON
    my $json = $self->session()->json()->encode( $opts{details} );

    # POST
  return $self->session()->talk(
        method => 'POST',
        path =>
          join( '/', 'packages', $self->subject()->name(), $self->name(), ),
        content => $json,
    );
} ## end sub create_package

## Delete Package
sub delete_package {
    my ( $self, @args ) = @_;

    my %opts = validate_with(
        params => [@args],
        spec   => {
            name => {
                type => SCALAR,
            },
        },
    );

  return $self->session()->talk(
        method => 'DELETE',
        path   => join( '/',
            'packages',    $self->subject()->name(),
            $self->name(), $opts{name},
        ),
    );
} ## end sub delete_package

## Get Webhooks
sub get_webhooks {
    my ($self) = @_;
  return $self->session->talk(
        path =>
          join( '/', 'webhooks', $self->subject()->name(), $self->name() ),
    );
} ## end sub get_webhooks

#######################
# API HELPERS
#######################

## Package name
sub package_names {
    my ($self) = @_;
    my $resp = $self->packages() or return;
    my @packages = map { $_->{name} } @{$resp};
  return @packages;
} ## end sub package_names

#######################
1;

__END__
