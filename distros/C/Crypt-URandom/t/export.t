use Test::More tests => 2;
use Crypt::URandom qw(urandom);

ok(length(urandom(5000)) == 5000, 'urandom(5000) called successfully');
ok(length(urandom(1)) == 1, 'urandom(1) called successfully');
