#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN {
    use_ok ( 'Chart::OFC2::Types', qw( PositiveInt ChartOFC2Labels ) ) or exit;
}
