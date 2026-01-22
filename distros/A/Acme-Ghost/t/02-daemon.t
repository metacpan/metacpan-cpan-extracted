#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2026 D&D Corporation
#
# This program is distributed under the terms of the Artistic License 2.0
#
#########################################################################
use strict;
use Test::More;
use Acme::Ghost;

# Set debug mode
$ENV{ACME_GHOST_DEBUG} //= 0;

my $g = Acme::Ghost->new(
    logfile => 'daemon.log',
    pidfile => 'daemon.pid',
);
#note explain $ghost;

ok !$g->is_daemonized, "Is not daemonized";
is $g->pid, 0, "No PID in ghost process";
#note $g->pid;

done_testing;

__END__

ACME_GHOST_DEBUG=1 prove -lv t/02-daemon.t
tail -f daemon.log | bell -s mush -v 36000 | ccze -A -p syslog
