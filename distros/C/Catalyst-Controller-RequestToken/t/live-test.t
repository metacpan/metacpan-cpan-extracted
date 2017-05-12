#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN {
    plan skip_all => 'this test needs Test::WWW::Mechanize::Catalyst'
        unless eval "require Test::WWW::Mechanize::Catalyst";
    plan tests => 15;
}

# make sure testapp works
use ok 'TestApp';

# a live test against TestApp, the test application
use Test::WWW::Mechanize::Catalyst 'TestApp';
my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->get_ok( 'http://localhost/', 'get main page' );
$mech->content_like( qr/it works/i, 'index page' );

$mech->get_ok( 'http://localhost/simple/form', 'get main page' );
$mech->content_like( qr/FORM/i, 'form page - valid' );

$mech->submit_form_ok( {}, 'submit form' );
$mech->content_like( qr/CONFIRM/i, 'submit to confirm page - valid' );

$mech->submit_form_ok( {}, 'submit form' );
$mech->content_like( qr/SUCCESS/i, 'submit to success page - valid' );

$mech->reload;
$mech->content_like( qr/INVALID ACCESS/i,
    'reload on success page - invalid' );

$mech->back;
$mech->content_like( qr/CONFIRM/i, 'back to confirm page - valid' );

$mech->submit;
$mech->content_like( qr/INVALID ACCESS/i,
    'submit to success page - invalid' );

$mech->back;
$mech->back;
$mech->reload;
$mech->content_like( qr/FORM/i, 'back to form page - valid' );
$mech->submit;
$mech->content_like( qr/CONFIRM/i, 'submit to confirm page - valid' );
$mech->submit;
$mech->content_like( qr/SUCCESS/i, 'submit to success page - valid' );

=cut
