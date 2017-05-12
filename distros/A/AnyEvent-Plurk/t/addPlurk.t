#!/usr/bin/env perl
use common::sense;
use Test::More;

unless($ENV{TEST_ANYEVENT_PLURK}) {
    plan(skip_all => "define TEST_ANYEVENT_PLURK env to test.")
}

use AnyEvent;
use AnyEvent::Plurk;

my ($api_key,$username,$password) = split(" ", $ENV{TEST_ANYEVENT_PLURK});

my $p = AnyEvent::Plurk->new(
    api_key  => $api_key,
    username => $username,
    password => $password
);

$p->login;

my $plurk = $p->add_plurk(rand ." $$ Lorem ipsum $$");

ok($plurk->{plurk_id} > 0);

$p->delete_plurk($plurk->{plurk_id});

done_testing;
