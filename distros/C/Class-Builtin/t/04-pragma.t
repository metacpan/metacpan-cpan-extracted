#!perl -T
use strict;
use warnings;
# use Class::Builtin;
#BEGIN{
#    if ($] < 5.010) {
#	print "1..0 # perl $] < 5.10.0\n";
#	exit 0;
#    }
#}

use Test::More qw/no_plan/; #tests => 1;

{
    use scalar::object;
    is 'dankogai'->uc, 'DANKOGAI';
}

eval {
    print 'dankogai'->uc;
};
ok($@, $@);
