
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw( :utils );

my $crypto_auth = Crypt::NaCl::Sodium->auth();

my ($master_key);

{
    ## Alice
    ########

    my ($key, $mac, $msg);

    # Alice generates secret key
    $master_key = $key = $crypto_auth->keygen();
    ok($key, "key generated");

    # ... and shares it with Bob
    send_to( Bob => { key => $key } );

    # now Alice and Bob can start communicating

    # Alice's message to Bob
    $msg = "Hi Bob!";

    # MAC guarantees message integrity and authenticity
    $mac = $crypto_auth->mac( $msg, $key );
    ok($mac, "mac generated");

    # we can now send unencrypted message to Bob
    send_to( Bob => { msg => $msg } );

    # and MAC confirming that Alice has wrote it
    send_to( Bob => { mac => $mac } );
}

{
    ## Bob
    ########
    my ($key, $mac, $msg);

    # Bob receives the secret key from Alice
    $key = receive_for( Bob => 'key' );
    ok($key, "received key");

    # Bob is now ready to receive first message from Alice
    $msg = receive_for( Bob => 'msg' );
    ok($msg, "received msg");

    # and the MAC
    $mac = receive_for( Bob => 'mac' );
    ok($mac, "received mac");

    # Bob can now confirm that Alice has sent the message
    ok($crypto_auth->verify( $mac, $msg, $key ), "msg verified");

    # now we know that Alice is talking to us - time to reply
    $msg = "Hello Alice!";

    $mac = $crypto_auth->mac( $msg, $key );
    ok($mac, "new mac generated");

    # Alice will get our reply and the MAC
    send_to( Alice => { msg => $msg } );
    send_to( Alice => { mac => $mac } );
}

{
    ## Alice
    ########
    my ($mac, $msg);

    # receiving the reply
    $msg = receive_for( Alice => 'msg' );
    ok($msg, "received msg");
    $mac = receive_for( Alice => 'mac' );
    ok($mac, "received mac");

    # and Alice can now confirm that it is from Bob
    ok($crypto_auth->verify( $mac, $msg, $master_key ), "msg verified");
}

done_testing();

my %q;

sub send_to {
    my ($recipient, $data ) = @_;
    push @{ $q{$recipient} }, $data;
}

sub receive_for {
    my ($recipient, $key ) = @_;

    my $data = shift @{ $q{$recipient} };

    return $data->{$key};
}

