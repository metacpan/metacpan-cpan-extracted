package Apache2::ScoreBoardFile;

use 5.012001;
use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Apache2::ScoreBoardFile', $VERSION);

1;
__END__

=encoding utf8

=head1 NAME

Apache2::ScoreBoardFile - Perl extension to the Apache HTTPD ScoreBoard

=head1 SYNOPSIS

C<httpd.conf>:

 LoadModule status_module "/path/to/mod_status.so"
 ExtendedStatus On
 ScoreBoardFile "/path/to/scoreboard.sb"

Perl level:

 use Apache2::ScoreBoardFile;
 $sb=Apache2::ScoreBoardFile->new($filename);
 $sb=Apache2::ScoreBoardFile->new($filehandle);

 $shared_mem_size=$sb->shmsize;
 $server_limit=$sb->server_limit;
 $thread_limit=$sb->thread_limit;
 $type=$sb->type;
 $generation=$sb->generation;
 $lb_limit=$sb->lb_limit;
 $restart_time=$sb->restart_time;

 $process=$sb->process($index);

 $pid=$process->pid;
 $generation=$process->generation;
 $quiescing=$process->quiescing;

 $worker=$sb->worker($index);
 $worker=$sb->worker($proc_index, $thread_index);

 $thread_num=$worker->thread_num;
 $pid=$worker->pid;
 $generation=$worker->generation;
 $status=$worker->status;
 $access_count=$worker->access_count;
 $bytes_served=$worker->bytes_served;
 $my_access_count=$worker->my_access_count;
 $my_bytes_served=$worker->my_bytes_served;
 $conn_count=$worker->conn_count;
 $conn_bytes=$worker->conn_bytes;
 $start_time=$worker->start_time;
 $stop_time=$worker->stop_time;
 $last_used=$worker->last_used;
 $client=$worker->client;
 $request=$worker->request;
 $vhost=$worker->vhost;
 $tid=$worker->tid;
 $utime=$worker->utime;
 $stime=$worker->stime;
 $cutime=$worker->cutime;
 $cstime=$worker->cstime;

 my %summary;
 my @keys=qw/. _ S R W K L D C G I bw iw cw nr nb/;
 @summary{@keys}=$sb->summary(@keys);

=head1 DESCRIPTION

C<Apache2::ScoreBoardFile> provides an interface to the shared scoreboard
file used by Apache HTTPD.

Apache HTTPD can keep track of its activity in a memory section mapped into
the address space of each of its processes. Provided that shared memory section
is configured as a disk file this module makes it read-only accessible for
an unrelated process. In other words you can watch what HTTPD is doing not
being part of HTTPD.

There is already a module named L<Apache::ScoreBoard> which does a very similar
thing as this one. Except it relies on a working HTTPD server to access the
scoreboard. This has the advantage that you can fetch the information from
a remote machine. But on the downside if the server is under heavy load or
not serving at all it's hard to access the scoreboard.

B<NOTE>, by the time of this writing this module is tested with the prefork
MPM only. Also, the test suite is expected to fail for other MPMs. That does
not mean that the module does not work for other MPMs. It only requires some
manual tests by your site. Patches are welcome.

=head2 Methods

=head3 $sb=Apache2::ScoreBoardFile-E<gt>new($filename_or_handle);

the constructor. The parameter is either the name of the scoreboard file or an
open file handle.

=head3 $shared_mem_size=$sb-E<gt>shmsize;

the shared memory size.

=head3 $server_limit=$sb-E<gt>server_limit;

see C<ServerLimit> in Apache HTTP Server Documentation.

=head3 $thread_limit=$sb-E<gt>thread_limit;

see C<ThreadLimit> in Apache HTTP Server Documentation.

=head3 $type=$sb-E<gt>type;

the type of the scoreboard. See F<include/scoreboard.h> in your apache
distribution. This value should contain C<2> which means C<SB_SHARED>.
Please drop me a mail if it says otherwise in your installation.

=head3 $generation=$sb-E<gt>generation;

the server generation (number of times it has been restarted by C<SIGHUP>
or C<SIGUSR1>)

=head3 $lb_limit=$sb-E<gt>lb_limit;

no clue what that means

=head3 $restart_time=$sb-E<gt>restart_time;

server restart time in UNIX seconds (fractional number)

=head3 $process=$sb-E<gt>process($index);

returns a parent (or process) score board entry. C<$index> is a number between
C<0> and C<ServerLimit - 1>. Returns an C<Apache2::ScoreBoardFile::Process>
object.

=head3 $pid=$process-E<gt>pid;

returns the process ID of the C<Apache2::ScoreBoardFile::Process> object.

=head3 $generation=$process-E<gt>generation;

returns the generation of the C<Apache2::ScoreBoardFile::Process> object.
If this generation differs from the one reported by C<< $sb->generation >>
the server is performing a restart and this process belongs to the old
generation.

=head3 $quiescing=$process-E<gt>quiescing;

if true the process is going down gracefully.

=head3 $worker=$sb-E<gt>worker($index);

returns an C<Apache2::ScoreBoardFile::Worker> object by its overall index.

=head3 $worker=$sb-E<gt>worker($proc_index, $thread_index);

returns an C<Apache2::ScoreBoardFile::Worker> object by its process index
and the thread index within the process.

=head3 $thread_num=$worker-E<gt>thread_num;

returns the overall index of a worker

=head3 $pid=$worker-E<gt>pid;

with prefork-MPM this field is unused. F<include/scoreboard.h> explains:

 /* With some MPMs (e.g., worker), a worker_score can represent
  * a thread in a terminating process which is no longer
  * represented by the corresponding process_score.  These MPMs
  * should set pid and generation fields in the worker_score.
  */

=head3 $generation=$worker-E<gt>generation;

with prefork-MPM this field is unused. F<include/scoreboard.h> explains:

 /* With some MPMs (e.g., worker), a worker_score can represent
  * a thread in a terminating process which is no longer
  * represented by the corresponding process_score.  These MPMs
  * should set pid and generation fields in the worker_score.
  */

=head3 $status=$worker-E<gt>status;

the status of a worker as one of the letters seen on the C<mod_status>
page:

 "_" Waiting for Connection
 "S" Starting up
 "R" Reading Request
 "W" Sending Reply
 "K" Keepalive (read)
 "D" DNS Lookup
 "C" Closing connection
 "L" Logging
 "G" Gracefully finishing
 "I" Idle cleanup of worker
 "." Open slot with no current process

A C<?> is reported for an unknown status.

=head3 $access_count=$worker-E<gt>access_count;

=head3 $bytes_served=$worker-E<gt>bytes_served;

=head3 $my_access_count=$worker-E<gt>my_access_count;

=head3 $my_bytes_served=$worker-E<gt>my_bytes_served;

=head3 $conn_count=$worker-E<gt>conn_count;

=head3 $conn_bytes=$worker-E<gt>conn_bytes;

=head3 $start_time=$worker-E<gt>start_time;

=head3 $stop_time=$worker-E<gt>stop_time;

=head3 $last_used=$worker-E<gt>last_used;

=head3 $client=$worker-E<gt>client;

=head3 $request=$worker-E<gt>request;

=head3 $vhost=$worker-E<gt>vhost;

=head3 $tid=$worker-E<gt>tid;

=head3 $utime=$worker-E<gt>utime;

=head3 $stime=$worker-E<gt>stime;

=head3 $cutime=$worker-E<gt>cutime;

=head3 $cstime=$worker-E<gt>cstime;

various other fields. Documentation patches welcome.

=head3 @summary{@keys}=$sb-E<gt>summary(@keys);

This method iterates over all workers and collects summary activity.

The following keys are recognized:

=over 4

=item C<_>

count the number of workers in C<Waiting for Connection> state

=item C<S>

count the number of workers in C<Starting up> state

=item C<R>

count the number of workers in C<Reading Request> state

=item C<W>

count the number of workers in C<Sending Reply> state

=item C<K>

count the number of workers in C<Keepalive (read)> state

=item C<D>

count the number of workers in C<DNS Lookup> state

=item C<C>

count the number of workers in C<Closing connection> state

=item C<L>

count the number of workers in C<Logging> state

=item C<G>

count the number of workers in C<Gracefully finishing> state

=item C<I>

count the number of workers in C<Idle cleanup of worker> state

=item C<.>

count the number of open slots with no current worker

=item C<cw>

the current number of active workers. For prefork-MPM this is the number
of apache worker processes currently running. Number of workers in any state
except for C<.>, C<S> and C<I>.

=item C<bw>

current number of busy workers. Any worker in a state except for C<.>, C<S>,
C<I>, C<_> is busy.

=item C<iw>

current number of idle workers (C<_> state).

=item C<nr>

overall number of requests served so far, sum(access_count).

=item C<nb>

overall number of bytes served so far, sum(bytes_served).

=back

=head1 SEE ALSO

=over 4

=item * L<Apache::ScoreBoard>

=item * F<include/scoreboard.h> in your apache distribution

=back

=head1 AUTHOR

Torsten Förtsch, E<lt>torsten.foertsch@gmx.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Torsten Förtsch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
