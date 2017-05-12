use strict;
use warnings;

package Badge::Depot::Plugin::Afakebadge;

use Moose;
use namespace::autoclean;
use MooseX::AttributeShortcuts;
use Types::Standard qw/Str Bool/;
with 'Badge::Depot';

has username => (
    is => 'ro',
    isa => Str,
);
has repo => (
    is => 'ro',
    isa => Str,
);
has alt_text => (
    is => 'ro',
    isa => Str,
    predicate => 1,
);
has dont_link => (
    is => 'ro',
    isa => Bool,
    default => 0,
);

sub BUILD {
    my $self = shift;
    $self->link_url(sprintf q{https://travis-ci.org/%s/%s}, $self->username, $self->repo) if !$self->dont_link;
    $self->image_url(sprintf q{https://travis-ci.org/%s/%s.svg?branch=master}, $self->username, $self->repo);
    $self->image_alt($self->alt_text) if $self->has_alt_text;
}

1;
