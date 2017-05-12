
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw( :utils );

my $crypto_aead = Crypt::NaCl::Sodium->aead();

my ($master_key);
{
    ## Alice
    ########

    my ($key, $nonce, $additional_data, $decrypted_msg, $msg, $secret);

    # Alice generates secret key
    $master_key = $key = $crypto_aead->keygen();
    ok($key, "key generated");

    # ... and shares it with Bob
    send_to( Bob => { key => $key } );

    # now Alice and Bob can start communicating

    # then generates random nonce
    $nonce = $crypto_aead->nonce();
    ok($nonce, "nonce generated");

    send_to( Bob => { nonce => $nonce } );

    # Alice's message to Bob
    $msg = "Hi Bob!";

    # unencrypted metadata
    $additional_data = "greeting";

    # Bob will need it to decrypt and verify secret message
    send_to( Bob => { additional_data => $additional_data } );

    # the secret will include the additional data
    $secret = $crypto_aead->encrypt( $msg, $additional_data, $nonce, $key );
    ok($secret, "msg encrypted");

    # message is ready for Bob
    send_to( Bob => { secret => $secret } );
}

{
    ## Bob
    ########
    my ($key, $nonce, $additional_data, $decrypted_msg, $msg, $secret);

    # Bob receives the secret key from Alice
    $key = receive_for( Bob => 'key' );
    ok($key, "received key");

    # and random nonce
    $nonce = receive_for( Bob => 'nonce' );
    ok($nonce, "received nonce");

    # Bob is now ready to receive first message from Alice
    # first the additional data
    $additional_data = receive_for( Bob => 'additional_data' );
    ok($additional_data, "received additional_data");

    # then the secret itself
    $secret = receive_for( Bob => 'secret' );
    ok($secret, "received secret");

    # he has now all information required to decrypt message
    $decrypted_msg = $crypto_aead->decrypt( $secret, $additional_data, $nonce, $key );
    is($decrypted_msg, "Hi Bob!", "message decrypted");

    # time to reply
    $msg = "Hello Alice!";

    # generates new nonce
    $nonce = $crypto_aead->nonce();
    ok($nonce, "new nonce generated");

    # Bob replies with no additional data
    $additional_data = "";

    # let's encrypt now
    $secret = $crypto_aead->encrypt( $msg, $additional_data, $nonce, $key );
    ok($secret, "msg encrypted");

    # Alice needs all pieces to verify and decrypt Bob's message
    send_to( Alice => { nonce => $nonce } );
    send_to( Alice => { additional_data => $additional_data } );
    send_to( Alice => { secret => $secret } );
}
{
    ## Alice
    ########
    my ($nonce, $additional_data, $decrypted_msg, $secret);

    # Bob's data sent to Alice
    $nonce           = receive_for( Alice => 'nonce' );
    ok($nonce, "received nonce");
    $additional_data = receive_for( Alice => 'additional_data' );
    ok(defined $additional_data, "received additional_data");
    $secret          = receive_for( Alice => 'secret' );
    ok($secret, "received secret");

    # we have now all information required to decrypt message
    $decrypted_msg = $crypto_aead->decrypt( $secret, $additional_data, $nonce, $master_key );
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

