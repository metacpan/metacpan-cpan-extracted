#!/usr/bin/perl

use strict;
use warnings;

use v5.10;

use AnyEvent;
use AnyEvent::Postfix::Logs;

my $guard = AnyEvent->condvar;

my %traffic;
my $log = AnyEvent::Postfix::Logs->new(
    sources => [ \*STDIN ],
    on_mail => sub {
        my $mail = shift;
        $traffic{ $_ } += $mail->{size} for @{ $mail->{to} };
    }
);

my $usr1 = AnyEvent->signal(
    signal => "USR1",
    cb     => sub {
        say "$_: $traffic{$_}" for keys %traffic;
        say "---";
        %traffic = ();
    },
);

my $usr2 = AnyEvent->signal(
    signal => "USR2",
    cb     => sub {
        $guard->broadcast;
    },
);

say "Watcher running with pid ", $$;

$guard->wait;
