#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

binmode STDOUT, ':utf8';

use AnyEvent;
use AnyEvent::Lingr;

use Config::Pit;

my $conf = pit_get 'lingr.com', require => {
    'user'     => 'lingr username',
    'password' => 'lingr password',
    'api_key'  => 'lingr api_key (optional)',
};

my $cv = AE::cv;

my $lingr = AnyEvent::Lingr->new(%$conf);
$lingr->on_error(sub {
    my ($msg) = @_;

    if ($msg =~ /^596:/) {
        # reconnect after the timeout
        $lingr->start_session;
    }
    else {
        warn 'Error: ', $msg;
        $cv->send;
    }
});
$lingr->on_room_info(sub {
    my ($rooms) = @_;

    my @rooms = map { $_->{id} } @$rooms;
    print "Subscribed: ", join(',', @rooms), "\n";
});
$lingr->on_event(sub {
    my ($event) = @_;

    if (my $msg = $event->{message}) {
        print sprintf "[%s] %s: %s\n", $msg->{room}, $msg->{nickname}, $msg->{text};
    }
});

$lingr->start_session;

$cv->recv;


