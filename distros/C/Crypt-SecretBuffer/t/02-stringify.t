use Test2::V0;
use Crypt::SecretBuffer qw( secret );

my $buf= secret("test");
is( "$buf", '[REDACTED]', 'default stringify_mask' );

$buf->{stringify_mask}= '*****';
is( "$buf", '*****', 'custom stringify_mask' );

$buf->{stringify_mask}= undef;
is( "$buf", 'test', 'disable stringify_mask' );

$buf= secret;
$buf->{stringify_mask}= undef;
is( "$buf", '', 'uninitialized buffer returns empty string' );

$buf= secret(stringify_mask => "[PASSWORD]", assign => "test");
is( "$buf", '[PASSWORD]', 'attribute assigned by ctor' );
is( $buf->stringify_mask, '[PASSWORD]', 'read attribute' );
$buf->stringify_mask(undef);
is( "$buf", "test", 'expose secret using attr setter' );

done_testing;
