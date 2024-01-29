#!/usr/bin/perl -w
use strict;

my $g = MyGhost->new(
    logfile => 'daemon.log',
    pidfile => 'daemon.pid',
);

exit $g->ctrl(shift(@ARGV) // 'start'); # start, stop, restart, reload, status

1;

package MyGhost;

use parent 'Acme::Ghost';

sub init {
    my $self = shift;
    $SIG{HUP} = sub { $self->hangup }; # Listen USR2 (reload)
}
sub hangup {
    my $self = shift;
    $self->log->debug("Hang up!");
}
sub startup {
    my $self = shift;
    my $max = 100;
    my $i = 0;
    while ($self->ok) {
        $i++;
        sleep 3;
        $self->log->debug(sprintf("> %d/%d", $i, $max));
        last if $i >= $max;
    }
}

1;

__END__
