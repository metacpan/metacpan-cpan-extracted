#! /usr/bin/env perl

use strict;
use warnings;
use Test::More 0.88;
use Data::Dumper;

my $program    = "$^X -Ilib bin/dpath";
my $infile     = "t/testdata.taparchive";

my $dumper = `$program -i taparchive -o dumper / $infile`;
my $VAR1;
eval $dumper;

#diag Dumper($VAR1->[0]);

# meta
is(scalar @{$VAR1->[0]{meta}{file_order}}, 1, 'meta file count');
is($VAR1->[0]{meta}{file_order}[0], 'testdata.tap', 'meta file_order');

# dom
is(scalar(@{$VAR1->[0]{dom}[0]{lines}}), 11, 'tap::dom count lines');
is($VAR1->[0]{dom}[0]{pragmas}[0], 'strict', 'tap::dom pragmas');
is($VAR1->[0]{dom}[0]{lines}[1]{as_string}, '1..6', 'tap::dom plan');
is($VAR1->[0]{dom}[0]{tests_planned}, 6, 'tap::dom tests_planned');
   
done_testing;
