#!/usr/bin/perl
use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/lib";

use Test::More;
BEGIN {
    do {
        eval { require Test::WWW::Mechanize::Catalyst }
        and
        Test::WWW::Mechanize::Catalyst->VERSION('0.51')
    }
      or plan skip_all =>
      "Test::WWW::Mechanize::Catalyst is needed for this test";
}
use HTTP::Request;

use Test::More;
use Test::WWW::Mechanize::Catalyst;
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AuthTestApp');
$mech->get("http://localhost/moose");
is( $mech->status, 401, "status is 401" ) or die $mech->content;
$mech->content_lacks( "foo", "no output" );
my $r = HTTP::Request->new( GET => "http://localhost/moose" );
$r->authorization_basic(qw/foo s3cr3t/);
$mech->request($r);
is( $mech->status, 200, "status is 200" );
$mech->content_contains( "foo", "foo output" );

AuthTestApp->get_auth_realm('test')->credential->no_unprompted_authorization_required(1);
$mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AuthTestApp');
$mech->get("http://localhost/moose");
isnt( $mech->status, 401, "status isnt 401" ) or die $mech->content;

AuthTestApp->get_auth_realm('test')->credential->no_unprompted_authorization_required(0);
AuthTestApp->get_auth_realm('test')->credential->require_ssl(1);
$mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AuthTestApp');
$r = HTTP::Request->new( GET => "http://localhost/moose" );
$r->authorization_basic(qw/foo s3cr3t/);
$mech->request($r);
is( $mech->status, 401, "status is 401" );

done_testing;

