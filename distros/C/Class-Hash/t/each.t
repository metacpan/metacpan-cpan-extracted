# vim: set ft=perl :

use Test::More tests => 7;
use Class::Hash;

my $hash = Class::Hash->new(apples => 1, oranges => 2, tangerines => 3, 
	{ no_named_accessors => 1, 'each' => 1 });

my %test;
while (my ($k, $v) = $hash->each) {
	$test{$k} = $v;
}

while (my ($k, $v) = each %test) {
	is($test{$k}, $hash->{$k}, $k);
}

Class::Hash->options($hash)->{'each'} = 0;

eval {
	$hash->each;
};

if ($@) {
	pass('each failed');
} else {
	fail('each succeeded');
}

%test = ();
while (my ($k, $v) = Class::Hash->each($hash)) {
	$test{$k} = $v;
}

while (my ($k, $v) = each %test) {
	is($test{$k}, $hash->{$k}, $k);
}
