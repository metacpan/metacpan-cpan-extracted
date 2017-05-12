package CatalystX::Resource::TestKit;

use strict;
use warnings;
use Import::Into;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Test::More;
use Test::Warnings;

sub import {
    my $target = caller;
    Test::More->import::into($target);
    Test::Warnings->import::into($target, qw/ :all /);
    strict->import::into($target);
    warnings->import::into($target);
}

1;
