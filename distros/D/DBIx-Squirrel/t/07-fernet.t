use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('Crypt::CBC');
    use_ok('Digest::SHA');
    use_ok('MIME::Base64::URLSafe');
    use_ok(
        'DBIx::Squirrel::Crypt::Fernet',
        qw/fernet_decrypt fernet_encrypt fernet_genkey fernet_verify Fernet/,
    );
}

diag join(
    ', ',
    "Testing DBIx::Squirrel::Crypt::Fernet $DBIx::Squirrel::Crypt::Fernet::VERSION",
    "Perl $]", "$^X",
);

my( $expired_key, $expired_token ) = (
    'cJ3Fw3ehXqef-Vqi-U8YDcJtz8Gv-ZHyxultoAGHi4c=',
    'gAAAAABT8bVcdaked9SPOkuQ77KsfkcoG9GvuU4SVWuMa3ewrxpQdreLdCT6cc7rdqkavhyLgqZC41dW2vwZJAHLYllwBmjgdQ==',
);

# Yes, I know I can use subtests, but subtests create a few more issues
# on the CPANTS testing matrix. So, I'm keeping things simple by using
# lexical scopes for groups of related tests.

{
    my $h = '*  Testing object-oriented interface  *';
    note $_ for '', '*' x length($h), $h, '*' x length($h), '';

    my( $key, $fernet, $message, $ttl, $verify, $encrypted_token, $decrypted_text );

    $key = Fernet->generatekey();
    is length($key), 44, "ok - got base64 key";

    $fernet = Fernet($key);
    isa_ok $fernet, 'DBIx::Squirrel::Crypt::Fernet';

    is $fernet->to_string(), $key, "ok - to_string serialisation";
    is "$fernet",            $key, "ok - stringification";

    $message         = 'This is a test';
    $encrypted_token = $fernet->encrypt($message);
    ok length($encrypted_token) > 0, "ok - encrypt";

    $verify = $fernet->verify($encrypted_token);
    is $verify, !!1, "ok - verify";

    $decrypted_text = $fernet->decrypt($encrypted_token);
    is $decrypted_text, $message, "ok - decrypt";

    ( $fernet, $ttl ) = ( Fernet($expired_key), 10 );

    $verify = $fernet->verify( $expired_token, $ttl );
    is $verify, !!0, "ok - verify with ttl (expired)";

    $decrypted_text = $fernet->decrypt( $expired_token, $ttl );
    is $decrypted_text, undef, "ok - decrypt with ttl (expired)";

    $fernet = Fernet($key);

    $verify = $fernet->verify( $encrypted_token, $ttl );
    is $verify, !!1, "ok - verify with ttl";

    $decrypted_text = $fernet->decrypt( $encrypted_token, $ttl );
    is $decrypted_text, $message, "ok - decrypt with ttl";
}

{
    my $h = '*  Testing exported interface  *';
    note $_ for '', '*' x length($h), $h, '*' x length($h), '';

    my( $key, $fernet, $message, $ttl, $verify, $encrypted_token, $decrypted_text );

    $key = fernet_genkey();
    is length($key), 44, "ok - got base64 key";

    $message         = 'This is a test';
    $encrypted_token = fernet_encrypt( $key, $message );
    ok length($encrypted_token) > 0, "ok - encrypt";

    $verify = fernet_verify( $key, $encrypted_token );
    is $verify, !!1, "ok - verify";

    $decrypted_text = fernet_decrypt( $key, $encrypted_token );
    is $decrypted_text, $message, "ok - decrypt";

    $ttl    = 10;
    $verify = fernet_verify( $expired_key, $expired_token, $ttl );
    is $verify, !!0, "ok - verify with ttl (expired)";

    $decrypted_text = fernet_decrypt( $expired_key, $expired_token, $ttl );
    is $decrypted_text, undef, "ok - decrypt with ttl (expired)";

    $verify = fernet_verify( $key, $encrypted_token, $ttl );
    is $verify, !!1, "ok - verify with ttl";

    $decrypted_text = fernet_decrypt( $key, $encrypted_token, $ttl );
    is $decrypted_text, $message, "ok - decrypt with ttl";
}

done_testing();
