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

$p->reg_cb(
    unread_plurks => sub {
        my ($p, $plurks) = @_;
        is(ref($plurks), "ARRAY", "Received latest plurks");

        for my $pu (@$plurks) {
            is(ref($pu->{owner}), "HASH");
        }

        done_testing;
        exit;
    }
);

my $v = AE::cv;
$p->start;
$v->recv;
