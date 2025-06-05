use FindBin;
use lib "$FindBin::Bin/lib";
use Test2AndUtils;
use Crypt::SecretBuffer qw(secret);

my $buf = Crypt::SecretBuffer->new("abc123\0abc456");

is($buf->index('abc'), 0, 'find first substring');
is($buf->index('123'), 3, 'find middle substring');
is($buf->index("\0"), 6, 'find middle substring');
is($buf->index("\0", 6), 6, 'find NUL byte');
is($buf->index('abc', 4), 7, 'find substring after offset');
is($buf->index('nope'), -1, 'return -1 when not found');
is($buf->index('abc', -4), -1, 'negative offset beyond substring');
is($buf->index("6", $buf->length-1), $buf->length-1, 'find last byte starting from last byte');
is($buf->index("6", -1), $buf->length-1, 'find last byte using negative index');

done_testing;

