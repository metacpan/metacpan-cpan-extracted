package t::ForwardManager;
use strict;

use Ambrosia::Meta;
class
{
    extends => [qw/Ambrosia::BaseManager/]
};

sub prepare
{
    my $self = shift;
    $ENV{TEST_BASE_MANAGER} ||= [];
    push @{$ENV{TEST_BASE_MANAGER}}, 'forward';
    $self->relegate('base');

    $self->forward('forward_base');
}

1;
