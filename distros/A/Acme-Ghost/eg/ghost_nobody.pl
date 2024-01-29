#!/usr/bin/perl -w
use strict;

my $g = MyGhost->new(
    pidfile => '/tmp/daemon.pid',
    user    => 'nobody',
    group   => 'nogroup',
);

exit $g->ctrl(shift(@ARGV) // 'start', 0); # start, stop, restart, status

1;

package MyGhost;

use parent 'Acme::Ghost';

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

sudo ACME_GHOST_DEBUG=1 perl -Ilib eg/ghost_nobody.pl start
