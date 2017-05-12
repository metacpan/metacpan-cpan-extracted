#! perl

use strict;
use warnings;

use Test::More 0.88;
use Test::Deep;
use Test::Exception;

use Bio::DNA::Incomplete ':all';

ok(match_pattern('ACGT', 'ACGT'),"'ACGT' matches 'ACGT'");
ok(match_pattern('ACKT', 'ACGT'), "'ACKT' matches 'ACGT'");
ok(match_pattern('ACKT', 'acgt'), "'ACKT' matches 'acgt'");
ok(match_pattern('ackt', 'ACGT'), "'ackt' matches 'ACGT'");
ok(!match_pattern('KCKT', 'ACGT'), "'KCKT' does not match 'ACGT'");
ok(!match_pattern('ACKT', 'ACGT '), "'ACKT ' does not match 'ACGT'");

throws_ok { pattern_to_regex_string("XXX") } qr/Invalid/, 'Invalid pattern gives an error';

my @possibilities = qw/ACGG ACTG ACGT ACTT ACGC ACTC/;
my @possibilities2 = qw/CGGA CTGA CGTA CTTA CGCA CTCA/;

cmp_set([ all_possibilities('ACKB') ], \@possibilities, 'ACKB matches ' . join ", ", @possibilities);
cmp_set([ all_possibilities('CKBA') ], \@possibilities2, 'ACKB matches ' . join ", ", @possibilities2);

done_testing;
