use v5.14;
use warnings;
use Encode;
use utf8;

use Test::More;
use Data::Dumper;

use lib '.';
use t::Util;

is(
    desumasu(qw(--dearu --subst --all --no-color t/t1-s.txt))->run->{stdout},
    slurp('t/t2-s.txt')
);

is(
    desumasu(qw(--desumasu --subst --all --no-color t/t2-s.txt))->run->{stdout},
    slurp('t/t2-r.txt')
);

is(
    desumasu(qw(--dearu-n --subst --all --no-color t/t1-s.txt))->run->{stdout},
    slurp('t/t3-r.txt')
);

is(
    desumasu(qw(--dearu-N --subst --all --no-color t/t1-s.txt))->run->{stdout},
    slurp('t/t4-r.txt')
);

done_testing;
