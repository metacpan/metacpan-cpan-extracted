use Acme::UNIVERSAL::cannot;
use strict;
use warnings;
use Test::More tests => 6;
use Test::Exception;

{
    package foo;
    sub quux {}
}

my $i = bless {}, 'foo';

lives_ok {
    ok $i->cannot('bar');
};
ok !$i->can('bar');

lives_ok {
    ok !$i->cannot('quux');
};
ok $i->can('quux');

