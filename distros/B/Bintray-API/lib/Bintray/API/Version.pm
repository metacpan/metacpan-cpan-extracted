package Bintray::API::Version;

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
  package
);

#######################
# LOAD DIST MODULES
#######################
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
            package => {
                type => OBJECT,
                isa  => 'Bintray::API::Package',
            },
        },
    );

  return $class->SUPER::new(%opts);
} ## end sub new

#######################
# API METHODS
#######################

## Info
sub info {
    my ($self) = @_;
  return $self->session()->talk(
        path => join( '/',
            'packages',                 $self->package->repo->subject->name,
            $self->package->repo->name, $self->package->name,
            'versions',                 $self->name,
        ),
    );
} ## end sub info

## Update Version
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
            'packages',                 $self->package->repo->subject->name,
            $self->package->repo->name, $self->package->name,
            'versions',                 $self->name,
        ),
        content => $json,
    );
} ## end sub update

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
            'packages',                 $self->package->repo->subject->name,
            $self->package->repo->name, $self->package->name,
            'versions',                 $self->name,
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
            'packages',                 $self->package->repo->subject->name,
            $self->package->repo->name, $self->package->name,
            'versions',                 $self->name,
            'attributes', ),
        content => $json,
    );
} ## end sub set_attributes

## Update Attributes
sub update_attributes { return shift->set_attributes( @_, update => 1, ); }

## Test WebHook
sub test_webhook {
    my ($self) = @_;
  return $self->session()->talk(
        method => 'POST',
        path   => join( '/',
            'webhooks',                 $self->package->repo->subject->name,
            $self->package->repo->name, $self->package->name,
            'versions',                 $self->name,
        ),
        wantheaders => 1,
    );
} ## end sub test_webhook

## Upload
sub upload {
    my ( $self, @args ) = @_;

    my %opts = validate_with(
        params => [@args],
        spec   => {
            file => {
                type => SCALAR,
            },
            repo_path => {
                type => SCALAR,
            },
            publish => {
                type    => BOOLEAN,
                default => 0,
            },
            explode => {
                type    => BOOLEAN,
                default => 0,
            },
        },
    );

    # Read File contents
    my $file_contents;
    open( my $fh, '<:raw', $opts{file} )
      or croak "ERROR: Failed to open $opts{file} to read!";
    my $fs = -s $fh;
    read( $fh, $file_contents, $fs );
    close($fh);

    # Cleanup Repo Path
    $opts{repo_path} =~ s{^\/}{}xi;

    # Upload
  return $self->session->talk(
        method => 'PUT',
        path   => join( '/',
            'content',                  $self->package->repo->subject->name,
            $self->package->repo->name, $self->package->name,
            $self->name,                $opts{repo_path},
        ),
        content => $file_contents,
        params  => [

            # Publish?
            ( defined $opts{publish} ? { publish => $opts{publish} } : (), ),

            # Explode?
            ( defined $opts{explode} ? { explode => $opts{explode} } : (), ),
        ],
    );
} ## end sub upload

## Publish files
sub publish {
    my ( $self, @args ) = @_;

    my %opts = validate_with(
        params => [@args],
        spec   => {
            discard => {
                type    => BOOLEAN,
                default => 0,
            },
        },
    );

  return $self->session->talk(
        method => 'POST',
        path   => join( '/',
            'content',                  $self->package->repo->subject->name,
            $self->package->repo->name, $self->package->name,
            $self->name,                'publish',
        ), (
            # Check for discard
            $opts{discard}
            ? ( content =>
                  $self->session->json->encode( { discard => 'true' } ) )
            : (),
        ),
    );
} ## end sub publish

## Discard files
sub discard { return shift->publish( @_, discard => 1, ); }

## Sign a Version
sub sign {
    my ( $self, @args ) = @_;
    my %opts = validate_with(
        params => [@_],
        spec   => {
            passphrase => {
                type    => SCALAR,
                default => '',
            },
        },
    );

  return $self->session()->talk(
        method => 'POST',
        path   => join( '/',
            'gpg',                      $self->package->repo->subject->name,
            $self->package->repo->name, $self->package->name,
            'versions',                 $self->name,
        ), (
            $opts{passphrase}
            ? (
                query => [
                    {
                        passphrase => $opts{passphrase},
                    },
                ],
              )
            : (),
        ),
    );
} ## end sub sign

#######################
1;

__END__
