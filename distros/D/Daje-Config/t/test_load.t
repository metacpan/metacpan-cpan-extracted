#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Daje::Config;

sub test_load() {
    my $loader = Daje::Config->new(
        path => '/home/jan/Project/Daje-Workflow-Loader/conf',
        type => 'workflow',
    )->load();

    return 1;
}

ok(test_load() == 1);

done_testing();

