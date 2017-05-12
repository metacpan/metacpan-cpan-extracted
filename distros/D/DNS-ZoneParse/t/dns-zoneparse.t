use strict;
BEGIN { $^W++ }
use Test::More tests => 61;
use File::Spec::Functions ':ALL';
use lib '../lib/';

# See if the module compiles - it should...
require_ok( 'DNS::ZoneParse' );

my $filename = catfile( ( splitpath( rel2abs( $0 ) ) )[0, 1], 'test-zone.db' );
my $FH;
open( $FH, '<', $filename ) or die "error loading test file $filename: $!";
my $zone_data = do { local $/; <$FH> };
close $FH;

sub on_parse_fail {
    my ( $dns, $line, $reason ) = @_;
    if ( $line !~ /this should fail/ ) {
        ok( 0, "Parse failure ($reason) on line: $line\n" );
    }
}

#create a DNS::ZoneParse object;

my $str_zonefile = DNS::ZoneParse->new( \$zone_data, undef, \&on_parse_fail );
ok( $str_zonefile,                                'new obj from string' );
ok( $str_zonefile->last_parse_error_count() == 2, "caught all errors" );
test_zone( $str_zonefile );

$str_zonefile = DNS::ZoneParse->new( $filename, undef, \&on_parse_fail );
ok( $str_zonefile,                                'new obj from filename' );
ok( $str_zonefile->last_parse_error_count() == 2, "caught all errors" );
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
    ok( defined $serial, 'serial is defined' );
    $zf->new_serial( 1 );
    my $newserial = $zf->soa->{serial};
    ok( $newserial = $serial + 1, 'new_serial( int )' );
    $serial = $zf->new_serial();
    ok( $serial > $newserial, 'new_serial()' );

    ok( $zf->fqname( $zf->soa ) eq $zf->soa->{'ORIGIN'}, 'SOA fqname test' );
    ok( $zf->fqname( $zf->a->[0] ) eq 'dns-zoneparse-test.net.', 'A @ fqname test' );
    ok( $zf->fqname( $zf->a->[1] ) eq 'localhost.dns-zoneparse-test.net.', 'A named fqname test' );

    is_deeply(
        $zf->soa,
        {
            'minimumTTL' => '86400',
            'serial'     => $serial,
            'ttl'        => '1H',
            'primary'    => 'ns0.dns-zoneparse-test.net.',
            'origin'     => '@',
            'email'      => 'support\\.contact.dns-zoneparse-test.net.',
            'retry'      => '3600',
            'refresh'    => '10801',
            'expire'     => '691200',
            'ORIGIN'     => 'dns-zoneparse-test.net.',
            'class'      => 'IN',
        },
        'SOA parsed ok',
    );

    is_deeply(
        $zf->a,
        [
            {
                'ttl'    => '43200',
                'name'   => '@',
                'class'  => 'IN',
                'host'   => '127.0.0.1',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                'ttl'    => '43200',
                'name'   => 'localhost',
                'class'  => 'IN',
                'host'   => '127.0.0.1',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                'ttl'    => '43200',
                'name'   => 'mail',
                'class'  => 'IN',
                'host'   => '127.0.0.1',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                'ttl'    => '43200',
                'name'   => 'www',
                'class'  => 'IN',
                'host'   => '127.0.0.1',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                'ttl'    => '43200',
                'name'   => 'www',
                'class'  => 'IN',
                'host'   => '10.0.0.2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                'ttl'    => '43200',
                'name'   => 'www',
                'class'  => 'IN',
                'host'   => '10.0.0.3',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                'ttl'    => '43200',
                'name'   => 'www',
                'class'  => 'IN',
                'host'   => '10.0.0.5',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                'ttl'    => '43200',
                'name'   => 'foo',
                'class'  => 'IN',
                'host'   => '10.0.0.6',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                'ttl'    => '43200',
                'name'   => 'mini',
                'class'  => 'IN',
                'host'   => '10.0.0.7',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
        ],
        'A records parsed OK',
    );

    is_deeply(
        $zf->ns,
        [
            {
                'ttl'    => '43200',
                'name'   => '@',
                'class'  => 'IN',
                'host'   => 'ns0.dns-zoneparse-test.net.',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                'ttl'    => '43200',
                'name'   => '@',
                'class'  => 'IN',
                'host'   => 'ns1.dns-zoneparse-test.net.',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
        ],
        'NS records parsed OK',
    );

    is_deeply(
        $zf->mx,
        [
            {
                'priority' => '10',
                'ttl'      => '43200',
                'name'     => '@',
                'class'    => 'IN',
                'host'     => 'mail',
                'ORIGIN'   => 'dns-zoneparse-test.net.',
            },
            {
                'priority' => '10',
                'ttl'      => '43200',
                'name'     => 'www',
                'class'    => 'IN',
                'host'     => '10.0.0.4',
                'ORIGIN'   => 'dns-zoneparse-test.net.',
            },
        ],
        'MX records parsed OK',
    );

    is_deeply(
        $zf->cname,
        [
            {
                'ttl'    => '43200',
                'name'   => 'ftp',
                'class'  => 'IN',
                'host'   => 'www',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                'ttl'    => '86401',
                'name'   => '-=+!@#$%^&*`~://+-,[]{}|\\?~`\'";',
                'class'  => 'IN',
                'host'   => 'ns0.dns-zoneparse-test.net.',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
        ],
        'CNAME records parsed OK',
    );

    is_deeply(
        $zf->txt,
        [
            {
                'text'   => 'web server',
                'ttl'    => '43200',
                'name'   => 'www',
                'class'  => 'IN',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                'text'   => 'This is a text message',
                'ttl'    => '43200',
                'name'   => 'soup',
                'class'  => 'IN',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                'text'   => 'This is another text message',
                'ttl'    => '86401',
                'name'   => 'txta',
                'class'  => 'IN',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                'text'   => 'I\'ve"got\\back\\"slashes;!',
                'ttl'    => '86401',
                'name'   => 'txttest1',
                'class'  => 'IN',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                'text'   => 'embedded"quote',
                'ttl'    => '86401',
                'name'   => 'txttest2',
                'class'  => 'IN',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                'text'   => 'noquotes',
                'ttl'    => '86401',
                'name'   => 'txttest3',
                'class'  => 'IN',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                'text'   => 'MORE (complicated) stuff -h343-',
                'ttl'    => '86401',
                'name'   => 'txttest4',
                'class'  => 'IN',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
        ],
        'TXT records parsed OK',
    );

    is_deeply(
        $zf->aaaa,
        [
            {
                'host'   => 'fe80::0260:83ff:fe7c:3a2a',
                'ttl'    => '43200',
                'name'   => 'icarus',
                'class'  => 'IN',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
        ],
        'AAAA records parsed OK',
    );

    is_deeply(
        $zf->rp,
        [
            {
                'name'   => 'txta',
                'class'  => 'IN',
                'ttl'    => '86401',
                'mbox'   => 'mbox',
                'text'   => 'sometext',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
        ],
        'RP records parsed OK',
    );

    is_deeply(
        $zf->srv,
        [
            {
                'name'     => 'srvtest1.a',
                'class'    => 'IN',
                'ttl'      => '86401',
                'priority' => 11,
                'weight'   => 22,
                'port'     => 33,
                'host'     => 'avalidname',
                'ORIGIN'   => 'dns-zoneparse-test.net.',
            },
            {
                'name'     => 'srvtest2',
                'class'    => 'IN',
                'ttl'      => '86401',
                'priority' => 11,
                'weight'   => 22,
                'port'     => 33,
                'host'     => 'avalidname',
                'ORIGIN'   => 'a.dns-zoneparse-test.net.',
            },
        ],
        'SRV records parsed OK',
    );

    is_deeply(
        $zf->loc,
        [
            {
                'name'   => 'borrowed.from.rfc.1876.com.',
                'ttl'    => '86401',
                'class'  => 'IN',
                'd1'     => '42',
                'm1'     => '21',
                's1'     => '54',
                'NorS'   => 'N',
                'd2'     => '71',
                'm2'     => '06',
                's2'     => '18',
                'EorW'   => 'W',
                'alt'    => '-24m',
                'siz'    => '30m',
                'hp'     => '',
                'vp'     => '',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                'name'   => 'borrowed2.from.rfc.1876.com.',
                'ttl'    => '86401',
                'class'  => 'IN',
                'd1'     => '42',
                'm1'     => '21',
                's1'     => '43.952',
                'NorS'   => 'N',
                'd2'     => '71',
                'm2'     => '5',
                's2'     => '6.344',
                'EorW'   => 'W',
                'alt'    => '-24m',
                'siz'    => '1m',
                'hp'     => '200m',
                'vp'     => '',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                'name'   => 'borrowed3.from.rfc.1876.com.',
                'ttl'    => '86401',
                'class'  => 'IN',
                'd1'     => '52',
                'm1'     => '14',
                's1'     => '05',
                'NorS'   => 'N',
                'd2'     => '00',
                'm2'     => '08',
                's2'     => '50',
                'EorW'   => 'E',
                'alt'    => '10m',
                'siz'    => '',
                'hp'     => '',
                'vp'     => '',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                'name'   => 'borrowed4.from.rfc.1876.com.',
                'ttl'    => '86401',
                'class'  => 'IN',
                'd1'     => '32',
                'm1'     => '7',
                's1'     => '19',
                'NorS'   => 'S',
                'd2'     => '116',
                'm2'     => '2',
                's2'     => '25',
                'EorW'   => 'E',
                'alt'    => '10m',
                'siz'    => '',
                'hp'     => '',
                'vp'     => '',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                'name'   => 'borrowed5.from.rfc.1876.com.',
                'ttl'    => '86401',
                'class'  => 'IN',
                'd1'     => '42',
                'm1'     => '21',
                's1'     => '28.764',
                'NorS'   => 'N',
                'd2'     => '71',
                'm2'     => '00',
                's2'     => '51.617',
                'EorW'   => 'W',
                'alt'    => '-44m',
                'siz'    => '2000m',
                'hp'     => '',
                'vp'     => '',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                'name'   => 'notborrowed.from.rfc.1876.com.',
                'ttl'    => '86401',
                'class'  => 'IN',
                'd1'     => '32',
                'm1'     => '7',
                's1'     => '',
                'NorS'   => 'S',
                'd2'     => '116',
                'm2'     => '',
                's2'     => '',
                'EorW'   => 'E',
                'alt'    => '-15m',
                'siz'    => '16m',
                'hp'     => '17m',
                'vp'     => '18m',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
        ],
        'LOC records parsed OK',
    );

    is_deeply(
        $zf->hinfo,
        [
            {
                'name'   => 'icarus',
                'class'  => 'IN',
                'ttl'    => '43200',
                'cpu'    => 'server',
                'os'     => 'freebsd',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                'name'   => 'soup',
                'class'  => 'IN',
                'ttl'    => '86401',
                'cpu'    => 'server',
                'os'     => 'freebsd',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },

            {
                name     => 'commenttest0',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'test',
                os       => 'test2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest1',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'test',
                os       => 'test2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest2',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'test',
                os       => 'test2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest3',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'test',
                os       => 'test2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest4',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'test',
                os       => 'test2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest5',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'test',
                os       => 'test2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest6',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'test',
                os       => 'test2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest7',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'test',
                os       => 'test2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest8',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'test',
                os       => 'test2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest9',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'test',
                os       => 'test2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest10',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'test',
                os       => 'test2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest11',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'test',
                os       => 'test2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest12',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'test',
                os       => 'test2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest13',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'test',
                os       => 'test2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest14',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'test',
                os       => 'test2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest15',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'test',
                os       => 'test2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest16',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'test',
                os       => 'tes;t2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest17',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'test',
                os       => 'tes;t2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest18',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'test',
                os       => 'tes;t2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest19',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'test',
                os       => 'tes;t2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest20',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'test',
                os       => 'tes;t2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest21',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'test',
                os       => 'tes;t2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest22',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'test',
                os       => 'tes;t2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest23',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'test',
                os       => 'tes;t2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest24',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'te;st',
                os       => 'test2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest25',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'te;st',
                os       => 'test2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest26',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'te;st',
                os       => 'test2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest27',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'te;st',
                os       => 'test2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest28',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'te;st',
                os       => 'test2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest29',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'te;st',
                os       => 'test2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest30',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'te;st',
                os       => 'test2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest31',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'te;st',
                os       => 'test2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest32',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'te;st',
                os       => 'te;st2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest33',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'te;st',
                os       => 'te;st2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest34',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'te;st',
                os       => 'te;st2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
            {
                name     => 'commenttest35',
                class    => 'IN',
                ttl      => '86401',
                cpu      => 'te;st',
                os       => 'te;st2',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },

        ],
        'HINFO records parsed OK',
    );

    is_deeply(
        $zf->generate,
        [
            {
                'rhs' => '10.0.0.$',
                'ttl' => '43200',
                'lhs' => 'www$',
                'range' => '1-10/1',
                'type' => 'A',
                'class' => 'IN',
                'ORIGIN' => 'dns-zoneparse-test.net.',
            },
        ],
        '$GENERATE directives parsed OK',
    );

}
