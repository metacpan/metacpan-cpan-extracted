use Test::More tests => 10;
use Crypt::URandom();

foreach my $correct (qw(500000 500 50)) {
	my $actual = length Crypt::URandom::urandom($correct);
        ok($actual == $correct, "Crypt::URandom::urandom($correct) returned $actual bytes");
	$actual = length Crypt::URandom::urandom_ub($correct);
        ok($actual == $correct, "Crypt::URandom::urandom_ub($correct) returned $actual bytes");
}
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
		$returns_binary_data = 1;
		if (Encode::is_utf8(Crypt::URandom::urandom_ub(2))) {
			$returns_binary_data = 0;
		}
		ok($returns_binary_data, 'Crypt::Urandom::urandom_ub returns binary data');
	}
}
my $exception_thrown = 1;
eval {
	Crypt::URandom::urandom();
	$exception_thrown = 0;
};
chomp $@;
ok($exception_thrown, "Correctly throws exception with no parameter:$@");
$exception_thrown = 1;
eval {
	Crypt::URandom::urandom("sdfadsf");
	$exception_thrown = 0;
};
chomp $@;
ok($exception_thrown, "Correctly throws exception with non integer parameter:$@");
