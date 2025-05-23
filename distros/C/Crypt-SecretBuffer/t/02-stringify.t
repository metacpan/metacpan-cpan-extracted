use Test2::V0;
use Crypt::SecretBuffer qw( secret );

my $buf= Crypt::SecretBuffer->new("test");
is( "$buf", '[REDACTED]', 'default stringify_mask' );

$buf->{stringify_mask}= '*****';
is( "$buf", '*****', 'custom stringify_mask' );

$buf->{stringify_mask}= undef;
is( "$buf", 'test', 'disable stringify_mask' );

$buf= Crypt::SecretBuffer->new;
$buf->{stringify_mask}= undef;
is( "$buf", '', 'uninitialized buffer returns empty string' );

done_testing;
