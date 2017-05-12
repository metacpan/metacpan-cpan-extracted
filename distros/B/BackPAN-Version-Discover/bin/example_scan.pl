#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;

use BackPAN::Version::Discover;

my $bvd = BackPAN::Version::Discover->new();

# exclude relative dirs and anything under $HOME
my @dirs = grep { ! /^$ENV{HOME}|^[^\/]/ } @INC;

# this may take some time and use lots of ram and/or CPU
my $results = $bvd->scan( dirs => \@dirs );

print Dumper($results);

