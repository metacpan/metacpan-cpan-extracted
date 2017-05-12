use strict;
BEGIN { $^W++ }
use Test::More tests => 19;
use lib '../lib/';

# See if the module compiles - it should...
require_ok( 'DNS::ZoneParse' );

my $zone_data = do { local $/; <DATA> };
close DATA;

sub on_parse_fail {
    my ( $dns, $line, $reason ) = @_;
    if ( $line !~ /this should fail/ ) {
        ok( 0, "Parse failure ($reason) on line: $line\n" );
    }
}

my $str_zonefile = DNS::ZoneParse->new( \$zone_data, undef, \&on_parse_fail );
ok( $str_zonefile,                                'new obj from string' );
ok( $str_zonefile->last_parse_error_count() == 0, "caught all errors (none!)" );

ok( $str_zonefile->ttl_to_int( '0' ) == 0, 'ttl 0' );
ok( $str_zonefile->ttl_to_int( '1' ) == 1, 'ttl 1' );
ok( $str_zonefile->ttl_to_int( '1S' ) == 1, 'ttl 1S' );
ok( $str_zonefile->ttl_to_int( '1M' ) == 60, 'ttl 1M' );
ok( $str_zonefile->ttl_to_int( '1H' ) == 60 * 60, 'ttl 1H' );
ok( $str_zonefile->ttl_to_int( '1D' ) == 24 * 60 * 60, 'ttl 1D' );
ok( $str_zonefile->ttl_to_int( '1W' ) == 7 * 24 * 60 * 60, 'ttl 1W' );

ok( $str_zonefile->ttl_to_int( '4D' ) == 4 * 24 * 60 * 60, 'ttl 4D' );
ok( $str_zonefile->ttl_to_int( '8M' ) == 8 * 60, 'ttl 8M' );
ok( $str_zonefile->ttl_to_int( '8000S' ) == 8000, 'ttl 8000S' );

ok( $str_zonefile->ttl_to_int( '0W0D0H0M1S' ) == 1, 'ttl 0W0D0H0M1S' );
ok( $str_zonefile->ttl_to_int( '4W3D2H1M0S' ) == ( 0 + ( 60 * ( 1 + 60 * ( 2 + 24 * ( 3 +  7 * 4 ) ) ) ) ), 'ttl 4W3D2H1M0S' );
ok( $str_zonefile->ttl_to_int( '1W2D1H2M1S' ) == ( 1 + ( 60 * ( 2 + 60 * ( 1 + 24 * ( 2 +  7 * 1 ) ) ) ) ), 'ttl 1W2D1H2M1S' );
ok( $str_zonefile->ttl_to_int( '2W1D400H1M2S' ) == ( 2 + ( 60 * ( 1 + 60 * ( 400 + 24 * ( 1 +  7 * 2 ) ) ) ) ), 'ttl 2W1D400H1M2S' );

ok( $str_zonefile->ttl_to_int( '1w0s' ) == ( 0 + ( 60 * ( 0 + 60 * ( 0 + 24 * ( 0 +  7 * 1 ) ) ) ) ), 'ttl 1w0s' );
ok( $str_zonefile->ttl_to_int( '4h1D' ) == ( 0 + ( 60 * ( 0 + 60 * ( 4 + 24 * ( 1 +  7 * 0 ) ) ) ) ), 'ttl 4h1D' );

__DATA__
dns-zoneparse-test.net.        IN      SOA     ns0.dns-zoneparse-test.net.   support\.contact.dns-zoneparse-test.net. (
                        2000100502   ; serial number
                        10801       ; refresh
                        3600        ; retry
                        691200      ; expire
                        86400     ) ; minimum TTL

@                       IN      NS      ns0.dns-zoneparse-test.net.
@         43200         IN      NS      ns1.dns-zoneparse-test.net.
