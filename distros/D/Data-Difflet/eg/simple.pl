#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;

use Data::Difflet;

my $difflet = Data::Difflet->new();
print $difflet->compare(
    {
        a => 2,
        c => 5,
    },
    {
        a => 3,
        b => 4,
    }
);
