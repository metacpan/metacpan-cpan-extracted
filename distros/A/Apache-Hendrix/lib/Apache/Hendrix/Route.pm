package Apache::Hendrix::Route;

# $Id$

use v5.10.0;
use warnings;
use strict;
use Carp;
use Moose;
use MooseX::FollowPBP;
use version; our $VERSION = qv(0.1.0);

has 'path'   => ( isa => 'Str | RegexpRef', is => 'rw', required => 1 );
has 'base'   => ( isa => 'Str | RegexpRef', is => 'rw', required => 1 );
has 'module' => ( isa => 'Maybe[Str]',      is => 'rw', required => 0 );
has 'method' => ( isa => 'CodeRef',         is => 'rw', required => 1 );

# Route Helper Methods

sub BUILD {
    my ($self) = @_;
    my $base = $self->get_base;

    # If we aren't given a regexp, see if we need to make one.
    if ( !ref( $self->get_path ) ) {
        my $regexp = $self->build_regexp( $self->get_path );

        # If we've been modified, we're now a regexp
        if ( $regexp ne $self->get_path ) {
            $self->set_path($regexp);
        }
    }

    # Keep track of who owns this route
    $self->set_module( $ENV{module} );

    return;
}

sub build_regexp {
    my ( $self, $pattern ) = @_;

    if ( $pattern =~ m{:([^/]+)} ) {
        $pattern =~ s{:([^/]+)}{(?<$1>[^/]+)}g;
        return qr/$pattern/;
    }

    return $pattern;
}

__PACKAGE__->meta->make_immutable;

1;
