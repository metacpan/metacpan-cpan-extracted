
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw( :utils );

my $crypto_sign = Crypt::NaCl::Sodium->sign();

my ($a_skey, $b_skey, $a_key, $b_key);
{
    ## Alice
    ########

    my ($msg, $sealed);

    # Alice generates secret keypair
    (my $a_pkey, $a_skey) = $crypto_sign->keypair();
    ok($a_skey, "skey generated");
    ok($a_pkey, "pkey generated");

    # ... and shares the public key with Bob
    send_to( Bob => { public_key => $a_pkey } );

    # now Alice can sign her messages
    # while Bob can verify that Alice has signed them

    # a message to Bob
    $msg = "Hi Bob!";

    # Alice signs and seals the message using combined mode
    $sealed = $crypto_sign->seal( $msg, $a_skey );
    ok($sealed, "msg sealed");

    # message is ready for Bob
    send_to( Bob => { sealed => $sealed } );
}

{
    ## Bob
    ########
    my ($msg, $sealed, $opened, $mac);

    # Bob generates his secret keypair
    (my $b_pkey, $b_skey) = $crypto_sign->keypair();
    ok($b_skey, "skey generated");
    ok($b_pkey, "pkey generated");

    # ... and shares his public key with Alice
    send_to( Alice => { public_key => $b_pkey } );

    # Bob receives the public key from Alice
    $a_key = receive_for( Bob => 'public_key' );
    ok($a_key, "received pkey");

    # Bob is now ready to receive first message from Alice
    $sealed = receive_for( Bob => 'sealed' );
    ok($sealed, "received sealed msg");

    # since Bob already has Alice's public key we have all information required
    # to verify and open a message
    $opened = $crypto_sign->open( $sealed, $a_key );
    is($opened, "Hi Bob!", "message opened");

    # now it is time to reply
    $msg = "Hello Alice!";

    # this time we use detached mode
    $mac = $crypto_sign->mac( $msg, $b_skey );
    ok($mac, "mac generated");

    # Alice needs both to verify Bob's message
    send_to( Alice => { mac => $mac } );
    send_to( Alice => { msg => $msg } );
}

{
    ## Alice
    ########
    my ($msg, $mac);

    # Alice receives the public key from Bob
    $b_key = receive_for( Alice => 'public_key' );
    ok($b_key, "received pkey");

    # Bob used the detached mode
    $mac = receive_for( Alice => 'mac' );
    ok($mac, "received mac");
    $msg = receive_for( Alice => 'msg' );
    ok($msg, "received msg");

    # since we already have the message, all left to do is to verify that Bob
    # indeed has sent it
    ok($crypto_sign->verify($mac, $msg, $b_key), "msg verified");
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

