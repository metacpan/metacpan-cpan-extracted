#!/usr/bin/perl -w
use strict;

my $g = MyGhost->new(
    logfile => 'daemon.log',
    pidfile => 'daemon.pid',
);

exit $g->ctrl(shift(@ARGV) // 'start', 0); # start, stop, restart, reload, status

1;

package MyGhost;

use parent 'Acme::Ghost';
use AnyEvent;

sub startup {
    my $self = shift;
    my $quit = AnyEvent->condvar;
    my $i = 0;

    # Create watcher timer
    my $watcher = AnyEvent->timer (after => 1, interval => 1, cb => sub {
        $quit->send unless $self->ok;
    });

    # Create process timer
    my $timer = AnyEvent->timer(after => 3, interval => 3, cb => sub {
        $self->log->info("Tick! " . ++$i);
        $quit->send if $i >= 10;
    });

    $self->log->debug("Start AnyEvent");
    $quit->recv; # Run!
    $self->log->debug("Finish AnyEvent");
}

1;

__END__
