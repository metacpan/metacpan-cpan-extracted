#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 4;

use constant ADT => 'Acme::DarmstadtPM::TieHash';

use_ok(ADT);

tie my %hash,ADT,sub{$_[0] + $_[-1]};

is($hash{[1,5]},6,'Check [1,5]');
is($hash{[1,5]},6,'Check [1,5] - second call');
is($hash{[2,3,5]},7,'Check [2,3,5]');

untie %hash;


