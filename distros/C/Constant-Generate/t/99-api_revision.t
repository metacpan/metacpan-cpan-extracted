#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Constant::Generate [qw(FOO)],
    dualvar => 1, -prefix => 'STR_';
    
ok(STR_FOO == 0 && STR_FOO eq 'FOO',
   "dualvar option");

use Constant::Generate::Dualvar [qw(GRR GAH)],
    prefix => 'STR_';
    
ok(STR_GRR == 0 && STR_GRR eq 'GRR',
   "Constant::Generate::Dualvar");

use Constant::Generate::Stringified [qw(MEH)], prefix => 'STR_';

ok(STR_MEH == 0 && STR_MEH eq 'MEH',
   "Constant::Generate::Stringified back-compat");

done_testing();