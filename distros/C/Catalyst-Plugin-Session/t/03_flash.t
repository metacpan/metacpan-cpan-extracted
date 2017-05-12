#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;
use Test::MockObject::Extends;
use Test::Exception;
use Test::Deep;

my $m;
BEGIN { use_ok( $m = "Catalyst::Plugin::Session" ) }

my $c = Test::MockObject::Extends->new($m);

my $flash = {};
$c->mock(
    get_session_data => sub {
        my ( $c, $key ) = @_;
        return $key =~ /expire/ ? time() + 1000 : $flash;
    },
);
$c->mock("debug" => sub { 0 });
$c->mock("store_session_data" => sub { $flash = $_[2] });
$c->mock("delete_session_data" => sub { $flash = {} });
$c->set_always( _sessionid => "deadbeef" );
$c->set_always( config     => { session => { expires => 1000 } } );
$c->set_always( stash      => {} );

is_deeply( $c->session, {}, "nothing in session" );

is_deeply( $c->flash, {}, "nothing in flash" );

$c->flash->{foo} = "moose";

$c->finalize_body;

is_deeply( $c->flash, { foo => "moose" }, "one key in flash" );

cmp_deeply( $c->session, { __updated => re('^\d+$'), __flash => $c->flash }, "session has __flash with flash data" );

$c->flash(bar => "gorch");

is_deeply( $c->flash, { foo => "moose", bar => "gorch" }, "two keys in flash" );

cmp_deeply( $c->session, { __updated => re('^\d+$'), __flash => $c->flash }, "session still has __flash with flash data" );

$c->finalize_body;

is_deeply( $c->flash, { bar => "gorch" }, "one key in flash" );

$c->finalize_body;

$c->flash->{test} = 'clear_flash';

$c->finalize_body;

$c->clear_flash();

is_deeply( $c->flash, {}, "nothing in flash after clear_flash" );

$c->finalize_body;

is_deeply( $c->flash, {}, "nothing in flash after finalize after clear_flash" );

cmp_deeply( $c->session, { __updated => re('^\d+$'), }, "session has empty __flash after clear_flash + finalize" );

$c->flash->{bar} = "gorch";

$c->config->{session}{flash_to_stash} = 1;

$c->finalize_body;
$c->prepare_action;

is_deeply( $c->stash, { bar => "gorch" }, "flash copied to stash" );
