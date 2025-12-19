use Test2::V0;
use Crypt::SecretBuffer qw( secret unmask_secrets_to );

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
is( "$buf", "test", 'unmask secret using attr setter' );

delete $buf->{stringify_mask};
is( "$buf", '[REDACTED]', 'restore default stringify_mask' );

done_testing;
