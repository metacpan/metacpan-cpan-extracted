
use Test::More;
use English();
use Carp();
use English qw( -no_match_vars );
use Exporter();
use XSLoader();
use constant;
use overload;
BEGIN {
	if ($^O eq 'MSWin32') {
		require Win32;
		require Win32::API;
		require Win32::API::Type;
	} else {
		require FileHandle;
	}
}
@INC = qw(blib/lib); # making sure we're testing pure perl version
require Crypt::URandom;

foreach my $correct (qw(500000 500 50)) {
	my $actual = length Crypt::URandom::urandom($correct);
        ok($actual == $correct, "Crypt::URandom::urandom($correct) returned $actual bytes");
	$actual = length Crypt::URandom::urandom_ub($correct);
        ok($actual == $correct, "Crypt::URandom::urandom_ub($correct) returned $actual bytes");
	eval { Crypt::URandom::getrandom($correct); };
	ok($@, "Crypt::URandom::getrandom throws an exception when the .so library is unavailable:$@");
}
done_testing();
