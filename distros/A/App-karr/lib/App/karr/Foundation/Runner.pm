# ABSTRACT: karr-foundation command execution -- fork/pipe/select tee + run classification

package App::karr::Foundation::Runner;
our $VERSION = '0.601';
use Moo;
use App::karr::Error qw( clean_error user_error );
use App::karr::Encoding qw( from_octets json_decode to_octets to_octets_for_env );
use App::karr::AgentName qw( agent_name );
use Encode ();
use IO::Select;
use IO::Handle ();
use POSIX qw( SIGTERM SIGKILL SIGALRM WNOHANG setpgid );
use Scalar::Util qw( looks_like_number );



has foundation => (
  is       => 'ro',
  weak_ref => 1,
  required => 1,
);

# ---------------------------------------------------------------------------
# Command execution
# ---------------------------------------------------------------------------

sub _run_command {
  my ( $self, $repo, $karr, $cmd, $ticket, $agent, %opt ) = @_;
  my $command      = $cmd // $karr->{command};
  my $stream_terms = $self->foundation->_stream_to_terminal;

  # What this run is, and how long it may take. Both default to the agent, who
  # was the only caller for as long as there was only one kind of run. The
  # C<on_drained> hook (#193) is the second: it wants the whole apparatus below
  # -- the process group, the timeout, the tee -- and none of the identity, so
  # it passes its own role and its own budget and takes everything else as it
  # stands. Anything the identity decides is keyed off $role and nothing else.
  my $role         = $opt{role} // 'agent';
  my $max_runtime  = $opt{max_runtime} // $karr->{max_runtime} // 1800;

  # How this run's output is to be read for a human, decided by the agent
  # definition that supplied the command and by nothing else (#188). Undef --
  # every board that names no agent -- is the historical path: the octets the
  # command printed, verbatim, to the log and the terminal.
  my $render = ref $agent eq 'HASH' ? $agent->{render} : undef;

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
  local $ENV{KARR_ROLE} = to_octets_for_env($role);

  # The prompt is the board agent's instruction, so only the board agent gets
  # the board's one. A hook handed a prompt telling it to pick the next
  # actionable task would be told to do the one thing it is not there for, and
  # every karr write it made would land in the agent's activity log -- which is
  # the evidence the auto-block reads. KARR_ROLE keeps those apart, and this
  # keeps the instruction with the identity it belongs to.
  #
  # A caller that brings its OWN instruction passes it, and the coordination
  # agent (#210) is the one that does: it is an agent and needs a prompt, but
  # not the board's -- it is not there to work a card, and it is not even run
  # in a board's own repository in the sense the drain means. `prompt => ...`
  # is therefore the exception the two identities above make necessary, not a
  # third way for a board agent to be told what to do.
  local $ENV{PROMPT}    = to_octets_for_env(
      defined $opt{prompt} ? $opt{prompt}
    : $role eq 'agent'     ? $self->foundation->_prompt_for( $karr, $ticket )
    :                        '' );

  # The id of the task this run is about, in ticket mode, and empty in every
  # other mode -- localised either way so a run never inherits the previous
  # one's card, and so a template reading it in drain mode gets nothing rather
  # than a stale number. This is the whole machine-readable half of the ticket
  # contract: the prompt above carries the assignment in prose for the agent,
  # $KARR_TASK carries it for a command template that wants the bare id
  # (`myagent --task "$KARR_TASK"`). Deliberately not an argument appended to
  # the command -- how arguments are appended is what `kind: claude-code`
  # settles per agent definition (#188), and an env var is the one thing that
  # works with every command template that exists today, including the
  # synthesized `claude -p "$PROMPT"`.
  local $ENV{KARR_TASK} = defined $ticket ? to_octets_for_env("$ticket") : '';

  # The claim name this run holds its cards under, defaulted for every nested
  # `karr` call the child makes (ADR 0005 / #281). `karr agent-name` and this
  # have to produce the same string from the same checkout, so both go through
  # App::karr::AgentName; the value is the checkout's own directory name (a
  # claim visible in `karr show`, distinct per worktree). `unique => 1` appends
  # a per-run random suffix -- foundation is the many-agent context, and two
  # checkouts of one shared board could otherwise stamp the same bare name at
  # once. It is minted ONCE here and exported, so it is the same value for
  # every `karr` the child spawns during this run (stable per run, not per
  # invocation -- which is why a fresh PID per call was rejected); a run that
  # dies leaves at most this claim for claim_timeout to clear. Through the same
  # %ENV octet edge KARR_TASK above uses, never a direct encode.
  local $ENV{KARR_CLAIM} = to_octets_for_env( agent_name( dir => "$repo", unique => 1 ) );

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
  $self->foundation->_append_log( $repo, 'START '
    . ( $role ne 'agent' ? "role=$role " : '' )
    . ( ref $agent eq 'HASH' && defined $agent->{name} ? "agent=$agent->{name} " : '' )
    . "command=$command" );
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

  # Line assembly for a rendered stream (see _render_stream_line). Only used
  # when $render is on; the raw path below never touches them.
  my $line_buf = '';
  my $shown    = '';

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
    if ($render) {
      $pending .= $chunk;
      $line_buf .= Encode::decode( 'UTF-8', $pending, Encode::FB_QUIET );
      while ( $line_buf =~ s/\A([^\n]*)\n// ) {
        my $text = $self->_render_stream_line( $render, $1 );
        next unless length $text;
        print {$log_fh} to_octets($text);
        print $text if $stream_terms;
        $shown = substr $text, -1;
      }
    }
    else {
      print {$log_fh} $chunk;
      if ($stream_terms) {
        $pending .= $chunk;
        print Encode::decode( 'UTF-8', $pending, Encode::FB_QUIET );
      }
    }
    # The classification buffer keeps the raw octets whatever the terminal and
    # the log were given: _run_result reads the result object out of the tail
    # of the stream, and rendering has just dropped it on the floor.
    $output .= $chunk;
  }

  # A last line the command left without a newline (it was killed, or it simply
  # does not end its output with one) still has something to say.
  if ( $render && length $line_buf ) {
    my $text = $self->_render_stream_line( $render, $line_buf );
    if ( length $text ) {
      print {$log_fh} to_octets($text);
      print $text if $stream_terms;
      $shown = substr $text, -1;
    }
  }
  # Rendered text arrives as deltas and the last one rarely ends a line, so
  # without this the shell prompt (and the next log line) lands mid-sentence.
  if ( $render && length $shown && $shown ne "\n" ) {
    print {$log_fh} "\n";
    print "\n" if $stream_terms;
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
        "TIMEOUT after ${elapsed}s -- sending SIGTERM to $pid (group -$pid)" );
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
# Live output for a structured stream
# ---------------------------------------------------------------------------

# One line of a rendered stream, as text for the terminal and the log, or the
# empty string for a line that carries nothing a human wants to read.
#
# This exists because of a trap in the `kind: claude-code` contract. A run has
# to be asked for structured output before it will report on itself, and plain
# `--output-format json` buys that by printing NOTHING until the run ends --
# which silently cancels the live output App::karr::Foundation promises for a
# TTY, on exactly the runs that take half an hour. `stream-json` ends with the
# same result object and streams on the way there, so the contract asks for
# that instead and the rendering happens here.
#
# What is rendered is the assistant's own text, which is the same choice
# App::karr::Foundation's documented jq pipeline makes
# (`select(.type == "stream_event") | .event.delta.text`). Everything else in
# the stream -- the init banner, the per-message envelopes, the tool plumbing,
# the final result object -- is machinery, and the machinery is what an
# operator watching a board does not want to read. The result object is not
# lost by suppressing it: the drain classifies from it (it stays in the raw
# buffer) and logs a RESULT line of its own.
#
# A line that is not JSON at all passes through verbatim. The pipe is shared
# with the command's stderr, so a wrapper's banner, a `set -x` trace or a
# warning can land between two stream events, and swallowing those would be
# the same mistake one level down.
sub _render_stream_line {
  my ( $self, $render, $line ) = @_;
  return '' unless $render eq 'stream-json';
  return '' unless defined $line && $line =~ /\S/;
  # Same cheap pre-filter as _run_result: prose never reaches the parser.
  return "$line\n" unless $line =~ /\A\s*\{.*\}\s*\z/s;
  my $ev = eval { json_decode($line) };
  return "$line\n" unless ref $ev eq 'HASH';
  return '' unless ( $ev->{type} // '' ) eq 'stream_event';
  my $delta = ( $ev->{event} // {} )->{delta};
  return '' unless ref $delta eq 'HASH';
  my $text = $delta->{text};
  return defined $text && !ref $text ? $text : '';
}

# ---------------------------------------------------------------------------
# Structured result (a claude-code run's own report)
# ---------------------------------------------------------------------------

# How much of a transcript is looked at for the report at its end. The buffer
# is everything the agent printed and can be megabytes; the object itself is a
# couple of kilobytes. A report that does not fit in the window fails to parse
# and the run counts as unstructured, which is the safe direction.
my $RESULT_TAIL_BYTES = 1_048_576;

# The run's own report, or undef when it made none.
#
# How foundation finds out that a run answers structurally: it does not ask,
# and it is not told. It reads what the run left at the end of its output.
#
# The two alternatives are both worse. A configuration key ("this board's agent
# emits json") is a second copy of a fact the command already carries, and a
# copy that has gone stale is worse than no copy at all -- it makes foundation
# look for a report that is not there, or ignore one that is, and it puts the
# operator in charge of keeping two strings in step. Sniffing the command
# string for --output-format json means parsing a shell template foundation
# deliberately does not parse (#159: the expansion is the shell's, not ours),
# and it guesses wrong on the very pipeline this module's own documentation
# recommends -- `... --output-format stream-json ... | jq -r ...` carries the
# flag and delivers no JSON at all.
#
# What is not a guess is the output. `claude -p --output-format json` ends with
# exactly one line, a JSON object with "type":"result". That is the format's
# contract, so reading the tail asks the run itself.
#
# Only the LAST non-empty line is examined, and that is the whole answer to
# "an agent that mixes prose and JSON must not be misclassified":
#
#   * prose BEFORE the object is irrelevant -- a wrapper's banner, a `set -x`
#     line, a warning that reached the shared stdout/stderr pipe earlier;
#   * prose CONTAINING an object cannot reach the classifier. An agent working
#     a karr board prints the board, and a board can hold a pasted result
#     object the way #160's board held a "503" and a "403". Anything that
#     scans a whole transcript eventually reads the agent's own quotation as
#     the agent's own report; a tail read cannot;
#   * anything printed AFTER the object makes the run unstructured again and
#     the text scan takes over. Structure is lost, never invented.
sub _run_result {
  my ( $self, $output ) = @_;
  return undef unless defined $output && length $output;
  my $tail = length($output) > $RESULT_TAIL_BYTES
    ? substr( $output, -$RESULT_TAIL_BYTES )
    : $output;
  my ( $last ) = grep { /\S/ } reverse split /\n/, $tail, -1;
  return undef unless defined $last;
  $last =~ s/\A\s+//;
  $last =~ s/\s+\z//;
  # Cheap pre-filter before the parser, the same bargain _match_error makes
  # with its trigger substrings: nearly every run ends in prose, and prose is
  # rejected here without JSON::MaybeXS ever seeing it.
  return undef unless $last =~ /\A\{.*\}\z/s;
  # The buffer holds octets (the tee keeps the log and the scan byte-exact),
  # and json_decode is the character-level door -- App::karr::Encoding owns
  # both crossings, so the decode is from_octets and nothing else.
  my $data = eval { json_decode( from_octets( $last ) ) };
  return undef unless ref $data eq 'HASH';
  return undef unless ( $data->{type} // '' ) eq 'result';
  return $data;
}

# What the report says about how the run ended, as ( $error, $ended ):
#
#   $ended  always describes the ending, for the log and for .karr.state
#   $error  is set only where that ending is a common error -- the same
#           currency _match_error returns, so the drain treats a reported
#           error and a scanned one alike from there on
#
# A reported error is a hard signal, not a near-miss: it is the run's own
# statement about itself, not an inference drawn from its prose. The progress
# guard #160 put in front of the text scan therefore does not belong in front
# of this one -- that guard exists because a word search over a transcript
# cannot tell the agent's report from the board's contents, which is a problem
# a field in the agent's own result object does not have.
sub _result_error {
  my ( $self, $result ) = @_;
  return ( undef, 'success' ) unless $result->{is_error};

  my $subtype = $result->{subtype} // 'error';

  # A status from the provider is exactly the case the text scan was written
  # for, arriving as a number in a field instead of a word in a sentence. The
  # board backs off, as it always did for a rate limit.
  my $api = $result->{api_error_status};
  return ( "api $api", "api $api" ) if defined $api && length $api;

  # The turn budget ran out. This is the one error flag that reports no
  # failure of the agent and none of the provider: both worked, the task was
  # larger than the budget it was given, and the honest response is to run
  # again rather than to park the board for an exponentially growing hour.
  # So it names the ending and returns no error, and the run is judged the way
  # every other run is -- by what the board did.
  return ( undef, 'max turns' )
    if $subtype eq 'error_max_turns'
    || ( $result->{terminal_reason} // '' ) eq 'max_turns';

  return ( $subtype, $subtype );
}

# The numbers worth keeping out of a report: how far the run got and what it
# cost. .karr.state carries the last one so an operator -- and the coordination
# agent this is groundwork for -- can read the last run's report without
# parsing .karr.log.
sub _result_summary {
  my ( $self, $result, $ended ) = @_;
  return {
    ended    => $ended,
    turns    => $result->{num_turns},
    duration => $result->{duration_ms},
    cost_usd => $result->{total_cost_usd},
    session  => $result->{session_id},
  };
}

# The same report as one .karr.log line. Every field is optional: a report is
# read for its is_error flag first of all, and one that carries no numbers is
# still a report.
sub _result_line {
  my ( $self, $result, $ended ) = @_;
  my @bits;
  my ( $turns, $ms, $cost ) =
    @{$result}{qw( num_turns duration_ms total_cost_usd )};
  # looks_like_number, not a regex: these come out of somebody else's JSON and
  # the only thing being asked is whether they can be printed as numbers. A
  # field that cannot is left out of the line rather than warned about -- a
  # report is read for its error flag first of all, and one carrying no usable
  # numbers is still a report.
  push @bits, ( $turns == 1 ? '1 turn' : "$turns turns" )
    if looks_like_number( $turns );
  push @bits, sprintf( '%.1fs', $ms / 1000 ) if looks_like_number( $ms );
  push @bits, sprintf( '$%.4f', $cost )      if looks_like_number( $cost );
  return "RESULT $ended" . ( @bits ? ' (' . join( ', ', @bits ) . ')' : '' );
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

App::karr::Foundation::Runner - karr-foundation command execution -- fork/pipe/select tee + run classification

=head1 VERSION

version 0.601

=head1 DESCRIPTION

L<App::karr::Foundation::Runner> runs a single agent command for
L<App::karr::Foundation>. It forks the command under C</bin/sh -c>, reads its
combined stdout/stderr over a native pipe, and tees each chunk to the
persistent C<.karr.log>, the terminal (when streaming), and an in-memory buffer
the run is classified from, enforcing the per-run C<max_runtime> timeout. A
weak back-reference to the owning foundation supplies shared options and helpers
(C<dry_run>, C<_stream_to_terminal>, C<_prompt_for>, C<_append_log>,
C<_say_verbose>).

That buffer is read twice over, in this order. First for the run's B<own
report>: an agent invoked with C<--output-format json> ends its output with a
JSON object saying whether the run failed, how it ended, how many turns it
took, how long it ran and what it cost. C<_run_result> finds it -- at the tail
of the output, which is the only place a mixture of prose and JSON cannot be
misread -- and C<_result_error> says whether the ending it describes is a
common error and of what kind.

Only where a run left no report does the older text scan run: observable common
errors (rate limit, auth, network, 5xx, ...) matched against the transcript,
where a symptom word counts only next to a failure word on the same line, or
inside a phrase an API really emits, and an HTTP status only where something
adjacent marks it as one. The drain asks that at all only for a run that made
no progress -- see L<App::karr::Foundation>'s "Drain semantics".

The command is a shell template, not a string karr rewrites: C<PROMPT>,
C<KARR_REPO>, C<KARR_ROLE> and C<KARR_TASK> are exported into the child's
environment and C</bin/sh> expands them like any other parameter. A prompt's own
backticks therefore stay text, and C<< awk '{print $2}' >> reaches awk intact.
C<KARR_TASK> holds the id of the task a C<< mode: ticket >> run was given and is
empty in every other mode; the same id is spelled out in the prompt.

Where the agent came from a definition with an invocation contract that asks
for structured live output (C<kind: claude-code>, #188), the tee renders it: the
assistant's own text goes to the terminal and to F<.karr.log> as it arrives,
while the raw stream stays in the classification buffer. That is what lets the
contract ask for a machine-readable format without losing the live output an
interactive run is watched for. A board that names no agent is on the older
path -- the octets the command printed, verbatim, to both sinks.

A C<.karr.log> it cannot open ends the run for that board B<before> the command
is started, never after: the agent is refused rather than launched unwatched.
Once the fork has happened the parent owes it a C<waitpid>, so nothing between
the two may throw.

The agent is not the only thing that goes through this door. The C<on_drained>
hook (L<App::karr::Foundation>) is a command in a repository that must not
outlive the run that started it either, so it is started here rather than
beside here -- one process-group kill, one timeout, one tee, one place where
the live child is registered for the shutdown handler. What it does B<not>
share is the identity: C<< role => 'hook' >> puts C<KARR_ROLE=hook> in its
environment and leaves C<PROMPT> empty, so its own C<karr> writes land in a
different activity log from the agent's and it is never handed the instruction
to go and pick a card. C<< max_runtime => N >> gives it its own budget, because
how long a board's agent may run says nothing about how long whatever the
operator hung on C<on_drained> may take. Nothing else in this method asks who
the caller is: the run is classified by the drain, which simply does not
classify a hook.

The coordination agent (L<App::karr::Foundation::Coordinator>) is the third,
and the one that needed a third option: it B<is> an agent and needs an
instruction, but not a board's -- so it passes C<< prompt => ... >> beside
C<< role => 'coordinator' >> and gets its own text in C<$PROMPT> instead of
the board's or the hook's silence.

=head2 foundation

The owning L<App::karr::Foundation> instance, held C<weak_ref> to avoid a
reference cycle. Supplies the shared options and helpers a run needs
(C<dry_run>, C<_stream_to_terminal>, C<_prompt_for>, C<_append_log>,
C<_say_verbose>) that do not belong to the Runner itself.

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

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
