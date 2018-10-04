use strict;
use warnings;
use Test::More;

use_ok 'Crypt::Blowfish::Mod';

my $str = "You're the man now, dog";

subtest 'long raw key' => sub {
    my $long_key = 'a' x 256;

    ok( my $cipher = new Crypt::Blowfish::Mod( key_raw => $long_key ), 'long key instance' );

    my $out = $cipher->encrypt( $str );
};

subtest 'strange raw key works' => sub {
    ok(
        my $cipher = new Crypt::Blowfish::Mod(
            key_raw => 'sdoifuowerjle8784371oiojlkfjsldkfj+/565719.")o832948'
        ),
        'created'
    );
    my $out = $cipher->encrypt( $str );

    is( $out, 'OA4hPAuNesKCRnsXsBBquDPA1cx1vCXSxlnC', 'encrypt' );
};

subtest 'b64 encrypt' => sub {
    ok( my $cipher = new Crypt::Blowfish::Mod( key => 'MTIzNDU2' ), 'created' );
    my $out = $cipher->encrypt( $str );

    is( $out, 'qpKjrAawOJeCw2GtABI7HJYBcxobKAbv60wA', 'encrypt base64' );

    my $data = $cipher->decrypt( $out );

    is( $data, $str, 'decrypt base64' );
};

subtest 'b64 key' => sub {
    ok( my $cipher = new Crypt::Blowfish::Mod( 'MTIzNDU2' ), 'created' );
    my $out  = $cipher->encrypt( $str );
    my $data = $cipher->decrypt( $out );

    is( $data, $str, 'decrypt' );
};

subtest 'size stress' => sub {
    my $cipher = new Crypt::Blowfish::Mod( 'MTIzNDU2' );

    my $str;

    for ( 1 .. 50 ) {
        $str .= ( 'x' x 1000 ) x $_;

        my $out  = $cipher->encrypt( $str );
        my $data = $cipher->decrypt( $out );

        is( $data, $str, 'decrypt large str ' . $_ );
    }
};

subtest 'raw' => sub {
    ok( my $cipher = new Crypt::Blowfish::Mod( key_raw => 'lkdjflkajsldkfj03804223$=(/)/(1lkjl' ),
        'raw key created' );

    my $out  = $cipher->encrypt_raw( $str );
    my $data = $cipher->decrypt_raw( $out );

    is( $data, $str, 'decrypt raw' );
};

subtest 'utf8' => sub {
    $str = 'fó€bar';

    ok( my $cipher = new Crypt::Blowfish::Mod( key_raw => 'lkdjflkajsldkfj03804223$=(/)/(1lkjl' ),
        'raw key created' );

    my $out  = $cipher->encrypt( $str );
    my $data = $cipher->decrypt( $out );

    is( $data, $str, 'enc/decrypt utf8' );
};

subtest 'utf8 raw' => sub {
    $str = 'fó€bar';

    ok( my $cipher = new Crypt::Blowfish::Mod( key_raw => 'lkdjflkajsldkfj03804223$=(/)/(1lkjl' ),
        'raw key created' );

    my $out  = $cipher->encrypt_raw( $str );
    my $data = $cipher->decrypt_raw( $out );

    is( $data, $str, 'enc/decrypt utf8' );
};

subtest 'legacy raw' => sub {
    $str = 'foobar';

    ok( my $cipher = new Crypt::Blowfish::Mod( key_raw => 'lkdjflkajsldkfj03804223$=(/)/(1lkjl' ),
        'raw key created' );

    my $out  = $cipher->encrypt_legacy( $str );
    my $data = $cipher->decrypt( $out );

    is( $data, $str, 'enc/decrypt legacy' );
};

subtest 'legacy failed' => sub {
    $str = 'déjà-vu';

    ok( my $cipher = new Crypt::Blowfish::Mod( key_raw => 'lkdjflkajsldkfj03804223$=(/)/(1lkjl' ),
        'raw key created' );

    my $out  = $cipher->encrypt_legacy( $str );
    my $data = $cipher->decrypt( $out );

    isnt( $data, $str, 'enc/decrypt legacy invalid' );
};

done_testing;
