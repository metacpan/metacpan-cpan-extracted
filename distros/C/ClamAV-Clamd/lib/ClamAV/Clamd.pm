package ClamAV::Clamd;

use 5.010;
use strict;
use warnings;
use XSLoader ();

our $VERSION = '0.01';

XSLoader::load('ClamAV::Clamd', $VERSION);

1;

__END__

=head1 NAME

ClamAV::Clamd - talk to the clamd daemon

=head1 SYNOPSIS

    use ClamAV::Clamd;

    my $clamd = ClamAV::Clamd->new(
        socket => '/var/run/clamav/clamd.ctl',
    );

    $clamd->ping or die $clamd->error;

    my $v = $clamd->scan_path('/var/spool/uploads/xyz');

    if    ($v->is_clean)       { accept_it()  }
    elsif ($v->is_infected)    { reject("found " . $v->signature) }
    elsif ($v->is_unscannable) { reject("not scanned: " . $v->reason) }
    else                       { reject("scanner unavailable: " . $v->error) }

=head1 DESCRIPTION

A client for the clamd daemon's socket protocol. It does not link
libclamav and has no dependencies: clamd holds the signature engine -
around 1.6 GB of it - and this asks it questions.

Scanning by descriptor or by bytes, blocking or on an event loop, with a
four-state verdict and a C ABI for other XS distributions.

=head1 RECOMMENDED CLAMD.CONF

This is the configuration this module was developed and measured
against. The three C<Alert> settings are the important part - without
them clamd cannot tell anyone it declined to scan something.

    LocalSocket /run/clamav/clamd.ctl
    LocalSocketMode 660

    # Turn silently-skipped scans into reportable detections.
    AlertExceedsMax       yes
    AlertEncryptedArchive yes
    AlertEncryptedDoc     yes

C<LocalSocket> rather than C<TCPSocket> where you can: descriptor
passing needs a UNIX socket, and it is what lets clamd scan a file it has
no permission to open by name.

If you must use TCP, raise C<StreamMaxLength> to whatever your largest
acceptable upload is. Over that ceiling clamd answers
C<INSTREAM size limit exceeded. ERROR> and closes - which this module
reports as C<unscannable> and never as clean, but it is a scan you did
not get.

=head2 Concurrency

C<MaxThreads> defaults to 10 and clamd B<queues silently> past it rather
than refusing. Measured here, 30 concurrent scans put p95 latency at
about 7x the unloaded figure and nothing was rejected - so a burst of
uploads becomes a burst of slow requests, not a burst of errors.

=head1 METHODS

=head2 new

    ClamAV::Clamd->new(socket => '/var/run/clamav/clamd.ctl');
    ClamAV::Clamd->new(host => '127.0.0.1', port => 3310);

Takes C<socket>, or C<host> and C<port>, plus:

=over 4

=item C<connect_timeout> - seconds, default 5

=item C<reply_timeout> - seconds, default 30

=item C<reply_max> - ceiling on a single reply, default 1 MiB

=item C<frame> - C<'z'> (default) or C<'n'>

=item C<chunk> - INSTREAM chunk size, default 64 KiB

=item C<max_size> - refuse anything larger without scanning; off by default

=back

Croaks on a configuration that cannot work: no address, both addresses, a
non-positive timeout, an unknown framing, or a UNIX socket path too long
for the platform's C<sockaddr_un>.

That last one croaks rather than truncating because the kernel copies a
fixed-size array, so an over-long path is silently shortened - and a
shortened path connects to a B<different socket> than the one asked for.
Believing an answer from an unidentified peer is worse than not getting
one.

Nothing connects here. The address is stored, and each command makes and
closes its own connection.

=head2 ping

True if clamd answered C<PONG>, undef otherwise with L</error> set.

=head2 version

clamd's version string, or undef.

=head2 stats

The C<STATS> reply, or undef.

=head2 reload

Asks clamd to reload its signature database. True if it accepted.

Reloading is normally the operator's business, and a client that calls
this on a timer is picking a fight with whatever else manages that
daemon.

=head2 scan_fd

    $clamd->scan_fd($filehandle);
    $clamd->scan_fd($descriptor_number);

Scans an open file by handing clamd the descriptor itself. Takes a Perl
filehandle or a raw descriptor number. Returns a L</VERDICTS> object.

The descriptor is B<borrowed>. It is not closed, and its file position is
not moved - clamd scans the whole file wherever the descriptor happens to
be positioned, so there is nothing to correct and correcting it would
change state the caller owns.

Only regular files are accepted. A pipe, a socket or a directory is
refused with C<ERR_NOTREG>, because a scan of one cannot mean what the
caller thinks it means.

Requires a UNIX socket. See L</WHY THE DESCRIPTOR AND NOT THE PATH>.

=head2 scan_path

    $clamd->scan_path('/var/spool/uploads/xyz');

Opens the file and scans its descriptor, returning a L</VERDICTS>
object. The file is opened B<here>, by this process, and the descriptor
is what travels.

This is deliberately not clamd's own C<SCAN> command, which hands clamd a
path for clamd to resolve - and which therefore requires clamd to have
permission on it.

=head2 scan

    $clamd->scan($bytes);

Scans bytes that were never a file - a small upload held in memory, a
decoded attachment, anything already in a scalar. Returns a L</VERDICTS>
object.

The bytes are sent from where they are, with no intermediate copy. They
must be B<bytes>: a string with wide characters is refused rather than
guessed at, because guessing an encoding means scanning something the
caller never stored.

Unlike L</scan_fd>, this works over TCP and on every platform - there is
no descriptor involved.

=head2 transport

C<'fildes'> or C<'instream'>: which transport produced the last scan, or
undef if none has run.

Worth watching. A deployment that quietly fell back to C<instream> is
sending every scanned file across the socket in full, and that is the
kind of thing better read off a field than inferred from a latency graph.

=head1 SCANNING WITHOUT BLOCKING

A scan is a round trip to a daemon that may have queued the request
behind a dozen others. Inside an event-driven server, spending that in a
blocking read stalls every other connection the worker owns - which is
the whole reason this module talks to clamd rather than linking
libclamav.

    my $scan = $clamd->start_scan($path, 'path');

    # ... register $scan->fd with whatever loop you have, waiting for
    # $scan->want ('read' or 'write'), and on readiness:

    if ($scan->step) {
        my $v = $scan->verdict;
    }

B<This module owns no event loop and depends on none.> There is no
adapter to write and no framework to adopt: a descriptor, a readiness,
and a step function are enough for a bare C<select> loop, and enough for
anything larger to wrap in its own future type in about twenty lines.

=head2 start_scan($what, $kind)

C<$kind> is C<'bytes'> (the default), C<'path'>, or C<'fd'>. Returns a
C<ClamAV::Clamd::Scan>.

The handle keeps a reference to whatever it reads from, so a scan
outlives the filehandle or scalar it was given.

=head2 The scan handle

=over 4

=item C<fd>

The descriptor to watch. Undef once finished - there is nothing left to
watch, and a loop still watching a closed descriptor will eventually
dispatch on somebody else's connection.

=item C<want>

C<'read'>, C<'write'>, or undef when finished.

=item C<step>

Advance as far as possible without blocking. True when finished.

=item C<is_done> / C<verdict>

C<verdict> is undef until the scan finishes, and thereafter always
returns the same verdict.

=item C<cancel>

Abandon a scan in flight. The connection is B<closed>, never kept: clamd
is still going to answer, and a connection carrying an unread verdict
would hand that verdict to whichever scan picked it up next.

=back

=head2 Two things the caller owns

B<The deadline only advances when you step.> Without a timer this module
cannot wake anybody. C<reply_timeout> is checked on every step, so a scan
that is being driven will time out - but a driver that stops calling
C<step> never learns that it should have. If your loop has timers, set
one.

B<Concurrency is yours to bound.> clamd's C<MaxThreads> defaults to 10
and it B<queues silently> past that rather than refusing: measured here,
30 concurrent scans put p95 latency at about 7x the unloaded figure and
nothing was rejected. A cap belongs where the request context is, which
is your code and not this module.

=head2 The blocking methods are this same machine

L</scan>, L</scan_fd> and L</scan_path> run the identical state machine
under C<poll>. There is deliberately no second implementation of the
protocol in this distribution: a bug fixed on one path is fixed on both,
and the non-blocking path cannot rot from disuse because every blocking
call exercises it.

=head1 VERDICTS

Every scan returns a C<ClamAV::Clamd::Verdict>, B<including one that
never reached clamd>. Returning undef on a timeout would mean

    if ($clamd->scan($file)->is_clean) { ... }

dies on the one path where it matters most, so there is always something
to ask.

=head2 The four states

=over 4

=item C<clean>

Scanned in full, nothing found.

=item C<infected>

Scanned, and this signature matched.

=item C<unscannable>

B<Not scanned, or not scanned completely.> Over a size ceiling, nested
past C<MaxRecursion>, too many members, or an encrypted archive clamd
could not open.

=item C<error>

No usable answer at all: clamd unreachable, a timeout, a reply in no
recognised shape.

=back

There are four rather than two because C<unscannable> must never
collapse into C<clean>. A boolean API reports "clean" for precisely the
inputs an attacker constructs - a 2 KB nested zip, a password-protected
archive, anything over the size ceiling - and it passes every test
anybody writes for it, because nobody writes the test where the answer is
"I did not look".

C<error> must not collapse into C<clean> either. A scanner that is down
and reports clean B<is> the vulnerability.

=head2 Methods

C<state>, C<is_clean>, C<is_infected>, C<is_unscannable>, C<is_error>,
C<signature>, C<reason>, C<transport>, C<error>, C<raw>.

C<is_clean> is true for B<exactly one> of the four states. A caller who
wants to accept an upload writes one short safe thing; a caller who wants
to reject one has more to think about, which is the right way round.

C<reason> says why something was unscannable: C<MaxFileSize>,
C<MaxRecursion>, C<MaxFiles>, C<StreamMaxLength>, C<Encrypted>, or
C<max_size> for the client's own ceiling.

=head2 In boolean and string context

A verdict is true only when it is clean, and stringifies to its state:

    if ($clamd->scan($bytes)) { accept() }        # accepts only clean
    warn "upload was $v";                         # "unscannable"

An object is otherwise always true, which would make that first line
accept every infected file there is. That is the most dangerous plausible
misuse of this API, so it is wired to be correct instead.

=head2 The signature is remote input

C<signature> is a string chosen, in effect, by whoever supplied the file:
a file crafted to match a given signature decides what comes back. It is
length-bounded, and it belongs in a log rather than in a response body.

=head1 WHY THE DESCRIPTOR AND NOT THE PATH

A web server writing an upload to a private spool directory owns those
files; clamd runs as another user entirely. There are only two ways to
bridge that, and one of them is bad:

=over 4

=item Widen the permissions

Loosen the file, or the directory, or run clamd somewhere it can read a
directory full of unscanned attacker-controlled bytes. Every version of
this opens up exactly the wrong place.

=item Pass the descriptor

The receiving process gets an open file description with access already
granted. It never resolves a name, so it needs no permission on one.

=back

This module does the second. The difference is demonstrable: given a file
whose path has been made unreadable, clamd's own path-based command
answers

    File path check failure: Permission denied. ERROR

while C<scan_fd> on a descriptor opened before the path was closed off
returns the detection.

Descriptor passing needs a UNIX socket and a platform with C<SCM_RIGHTS>.
Over TCP, and on Windows, C<scan_fd> and C<scan_path> fall back to
streaming the file instead, and L</transport> says so.

They never send C<FILDES> where it cannot work. clamd's answer to a
C<FILDES> it cannot honour is not an error - it is silence, with the
connection held open, so the alternative to knowing better is a worker
parked forever.

=head1 SIZE LIMITS

C<max_size>, if set, refuses anything larger B<without scanning it> and
without transferring it. It is off by default, because a limit the client
only believes clamd has would refuse work that would have succeeded.

Set it to match clamd's C<StreamMaxLength> and C<MaxFileSize> if you know
them. Setting it B<larger> than clamd's real limits is worse than leaving
it unset: it reads like a safety belt while clamd silently declines to
scan anything above its own ceiling.

Streaming something larger than clamd's C<StreamMaxLength> is not a
disaster - clamd replies C<INSTREAM size limit exceeded. ERROR> and
closes. It is an error, never a clean verdict.

=head2 error

The message from the last failed command, or undef if it succeeded.

=head2 error_code

The code for that failure: C<ERR_CONNECT>, C<ERR_TIMEOUT>, C<ERR_IO>,
C<ERR_TOOBIG>, C<ERR_CONFIG>, C<ERR_CLOSED>, C<ERR_NOTREG> or
C<ERR_NOFDPASS>. Compare against these rather than matching on message
text.

=head2 have_fd_passing

Whether this platform can pass file descriptors over a socket. False on
Windows, which has C<AF_UNIX> but no C<SCM_RIGHTS>.

=head1 FAILURE IS NEVER SUCCESS

No transport failure is reported as a verdict. Every command returns
undef when it could not get an answer, and sets both L</error> and a
non-zero L</error_code>. A timeout, a refused connection, a peer that
closed mid-reply and a reply that exceeded C<reply_max> are all failures
to answer, never answers.

=head1 C ABI

Another XS distribution can call clamd through this one's C entry points
without going near Perl, by vendoring F<include/clamav/clamd_abi.h>,
fetching the table once from C<ClamAV::Clamd::_abi_ptr>, and gating on

    abi->abi_version >= CLAMD_ABI_VERSION

with B<greater-or-equal and never equality>. The table is append-only, so
a later version is a superset whose prefix stays valid; an equality check
turns every release of this module into a breaking change for everything
built against it.

The header is installed for L<ExtUtils::Depends>, which is a
configure-time dependency only. Nothing is needed at runtime, and a build
without it produces a fully working module - only the wiring for other XS
distributions is skipped.

=head2 It is not there for speed

Measured on the machine this was developed on: a small-file scan takes
about 637 microseconds, a Perl method call into this module takes about
0.03, and driving a scan to completion from Perl costs roughly 0.1
microseconds in total. Even a 90 MB stream - the case built to generate
the most readiness events there are - takes 142 C<step> calls, about five
microseconds of Perl against a scan lasting 0.64 seconds.

That is B<0.0007%>. A scan is a socket round trip to a daemon holding
1.6 GB of signatures, and nothing on the Perl side is measurable beside
it.

The ABI exists so a consumer that is already in C can stay in C, and for
consistency with how other providers are consumed. If you are reaching
for it because you expect it to be faster, use the Perl API: it is
simpler, and it is not measurably slower.

=head1 SEE ALSO

L<ClamAV::Client> and L<File::Scan::ClamAV> are pure-Perl clamd clients.
If a blocking scan in a cron job is what you need, they have no XS to
compile and that is a real advantage.

L<Mail::ClamAV> binds libclamav rather than talking to the daemon.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
