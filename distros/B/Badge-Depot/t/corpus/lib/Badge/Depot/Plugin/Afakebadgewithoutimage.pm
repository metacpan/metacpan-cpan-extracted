use strict;
use warnings;

package Badge::Depot::Plugin::Afakebadgewithoutimage;

use Moose;
use namespace::autoclean;
use MooseX::AttributeShortcuts;
use Types::Standard qw/Str Bool/;
with 'Badge::Depot';

has username => (
    is => 'ro',
    isa => Str,
);

sub BUILD {
    my $self = shift;
    $self->link_url(sprintf q{https://travis-ci.org/%s}, $self->username);
}

1;
