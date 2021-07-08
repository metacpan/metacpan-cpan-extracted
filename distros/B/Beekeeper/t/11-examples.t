#!/usr/bin/env perl -w

use strict;
use warnings;

BEGIN {
    use Cwd 'abs_path';
    my ($dir) = abs_path(__FILE__);
    ($dir) = $dir =~ m|(.*)/|;
    unshift @INC, "$dir/lib", "$dir/../lib";
}

use Tests::Examples;

Tests::Examples->runtests;
