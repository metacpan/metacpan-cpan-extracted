#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 3;
use FindBin;
use lib "$FindBin::Bin/../lib";
use AnyEvent;
use AnyMQ;
use AnyMQ::Pg;
use Data::Dumper;

my $cv;
my $listener;
my $notif_count = 0;

BEGIN {
    use_ok('AnyMQ::Pg') || warn "Error using AnyMQ::Pg!\n";
}

SKIP: {
    skip "Set \$AMQPG_TESTS to test with AnyMQ::Pg", 2
        unless $ENV{AMQPG_TESTS};

    run_tests();
}

sub run_tests {
    my $bus = AnyMQ->new_with_traits(
        traits     => ['Pg'],
        dsn        => 'user=postgres dbname=postgres',
        on_connect       => \&connected,
        on_error         => \&error,
    );
    $cv = AE::cv;

    # listen for events
    my $topic = $bus->topic('LOLHI');
    $listener = $bus->new_listener($topic);
    $listener->poll(\&got_notification);
    
    # try publishing before we may be connected
    $topic->publish({ blah => 123 });

    $cv->recv;
}

sub got_notification {
    my ($notif) = @_;
    $notif_count++;
    is($notif->{blah}, 123, "Got published notification");
    $cv->send if $notif_count == 2;
}

sub connected {
    my ($self) = @_;
    
    # publish after we are connected
    my $topic = $self->topic('LOLHI');
    $topic->publish({ blah => 123 });
}

sub error {
    my ($self, $err) = @_;
    warn "Pg error: $err";
    $cv->send;
}


