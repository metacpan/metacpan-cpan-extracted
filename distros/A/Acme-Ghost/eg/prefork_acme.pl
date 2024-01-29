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
use Data::Dumper qw/Dumper/;

sub init {
    my $self = shift;
    $SIG{HUP} = sub { $self->hangup };
}
sub hangup {
    my $self = shift;
    $self->log->debug(Dumper($self->{pool}));
}
sub spirit {
    my $self = shift;
    my $max = 10;
    my $i = 0;
    while ($self->tick) {
        $i++;
        sleep 1;
        $self->log->debug(sprintf("$$> %d/%d", $i, $max));
        last if $i >= $max;
    }
}

1;

__END__

perl -Ilib eg/prefork_acme.pl start
