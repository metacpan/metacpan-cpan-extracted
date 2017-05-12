use 5.006;    # our
use strict;
use warnings;

package HTTP::Tiny::Mock;

our $VERSION = '0.001000';

# ABSTRACT: A mock HTTP::Tiny subclass that dispatches predefined files

# AUTHORITY

use HTTP::Tiny;
use Path::Tiny 0.070 qw( path );

our @ISA;
my $parent_new;

BEGIN {
    @ISA        = ('HTTP::Tiny');
    $parent_new = __PACKAGE__->can('new');
}

BEGIN {
    *new = sub {
        my ( $self, $file, @rest ) = @_;
        my $instance = $self->$parent_new(@rest);
        $instance->{ __PACKAGE__ . '-src' } = $file;
        $instance;
    };
}

sub mirror {
    my ( $self, $url, $target, $opts ) = @_;
    path( $self->{ __PACKAGE__ . '-src' } )->copy($target);
    return { status => 'success' };
}

sub request {
    die "Should not be called";
}

1;

