package t::RelegateManager;
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
    push @{$ENV{TEST_BASE_MANAGER}}, 'relegate';
    $self->relegate('base');
}

1;
