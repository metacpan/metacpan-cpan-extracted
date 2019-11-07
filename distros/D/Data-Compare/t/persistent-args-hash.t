#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

use Data::Compare;
use Test::More;

local $Data::Dumper::Indent = 1;
local $Data::Dumper::Terse = 1;
local $Data::Dumper::Sortkeys = 1;

my @elements = (
    { foo => 'always' },
    { foo => 'always' },
    { foo => 'always', bar => 'sometimes' }
);

my $want = { foo => 'always' };
my @matching_no_args= grep { Data::Compare::Compare($_, $want) } @elements;
is(scalar @matching_no_args, 2, 'Just the two matching elements without args')
    or diag(Dumper(@matching_no_args));


my %args;
my @matching_args
    = grep { Data::Compare::Compare($_, $want, \%args) } @elements;
is(scalar @matching_args,
    2, 'Just the two matching elements when passed a consistent hashref')
    or diag(Dumper(@matching_args));

done_testing();
