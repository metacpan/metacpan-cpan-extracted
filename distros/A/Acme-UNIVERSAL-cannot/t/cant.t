use Acme::UNIVERSAL::cannot;
use strict;
use warnings;
use Test::More tests => 8;
use Test::Exception;

{
    package foo;
    sub quux {}
}

my $i = bless {}, 'foo';

lives_ok {
    ok $i->cant('bar');
    ok $i->can't('bar');
};
ok !$i->can('bar');

lives_ok {
    ok !$i->cant('quux');
    ok !$i->can't('quux');
};
ok $i->can('quux');

