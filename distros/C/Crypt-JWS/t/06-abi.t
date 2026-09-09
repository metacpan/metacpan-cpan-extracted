#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Crypt::JWS ();

# The table a C consumer would resolve: nonzero pointer, then the
# built-in selftest calls through every core entry the way a consumer
# does (version check, key_from_oct, sign, verify, sha256,
# random_bytes, key_is_private, key_free).
ok Crypt::JWS::_abi_ptr(), '_abi_ptr resolves';
ok Crypt::JWS::_abi_selftest(), 'ABI selftest passes through the table';

# The pointer is the same one every time, which is what a consumer that
# resolves once and caches is relying on.
is Crypt::JWS::_abi_ptr(), Crypt::JWS::_abi_ptr(), '_abi_ptr is stable';

# v3: key_from_x509_der through the table. The selftest needs the pair -
# a certificate proves a key came back, only the matching private key
# proves it is the right one - so the material comes from t/data rather
# than a byte array compiled into the XS.
{
    my ($dir) = grep { -d } ('t/data', 'data');
    my $slurp = sub {
        open my $fh, '<:raw', "$dir/$_[0]" or die "$dir/$_[0]: $!";
        local $/; <$fh>;
    };
    my $pem = $slurp->('test-rsa-cert.pem');
    my ($b64) = $pem =~ /-----BEGIN CERTIFICATE-----(.*?)-----END/s;
    require MIME::Base64;
    ok Crypt::JWS::_abi_selftest(MIME::Base64::decode_base64($b64),
                                 $slurp->('test-rsa-key.pem')),
        'ABI selftest passes through key_from_x509_der';
}

done_testing();
