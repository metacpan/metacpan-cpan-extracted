
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw( :utils );

my $crypto_secretbox = Crypt::NaCl::Sodium->secretbox();


my ($master_key);
{
    ## Alice
    ########

    my ($key, $nonce, $decrypted_msg, $msg, $secret);
    # Alice generates secret key
    $master_key = $key = $crypto_secretbox->keygen();
    ok($key, "key generated");

    # ... and shares it with Bob
    send_to( Bob => { key => $key } );

    # now Alice and Bob can start communicating

    # Alice generates random nonce
    $nonce = $crypto_secretbox->nonce( );
    ok($nonce, "nonce generated");

    send_to( Bob => { nonce => $nonce } );

    # Alice's message to Bob
    $msg = "Hi Bob!";

    # encrypts using combined mode
    $secret = $crypto_secretbox->encrypt( $msg, $nonce, $key );
    ok($secret, "msg encrypted");

    # message is ready for Bob
    send_to( Bob => { secret => $secret } );

}

{
    ## Bob
    ########

    my ($key, $nonce, $decrypted_msg, $msg, $mac, $secret);

    # Bob receives the secret key from Alice
    $key = receive_for( Bob => 'key' );
    ok($key, "received key");

    # and random nonce
    $nonce = receive_for( Bob => 'nonce' );
    ok($nonce, "received nonce");

    # Bob is now ready to receive first message from Alice
    $secret = receive_for( Bob => 'secret' );
    ok($secret, "received secret");

    # we have now all information required to decrypt message
    $decrypted_msg = $crypto_secretbox->decrypt( $secret, $nonce, $key );
    is($decrypted_msg, "Hi Bob!", "message decrypted");

    # time to reply
    $msg = "Hello Alice!";

    # generates new nonce
    $nonce = $crypto_secretbox->nonce();
    ok($nonce, "new nonce generated");

    # this time we use detached mode
    ($mac, $secret) = $crypto_secretbox->encrypt( $msg, $nonce, $key );
    ok($mac, "mac generated");
    ok($secret, "msg encrypted");

    # Alice needs all pieces to verify and decrypt Bob's message
    send_to( Alice => { nonce => $nonce } );
    send_to( Alice => { mac => $mac } );
    send_to( Alice => { secret => $secret } );
}
{
    ## Alice
    ########

    my ($nonce, $decrypted_msg, $mac, $secret);

    # Bob used the detached mode
    $nonce  = receive_for( Alice => 'nonce' );
    ok($nonce, "received nonce");
    $mac    = receive_for( Alice => 'mac' );
    ok($mac, "received mac");
    $secret = receive_for( Alice => 'secret' );
    ok($secret, "received secret");

    # we have now all information required to decrypt message
    $decrypted_msg = $crypto_secretbox->decrypt_detached( $mac, $secret, $nonce, $master_key );
    is($decrypted_msg, "Hello Alice!", "message decrypted");
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

