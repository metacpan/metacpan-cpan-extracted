use lib 't/lib';
use Test::More;
use Two;

my $package = Two->new();

is($package->one, 'testing');
is_deeply($package->two, { one => 1, two => 2, three => 3});
is_deeply($package->three, [qw/1 2 3/]);

eval {
	$package->fail_one;
};
like($@, qr/Modification of a read-only value attempted/);

eval {
	$package->fail_two;
};
like($@, qr/Attempt to access disallowed key 'not_exists'/);

eval {
	$package->fail_three;
};
like($@, qr/Modification of a read-only value attempted/);



done_testing();
