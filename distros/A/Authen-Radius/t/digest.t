use strict;
use warnings;
use Test::More tests => 3;
use Test::NoWarnings;

BEGIN { use_ok('Authen::Radius') };

# Convert each two-digit hex number back to an ASCII character.
sub hex_to_ascii {
    my $str = shift;
    return $str unless ( defined $str );
    $str =~ s/([a-fA-F0-9]{2})/chr(hex $1)/eg;
    return $str;
}

my $key  = "Jefe";
my $data = "what do ya want for nothing?";

my $etalon_digest = hex_to_ascii("750c783e6ab0b503eaa86e310a5db738");

my $digest = Authen::Radius::hmac_md5( undef, $data, $key );
cmp_ok( $digest, 'eq', $etalon_digest );
