use Test::More tests => 16;
use Basset::Container::Hash;
package Basset::Container::Hash;
{		Test::More::ok(1, "uses strict");
		Test::More::ok(1, "uses warnings");
};
{#line 170 Basset::Container::Hash
my %x = ('a' => 'b');

tie my %y, 'Basset::Container::Hash', \%x;	#<- %x is the parent of 'y'.

$y{'a'} = 'c';
$y{'b'} = 'd';

Test::More::is($x{'a'}, 'b', '$x{a} = b');
Test::More::is($y{'a'}, 'c', '$y{a} = c');
Test::More::is($y{'b'}, 'd', '$y{b} = d');
Test::More::is($x{'b'}, undef, '$x{b} is undef');
Test::More::is(scalar(%y), '2/8', 'scalar %y works');
delete $y{'a'};
Test::More::is($y{'a'}, 'b', '$y{a} is now b');
Test::More::ok(exists $y{'a'} != 0, '$y{a} exists');
Test::More::ok(exists $y{'b'} != 0, '$y{b} exists');
Test::More::ok(exists $y{'c'} == 0, '$y{c} does not exist');
delete $y{'b'};

my ($key, $value) = each %y;

Test::More::is($key, 'a', 'only key left is a');

$y{'new'} = 'value';

my ($key2, $value2) = (keys %y)[0];

Test::More::is($key2, 'new', 'first set key is new');

my @keys = sort keys %y;
Test::More::is($keys[0], 'a', 'first key is a');
Test::More::is($keys[1], 'new', 'second key is new');

%y = ();
my @keys2 = sort keys %y;
Test::More::is(scalar @keys2, 1, 'only one key remains');
};
