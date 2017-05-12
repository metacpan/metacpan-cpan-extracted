#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Class::MOP;
use Class::MOP::Class;

use_ok("Catalyst::Plugin::Session::State::Stash" );
use_ok("Catalyst::Plugin::Session");

my $ctx_meta = Class::MOP::Class->create_anon_class(
    superclasses => [qw/
        Catalyst::Plugin::Session::State::Stash
        Catalyst::Plugin::Session
    /],
);

$ctx_meta->add_attribute( $_, reader => $_, default => sub { {} } )
    for qw/config session stash/;;
$ctx_meta->add_method("debug" => sub { 0 });

my $sessionid;
$ctx_meta->add_method( sessionid => sub { shift; $sessionid = shift if @_; $sessionid } );

$ctx_meta->make_immutable( replace_constructor => 1 );
my $app = $ctx_meta->name->new;

isa_ok($app, 'Catalyst::Plugin::Session::State::Stash');
isa_ok($app, 'Catalyst::Plugin::Session');

can_ok( $app, 'config');
can_ok( $app, "setup_session" );
can_ok( $app, '_session_plugin_config');

$app->setup_session;

is( $app->config->{'Plugin::Session'}{stash_key},
    '_session', "default cookie name is set" );

can_ok( $app, "get_session_id" );

ok( !$app->get_session_id, "no session id yet");

$app->stash->{ '_session' } = {id => 1};
$app->stash->{'session_id'} = {id => 2};
$app->stash->{'other_thing'} = { id => 3 };

is( $app->get_session_id, "1", "Pull newfound session id" );

$app->config->{'Plugin::Session'}{stash_key} = "session_id";

is( $app->get_session_id, "2", "Pull session id from second key" );

can_ok( $app, "set_session_id" );

# Check forwards config compatibility..
$app->config->{'Plugin::Session'} = {};
$app->setup_session;

is( $app->config->{'Plugin::Session'}{stash_key},
    '_session', "default cookie name is set when new stash key used" );

$app->config->{'Plugin::Session'}{stash_key} = "other_thing";

is( $app->get_session_id, "3", "Pull session id from key in new config" );

done_testing;

