#!/usr/bin/perl -w
use strict;

use Acme::Ghost;

my $g = Acme::Ghost->new(
    logfile => 'daemon.log',
    pidfile => 'daemon.pid',
);

my $cmd = shift(@ARGV) // 'start';
if ($cmd eq 'status') {
    if (my $runned = $g->status) {
        print "Running $runned\n";
    } else {
        print "Not running\n";
    }
    exit 0; # Ok
} elsif ($cmd eq 'stop') {
    if (my $runned = $g->stop) {
        if ($runned < 0) {
            print STDERR "Failed to stop " . $g->pid . "\n";
            exit 1; # Error
        }
        print "Stopped $runned\n";
    } else {
        print "Not running\n";
    }
    exit 0; # Ok
} elsif ($cmd ne 'start') {
    print STDERR "Command incorrect\n";
    exit 1; # Error
}

# Daemonize
$g->daemonize;

my $max = 10;
my $i = 0;
while (1) {
    $i++;
    sleep 3;
    $g->log->debug(sprintf("> %d/%d", $i, $max));
    last if $i >= $max;
}

exit 0;

__END__
