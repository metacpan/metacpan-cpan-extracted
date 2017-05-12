use Compile::Generators;

use strict;

use Test::More tests => 9;

sub gen_test1 :generator {
    yield 'Foo';
    yield 'Bar';
}

sub gen_test2 :generator {
    yield 42;
    yield 53;
    yield 64;
}

# Test multiple yields in order
# Test that calling after generator is complete continues returning nothing
my $test1 = gen_test1();
my $test2 = gen_test2();

is($test1->(), 'Foo');
is($test2->(), 42);
is($test1->(), 'Bar');
is($test2->(), 53);
ok(not defined $test1->());
is($test2->(), 64);
ok(not defined $test1->());
ok(not defined $test2->());

pass __FILE__;

