#!perl -w

use strict;
use Test::More tests => 10;

use Acme::Perl::VM;
use Acme::Perl::VM qw(:perl_h);

is_deeply [run_block{ my @x = (42); push    @x, 10, 20;  @x }], [42, 10, 20];
is_deeply [run_block{ my @x = (42); unshift @x, 10, 20;  @x }], [10, 20, 42];

is_deeply [run_block{ my @x = (10, 20); (  pop(@x), 0, @x) }], [20, 0, 10];
is_deeply [run_block{ my @x = (10, 20); (shift(@x), 0, @x) }], [10, 0, 20];


is_deeply \@PL_stack,      [], '@PL_stack is empty';
is_deeply \@PL_markstack,  [], '@PL_markstack is empty';
is_deeply \@PL_scopestack, [], '@PL_scopestack is empty';
is_deeply \@PL_cxstack,    [], '@PL_cxstack is empty';
is_deeply \@PL_savestack,  [], '@PL_savestack is empty';
is_deeply \@PL_tmps,       [], '@PL_tmps is empty';
