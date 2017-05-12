#!perl -w

use strict;
use Test::More tests => 10;

use Acme::Perl::VM;
use Acme::Perl::VM qw(:perl_h);

is_deeply [run_block{ my(@a, $b) = (1, 2, 3); (\@a, $b) }], [[1, 2, 3], undef];
is_deeply [run_block{ my($a, @b) = (1, 2, 3); ($a, \@b) }], [1, [2, 3]];

is_deeply [run_block{ my($a, $b) = (10, 20); ($b, $a) = ($a, $b); ($a, $b) }], [20, 10];

is_deeply [run_block{ my(%a, $b) = (foo => 42); (\%a, $b) }], [{foo => 42}, undef];

is_deeply \@PL_stack,      [], '@PL_stack is empty';
is_deeply \@PL_markstack,  [], '@PL_markstack is empty';
is_deeply \@PL_scopestack, [], '@PL_scopestack is empty';
is_deeply \@PL_cxstack,    [], '@PL_cxstack is empty';
is_deeply \@PL_savestack,  [], '@PL_savestack is empty';
is_deeply \@PL_tmps,       [], '@PL_tmps is empty';
