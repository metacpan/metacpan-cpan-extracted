#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use_ok "Catalyst::Plugin::Snippets";

use Test::MockObject;
use Test::MockObject::Extends;

my $req    = Test::MockObject->new;
my $res    = Test::MockObject->new;
my $cache  = Test::MockObject->new;
my $action = Test::MockObject->new;
my $c      = Test::MockObject::Extends->new("Catalyst::Plugin::Snippets");

$req->set_always( arguments => ["arg"] );

my ( $content_type, $body );
$res->mock(
    content_type => sub { shift; $content_type = shift if @_; $content_type } );
$res->mock( body => sub { shift; $body = shift if @_; $body } );

my %cache;
$cache->mock( get => sub { $cache{ $_[1] } } );
$cache->mock( set => sub { $cache{ $_[1] } = $_[2] } );

$action->set_always( name => "action_name" );

my %config;
$c->set_always( config => { snippets => \%config } );

$c->set_always( request   => $req );
$c->set_always( response  => $res );
$c->set_always( cache     => $cache );
$c->set_always( action    => $action );
$c->set_always( sessionid => "_this_is_sid_" );

$c->setup;

is( $config{format}, "plain", "config: format" );
ok( $config{allow_refs}, "config: allow_refs" );
ok( !$config{use_session_id}, "config: use_session_id" );
is( $config{content_type}, "text/plain", "config: content_type" );

$c->snippet( "foo", "bar", 4 );
is( $c->snippet( "foo", "bar" ), 4, "get and set client data" );

$config{use_session_id} = 1;

$c->snippet( "foo", "bar", 123 );
is( $c->snippet( "foo", "bar" ),
    123, "get and set client in a certain session" );

my $old_sid = $c->sessionid;

$c->set_always( sessionid => "jsahtat" );

$c->snippet( "foo", "bar", 321 );
is( $c->snippet( "foo", "bar" ),
    321, "get and set client in another session" );

$c->set_always( sessionid => $old_sid );

is( $c->snippet( "foo", "bar" ),
    123, "ensures that cliend data doesn't clash with sessionid in key" );

$c->serve_snippet;
is( $res->body, "", "body is empty" );

$c->snippet( "action_name", "arg", "moose" );

$c->serve_snippet;
is( $res->body, "moose", "body is correct" );

if ( eval { require JSON::Syck } ) {
    $config{format} = "json";

    $c->serve_snippet;
    is( JSON::Syck::Load( $res->body ), "moose", "JSON body is correct" );

    $c->snippet( "action_name", "arg", { key => "value" } );

    $c->serve_snippet;
    is_deeply(
        JSON::Syck::Load( $res->body ),
        { key => "value" },
        "JSON body is correct - for deep struct"
    );
}


