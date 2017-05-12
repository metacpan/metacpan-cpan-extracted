#!perl -w

use strict;
use Test::More tests => 20;

use Acme::Perl::VM;
use Acme::Perl::VM qw(:perl_h);

is_deeply [run_block{       (1, 10) }], [1, 10];
is_deeply [run_block{ return(2, 20) }], [2, 20];

is_deeply [run_block{ do{       (1, 10)} }], [1, 10];
is_deeply [run_block{ do{ return(2, 20)} }], [2, 20];

is_deeply [scalar run_block{ do{       (1, 10)} }], [10];
is_deeply [scalar run_block{ do{ return(2, 20)} }], [20];

is_deeply [run_block{ do{       (1 + 10)} }], [11];
is_deeply [run_block{ do{ return(2 + 20)} }], [22];

is_deeply [run_block{ do{ my $i = 1;       ($i + 10)} }], [11];
is_deeply [run_block{ do{ my $i = 2; return($i + 20)} }], [22];

is_deeply [run_block{ do{ my $i = 1; $i++;       (10 + $i)} }], [12];
is_deeply [run_block{ do{ my $i = 2; $i++; return(20 + $i)} }], [23];

is_deeply [run_block{ do{ my $i = 1;       ($i + $i + $i)} }], [3];
is_deeply [run_block{ do{ my $i = 2; return($i + $i + $i)} }], [6];

is_deeply \@PL_stack,      [], '@PL_stack is empty';
is_deeply \@PL_markstack,  [], '@PL_markstack is empty';
is_deeply \@PL_scopestack, [], '@PL_scopestack is empty';
is_deeply \@PL_cxstack,    [], '@PL_cxstack is empty';
is_deeply \@PL_savestack,  [], '@PL_savestack is empty';
is_deeply \@PL_tmps,       [], '@PL_tmps is empty';
