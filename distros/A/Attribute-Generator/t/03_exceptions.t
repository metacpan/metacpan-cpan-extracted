use Test::More tests => 2;

use strict;
use warnings;

use Attribute::Generator;

sub foo : Generator {
    yield 'foo';
    die "TEST EXCEPTION\n";
}

my $foo = foo();

is($foo->next, 'foo');

eval {
    $foo->next;
};
is($@, "TEST EXCEPTION\n");

