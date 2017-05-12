use strict;
BEGIN { $^W++ }
use Test::More tests => 11;
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
test_zone( $str_zonefile );

my $serialized = $str_zonefile->output();
$str_zonefile = DNS::ZoneParse->new( \$serialized, undef, \&on_parse_fail );
ok( $str_zonefile,                                'new obj from output' );
ok( $str_zonefile->last_parse_error_count() == 0, "caught all errors (none!)" );
test_zone( $str_zonefile );

sub test_zone {
    my $zf = shift;

    # See if the new_serial method works.
    my $serial = $zf->soa->{serial};
    ok( $serial == 2000100502, 'serial is correct' );

    is_deeply(
        $zf->soa,
        {
            'minimumTTL' => '86400',
            'serial'     => $serial,
            'ttl'        => '3600',
            'primary'    => 'ns0.dns-zoneparse-test.net.',
            'origin'     => 'dns-zoneparse-test',
            'email'      => 'support\\.contact.dns-zoneparse-test.net.',
            'retry'      => '3600',
            'refresh'    => '10801',
            'expire'     => '691200',
            'ORIGIN'     => 'net.',
            'class'      => 'IN',
        },
        'SOA parsed ok',
    );

    # Woah! This is expected. We have an explicit origin and then @ records,
    # which means the @ records point to the $ORIGIN. $ORIGIN is only set by
    # the SOA when $ORIGIN isn't set explicitly!
    is_deeply(
        $zf->ns,
        [
            {
                'ttl'    => '43200',
                'name'   => '@',
                'class'  => 'IN',
                'host'   => 'ns0.dns-zoneparse-test.net.',
                'ORIGIN' => 'net.',
            },
            {
                'ttl'    => '43200',
                'name'   => '@',
                'class'  => 'IN',
                'host'   => 'ns1.dns-zoneparse-test.net.',
                'ORIGIN' => 'net.',
            },
        ],
        'NS records parsed OK',
    );

}

__DATA__
$TTL 1H
$ORIGIN net.
dns-zoneparse-test      3600   IN      SOA     ns0.dns-zoneparse-test.net.   support\.contact.dns-zoneparse-test.net. (
                        2000100502   ; serial number
                        10801       ; refresh
                        3600        ; retry
                        691200      ; expire
                        86400     ) ; minimum TTL

@         43200         IN      NS      ns0.dns-zoneparse-test.net.
@                       IN      NS      ns1.dns-zoneparse-test.net.
