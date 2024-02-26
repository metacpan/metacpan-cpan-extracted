use Test::More tests => 6;
use Crypt::URandom qw(urandom urandom_ub);

ok(length(urandom(5000)) == 5000, 'urandom(5000) called successfully');
ok(length(urandom(1)) == 1, 'urandom(1) called successfully');
ok(length(urandom(0)) == 0, 'urandom(0) called successfully');

ok(length(urandom_ub(5000)) == 5000, 'urandom_ub(5000) called successfully');
ok(length(urandom_ub(1)) == 1, 'urandom_ub(1) called successfully');
ok(length(urandom_ub(0)) == 0, 'urandom_ub(0) called successfully');
