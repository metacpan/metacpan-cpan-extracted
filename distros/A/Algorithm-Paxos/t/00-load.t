#!/usr/bin/env perl
use strict;
use Test::More;
use File::Find;

find(
    sub {
        m/\.pm/ or return;
        my $_ = $File::Find::name;
        s|/|::|g;
        s/^lib:://;
        s/.pm$//;
        ::use_ok($_);
    },
    'lib/'
);

done_testing;
