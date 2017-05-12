package App::DistSync::Lock; # $Id: Lock.pm 5 2014-10-08 16:24:59Z abalama $
use strict;

=head1 NAME

App::DistSync::Lock - Lock File Manipulation

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

  use File::Pid;
  
  my $lock = new App::DistSync::Lock(
          file => '/some/file.lock',
          hold => 3600,
          pid  => $$,
      );
  
  if ( my $pid = $lock->running ) {
      die "Already running: $num\n";
  }

=head1 DESCRIPTION

This module manages a lock file. It will create a lock file,
query the process within to discover if it's still running, and remove
the lock file. This module based on L<File::Pid> and L<LockFile::Simple>.

=head2 new

    my $lock = new App::DistSync::Lock;

    my $lock = new App::DistSync::Lock(
          file => '/var/run/daemon.pid',
          hold => 3600,
          pid  => $$,
      );


This constructor takes three optional paramters.

C<file> - The name of the lock file to work on. If not specified, a lock
file located in current directory will be created that matches
C<MANIFEST.LOCK>.

C<hold> - Max amount of seconds before breaking lock (0 for never, default is 3600)

C<pid> - The pid to write to a new lockfile. If not specified, C<$$> is
used when the lock file doesn't exist. When the lock file does exist, the
pid inside it is used.

=head2 running

    my $pid = $lock->running;
    die "Service already running: $pid\n" if $pid;

Checks to see if the pricess identified in the lock file is still
running. If the process is still running, the pid is returned. Otherwise
C<undef> or 0 is returned.

=head2 status

    my $status = $lock->status;

Returns current status

=head2 error

    my $error = $lock->error;

Returns current error message

=head1 HISTORY

See C<CHANGES> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

C<perl>, L<File::Pid>, L<LockFile::Simple>

=head1 AUTHOR

Serz Minus (Lepenkov Sergey) L<http://www.serzik.com> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2014 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut

use vars qw/$VERSION/;
$VERSION = '1.00';

use File::Basename qw/basename/;
use Carp;

sub new {
    my $class = shift;
    my $stamp = time;
    my ($name) = basename($0);
    
    my $self = bless({@_,
            status  => 0,
            error   => "",
            stamp   => $stamp,
            name    => $name,
            run     => 0,
        }, $class);

    $self->{file} ||= 'MANIFEST.LOCK';
    my $file = $self->{file};

    if (exists($self->{pid}) && defined($self->{pid})) {
        croak("Incorrect pid specified") unless $self->{pid} =~ /^[0-9]{1,11}$/;
    } else {
        $self->{pid} = $$;
    }
    my $pid = $self->{pid};

    if (exists($self->{hold}) && defined($self->{hold})) {
        croak("Incorrect hold specified") unless $self->{hold} =~ /^[0-9]{1,11}$/;
    } else {
        $self->{hold} = 3600;
    }
    my $hold = $self->{hold};
    
    # Current string
    my $str = sprintf("%d#%d#%s", $pid, $stamp, $name);
    
    # Check existing file
    local *RD_LOCK_FILE;
    if ($file && -e $file) {
        unless (open(RD_LOCK_FILE, "<", $file)) {
            $self->{error} = sprintf("Can't open file %s to read: %s", $file, $!);
            return $self;
        }
        my $l;
        chomp($l = <RD_LOCK_FILE>);
        $l = "" unless defined $l;
        unless (close RD_LOCK_FILE) {
            $self->{error} = sprintf("Can't close file %s: %s", $file, $!);
            return $self;
        }
        if ($l eq $str) {
            # This procces == Checking process
            $self->{error} = "Process already exists";
            return $self;
        } else {
            my ($r_pid, $r_stamp, $r_name) = split(/#/, $l);
            if ($r_pid && $self->running($r_pid)) {
                $self->{run} = $r_pid;
                # If file too old to be considered stale?
                if (($hold > 0) && (($stamp - $r_stamp) > $hold)) {
                    unless (unlink $file) {
                        $self->{error} = sprintf("Can't unlink file %s: %s", $file, $!);
                        return $self;
                    }
                } else {
                    $self->{error} = "Process #$r_pid already running";
                    return $self;
                }
            }
        }
    }
    
    # Create new file
    local *MY_LOCK_FILE;
    unless (open(MY_LOCK_FILE, ">", $file)) {
        $self->{error} = sprintf("Can't open file %s to write: %s", $file, $!);
        return $self;
    }
    unless (print MY_LOCK_FILE sprintf("%s\n", $str)) {
        $self->{error} = sprintf("Can't print to file %s: %s", $file, $!);
        return $self;
    }
    unless (close MY_LOCK_FILE) {
        $self->{error} = sprintf("Can't close file %s: %s", $file, $!);
        return $self;
    }
    
    $self->{status} = 1;
    return $self;
}
sub error { 
    my $self = shift;
    #my $s = shift;
    #$self->{error} = $s if defined $s;
    return $self->{error};
}
sub status { 
    my $self = shift;
    #my $s = shift;
    #$self->{status} = $s if defined $s;
    return $self->{status};
}
sub running { 
    my $self = shift;
    my $pid = shift;
    $pid = $self->{run} unless defined $pid;
    return 0 unless $pid;
    unless ($pid =~ /^[0-9]{1,11}$/) {
        carp("Incorrect pid specified");
        return 0;
    }
    return kill(0, $pid)
        ? $pid
        : 0;
}

sub DESTROY {
    my $self = shift;
    my $file = $self->{file};
    my $status = $self->{status};
    return unless $file && $status && -e $file;
    unlink $file or carp(sprintf("Can't unlink file %s: %s", $file, $!));
}

1;
