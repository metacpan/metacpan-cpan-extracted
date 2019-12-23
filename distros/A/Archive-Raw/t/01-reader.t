#!perl

use strict;
use warnings;
use Test::More;
use Archive::Raw;

my $entry;
my $reader = Archive::Raw::Reader->new();
isa_ok $reader, 'Archive::Raw::Reader';

done_testing;
