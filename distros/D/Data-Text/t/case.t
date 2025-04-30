use strict;
use warnings;

use Test::Most;

BEGIN { use_ok('Data::Text') }

# Test uppercase
my $upper = Data::Text->new('hello world');
isa_ok($upper, 'Data::Text', 'Object created for uppercase');
$upper->uppercase();
is($upper->as_string, 'HELLO WORLD', 'Text converted to uppercase');

# Test lowercase
my $lower = Data::Text->new('HELLO WORLD');
isa_ok($lower, 'Data::Text', 'Object created for lowercase');
$lower->lowercase();
is($lower->as_string, 'hello world', 'Text converted to lowercase');

# Chaining test
my $chain = Data::Text->new('Hello')->append(' World')->uppercase()->lowercase();
is($chain->as_string, 'hello world', 'Chained upper->lower works');

# Edge case: undef
my $undef = Data::Text->new();
$undef->uppercase();
ok(!defined $undef->as_string(), 'uppercase on undef does nothing');
$undef->lowercase();
ok(!defined $undef->as_string(), 'lowercase on undef still does nothing');

done_testing();
