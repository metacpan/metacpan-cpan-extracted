package t::ForwardBaseManager;
use strict;

use Ambrosia::Meta;
class
{
    extends => [qw/Ambrosia::BaseManager/]
};

sub prepare
{
    $ENV{TEST_BASE_MANAGER} ||= [];
    push @{$ENV{TEST_BASE_MANAGER}}, 'forward_base';
}

1;
