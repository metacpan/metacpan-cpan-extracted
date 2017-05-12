use strict;
use lib qw(t);
use Test::More;
use Test::Deep;

# test inconsistent attributes -- ones declared as both instance and class attributes
# note that error is detected at 'declare time' during use

eval "use autoclass_011::Inconsistent1";

ok(!$@,'use autoclass_011::Inconsistent1 found no inconsistencies');
eval "use autoclass_011::Inconsistent2";

# NG 12-11-25: as of perl 5.17.6, order of hash keys is randomized. we cannot predict
#              order in which inconsistent attributes detected, so must relax the regex
#              checked here
# like($@,qr/^Inconsistent declarations for attribute\(s\) a b/,
#      'use autoclass_011::Inconsistent2 found expected inconsistencies');
like($@,qr/^Inconsistent declarations for attribute\(s\)/,
     'use autoclass_011::Inconsistent2 found expected inconsistencies');
done_testing();
