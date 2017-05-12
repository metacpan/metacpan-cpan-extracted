#!/usr/bin/perl
use strict;
use AnyEvent::FriendFeed::Realtime;

my($user, $remote_key, $request) = @ARGV;
my $done = AnyEvent->condvar;

binmode STDOUT, ":utf8";

my $client = AnyEvent::FriendFeed::Realtime->new(
    username   => $user,
    remote_key => $remote_key,
    request    => $request || "/feed/home",
    on_entry   => sub {
        my $entry = shift;
        print "$entry->{from}{name}: $entry->{body}\n";
    },
    on_error   => sub {
        warn "ERROR: $_[0]";
        $done->send;
    },
);

$done->recv;
