#!/usr/bin/env perl

use strict;
use warnings;

use Acme::Sort::Sleep qw( sleepsort );
use Test::More;

my @empty    = ();
my @unsorted = qw( 3 1 3.337 0 );
my @sorted   = ();

@sorted = sleepsort( @empty );
is_deeply [ @sorted ], [ @empty ], "empty array";

@sorted = sleepsort( @unsorted );
is_deeply [ @sorted ], [ sort @unsorted ], "sorted array";

done_testing;
