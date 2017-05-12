use strict; use warnings;

use Test::More;
use Test::TypeTiny;

use Acme::Types::NonStandard -all;

use Scalar::Util 'dualvar';
should_pass dualvar(2, 4),      ConfusingDualVar;
should_pass dualvar(2.2, 4.4),  ConfusingDualVar;
should_fail dualvar(2, 'foo'),  ConfusingDualVar;
should_fail dualvar(2, 2),      ConfusingDualVar;

should_pass 42,                   FortyTwo;
should_fail 24,                   FortyTwo;
should_pass FortyTwo->coerce(''), FortyTwo;

my $orig = 'foo';
my $r = \$orig;
my $rr = \$r;
my $rrr = \$rr;
should_pass $rrr,     RefRefRef;
should_fail $rr,      RefRefRef;
should_fail $r,       RefRefRef;
should_fail $orig,    RefRefRef;

should_pass [undef,undef], ReallySparseArray;
should_fail [undef, 1],    ReallySparseArray;

my $h = +{ foo => [ 'bar' ], baz => 'quux' };
$h->{foo}->[1] = $h->{foo};
should_pass $h,                ProbableMemoryLeak;
should_fail +{ foo => 'bar' }, ProbableMemoryLeak;

done_testing
