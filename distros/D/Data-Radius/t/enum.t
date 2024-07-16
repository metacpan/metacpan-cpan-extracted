use strict;
use warnings;
use Test::More tests => 12 + 1;
use Test::NoWarnings;

BEGIN { use_ok('Data::Radius::Util', qw(is_enum_type)) };

my %types = (
    string      => 0,
    integer     => 1,
    byte        => 1,
    short       => 1,
    signed      => 1,
    ipaddr      => 0,
    ipv6addr    => 0,
    avpair      => 0,
    'combo-ip'  => 0,
    octets      => 0,
    tlv         => 0,
);

foreach my $t (sort keys %types) {
    is( is_enum_type($t), $types{$t}, $t);
}
