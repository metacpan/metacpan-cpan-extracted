#!perl -T

use strict;
use warnings;

use Test::More tests => 3;

use B::RecDeparse;

my $cr = eval { B::RecDeparse::compile(deparse => '-sCi0v1', level => 1) };
is(defined $cr, 1, 'compile() returns a defined thingy');
is(ref $cr, 'CODE', 'compile() returns a code reference');
is($@, '', 'compile() re-evaluated without dieing');
