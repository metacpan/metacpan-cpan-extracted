use strict; use warnings;
package Convert::Base32::Crockford;
our $VERSION = '0.16';

use Convert::Base32 ();

use base 'Exporter';
our @EXPORT = qw(encode_base32 decode_base32);

sub encode_base32 {
    my $base32 = Convert::Base32::encode_base32($_[0]);
    $base32 =~
    tr  {abcdefghijklmnopqrstuvwxyz234567}
        {0123456789ABCDEFGHJKMNPQRSTVWXYZ};
    return $base32;
}

sub decode_base32 {
    my $string = uc($_[0]);
    $string =~
    tr  {0O1IL23456789ABCDEFGHJKMNPQRSTVWXYZ-}
        {aabbbcdefghijklmnopqrstuvwxyz234567}d;
    return Convert::Base32::decode_base32($string);
}

1;
