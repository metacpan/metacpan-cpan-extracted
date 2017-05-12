use strict;
use Data::Dumper;
use Test::More tests => 2;

my $t;

BEGIN { use_ok('Anarres::Mud::Driver::Compiler::Type', ':all'); }

ok(M_EFUN, 'M_EFUN is a valid flag');
