package Bintray::API::Package;

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
  repo
  session
);

#######################
# LOAD DIST MODULES
#######################
use Bintray::API::Session;
use Bintray::API::Version;

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
            repo => {
                type => OBJECT,
                isa  => 'Bintray::API::Repo',
            },
        },
    );

  return $class->SUPER::new(%opts);
} ## end sub new

## Version Object
sub version {
    my ( $self, @args ) = @_;

    my %opts = validate_with(
        params => [@args],
        spec   => {
            name => {
                type => SCALAR,
            },
        },
    );

  return Bintray::API::Version->new(
        session => $self->session(),
        package => $self,
        name    => $opts{name},
    );
} ## end sub version

#######################
# API METHODS
#######################

## Package Info
sub info {
    my ($self) = @_;
  return $self->session()->talk(
        path => join( '/',
            'packages',            $self->repo()->subject()->name(),
            $self->repo()->name(), $self->name(),
        ),
        anon => 1,
    );
} ## end sub info

## Update Package
sub update {
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
        method => 'PATCH',
        path   => join( '/',
            'packages',            $self->repo()->subject()->name(),
            $self->repo()->name(), $self->name(),
        ),
        content => $json,
    );
} ## end sub update

## Create Version
sub create_version {
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
        path   => join( '/',
            'packages',            $self->repo()->subject()->name(),
            $self->repo()->name(), $self->name(),
            'versions', ),
        content => $json,
    );
} ## end sub create_version

## Delete version
sub delete_version {
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
            'packages',            $self->repo()->subject()->name(),
            $self->repo()->name(), $self->name(),
            'versions',            $opts{name},
        ),
    );
} ## end sub delete_version

## Get Attributes
sub get_attributes {
    my ( $self, @args ) = @_;

    my %opts = validate_with(
        params => [@args],
        spec   => {
            names => {
                type    => ARRAYREF,
                default => [],
            },
        },
    );

  return $self->session->talk(
        path => join( '/',
            'packages',            $self->repo()->subject()->name(),
            $self->repo()->name(), $self->name(),
            'attributes', ), (
            defined $opts{names}
            ? (
                query => [
                    {
                        names => join( ',', @{ $opts{names} } ),
                    },
                ],
              )
            : (),
        ),
    );
} ## end sub get_attributes

# Set Attributes
sub set_attributes {
    my ( $self, @args ) = @_;

    my %opts = validate_with(
        params => [@args],
        spec   => {
            attributes => {
                type => ARRAYREF,
            },
            update => {
                type    => BOOLEAN,
                default => 0,
            },
        },
    );

    # Create JSON
    my $json = $self->session()->json()->encode( $opts{attributes} );

    # POST
  return $self->session()->talk(
        method => $opts{update} ? 'PATCH' : 'POST',
        path => join( '/',
            'packages',            $self->repo()->subject()->name(),
            $self->repo()->name(), $self->name(),
            'attributes', ),
        content => $json,
    );
} ## end sub set_attributes

## Update Attributes
sub update_attributes { return shift->set_attributes( @_, update => 1, ); }

## Add WebHook
sub set_webhook {
    my ( $self, @args ) = @_;

    my %opts = validate_with(
        params => [@args],
        spec   => {
            url    => { type => SCALAR },
            method => {
                type    => SCALAR,
                default => 'post',
                regex   => qr{^(?:post|put|get)$}xi,
            }
        },
    );

  return $self->session->talk(
        method => 'POST',
        path   => join( '/',
            'webhooks',            $self->repo()->subject()->name(),
            $self->repo()->name(), $self->name(),
        ),
        wantheaders => 1,
    );
} ## end sub set_webhook

## Delete webhook
sub delete_webhook {
    my ($self) = @_;
  return $self->session->talk(
        method => 'DELETE',
        path   => join( '/',
            'webhooks',            $self->repo()->subject()->name(),
            $self->repo()->name(), $self->name(),
        ),
    );
} ## end sub delete_webhook

#######################
1;

__END__
