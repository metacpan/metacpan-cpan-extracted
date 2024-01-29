#!/usr/bin/perl -w
use strict;

my $g = MyGhost->new(
    logfile => 'daemon.log',
    pidfile => 'daemon.pid',
);
exit $g->ctrl(shift(@ARGV) // 'start');

1;

package MyGhost;

use parent 'Acme::Ghost::Prefork';
use Mojo::IOLoop;

sub init {
    my $self = shift;
    $self->{loop} = Mojo::IOLoop->new;
}
sub spirit {
    my $self = shift;
    my $loop = $self->{loop};
    my $max = 10;
    my $i = 0;

    # Add a timers
    my $timer = $loop->timer(5 => sub {
        my $l = shift; # loop
        $self->log->info("Timer!");
    });

    my $recur = $loop->recurring(1 => sub {
        my $l = shift; # loop
        $l->stop unless $self->tick;
        $self->log->debug(sprintf("$$> %d/%d", ++$i, $max));
        $l->stop if $i >= $max;
    });

    $self->log->debug("Start IOLoop");

    # Start event loop if necessary
    $loop->start unless $loop->is_running;

    $self->log->debug("Finish IOLoop");
}

1;

__END__

perl -Ilib eg/prefork_ioloop.pl start
