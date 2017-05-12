#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# make sure testapp works
use ok 'TestApp';

use Test::WWW::Mechanize::Catalyst 'TestApp';

isa_ok(
  my $session_mech = Test::WWW::Mechanize::Catalyst->new,
  'Test::WWW::Mechanize::Catalyst' => '$session_mech'
);

$session_mech->get_ok('/set_session_foo', 'setting session foo');
$session_mech->content_like(qr/session foo/i, 'session setter ran okay');

$session_mech->get_ok('/check_session_foo', 'checking session foo');
$session_mech->content_like(qr/still bar/i, 'session works sanity check');

$session_mech->get_ok('/session_id', 'fetching session id');
ok(my $sid = $session_mech->content, 'assuming this is a session id');

{ # $hack_mech instead of $session_mech

  isa_ok(
    my $hack_mech = Test::WWW::Mechanize::Catalyst->new,
    'Test::WWW::Mechanize::Catalyst' => '$hack_mech'
  );

  $hack_mech->get_ok('/check_session_foo', 'checking session item');
  $hack_mech->content_unlike(qr/still bar/i, 'session foo is empty');

  $hack_mech->get_ok("/check_session_foo?testapp_session=$sid", 'checking session item');
  $hack_mech->content_like(qr/still bar/i, 'session foo works when passing $sid in url');

  $hack_mech->get_ok("/set_session_bazz", 'setting session bazz');
  $hack_mech->content_like(qr/session bazz/i, 'session setter ran okay');

} # $hack_mech cycle complete

$session_mech->get_ok('/check_session_bazz', 'checking session bazz');
$session_mech->content_like(qr/still quxx/i, 'sucessfully completed complete session cycle');


done_testing;
