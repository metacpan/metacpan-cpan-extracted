use FindBin;
use lib "$FindBin::Bin/lib";
use Test2AndUtils;
use Crypt::SecretBuffer qw(secret);

my $buf = Crypt::SecretBuffer->new('abc123abc456');

is($buf->index('abc'), 0, 'find first substring');
is($buf->index('123'), 3, 'find middle substring');
is($buf->index('abc', 4), 6, 'find substring after offset');
is($buf->index('nope'), -1, 'return -1 when not found');
is($buf->index('abc', -4), -1, 'negative offset beyond substring');

done_testing;

