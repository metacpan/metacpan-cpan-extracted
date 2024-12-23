#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Daje::Workflow::Loader;

sub test_load() {
    my $loader = Daje::Workflow::Loader->new(
        path => '/home/jan/Project/Daje-Workflow-Loader/conf'
    )->load();

    return 1;
}

ok(test_load() == 1);

done_testing();

