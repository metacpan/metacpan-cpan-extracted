#!perl -w

use strict;
use Test::More tests => 10;

use Acme::Perl::VM;
use Acme::Perl::VM qw(:perl_h);

is_deeply [run_block{ (1 .. 10)    }], [(1 .. 10)];
is_deeply [run_block{ ('a' .. 'z') }], [('a' .. 'z')];

is_deeply [run_block{ my($i, $j) = (1, 10); ([$i .. $j], [$i, $j])   }], [[1 .. 10],    [1,    10]];
is_deeply [run_block{ my($i, $j) = qw(a z); ([$i .. $j], [$i, $j])   }], [['a' .. 'z'], ['a', 'z']];

is_deeply \@PL_stack,      [], '@PL_stack is empty';
is_deeply \@PL_markstack,  [], '@PL_markstack is empty';
is_deeply \@PL_scopestack, [], '@PL_scopestack is empty';
is_deeply \@PL_cxstack,    [], '@PL_cxstack is empty';
is_deeply \@PL_savestack,  [], '@PL_savestack is empty';
is_deeply \@PL_tmps,       [], '@PL_tmps is empty';
