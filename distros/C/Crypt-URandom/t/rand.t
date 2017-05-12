use Test::More tests => 3;
use Crypt::URandom();

ok(length(Crypt::URandom::urandom(500)) == 500, 'Crypt::URandom::urandom(500) called successfully');
ok(length(Crypt::URandom::urandom(50)) == 50, 'Crypt::URandom::urandom(50) called successfully');
SKIP: {
	eval { require Encode; };
	if ($@) {
		skip("Encode module cannot be loaded", 1);
	} else {
		my $returns_binary_data = 1;
		if (Encode::is_utf8(Crypt::URandom::urandom(2))) {
			$returns_binary_data = 0;
		}
		ok($returns_binary_data, 'Crypt::Urandom::urandom returns binary data');
	}
}
