#!/usr/bin/env perl

use strict;
use warnings;

use DateTime;
use DateTime::Format::HTTP;
use Digest::MD5 qw( md5_hex );
use URI;

use Test::More;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# make sure testapp works
use ok 'TestApp';

# a live test against TestApp, the test application
use Test::WWW::Mechanize::Catalyst 'TestApp';
my $m = Test::WWW::Mechanize::Catalyst->new;
$m->get_ok('http://localhost/', 'GET /');
$m->content_like(qr/Content[ ]Ok/, 'expected text');

isa_ok(my $c = $m->catalyst_app, "Catalyst", "catalyst_app");

can_ok($c, qw( not_cached )) or BAIL_OUT "missing expected method";

foreach my $hdr (qw( ETag Expires Last-Modified )) {

    my $aux = DateTime::Format::HTTP->format_datetime(
	DateTime->now->subtract( minutes => 12 )
    );

    my $val = (($hdr eq 'Expires') || ($hdr eq 'Last-Modified')) ? $aux : md5_hex($aux);

    my $uri = URI->new('http://localhost/');
    $uri->query_form( $hdr => $val );

    my $res = $m->get($uri);
    ok($res->is_success, "GET ${uri}");
    is($res->header($hdr), $val, $hdr) or BAIL_OUT "${hdr} header not set as expected";
}


done_testing;
