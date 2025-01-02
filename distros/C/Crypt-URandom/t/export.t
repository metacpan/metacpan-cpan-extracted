use Test::More;
use Crypt::URandom qw(urandom urandom_ub getrandom);

ok(length(urandom(5000)) == 5000, 'urandom(5000) called successfully');
ok(length(urandom(1)) == 1, 'urandom(1) called successfully');
ok(length(urandom(0)) == 0, 'urandom(0) called successfully');

ok(length(urandom_ub(5000)) == 5000, 'urandom_ub(5000) called successfully');
ok(length(urandom_ub(1)) == 1, 'urandom_ub(1) called successfully');
ok(length(urandom_ub(0)) == 0, 'urandom_ub(0) called successfully');

my $getrandom = 1;
eval {
	getrandom(1);
	1;
} or do {
	$getrandom = 0;
};
if ($getrandom) {
	ok(length(getrandom(5000)) == 5000, 'getrandom(5000) called successfully');
	ok(length(getrandom(1)) == 1, 'getrandom(1) called successfully');
	ok(length(getrandom(0)) == 0, 'getrandom(0) called successfully');
}

done_testing();
