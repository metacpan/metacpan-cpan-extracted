package L;

use strict;
use warnings;

use Test::More tests => 5;

use_ok('Class::Accessor::Lite');

Class::Accessor::Lite->mk_new_and_accessors(qw(foo bar));

ok ! $@, 'call mk_new_and_accessors';

my $l = L->new(
    foo  => 2,
);
is ref($l), 'L';
is $l->foo, 2;
ok ! defined $l->bar;
