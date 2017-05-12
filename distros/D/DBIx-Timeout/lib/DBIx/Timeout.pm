package DBIx::Timeout;

require 5.008;    # v5.8.0+ needed for safe signals

use warnings;
use strict;

our $VERSION = '1.01';

use Params::Validate qw(validate CODEREF);
use Carp qw(croak);
use POSIX qw(_exit);

our $TIMEOUT_EXIT_CODE = 29;

sub call_with_timeout {
    my $pkg = shift;

    my %args =
      validate(@_,
               {dbh     => {isa  => 'DBI::db'},
                code    => {type => CODEREF},
                timeout => 1
               });
    my ($dbh, $code, $timeout) = @args{('dbh', 'code', 'timeout')};

    my $child_pid = $pkg->_fork_child($dbh, $timeout);

    # run code, trapping error since it may have come from the timeout
    # connection killing
    eval { $code->() };
    my $err = $@;

    # signal the child that processing is done - will wake up from
    # sleep if timeout didn't already pass.  It's ok if this fails,
    # that means the child is probably already done.
    kill USR1 => $child_pid;

    # reap the child, examining exit code to determine if timeout fired
    if (waitpid $child_pid, 0) {
        my $exit_code = $? >> 8;
        if ($exit_code == $TIMEOUT_EXIT_CODE) {
            return 0;
        }
    } else {
        croak("waitpid() failed: $!");
    }

    # the error wasn't a timeout, rethrow
    die $err if $err;

    # everything is all right
    return 1;
}

# forks off the child process
sub _fork_child {
    my ($pkg, $dbh, $timeout) = @_;

    # pull a list of active handles for use after the fork
    my %drivers    = DBI->installed_drivers();
    my @active_dbh =
      grep { $_ and $_->isa('DBI::db') and $_->{Active} }
      map { @{$_->{ChildHandles}} } values %drivers;

    # do the fork, return in the parent
    my $child_pid = fork();
    croak("Failed to fork(): $!") unless defined $child_pid;
    return $child_pid if $child_pid;

    # do the dance needed to keep open DBI connections from causing
    # errors when this child exits
    foreach my $active_dbh (@active_dbh) {
        $active_dbh->{InactiveDestroy} = 1;
    }

    # setup a (safe) signal handler for USR1 which will exit early
    # from sleep()
    local $SIG{USR1} = sub { _exit(0) };

    # now running in the child, sleep for $timeout seconds
    sleep $timeout;

    # turn off USR1 handler, signalling now won't kill us in the
    # middle of killing the parent's thread
    $SIG{USR1} = 'IGNORE';

    # woke up, time to kill parent's thread
    $pkg->_kill_connection($dbh);

    # tell the parent what happened (use POSIX::_exit() to make sure
    # the parent really gets the message - otherwise END blocks can
    # change the exit code)
    _exit($TIMEOUT_EXIT_CODE);
}


# MySQL specific thread-killer
sub _kill_connection {
    my ($self, $dbh) = @_;

    my $thread_id = $dbh->{thread_id};

    my $new_dbh = $dbh->clone();
    $new_dbh->{InactiveDestroy} = 0;
    $new_dbh->do("KILL $thread_id");
}


1;

__END__

=head1 NAME

DBIx::Timeout - provides safe timeouts for DBI calls

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

  use DBIx::Timeout;

  # run code() for a maximum of 5 minutes, doing work with $dbh
  $ok = DBIx::Timeout->call_with_timeout(
    dbh     => $dbh,
    code    => sub { $dbh->do('LONG-RUNNING SQL HERE') },
    timeout => 300,
  );

  # handle the result
  if (!$ok) {
    die "You ran out of time!";
  }

=head1 DESCRIPTION

This module provides a safe method of timing out DBI requests.  An
unsafe method is described in the DBI docs:

   http://search.cpan.org/~timb/DBI/DBI.pm#Signal_Handling_and_Canceling_Operations

The problem with using POSIX sigaction() (the method described above)
is that it relies on unsafe signals to work.  Unsafe signals are well
known to cause instability.  To understand why, imagine the DB client
code is in the middle of updating some global state when the signal
arrives.  That global state could be left in an inconsitent state,
just waiting for the next time it is needed to cause problems.  Since
this will likely occur far from the cause, and only occur rarely, it
can be a very difficult problem to track down.

Instead, this module:

  - Forks a child process which sleeps for $timeout seconds.

  - Runs your long-running query in the parent process.

  - If the parent process finishes first it kills the child and
    returns.

  - If the child process wakes up it kills the parent's DB thread and
    exits with a code so the parent knows it was timed out.

B<NOTE>: After this call your database connection may be killed even
if no timeout occurred.  This is due to a race condition - the child
may wake up just as parent process finishes.  Patches addressing this
bug are welcome.  Until this is fixed you should be ready to reconnect
after call_with_timeout().

=head1 DATABASE SUPPORT

This release supports only MySQL.  I would appreciate patches from
users of other databases.  Your patch will need to provide code to
kill a running query.  In MySQL this uses the KILL command,
implemented in _kill_connection().

=head1 OPERATING SYSTEM SUPPORT

So far this code has been tested only on Linux.  I expect it will work
on any OS with normal fork(), kill() and waitpid() implementations.  I
do I<not> expect it will work on Windows!

=head1 INTERFACE

=head2 call_with_timeout

  $ok = DBIx::Timeout->call_with_timeout(
    dbh     => $dbh,
    code    => sub { $dbh->do('LONG-RUNNING SQL HERE') },
    timeout => 300,
  );

This method calls code() with the specified timeout.  You must also
pass the database handle which will be used to execute the
long-running query.  This is the connection which will be killed if
the timeout occurs.

The method will return 0 when a timeout is detected.  Note that in
either case the connection for C<$dbh> may be killed after this method
returns.

=head1 KNOWN ISSUES

When the timeout fires a warning may occur that looks like:

    DBD::mysql::db selectcol_arrayref failed: Unknown error at ...

You can silence this warning by turning off PrintError:

    $dbh->{PrintError} = 0;

I prefer RaiseError in any case.

=head1 BUGS

Please report any bugs or feature requests to
bug-dbix-timeout@rt.cpan.org, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Timeout>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

This module is supported on the dbi-users mailing list.  Details here:

  http://lists.cpan.org/showlist.cgi?name=dbi-users

You can find the public Subversion repository here:

  https://dbix-timeout.googlecode.com/svn/trunk

=head1 CREDITS

The mechanism used by this module was suggested by Perrin Harkins.

=head1 AUTHOR

Sam Tregar, C<< sam@tregar.com >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Sam Tregar, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
