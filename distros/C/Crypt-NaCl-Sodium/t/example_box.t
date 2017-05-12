
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw( :utils );

my $crypto_box = Crypt::NaCl::Sodium->box();


my ($a_skey, $b_skey, $a_key, $b_key);

{
    ## Alice
    ########

    # Alice generates secret keypair
    (my $a_pkey, $a_skey) = $crypto_box->keypair();
    ok($a_skey, "skey generated");
    ok($a_pkey, "pkey generated");

    # ... and shares the public key with Bob
    send_to( Bob => { public_key => $a_pkey } );
}

{
    ## Bob
    ########

    # Bob generates his secret keypair
    (my $b_pkey, $b_skey) = $crypto_box->keypair();
    ok($b_skey, "skey generated");
    ok($b_pkey, "pkey generated");

    # Bob receives the public key from Alice
    $a_key = receive_for( Bob => 'public_key' );
    ok($a_key, "received pkey");

    # ... and shares his public key with Alice
    send_to( Alice => { public_key => $b_pkey } );
}

    # now Alice and Bob can start communicating
{
    ## Alice
    ########

    my ($nonce, $msg, $secret);

    # Alice receives the public key from Bob
    $b_key = receive_for( Alice => 'public_key' );
    ok($b_key, "received pkey");

    # Alice generates random nonce
    $nonce = $crypto_box->nonce();
    ok($nonce, "nonce generated");

    send_to( Bob => { nonce => $nonce } );

    # Alice's message to Bob
    $msg = "Hi Bob!";

    # encrypts using combined mode
    $secret = $crypto_box->encrypt( $msg, $nonce, $b_key, $a_skey );
    ok($secret, "msg encrypted");

    # message is ready for Bob
    send_to( Bob => { secret => $secret } );
}

{
    ## Bob
    ########
    my ($nonce, $decrypted_msg, $msg, $mac, $secret, $b_precal_key);

    # Bob receives the random nonce
    $nonce = receive_for( Bob => 'nonce' );
    ok($nonce, "received nonce");

    # and is now ready to receive first message from Alice
    $secret = receive_for( Bob => 'secret' );
    ok($secret, "received secret");

    # since Bob already has Alice's public key we have all information required to decrypt message
    $decrypted_msg = $crypto_box->decrypt( $secret, $nonce, $a_key, $b_skey );
    is($decrypted_msg, "Hi Bob!", "message decrypted");

    # Bob is going to send a lot of messages to Alice, so we speed up the
    # encryption and decryption by precalculating the shared key
    $b_precal_key = $crypto_box->beforenm( $a_key, $b_skey );
    ok($b_precal_key, "precal_key generated");

    # now it is time to reply
    $msg = "Hello Alice!";

    # generates new nonce
    $nonce = $crypto_box->nonce();
    ok($nonce, "new nonce generated");

    # this time we use detached mode using precalculated key
    ($mac, $secret) = $crypto_box->encrypt_afternm( $msg, $nonce, $b_precal_key );
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
    my ($nonce, $decrypted_msg, $mac, $secret, $a_precal_key);

    # Bob used the detached mode
    $nonce  = receive_for( Alice => 'nonce' );
    ok($nonce, "received nonce");
    $mac    = receive_for( Alice => 'mac' );
    ok($mac, "received mac");
    $secret = receive_for( Alice => 'secret' );
    ok($secret, "received secret");


    # Alice also precalculates the shared key
    $a_precal_key = $crypto_box->beforenm( $b_key, $a_skey );
    ok($a_precal_key, "precal_key generated");

    # we have now all information required to decrypt message
    $decrypted_msg = $crypto_box->decrypt_detached_afternm( $mac, $secret, $nonce, $a_precal_key );
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

