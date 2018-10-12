package Build::PPK::Pipeline;

# Copyright (c) 2018, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use Carp;
use POSIX ();

sub open {
    my ( $class, @subs ) = @_;
    my @pids;

    pipe my ( $child_out, $in )       or confess("Unable to create a file handle pair for standard input piping: $!");
    pipe my ( $error_out, $error_in ) or confess("Unable to create a file handle pair for standard error piping: $!");

    foreach my $sub (@subs) {
        pipe my ( $out, $child_in ) or confess("Unable to create a file handle pair for standard output piping: $!");

        my $pid = fork();

        if ( $pid == 0 ) {
            POSIX::dup2( fileno($child_out), fileno(STDIN) )  or die("Cannot dup2() output to current child stdin: $!");
            POSIX::dup2( fileno($child_in),  fileno(STDOUT) ) or die("Cannot dup2() input to current child stdout: $!");
            POSIX::dup2( fileno($error_in),  fileno(STDERR) ) or die("Cannot dup2() error input to current child: $!");

            exit $sub->();
        }
        elsif ( !defined($pid) ) {
            confess("Unable to fork(): $!");
        }

        $child_out = $out;

        push @pids, $pid;
    }

    return bless {
        'in'   => $in,
        'out'  => $child_out,
        'err'  => $error_out,
        'pids' => \@pids
    }, $class;
}

sub close {
    my ($self) = @_;

    close $self->{'in'};
    close $self->{'out'};
    close $self->{'err'};

    my %statuses;

    foreach my $pid ( @{ $self->{'pids'} } ) {
        waitpid( $pid, 0 );
        $statuses{$pid} = $? >> 8;
    }

    return \%statuses;
}

1;
