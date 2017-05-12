package Captive::Portal::LockHandle;

use strict;
use warnings;

=head1 NAME

Captive::Portal::LockHandle - lock handling for Captive::Portal

=cut

our $VERSION = '4.10';

use Log::Log4perl qw(:easy);
use Try::Tiny;
use Time::HiRes qw(usleep ualarm);
use Fcntl qw(:flock O_CREAT O_RDWR);

use parent qw(FileHandle);

=head1 DESCRIPTION

Inherit from FileHandle, add locking and DESTROY().

=head1 CONSTRUCTION and DESTROY

=over 4

=item $handle = Captive::Portal::LockHandle->new(%options)

Returns a filehandle with the requested lock assigned. There is no unlock, after destroying the filehandle the file is automatically closed and the lock released.

Options:

 file     => filename to lock, created if not existing
 shared   => shared lock, defaults to exclusive lock
 blocking => blocking lock request, defaults to blocking
 try      => number of retries in nonblocking mode, defaults to 1 retry
 timeout  => timeout in blocking mode, defaults to 1s

=cut 

sub new {
    my $self = shift;
    my %opts = @_;

    LOGDIE "missing param 'file'" unless exists $opts{file};

    my $file = delete $opts{file};

    DEBUG "lock requested for $file";

    # make lexical scoped filehandle

    my $lock_handle = $self->SUPER::new( $file, O_RDWR | O_CREAT )
      or LOGDIE "Can't open $file: $!";

    my $fileno = $lock_handle->fileno or LOGDIE "Can't read fileno: $!";

    # defaults
    $opts{shared}   = 0         unless exists $opts{shared};
    $opts{blocking} = 1         unless exists $opts{blocking};
    $opts{try}      = 1         unless exists $opts{try};
    $opts{timeout}  = 1_000_000 unless exists $opts{timeout};    # 1s

    DEBUG "fd=$fileno, ", $opts{shared} ? 'SHARED, ' : 'EXCLUSIVE, ',
      $opts{blocking}
      ? "BLOCKING, timeout $opts{timeout} us"
      : "NONBLOCKING, retry $opts{try}";

    my $mode;
    if ( $opts{shared} ) {
        $mode = LOCK_SH;
    }
    else {
        $mode = LOCK_EX;
    }

    # try to get the lock:
    #   - blocking with timeout
    #   - nonblocking with retry

    if ( $opts{blocking} ) {

        my $old_alarm;
        my $error;

        try {

            local $SIG{ALRM} = sub {
                die "fd=$fileno, timeout locking $file\n";
            };

            $old_alarm = ualarm $opts{timeout} || 0;

            flock $lock_handle, $mode
              or die "fd=$fileno, couldn't lock $file: $!\n";

            DEBUG "fd=$fileno, LOCKED";

            # reset alarm
            ualarm $old_alarm;
        }
        catch {

            # reset alarm
            ualarm $old_alarm;

            # propagate error
            $error = $_;
        };

        die "$error\n" if $error;

        return $lock_handle;

    }
    else {

        my $error;

        $mode |= LOCK_NB;

        my $retry = $opts{try};

        while ( $retry-- > 0 ) {

            undef $error;

            try {
                flock $lock_handle, $mode
                  or die "fd=$fileno, couldn't lock $file: $!\n";

                DEBUG "fd=$fileno, LOCKED";
            }
            catch { $error = $_; };

            if ($error) {
                DEBUG $error;
                DEBUG "fd=$fileno, lock retries left: $retry";

                # sleep for 1ms
                usleep 1_000;

                next;
            }

            return $lock_handle;
        }

        die "$error\n";

    }
}

=item $handle->DESTROY()

Called whenever the locked filehandle is destroyed. Just implemented to get proper debug messages for locking/unlocking.

=cut

sub DESTROY {
    my $lock_handle = shift;
    my $fileno      = $lock_handle->fileno;

    DEBUG "fd=$fileno, UNLOCKED";
}

1;

=back

=head1 AUTHOR

Karl Gaissmaier, C<< <gaissmai at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2013 Karl Gaissmaier, all rights reserved.

This distribution is free software; you can redistribute it and/or modify it
under the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 2, or (at your option) any later version, or

b) the Artistic License version 2.0.

=cut

# vim: sw=4

