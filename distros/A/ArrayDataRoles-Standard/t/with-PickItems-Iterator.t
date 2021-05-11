#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use ArrayData::Test::Source::LinesInDATA;
use Role::Tiny;
use Role::TinyCommons::Collection::PickItems::Iterator; # for scan_prereqs

my $t = ArrayData::Test::Source::LinesInDATA->new;
Role::Tiny->apply_roles_to_object($t, 'Role::TinyCommons::Collection::PickItems::Iterator');

# minimal for now

subtest pick_item => sub {
    my $res = $t->pick_item;
    ok($res >=1 && $res <= 5);
};

# XXX pick_items

done_testing;
