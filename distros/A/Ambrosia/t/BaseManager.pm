package t::BaseManager;
use strict;

use Ambrosia::Meta;
class
{
    extends => [qw/Ambrosia::BaseManager/]
};

sub prepare
{
    $ENV{TEST_BASE_MANAGER} ||= [];
    push @{$ENV{TEST_BASE_MANAGER}}, 'base';
}

1;
