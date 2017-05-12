use Compile::Generators;

use strict;

use Test::More tests => 5;

# Test two yields in a generator
# Test that goto works into if/else
# Yay!
sub gen_test :generator {
    my $num = shift;
    if ($num % 2) {
        yield 'odd';
    }
    else {
        yield 'even';
    }
}

my $test = gen_test();
is($test->(345), 'odd');
ok(not defined $test->(456));

$test = gen_test();
is($test->(456), 'even');
ok(not defined $test->(345));

pass __FILE__;

