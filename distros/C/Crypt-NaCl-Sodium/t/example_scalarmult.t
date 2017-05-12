
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw( :utils );


my $crypto_scalarmult = Crypt::NaCl::Sodium->scalarmult();

my ($a_skey, $a_shared_key, $b_shared_key);

{
    ## Alice
    ########

    # Alice generates secret key
    $a_skey = $crypto_scalarmult->keygen();
    ok($a_skey, "skey generated");

    # and computes the public key
    my $a_pkey = $crypto_scalarmult->base( $a_skey );
    ok($a_pkey, "pkey generated");

    # ... and shares it with Bob
    send_to( Bob => { public_key => $a_pkey } );
}

{
    ## Bob
    ########

    # Bob generates his secret key
    my $b_skey = $crypto_scalarmult->keygen();
    ok($b_skey, "skey generated");

    # and computes the public key
    my $b_pkey = $crypto_scalarmult->base( $b_skey );
    ok($b_pkey, "pkey generated");

    # ... and shares his public key with Alice
    send_to( Alice => { public_key => $b_pkey } );

    # Bob receives the public key from Alice
    my $a_key = receive_for( Bob => 'public_key' );
    ok($a_key, "received pkey");

    # Bob can now calculate the shared secret key
    $b_shared_key = $crypto_scalarmult->shared_secret( $b_skey, $a_key );
    ok($b_shared_key, "shared_key generated");
}

{
    ## Alice
    ########

    # Alice receives the public key from Bob
    my $b_key = receive_for( Alice => 'public_key' );
    ok($b_key, "received pkey");

    # and can now also calculate the shared secret key
    $a_shared_key = $crypto_scalarmult->shared_secret( $a_skey, $b_key );
    ok($a_shared_key, "shared_key generated");

    # shared keys calculated by Alice and Bob are equal
    is($a_shared_key->to_hex, $b_shared_key->to_hex, "shared key equal");
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

