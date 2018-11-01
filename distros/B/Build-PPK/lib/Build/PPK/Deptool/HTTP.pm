package Build::PPK::Deptool::HTTP;

# Copyright (c) 2018, cPanel, L.L.C.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use POSIX ();
use Fcntl ();

use Cwd            ();
use File::Basename ();

use Build::PPK::Pipeline ();

use Carp ();

sub fetch_dist {
    my ( $class, %args ) = @_;

    die('No URL specified')         unless $args{'url'};
    die('No output path specified') unless $args{'path'};

    return if -e $args{'path'};

    my $tmpfile;

    my @filters = (
        sub {
            exec qw(wget -O -), $args{'url'} or Carp::confess("Unable to spawn wget: $!");
        }
    );

    if ( $args{'path'} =~ /\.tar/ ) {
        $tmpfile = "$args{'path'}.tmp";

        push @filters, sub {
            open( my $fh, '>', $tmpfile ) or Carp::confess("Cannot open $tmpfile for writing: $!");

            while ( my $len = read( STDIN, my $buf, 4096 ) ) {
                print $fh $buf;
            }

            close $fh;

            exit 0;
        };
    }
    else {
        unless ( -d $args{'path'} ) {
            mkdir( $args{'path'} ) or Carp::confess("Unable to create distribution directory $args{'path'} : $!");
        }

        push @filters, sub {
            chdir( $args{'path'} ) or Carp::confess("Unable to chdir() to $args{'path'}: $!");
            exec qw(tar pzxf -) or Carp::confess("Unable to spawn tar: $!");
        };
    }

    my $pipeline = Build::PPK::Pipeline->open(@filters);

    close $pipeline->{'in'};

    sysopen( my $null_fh, '/dev/null', &Fcntl::O_RDONLY ) or Carp::confess("Unable to open /dev/null: $!");

    POSIX::dup2( fileno($null_fh), fileno( $pipeline->{'out'} ) );

    my $stderr;

    while ( my $len = sysread( $pipeline->{'err'}, my $buf, 512 ) ) {
        $stderr .= $buf;
    }

    my $statuses = $pipeline->close;
    my $errors;

    foreach my $pid ( keys %{$statuses} ) {
        my $status = $statuses->{$pid};

        next unless $status != 0;

        if ($stderr) {
            chomp $stderr;
            $errors = "Process $pid died with nonzero exit status $status: $stderr";
        }
        else {
            $errors = "Process $pid died with nonzero exit status $status";
        }
    }

    if ($errors) {
        unlink($tmpfile) if $tmpfile;
        die($errors);
    }

    if ($tmpfile) {
        unless ( rename( $tmpfile => $args{'path'} ) ) {
            die("Unable to rename temporary file $tmpfile to $args{'path'}: $!");
        }
    }

    return;
}

1;
