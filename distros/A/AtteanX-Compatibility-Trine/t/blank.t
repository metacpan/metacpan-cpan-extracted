#!/usr/bin/env perl

use strict;
use Test::More;

use_ok('AtteanX::Compatibility::Trine');
use_ok('Attean::Blank');

can_ok('Attean::Blank', 'blank_identifier');

my $blank = Attean::Blank->new('dahut');

is($blank->blank_identifier, 'dahut', 'Blank roundtripped OK');

done_testing;
