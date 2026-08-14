# ABSTRACT: karr-foundation command execution — fork/pipe/select tee + error classification

package App::karr::Foundation::Runner;
our $VERSION = '0.500';
use Moo;
use App::karr::Error qw( clean_error user_error );
use App::karr::Encoding qw( to_octets_for_env );
use Encode ();
use IO::Select;
use IO::Handle ();
use POSIX qw( SIGTERM SIGKILL SIGALRM WNOHANG setpgid );


has foundation => (
  is       => 'ro',
  weak_ref => 1,
  required => 1,
);

# ---------------------------------------------------------------------------
# Command execution
# ---------------------------------------------------------------------------

sub _run_command {
  my ( $self, $repo, $karr, $cmd ) = @_;
  my $command      = $cmd // $karr->{command};
  my $max_runtime  = $karr->{max_runtime} // 1800;
  my $stream_terms = $self->foundation->_stream_to_terminal;

  # Environment for the child (and all karr calls it spawns). The child inherits
  # it across the fork/exec below, so a command template — including the
  # synthesized claude command — expands $PROMPT, ${KARR_REPO}, $KARR_ROLE and
  # every other variable foundation itself was started with as ordinary shell
  # parameters. %ENV is a byte boundary owned by App::karr::Encoding, so each
  # value is encoded through to_octets_for_env before the assignment (#167):
  # a non-ASCII prompt would otherwise emit "Wide character in setenv" on
  # stderr and the bytes the child receives would depend on the IO layers in
  # scope at the call site.
  local $ENV{KARR_REPO} = to_octets_for_env("$repo");
  local $ENV{KARR_ROLE} = to_octets_for_env('agent');
  local $ENV{PROMPT}    = to_octets_for_env( $self->foundation->_prompt_for($karr) );

  # The expansion is the shell's, not ours (#159). Splicing %ENV into the command
  # string here instead meant the shell went on to parse the *values*: a prompt
  # is board content written in Markdown, so its backtick spans and $(...) ran as
  # commands in the board's own directory, and the substitution reached inside
  # single quotes, where sh guarantees a literal — awk '{print $2}' arrived as
  # awk '{print }'. Parameter expansion has neither problem: sh does not rescan
  # an expanded value for substitutions, and it leaves single quotes alone. A
  # template that needs a value the shell cannot see gets it exported above,
  # never spliced.
  #
  # So this logs the template, which is now exactly the string /bin/sh -c is
  # handed. It used to log the substituted result, which after this change is not
  # even computable without reimplementing the shell — and what an operator reads
  # this line for is which command was resolved (--command vs default_command vs
  # .karr vs synthesized claude), not a second copy of the prompt. It also no
  # longer copies whatever an env var held — a wrapper's API key included — into
  # a plaintext .karr.log.
  $self->foundation->_append_log( $repo, "START command=$command" );
  $self->foundation->_say_verbose("exec in $repo: $command");

  if ( $self->foundation->dry_run ) {
    $self->foundation->_append_log( $repo, "DRY-RUN (skipped)" );
    return ( 0, '' );
  }

  my $log_file = $repo->child('.karr.log');

  # Opened before the command is started, not after (#147). Everything from the
  # fork below to the waitpid at the end of this method runs with a live agent
  # on the other side, and the drain loop that calls this catches per repo and
  # moves on to the next board — so a croak in that window releases the board's
  # lock with its agent still running and leaves one behind for the rest of the
  # foundation run. Refusing to start an agent whose log cannot be written is
  # the honest failure, and it is the one the foundation's own
  # _append_log("START ...") above already makes for the same file.
  # A resource the OS refused is the operator's problem, not a bug report, so
  # this and the two below carry the errno and no call site into this file (#77).
  open( my $log_fh, '>>', "$log_file" ) or user_error("open log $log_file: $!");
  $log_fh->autoflush(1);

  # Native pipe: the child writes stdout+stderr, the parent reads. The parent
  # is the tee — it fans each chunk to the persistent log, the terminal (when
  # streaming), and an in-memory buffer for error scanning. No external tee
  # process to race, and the run's output is captured directly (no re-slurping
  # the log via byte offsets).
  pipe( my $reader, my $writer ) or user_error("pipe failed: $!");

  my $pid = fork;
  user_error("fork failed: $!") unless defined $pid;

  if ( $pid == 0 ) {
    # child
    close $reader;
    chdir "$repo" or die "chdir $repo: $!";
    open( STDOUT, '>&', $writer ) or die "dup stdout: $!";
    open( STDERR, '>&STDOUT' )    or die "dup stderr: $!";
    # The agent becomes its own process group leader so the runner can signal
    # the whole tree (the agent, its forked grandchildren, anything it
    # backgrounded) without reaching the runner itself (#148). Before this the
    # timeout SIGTERM hit only the shell — `sleep 300 & wait`, a pipeline, any
    # command the agent backgrounded, all survived the kill because they were
    # children of /bin/sh, not of the runner. setpgrp(0,0) puts the child in a
    # group whose pgid is its own pid; the parent signals that group with
    # kill 'TERM', -$pid. SIGALRM is also reset to default in the child — the
    # timeout timer is the runner's, not the agent's.
    setpgid( 0, 0 ) if defined &setpgid;
    POSIX::setsid() if !defined &setpgid;    # fall back if POSIX::setpgid isn't there
    $SIG{ALRM} = 'DEFAULT';
    exec( '/bin/sh', '-c', $command ) or die "exec: $!";
  }

  # parent. From here to the waitpid below there is a running agent, so nothing
  # in between may die: no croaking call, and no unguarded call into the
  # foundation (its _append_log throws when the log file is gone). Keep it that
  # way — the tee loop below reports its errors by ending, not by dying.
  close $writer;

  # setpgid in the child may race with the parent's getpgid (the child has not
  # called it yet when fork returns in the parent). setpgid( $pid, $pid ) in the
  # parent is idempotent if the child has already done it, and is the
  # documented way to guarantee the value is set before we signal the group.
  setpgid( $pid, $pid ) if defined &setpgid;

  # The runner is the only place that knows the agent's pid and pgid — the
  # Foundation needs both so its SIGTERM handler can kill the agent's process
  # group when the cron host stops us mid-drain (#163). Record them here, in
  # the foundation's own attribute, so a handler installed in run() can reach
  # them without re-reading the lock file (which it does anyway, defensively).
  $self->foundation->_live_agent(
    { repo => $repo, pid => $pid, pgid => $pid, lockfile => $self->foundation->_state->_lock_file( $repo ) }
  );

  my $started   = time;
  my $output    = '';
  my $timed_out = 0;
  my $sel       = IO::Select->new($reader);

  # Deadline arming: the deadline must fire regardless of IO activity, because
  # an agent that closes its stdout/stderr while still running ends the read
  # loop on EOF with $timed_out still 0, and the runner falls into a bare
  # blocking waitpid that holds .karr.lock forever (#161). SIGALRM with a
  # handler that sets $timed_out keeps the deadline independent of the read
  # loop: the alarm fires at the deadline, the handler arms the flag, the
  # next loop iteration sees it and ends the loop. arm_alarm() also re-arms on
  # each can_read wakeup so a long-running command never gets a stale timer
  # from a prior iteration — every iteration arms for "remaining from now",
  # which is what the user expects max_runtime to mean.
  my $alarm_target;
  if ( $max_runtime > 0 ) {
    $alarm_target = $started + $max_runtime;
    $SIG{ALRM} = sub {
      $timed_out = 1;
      # Closing the read end of the pipe unblocks can_read with no data so
      # the loop wakes immediately rather than waiting for the alarm delivery
      # to reach it through sysread's EINTR. Cheap and signal-safe.
      close $reader;
      $sel = undef;
    };
    alarm $max_runtime;
  }

  # The agent's output arrives as raw octets in 64k reads that can split a
  # multi-byte character, while STDOUT carries the :encoding(UTF-8) layer
  # F<karr-foundation> installed and therefore wants characters. FB_QUIET is
  # the streaming decoder: it consumes every complete sequence and leaves a
  # trailing partial one in $pending for the next chunk. The log file and the
  # error-scanning buffer keep the raw octets.
  my $pending = '';

  while (1) {
    last if $timed_out;
    if ( !$sel ) {
      # SIGALRM fired and closed $reader; nothing left to do but exit the loop
      # so the kill path runs.
      last;
    }
    my @ready = $sel->can_read( $max_runtime > 0 ? $max_runtime - ( time - $started ) : undef );
    last if $timed_out;
    unless (@ready) {
      # Spurious wakeup (signal) or genuine deadline. SIGALRM would have set
      # the flag, but the deadline could also be reached by wall clock if a
      # signal reset the alarm — check both and end the loop either way.
      next unless $max_runtime > 0;
      last if time - $started >= $max_runtime;
      next;
    }
    my $chunk;
    my $n = sysread( $reader, $chunk, 65536 );
    last if !defined $n;   # read error (or SIGALRM closing the fd)
    last if $n == 0;       # EOF — the command closed its output
    print {$log_fh} $chunk;
    if ($stream_terms) {
      $pending .= $chunk;
      print Encode::decode( 'UTF-8', $pending, Encode::FB_QUIET );
    }
    $output .= $chunk;
  }

  # Disarm the alarm before reap: a waitpid that takes longer than max_runtime
  # would otherwise be cut short by SIGALRM (no handler anymore — the default
  # action is to die, and Foundation is the parent). $max_runtime == 0 already
  # never armed.
  alarm 0;
  $SIG{ALRM} = 'DEFAULT' if $max_runtime > 0;

  my $exit_code;
  if ($timed_out) {
    my $elapsed = time - $started;
    # The one call that has to happen here rather than after the kill: it is the
    # only record of why the agent was stopped, and the kill/waitpid pair below
    # can block for as long as the child stays unkillable. So it runs
    # best-effort — a log the OS took away mid-run (#147) must not cost us the
    # SIGTERM/SIGKILL and the reap, which are all that stop a hung agent. The
    # failure is reported once the child is safely gone, and the END line below
    # raises it for real if the log is still unwritable by then.
    my $log_err;
    eval {
      $self->foundation->_append_log( $repo,
        "TIMEOUT after ${elapsed}s \x{2014} sending SIGTERM to $pid (group -$pid)" );
      1;
    } or $log_err = clean_error($@);
    # Negative pid = process group (kill(2) group semantics, #148). The shell,
    # the agent, any grandchildren the agent backgrounded, all receive the
    # signal. SIGTERM is catchable, so we wait up to 2s before escalating.
    kill 'TERM', -$pid;
    my $deadline = time + 2;
    while ( time < $deadline ) {
      last if kill( 0, $pid ) == 0;
      select undef, undef, undef, 0.05;
    }
    kill 'KILL', -$pid;
    waitpid( $pid, 0 );
    warn "karr-foundation: cannot write $log_file: $log_err\n" if $log_err;
    # 128 + SIGTERM(15) = 143 — same convention as shells, distinct from a
    # clean non-zero exit, and surfaces in cooldown/last_error so an agent
    # that exceeded max_runtime triggers the backoff (#164 / #161).
    $exit_code = 128 + SIGTERM;
  } else {
    # The child may still be alive after the loop ended on EOF — a command
    # whose stdout is closed while it keeps running (the classic
    # `exec >/dev/null 2>&1; sleep N`, #161). Reap it with a wait loop that
    # checks the wall-clock deadline: if the loop ended on EOF before
    # max_runtime expired, this blocks until the child exits on its own or
    # until the deadline arrives and we kill it via the timed_out path. The
    # loop uses WNOHANG to keep checking; the deadline path is identical to
    # the SIGALRM path above.
    my $deadline;
    if ( $max_runtime > 0 ) {
      $deadline = $started + $max_runtime;
      while (1) {
        my $w = waitpid( $pid, WNOHANG );
        last if $w > 0 || $w < 0;
        if ( time >= $deadline ) {
          $timed_out = 1;
          kill 'TERM', -$pid;
          my $term_deadline = time + 2;
          while ( time < $term_deadline ) {
            last if kill( 0, $pid ) == 0;
            select undef, undef, undef, 0.05;
          }
          kill 'KILL', -$pid;
          waitpid( $pid, 0 );
          last;
        }
        select undef, undef, undef, 0.05;
      }
    } else {
      waitpid( $pid, 0 );
    }
    $exit_code = _classify_exit($?);
    $exit_code = 128 + SIGTERM if $timed_out && $exit_code == 0;
  }

  close $reader if defined fileno $reader;
  close $log_fh;

  # Clear the live-agent handle: the SIGTERM handler must not see this agent
  # after we have reaped it. The next iteration of the drain (or the next
  # repo) installs its own.
  $self->foundation->_live_agent( undef );

  my $elapsed = time - $started;
  $self->foundation->_append_log( $repo, "END elapsed=${elapsed}s exit=$exit_code" );
  return ( $exit_code, $output );
}

# Translate the raw $? from waitpid(2) into the exit code the drain sees. A
# child that exited normally: the high 8 bits are the status. A child that
# died from a signal: the low 7 bits are the signal number and the high 8
# bits are 0 — `$? >> 8` was 0 here, which is the bug #164 pins: the runner
# reported the OOM-killed / SIGTERM'd / SIGSEGV'd agent as exit 0, the drain
# read it as a clean run, and the cooldown that was supposed to catch a
# machine-killing agent never engaged. Surface the signal as 128 + signum so
# it is distinguishable from any real exit code (shells do the same), and
# fall through to the normal high-bits path otherwise.
#
# Accept both forms: the runner calls this as a function
# (`_classify_exit($?)`) and tests call it as a method (`$r->_classify_exit($?)`).
# `use Moo;` turns every sub in the package into a method, so the method
# form has $self as the first arg; the function form has $status as the first
# arg. Inspect $_[0]: if it's a blessed reference, it's $self and we look at
# $_[1] for $status.
sub _classify_exit {
  my $status = ( ref $_[0] ) ? $_[1] : $_[0];
  return 0 unless defined $status;
  my $sig = $status & 127;
  return 128 + $sig if $sig;
  return ( $status >> 8 ) & 255;
}

# ---------------------------------------------------------------------------
# Common-error detection
# ---------------------------------------------------------------------------

# What the drain scans an agent's transcript for: a failure the agent reports
# while still exiting 0 -- a rate limit, a dead key, a 5xx -- because that run
# produced nothing and starting the next one immediately just spends the next
# window on the same wall.
#
# These were bare case-insensitive substrings (network, quota, credentials,
# 401, 403, 429, 503, ...) matched against the whole transcript. That is not a
# near-miss instrument, it is a word search over everything the agent printed,
# and an agent working a karr board prints the board: a backlog line reading
# "retry the network fetch on 503" tripped it twice over, and "403" tripped on
# a diffstat (#160). So a symptom word on its own never counts here. It counts
# next to a failure word on the same line ($SIGNAL / _near), or inside one of
# the fixed phrases an API really emits. Numbers are the worse half -- 403 is a
# line count, a byte count, a task id -- so an HTTP status counts only where
# something adjacent says it is one (_http).
#
# Every quantifier below is bounded and every gap stays inside one line: this
# runs over megabytes of agent output, and an unbounded gap between two classes
# that share characters backtracks quadratically over a banner rule.

# A word that turns a symptom into a report of failure. Deliberately excludes
# "retry", "limit" and "timeout" on their own: those are what a backlog full of
# networking tickets says, not what a failing API says.
my $SIGNAL = qr/\b(?:
    error | errors | failed | failing | failure | refused | rejected | denied
  | unavailable | unreachable | invalid | missing | expired | revoked | unable
  | exceeded | exhausted
)\b/xi;

# Limits are reported with verbs of their own.
my $LIMIT = qr/\b(?:
    exceed(?:ed|s|ing)? | reach(?:ed|ing)? | hit | hitting | exhausted
  | throttl(?:ed|ing) | error | over
)\b/xi;

# $symptom counts only within one line of a failure word, in either order.
sub _near {
  my ( $symptom, $signal ) = @_;
  $signal //= $SIGNAL;
  return qr/ (?: $symptom [^\n]{0,40}? $signal ) | (?: $signal [^\n]{0,40}? $symptom ) /x;
}

# An HTTP status, only where something adjacent marks it as one: an
# http/status/code/error token just before it -- with nothing but punctuation,
# a "code"/"status" word or a protocol version in between -- or its own reason
# phrase directly after it. " | 403 ++++++" and "line 403" mark neither.
my $GAP = qr/[ \t:=,.\-\/\(\[]{0,8}/;

sub _http {
  my ( $code, $phrase ) = @_;
  return qr/
      (?: \b (?: https? | status | code | error | err | response ) \b
          $GAP (?: code | status | \d+\.\d+ )? $GAP \b $code \b )
    | (?: \b $code \b [ \t:,\-\(\[]{0,4} $phrase )
  /xi;
}

# [ name => regex ]. The name is what reaches .karr.log and .karr.state, and it
# keeps the wording of the substring it replaces so an operator's grep for
# "COMMON-ERROR rate limit" still finds it.
# Middle field: lowercase literals the pattern cannot match without. It is a
# pre-filter, not a pattern (see _match_error) -- these regexes are 30x the
# work of the substrings they replace, and a transcript is megabytes.
my @DEFAULT_PATTERNS = (
  # rate limiting / capacity
  [ 'rate limit', ['rate'],
    _near( qr/\brate[_ -]?limit(?:s|ed|ing)?\b/i, $LIMIT ) ],
  [ 'rate limit', ['rate_limit_error'],    qr/\brate_limit_error\b/i ],
  [ 'usage limit', ['usage limit'],        _near( qr/\busage limit\b/i, $LIMIT ) ],
  [ 'quota', ['quota'],                    _near( qr/\bquotas?\b/i, $LIMIT ) ],
  [ 'overloaded', ['overloaded_error'],    qr/\boverloaded_error\b/i ],
  [ 'overloaded', ['overload','overcapacity'],
    _near( qr/\bover(?:loaded|capacity)\b/i ) ],
  [ 'too many requests', ['too many requests'], qr/\btoo many requests\b/i ],
  [ '429', ['429'],                        _http( 429, qr/too many requests/i ) ],
  [ '529', ['529'],                        _http( 529, qr/overloaded/i ) ],
  # authentication
  [ 'invalid api key', ['api'],
    qr/\b(?:invalid|missing|expired|revoked|no)\s+api[_ -]?key\b
     | \bapi[_ -]?key\b [^\n]{0,24}?
       \b(?:invalid|missing|expired|revoked|required|not\s+found)\b/xi ],
  [ 'authentication', ['authentication_error'], qr/\bauthentication_error\b/i ],
  [ 'authentication', ['authenticat'],     _near( qr/\bauthenticat(?:ion|ed|e)\b/i ) ],
  [ 'credentials', ['credential'],         _near( qr/\bcredentials?\b/i ) ],
  [ 'unauthorized', ['unauthori'],         _near( qr/\bunauthori[sz]ed\b/i ) ],
  [ 'forbidden', ['forbidden'],            _near( qr/\bforbidden\b/i ) ],
  [ '401', ['401'],                        _http( 401, qr/unauthori[sz]ed/i ) ],
  [ '403', ['403'],                        _http( 403, qr/forbidden/i ) ],
  # network / transport
  [ 'network', ['network'],                _near( qr/\bnetwork\b/i ) ],
  [ 'connection', ['connection'],
    qr/\bconnection\s+(?:refused|reset|closed|aborted|error|failed)\b/i ],
  [ 'connection',
    [qw( econnrefused econnreset etimedout ehostunreach enetunreach enotfound eai_again )],
    qr/\bE(?:CONNREFUSED|CONNRESET|TIMEDOUT|HOSTUNREACH|NETUNREACH|NOTFOUND|AI_AGAIN)\b/i ],
  [ 'fetch failed', ['fetch failed'],      qr/\bfetch failed\b/i ],
  # /x eats a literal space, so every phrase here spells it \s+.
  [ 'name resolution', ['resolve host','name resolution','service not known'],
    qr/\bcould\s+not\s+resolve\s+host\b
     | \btemporary\s+failure\s+in\s+name\s+resolution\b
     | \bname\s+or\s+service\s+not\s+known\b/xi ],
  [ 'timed out', ['time'],
    qr/\b(?:connection|connect|request|socket|read|write|handshake|operation|upstream)\b
       [^\n]{0,16}? \btimed?[ _-]?out\b/xi ],
  # server side
  [ 'service unavailable', ['service unavailable'],   qr/\bservice unavailable\b/i ],
  [ 'internal server error', ['internal server error'], qr/\binternal server error\b/i ],
  [ 'bad gateway', ['bad gateway'],        qr/\bbad gateway\b/i ],
  [ '500', ['500'],                        _http( 500, qr/internal server error/i ) ],
  [ '502', ['502'],                        _http( 502, qr/bad gateway/i ) ],
  [ '503', ['503'],                        _http( 503, qr/service unavailable/i ) ],
);

sub _error_patterns {
  my ( $self, $karr ) = @_;
  # A board's own error_patterns stay what they were documented as: plain
  # case-insensitive substrings. Somebody who configures one has seen the
  # string their agent prints and means exactly it -- the narrowing above is
  # for the defaults, which have to hold for every board. Such a pattern is
  # its own pre-filter.
  my @custom = map { [ $_, [ lc $_ ], qr/\Q$_\E/i ] }
               @{ $karr->{error_patterns} // [] };
  return [ @DEFAULT_PATTERNS, @custom ];
}

sub _match_error {
  my ( $self, $text, $patterns ) = @_;
  return undef unless defined $text && length $text;
  # The pre-filter earns its keep on the output that has none of this in it,
  # which is nearly all of it: index() over a whole transcript is a memory
  # scan, these patterns are not, and skipping one that cannot match costs a
  # single index instead of a full pass. A trigger that does not occur in what
  # its own pattern matches would silently switch that pattern off, so t/152
  # checks the two against each other over the corpus.
  my $lc;
  for my $p ( @$patterns ) {
    my ( $name, $triggers, $re ) =
      ref $p eq 'ARRAY' ? @$p : ( $p, [ lc $p ], qr/\Q$p\E/i );
    $lc //= lc $text;
    next unless grep { index( $lc, $_ ) >= 0 } @$triggers;
    return $name if $text =~ $re;
  }
  return undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Foundation::Runner - karr-foundation command execution — fork/pipe/select tee + error classification

=head1 VERSION

version 0.500

=head1 DESCRIPTION

L<App::karr::Foundation::Runner> runs a single agent command for
L<App::karr::Foundation>. It forks the command under C</bin/sh -c>, reads its
combined stdout/stderr over a native pipe, and tees each chunk to the
persistent C<.karr.log>, the terminal (when streaming), and an in-memory buffer
used for error scanning, enforcing the per-run C<max_runtime> timeout. It also
classifies observable common errors (rate limit, auth, network, 5xx, ...) in
that buffer: a symptom word counts only next to a failure word on the same
line, or inside a phrase an API really emits, and an HTTP status only where
something adjacent marks it as one. The drain asks at all only for a run that
made no progress -- see L<App::karr::Foundation>'s "Drain semantics". A
weak back-reference to the owning foundation supplies shared options and helpers
(C<dry_run>, C<_stream_to_terminal>, C<_prompt_for>, C<_append_log>,
C<_say_verbose>).

The command is a shell template, not a string karr rewrites: C<PROMPT>,
C<KARR_REPO> and C<KARR_ROLE> are exported into the child's environment and
C</bin/sh> expands them like any other parameter. A prompt's own backticks
therefore stay text, and C<< awk '{print $2}' >> reaches awk intact.

A C<.karr.log> it cannot open ends the run for that board B<before> the command
is started, never after: the agent is refused rather than launched unwatched.
Once the fork has happened the parent owes it a C<waitpid>, so nothing between
the two may throw.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/karr/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
