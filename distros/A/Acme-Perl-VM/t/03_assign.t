#!perl -w

use strict;
use Test::More tests => 16;

use Acme::Perl::VM;
use Acme::Perl::VM qw(:perl_h);

is scalar(run_block{ my $x }),         undef, 'padsv (intro)';
is scalar(run_block{ my $x = 10 }),       10, 'sassign';

my $y = 20;
is scalar(run_block{ my $x = $y }), 20, 'sassign';

is_deeply [run_block{ my($x) = (10) }],         [10],        'aassign';
is_deeply [run_block{ my($x, $y) = (10, 20) }], [10, 20],    'aassign';
is_deeply [run_block{ my($x, $y) = (10) }],     [10, undef], 'aassign';

is_deeply [scalar run_block{ my $x = 50;        $x }], [50];
is_deeply [scalar run_block{ my $x = 60; return $x }], [60];

is_deeply [run_block{ my $x = 50;        $x }], [50];
is_deeply [run_block{ my $x = 60; return $x }], [60];

is_deeply \@PL_stack,      [], '@PL_stack is empty';
is_deeply \@PL_markstack,  [], '@PL_markstack is empty';
is_deeply \@PL_scopestack, [], '@PL_scopestack is empty';
is_deeply \@PL_cxstack,    [], '@PL_cxstack is empty';
is_deeply \@PL_savestack,  [], '@PL_savestack is empty';
is_deeply \@PL_tmps,       [], '@PL_tmps is empty';
