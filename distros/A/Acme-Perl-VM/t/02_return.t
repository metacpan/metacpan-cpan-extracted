#!perl -w

use strict;
use Test::More tests => 15;

use Acme::Perl::VM;
use Acme::Perl::VM qw(:perl_h);

is scalar(run_block{ 42 }), 42;
is scalar(run_block{ (1, 2, 3) }), 3;

is_deeply [run_block{ 42 }], [42];
is_deeply [run_block{ (1, 2, 3) }], [1, 2, 3];

is scalar(run_block{ return 42 }), 42;
is scalar(run_block{ return(1, 2, 3) }), 3;

is_deeply [run_block{ return 42 }], [42];
is_deeply [run_block{ return(1, 2, 3) }], [1, 2, 3];

is_deeply run_block{ return 42; die }, 42;

is_deeply \@PL_stack,      [], '@PL_stack is empty';
is_deeply \@PL_markstack,  [], '@PL_markstack is empty';
is_deeply \@PL_scopestack, [], '@PL_scopestack is empty';
is_deeply \@PL_cxstack,    [], '@PL_cxstack is empty';
is_deeply \@PL_savestack,  [], '@PL_savestack is empty';
is_deeply \@PL_tmps,       [], '@PL_tmps is empty';
