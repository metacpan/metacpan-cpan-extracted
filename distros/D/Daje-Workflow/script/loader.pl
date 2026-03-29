#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use Daje::Workflow::Loader;

sub test_load() {
    my $loader = Daje::Workflow::Loader->new(
        path => '/home/jan/Program/sentinel/workflows',
        type => => 'workflow',
    );

    $loader->load();
    print $loader->error() .'\n' if $loader->error();

    return 1;
}

test_load();