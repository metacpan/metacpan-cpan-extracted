# -*- Mode: Python -*-

use strict;
use warnings;

use Test::More 'no_plan';
use Acme::Pythonic;

# ----------------------------------------------------------------------

my $loaded = 0
eval:
    require FindBin;
    $loaded = 1

is $loaded, 1

# ----------------------------------------------------------------------

$loaded = 0
eval:
    die
    $loaded = 1

is $loaded, 0