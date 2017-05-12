use Test::More;

plan tests => 2;

use Crypt::Format;

{
    local $INC{'BadBase64.pm'} = __FILE__;
    local $Crypt::Format::BASE64_MODULE = 'BadBase64';

    my $faux_pem = "-----BEGIN XXX-----\nencoded\n-----END XXX-----";

    is(
        Crypt::Format::der2pem(0000, 'XXX'),
        $faux_pem,
        'der2pem() (encode())',
    );

    is(
        Crypt::Format::pem2der($faux_pem),
        'decoded',
        'pem2der() (decode())',
    );
}

#----------------------------------------------------------------------

package BadBase64;

sub encode { "encoded\n" }

sub decode { 'decoded' }

1;
