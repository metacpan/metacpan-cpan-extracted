package App::ptimeout;

use strict;
use warnings;
no warnings 'numeric';

use Proc::Killfam;

our $VERSION = '1.0.0';

sub _run {
    my($timeout, @argv) = @_;

    if($timeout =~ /m$/) { $timeout *= 60 }
     elsif($timeout =~ /h$/) { $timeout *= 3600 }

    my $pid = fork();
    if(!defined($pid)) {
        die("Error forking\n")
    } elsif($pid) { # still in the ptimeout process
        # if the watchdog kills us, exit with status 124
        $SIG{TERM} = sub { exit 124 };

        my $status = system @argv;
        kill SIGTERM => $pid; # kill the watchdog
        exit $status >> 8;
    } else { # watchdog child process
        sleep $timeout;
        warn "timed out\n";
        killfam SIGTERM => getppid;
    }
}

=head1 NAME

App::ptimeout - module implementing L<ptimeout>

=head1 AUTHOR, COPYRIGHT and LICENCE

Copyright 2021 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This software is free-as-in-speech software, and may be used,
distributed, and modified under the terms of either the GNU
General Public Licence version 2 or the Artistic Licence.  It's
up to you which one you use.  The full text of the licences can
be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This is also free-as-in-mason software.

1;
