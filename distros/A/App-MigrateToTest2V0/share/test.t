use Test::More tests => 10;
use Test::Deep;
use URI;

isa_ok [], 'ARRAY';
isa_ok +{}, 'HASH';

is_deeply [], [];

my $inst = Foo->new;
isa_ok $inst, 'Foo', '$inst is an instance of Foo';
isa_ok($inst, 'Foo', '$inst is an instance of Foo');

cmp_deeply [1, 1], set(1);
cmp_deeply [2, 1], bag(1, 2);
cmp_deeply {code => 1}, {code => 1};

is $inst->bag, undef;

my $url = 'https://example.com/';
my $uri = URI->new('https://example.com/');
is $url, $uri;

package Foo;

sub new {
    my $class = shift;
    bless +{}, $class;
}

sub bag {}
