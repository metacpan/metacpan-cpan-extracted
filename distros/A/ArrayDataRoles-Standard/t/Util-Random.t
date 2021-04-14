#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Role::Tiny;
use ArrayData::Test::Source::LinesDATA;

my $t = ArrayData::Test::Source::LinesDATA->new;
Role::Tiny->apply_roles_to_object($t, 'ArrayDataRole::Util::Random');

# minimal for now

subtest get_rand_elem => sub {
    my $res = $t->get_rand_elem;
    ok($res >=1 && $res <= 5);
};

# XXX get_rand_elems

done_testing;
