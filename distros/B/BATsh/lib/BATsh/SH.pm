package BATsh::SH;
######################################################################
#
# BATsh::SH - Pure Perl sh/bash interpreter
#
# Copyright (c) 2026 INABA Hitoshi <ina.cpan@gmail.com>
#
# Implements sh/bash command set in Perl.
# No external sh or bash required.
#
# Supported:
#   Variable assignment: VAR=value
#   export VAR=value, export VAR, unset VAR
#   echo, printf
#   if/then/elif/else/fi
#   for VAR in list; do ... done
#   while condition; do ... done
#   until condition; do ... done
#   case $var in pat|pat) ... ;; *) ... ;; esac  (|, globs, [classes], ;& ;;&)
#   test / [ ... ]  (file, string, integer comparisons)
#   cd, pwd, exit, true, false, :
#   trap 'cmd' SIG... / trap - SIG / trap '' SIG / trap [-p]  (EXIT + %SIG bridge)
#   read VAR  (reads one line from STDIN)
#   shift [N]  (shift positional parameters left)
#   local VAR=value  (function-scoped variable)
#   $(( arithmetic ))  -- +,-,*,/,%, and $1..$9 inside
#   $( command ) and `command`  (command substitution, nested)
#   name() { ... }, function name { ... }  (function definitions)
#   cmd1 | cmd2 [| cmd3 ...]  (pipeline via tmpfile, 5.005_03)
#   cmd1 && cmd2, cmd1 || cmd2, cmd1 ; cmd2  (compound commands)
#   > >> < 2> 2>> 2>&1 1>&2  (I/O redirection)
#   cmd << DELIM ... DELIM, <<-DELIM, <<'DELIM'  (here-document)
#   cmd &  (background execution of an external command; SH mode)
#   $VAR, ${VAR}, $1..$9, $@, $*, $#, $?, $$, $0, $!
#   ${VAR:-def}, ${VAR:=def}, ${VAR:+alt}
#   ${VAR%pat}, ${VAR%%pat}  (shortest/longest suffix removal)
#   ${VAR#pat}, ${VAR##pat}  (shortest/longest prefix removal)
#   ${VAR/pat/rep}, ${VAR//pat/rep}  (first/all substitution)
#   ${VAR^^}, ${VAR^}, ${VAR,,}, ${VAR,}  (case conversion)
#   ${VAR:N:L}, ${VAR:N}  (substring)
#   ${#VAR}  (string length)
#   arr=(a b c), arr+=(d e)  (indexed array assignment / append)
#   arr[i]=v, arr[i]+=v      (indexed element assignment / append)
#   declare -a arr, declare -A map, typeset ... (array declaration)
#   map=([k1]=v1 [k2]=v2), map[k]=v  (associative array assignment)
#   ${arr[i]}, ${map[key]}   (element access; $arr == ${arr[0]})
#   ${arr[@]}, ${arr[*]}     (all elements)
#   ${#arr[@]}, ${#map[@]}   (element count)
#   ${#arr[i]}               (length of one element)
#   ${!arr[@]}, ${!map[@]}   (indices / keys)
#   unset arr, unset arr[i]  (whole array / single element)
#   source / . file
#   {a,b,c}, {1..5}, {a..e}[..step]  (brace expansion, v0.07)
#   shopt -s/-u extglob; ?(),*(),+(),@(),!()  (extended pattern matching
#     in case patterns and ${VAR%pat}-family patterns, v0.07)
#   cmd <<< word  (here-string, v0.07)
#   <(cmd), >(cmd)  (process substitution via temp file, v0.07)
#   select VAR in list; do ... done  (menu loop, v0.07)
#   alias name=value, alias, unalias  (v0.07)
#   exec cmd, exec > file ...  (v0.07)
#   ( cmd1; cmd2 )  (subshell command group with isolated scope, v0.07)
#
######################################################################

use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }

use File::Spec ();
use Carp qw(croak);
use Fcntl qw(O_RDONLY O_WRONLY O_CREAT O_EXCL O_TRUNC O_APPEND);
use vars qw($VERSION);
$VERSION = '0.08';
$VERSION = $VERSION;

require BATsh::MB;

# Bareword filehandle globs for SH pipeline (Perl 5.005_03 compatible)
use vars qw(*_SH_PIPE_SAVOUT *_SH_PIPE_SAVIN *_SH_PIPE_WFH *_SH_PIPE_RFH);

# Bareword filehandle globs for SH I/O redirection (Perl 5.005_03 compatible)
use vars qw(*_SH_REDIR_SRC *_SH_REDIR_DST *_SH_REDIR_SAVOUT *_SH_REDIR_SAVERR *_SH_REDIR_SAVIN);

# Bareword filehandle glob for here-document temp file (Perl 5.005_03 compatible)
use vars qw(*_HD_TMP);

# Bareword filehandle globs for background-job PID temp file (Perl 5.005_03 compatible)
use vars qw(*_BG_TMP *_BG_PIDFH);

# $!  -- PID of the most recent background job (package-level so _expand and
# the test suite can read it).  Empty string before any background job.
use vars qw($_LAST_BG_PID);
$_LAST_BG_PID = '';

# Active nesting depth of command substitution _cmd_subst().  Each active
# level uses a distinct capture temp file so that a nested $( ... $( ... ) )
# does not truncate/unlink the file the outer level is still capturing into.
# (Sequential, non-overlapping substitutions safely reuse the same depth.)
use vars qw($_SUBST_DEPTH);
$_SUBST_DEPTH = 0;

# Active nesting depth of pipeline execution _exec_sh_pipe().  A pipeline
# segment may itself contain a $(...) whose body is another pipeline; each
# active pipeline must use distinct stage temp files so the inner pipeline
# does not clobber/unlink the outer pipeline's stage file (which would leave
# the outer's final segment reading from the real STDIN and hanging).
use vars qw($_PIPE_DEPTH);
$_PIPE_DEPTH = 0;

# SH function registry -- must be package-level for access from _expand and _exec_line
use vars qw(%_SH_FUNCTIONS);

# SH alias registry (v0.07).  NAME (case-sensitive, as bash) => raw
# replacement text.  Populated by the "alias" builtin, consumed by
# _alias_expand_line() at the top of _exec_line().
use vars qw(%_SH_ALIAS);

# Variable attribute registries (v0.08).  Keyed by the UPPERCASED variable
# name (matching BATsh::Env's case-insensitive store).  %_SH_READONLY marks
# a variable read-only ("readonly" / "declare -r"); a later assignment is
# refused with a diagnostic and non-zero status.  %_SH_INTATTR marks the
# integer attribute ("declare -i"); an assignment then evaluates its right
# hand side as shell arithmetic.
use vars qw(%_SH_READONLY %_SH_INTATTR);

# Shell umask (v0.08).  Native Win32 Perl's umask() is effectively a no-op
# (it always reports 0), so the shell keeps its OWN notion of the mask so
# that "umask MODE; umask" round-trips on every platform.  It is seeded
# once from the real process umask (meaningful on Unix-like systems) and,
# on a set, is also pushed to the OS umask so it still affects file modes
# where the OS honours it.
use vars qw($_SH_UMASK $_SH_UMASK_INIT);
$_SH_UMASK_INIT = 0;

# Process-substitution bookkeeping (v0.07).  <(cmd) is captured eagerly
# into a temp file during _expand(); >(cmd) defers cmd until after the
# current simple command finishes.  Both use unique sysopen(O_CREAT|
# O_EXCL) temp files, mirroring _hd_tempfile() / _subst_tempfile().
use vars qw($_PROCSUB_SEQ @_PROCSUB_TMPFILES @_PROCSUB_DEFERRED);
$_PROCSUB_SEQ      = 0;
@_PROCSUB_TMPFILES = ();
@_PROCSUB_DEFERRED = ();

# SH array storage (v0.06).  Indexed and associative arrays.
#   %_SH_ARRAY      : NAME (uppercased) => hashref { subscript => value }
#   %_SH_ARRAY_TYPE : NAME (uppercased) => 'indexed' | 'assoc'
# Array names are case-insensitive (stored uppercase) to match the scalar
# store.  Indexed arrays may be sparse; subscripts are integer strings.
# Associative arrays use arbitrary string subscripts.  Element order for
# ${arr[@]} is ascending numeric index (indexed) or ascending key sort
# (assoc) -- the latter is chosen for deterministic output across Perl
# versions, since bash leaves associative-array order unspecified.
use vars qw(%_SH_ARRAY %_SH_ARRAY_TYPE);

# SH trap registry (v0.06).  Maps a normalized signal name (e.g. INT, TERM,
# EXIT) to the raw command string to run when that signal/event fires.  An
# empty string means "ignore"; absence means "default".  Real signals are
# bridged to Perl's %SIG (see _sh_set_os_sig); the EXIT pseudo-signal is run
# internally when the script exits (see fire_exit_trap / _cmd_exit).
use vars qw(%_SH_TRAP);

# getopts state (v0.07).  POSIX getopts tracks its position across the
# argument list with the OPTIND shell variable (1-based, stored in the
# Env), but the offset of the next option CHARACTER inside a clustered
# argument such as "-abc" is internal state that the shell does not
# expose.  We keep that character offset in $_GETOPTS_CHARPOS and detect
# an external reset of the loop (the script setting OPTIND=1 before a
# fresh getopts loop) by remembering, in $_GETOPTS_LAST_OPTIND, the
# OPTIND value getopts itself last stored: if the OPTIND we read back
# differs, the caller reset the loop and the character offset restarts.
use vars qw($_GETOPTS_CHARPOS $_GETOPTS_LAST_OPTIND);
$_GETOPTS_CHARPOS     = 0;
$_GETOPTS_LAST_OPTIND = 0;

# "command NAME ..." bypass flag (v0.08).  The POSIX "command" builtin runs
# NAME as if no shell function of that name existed.  _cmd_command() localizes
# this to 1 around the re-dispatch of the raw remainder so that the
# function-lookup gate in _exec_line_impl() is skipped for that one command
# (builtins and external programs are unaffected, exactly as bash does).
use vars qw($_CMD_NO_FUNC);
$_CMD_NO_FUNC = 0;
# ----------------------------------------------------------------
my $LAST_STATUS = 0;   # $?

# Shell options (set -e / -u / -x), process-persistent like the Env store;
# reset by reset_sh_options() at the start of each top-level run.
my $_OPT_ERREXIT = 0;   # set -e: exit on a failing simple command
my $_OPT_NOUNSET = 0;   # set -u: error on expanding an unset variable
my $_OPT_XTRACE  = 0;   # set -x: trace each simple command to STDERR
my $_OPT_EXTGLOB = 0;   # shopt -s extglob: ?(),*(),+(),@(),!() in patterns
my $_ERREXIT_HOLD = 0;  # >0: -e suppressed (condition / non-final &&-|| member)
my $_ERREXIT_DONE = 0;  # set by _exec_sh_compound: -e already adjudicated
my @FUNCTION_STACK = ();   # for 'local' variable scoping

# Signal: pending exit
my $_EXIT_CODE    = undef;   # undef = no exit pending
my $_BREAK        = 0;       # break out of loop
my $_CONTINUE     = 0;       # continue next iteration
my $_RETURN       = 0;       # return from function/source

# Here-document state (Perl 5.005_03 compatible)
my $_HD_SEQ       = 0;        # per-process counter for unique temp names
my @_HD_TMPFILES  = ();       # tempfiles to remove on END (failsafe cleanup)

# Background-job state (Perl 5.005_03 compatible)
my $_BG_SEQ       = 0;        # per-process counter for unique pidfile names
my @_BG_TMPFILES  = ();       # pidfiles to remove on END (failsafe cleanup)

# Command-substitution capture state (Perl 5.005_03 compatible)
my $_SUBST_SEQ      = 0;      # per-process counter for unique capture names
my @_SUBST_TMPFILES = ();     # capture files to remove on END (failsafe cleanup)

# SH pipeline stage state (Perl 5.005_03 compatible)
my $_PIPE_SEQ      = 0;       # per-process counter for unique stage names
my @_SHP_TMPFILES  = ();      # stage files to remove on END (failsafe cleanup)

# ----------------------------------------------------------------
# Public: execute an array of SH lines
# Returns exit status (0 = success)
# ----------------------------------------------------------------
# ----------------------------------------------------------------
# get_status / set_status: read or set the SH-side $? from outside
# the interpreter.  Used by BATsh.pm to bridge $? <-> %ERRORLEVEL%
# at every CMD<->SH section boundary.  Call as plain functions.
# ----------------------------------------------------------------
sub get_status { return $LAST_STATUS }
sub set_status {
    $LAST_STATUS = defined $_[0] ? int($_[0]) : 0;
    return $LAST_STATUS;
}

# ----------------------------------------------------------------
# exit_code_pending: the exit code set by the SH "exit" builtin in the
# most recent exec_block, or undef when no exit was executed.  The value
# stays readable until the next exec_block resets it; BATsh.pm reads it
# right after each SH block to terminate the whole script.
# ----------------------------------------------------------------
sub exit_code_pending { return $_EXIT_CODE }

sub exec_block {
    my ($class, $lines_ref, %opts) = @_;
    $_EXIT_CODE = undef;
    $_BREAK     = 0;
    $_CONTINUE  = 0;
    $_RETURN    = 0;

    my $status = _run_lines($class, $lines_ref, \%opts);
    return defined $_EXIT_CODE ? $_EXIT_CODE : $status;
}

# ----------------------------------------------------------------
# Run an array of lines sequentially, handling multi-line blocks
# Returns last exit status
# ----------------------------------------------------------------
sub _run_lines {
    my ($class, $lines_ref, $opts_ref) = @_;
    my @lines = @{$lines_ref};
    my $status = 0;
    my $i = 0;

    while ($i <= $#lines) {
        return $status if defined $_EXIT_CODE;
        return $status if $_BREAK || $_RETURN;

        my $line = $lines[$i];
        $i++;
        # Normalise
        $line =~ s/\r?\n\z//;
        # Strip a trailing "# comment" (word-initial, unquoted) and write
        # the cleaned line back so downstream block parsers see it too.
        my $nocmt = _strip_sh_comment($line);
        if ($nocmt ne $line) { $line = $nocmt; $lines[$i - 1] = $line; }
        # Skip empty and comment lines
        next if $line =~ /\A\s*\z/;
        next if $line =~ /\A\s*#/;

        # Check for block-opening keywords
        my $stripped = $line;
        $stripped =~ s/\A\s+//;
        my $first = '';
        ($first) = ($stripped =~ /\A(\S+)/);
        $first = lc(defined($first) ? $first : '');

        if ($first eq 'if') {
            ($status, $i) = _parse_if($class, \@lines, $i - 1, $opts_ref);
            next;
        }
        if ($first eq 'for') {
            ($status, $i) = _parse_for($class, \@lines, $i - 1, $opts_ref);
            next;
        }
        if ($first eq 'select') {
            ($status, $i) = _parse_select($class, \@lines, $i - 1, $opts_ref);
            next;
        }
        if ($first eq 'while' || $first eq 'until') {
            ($status, $i) = _parse_while($class, \@lines, $i - 1, $opts_ref);
            next;
        }
        if ($first eq 'case') {
            ($status, $i) = _parse_case($class, \@lines, $i - 1, $opts_ref);
            next;
        }

        # Subshell command group: "( commands )" [redir].  A leading "(("
        # is arithmetic-expansion-flavoured, not a subshell group, and is
        # left alone (standalone "((...))" arithmetic commands are not
        # implemented; only "$((...))" as an expansion is).
        if ($stripped =~ /\A\(/ && $stripped !~ /\A\(\(/) {
            ($status, $i) = _parse_subshell($class, \@lines, $i - 1, $opts_ref);
            next;
        }

        # Function definition: "name() {" or "function name {"
        if ($stripped =~ /\A(?:function\s+[A-Za-z_]|[A-Za-z_][A-Za-z0-9_]*\s*\(\s*\))/) {
            ($status, $i) = _parse_function($class, \@lines, $i - 1, $opts_ref);
            next;
        }

        # Here-document: cmd << [-] [QUOTE]DELIM[QUOTE]
        # Detected on a simple command line; body is read from following
        # lines up to a line equal to DELIM (after optional tab strip for <<-).
        my @hd = _hd_detect($line);
        if (@hd) {
            my ($cmd_part, $dash, $delim, $quoted) = @hd;
            my @body = ();
            my $terminated = 0;
            while ($i <= $#lines) {
                my $bl = $lines[$i];
                $i++;
                $bl =~ s/\r?\n\z//;
                my $probe = $bl;
                $probe =~ s/\A\t+// if $dash;   # <<- strips leading tabs
                if ($probe eq $delim) { $terminated = 1; last }
                $bl =~ s/\A\t+// if $dash;       # also strip tabs from body
                push @body, $bl;
            }
            if (!$terminated) {
                warn "sh: unexpected EOF while looking for here-document delimiter \`$delim'\n";
                $LAST_STATUS = 2;
                $status = 2;
                next;
            }
            $status = _hd_run($class, $cmd_part, \@body, $quoted, $opts_ref);
            next;
        }

        # A simple-command prefix followed on the SAME physical line by a
        # control structure introduced with ';' -- e.g.
        #   x=""; if [ -z "$x" ]; then echo empty; fi
        #   i=0; while [ $i -lt 3 ]; do ...; done
        #   v=cat; case $v in ...; esac
        # The first token is not a control keyword, so the block-opener
        # dispatch above did not fire.  Run the prefix now, then rewrite
        # the current slot to the control structure and reprocess it, so
        # the proper _parse_* handles it (and may consume following
        # physical lines for a multi-line body).
        my $ctl_off = _find_control_split($line);
        if (defined $ctl_off) {
            my $prefix = substr($line, 0, $ctl_off);
            my $rest   = substr($line, $ctl_off);
            $prefix =~ s/\s*;\s*\z//;
            if ($prefix =~ /\S/) {
                $_ERREXIT_DONE = 0;
                $status = _exec_line($class, $prefix, $opts_ref);
                _errexit_check($status) unless $_ERREXIT_DONE;
                $_ERREXIT_DONE = 0;
            }
            last if defined $_EXIT_CODE || $_BREAK || $_RETURN;
            $lines[$i - 1] = $rest;
            $i--;
            next;
        }

        $_ERREXIT_DONE = 0;
        $status = _exec_line($class, $line, $opts_ref);
        _errexit_check($status) unless $_ERREXIT_DONE;
        $_ERREXIT_DONE = 0;
        $_CONTINUE = 0 if $_CONTINUE;
    }
    return $status;
}

# ----------------------------------------------------------------
# Execute one SH line
# ----------------------------------------------------------------
# _exec_line: thin wrapper around _exec_line_impl() that drains any
# process-substitution bookkeeping (v0.07) added while executing THIS
# call's line -- running deferred >(cmd) jobs and removing <(cmd) temp
# files -- after the simple command has run.  Because _exec_line_impl()
# itself calls back into _exec_line() (never _exec_line_impl() directly)
# for background execution, redirection wrapping, compound/pipeline
# segments, and exec, each nesting level drains only the entries it
# introduced, using the before/after array-length markers below.
# ----------------------------------------------------------------
sub _exec_line {
    my ($class, $raw, $opts_ref) = @_;
    my $tmp_before = scalar(@_PROCSUB_TMPFILES);
    my $def_before = scalar(@_PROCSUB_DEFERRED);
    my $rc = _exec_line_impl($class, $raw, $opts_ref);
    if (@_PROCSUB_DEFERRED > $def_before) {
        my @jobs = splice(@_PROCSUB_DEFERRED, $def_before);
        for my $job (@jobs) {
            my ($tmp, $cmd) = @{$job};
            _sh_exec_with_redirs($class, $cmd, [[0, 0, $tmp]], $opts_ref);
        }
    }
    if (@_PROCSUB_TMPFILES > $tmp_before) {
        my @files = splice(@_PROCSUB_TMPFILES, $tmp_before);
        for my $f (@files) { unlink $f if defined $f }
    }
    return $rc;
}

sub _exec_line_impl {
    my ($class, $raw, $opts_ref) = @_;

    my $line = $raw;
    $line =~ s/\A\s+//;
    return 0 if $line =~ /\A\s*\z/;
    return 0 if $line =~ /\A\s*#/;

    # Shebang: treat as comment
    return 0 if $line =~ /\A#!/;

    # Alias expansion (v0.07): replace a leading command word that names
    # an active alias with its stored text, re-checking the new leading
    # word up to a small bounded number of times so that alias chains
    # (alias ll=ls; alias ls='ls -la') resolve.  A name is expanded at
    # most once per line to guard against a self-referential alias
    # (alias ls=ls) looping forever.  Only the first word of the line is
    # considered -- bash's "trailing space in the alias value also makes
    # the next word alias-eligible" refinement is not modelled.
    $line = _alias_expand_line($line);

    # Brace expansion (v0.07): {a,b,c} and {1..5}/{a..e} word-generation,
    # performed lexically on the raw line before any other expansion, so
    # that e.g. "echo a{b,c}d" becomes two arguments "abd acd".  Regions
    # that are quoted, or that belong to ${...}/$(...)/$((...))/`...`,
    # are left untouched (their braces/parens are not brace-expansion
    # syntax).
    $line = _brace_expand_line($line);

    # ----------------------------------------------------------------
    # Background execution: an unquoted trailing & (v1).
    # Detected here, BEFORE _split_sh_compound, so that the bare & is
    # never mistaken for && and so that an internal & (e.g. in 2>&1 or
    # >&2) is left untouched.  Only the single & at the very end of the
    # line is consumed.  Builtins / functions / control words / variable
    # assignments run in the FOREGROUND (the & is ignored); only external
    # commands are launched asynchronously.
    # ----------------------------------------------------------------
    my ($_is_bg, $_bg_line) = _split_trailing_bg($line);
    if ($_is_bg) {
        $line = $_bg_line;
        my $probe = $line;
        $probe =~ s/\A\s+//;
        my $w0 = '';
        ($w0) = ($probe =~ /\A(\S+)/);
        $w0 = '' unless defined $w0;
        if (_sh_word_is_foreground($w0)) {
            # & ignored: run the stripped line in the foreground.
            return _exec_line($class, $line, $opts_ref);
        }
        my $exp = _expand($class, $line);
        $exp =~ s/\A\s+//;
        $exp =~ s/\s+\z//;
        return _bg_launch($class, $exp);
    }

    # Detect && / || / ; compound commands BEFORE expansion.
    # These must be split before _expand so that short-circuit logic works.
    my @compound = _split_sh_compound($line);
    if (@compound > 1) {
        return _exec_sh_compound($class, \@compound, $opts_ref);
    }

    # set -x: trace the simple command to STDERR (the raw, pre-expansion
    # line -- expanding a copy here would run $(...) substitutions twice).
    print STDERR '+ ', BATsh::MB::dec($line), "\n" if $_OPT_XTRACE;

    # Detect pipeline BEFORE variable expansion to avoid expanding
    # pipe-like characters inside command substitutions prematurely.
    # _split_sh_pipe returns >1 segment only when bare | is present.
    my @pipe_segs = _split_sh_pipe($line);
    if (@pipe_segs > 1) {
        return _exec_sh_pipe($class, \@pipe_segs, $opts_ref);
    }

    # A single control/compound command (while/for/if/until/case/select or
    # a "( subshell )") may reach here as a pipeline element or && / ||
    # operand -- e.g. the right side of  cmd | while read x; do ...; done,
    # or  true && for i in ..; do ..; done.  Route it through the block
    # runner so its inline ';'-separated body is parsed by the proper
    # _parse_* handler instead of being split and exec'd as external words.
    if (_seg_is_control($line)) {
        my @one = ($line);
        return _run_lines($class, \@one, $opts_ref);
    }

    # Array / associative-array operations (v0.06).  Detected on the RAW line
    # (before _expand) so that the "(a b c)" literal and the "[sub]" subscripts
    # are not mangled by variable / command-substitution expansion.
    {
        my @h = _sh_try_array_op($class, $line, $opts_ref);
        return $h[1] if @h;
    }

    # trap (v0.06).  Detected on the RAW line so that the handler command is
    # captured literally and (re-)expanded only when the trap fires, matching
    # shell semantics for e.g. trap 'rm $tmp' EXIT.
    {
        my $probe = $line;
        $probe =~ s/\A\s+//;
        if ($probe =~ /\Atrap(\s.*|)\z/is && $probe !~ /\Atrap\s*=/) {
            return _cmd_trap($class, $1, $opts_ref);
        }
    }

    # POSIX assignment prefix on the RAW line: `VAR=value command args`.
    # Detected before expansion so that a value containing $(...) or quoted
    # spaces is not mistaken for a trailing command.  Pure assignments (no
    # command following) fall through to the post-expansion handler below.
    {
        my ($pairs_ref, $remainder) = _sh_assign_prefix($line);
        if ($pairs_ref && defined $remainder && $remainder ne '') {
            my $ro_fail = 0;
            for my $p (@{$pairs_ref}) {
                my ($var, $rawval) = @{$p};
                my $val = _arr_dequote(_expand($class, $rawval));
                $ro_fail = 1 unless _sh_store_scalar($var, $val);
            }
            if ($ro_fail) { $LAST_STATUS = 1; return 1 }
            return _exec_line($class, $remainder, $opts_ref);
        }
    }

    # Keep the pre-expansion text around.  It is used below (echo) to
    # decide whether filename globbing should even be attempted: that
    # decision must be based on glob metacharacters that were literally
    # present in the source line, never on characters that merely ended
    # up looking like "*", "?" or "[" because a variable's *value*
    # happened to contain them (e.g. a getopts "?"/":" result).  This is
    # the same principle the tilde-prepass above already relies on:
    # expansion results are not themselves subject to re-expansion.
    my $_raw_pre_expand = $line;

    # Expand variables and command substitutions
    $line = _expand($class, $line);

    # Strip trailing ;
    $line =~ s/\s*;\s*\z//;

    # exec (v0.07): "exec > file" (etc.) applies its redirections
    # permanently to the current shell (no restore); "exec cmd ..." runs
    # cmd with those redirections and then terminates the whole script
    # with cmd's exit status, approximating process replacement without
    # a real fork/exec (this interpreter has no fork, by design -- see
    # the pipeline / background-job implementation notes above).
    if ($line =~ /\Aexec(?:\s+(.*)|\s*)\z/is) {
        my $exec_rest = defined $1 ? $1 : '';
        return _cmd_exec($class, $exec_rest, $opts_ref);
    }

    # Here-string: cmd <<< word (v0.07).  Detected after expansion (the
    # word is fully variable/command/arithmetic-expanded, like any other
    # word) and turned into an ordinary "< tempfile" stdin redirection,
    # reusing the here-document temp-file machinery.
    {
        my ($hs_line, $hs_content) = _sh_strip_herestring($line);
        if (defined $hs_content) {
            my $tmp = _hd_tempfile($hs_content . "\n");
            if (!defined $tmp) { $LAST_STATUS = 2; return 2 }
            my ($clean_line, $redirs_ref) = _sh_strip_redirects($hs_line);
            unshift @{$redirs_ref}, [0, 0, $tmp]
                unless grep { $_->[0] == 0 } @{$redirs_ref};
            my $rc = _sh_exec_with_redirs($class, $clean_line, $redirs_ref, $opts_ref);
            unlink $tmp;
            @_HD_TMPFILES = grep { $_ ne $tmp } @_HD_TMPFILES;
            return $rc;
        }
    }

    # Detect I/O redirections: >, >>, <, 2>, 2>>, 2>&1
    # Must be done after expansion so that variable-in-filename works.
    my ($clean_line, $sh_redirs_ref) = _sh_strip_redirects($line);
    if (@{$sh_redirs_ref}) {
        return _sh_exec_with_redirs($class, $clean_line, $sh_redirs_ref, $opts_ref);
    }
    $line = $clean_line;

    my ($cmd, $rest) = _split_sh($line);
    return 0 unless defined $cmd && $cmd ne '';

    my $lc_cmd = lc($cmd);

    # Pure assignment: VAR=value (no spaces around =).  Assignment prefixes
    # of the form `VAR=value command` were already handled before expansion,
    # so anything reaching here is a standalone assignment.  Match the whole
    # (expanded) line so values containing spaces are preserved in full.
    if ($line =~ /\A([A-Za-z_][A-Za-z0-9_]*)=(.*)\z/s) {
        my ($var, $val) = ($1, $2);   # capture before $1 is clobbered
        # Dequote the value the same way command words are dequoted, so
        # concatenated quotes (a"b"c, x'y'z) and backslash escapes resolve
        # correctly -- not just a single outermost "..." / '...' pair.
        $val = _arr_dequote($val);
        my $ok = _sh_store_scalar($var, $val);
        $LAST_STATUS = $ok ? 0 : 1;
        return $ok ? 0 : 1;
    }

    if ($lc_cmd eq 'export')  { return _cmd_export($rest) }
    if ($lc_cmd eq 'unset')   { return _cmd_unset($rest) }
    if ($lc_cmd eq 'echo') {
        # Apply word-splitting and glob expansion to unquoted tokens
        # (tilde expansion already happened earlier, in _expand()).
        #
        # Whether to glob at all is decided from the RAW, pre-expansion
        # source text -- NOT from the already-expanded $rest.  By this
        # point $rest has had all $VAR / ${VAR} / $(...) substitutions
        # applied, so a variable whose *value* happens to be "?" (as
        # getopts sets $opt on an unknown option, or ":" on a missing
        # argument) would otherwise be indistinguishable from a literal
        # "?" glob pattern typed in the script -- and get run through
        # _parse_args()/glob() against the current directory, silently
        # replacing the echoed value with whatever 1-character filename
        # happened to match.  Checking the raw text instead means only
        # a glob metacharacter that was actually written in the source
        # (e.g. "echo *.txt") triggers globbing.
        my (undef, $raw_rest) = _split_sh($_raw_pre_expand);
        $raw_rest = '' unless defined $raw_rest;
        if (_raw_has_glob($raw_rest)) {
            my @words = _parse_args($rest);
            $rest = join(' ', @words);
        }
        return _cmd_echo($rest);
    }
    if ($lc_cmd eq 'printf')  { return _cmd_printf($rest) }
    if ($lc_cmd eq 'cd')      { return _cmd_cd($rest) }
    if ($lc_cmd eq 'pwd')     { print Cwd::cwd(), "\n"; return 0 }
    if ($lc_cmd eq 'exit')    { return _cmd_exit($rest) }
    if ($lc_cmd eq 'true')    { $LAST_STATUS = 0; return 0 }
    if ($lc_cmd eq 'false')   { $LAST_STATUS = 1; return 1 }
    if ($lc_cmd eq ':')       { $LAST_STATUS = 0; return 0 }
    if ($lc_cmd eq 'read')    { return _cmd_read($rest) }
    if ($lc_cmd eq 'test' || $cmd eq '[') { return _cmd_test($rest) }
    if ($lc_cmd eq 'source' || $cmd eq '.') { return _cmd_source($class, $rest, $opts_ref) }
    if ($lc_cmd eq 'return')  { $_RETURN = 1; $LAST_STATUS = ($rest =~ /\A\s*(\d+)/) ? int($1) : 0; return $LAST_STATUS }
    if ($lc_cmd eq 'break')   { $_BREAK = 1; return 0 }
    if ($lc_cmd eq 'continue') { $_CONTINUE = 1; return 0 }
    if ($lc_cmd eq 'shift')   { return _cmd_shift($rest) }
    if ($lc_cmd eq 'getopts') { return _cmd_getopts($rest) }
    if ($lc_cmd eq 'local')   { return _cmd_local($rest) }
    if ($lc_cmd eq 'set')     { return _cmd_set_sh($rest) }
    if ($lc_cmd eq 'shopt')   { return _cmd_shopt($rest) }
    if ($lc_cmd eq 'alias')   { return _cmd_alias($rest) }
    if ($lc_cmd eq 'unalias') { return _cmd_unalias($rest) }
    if ($lc_cmd eq 'eval') {
        # POSIX eval: the (already expanded) arguments are stripped of one
        # level of quoting, concatenated, and executed as a new command
        # line -- which re-parses and re-expands, giving the double
        # expansion eval exists for.  "eval" with no arguments is a noop.
        if (!defined $rest || $rest =~ /\A\s*\z/) { $LAST_STATUS = 0; return 0 }
        my @words = _parse_args($rest);
        return _exec_line($class, join(' ', @words), $opts_ref);
    }
    if ($lc_cmd eq 'let')     { return _cmd_let($rest) }
    if ($lc_cmd eq 'type')    { return _cmd_type($rest) }
    if ($lc_cmd eq 'command') {
        # The introspection forms (-v / -V) are pure lookups; the plain
        # run form re-dispatches the RAW (pre-expansion) remainder so it is
        # expanded exactly once and shell functions of the same name are
        # bypassed.  Passing $_raw_pre_expand keeps expansion single-pass.
        return _cmd_command($class, $rest, $_raw_pre_expand, $opts_ref);
    }
    if ($lc_cmd eq 'umask')    { return _cmd_umask($rest) }
    if ($lc_cmd eq 'hash')     { return _cmd_hash($rest) }
    if ($lc_cmd eq 'readonly') { return _cmd_readonly($class, $rest) }
    if ($lc_cmd eq 'mapfile' || $lc_cmd eq 'readarray') {
        return _cmd_mapfile($class, $rest);
    }

    # Defined SH function (skipped while running under "command NAME ...").
    if (!$_CMD_NO_FUNC && exists $_SH_FUNCTIONS{$cmd}) {
        return _call_sh_function($class, $cmd, $rest, $opts_ref);
    }

    # Unknown: try as external (runs via Perl system)
    return _cmd_external($cmd, $rest);
}

# ----------------------------------------------------------------
# Variable / arithmetic expansion
# ----------------------------------------------------------------
sub _expand {
    my ($class, $str) = @_;
    return '' unless defined $str;

    # Tilde expansion (v0.07) MUST run before variable / command
    # substitution below: POSIX expands ~word from the literal source
    # text only, once, at the start of a word (or right after the '='
    # of a leading NAME= assignment).  A ~ that only appears because a
    # $VAR happened to hold a string starting with "~" must NOT be
    # re-expanded -- doing tilde expansion after $VAR substitution
    # cannot tell the two cases apart, so it must happen first here.
    $str = _tilde_prepass($str);

    # Protect backslash escapes before any expansion.  In POSIX shells the
    # backslash inside double quotes keeps its special meaning only before
    # $ ` " \ and newline, so "\$" is a literal dollar (NO expansion), "\`"
    # is a literal backtick (NO command substitution) and "\\" is a literal
    # backslash.  Earlier releases performed the $-/`-substitutions globally
    # with no escape awareness, so "\$_" expanded $_ to empty and left the
    # stray backslash (giving e.g. perl -e "...uc(\)..." -> syntax error).
    # We stash the escaped specials under NUL-delimited sentinels (a NUL can
    # never occur in shell source) and restore them as literals at the end.
    # Order matters: "\\" first so that "\\$" means backslash + expansion.
    $str =~ s/\\\\/\x00BATSH_BS\x00/g;   # \\  -> literal backslash
    $str =~ s/\\\$/\x00BATSH_DL\x00/g;   # \$  -> literal dollar (no expand)
    $str =~ s/\\`/\x00BATSH_BT\x00/g;    # \`  -> literal backtick (no subst)

    # $(( arithmetic ))
    $str =~ s/\$\(\(\s*(.*?)\s*\)\)/_eval_arith($1)/ge;

    # <(cmd) / >(cmd) process substitution (v0.07) -- MUST run before
    # $(...) below, and before backtick substitution, so that <(...) is
    # never mistaken for a stray "<" redirection operator by the later
    # redirect-stripping stage.
    $str = _replace_process_subst($class, $str);

    # $( command ) substitution
    # Use _extract_cmd_subst to correctly handle nested () and quoted ) chars.
    $str = _replace_cmd_subst($class, $str);

    # backtick command substitution: `cmd`
    $str =~ s/`([^`]*)`/_cmd_subst($class, $1)/ge;

    # ---- Array expansions (v0.06) ----------------------------------
    # These MUST precede the scalar ${#VAR} / ${VAR} rules below so that a
    # subscripted reference is never mis-parsed as a plain variable.

    # ${#NAME[@]} / ${#NAME[*]} -- number of set elements
    $str =~ s/\$\{#([A-Za-z_][A-Za-z0-9_]*)\[[\@*]\]\}/
        _arr_count($1)
    /ge;

    # ${#NAME[SUB]} -- length of one element
    $str =~ s/\$\{#([A-Za-z_][A-Za-z0-9_]*)\[([^\]]*)\]\}/
        do {
            my $v = _arr_get_element($1, _arr_expand_sub($class, $2));
            defined $v ? length($v) : 0
        }
    /ge;

    # ${!NAME[@]} / ${!NAME[*]} -- list of indices / keys
    $str =~ s/\$\{!([A-Za-z_][A-Za-z0-9_]*)\[[\@*]\]\}/
        join(' ', _arr_ordered_keys($1))
    /ge;

    # ${NAME[@]} / ${NAME[*]} -- all elements (space-joined word-split model)
    $str =~ s/\$\{([A-Za-z_][A-Za-z0-9_]*)\[[\@*]\]\}/
        join(' ', _arr_values($1))
    /ge;

    # ${NAME[SUB]} -- single element
    $str =~ s/\$\{([A-Za-z_][A-Za-z0-9_]*)\[([^\]]*)\]\}/
        do {
            my $v = _arr_get_element($1, _arr_expand_sub($class, $2));
            defined $v ? $v : ''
        }
    /ge;
    # ----------------------------------------------------------------

    # ${#VAR} -- length of value (characters, not bytes, under DBCS guard)
    $str =~ s/\$\{#([A-Za-z_][A-Za-z0-9_]*)\}/
        do { my $v = BATsh::Env->get($1);
             defined $v ? BATsh::MB::mb_length($v) : 0 }
    /ge;

    # ${VAR%%pattern} -- remove longest suffix   (MUST be before single %)
    $str =~ s/\$\{([A-Za-z_][A-Za-z0-9_]*)%%([^}]*)\}/
        do { my $v = BATsh::Env->get($1); $v = defined $v ? $v : ''; _sh_remove_suffix($v, $2, 1) }
    /ge;

    # ${VAR%pattern}  -- remove shortest suffix  (single %, not %%)
    $str =~ s/\$\{([A-Za-z_][A-Za-z0-9_]*)%(?!%)([^}]*)\}/
        do { my $v = BATsh::Env->get($1); $v = defined $v ? $v : ''; _sh_remove_suffix($v, $2, 0) }
    /ge;

    # ${VAR##pattern} -- remove longest prefix   (MUST be before single #)
    $str =~ s/\$\{([A-Za-z_][A-Za-z0-9_]*)##([^}]*)\}/
        do { my $v = BATsh::Env->get($1); $v = defined $v ? $v : ''; _sh_remove_prefix($v, $2, 1) }
    /ge;

    # ${VAR#pattern}  -- remove shortest prefix  (single #, not ##)
    $str =~ s/\$\{([A-Za-z_][A-Za-z0-9_]*)#(?!#)([^}]*)\}/
        do { my $v = BATsh::Env->get($1); $v = defined $v ? $v : ''; _sh_remove_prefix($v, $2, 0) }
    /ge;

    # ${VAR//pat/rep} -- replace all occurrences  (MUST be before single /)
    $str =~ s/\$\{([A-Za-z_][A-Za-z0-9_]*)\/\/([^\/}]*)\/([^}]*)\}/
        do { my $v = BATsh::Env->get($1); $v = defined $v ? $v : ''; _sh_replace($v, $2, $3, 1) }
    /ge;

    # ${VAR/pat/rep} -- replace first occurrence  (single /, not //)
    $str =~ s/\$\{([A-Za-z_][A-Za-z0-9_]*)\/(?!\/)([^\/}]*)\/([^}]*)\}/
        do { my $v = BATsh::Env->get($1); $v = defined $v ? $v : ''; _sh_replace($v, $2, $3, 0) }
    /ge;

    # ${VAR^^} -- uppercase all
    $str =~ s/\$\{([A-Za-z_][A-Za-z0-9_]*)\^\^\}/
        do { my $v = BATsh::Env->get($1); defined $v ? uc($v) : '' }
    /ge;

    # ${VAR^} -- uppercase first char
    $str =~ s/\$\{([A-Za-z_][A-Za-z0-9_]*)\^\}/
        do { my $v = BATsh::Env->get($1); $v = defined $v ? $v : ''; ucfirst($v) }
    /ge;

    # ${VAR,,} -- lowercase all
    $str =~ s/\$\{([A-Za-z_][A-Za-z0-9_]*),,\}/
        do { my $v = BATsh::Env->get($1); defined $v ? lc($v) : '' }
    /ge;

    # ${VAR,} -- lowercase first char
    $str =~ s/\$\{([A-Za-z_][A-Za-z0-9_]*),\}/
        do { my $v = BATsh::Env->get($1); $v = defined $v ? $v : ''; lcfirst($v) }
    /ge;

    # ${VAR:offset:length} and ${VAR:offset}
    $str =~ s/\$\{([A-Za-z_][A-Za-z0-9_]*):(-?\d+):(\d+)\}/
        do {
            my $v = BATsh::Env->get($1); $v = defined $v ? $v : '';
            BATsh::MB::mb_substr($v, int($2), int($3))
        }
    /ge;
    $str =~ s/\$\{([A-Za-z_][A-Za-z0-9_]*):(-?\d+)\}/
        do {
            my $v = BATsh::Env->get($1); $v = defined $v ? $v : '';
            BATsh::MB::mb_substr($v, int($2))
        }
    /ge;

    # ${VAR:-default} ${VAR:=default} ${VAR:+alt}
    $str =~ s/\$\{([A-Za-z_][A-Za-z0-9_]*):-(.*?)\}/
        do { my $v = BATsh::Env->get($1); (defined $v && $v ne '') ? $v : $2 }
    /ge;
    $str =~ s/\$\{([A-Za-z_][A-Za-z0-9_]*):=(.*?)\}/
        do {
            my $v = BATsh::Env->get($1);
            if (!defined $v || $v eq '') { BATsh::Env->set($1,$2); $v = $2 }
            $v
        }
    /ge;
    $str =~ s/\$\{([A-Za-z_][A-Za-z0-9_]*):\+([^}]*)\}/
        do { my $v = BATsh::Env->get($1); (defined $v && $v ne '') ? $2 : '' }
    /ge;

    # ${VAR} -- plain expansion (array name yields element 0)
    $str =~ s/\$\{([A-Za-z_][A-Za-z0-9_]*)\}/
        do {
            my $n = $1;
            if (_arr_exists($n)) {
                my $v = _arr_get_element($n, 0); defined $v ? $v : ''
            }
            else {
                my $v = BATsh::Env->get($n);
                _nounset_hit($n) if !defined $v;
                defined $v ? $v : ''
            }
        }
    /ge;

    # $? last status
    $str =~ s/\$\?/$LAST_STATUS/g;

    # $$  PID
    $str =~ s/\$\$/$$/g;

    # $!  PID of the most recent background job (empty before any)
    $str =~ s/\$\!/$_LAST_BG_PID/g;


    # $0 script name
    $str =~ s/\$0/do { my $v=BATsh::Env->get('%0'); defined $v ? $v : '' }/ge;

    # $1..$9 positional parameters
    $str =~ s/\$([1-9])/
        do {
            my $n = $1;
            my $v = BATsh::Env->get("%$n");
            $v = BATsh::Env->get("BATSH_ARG$n") unless defined $v && $v ne '';
            defined $v ? $v : ''
        }
    /ge;

    # $@ and $* all positional parameters (both join with a space here).
    # Historically only $@ was substituted; $* fell through unexpanded and
    # printed literally.  Both now expand to the space-joined parameter
    # list held in %*.
    $str =~ s/\$\@/do { my $v=BATsh::Env->get('%*'); defined $v ? $v : '' }/ge;
    $str =~ s/\$\*/do { my $v=BATsh::Env->get('%*'); defined $v ? $v : '' }/ge;

    # $# number of positional parameters
    $str =~ s/\$#/
        do {
            my $c = 0;
            for my $nn (1..9) {
                my $vv = BATsh::Env->get("%$nn");
                $vv = BATsh::Env->get("BATSH_ARG$nn") unless defined $vv && $vv ne '';
                last unless defined $vv && $vv ne '';
                $c = $nn;
            }
            $c
        }
    /ge;

    # $VAR (array name yields element 0)
    $str =~ s/\$([A-Za-z_][A-Za-z0-9_]*)/
        do {
            my $n = $1;
            if (_arr_exists($n)) {
                my $v = _arr_get_element($n, 0); defined $v ? $v : ''
            }
            else {
                my $v = BATsh::Env->get($n);
                _nounset_hit($n) if !defined $v;
                defined $v ? $v : ''
            }
        }
    /ge;

    # Restore the escaped specials as literal characters (reverse order of
    # protection is not required, the sentinels are disjoint).
    $str =~ s/\x00BATSH_DL\x00/\$/g;
    $str =~ s/\x00BATSH_BT\x00/`/g;
    $str =~ s/\x00BATSH_BS\x00/\\/g;

    return $str;
}

# ----------------------------------------------------------------
# Arithmetic evaluator
# ----------------------------------------------------------------
use vars qw(@_A_TOK $_A_POS $_A_ERR);

sub _eval_arith {
    my ($expr) = @_;
    # Full shell-arithmetic evaluator (bash semantics, Perl 5.005_03 safe):
    #   , = += -= *= /= %= <<= >>= &= ^= |= ?: || && | ^ & == != < <= > >=
    #   << >> + - * / % ** (right assoc) unary ! ~ + - prefix/postfix ++ --
    # Comparisons and logical operators yield 1/0; / and % truncate toward
    # zero; assignments and ++/-- on a bare NAME write back to the variable
    # store.  $N and $NAME are resolved to their numeric values while
    # tokenizing; a bare NAME stays assignable.  Numbers may be decimal,
    # hex (0x..), or octal (0..).  On any syntax error or division by zero
    # a warning is printed and 0 is returned (matching the old behaviour
    # of returning 0 on an unsupported expression).
    local @_A_TOK = _arith_tokenize(defined $expr ? $expr : '');
    local $_A_POS = 0;
    local $_A_ERR = 0;
    my ($v) = _a_comma();
    $_A_ERR = 1 if !$_A_ERR && $_A_POS < scalar(@_A_TOK);   # trailing junk
    if ($_A_ERR) {
        warn "sh: arithmetic: syntax error or division by zero: $expr\n";
        return 0;
    }
    return int($v);
}

# Tokenize into [TYPE, VALUE] pairs: TYPE 'n' number, 'v' name, 'o' operator.
sub _arith_tokenize {
    my ($s) = @_;
    my @tok = ();
    my $i = 0;
    my $n = length($s);
    while ($i < $n) {
        my $c = substr($s, $i, 1);
        if ($c =~ /\s/) { $i++; next }
        # $N positional / $NAME -- resolve to a numeric value now
        if ($c eq '$') {
            if (substr($s, $i+1, 1) =~ /\A[1-9]\z/) {
                push @tok, ['n', _arith_pos(substr($s, $i+1, 1))];
                $i += 2; next;
            }
            if (substr($s, $i+1) =~ /\A([A-Za-z_][A-Za-z0-9_]*)/) {
                push @tok, ['n', _arith_var($1)];
                $i += 1 + length($1); next;
            }
            return (['o', '?ERR?']);   # lone $: force a syntax error
        }
        # Numbers: hex 0x.., octal 0.., decimal
        if ($c =~ /\d/) {
            if ($c eq '0' && substr($s, $i+1, 1) =~ /\A[xX]\z/
                && substr($s, $i+2) =~ /\A([0-9A-Fa-f]+)/) {
                push @tok, ['n', hex($1)];
                $i += 2 + length($1); next;
            }
            substr($s, $i) =~ /\A(\d+)/;
            my $num = $1;
            if ($num =~ /\A0[0-7]+\z/) { push @tok, ['n', oct($num)] }
            else                       { push @tok, ['n', int($num)] }
            $i += length($num); next;
        }
        # Bare NAME (assignable lvalue)
        if ($c =~ /[A-Za-z_]/) {
            substr($s, $i) =~ /\A([A-Za-z_][A-Za-z0-9_]*)/;
            push @tok, ['v', $1];
            $i += length($1); next;
        }
        # Operators: longest match first
        my $three = substr($s, $i, 3);
        if ($three eq '<<=' || $three eq '>>=') {
            push @tok, ['o', $three]; $i += 3; next;
        }
        my $two = substr($s, $i, 2);
        if ($two =~ /\A(?:\*\*|<<|>>|<=|>=|==|!=|&&|\|\||\+=|-=|\*=|\/=|%=|&=|\^=|\|=|\+\+|--)\z/) {
            push @tok, ['o', $two]; $i += 2; next;
        }
        if ($c =~ /\A[-+*\/%()<>=!&|^~?:,]\z/) {
            push @tok, ['o', $c]; $i++; next;
        }
        return (['o', '?ERR?']);   # unknown character: force a syntax error
    }
    return @tok;
}

sub _a_peek  { return $_A_POS < @_A_TOK ? $_A_TOK[$_A_POS] : undef }
sub _a_isop  {
    my ($op) = @_;
    my $t = _a_peek();
    return defined $t && $t->[0] eq 'o' && $t->[1] eq $op;
}
sub _a_next  { return $_A_TOK[$_A_POS++] }

# Each _a_* returns (value, lvalue_name_or_undef).

sub _a_comma {
    my ($v, $lv) = _a_assign();
    while (_a_isop(',')) {
        _a_next();
        ($v, $lv) = _a_assign();
    }
    return ($v, undef);
}

sub _a_assign {
    # Lookahead: NAME followed by an assignment operator
    my $t = _a_peek();
    if (defined $t && $t->[0] eq 'v' && $_A_POS + 1 < @_A_TOK) {
        my $op = $_A_TOK[$_A_POS + 1];
        if ($op->[0] eq 'o' && $op->[1] =~ /\A(?:=|\+=|-=|\*=|\/=|%=|<<=|>>=|&=|\^=|\|=)\z/) {
            my $name = $t->[1];
            _a_next(); _a_next();
            my ($rhs) = _a_assign();
            my $val;
            if ($op->[1] eq '=') { $val = $rhs }
            else {
                my $cur = _arith_var($name);
                my $o = $op->[1];
                if    ($o eq '+=')  { $val = $cur +  $rhs }
                elsif ($o eq '-=')  { $val = $cur -  $rhs }
                elsif ($o eq '*=')  { $val = $cur *  $rhs }
                elsif ($o eq '/=')  { if ($rhs == 0) { $_A_ERR = 1; return (0, undef) }
                                      $val = int($cur / $rhs) }
                elsif ($o eq '%=')  { if ($rhs == 0) { $_A_ERR = 1; return (0, undef) }
                                      $val = $cur %  $rhs }
                elsif ($o eq '<<=') { $val = $cur << $rhs }
                elsif ($o eq '>>=') { $val = $cur >> $rhs }
                elsif ($o eq '&=')  { $val = $cur &  $rhs }
                elsif ($o eq '^=')  { $val = $cur ^  $rhs }
                else                { $val = $cur |  $rhs }
            }
            $val = int($val);
            BATsh::Env->set($name, $val);
            return ($val, undef);
        }
    }
    return _a_ternary();
}

sub _a_ternary {
    my ($c) = _a_lor();
    if (_a_isop('?')) {
        _a_next();
        my ($tv) = _a_assign();
        if (!_a_isop(':')) { $_A_ERR = 1; return (0, undef) }
        _a_next();
        my ($fv) = _a_ternary();
        return (($c != 0) ? $tv : $fv, undef);
    }
    return ($c, undef);
}

sub _a_lor {
    my ($v) = _a_land();
    while (_a_isop('||')) {
        _a_next();
        my ($r) = _a_land();
        $v = (($v != 0) || ($r != 0)) ? 1 : 0;
    }
    return ($v, undef);
}

sub _a_land {
    my ($v) = _a_bor();
    while (_a_isop('&&')) {
        _a_next();
        my ($r) = _a_bor();
        $v = (($v != 0) && ($r != 0)) ? 1 : 0;
    }
    return ($v, undef);
}

sub _a_bor {
    my ($v) = _a_bxor();
    while (_a_isop('|')) {
        _a_next();
        my ($r) = _a_bxor();
        $v = $v | $r;
    }
    return ($v, undef);
}

sub _a_bxor {
    my ($v) = _a_band();
    while (_a_isop('^')) {
        _a_next();
        my ($r) = _a_band();
        $v = $v ^ $r;
    }
    return ($v, undef);
}

sub _a_band {
    my ($v) = _a_eqne();
    while (_a_isop('&')) {
        _a_next();
        my ($r) = _a_eqne();
        $v = $v & $r;
    }
    return ($v, undef);
}

sub _a_eqne {
    my ($v) = _a_rel();
    while (_a_isop('==') || _a_isop('!=')) {
        my $op = _a_next()->[1];
        my ($r) = _a_rel();
        $v = ($op eq '==') ? (($v == $r) ? 1 : 0) : (($v != $r) ? 1 : 0);
    }
    return ($v, undef);
}

sub _a_rel {
    my ($v) = _a_shiftop();
    while (_a_isop('<') || _a_isop('<=') || _a_isop('>') || _a_isop('>=')) {
        my $op = _a_next()->[1];
        my ($r) = _a_shiftop();
        if    ($op eq '<')  { $v = ($v <  $r) ? 1 : 0 }
        elsif ($op eq '<=') { $v = ($v <= $r) ? 1 : 0 }
        elsif ($op eq '>')  { $v = ($v >  $r) ? 1 : 0 }
        else                { $v = ($v >= $r) ? 1 : 0 }
    }
    return ($v, undef);
}

sub _a_shiftop {
    my ($v) = _a_add();
    while (_a_isop('<<') || _a_isop('>>')) {
        my $op = _a_next()->[1];
        my ($r) = _a_add();
        $v = ($op eq '<<') ? ($v << $r) : ($v >> $r);
    }
    return ($v, undef);
}

sub _a_add {
    my ($v) = _a_mul();
    while (_a_isop('+') || _a_isop('-')) {
        my $op = _a_next()->[1];
        my ($r) = _a_mul();
        $v = ($op eq '+') ? ($v + $r) : ($v - $r);
    }
    return ($v, undef);
}

sub _a_mul {
    my ($v) = _a_pow();
    while (_a_isop('*') || _a_isop('/') || _a_isop('%')) {
        my $op = _a_next()->[1];
        my ($r) = _a_pow();
        if ($op eq '*') { $v = $v * $r }
        else {
            if ($r == 0) { $_A_ERR = 1; return (0, undef) }
            # bash / and % truncate toward zero
            if ($op eq '/') {
                my $q = abs(int($v)) - (abs(int($v)) % abs(int($r)));
                $q /= abs(int($r));
                $q = -$q if (($v < 0) ne ($r < 0)) && $q != 0;
                $v = $q;
            }
            else {
                my $m = abs(int($v)) % abs(int($r));
                $m = -$m if $v < 0;
                $v = $m;
            }
        }
    }
    return ($v, undef);
}

sub _a_pow {
    my ($v, $lv) = _a_unary();
    if (_a_isop('**')) {
        _a_next();
        my ($r) = _a_pow();   # right associative
        return (int($v ** $r), undef);
    }
    return ($v, $lv);
}

sub _a_unary {
    if (_a_isop('!')) { _a_next(); my ($v) = _a_unary(); return (($v == 0) ? 1 : 0, undef) }
    if (_a_isop('~')) { _a_next(); my ($v) = _a_unary(); return (-int($v) - 1, undef) }
    if (_a_isop('+')) { _a_next(); my ($v) = _a_unary(); return (+$v, undef) }
    if (_a_isop('-')) { _a_next(); my ($v) = _a_unary(); return (-$v, undef) }
    # Prefix ++NAME / --NAME
    if (_a_isop('++') || _a_isop('--')) {
        my $op = _a_next()->[1];
        my $t = _a_peek();
        if (!defined $t || $t->[0] ne 'v') { $_A_ERR = 1; return (0, undef) }
        _a_next();
        my $val = _arith_var($t->[1]) + (($op eq '++') ? 1 : -1);
        BATsh::Env->set($t->[1], $val);
        return ($val, undef);
    }
    return _a_postfix();
}

sub _a_postfix {
    my ($v, $lv) = _a_primary();
    if (defined $lv && (_a_isop('++') || _a_isop('--'))) {
        my $op = _a_next()->[1];
        BATsh::Env->set($lv, $v + (($op eq '++') ? 1 : -1));
        return ($v, undef);   # postfix returns the OLD value
    }
    return ($v, $lv);
}

sub _a_primary {
    my $t = _a_peek();
    if (!defined $t) { $_A_ERR = 1; return (0, undef) }
    if ($t->[0] eq 'o' && $t->[1] eq '(') {
        _a_next();
        my ($v) = _a_comma();
        if (!_a_isop(')')) { $_A_ERR = 1; return (0, undef) }
        _a_next();
        return ($v, undef);
    }
    if ($t->[0] eq 'n') { _a_next(); return ($t->[1], undef) }
    if ($t->[0] eq 'v') { _a_next(); return (_arith_var($t->[1]), $t->[1]) }
    $_A_ERR = 1;
    return (0, undef);
}

sub _arith_pos {
    my ($n) = @_;
    my $v = BATsh::Env->get("%$n");
    $v = BATsh::Env->get("BATSH_ARG$n") unless defined $v && $v ne '';
    return (defined $v && $v =~ /\A-?\d+\z/) ? $v : 0;
}

sub _arith_var {
    my ($name) = @_;
    my $v = BATsh::Env->get($name);
    return (defined $v && $v =~ /\A-?\d+\z/) ? $v : 0;
}

# ----------------------------------------------------------------
# Command substitution $( cmd )
# ----------------------------------------------------------------
# _replace_cmd_subst: replace all $(...) in $str with their output.
# Unlike a simple [^)]* regex, this function tracks nesting depth
# and quoted strings so that $(cmd | perl -e "...)" works correctly.
# ----------------------------------------------------------------
sub _replace_cmd_subst {
    my ($class, $str) = @_;
    return '' unless defined $str;

    my $result = '';
    my @chars  = split //, $str;
    my $n      = scalar @chars;
    my $i      = 0;

    while ($i < $n) {
        my $ch = $chars[$i];

        # $( ... ) -- find matching close paren respecting nesting and quotes
        if ($ch eq '$' && $i+1 < $n && $chars[$i+1] eq '(') {
            $i += 2;   # skip $(
            my $depth  = 1;
            my $body   = '';
            my $in_sq  = 0;
            my $in_dq  = 0;

            while ($i < $n && $depth > 0) {
                my $c = $chars[$i];

                if ($in_sq) {
                    if ($c eq "'") { $in_sq = 0 }
                    $body .= $c; $i++; next;
                }
                if ($c eq "'" && !$in_dq) {
                    $in_sq = 1; $body .= $c; $i++; next;
                }
                if ($c eq '"' && !$in_sq) {
                    $in_dq = !$in_dq; $body .= $c; $i++; next;
                }
                if ($in_dq) {
                    if ($c eq '\\') {
                        $body .= $c; $i++;
                        $body .= $chars[$i] if $i < $n; $i++; next;
                    }
                    $body .= $c; $i++; next;
                }
                if ($c eq '\\') {
                    $body .= $c; $i++;
                    $body .= $chars[$i] if $i < $n; $i++; next;
                }
                if ($c eq '(') { $depth++; $body .= $c; $i++; next }
                if ($c eq ')') {
                    $depth--;
                    if ($depth == 0) { $i++; last }  # closing )
                    $body .= $c; $i++; next;
                }
                $body .= $c; $i++;
            }

            $result .= _cmd_subst($class, $body);
            next;
        }

        $result .= $ch; $i++;
    }

    return $result;
}

# ----------------------------------------------------------------
sub _cmd_subst {
    my ($class, $cmd_str) = @_;
    # Capture stdout via temporary file (Perl 5.005_03 compatible).
    # We use _run_lines so that all BATsh::SH builtins, functions,
    # and pipelines work recursively inside $(...) and `...`.
    # Tag the capture file with the active nesting depth so a nested
    # $( ... $( ... ) ) gets a distinct file per level (the inner level
    # must not truncate/unlink the file the outer level captures into).
    local $_SUBST_DEPTH = $_SUBST_DEPTH + 1;
    local *_SUBST_SAVOUT;
    open(_SUBST_SAVOUT, '>&STDOUT') or return '';
    local *_SUBST_CAPFH;
    my $tmpfile = _subst_tempfile();
    if (!defined $tmpfile) {
        open(STDOUT, '>&_SUBST_SAVOUT'); close(_SUBST_SAVOUT); return '';
    }
    open(STDOUT, '>&_SUBST_CAPFH')
        or do {
            close(_SUBST_CAPFH); unlink $tmpfile;
            open(STDOUT, '>&_SUBST_SAVOUT'); close(_SUBST_SAVOUT); return '';
        };
    close(_SUBST_CAPFH);
    eval {
        # Use _run_lines for full recursive BATsh::SH execution.
        # $cmd_str may contain pipes, builtins, functions, etc.
        my @sub_lines = split /\n/, $cmd_str;
        _run_lines($class, \@sub_lines, {});
    };
    open(STDOUT, '>&_SUBST_SAVOUT');
    close(_SUBST_SAVOUT);
    my $output = '';
    local *_SUBST_READFH;
    if (open(_SUBST_READFH, "< $tmpfile")) {
        local $/;
        $output = <_SUBST_READFH>;
        close(_SUBST_READFH);
    }
    unlink $tmpfile;
    @_SUBST_TMPFILES = grep { $_ ne $tmpfile } @_SUBST_TMPFILES;
    $output = '' unless defined $output;
    $output =~ s/\n+\z//;   # strip trailing newlines (like shell)
    return BATsh::MB::enc($output);
}

# _subst_tempfile: create a unique, empty temp file (O_CREAT|O_EXCL to
# avoid symlink races -- mirrors _bg_tempfile / _hd_tempfile) for capturing
# one command-substitution's stdout output, and open it as the package
# bareword filehandle _SUBST_CAPFH.  Returns the path, or undef on failure.
sub _subst_tempfile {
    my $dir = File::Spec->tmpdir();
    $dir = '.' if !(-d $dir && -w $dir);

    my $attempt = 0;
    while ($attempt < 1000) {
        $_SUBST_SEQ++;
        $attempt++;
        my $path = File::Spec->catfile($dir,
            'batsh_cap_' . $$ . '_' . $_SUBST_DEPTH . '_' . $_SUBST_SEQ . '.tmp');
        if (sysopen(_SUBST_CAPFH, $path, O_WRONLY | O_CREAT | O_EXCL, 0600)) {
            push @_SUBST_TMPFILES, $path;
            return $path;
        }
        # EEXIST or transient error: retry with next sequence number
    }
    return undef;
}

# ----------------------------------------------------------------
# Process substitution (v0.07): <(cmd) and >(cmd).
#
# This interpreter never forks (see the pipeline / background-job notes
# elsewhere in this file), so neither form uses a real named pipe.
# Instead:
#
#   <(cmd)   cmd's stdout is captured into a temp file (exactly like
#            $(cmd), but the file is kept instead of being read back
#            into a scalar) and <(cmd) is replaced by that file's path.
#            This covers the common case of feeding a whole command's
#            output to something that wants a filename, e.g.
#            "diff <(sort a) <(sort b)".
#
#   >(cmd)   an empty temp file is created and >(cmd) is replaced by its
#            path immediately; cmd itself is deferred and run with that
#            file as its stdin only after the current simple command
#            finishes (see the _exec_line wrapper), e.g.
#            "generate | tee >(gzip > out.gz)". Because cmd runs after
#            (not concurrently with) the writer, this is a best-effort
#            approximation of real, streaming >(...) and does not suit
#            writers that expect the reader to keep up in real time.
#
# Both temp files are removed by the _exec_line wrapper once the current
# simple command (and, for >(cmd), its deferred job) has finished; a
# process substitution used INSIDE another command substitution / loop
# condition is cleaned up at that inner level, not held open for the
# rest of the script.
# ----------------------------------------------------------------
sub _replace_process_subst {
    my ($class, $str) = @_;
    return $str unless defined $str && $str =~ /[<>]\(/;

    my $result = '';
    my @chars  = split //, $str;
    my $n      = scalar @chars;
    my $i      = 0;
    my $in_sq  = 0;
    my $in_dq  = 0;

    while ($i < $n) {
        my $ch = $chars[$i];

        if ($in_sq) {
            if ($ch eq "'") { $in_sq = 0 }
            $result .= $ch; $i++; next;
        }
        if ($ch eq "'" && !$in_dq) { $in_sq = 1; $result .= $ch; $i++; next }
        if ($ch eq '"' && !$in_sq) { $in_dq = !$in_dq; $result .= $ch; $i++; next }
        if (!$in_dq && $ch eq '\\') {
            $result .= $ch; $i++;
            $result .= $chars[$i] if $i < $n; $i++; next;
        }

        if (!$in_sq && !$in_dq && ($ch eq '<' || $ch eq '>')
                && $i+1 < $n && $chars[$i+1] eq '(') {
            my $dir   = $ch;
            my $depth = 1;
            my $j     = $i + 2;
            my $body  = '';
            while ($j < $n && $depth > 0) {
                my $c = $chars[$j];
                if    ($c eq '(') { $depth++; $body .= $c; $j++ }
                elsif ($c eq ')') { $depth--; $j++; $body .= $c if $depth > 0 }
                else               { $body .= $c; $j++ }
            }
            if ($depth != 0) { $result .= $ch; $i++; next }   # unterminated: literal '<'/'>'

            if ($dir eq '<') {
                # Quote the generated path: it is a literal filename that
                # must survive the dequoting applied later to redirection
                # targets and command words -- otherwise a Windows temp
                # path (C:\...\batsh_ps.tmp) would lose its backslashes,
                # or a space in the temp dir would split the word.
                $result .= '"' . _procsub_capture($class, $body) . '"';
            }
            else {
                my $tmp = _procsub_tempfile();
                if (defined $tmp) {
                    close(_PROCSUB_CAPFH);
                    push @_PROCSUB_DEFERRED, [$tmp, $body];
                    $result .= '"' . $tmp . '"';
                }
            }
            $i = $j; next;
        }

        $result .= $ch; $i++;
    }

    return $result;
}

# _procsub_capture: run $cmd_str now, capturing its stdout into a fresh
# temp file kept on disk, and return the file's path.  Mirrors
# _cmd_subst() but keeps the file instead of reading it back.
sub _procsub_capture {
    my ($class, $cmd_str) = @_;
    local *_PROCSUB_SAVOUT;
    open(_PROCSUB_SAVOUT, '>&STDOUT') or return '';
    my $tmpfile = _procsub_tempfile();
    if (!defined $tmpfile) {
        open(STDOUT, '>&_PROCSUB_SAVOUT'); close(_PROCSUB_SAVOUT); return '';
    }
    open(STDOUT, '>&_PROCSUB_CAPFH')
        or do {
            close(_PROCSUB_CAPFH); unlink $tmpfile;
            @_PROCSUB_TMPFILES = grep { $_ ne $tmpfile } @_PROCSUB_TMPFILES;
            open(STDOUT, '>&_PROCSUB_SAVOUT'); close(_PROCSUB_SAVOUT); return '';
        };
    close(_PROCSUB_CAPFH);
    eval {
        my @sub_lines = split /\n/, $cmd_str;
        _run_lines($class, \@sub_lines, {});
    };
    open(STDOUT, '>&_PROCSUB_SAVOUT');
    close(_PROCSUB_SAVOUT);
    return $tmpfile;
}

# _procsub_tempfile: create a unique, empty temp file (O_CREAT|O_EXCL to
# avoid symlink races, mirroring _subst_tempfile()) and open it as the
# package bareword filehandle _PROCSUB_CAPFH.  Returns the path, or
# undef on failure.  The path is tracked in @_PROCSUB_TMPFILES for the
# _exec_line wrapper (normal cleanup) and the END-block failsafe.
sub _procsub_tempfile {
    my $dir = File::Spec->tmpdir();
    $dir = '.' if !(-d $dir && -w $dir);

    my $attempt = 0;
    while ($attempt < 1000) {
        $_PROCSUB_SEQ++;
        $attempt++;
        my $path = File::Spec->catfile($dir,
            'batsh_ps_' . $$ . '_' . $_PROCSUB_SEQ . '.tmp');
        if (sysopen(_PROCSUB_CAPFH, $path, O_WRONLY | O_CREAT | O_EXCL, 0600)) {
            push @_PROCSUB_TMPFILES, $path;
            return $path;
        }
        # EEXIST or transient error: retry with next sequence number
    }
    return undef;
}

# ----------------------------------------------------------------
# export
# ----------------------------------------------------------------
sub _cmd_export {
    my ($rest) = @_;
    $rest =~ s/\A\s+//;
    # export -p: print all
    if ($rest =~ /\A-p\s*\z/) {
        for my $k (sort keys %BATsh::Env::STORE) {
            my $v = $BATsh::Env::STORE{$k};
            $v =~ s/'/'\\''/g;
            print "export $k='$v'\n";
        }
        return 0;
    }
    # export VAR=value or export VAR
    for my $item (split /\s+/, $rest) {
        if ($item =~ /\A([A-Za-z_][A-Za-z0-9_]*)=(.*)\z/s) {
            _sh_store_scalar($1, $2);
        }
        elsif ($item =~ /\A([A-Za-z_][A-Za-z0-9_]*)\z/) {
            # export existing variable (already in store; no-op)
        }
    }
    $LAST_STATUS = 0;
    return 0;
}

# ----------------------------------------------------------------
# unset
# ----------------------------------------------------------------
sub _cmd_unset {
    my ($rest) = @_;
    my $status = 0;
    for my $var (split /\s+/, $rest) {
        $var =~ s/\A\s+//; $var =~ s/\s+\z//;
        next if $var eq '';
        # A readonly variable / element cannot be unset (bash: status 1).
        if ($_SH_READONLY{ uc($var) }) {
            print STDERR "sh: unset: $var: cannot unset: readonly variable\n";
            $status = 1;
            next;
        }
        # unset NAME[SUB] -- remove a single array element
        if ($var =~ /\A([A-Za-z_][A-Za-z0-9_]*)\[([^\]]*)\]\z/) {
            my ($name, $sub) = ($1, $2);
            my $k = _arr_name($name);
            if (exists $_SH_ARRAY{$k}) {
                if ((defined $_SH_ARRAY_TYPE{$k} && $_SH_ARRAY_TYPE{$k} eq 'assoc')) {
                    delete $_SH_ARRAY{$k}{$sub};
                }
                else {
                    delete $_SH_ARRAY{$k}{ _arr_index($sub) };
                }
            }
            next;
        }
        # unset NAME -- remove a whole array (and any scalar of the same name)
        my $k = _arr_name($var);
        if (exists $_SH_ARRAY{$k}) {
            delete $_SH_ARRAY{$k};
            delete $_SH_ARRAY_TYPE{$k};
        }
        BATsh::Env->unset($var);
    }
    $LAST_STATUS = $status;
    return $status;
}

# ----------------------------------------------------------------
# echo
# ----------------------------------------------------------------
sub _cmd_echo {
    my ($rest) = @_;
    $rest =~ s/\A\s+//;
    my $no_newline = 0;
    if ($rest =~ s/\A-n\s*//) { $no_newline = 1 }
    # -e: enable escape sequences
    my $escape = 0;
    if ($rest =~ s/\A-e\s*//) { $escape = 1 }
    if ($escape) {
        $rest =~ s/\\n/\n/g;
        $rest =~ s/\\t/\t/g;
        $rest =~ s/\\r/\r/g;
        $rest =~ s/\\\\/\\/g;
    }
    # Remove shell quoting structurally so that quotes anywhere in the
    # argument list are dropped (e.g. echo "${arr[@]}" tail), not only when
    # the whole string is wrapped in one pair of quotes.
    $rest = _arr_dequote($rest);
    $rest = BATsh::MB::dec($rest);
    if ($no_newline) { print $rest }
    else             { print "$rest\n" }
    $LAST_STATUS = 0;
    return 0;
}

# ----------------------------------------------------------------
# printf
# ----------------------------------------------------------------
# A faithful pure-Perl printf: POSIX/bash format-string escapes, the full
# conversion set (%d %i %o %u %x %X %e %E %f %g %G %c %s %b %q %%), field
# width / precision including the dynamic "*" form, argument RECYCLING (the
# format is reused until the arguments are exhausted), the "%b" conversion
# (backslash escapes interpreted in the argument, with "\c" ending output),
# the "%q" conversion (shell-reusable quoting), and the "-v VAR" option
# (store the result in a shell variable instead of printing).  Perl 5.005_03
# safe: no lexical filehandles, no 3-argument open, no post-5.005 sprintf
# conversions (%a is deliberately not emitted).
sub _cmd_printf {
    my ($rest) = @_;
    $rest = '' unless defined $rest;

    my @tok = _arr_split_words($rest);

    # Options on the still-quoted tokens: -v VAR / -vVAR, and -- terminator.
    my $target;
    while (@tok) {
        my $t0 = $tok[0];
        if ($t0 eq '--') { shift @tok; last }
        if ($t0 eq '-v') {
            shift @tok;
            my $vn = @tok ? _arr_dequote(shift @tok) : '';
            $target = $vn if $vn ne '';
            next;
        }
        if ($t0 =~ /\A-v(.+)\z/s) {
            shift @tok;
            $target = _arr_dequote($1);
            next;
        }
        last;
    }
    if (!@tok) { $LAST_STATUS = 0; return 0 }

    my $fmt  = _arr_dequote(shift @tok);
    my @args = map { _arr_dequote($_) } @tok;
    $fmt  = BATsh::MB::dec($fmt);
    @args = map { BATsh::MB::dec($_) } @args;

    my ($fmt_x, $fmt_stop) = _printf_unescape($fmt, 1);
    my $out = _printf_format($fmt_x, $fmt_stop, @args);

    if (defined $target) {
        BATsh::Env->set($target, $out);
    }
    else {
        print $out;
    }
    $LAST_STATUS = 0;
    return 0;
}

# _printf_unescape(STR, ALLOW_C): interpret C/POSIX backslash escapes.
# Returns (RESULT, STOP) where STOP is true when a "\c" (only recognised
# when ALLOW_C is set) requested that output cease.  Unknown escapes keep
# their backslash, matching bash.
sub _printf_unescape {
    my ($s, $allow_c) = @_;
    $s = '' unless defined $s;
    my $out  = '';
    my $stop = 0;
    my $i    = 0;
    my $n    = length $s;
    while ($i < $n) {
        my $c = substr($s, $i, 1);
        if ($c ne '\\') { $out .= $c; $i++; next }
        my $d = substr($s, $i + 1, 1);
        if    ($d eq 'n')  { $out .= "\n";     $i += 2 }
        elsif ($d eq 't')  { $out .= "\t";     $i += 2 }
        elsif ($d eq 'r')  { $out .= "\r";     $i += 2 }
        elsif ($d eq '\\') { $out .= "\\";     $i += 2 }
        elsif ($d eq 'a')  { $out .= chr(7);   $i += 2 }
        elsif ($d eq 'b')  { $out .= chr(8);   $i += 2 }
        elsif ($d eq 'f')  { $out .= chr(12);  $i += 2 }
        elsif ($d eq 'v')  { $out .= chr(11);  $i += 2 }
        elsif ($d eq 'e' || $d eq 'E') { $out .= chr(27); $i += 2 }
        elsif ($d eq '"')  { $out .= '"';      $i += 2 }
        elsif ($d eq "'")  { $out .= "'";      $i += 2 }
        elsif ($d eq 'c' && $allow_c) { $stop = 1; last }
        elsif ($d eq 'x') {
            my $h = substr($s, $i + 2);
            if ($h =~ /\A([0-9A-Fa-f]{1,2})/) {
                $out .= chr(hex($1)); $i += 2 + length($1);
            }
            else { $out .= '\\x'; $i += 2 }
        }
        elsif ($d =~ /[0-7]/) {
            my $o = substr($s, $i + 1);
            if ($o =~ /\A(0?[0-7]{1,3})/) {
                $out .= chr(oct($1) & 0xFF); $i += 1 + length($1);
            }
            else { $out .= '\\'; $i++ }
        }
        elsif ($d eq '') { $out .= '\\'; $i++ }
        else             { $out .= '\\' . $d; $i += 2 }
    }
    return ($out, $stop);
}

# _printf_int(STR) / _printf_num(STR): coerce a printf argument to an
# integer / a number for a numeric conversion.  A leading ' or " selects
# the numeric value of the following character (POSIX); otherwise a leading
# numeric prefix (decimal, 0x hex, 0 octal) is used, and a non-numeric
# argument yields 0 (bash warns and uses 0; we stay quiet).
sub _printf_int {
    my ($s) = @_;
    $s = '' unless defined $s;
    if ($s =~ /\A['"](.)/s) { return ord($1) }
    if ($s =~ /\A\s*([-+]?)0[xX]([0-9A-Fa-f]+)/) {
        my $v = hex($2); return ($1 eq '-') ? -$v : $v;
    }
    if ($s =~ /\A\s*([-+]?)0([0-7]+)\z/) {
        my $v = oct($2); return ($1 eq '-') ? -$v : $v;
    }
    if ($s =~ /\A\s*([-+]?\d+)/) { return int($1) }
    return 0;
}

sub _printf_num {
    my ($s) = @_;
    $s = '' unless defined $s;
    if ($s =~ /\A['"](.)/s) { return ord($1) }
    if ($s =~ /\A\s*([-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?)/) { return $1 + 0 }
    if ($s =~ /\A\s*([-+]?)0[xX]([0-9A-Fa-f]+)/) {
        my $v = hex($2); return ($1 eq '-') ? -$v : $v;
    }
    return 0;
}

# _printf_shellquote(STR): the "%q" conversion -- quote STR so it reads back
# as a single shell word.  Safe characters are emitted bare; anything else
# is single-quoted with embedded single quotes rendered as '\''.
sub _printf_shellquote {
    my ($s) = @_;
    $s = '' unless defined $s;
    return "''" if $s eq '';
    return $s if $s =~ m{\A[-A-Za-z0-9_./:=@%+,]+\z};
    my $q = $s;
    $q =~ s/'/'\\''/g;
    return "'" . $q . "'";
}

# _sp(FMT, ARGS): sprintf with warnings suppressed (a non-numeric argument
# already coerced to 0, an over-wide field, etc. must not print to STDERR).
sub _sp {
    my ($f, @a) = @_;
    local $SIG{'__WARN__'} = sub { };
    return sprintf($f, @a);
}

# _printf_format(FMT, FMT_STOP, ARGS): apply the (already escape-expanded)
# format to the argument list, recycling the format until the arguments are
# exhausted (bash semantics), and stopping early if a "\c" was seen.
sub _printf_format {
    my ($fmt, $fmt_stop, @args) = @_;
    my $out   = '';
    my $ai    = 0;
    my $narg  = scalar @args;
    my $guard = 0;
    while (1) {
        $guard++;
        last if $guard > 100000;
        my $consumed = 0;
        my $stop     = 0;
        my $i        = 0;
        my $len      = length $fmt;
        while ($i < $len) {
            my $c = substr($fmt, $i, 1);
            if ($c ne '%') { $out .= $c; $i++; next }
            if (substr($fmt, $i + 1, 1) eq '%') { $out .= '%'; $i += 2; next }
            my $tail = substr($fmt, $i);
            if ($tail =~ /\A(%[-+ 0#]*(?:\*|\d+)?(?:\.(?:\*|\d+))?)([diouxXeEfgGcsbq])/) {
                my $spec = $1;
                my $conv = $2;
                $i += length($1) + length($2);

                while ($spec =~ /\*/) {
                    my $val = ($ai < $narg) ? _printf_int($args[$ai]) : 0;
                    if ($ai < $narg) { $ai++; $consumed++ }
                    $val = -$val if $val < 0;   # negative field width -> abs
                    $spec =~ s/\*/$val/;
                }

                my $have = ($ai < $narg);
                my $raw  = $have ? $args[$ai] : '';

                if ($conv eq 's') {
                    $out .= _sp($spec . 's', $raw);
                    if ($have) { $ai++; $consumed++ }
                }
                elsif ($conv eq 'b') {
                    my ($ex, $st) = _printf_unescape($raw, 1);
                    $out .= _sp($spec . 's', $ex);
                    if ($have) { $ai++; $consumed++ }
                    if ($st) { $stop = 1; last }
                }
                elsif ($conv eq 'q') {
                    $out .= _sp($spec . 's', _printf_shellquote($raw));
                    if ($have) { $ai++; $consumed++ }
                }
                elsif ($conv eq 'c') {
                    my $ch = length($raw) ? substr($raw, 0, 1) : '';
                    $out .= _sp($spec . 's', $ch);
                    if ($have) { $ai++; $consumed++ }
                }
                elsif ($conv =~ /[diouxX]/) {
                    $out .= _sp($spec . $conv, _printf_int($raw));
                    if ($have) { $ai++; $consumed++ }
                }
                else {
                    $out .= _sp($spec . $conv, _printf_num($raw));
                    if ($have) { $ai++; $consumed++ }
                }
            }
            else { $out .= '%'; $i++ }
        }
        last if $stop || $fmt_stop;
        last unless ($ai < $narg && $consumed > 0);
    }
    return $out;
}

# ----------------------------------------------------------------
# Tilde expansion (v0.07): ~/path and ~user/path.
#
# POSIX word-initial tilde expansion.  Only applied to a word that
# begins with an UNQUOTED ~ (callers are responsible for that check);
# the tilde-prefix itself is never subject to variable / command
# substitution.  Forms:
#   ~          -> $HOME
#   ~/rest     -> $HOME . '/rest'
#   ~user      -> user's home directory (getpwnam; Unix-like only)
#   ~user/rest -> that directory . '/rest'
# If the login name is unknown (or getpwnam is unavailable, as on
# Win32) the word is returned unchanged, matching bash's behaviour of
# leaving an unresolvable ~name literal.
# NOT implemented: colon-list tilde expansion in PATH-like assignments
# (bash also tilde-expands after ':' in PATH=~/a:~/b); documented as a
# limitation in the POD.
# ----------------------------------------------------------------
sub _tilde_expand {
    my ($word) = @_;
    return $word unless defined $word && $word =~ /\A~/;
    my ($tag, $rest) = ($word =~ /\A~([^\/]*)(.*)\z/s);
    $tag  = '' unless defined $tag;
    $rest = '' unless defined $rest;
    my $home;
    if ($tag eq '') {
        $home = $ENV{'HOME'};
        $home = BATsh::Env->get('HOME') unless defined $home && $home ne '';
    }
    elsif ($^O !~ /MSWin32/i) {
        my @pw = eval { getpwnam($tag) };
        $home = (!$@ && @pw) ? $pw[7] : undef;
    }
    return $word unless defined $home && $home ne '';
    return $home . $rest;
}

# _tilde_prepass: scan a RAW (not-yet-variable-expanded) string and
# expand every unquoted, word-initial "~..." run using _tilde_expand().
# A "word start" is: the very beginning of the string, any position
# right after unquoted whitespace, or (once, at the very beginning of
# the string only) the position right after the '=' of a leading
# NAME= assignment token -- matching bash's extra tilde-expansion spot
# for VAR=~/path.  Quoted text (single or double quotes) is copied
# through untouched and never considered a word start for tilde
# purposes.  Everything else in the string (variables, command
# substitution, arithmetic, ...) is left as-is for the rest of
# _expand() to process afterwards.
sub _tilde_prepass {
    my ($str) = @_;
    return $str unless defined $str && $str =~ /~/;

    my @chars = split //, $str;
    my $n     = scalar @chars;
    my $out   = '';
    my $i     = 0;

    # Leading NAME= assignment token: the char right after '=' is also
    # a valid tilde-expansion start, but only for this one leading token.
    if ($str =~ /\A([A-Za-z_][A-Za-z0-9_]*=)/) {
        my $prefix = $1;
        $out .= $prefix;
        $i = length($prefix);
    }

    my $at_word_start = 1;
    my $in_sq = 0;
    my $in_dq = 0;
    while ($i < $n) {
        my $c = $chars[$i];
        if ($in_sq) { $out .= $c; $in_sq = 0 if $c eq "'"; $i++; $at_word_start = 0; next }
        if ($in_dq) { $out .= $c; $in_dq = 0 if $c eq '"'; $i++; $at_word_start = 0; next }
        if ($c eq "'") { $in_sq = 1; $out .= $c; $i++; $at_word_start = 0; next }
        if ($c eq '"') { $in_dq = 1; $out .= $c; $i++; $at_word_start = 0; next }
        if ($c =~ /\s/) { $out .= $c; $i++; $at_word_start = 1; next }
        if ($at_word_start && $c eq '~') {
            my $j = $i + 1;
            my $tag = '';
            while ($j < $n && $chars[$j] !~ /[\s\/'"]/) { $tag .= $chars[$j]; $j++ }
            $out .= _tilde_expand('~' . $tag);
            $i = $j;
            $at_word_start = 0;
            next;
        }
        $out .= $c;
        $i++;
        $at_word_start = 0;
    }
    return $out;
}

# ----------------------------------------------------------------
# Brace expansion (v0.07): {a,b,c} and {1..5} / {a..e} [..step] word
# generation.  Runs on the RAW source line, lexically, before any other
# expansion -- exactly like the tilde prepass above.  Quoted text and
# anything that is opaque shell syntax (${...}, $(...), $((...)), `...`,
# <(...), >(...), and backslash-escaped characters) is protected behind
# a NUL-delimited sentinel so its content is copied through untouched
# and its internal whitespace never becomes a false word boundary.
# ----------------------------------------------------------------
sub _brace_expand_line {
    my ($line) = @_;
    return $line unless defined $line && $line =~ /\{/;

    my @protected;
    my $safe = '';
    my @c = split //, $line;
    my $n = scalar @c;
    my $i = 0;
    while ($i < $n) {
        my $ch = $c[$i];

        if ($ch eq '\\') {
            my $seg = $ch . (($i+1 < $n) ? $c[$i+1] : '');
            push @protected, $seg;
            $safe .= "\x00BR" . $#protected . "\x00";
            $i += 2; next;
        }
        if ($ch eq "'") {
            my $j = $i + 1;
            while ($j < $n && $c[$j] ne "'") { $j++ }
            $j++ if $j < $n;
            my $seg = join('', @c[$i .. $j-1]);
            push @protected, $seg;
            $safe .= "\x00BR" . $#protected . "\x00";
            $i = $j; next;
        }
        if ($ch eq '"') {
            my $j = $i + 1;
            while ($j < $n && $c[$j] ne '"') {
                $j += ($c[$j] eq '\\' && $j+1 < $n) ? 2 : 1;
            }
            $j++ if $j < $n;
            my $seg = join('', @c[$i .. $j-1]);
            push @protected, $seg;
            $safe .= "\x00BR" . $#protected . "\x00";
            $i = $j; next;
        }
        if ($ch eq '$' && $i+1 < $n && ($c[$i+1] eq '(' || $c[$i+1] eq '{')) {
            my $openc  = $c[$i+1];
            my $closec = ($openc eq '(') ? ')' : '}';
            my $depth  = 1;
            my $j      = $i + 2;
            while ($j < $n && $depth > 0) {
                if    ($c[$j] eq $openc)  { $depth++ }
                elsif ($c[$j] eq $closec) { $depth-- }
                $j++;
            }
            my $seg = join('', @c[$i .. $j-1]);
            push @protected, $seg;
            $safe .= "\x00BR" . $#protected . "\x00";
            $i = $j; next;
        }
        if (($ch eq '<' || $ch eq '>') && $i+1 < $n && $c[$i+1] eq '(') {
            my $depth = 1;
            my $j     = $i + 2;
            while ($j < $n && $depth > 0) {
                if    ($c[$j] eq '(') { $depth++ }
                elsif ($c[$j] eq ')') { $depth-- }
                $j++;
            }
            my $seg = join('', @c[$i .. $j-1]);
            push @protected, $seg;
            $safe .= "\x00BR" . $#protected . "\x00";
            $i = $j; next;
        }
        if ($ch eq '`') {
            my $j = $i + 1;
            while ($j < $n && $c[$j] ne '`') { $j++ }
            $j++ if $j < $n;
            my $seg = join('', @c[$i .. $j-1]);
            push @protected, $seg;
            $safe .= "\x00BR" . $#protected . "\x00";
            $i = $j; next;
        }

        $safe .= $ch; $i++;
    }

    my @pieces = split /(\s+)/, $safe;
    my $out = '';
    for my $w (@pieces) {
        if ($w eq '' || $w =~ /\A\s+\z/) { $out .= $w; next }
        my @exp = ($w =~ /\{/) ? _brace_expand_word($w) : ($w);
        $out .= join(' ', @exp);
    }

    $out =~ s/\x00BR(\d+)\x00/$protected[$1]/ge;
    return $out;
}

# _brace_expand_word: expand all brace groups in one already-protected
# word, returning the list of resulting words (a single-element list
# containing the word unchanged when it holds no valid brace group).
sub _brace_expand_word {
    my ($word) = @_;
    return ($word) unless defined $word && $word =~ /\{/;
    my @found = _brace_find_group($word, 0);
    return ($word) unless @found;
    my ($open, $close, $alts_ref) = @found;
    my $prefix = substr($word, 0, $open);
    my $suffix = substr($word, $close + 1);
    my @suffix_words = _brace_expand_word($suffix);
    my @out;
    for my $a (@{$alts_ref}) {
        for my $aw (_brace_expand_word($a)) {
            for my $sw (@suffix_words) {
                push @out, $prefix . $aw . $sw;
            }
        }
    }
    return @out;
}

# _brace_find_group: locate the first VALID brace group at or after
# $start (a comma-list or a range -- a bare "{word}" with neither is
# left as literal text and scanning continues past it).  Returns
# ($open_pos, $close_pos, \@alternatives) or () when none remain.
sub _brace_find_group {
    my ($word, $start) = @_;
    my @c = split //, $word;
    my $n = scalar @c;
    my $i = $start;
    while ($i < $n) {
        if ($c[$i] eq '\\') { $i += 2; next }
        if ($c[$i] ne '{')  { $i++; next }

        my $open   = $i;
        my $depth  = 1;
        my $j      = $i + 1;
        my @commas;
        while ($j < $n && $depth > 0) {
            if ($c[$j] eq '\\') { $j += 2; next }
            if ($c[$j] eq '{')  { $depth++; $j++; next }
            if ($c[$j] eq '}')  { $depth--; $j++; next }
            if ($c[$j] eq ',' && $depth == 1) { push @commas, $j }
            $j++;
        }
        if ($depth != 0) { $i = $open + 1; next }   # unmatched '{'

        my $close = $j - 1;
        my @alts;
        if (@commas) {
            my $prev = $open + 1;
            for my $pos (@commas) {
                push @alts, substr($word, $prev, $pos - $prev);
                $prev = $pos + 1;
            }
            push @alts, substr($word, $prev, $close - $prev);
        }
        else {
            @alts = _brace_expand_range(substr($word, $open + 1, $close - $open - 1));
        }
        return ($open, $close, \@alts) if @alts;
        $i = $open + 1;   # not a valid group: keep scanning past it
    }
    return ();
}

# _brace_expand_range: expand "X..Y" or "X..Y..STEP" -- integer (with
# optional zero-padding taken from the wider operand) or single-letter.
# Returns () when $inner is not a recognised range expression.
sub _brace_expand_range {
    my ($inner) = @_;
    $inner = '' unless defined $inner;

    if ($inner =~ /\A(-?\d+)\.\.(-?\d+)(?:\.\.(-?\d+))?\z/) {
        my ($from, $to, $step) = ($1, $2, $3);
        my $pad = 0;
        if ($from =~ /\A-?0\d/ || $to =~ /\A-?0\d/) {
            my $w1 = length($from); $w1-- if substr($from, 0, 1) eq '-';
            my $w2 = length($to);   $w2-- if substr($to, 0, 1)   eq '-';
            $pad = ($w1 > $w2) ? $w1 : $w2;
        }
        $step = 1 unless defined $step && $step != 0;
        $step = -$step if $step > 0 && $from > $to;
        $step = -$step if $step < 0 && $from < $to;
        my @out;
        if ($step > 0) { for (my $v=$from; $v<=$to; $v+=$step) { push @out, _brace_pad($v, $pad) } }
        else            { for (my $v=$from; $v>=$to; $v+=$step) { push @out, _brace_pad($v, $pad) } }
        return @out;
    }
    if ($inner =~ /\A([A-Za-z])\.\.([A-Za-z])(?:\.\.(-?\d+))?\z/) {
        my ($from, $to, $step) = ($1, $2, $3);
        $step = 1 unless defined $step && $step != 0;
        $step = abs($step);
        my ($fo, $to_o) = (ord($from), ord($to));
        my @out;
        if ($fo <= $to_o) { for (my $v=$fo; $v<=$to_o; $v+=$step) { push @out, chr($v) } }
        else               { for (my $v=$fo; $v>=$to_o; $v-=$step) { push @out, chr($v) } }
        return @out;
    }
    return ();
}

sub _brace_pad {
    my ($v, $pad) = @_;
    return $v unless $pad;
    my $neg = ($v < 0) ? 1 : 0;
    my $s = sprintf('%0' . $pad . 'd', $neg ? -$v : $v);
    return $neg ? "-$s" : $s;
}

# ----------------------------------------------------------------
# cd
# ----------------------------------------------------------------
sub _cmd_cd {
    my ($rest) = @_;
    $rest =~ s/\A\s+//;
    $rest =~ s/\s+\z//;
    # Strip quotes the same way command words are dequoted, so
    # cd "a b" / cd 'dir' / cd "$HOME/x" reach chdir() as a plain path.
    $rest = _arr_dequote($rest);
    $rest = BATsh::MB::dec($rest);
    if ($rest eq '') {
        $rest = $ENV{'HOME'} || BATsh::Env->get('HOME') || '.';
    }
    unless (chdir($rest)) {
        print STDERR "cd: $rest: No such file or directory\n";
        $LAST_STATUS = 1;
        return 1;
    }
    BATsh::Env->set('PWD', BATsh::MB::enc(Cwd::cwd()));
    $LAST_STATUS = 0;
    return 0;
}

# ----------------------------------------------------------------
# exit
# ----------------------------------------------------------------
sub _cmd_exit {
    my ($rest) = @_;
    $rest =~ s/\A\s+//;
    my $code = ($rest =~ /\A(\d+)/) ? int($1) : 0;
    # Run the EXIT trap (once) before exiting, while no exit is yet pending so
    # the trap body executes.  Delete it first to avoid re-entry / double-fire.
    if (exists $_SH_TRAP{'EXIT'}) {
        my $cmd = delete $_SH_TRAP{'EXIT'};
        if (defined $cmd && $cmd ne '') {
            eval { _run_lines('BATsh::SH', [$cmd], {}) };
        }
    }
    $_EXIT_CODE = $code;
    $LAST_STATUS = $code;
    return $code;
}

# ----------------------------------------------------------------
# exec (v0.07)
#
#   exec > file / exec 2>&1 / ...   apply redirection(s) permanently to
#                                    the current shell (no save/restore)
#   exec cmd args...                run cmd (with its own redirections,
#                                    if any) then terminate the whole
#                                    script with cmd's exit status
#
# There is no real fork/exec here (this interpreter is Pure Perl and
# never forks -- see the Background Execution / Compound Commands notes
# above); "replacing the shell" is approximated by ending the script
# immediately afterward, and redirections are applied by permanently
# reassigning the STDIN/STDOUT/STDERR bareword globs instead of the
# save-and-restore dance _sh_exec_with_redirs() uses for ordinary
# commands.
# ----------------------------------------------------------------
sub _cmd_exec {
    my ($class, $rest, $opts_ref) = @_;
    $rest = '' unless defined $rest;
    my ($clean, $redirs_ref) = _sh_strip_redirects($rest);

    for my $r (@{$redirs_ref}) {
        my ($fd, $append, $file) = @{$r};
        $file = BATsh::MB::dec($file) unless $file =~ /\A&[12]\z/;
        my $ok = 1;
        if ($fd == 0) {
            # sysopen() takes the filename literally -- a leading '>' or a
            # trailing '|' is never treated as a mode or a pipe command.
            $ok = sysopen(STDIN, $file, O_RDONLY);
        }
        elsif ($fd == 1) {
            $ok = ($file eq '&2')
                ? open(STDOUT, '>&STDERR')
                : sysopen(STDOUT, $file,
                    O_WRONLY | O_CREAT | ($append ? O_APPEND : O_TRUNC), 0666);
        }
        else {
            $ok = ($file eq '&1')
                ? open(STDERR, '>&STDOUT')
                : sysopen(STDERR, $file,
                    O_WRONLY | O_CREAT | ($append ? O_APPEND : O_TRUNC), 0666);
        }
        unless ($ok) {
            warn "sh: exec: $file: $!\n";
            $LAST_STATUS = 1;
            return 1;
        }
    }

    $clean =~ s/\A\s+//; $clean =~ s/\s+\z//;
    if ($clean eq '') {
        # "exec" with only redirections: they now apply for the rest of
        # the script; exec itself does not terminate anything.
        $LAST_STATUS = 0;
        return 0;
    }

    my $rc = _exec_line($class, $clean, $opts_ref);
    $_EXIT_CODE  = $rc;   # exec replaces the shell: end the script here
    $LAST_STATUS = $rc;
    return $rc;
}

# ----------------------------------------------------------------
# trap -- signal / event handling (v0.06)
#
# Supported forms:
#   trap 'commands' SIGSPEC...   register a handler
#   trap - SIGSPEC...            reset to the default action
#   trap '' SIGSPEC...           ignore the signal
#   trap            / trap -p    list the current traps
#
# SIGSPEC may be a name (with or without a leading SIG), a number, or the
# EXIT pseudo-signal (also spelled 0).  Real OS signals are bridged to
# Perl's %SIG; EXIT is run internally when the script ends or on `exit`.
# The handler command is stored unexpanded and (re-)expanded when it fires.
# ----------------------------------------------------------------
sub _cmd_trap {
    my ($class, $rest, $opts_ref) = @_;
    my ($mode, $cmd, $sigs) = _sh_parse_trap($rest);

    if ($mode eq 'list') {
        my @names = @{$sigs} ? @{$sigs} : sort keys %_SH_TRAP;
        for my $n (@names) {
            my $sig = _sh_normalize_sig($n);
            next unless exists $_SH_TRAP{$sig};
            print "trap -- '" . $_SH_TRAP{$sig} . "' $sig\n";
        }
        $LAST_STATUS = 0;
        return 0;
    }

    for my $spec (@{$sigs}) {
        my $sig = _sh_normalize_sig($spec);
        next if $sig eq '';
        if ($mode eq 'reset') {
            delete $_SH_TRAP{$sig};
            _sh_set_os_sig($sig, 'DEFAULT');
        }
        elsif ($mode eq 'ignore') {
            $_SH_TRAP{$sig} = '';
            _sh_set_os_sig($sig, 'IGNORE');
        }
        else {   # set
            $_SH_TRAP{$sig} = $cmd;
            _sh_set_os_sig($sig, 'HANDLER');
        }
    }
    $LAST_STATUS = 0;
    return 0;
}

# Parse the (raw) argument string of a trap command.
# Returns ($mode, $cmd, \@sigs) where $mode is 'list', 'reset', 'ignore'
# or 'set'.  For 'set', $cmd is the (still unexpanded) handler command.
sub _sh_parse_trap {
    my ($s) = @_;
    $s = '' unless defined $s;
    $s =~ s/\A\s+//; $s =~ s/\s+\z//;
    return ('list', undef, []) if $s eq '';

    if ($s =~ /\A-p\b\s*(.*)\z/s) {
        my @sigs = grep { length } split /\s+/, $1;
        return ('list', undef, \@sigs);
    }

    my ($action, $quoted, $rest);
    if ($s =~ /\A'([^']*)'\s*(.*)\z/s) {
        ($action, $quoted, $rest) = ($1, 1, $2);
    }
    elsif ($s =~ /\A"((?:[^"\\]|\\.)*)"\s*(.*)\z/s) {
        ($action, $quoted, $rest) = ($1, 1, $2);
    }
    else {
        ($action, $rest) = split /\s+/, $s, 2;
        $quoted = 0;
        $rest   = '' unless defined $rest;
    }
    my @sigs = grep { length } split /\s+/, $rest;

    return ('reset',  undef, \@sigs) if !$quoted && $action eq '-';
    return ('ignore', '',    \@sigs) if $quoted  && $action eq '';
    return ('set',    $action, \@sigs);
}

# Normalize a signal spec to a bare name: strip a leading SIG, uppercase,
# and map the common signal numbers to names.
sub _sh_normalize_sig {
    my ($s) = @_;
    return '' unless defined $s;
    $s =~ s/\A\s+//; $s =~ s/\s+\z//;
    return '' if $s eq '';
    $s = uc($s);
    $s =~ s/\ASIG//;
    if ($s =~ /\A\d+\z/) {
        my %num = (0 => 'EXIT', 1 => 'HUP', 2 => 'INT', 3 => 'QUIT',
                   6 => 'ABRT', 9 => 'KILL', 13 => 'PIPE', 14 => 'ALRM',
                   15 => 'TERM');
        $s = exists $num{$s + 0} ? $num{$s + 0} : $s;
    }
    return $s;
}

# Bridge a trap to Perl's %SIG.  Pseudo-signals (EXIT/ERR/DEBUG/RETURN) are
# handled internally and never touch %SIG.  Assignment is eval-guarded so an
# unsupported signal name (e.g. on Windows) degrades quietly.
sub _sh_set_os_sig {
    my ($sig, $what) = @_;
    return if $sig eq 'EXIT' || $sig eq 'ERR'
           || $sig eq 'DEBUG' || $sig eq 'RETURN';
    # Some signals (e.g. HUP/USR1/USR2) do not exist on every platform --
    # notably Windows -- where assigning to %SIG for them emits a harmless
    # "No such signal" warning.  Suppress just that warning so a portable
    # script trapping such a signal stays quiet; all other warnings pass
    # through, and the assignment itself still succeeds (best effort).
    local $SIG{__WARN__} = sub {
        my $w = defined $_[0] ? $_[0] : '';
        warn $w unless $w =~ /No such signal/;
    };
    eval {
        if    ($what eq 'DEFAULT') { $SIG{$sig} = 'DEFAULT' }
        elsif ($what eq 'IGNORE')  { $SIG{$sig} = 'IGNORE' }
        else                       { $SIG{$sig} = sub { _sh_run_trap($sig) } }
    };
    return;
}

# Run the handler command registered for $sig (no-op if unset or 'ignore').
sub _sh_run_trap {
    my ($sig) = @_;
    my $cmd = $_SH_TRAP{$sig};
    return unless defined $cmd && $cmd ne '';
    eval { _run_lines('BATsh::SH', [$cmd], {}) };
}

# Run the EXIT trap (if any) exactly once, then clear it.  Called by the
# top-level run paths in BATsh.pm when the whole script has finished.
sub fire_exit_trap {
    my ($class) = @_;
    return unless exists $_SH_TRAP{'EXIT'};
    my $cmd = delete $_SH_TRAP{'EXIT'};
    return if !defined $cmd || $cmd eq '';
    $_EXIT_CODE = undef;   # let the trap body run to completion
    eval { _run_lines('BATsh::SH', [$cmd], {}) };
    return;
}

# ----------------------------------------------------------------
# read
# ----------------------------------------------------------------
sub _cmd_read {
    my ($rest) = @_;
    $rest = '' unless defined $rest;
    $rest =~ s/\A\s+//;
    $rest =~ s/\s+\z//;

    # Drop option flags such as -r (we always read a raw line); only the
    # bareword names that follow are treated as target variables.
    my @vars = grep { length && !/\A-/ } split /\s+/, $rest;

    my $line = <STDIN>;
    $line = BATsh::MB::enc($line) if defined $line;
    if (!defined $line) {
        # End of input.  POSIX read returns non-zero at EOF so that a
        # 'while read VAR; do ...; done < file' loop terminates instead
        # of spinning forever.
        for my $v (@vars) { BATsh::Env->set($v, '') }
        $LAST_STATUS = 1;
        return 1;
    }
    chomp $line;

    if (@vars == 1) {
        BATsh::Env->set($vars[0], $line);
    }
    elsif (@vars > 1) {
        my @words = split /\s+/, $line, scalar(@vars);
        for my $i (0 .. $#vars) {
            BATsh::Env->set($vars[$i], defined($words[$i]) ? $words[$i] : '');
        }
    }
    $LAST_STATUS = 0;
    return 0;
}

# ----------------------------------------------------------------
# shift
# ----------------------------------------------------------------
sub _cmd_shift {
    my ($rest) = @_;
    $rest = '' unless defined $rest;
    $rest =~ s/\A\s+//;

    # Optional /N offset (bash: shift N shifts N positions)
    my $n_shift = 1;
    if ($rest =~ /\A(\d+)\s*\z/) { $n_shift = int($1); $n_shift = 1 if $n_shift < 1 }

    for my $step (1 .. $n_shift) {
        # Shift BATSH_ARG* (legacy)
        for my $n (1 .. 8) {
            my $next = BATsh::Env->get('BATSH_ARG' . ($n + 1));
            BATsh::Env->set('BATSH_ARG' . $n, defined($next) ? $next : '');
        }
        BATsh::Env->set('BATSH_ARG9', '');

        # Shift %1..%9 (used by _expand $1..$9)
        for my $n (1 .. 8) {
            my $next = BATsh::Env->get('%' . ($n + 1));
            BATsh::Env->set('%' . $n, defined($next) ? $next : '');
        }
        BATsh::Env->set('%9', '');

        # Rebuild %*
        my @args;
        for my $n (1 .. 9) {
            my $v = BATsh::Env->get("%$n");
            last unless defined $v && $v ne '';
            push @args, $v;
        }
        BATsh::Env->set('%*', join(' ', @args));
    }
    $LAST_STATUS = 0;
    return 0;
}

# ----------------------------------------------------------------
# getopts optstring name [arg ...]
# ----------------------------------------------------------------
# POSIX option parser.  Called once per option in a loop:
#
#   while getopts "ab:c" opt; do
#       case $opt in
#           a) ... ;;
#           b) echo "$OPTARG" ;;
#           c) ... ;;
#           \?) echo "bad option" >&2 ;;
#       esac
#   done
#   shift $((OPTIND - 1))
#
# Sets the variable named by the second argument to the option letter
# found (or '?' on an unknown option, or ':' on a missing argument when
# the optstring begins with ':').  OPTARG receives an option's argument;
# OPTIND advances to the next argument to be processed.  Returns 0 while
# an option was parsed, non-zero when the option list is exhausted.
#
# A leading ':' in optstring selects "silent" error reporting: getopts
# does not print a diagnostic, sets the name variable to ':' for a
# missing argument and '?' for an unknown option, and puts the offending
# letter in OPTARG.  Otherwise getopts prints a message to STDERR, sets
# the name variable to '?', and unsets OPTARG.
#
# If no [arg ...] words are given, the positional parameters $1..$9 are
# parsed (BATsh stores them as %1..%9; the same first-empty-terminates
# convention used elsewhere in this module applies, so an intentionally
# empty positional parameter is not representable).
#
# All Perl 5.005_03 compatible: substr/index scanning, no regex features
# beyond \A \z, no prototypes, 2-argument state via package variables.
sub _cmd_getopts {
    my ($rest) = @_;
    $rest = '' unless defined $rest;
    $rest =~ s/\A\s+//;
    $rest =~ s/\s+\z//;

    # Split off optstring and name; the remainder (if any) are explicit
    # args.  _parse_args handles quoting/word-splitting consistently with
    # the rest of the interpreter.
    my @words = _parse_args($rest);
    if (@words < 2) {
        print STDERR "getopts: usage: getopts optstring name [arg ...]\n";
        $LAST_STATUS = 2;
        return 2;
    }
    my $optstring = shift @words;
    my $name      = shift @words;

    # Argument list: explicit words, else the positional parameters.
    my @args;
    if (@words) {
        @args = @words;
    }
    else {
        for my $n (1 .. 9) {
            my $v = BATsh::Env->get("%$n");
            $v = BATsh::Env->get("BATSH_ARG$n") unless defined $v && $v ne '';
            last unless defined $v && $v ne '';
            push @args, $v;
        }
    }

    # Silent-error mode: a leading ':' in the optstring.
    my $silent = 0;
    if (index($optstring, ':') == 0) {
        $silent = 1;
        $optstring = substr($optstring, 1);
    }

    # OPTIND is 1-based and defaults to 1.  If the caller reset it (or it
    # has never been set), restart the intra-argument character offset.
    my $optind = BATsh::Env->get('OPTIND');
    $optind = 1 unless defined $optind && $optind =~ /\A\d+\z/ && $optind >= 1;
    if ($optind != $_GETOPTS_LAST_OPTIND) {
        $_GETOPTS_CHARPOS = 0;   # fresh loop, or manual OPTIND change
    }

    # End of arguments?
    if ($optind > scalar(@args)) {
        $_GETOPTS_CHARPOS = 0;
        BATsh::Env->set('OPTIND', $optind);
        $_GETOPTS_LAST_OPTIND = $optind;
        $LAST_STATUS = 1;
        return 1;
    }

    my $cur = $args[$optind - 1];
    $cur = '' unless defined $cur;

    # Starting a new argument: must begin with '-' and not be a bare '-'.
    if ($_GETOPTS_CHARPOS == 0) {
        if (index($cur, '-') != 0 || $cur eq '-') {
            # Not an option word: stop (leave OPTIND on it).
            BATsh::Env->set('OPTIND', $optind);
            $_GETOPTS_LAST_OPTIND = $optind;
            $LAST_STATUS = 1;
            return 1;
        }
        if ($cur eq '--') {
            # Explicit end of options: consume it and stop.
            $optind++;
            BATsh::Env->set('OPTIND', $optind);
            $_GETOPTS_LAST_OPTIND = $optind;
            $_GETOPTS_CHARPOS = 0;
            $LAST_STATUS = 1;
            return 1;
        }
        $_GETOPTS_CHARPOS = 1;   # skip the leading '-'
    }

    my $optchar = substr($cur, $_GETOPTS_CHARPOS, 1);
    $_GETOPTS_CHARPOS++;
    my $is_last_char = ($_GETOPTS_CHARPOS >= length($cur));

    # Advance OPTIND past $cur once its last option character is consumed.
    my $advance = sub {
        $optind++;
        $_GETOPTS_CHARPOS = 0;
    };

    # Look the option character up in the optstring.  ':' and '?' are
    # never valid option letters.
    my $pos = ($optchar eq ':' || $optchar eq '?') ? -1
            : index($optstring, $optchar);

    if ($pos < 0) {
        # Unknown option.
        if ($silent) {
            BATsh::Env->set($name, '?');
            BATsh::Env->set('OPTARG', $optchar);
        }
        else {
            print STDERR BATsh::MB::dec("getopts: illegal option -- $optchar") . "\n";
            BATsh::Env->set($name, '?');
            BATsh::Env->set('OPTARG', '');
        }
        $advance->() if $is_last_char;
        BATsh::Env->set('OPTIND', $optind);
        $_GETOPTS_LAST_OPTIND = $optind;
        $LAST_STATUS = 0;
        return 0;
    }

    # Does this option take an argument?  (a ':' follows it in optstring)
    my $needs_arg = (substr($optstring, $pos + 1, 1) eq ':');

    if ($needs_arg) {
        if (!$is_last_char) {
            # -oVALUE : remainder of the current word is the argument.
            BATsh::Env->set('OPTARG', substr($cur, $_GETOPTS_CHARPOS));
            BATsh::Env->set($name, $optchar);
            $advance->();
        }
        else {
            # -o VALUE : the next word is the argument.
            if ($optind + 1 > scalar(@args)) {
                # Missing argument.
                $advance->();
                if ($silent) {
                    BATsh::Env->set($name, ':');
                    BATsh::Env->set('OPTARG', $optchar);
                }
                else {
                    print STDERR BATsh::MB::dec("getopts: option requires an argument -- $optchar") . "\n";
                    BATsh::Env->set($name, '?');
                    BATsh::Env->set('OPTARG', '');
                }
                BATsh::Env->set('OPTIND', $optind);
                $_GETOPTS_LAST_OPTIND = $optind;
                $LAST_STATUS = 0;
                return 0;
            }
            BATsh::Env->set('OPTARG', $args[$optind]);   # 0-based next word
            BATsh::Env->set($name, $optchar);
            $optind += 2;
            $_GETOPTS_CHARPOS = 0;
        }
    }
    else {
        # Flag option, no argument.  bash unsets OPTARG; we clear it.
        BATsh::Env->set($name, $optchar);
        BATsh::Env->set('OPTARG', '');
        $advance->() if $is_last_char;
    }

    BATsh::Env->set('OPTIND', $optind);
    $_GETOPTS_LAST_OPTIND = $optind;
    $LAST_STATUS = 0;
    return 0;
}

# ----------------------------------------------------------------
# local
# ----------------------------------------------------------------
sub _cmd_local {
    my ($rest) = @_;
    $rest =~ s/\A\s+//;

    my ($var, $val);
    if ($rest =~ /\A([A-Za-z_][A-Za-z0-9_]*)=(.*)\z/s) {
        ($var, $val) = ($1, $2);
        # Strip surrounding quotes from value
        $val =~ s/\A"(.*)"\z/$1/s;
        $val =~ s/\A'(.*)'\z/$1/s;
    }
    elsif ($rest =~ /\A([A-Za-z_][A-Za-z0-9_]*)\s*\z/) {
        $var = $1;
        $val = BATsh::Env->get($var);
        $val = '' unless defined $val;
    }
    else {
        $LAST_STATUS = 0;
        return 0;
    }

    # Save old value in innermost function scope so it can be restored on return
    if (@FUNCTION_STACK) {
        my $frame = $FUNCTION_STACK[-1];
        # Only save once per variable per frame (first local declaration wins)
        unless (exists $frame->{$var}) {
            my $old = BATsh::Env->get($var);
            $frame->{$var} = defined $old ? $old : undef;
        }
    }
    BATsh::Env->set($var, $val);
    $LAST_STATUS = 0;
    return 0;
}

# ----------------------------------------------------------------
# set (sh set options -- minimal implementation)
# ----------------------------------------------------------------
sub _cmd_set_sh {
    my ($rest) = @_;
    $rest =~ s/\A\s+//;
    $rest =~ s/\s+\z//;
    # set -e/+e -u/+u -x/+x, combinable (-eux), and set -o/+o NAME
    # (errexit / nounset / xtrace).  Unknown letters and other forms are
    # accepted silently (set is also a noop for positional-parameter use).
    my @words = split /\s+/, $rest;
    while (@words) {
        my $w = shift @words;
        if ($w =~ /\A([-+])o\z/ && @words) {
            my $on = ($1 eq '-') ? 1 : 0;
            my $name = lc(shift @words);
            if    ($name eq 'errexit') { $_OPT_ERREXIT = $on }
            elsif ($name eq 'nounset') { $_OPT_NOUNSET = $on }
            elsif ($name eq 'xtrace')  { $_OPT_XTRACE  = $on }
            next;
        }
        if ($w =~ /\A([-+])([a-zA-Z]+)\z/) {
            my $on = ($1 eq '-') ? 1 : 0;
            for my $ch (split //, $2) {
                if    ($ch eq 'e') { $_OPT_ERREXIT = $on }
                elsif ($ch eq 'u') { $_OPT_NOUNSET = $on }
                elsif ($ch eq 'x') { $_OPT_XTRACE  = $on }
            }
            next;
        }
    }
    $LAST_STATUS = 0;
    return 0;
}

# ----------------------------------------------------------------
# shopt -- bash shell option toggle (v0.07, minimal implementation)
#
# Recognised forms:
#   shopt -s extglob     enable extended pattern matching operators
#                         ?(...) *(...) +(...) @(...) !(...) in case
#                         patterns and in ${VAR#pat}/${VAR%pat}/... patterns
#   shopt -u extglob      disable it (the bash default)
#   shopt -p extglob      print "shopt -s extglob" or "shopt -u extglob"
#   shopt extglob         print "extglob   on" / "extglob   off"
#   shopt                 print the state of all known options
#
# Only "extglob" is modelled; any other option name is accepted silently
# (queried as "off") so scripts that probe unrelated options do not abort.
# ----------------------------------------------------------------
sub _cmd_shopt {
    my ($rest) = @_;
    $rest =~ s/\A\s+//; $rest =~ s/\s+\z//;
    my @words = split /\s+/, $rest;
    if (!@words) {
        print "extglob        " . ($_OPT_EXTGLOB ? 'on' : 'off') . "\n";
        $LAST_STATUS = 0;
        return 0;
    }
    my $mode = '';   # '-s' / '-u' / '-p' / '' (bare query)
    if ($words[0] =~ /\A-[sup]\z/) { $mode = shift(@words) }
    if (!@words) {
        # "shopt -p" / "shopt -s" / "shopt -u" with no names: report/no-op
        if ($mode eq '-p') {
            print 'shopt -' . ($_OPT_EXTGLOB ? 's' : 'u') . " extglob\n";
        }
        $LAST_STATUS = 0;
        return 0;
    }
    my $status = 0;
    for my $name (@words) {
        my $lc_name = lc($name);
        if ($lc_name ne 'extglob') {
            # Unknown option name: treated as always-off, matching bash's
            # exit-status-1-on-unknown-name behaviour without aborting.
            if ($mode eq '') { print "$name           off\n" }
            $status = 1;
            next;
        }
        if    ($mode eq '-s') { $_OPT_EXTGLOB = 1 }
        elsif ($mode eq '-u') { $_OPT_EXTGLOB = 0 }
        elsif ($mode eq '-p') { print 'shopt -' . ($_OPT_EXTGLOB ? 's' : 'u') . " extglob\n" }
        else                  { print "extglob        " . ($_OPT_EXTGLOB ? 'on' : 'off') . "\n" }
    }
    $LAST_STATUS = $status;
    return $status;
}

# ----------------------------------------------------------------
# alias / unalias (v0.07, minimal implementation)
#
#   alias                    list all aliases as alias NAME='VALUE'
#   alias NAME               print one alias, or an error if not set
#   alias NAME=VALUE ...     define one or more aliases (quote-aware)
#   unalias NAME ...         remove one or more aliases
#   unalias -a               remove all aliases
# ----------------------------------------------------------------
sub _cmd_alias {
    my ($rest) = @_;
    $rest = '' unless defined $rest;
    $rest =~ s/\A\s+//; $rest =~ s/\s+\z//;
    if ($rest eq '') {
        for my $name (sort keys %_SH_ALIAS) {
            print "alias $name='" . $_SH_ALIAS{$name} . "'\n";
        }
        $LAST_STATUS = 0;
        return 0;
    }
    my @tok = _arr_split_words($rest);
    my $status = 0;
    for my $t (@tok) {
        if ($t =~ /\A([A-Za-z_][A-Za-z0-9_.:-]*)=(.*)\z/s) {
            my ($name, $val) = ($1, $2);
            $_SH_ALIAS{$name} = _arr_dequote($val);
        }
        elsif ($t =~ /\A([A-Za-z_][A-Za-z0-9_.:-]*)\z/) {
            my $name = $1;
            if (exists $_SH_ALIAS{$name}) {
                print "alias $name='" . $_SH_ALIAS{$name} . "'\n";
            }
            else {
                print STDERR "sh: alias: $name: not found\n";
                $status = 1;
            }
        }
    }
    $LAST_STATUS = $status;
    return $status;
}

sub _cmd_unalias {
    my ($rest) = @_;
    $rest = '' unless defined $rest;
    $rest =~ s/\A\s+//; $rest =~ s/\s+\z//;
    if ($rest eq '-a') { %_SH_ALIAS = (); $LAST_STATUS = 0; return 0 }
    my $status = 0;
    for my $name (split /\s+/, $rest) {
        next if $name eq '';
        if (exists $_SH_ALIAS{$name}) { delete $_SH_ALIAS{$name} }
        else { print STDERR "sh: unalias: $name: not found\n"; $status = 1 }
    }
    $LAST_STATUS = $status;
    return $status;
}

# _alias_expand_line: replace a leading alias name with its stored text.
# See the call site in _exec_line() for the chaining / loop-guard notes.
sub _alias_expand_line {
    my ($line) = @_;
    return $line unless %_SH_ALIAS;
    my %seen;
    my $out = $line;
    my $guard = 0;
    while ($guard < 20) {
        $guard++;
        last unless $out =~ /\A(\s*)(\S+)(.*)\z/s;
        my ($lead, $w0, $tail) = ($1, $2, $3);
        last unless exists $_SH_ALIAS{$w0};
        last if $seen{$w0};
        $seen{$w0} = 1;
        $out = $lead . $_SH_ALIAS{$w0} . $tail;
    }
    return $out;
}

# ----------------------------------------------------------------
# reset_sh_options: restore default shell options.  Called by BATsh.pm
# at the start of each top-level run so one script's "set -e" does not
# leak into the next.  Call as a plain function.
# ----------------------------------------------------------------
sub reset_sh_options {
    $_OPT_ERREXIT = 0;
    $_OPT_NOUNSET = 0;
    $_OPT_XTRACE  = 0;
    $_OPT_EXTGLOB = 0;
    $_ERREXIT_HOLD = 0;
    $_ERREXIT_DONE = 0;
    # getopts loop state (v0.07): a fresh top-level run restarts option
    # parsing from the first argument, so one script's half-finished
    # getopts loop cannot leak its position into the next run.
    $_GETOPTS_CHARPOS     = 0;
    $_GETOPTS_LAST_OPTIND = 0;
    # Variable attributes (v0.08) are script-scoped, like the options
    # above: a fresh top-level run starts with no readonly / integer
    # markings so one script's "readonly X" cannot leak into the next.
    %_SH_READONLY = ();
    %_SH_INTATTR  = ();
    return 0;
}

# ----------------------------------------------------------------
# _errexit_check: under set -e, a failing simple command terminates the
# script with its status.  Suppressed while $_ERREXIT_HOLD > 0 (an if/
# while/until condition, or a non-final member of a && / || list) and
# when a control transfer (exit/break/continue/return) is already active.
# ----------------------------------------------------------------
sub _errexit_check {
    my ($rc) = @_;
    return $rc unless $_OPT_ERREXIT;
    return $rc if $_ERREXIT_HOLD;
    return $rc unless defined $rc && $rc =~ /\A-?\d+\z/ && $rc != 0;
    return $rc if defined $_EXIT_CODE || $_BREAK || $_CONTINUE || $_RETURN;
    $_EXIT_CODE  = $rc;
    $LAST_STATUS = $rc;
    return $rc;
}

# ----------------------------------------------------------------
# _nounset_hit: under set -u, expanding an unset variable is an error
# that terminates the script with status 1 (bash prints the message and
# aborts; here the current command still completes with '' before the
# script stops -- see BUGS AND LIMITATIONS).  A noop while -u is off.
# ----------------------------------------------------------------
sub _nounset_hit {
    my ($name) = @_;
    return 0 unless $_OPT_NOUNSET;
    return 0 if defined $_EXIT_CODE;   # report only the first hit
    warn "sh: $name: unbound variable\n";
    $_EXIT_CODE  = 1;
    $LAST_STATUS = 1;
    return 1;
}

# ----------------------------------------------------------------
# source / .
# ----------------------------------------------------------------
sub _cmd_source {
    my ($class, $rest, $opts_ref) = @_;
    $rest =~ s/\A\s+//;
    $rest =~ s/\s+\z//;
    if (defined $opts_ref->{'_batsh'}) {
        eval { $opts_ref->{'_batsh'}->source_file($rest) };
        if ($@) { print STDERR "source: $rest: $@\n"; return 1 }
    }
    return 0;
}

# ----------------------------------------------------------------
# test / [ ]
# ----------------------------------------------------------------
sub _cmd_test {
    my ($rest) = @_;
    $rest =~ s/\A\s+//;
    $rest =~ s/\s*\]\s*\z//;   # strip trailing ]
    my $result = _eval_test($rest);
    $LAST_STATUS = $result ? 0 : 1;
    return $LAST_STATUS;
}

sub _eval_test {
    my ($expr) = @_;
    $expr =~ s/\A\s+//;
    $expr =~ s/\s+\z//;

    # Compound: -a (AND), -o (OR)
    if ($expr =~ /^(.*)\s+-a\s+(.*)$/) {
        return _eval_test($1) && _eval_test($2);
    }
    if ($expr =~ /^(.*)\s+-o\s+(.*)$/) {
        return _eval_test($1) || _eval_test($2);
    }
    # Negation
    if ($expr =~ /^!\s+(.*)$/) {
        return !_eval_test($1);
    }

    # File tests
    if ($expr =~ /\A(-[a-z])\s+(.+)\z/) {
        my ($op, $path) = ($1, $2);
        $path =~ s/\A"//; $path =~ s/"\z//;
        $path = BATsh::MB::dec($path);
        if ($op eq '-e') { return -e $path ? 1 : 0 }
        if ($op eq '-f') { return -f $path ? 1 : 0 }
        if ($op eq '-d') { return -d $path ? 1 : 0 }
        if ($op eq '-r') { return -r $path ? 1 : 0 }
        if ($op eq '-w') { return -w $path ? 1 : 0 }
        if ($op eq '-x') { return -x $path ? 1 : 0 }
        if ($op eq '-s') { return (-s $path) ? 1 : 0 }
        if ($op eq '-z') { my $s = -s $path; return (!defined $s || $s == 0) ? 1 : 0 }
        if ($op eq '-n') { return (length($path) > 0) ? 1 : 0 }
        if ($op eq '-L') { return -l $path ? 1 : 0 }
    }

    # String comparisons: = == != < >
    if ($expr =~ /\A(.+?)\s+(=|==|!=|<|>)\s+(.+)\z/) {
        my ($a, $op, $b) = ($1, $2, $3);
        $a =~ s/\A"//; $a =~ s/"\z//;
        $b =~ s/\A"//; $b =~ s/"\z//;
        if ($op eq '='  || $op eq '==') { return ($a eq $b) ? 1 : 0 }
        if ($op eq '!=') { return ($a ne $b) ? 1 : 0 }
        if ($op eq '<')  { return ($a lt $b) ? 1 : 0 }
        if ($op eq '>')  { return ($a gt $b) ? 1 : 0 }
    }

    # Integer comparisons: -eq -ne -lt -le -gt -ge
    if ($expr =~ /\A(.+?)\s+(-eq|-ne|-lt|-le|-gt|-ge)\s+(.+)\z/) {
        my ($a, $op, $b) = ($1, $2, $3);
        $a =~ s/\A"//; $a =~ s/"\z//;
        $b =~ s/\A"//; $b =~ s/"\z//;
        $a = int($a) if $a =~ /\A-?\d+\z/;
        $b = int($b) if $b =~ /\A-?\d+\z/;
        if ($op eq '-eq') { return ($a == $b) ? 1 : 0 }
        if ($op eq '-ne') { return ($a != $b) ? 1 : 0 }
        if ($op eq '-lt') { return ($a <  $b) ? 1 : 0 }
        if ($op eq '-le') { return ($a <= $b) ? 1 : 0 }
        if ($op eq '-gt') { return ($a >  $b) ? 1 : 0 }
        if ($op eq '-ge') { return ($a >= $b) ? 1 : 0 }
    }

    # -n string (non-empty)
    if ($expr =~ /\A-n\s+(.+)\z/) {
        my $s = $1; $s =~ s/\A"//; $s =~ s/"\z//;
        return length($s) > 0 ? 1 : 0;
    }
    # -z string (empty)
    if ($expr =~ /\A-z\s+(.+)\z/) {
        my $s = $1; $s =~ s/\A"//; $s =~ s/"\z//;
        return length($s) == 0 ? 1 : 0;
    }

    # bare string: true if non-empty
    $expr =~ s/\A"//; $expr =~ s/"\z//;
    return (length($expr) > 0 && $expr ne '0') ? 1 : 0;
}

# ----------------------------------------------------------------
# if/then/else/elif/fi parser
# ----------------------------------------------------------------
sub _parse_if {
    my ($class, $lines_ref, $start, $opts_ref) = @_;
    my @lines = @{$lines_ref};
    my $i = $start;

    # Collect: if cond; then ... [elif cond; then ...] [else ...] fi
    # Build a structure: [ ['cond_lines'], ['body_lines'] ] ...
    my @branches = ();   # [ [$cond_lines], [$body_lines] ]
    my $else_body = undef;

    # First line: if cond; then
    my $if_line = $lines[$i]; $i++;
    $if_line =~ s/\r?\n\z//; $if_line =~ s/\A\s+//;

    # Fully-inline form on ONE physical line:
    #   if COND; then BODY... [elif COND; then BODY...] [else BODY...]; fi
    # Detected by a bare "fi" appearing as a top-level ';' segment.  The
    # line is expanded into the logical-line shape the multi-line block
    # collector below already understands (with then/do/else peeled onto
    # their own lines), then re-parsed; this correctly handles elif and
    # else, which the previous narrow single-line regex silently dropped.
    if (_inline_has_terminator($if_line, 'fi')) {
        my @work = _inline_expand($if_line);
        my ($st) = _parse_if($class, \@work, 0, $opts_ref);
        return ($st, $i);
    }

    # Extract condition (after 'if', before 'then' or ';')
    my $cond_str = $if_line;
    $cond_str =~ s/\Aif\s+//i;

    $cond_str =~ s/\s*;\s*then\s*\z//i;
    $cond_str =~ s/\s+then\s*\z//i;

    my @cond_lines = ($cond_str);
    my @body_lines = ();
    my $in_else    = 0;   # collecting the else-branch body
    # Nested if/fi depth: a nested "if ... fi" inside a branch body (on
    # its own lines or written inline) must not have its "fi"/"elif"/
    # "else" mistaken for the outer if's.  Only the depth-1 keywords are
    # the outer if's; deeper ones travel with the body and are re-parsed
    # when the body runs.
    my $depth = 1;

    while ($i <= $#lines) {
        my $l = $lines[$i]; $i++;
        $l =~ s/\r?\n\z//;
        my $ls = $l; $ls =~ s/\A\s+//;
        my $lc_first = lc( ($ls =~ /\A(\S+)/) ? $1 : '' );

        if ($depth == 1 && $lc_first eq 'fi') {
            push @branches, [ [@cond_lines], [@body_lines] ] unless $in_else;
            $else_body = [@body_lines] if $in_else;
            last;
        }
        elsif ($depth == 1 && !$in_else && $lc_first eq 'elif') {
            push @branches, [ [@cond_lines], [@body_lines] ];
            $cond_str = $ls;
            $cond_str =~ s/\Aelif\s+//i;
            $cond_str =~ s/\s*;\s*then\s*\z//i;
            $cond_str =~ s/\s+then\s*\z//i;
            @cond_lines = ($cond_str);
            @body_lines = ();
        }
        elsif ($depth == 1 && !$in_else && $lc_first eq 'else') {
            push @branches, [ [@cond_lines], [@body_lines] ];
            @body_lines = ();
            $in_else = 1;
        }
        elsif ($depth == 1 && $lc_first eq 'then') {
            # 'then' on its own line: continue collecting body
            next;
        }
        else {
            push @body_lines, $l;
            $depth += _if_depth_delta($l);
        }
    }

    # Evaluate branches
    my $status = 0;
    my $executed = 0;
    for my $branch (@branches) {
        my ($cond_ref, $body_ref) = @{$branch};
        $_ERREXIT_HOLD++;
        my $cond_status = _run_lines($class, $cond_ref, $opts_ref);
        $_ERREXIT_HOLD--;
        if ($cond_status == 0) {
            $status = _run_lines($class, $body_ref, $opts_ref);
            $executed = 1;
            last;
        }
    }
    if (!$executed && defined $else_body) {
        $status = _run_lines($class, $else_body, $opts_ref);
    }

    return ($status, $i);
}

# ----------------------------------------------------------------
# for VAR in list; do ... done
# ----------------------------------------------------------------
sub _parse_for {
    my ($class, $lines_ref, $start, $opts_ref) = @_;
    my @lines = @{$lines_ref};
    my $i = $start;

    my $for_line = $lines[$i]; $i++;
    $for_line =~ s/\r?\n\z//; $for_line =~ s/\A\s+//;

    # for VAR in LIST [; do [BODY [; done]]]
    #
    # The header may stand alone (do/done on following lines) or carry an
    # inline "; do ... ; done" tail all on one physical line.  The inline
    # form is detected first; ";do" is matched with \b after "do" so that a
    # "; done" terminator is never mistaken for the "do" keyword.
    my ($var, $list_str) = ('', '');
    my $inline_body;          # defined when the header has an inline "do" tail
    my $inline_closed = 0;    # true when that tail also held the "done"
    if ($for_line =~ /\Afor\s+([A-Za-z_][A-Za-z0-9_]*)\s+in\s+(.*?)\s*;\s*do\b\s*(.*)\z/is) {
        my $tail;
        ($var, $list_str, $tail) = ($1, $2, $3);
        $tail =~ s/\s+\z//;
        if ($tail eq '') {
            $inline_body = undef;                  # "for ... ; do" -> body follows
        }
        elsif ($tail =~ /\A(.*);\s*done\b\s*\z/s) {
            $inline_body = $1; $inline_closed = 1; # fully inline; greedy = last done
        }
        elsif ($tail eq 'done') {
            $inline_body = ''; $inline_closed = 1; # empty inline body
        }
        else {
            $inline_body = $tail;                  # "for ... ; do BODY" (done later)
        }
    }
    elsif ($for_line =~ /\Afor\s+([A-Za-z_][A-Za-z0-9_]*)\s+in\s+(.*?)\s*\z/i) {
        ($var, $list_str) = ($1, $2);              # header only; do/done on later lines
    }

    # Collect body until 'done' (skipped when the tail already closed the loop)
    my @body = ();
    if (defined $inline_body) {
        push @body, $inline_body unless $inline_body eq '';
    }
    if (!$inline_closed) {
        my $depth = 1;
        while ($i <= $#lines) {
            my $l = $lines[$i]; $i++;
            $l =~ s/\r?\n\z//;
            my $ls = $l; $ls =~ s/\A\s+//;
            my $lc_f = lc( ($ls =~ /\A(\S+)/) ? $1 : '' );
            if ($lc_f eq 'for' || $lc_f eq 'while' || $lc_f eq 'until') { $depth++ }
            if ($lc_f eq 'done') { $depth--; last if $depth == 0 }
            push @body, $l unless ($lc_f eq 'do' && $depth == 1);
        }
    }

    # Expand list items.  _expand_word_list resolves variables and command
    # substitutions, applies filename globbing to unquoted glob words, and
    # expands a whole-word ${arr[@]} / ${arr[*]} reference (quoted or not) to
    # one item per array element.
    my @items = _expand_word_list($class, $list_str);
    my $status = 0;
    for my $val (@items) {
        BATsh::Env->set($var, $val);
        $_BREAK = 0; $_CONTINUE = 0;
        $status = _run_lines($class, \@body, $opts_ref);
        last if $_BREAK || defined $_EXIT_CODE;
    }
    $_BREAK = 0;

    return ($status, $i);
}

# ----------------------------------------------------------------
# select VAR in LIST ; do ... done  (v0.07)
#
# Prints a numbered menu of LIST (one item per line, to STDERR), prompts
# with $PS3 (default "#? "), and reads one line from STDIN into REPLY:
#   - a number in range 1..#items sets VAR to that item and runs BODY
#   - anything else (including a blank line) sets VAR to '' and still
#     runs BODY, matching bash (the menu is then reprinted next
#     iteration)
#   - end of input (STDIN closed) ends the loop, as does break
# There is no multi-column menu layout (bash chooses columns based on
# terminal width and item count); every item is printed on its own line.
# ----------------------------------------------------------------
sub _parse_select {
    my ($class, $lines_ref, $start, $opts_ref) = @_;
    my @lines = @{$lines_ref};
    my $i = $start;

    my $sel_line = $lines[$i]; $i++;
    $sel_line =~ s/\r?\n\z//; $sel_line =~ s/\A\s+//;

    my ($var, $list_str) = ('', '');
    my $inline_body;
    my $inline_closed = 0;
    if ($sel_line =~ /\Aselect\s+([A-Za-z_][A-Za-z0-9_]*)\s+in\s+(.*?)\s*;\s*do\b\s*(.*)\z/is) {
        my $tail;
        ($var, $list_str, $tail) = ($1, $2, $3);
        $tail =~ s/\s+\z//;
        if    ($tail eq '')     { $inline_body = undef }
        elsif ($tail =~ /\A(.*);\s*done\b\s*\z/s) { $inline_body = $1; $inline_closed = 1 }
        elsif ($tail eq 'done') { $inline_body = ''; $inline_closed = 1 }
        else                     { $inline_body = $tail }
    }
    elsif ($sel_line =~ /\Aselect\s+([A-Za-z_][A-Za-z0-9_]*)\s+in\s+(.*?)\s*\z/i) {
        ($var, $list_str) = ($1, $2);
    }
    elsif ($sel_line =~ /\Aselect\s+([A-Za-z_][A-Za-z0-9_]*)\s*\z/i) {
        ($var, $list_str) = ($1, '"$@"');   # "select VAR" alone: positional params
    }
    else {
        return (0, $i);   # malformed header: nothing to do
    }

    my @body = ();
    if (defined $inline_body) {
        push @body, $inline_body unless $inline_body eq '';
    }
    if (!$inline_closed) {
        my $depth = 1;
        while ($i <= $#lines) {
            my $l = $lines[$i]; $i++;
            $l =~ s/\r?\n\z//;
            my $ls = $l; $ls =~ s/\A\s+//;
            my $lc_f = lc( ($ls =~ /\A(\S+)/) ? $1 : '' );
            if ($lc_f eq 'for' || $lc_f eq 'while' || $lc_f eq 'until' || $lc_f eq 'select') { $depth++ }
            if ($lc_f eq 'done') { $depth--; last if $depth == 0 }
            push @body, $l unless ($lc_f eq 'do' && $depth == 1);
        }
    }

    my @items = _expand_word_list($class, $list_str);
    my $status = 0;
    return ($status, $i) unless @items;

    my $ps3 = BATsh::Env->get('PS3');
    $ps3 = '#? ' unless defined $ps3 && $ps3 ne '';

    my $max_iter = 100_000;   # safety guard, mirrors _parse_while
    while ($max_iter-- > 0) {
        last if defined $_EXIT_CODE;
        for my $idx (0 .. $#items) {
            print STDERR ($idx + 1) . ') ' . $items[$idx] . "\n";
        }
        print STDERR BATsh::MB::dec($ps3);
        my $answer = <STDIN>;
        last unless defined $answer;   # EOF on STDIN ends the loop
        $answer =~ s/\r?\n\z//;
        BATsh::Env->set('REPLY', BATsh::MB::enc($answer));
        if ($answer =~ /\A[0-9]+\z/ && $answer >= 1 && $answer <= scalar(@items)) {
            BATsh::Env->set($var, $items[$answer - 1]);
        }
        else {
            BATsh::Env->set($var, '');
        }
        $_BREAK = 0; $_CONTINUE = 0;
        $status = _run_lines($class, \@body, $opts_ref);
        last if $_BREAK || defined $_EXIT_CODE;
    }
    $_BREAK = 0;

    return ($status, $i);
}

# ----------------------------------------------------------------
# while/until condition; do ... done
# ----------------------------------------------------------------
sub _parse_while {
    my ($class, $lines_ref, $start, $opts_ref) = @_;
    my @lines = @{$lines_ref};
    my $i = $start;

    my $while_line = $lines[$i]; $i++;
    $while_line =~ s/\r?\n\z//; $while_line =~ s/\A\s+//;

    my $is_until = ($while_line =~ /\Auntil\s/i) ? 1 : 0;

    # Extract condition, supporting an inline "COND; do BODY; done [REDIR]" form
    # as well as the multi-line header.  As in _parse_for, ";do" is matched with
    # \b after "do" so that a "; done" terminator is never taken for "do".
    my $rest = $while_line;
    $rest =~ s/\A(?:while|until)\s+//i;

    my $cond_str;
    my @body          = ();
    my $done_line     = '';
    my $inline_body;
    my $inline_closed = 0;

    if ($rest =~ /\A(.*?)\s*;\s*do\b\s*(.*)\z/s) {
        my $tail;
        ($cond_str, $tail) = ($1, $2);
        $tail =~ s/\s+\z//;
        if ($tail eq '') {
            $inline_body = undef;                  # "while COND; do" -> body follows
        }
        elsif ($tail =~ /\A(.*);\s*done\b\s*(.*)\z/s) {
            $inline_body   = $1;                   # greedy = last "; done"
            $inline_closed = 1;
            my $dr = $2; $dr =~ s/\A\s+//; $dr =~ s/\s+\z//;
            $done_line = ($dr ne '') ? "done $dr" : 'done';
        }
        elsif ($tail =~ /\Adone\b\s*(.*)\z/s) {
            $inline_body   = '';                   # empty inline body
            $inline_closed = 1;
            my $dr = $1; $dr =~ s/\A\s+//; $dr =~ s/\s+\z//;
            $done_line = ($dr ne '') ? "done $dr" : 'done';
        }
        else {
            $inline_body = $tail;                  # done on following lines
        }
    }
    else {
        $cond_str = $rest;                         # header only; do/done on later lines
        $cond_str =~ s/\s*;\s*do\s*\z//i;
        $cond_str =~ s/\s+do\s*\z//i;
    }

    # Collect body (skipped when the inline tail already closed the loop)
    if (defined $inline_body) {
        push @body, $inline_body unless $inline_body eq '';
    }
    if (!$inline_closed) {
        my $depth = 1;
        while ($i <= $#lines) {
            my $l = $lines[$i]; $i++;
            $l =~ s/\r?\n\z//;
            my $ls = $l; $ls =~ s/\A\s+//;
            my $lc_f = lc( ($ls =~ /\A(\S+)/) ? $1 : '' );
            if ($lc_f eq 'for' || $lc_f eq 'while' || $lc_f eq 'until') { $depth++ }
            if ($lc_f eq 'done') { $depth--; if ($depth == 0) { $done_line = $ls; last } }
            push @body, $l unless ($lc_f eq 'do' && $depth == 1);
        }
    }

    # Honor an input redirection on the `done' line, e.g.
    #   while read LINE; do ...; done < FILE
    # by reopening STDIN from FILE for the duration of the loop so that the
    # loop's `read' built-in consumes the file.  Perl 5.005_03 compatible:
    # 2-argument open and bareword filehandle duplication.
    my $saved_in = 0;
    if ($done_line ne '') {
        my $done_rest = $done_line;
        $done_rest =~ s/\Adone\b\s*//i;
        if ($done_rest ne '') {
            my ($dc, $rd) = _sh_strip_redirects(_expand($class, $done_rest));
            my $in_file;
            for my $r (@{$rd}) {
                my ($fd, $append, $file) = @{$r};
                $in_file = $file if $fd == 0;
            }
            if (defined $in_file && $in_file ne '') {
                if (sysopen(_WH_REDIR_SRC, $in_file, O_RDONLY)) {
                    if (open(_WH_REDIR_SAVIN, '<&STDIN')) {
                        if (open(STDIN, '<&_WH_REDIR_SRC')) { $saved_in = 1 }
                    }
                    close(_WH_REDIR_SRC);
                }
                else {
                    warn "sh: $in_file: $!\n";
                }
            }
        }
    }

    my $status = 0;
    my $max_iter = 100_000;   # safety guard
    while ($max_iter-- > 0) {
        last if defined $_EXIT_CODE;
        $_ERREXIT_HOLD++;
        my $cond_status = _run_lines($class, [$cond_str], $opts_ref);
        $_ERREXIT_HOLD--;
        my $cond_true = ($cond_status == 0);
        last if $is_until  && $cond_true;
        last if !$is_until && !$cond_true;
        $_BREAK = 0; $_CONTINUE = 0;
        $status = _run_lines($class, \@body, $opts_ref);
        last if $_BREAK;
    }
    $_BREAK = 0;

    if ($saved_in) {
        open(STDIN, '<&_WH_REDIR_SAVIN');
        close(_WH_REDIR_SAVIN);
    }

    return ($status, $i);
}

# ----------------------------------------------------------------
# case $var in pattern) ... ;; esac
# ----------------------------------------------------------------
sub _parse_case {
    my ($class, $lines_ref, $start, $opts_ref) = @_;
    my @lines = @{$lines_ref};
    my $i = $start;

    my $case_line = $lines[$i]; $i++;
    $case_line =~ s/\r?\n\z//; $case_line =~ s/\A\s+//;

    # Header: case WORD in [inline clauses...]
    # The clauses (and even esac) may follow inline on the same physical line
    # -- e.g. "case $x in a) echo a ;; *) echo other ;; esac" -- or on the
    # following lines.  $inline_rest captures anything after "in".
    my $word        = '';
    my $inline_rest = '';
    if ($case_line =~ /\Acase\s+(.*?)\s+in\b\s*(.*)\z/is) {
        $word        = _arr_dequote(_expand($class, $1));
        $inline_rest = $2;
    }
    else {
        return (0, $i);   # malformed header: nothing to do
    }

    # Accumulate the clause region (everything between "in" and "esac"),
    # stopping as soon as the closing esac is seen.  esac is only recognised
    # at a clause boundary (start of region, after a ;;/;&/;;& terminator, or
    # at the start of a line), so the word "esac" appearing inside a body
    # (e.g. echo esac) does not end the construct prematurely.
    my $region = '';
    my $found  = 0;
    {
        my $pos = _case_top_esac_pos($inline_rest);
        if ($pos >= 0) { $region = substr($inline_rest, 0, $pos); $found = 1 }
        else           { $region = $inline_rest }
    }
    while (!$found && $i <= $#lines) {
        my $l = $lines[$i]; $i++;
        $l =~ s/\r?\n\z//;
        my $pos = _case_top_esac_pos($l);
        if ($pos >= 0) {
            $region .= "\n" . substr($l, 0, $pos);
            $found = 1;
            last;
        }
        $region .= "\n" . $l;
    }

    # Split the region into clauses, then evaluate with fall-through support:
    #   ;;   normal: stop after the first matching clause
    #   ;&   fall through: run the NEXT clause's body unconditionally
    #   ;;&  continue: keep testing the remaining clauses against the word
    my @clauses = _case_split_clauses($region);

    my $status = 0;
    my $stop   = 0;   # a ;; was reached after a match -- stop entirely
    my $fall   = 0;   # previous clause ended in ;& -- run this body no matter what
    for my $cl (@clauses) {
        last if $stop;
        my ($ctext, $term) = @{$cl};
        next unless $ctext =~ /\S/;

        my ($pattern_str, $body_text) = _case_parse_clause($ctext);
        next unless defined $pattern_str;   # not a pattern) clause -- skip

        my $run = 0;
        if ($fall) {
            $run  = 1;
            $fall = 0;
        }
        else {
            for my $pat (_case_split_patterns($pattern_str)) {
                $pat =~ s/\A\s+//; $pat =~ s/\s+\z//;
                next if $pat eq '';
                if (_match_pattern($word, $pat)) { $run = 1; last }
            }
        }

        if ($run) {
            my @body = split /\n/, $body_text;
            $status = _run_lines($class, \@body, $opts_ref);
            last if $_BREAK || $_CONTINUE || $_RETURN || defined $_EXIT_CODE;
            if    ($term eq ';;')  { $stop = 1 }
            elsif ($term eq ';&')  { $fall = 1 }   # next body unconditionally
            # ';;&' : neither stop nor fall -- keep testing later clauses
        }
    }

    return ($status, $i);
}

# ----------------------------------------------------------------
# ( commands )  --  subshell command group with isolated scope (v0.07)
#
# There is no real fork here (this interpreter never forks -- see the
# pipeline / background-job / exec notes elsewhere in this file), so
# isolation is approximated by snapshotting every piece of state a real
# subshell would not leak changes from -- variables, indexed/associative
# arrays, function definitions, aliases, and the working directory --
# running the body, and restoring all of it afterward regardless of how
# the body finished.  "exit" inside the group ends only the group (its
# status becomes the group's status); break/continue/return still
# propagate to an enclosing loop/function exactly as bash's ( ... ) does
# NOT contain them.
#
# Both the single-line form "( cmd1; cmd2 )" and the multi-line form
# (bare "(" ending the first line, matching bare ")" ending the last)
# are recognised.  A trailing ">" / ">>" / "<" redirection after the
# closing ")" is honoured; other trailing redirections (2>, 2>&1, ...)
# and a trailing "&" are not -- documented as known limitations.
# ----------------------------------------------------------------
sub _parse_subshell {
    my ($class, $lines_ref, $start, $opts_ref) = @_;
    my @lines = @{$lines_ref};
    my $i = $start;

    my $first_line = $lines[$i]; $i++;
    $first_line =~ s/\r?\n\z//;
    my $stripped = $first_line;
    $stripped =~ s/\A\s+//;

    my @body_lines;
    my $trailer = '';
    my $found_close = 0;

    # Try the single-line form first: a quote-aware paren-depth scan for
    # the ')' that matches this line's opening '('.
    {
        my @c = split //, $stripped;
        my $n = scalar @c;
        my $in_sq = 0;
        my $in_dq = 0;
        my $d = 0;
        my $close_pos;
        for (my $k = 0; $k < $n; $k++) {
            my $ch = $c[$k];
            if ($in_sq) { $in_sq = 0 if $ch eq "'"; next }
            if ($ch eq "'" && !$in_dq) { $in_sq = 1; next }
            if ($ch eq '"' && !$in_sq) { $in_dq = !$in_dq; next }
            next if $in_sq || $in_dq;
            if    ($ch eq '(') { $d++ }
            elsif ($ch eq ')') { $d--; if ($d == 0) { $close_pos = $k; last } }
        }
        if (defined $close_pos) {
            push @body_lines, substr($stripped, 1, $close_pos - 1);
            $trailer = substr($stripped, $close_pos + 1);
            $found_close = 1;
        }
    }

    if (!$found_close) {
        # Multi-line form: accumulate lines, counting '(' / ')' globally
        # per line (not quote-aware, matching the existing _parse_function
        # brace-counter's level of rigor) until the depth returns to 0.
        my $accum = substr($stripped, 1);
        my $opens  = () = ($accum =~ /\(/g);
        my $closes = () = ($accum =~ /\)/g);
        my $depth = 1 + $opens - $closes;
        push @body_lines, $accum if $accum =~ /\S/;
        if ($depth <= 0) {
            $found_close = 1;
            if (@body_lines && $body_lines[-1] =~ /\A(.*)\)([^)]*)\z/s) {
                $body_lines[-1] = $1;
                $trailer = $2;
            }
        }
        else {
            while ($i <= $#lines) {
                my $l = $lines[$i]; $i++;
                $l =~ s/\r?\n\z//;
                my $o = () = ($l =~ /\(/g);
                my $c2 = () = ($l =~ /\)/g);
                $depth += $o - $c2;
                if ($depth <= 0) {
                    if ($l =~ /\A(.*)\)([^)]*)\z/s) {
                        push @body_lines, $1 if $1 =~ /\S/;
                        $trailer = $2;
                    }
                    $found_close = 1;
                    last;
                }
                push @body_lines, $l;
            }
        }
    }

    my @body;
    for my $bl (@body_lines) {
        for my $part (split /;/, $bl) {
            push @body, $part if $part =~ /\S/;
        }
    }

    # Trailing "> file" / ">> file" / "< file" on the closing ')' line.
    $trailer =~ s/\A\s+//; $trailer =~ s/\s+\z//;
    my ($subsh_out_file, $subsh_out_append, $subsh_in_file);
    if ($trailer ne '') {
        my $texp = _expand($class, $trailer);
        # Reuse the main redirection parser so a quoted target ("a b",
        # ">name", "cmd|") is read and dequoted exactly as elsewhere.
        my (undef, $tr_redirs) = _sh_strip_redirects($texp);
        for my $r (@{$tr_redirs}) {
            my ($fd, $app, $file) = @{$r};
            next if $file =~ /\A&[12]\z/;   # dup forms handled in body
            if    ($fd == 0) { $subsh_in_file  = $file }
            elsif ($fd == 1) { $subsh_out_file = $file; $subsh_out_append = $app }
        }
    }

    my $saved_out = 0;
    my $saved_in  = 0;
    my $redir_failed = 0;
    if (defined $subsh_out_file) {
        if (sysopen(_SH_SUBSH_DST, BATsh::MB::dec($subsh_out_file),
                    O_WRONLY | O_CREAT | ($subsh_out_append ? O_APPEND : O_TRUNC),
                    0666)) {
            if (open(_SH_SUBSH_SAVOUT, '>&STDOUT')) {
                if (open(STDOUT, '>&_SH_SUBSH_DST')) { $saved_out = 1 }
            }
            close(_SH_SUBSH_DST);
        }
        else { warn "sh: $subsh_out_file: $!\n"; $redir_failed = 1 }
    }
    if (defined $subsh_in_file) {
        if (sysopen(_SH_SUBSH_SRC, BATsh::MB::dec($subsh_in_file), O_RDONLY)) {
            if (open(_SH_SUBSH_SAVIN, '<&STDIN')) {
                if (open(STDIN, '<&_SH_SUBSH_SRC')) { $saved_in = 1 }
            }
            close(_SH_SUBSH_SRC);
        }
        else { warn "sh: $subsh_in_file: $!\n"; $redir_failed = 1 }
    }

    # A failed redirection aborts the group without running its body -- as
    # the shell does for "( cat ) < missing": it reports the error and does
    # NOT fall through to read the terminal (which would hang).  Restore any
    # handle already swapped, then return failure.
    if ($redir_failed) {
        if ($saved_out) { open(STDOUT, '>&_SH_SUBSH_SAVOUT'); close(_SH_SUBSH_SAVOUT) }
        if ($saved_in)  { open(STDIN,  '<&_SH_SUBSH_SAVIN');  close(_SH_SUBSH_SAVIN)  }
        $LAST_STATUS = 1;
        return (1, $i);
    }

    # Snapshot everything the subshell must not leak changes to.
    my $env_snap    = BATsh::Env->snapshot();
    my %arr_snap    = %_SH_ARRAY;
    my %arrty_snap  = %_SH_ARRAY_TYPE;
    my %fn_snap     = %_SH_FUNCTIONS;
    my %alias_snap  = %_SH_ALIAS;
    my $cwd_snap    = defined(&Cwd::cwd) ? Cwd::cwd() : undef;

    $_BREAK = 0; $_CONTINUE = 0;
    my $status = _run_lines($class, \@body, $opts_ref);
    my $subshell_exit = $_EXIT_CODE;   # "exit" inside ( ... ) ends only the group
    $_EXIT_CODE = undef;
    $status = $subshell_exit if defined $subshell_exit;

    BATsh::Env->restore($env_snap);
    %_SH_ARRAY      = %arr_snap;
    %_SH_ARRAY_TYPE = %arrty_snap;
    %_SH_FUNCTIONS  = %fn_snap;
    %_SH_ALIAS      = %alias_snap;
    chdir($cwd_snap) if defined $cwd_snap && $cwd_snap ne '';

    if ($saved_out) { open(STDOUT, '>&_SH_SUBSH_SAVOUT'); close(_SH_SUBSH_SAVOUT) }
    if ($saved_in)  { open(STDIN,  '<&_SH_SUBSH_SAVIN');  close(_SH_SUBSH_SAVIN)  }

    $LAST_STATUS = $status;
    return ($status, $i);
}

# Locate a clause-boundary "esac" at the top level of $s (outside quotes).
# Returns its character offset, or -1.  An esac is only at a clause boundary
# when the preceding non-blank character is a ';', '&', or newline, or it is
# at the very start -- so "echo esac" inside a body does not match.
sub _case_top_esac_pos {
    my ($s) = @_;
    return -1 unless defined $s && $s ne '';
    my @c = split //, $s;
    my $n = scalar @c;
    my $i = 0; my $sq = 0; my $dq = 0;
    while ($i < $n) {
        my $ch = $c[$i];
        if ($sq) { $sq = 0 if $ch eq "'"; $i++; next }
        if ($ch eq "'" && !$dq) { $sq = 1; $i++; next }
        if ($ch eq '"') { $dq = !$dq; $i++; next }
        if (!$dq && lc(substr($s, $i, 4)) eq 'esac') {
            my $after = ($i + 4 < $n) ? substr($s, $i + 4, 1) : '';
            my $aok = ($i + 4 >= $n || $after =~ /\s/) ? 1 : 0;
            my $j = $i - 1;
            $j-- while $j >= 0 && ($c[$j] eq ' ' || $c[$j] eq "\t");
            my $bok = ($j < 0 || $c[$j] eq ';' || $c[$j] eq '&'
                       || $c[$j] eq "\n") ? 1 : 0;
            return $i if $aok && $bok;
        }
        $i++;
    }
    return -1;
}

# Split a case region into clauses on the terminators ;;& / ;; / ;& at the
# top level (outside quotes).  Returns a list of [clause_text, terminator].
sub _case_split_clauses {
    my ($s) = @_;
    my @out;
    my $cur = '';
    my @c   = split //, $s;
    my $n   = scalar @c;
    my $i = 0; my $sq = 0; my $dq = 0;
    while ($i < $n) {
        my $ch = $c[$i];
        if ($sq) { $cur .= $ch; $sq = 0 if $ch eq "'"; $i++; next }
        if ($ch eq "'" && !$dq) { $sq = 1; $cur .= $ch; $i++; next }
        if ($ch eq '"') { $dq = !$dq; $cur .= $ch; $i++; next }
        if (!$sq && !$dq) {
            if (substr($s, $i, 3) eq ';;&') {
                push @out, [$cur, ';;&']; $cur = ''; $i += 3; next;
            }
            if (substr($s, $i, 2) eq ';;') {
                push @out, [$cur, ';;'];  $cur = ''; $i += 2; next;
            }
            if (substr($s, $i, 2) eq ';&') {
                push @out, [$cur, ';&'];  $cur = ''; $i += 2; next;
            }
        }
        $cur .= $ch; $i++;
    }
    push @out, [$cur, ';;'] if $cur =~ /\S/;
    return @out;
}

# Parse a clause "pat1|pat2) body" into ($patterns, $body).  A leading "("
# is accepted (bash form).  The "(" closing the pattern list is the first
# top-level ")" outside quotes and outside a [...] class.  Returns
# (undef, undef) when no pattern ")" is present.
sub _case_parse_clause {
    my ($s) = @_;
    $s =~ s/\A[\s\n]+//;
    $s =~ s/\A\(//;   # optional leading (
    my @c = split //, $s;
    my $n = scalar @c;
    my $i = 0; my $sq = 0; my $dq = 0; my $cls = 0; my $paren = 0;
    my $found = -1;
    while ($i < $n) {
        my $ch = $c[$i];
        if ($sq) { $sq = 0 if $ch eq "'"; $i++; next }
        if ($ch eq "'" && !$dq) { $sq = 1; $i++; next }
        if ($ch eq '"') { $dq = !$dq; $i++; next }
        if (!$sq && !$dq) {
            if    ($ch eq '[') { $cls = 1 }
            elsif ($ch eq ']') { $cls = 0 }
            # An extglob group (?(...)/*(.../@(.../!(...)) contributes a
            # balanced '(' ... ')' pair inside the pattern text; only a
            # ')' at $paren == 0 is the clause terminator.  Tracked
            # unconditionally, harmless when there is no '(' present.
            elsif ($ch eq '(' && !$cls) { $paren++ }
            elsif ($ch eq ')' && !$cls) {
                if ($paren > 0) { $paren-- }
                else             { $found = $i; last }
            }
        }
        $i++;
    }
    return (undef, undef) if $found < 0;
    my $patterns = substr($s, 0, $found);
    my $body     = ($found + 1 <= length($s)) ? substr($s, $found + 1) : '';
    return ($patterns, $body);
}

# Split a pattern list on top-level "|" (outside quotes and [...] classes).
sub _case_split_patterns {
    my ($s) = @_;
    my @out;
    my $cur = '';
    my @c   = split //, $s;
    my $n   = scalar @c;
    my $i = 0; my $sq = 0; my $dq = 0; my $cls = 0; my $paren = 0;
    while ($i < $n) {
        my $ch = $c[$i];
        if ($sq) { $cur .= $ch; $sq = 0 if $ch eq "'"; $i++; next }
        if ($ch eq "'" && !$dq) { $sq = 1; $cur .= $ch; $i++; next }
        if ($ch eq '"') { $dq = !$dq; $cur .= $ch; $i++; next }
        if (!$sq && !$dq) {
            if    ($ch eq '[') { $cls = 1 }
            elsif ($ch eq ']') { $cls = 0 }
            # Parenthesis depth: keeps an extglob group's internal '|'
            # (e.g. @(abc|def)) from being mistaken for a pattern
            # separator.  Tracked unconditionally -- harmless when
            # extglob is off, since ordinary patterns rarely contain a
            # literal unescaped '('.
            elsif ($ch eq '(' && !$cls) { $paren++ }
            elsif ($ch eq ')' && !$cls && $paren > 0) { $paren-- }
            elsif ($ch eq '|' && !$cls && !$paren) { push @out, $cur; $cur = ''; $i++; next }
        }
        $cur .= $ch; $i++;
    }
    push @out, $cur;
    return @out;
}

# Match a shell-glob case pattern against a word.  Supports * ? and
# character classes [abc] [a-z] [!abc]/[^abc], plus quoting and backslash
# escapes (a quoted or escaped metacharacter is matched literally).
sub _match_pattern {
    my ($word, $pat) = @_;
    $word = '' unless defined $word;
    my $re = _case_glob_to_re($pat);
    return ($word =~ /\A$re\z/) ? 1 : 0;
}

sub _case_glob_to_re {
    my ($pat) = @_;
    $pat = '' unless defined $pat;
    my $re = '';
    my @c = split //, $pat;
    my $n = scalar @c;
    my $i = 0;
    while ($i < $n) {
        my $ch = $c[$i];
        if ($_OPT_EXTGLOB && $ch =~ /[?*+\@!]/ && $i+1 < $n && $c[$i+1] eq '(') {
            my @eg = _extglob_scan(\@c, $i, \&_case_glob_to_re);
            if (@eg) { $re .= $eg[1]; $i = $eg[0]; next }
        }
        if ($ch eq "'") {                       # literal single-quoted run
            $i++;
            while ($i < $n && $c[$i] ne "'") { $re .= quotemeta($c[$i]); $i++ }
            $i++; next;
        }
        if ($ch eq '"') {                       # literal double-quoted run
            $i++;
            while ($i < $n && $c[$i] ne '"') {
                if ($c[$i] eq '\\' && $i + 1 < $n) {
                    $i++; $re .= quotemeta($c[$i]); $i++; next;
                }
                $re .= quotemeta($c[$i]); $i++;
            }
            $i++; next;
        }
        if ($ch eq '\\') {                      # escaped literal
            $i++; $re .= quotemeta($c[$i]) if $i < $n; $i++; next;
        }
        if ($ch eq '*') { $re .= '.*'; $i++; next }
        if ($ch eq '?') { $re .= '.';  $i++; next }
        if ($ch eq '[') {                       # character class
            my $j   = $i + 1;
            my $neg = 0;
            if ($j < $n && ($c[$j] eq '!' || $c[$j] eq '^')) { $neg = 1; $j++ }
            my $body = '';
            if ($j < $n && $c[$j] eq ']') { $body .= '\\]'; $j++ }  # leading ] literal
            while ($j < $n && $c[$j] ne ']') {
                my $cc = $c[$j];
                if ($cc eq '\\' && $j + 1 < $n) {
                    $body .= '\\' . $c[$j + 1]; $j += 2; next;
                }
                if ($cc eq '\\' || $cc eq '^' || $cc eq ']') { $body .= '\\' . $cc }
                else                                         { $body .= $cc }
                $j++;
            }
            if ($j < $n && $c[$j] eq ']') {
                $re .= '[' . ($neg ? '^' : '') . $body . ']';
                $i = $j + 1; next;
            }
            $re .= '\\['; $i++; next;            # unterminated [ : literal
        }
        $re .= quotemeta($ch);
        $i++;
    }
    return $re;
}

# ----------------------------------------------------------------
# extglob (v0.07): ?(list) *(list) +(list) @(list) !(list) pattern-list
# operators, active only while "shopt -s extglob" is on.  Shared by
# _case_glob_to_re() (case patterns) and _glob_to_re() (${VAR%pat} and
# friends).  $convert_sub converts one pattern-list alternative (which
# may itself contain nested extglob groups) to a regex fragment.
#
# Returns ($pos_after_close_paren, $regex_fragment), or () when the
# text at $i is not a well-formed extglob group (extglob is then left
# to fall through to its ordinary, literal meaning for that character).
#
# !(list) is approximated as "any run of characters that never forms a
# complete match of one of the alternatives" via a negative lookahead
# repeated per character; this matches the common "exclude these whole
# patterns" usage (e.g. !(*.jpg|*.png)) but, unlike real extglob, is not
# exact when !(...) is combined with more pattern after it in the same
# glob -- documented as a known limitation.
# ----------------------------------------------------------------
sub _extglob_scan {
    my ($chars_ref, $i, $convert_sub) = @_;
    my @c = @{$chars_ref};
    my $n = scalar @c;
    return () unless $i+1 < $n && $c[$i+1] eq '(';
    my $op    = $c[$i];
    my $depth = 1;
    my $j     = $i + 2;
    my $body  = '';
    while ($j < $n && $depth > 0) {
        my $cc = $c[$j];
        if    ($cc eq '(') { $depth++; $body .= $cc; $j++ }
        elsif ($cc eq ')') { $depth--; $j++; $body .= $cc if $depth > 0 }
        elsif ($cc eq '\\' && $j+1 < $n) { $body .= $cc . $c[$j+1]; $j += 2 }
        else                { $body .= $cc; $j++ }
    }
    return () if $depth != 0;

    my @alts    = _extglob_split_alts($body);
    my @re_alts = map { $convert_sub->($_) } @alts;
    my $inner   = '(?:' . join('|', @re_alts) . ')';
    my $frag;
    if    ($op eq '?') { $frag = $inner . '?' }
    elsif ($op eq '*') { $frag = $inner . '*' }
    elsif ($op eq '+') { $frag = $inner . '+' }
    elsif ($op eq '@') { $frag = $inner }
    elsif ($op eq '!') { $frag = '(?:(?!' . $inner . ').)*' }
    else                { return () }
    return ($j, $frag);
}

# _extglob_split_alts: split an extglob pattern-list body on top-level
# '|' (respecting nested parens and backslash escapes).
sub _extglob_split_alts {
    my ($body) = @_;
    my @out;
    my $cur   = '';
    my @c     = split //, $body;
    my $n     = scalar @c;
    my $i     = 0;
    my $depth = 0;
    while ($i < $n) {
        my $ch = $c[$i];
        if ($ch eq '\\' && $i+1 < $n) { $cur .= $ch . $c[$i+1]; $i += 2; next }
        if ($ch eq '(') { $depth++; $cur .= $ch; $i++; next }
        if ($ch eq ')') { $depth--; $cur .= $ch; $i++; next }
        if ($ch eq '|' && $depth == 0) { push @out, $cur; $cur = ''; $i++; next }
        $cur .= $ch; $i++;
    }
    push @out, $cur;
    return @out;
}

# ----------------------------------------------------------------
# External command
# ----------------------------------------------------------------
# ----------------------------------------------------------------
# _split_sh_pipe: split a SH command line on bare | characters,
# respecting single-quoted, double-quoted, and $(...) regions.
# Returns a list of segment strings; length 1 means no pipe found.
# ----------------------------------------------------------------
# _split_sh_compound: split a SH line on bare && / || / ;
# Returns list of { op => '', cmd => '...' } hashrefs.
# Length 1 means no compound operator found.
# Respects single-quotes, double-quotes, and $(...) nesting.
# ----------------------------------------------------------------
# _sh_strip_redirects: parse SH-style redirections from a command line.
#
# Recognized forms (processed right-to-left, last one wins per fd):
#   cmd > file       stdout overwrite
#   cmd >> file      stdout append
#   cmd < file       stdin
#   cmd 2> file      stderr overwrite
#   cmd 2>> file     stderr append
#   cmd 2>&1         stderr to stdout (recorded as fd=2, file='&1')
#   cmd 1>&2         stdout to stderr (recorded as fd=1, file='&2')
#
# Returns ($clean_cmd, \@redirs) where each redir is [fd, append, file].
# Parsing respects single-quotes, double-quotes, and backslash escapes.
# ----------------------------------------------------------------
# ----------------------------------------------------------------
# _sh_strip_herestring: detect an unquoted "<<< word" (here-string) on
# an already variable-expanded line.  Returns ($line_without_it,
# $dequoted_word) when found, or ($line, undef) otherwise.  Only the
# first occurrence on the line is honoured (one here-string per
# command, matching the existing single-here-document limitation).
# ----------------------------------------------------------------
sub _sh_strip_herestring {
    my ($line) = @_;
    my @c = split //, $line;
    my $n = scalar @c;
    my $in_sq = 0;
    my $in_dq = 0;
    my $i = 0;
    while ($i < $n) {
        my $ch = $c[$i];
        if ($in_sq) { $in_sq = 0 if $ch eq "'"; $i++; next }
        if ($ch eq "'" && !$in_dq) { $in_sq = 1; $i++; next }
        if ($ch eq '"' && !$in_sq) { $in_dq = !$in_dq; $i++; next }
        if (!$in_sq && !$in_dq && $ch eq '\\') { $i += 2; next }
        if (!$in_sq && !$in_dq && $ch eq '<' && $i+2 < $n
                && $c[$i+1] eq '<' && $c[$i+2] eq '<'
                && !($i+3 < $n && $c[$i+3] eq '<')) {
            my $before = join('', @c[0 .. $i-1]);
            my $j = $i + 3;
            $j++ while $j < $n && ($c[$j] eq ' ' || $c[$j] eq "\t");
            my $wsq = 0;
            my $wdq = 0;
            my $word = '';
            while ($j < $n) {
                my $cc = $c[$j];
                if ($wsq) { $word .= $cc; $wsq = 0 if $cc eq "'"; $j++; next }
                if ($cc eq "'" && !$wdq) { $wsq = 1; $word .= $cc; $j++; next }
                if ($cc eq '"' && !$wsq) { $wdq = !$wdq; $word .= $cc; $j++; next }
                last if !$wsq && !$wdq && $cc =~ /\s/;
                $word .= $cc; $j++;
            }
            my $after = join('', @c[$j .. $n-1]);
            return ($before . $after, _arr_dequote($word));
        }
        $i++;
    }
    return ($line, undef);
}

# _read_redir_word: read a redirection target starting at index $start,
# honouring '...' and "..." quoting and backslash escapes so that a
# quoted space stays part of the single filename.  Stops at the first
# UNQUOTED whitespace or '<'/'>'.  Returns ($raw, $next_index); $raw
# still carries its quote characters -- pass it through _arr_dequote()
# before use.  Perl 5.005_03 compatible (index-based scan, no regex on
# the whole word, no prototypes).
sub _read_redir_word {
    my ($chars, $start, $n) = @_;
    my $raw = '';
    my $j   = $start;
    my $sq  = 0;
    my $dq  = 0;
    while ($j < $n) {
        my $c = $chars->[$j];
        if ($sq) {
            $raw .= $c;
            $sq = 0 if $c eq "'";
            $j++; next;
        }
        if ($c eq "'" && !$dq) { $sq = 1; $raw .= $c; $j++; next }
        if ($c eq '"' && !$sq) { $dq = !$dq; $raw .= $c; $j++; next }
        if ($c eq "\\" && !$sq) {
            $raw .= $c; $j++;
            $raw .= $chars->[$j] if $j < $n;
            $j++; next;
        }
        last if !$dq && $c =~ /[\s<>]/;
        $raw .= $c; $j++;
    }
    return ($raw, $j);
}

sub _sh_strip_redirects {
    my ($line) = @_;
    my @chars  = split //, $line;
    my $n      = scalar @chars;
    my @found;
    my $clean  = '';
    my $in_sq  = 0;
    my $in_dq  = 0;
    my $i      = 0;

    while ($i < $n) {
        my $ch = $chars[$i];

        # Single-quote passthrough
        if ($in_sq) {
            if ($ch eq "'") { $in_sq = 0 }
            $clean .= $ch; $i++; next;
        }
        if ($ch eq "'" && !$in_dq) { $in_sq = 1; $clean .= $ch; $i++; next }

        # Double-quote toggle
        if ($ch eq '"' && !$in_sq) { $in_dq = !$in_dq; $clean .= $ch; $i++; next }

        # Inside double-quotes: only escape matters
        if ($in_dq) {
            if ($ch eq '\\') {
                $clean .= $ch; $i++;
                $clean .= $chars[$i] if $i < $n; $i++; next;
            }
            $clean .= $ch; $i++; next;
        }

        # Backslash escape outside quotes
        if ($ch eq '\\') {
            $clean .= $ch; $i++;
            $clean .= $chars[$i] if $i < $n; $i++; next;
        }

        # 2>&1 or 2>>&1 or 1>&2
        if ($ch =~ /[012]/ && $i+2 < $n
                && $chars[$i+1] eq '>'
                && ($i+3 < $n ? $chars[$i+2] eq '>' : 0)
                && $chars[$i+3] eq '&') {
            # 2>>&1 form (rare but handle)
            my $fd  = int($ch);
            my $j   = $i + 4;
            my $tgt = '';
            while ($j < $n && $chars[$j] =~ /\S/) { $tgt .= $chars[$j]; $j++ }
            push @found, [$fd, 0, "&$tgt"];
            $i = $j; next;
        }
        if ($ch =~ /[012]/ && $i+2 < $n
                && $chars[$i+1] eq '>' && $chars[$i+2] eq '&') {
            my $fd  = int($ch);
            my $j   = $i + 3;
            my $tgt = '';
            while ($j < $n && $chars[$j] =~ /\S/) { $tgt .= $chars[$j]; $j++ }
            push @found, [$fd, 0, "&$tgt"];
            $i = $j; next;
        }

        # fd> or fd>> (fd is 0,1,2; or implicit 1 when just > or >>)
        my $redir_fd = undef;
        if ($ch =~ /[012]/ && $i+1 < $n && $chars[$i+1] eq '>') {
            $redir_fd = int($ch); $i++;
        }
        elsif ($ch eq '<') {
            # < file  (stdin)
            my $j = $i + 1;
            $j++ while $j < $n && $chars[$j] eq ' ';
            my ($raw, $nj) = _read_redir_word(\@chars, $j, $n);
            push @found, [0, 0, _arr_dequote($raw)] if $raw ne '';
            $i = $nj; next;
        }
        elsif ($ch eq '>') {
            $redir_fd = 1;
        }

        if (defined $redir_fd) {
            # Check for >>
            my $append = 0;
            if ($i+1 < $n && $chars[$i+1] eq '>') { $append = 1; $i++ }
            # Skip spaces
            $i++;
            $i++ while $i < $n && $chars[$i] eq ' ';
            # Read filename, honouring quotes (so a quoted space stays in
            # the name), then strip the quotes.
            my ($raw, $nj) = _read_redir_word(\@chars, $i, $n);
            push @found, [$redir_fd, $append, _arr_dequote($raw)] if $raw ne '';
            $i = $nj;
            next;
        }

        $clean .= $ch; $i++;
    }

    $clean =~ s/\s+\z//;
    return ($clean, \@found);
}

# ----------------------------------------------------------------
# _sh_exec_with_redirs: apply I/O redirections then execute a SH line.
# Perl 5.005_03 compatible: fixed bareword FHs, 2-argument open.
# Supports: > >> < 2> 2>> 2>&1 1>&2
# ----------------------------------------------------------------
sub _sh_exec_with_redirs {
    my ($class, $line, $redirs_ref, $opts_ref) = @_;

    # Collect per-fd: stdin, stdout, stderr
    my ($in_file, $out_file, $out_app, $err_file, $err_app);
    my $err_to_stdout = 0;   # 2>&1
    my $out_to_stderr = 0;   # 1>&2

    for my $r (@{$redirs_ref}) {
        my ($fd, $append, $file) = @{$r};
        $file = BATsh::MB::dec($file) unless $file =~ /\A&[12]\z/;
        if    ($fd == 0) { $in_file  = $file; }
        elsif ($fd == 1) {
            if ($file eq '&2') { $out_to_stderr = 1 }
            else               { $out_file = $file; $out_app = $append }
        }
        else {  # fd == 2
            if ($file eq '&1') { $err_to_stdout = 1 }
            else               { $err_file = $file; $err_app = $append }
        }
    }

    my $ok = 1;
    my ($saved_in, $saved_out, $saved_err) = (0, 0, 0);

    # --- stdin ---
    if (defined $in_file && $ok) {
        sysopen(_SH_REDIR_SRC, $in_file, O_RDONLY)
            or do { warn "sh: $in_file: $!\n"; $ok = 0 };
        if ($ok) {
            open(_SH_REDIR_SAVIN, '<&STDIN')  or do { $ok = 0 };
        }
        if ($ok) {
            open(STDIN, '<&_SH_REDIR_SRC')    or do { $ok = 0 };
            close(_SH_REDIR_SRC);
            $saved_in = 1;
        }
    }

    # --- stdout ---
    if (defined $out_file && $ok) {
        sysopen(_SH_REDIR_DST, $out_file,
                O_WRONLY | O_CREAT | ($out_app ? O_APPEND : O_TRUNC), 0666)
            or do { warn "sh: $out_file: $!\n"; $ok = 0 };
        if ($ok) {
            open(_SH_REDIR_SAVOUT, '>&STDOUT') or do { $ok = 0 };
        }
        if ($ok) {
            open(STDOUT, '>&_SH_REDIR_DST')   or do { $ok = 0 };
            close(_SH_REDIR_DST);
            $saved_out = 1;
        }
    }
    elsif ($out_to_stderr && $ok) {
        open(_SH_REDIR_SAVOUT, '>&STDOUT')    or do { $ok = 0 };
        if ($ok) {
            open(STDOUT, '>&STDERR')           or do { $ok = 0 };
            $saved_out = 1;
        }
    }

    # --- stderr ---
    if (defined $err_file && $ok) {
        sysopen(_SH_REDIR_DST, $err_file,
                O_WRONLY | O_CREAT | ($err_app ? O_APPEND : O_TRUNC), 0666)
            or do { warn "sh: $err_file: $!\n"; $ok = 0 };
        if ($ok) {
            open(_SH_REDIR_SAVERR, '>&STDERR') or do { $ok = 0 };
        }
        if ($ok) {
            open(STDERR, '>&_SH_REDIR_DST')   or do { $ok = 0 };
            close(_SH_REDIR_DST);
            $saved_err = 1;
        }
    }
    elsif ($err_to_stdout && $ok) {
        # Redirect stderr to the current STDOUT (which may itself be redirected)
        open(_SH_REDIR_SAVERR, '>&STDERR')    or do { $ok = 0 };
        if ($ok) {
            open(STDERR, '>&STDOUT')           or do { $ok = 0 };
            $saved_err = 1;
        }
    }

    my $rc = 0;
    if ($ok) {
        $rc = _exec_line($class, $line, $opts_ref);
    }

    # Restore in reverse order
    if ($saved_err) { open(STDERR, '>&_SH_REDIR_SAVERR'); close(_SH_REDIR_SAVERR) }
    if ($saved_out) { open(STDOUT, '>&_SH_REDIR_SAVOUT'); close(_SH_REDIR_SAVOUT) }
    if ($saved_in)  { open(STDIN,  '<&_SH_REDIR_SAVIN');  close(_SH_REDIR_SAVIN)  }

    return $rc;
}

# ----------------------------------------------------------------
# _split_top_semi: split a physical line on TOP-LEVEL ';' only, keeping
# single/double quotes, backticks, $(...) / ${...} / <(...) / >(...)
# and plain (...) groups opaque.  Returns the ';'-separated segments
# (the ';' itself is not included).  Used by the inline-control
# expander (_inline_expand) and by _inline_has_terminator.  Pure Perl
# 5.005_03 (hand-rolled char scan; no regex features).
# ----------------------------------------------------------------
sub _split_top_semi {
    my ($line) = @_;
    my @segs;
    my $cur   = '';
    my $in_sq = 0;
    my $in_dq = 0;
    my $in_bt = 0;     # backtick `...`
    my $pdep  = 0;     # ( ) depth  (covers $(  <(  >(  and plain ( )
    my $bdep  = 0;     # ${ } depth
    my @c     = split //, $line;
    my $n     = scalar @c;
    my $i     = 0;

    while ($i < $n) {
        my $ch = $c[$i];

        if ($in_sq) {
            $cur .= $ch; $in_sq = 0 if $ch eq "'"; $i++; next;
        }
        if ($ch eq "'" && !$in_dq && !$in_bt) { $in_sq = 1; $cur .= $ch; $i++; next }
        if ($ch eq '"' && !$in_bt) { $in_dq = !$in_dq; $cur .= $ch; $i++; next }

        # Backslash escape: copy the next char verbatim
        if ($ch eq '\\') {
            $cur .= $ch; $i++;
            $cur .= $c[$i] if $i < $n; $i++; next;
        }

        if ($ch eq '`') { $in_bt = !$in_bt; $cur .= $ch; $i++; next }

        if (!$in_dq) {
            if ($ch eq '$' && $i+1 < $n && $c[$i+1] eq '{') {
                $bdep++; $cur .= '${'; $i += 2; next;
            }
            if ($bdep > 0 && $ch eq '}') { $bdep--; $cur .= $ch; $i++; next }
            if ($ch eq '(') { $pdep++; $cur .= $ch; $i++; next }
            if ($ch eq ')' && $pdep > 0) { $pdep--; $cur .= $ch; $i++; next }
        }

        if (!$in_dq && !$in_bt && $pdep == 0 && $bdep == 0 && $ch eq ';') {
            push @segs, $cur; $cur = ''; $i++;
            # collapse a following ';' (e.g. ";;") into the same split so
            # empty segments are not produced for the common cases
            next;
        }

        $cur .= $ch; $i++;
    }
    push @segs, $cur;
    return @segs;
}

# _inline_has_terminator: does the SINGLE physical line hold, as a
# top-level ';'-delimited segment, a bare terminator word ($term, e.g.
# 'fi' / 'done' / 'esac')?  Used to detect a fully-inline control
# structure written on one physical line.
sub _inline_has_terminator {
    my ($line, $term) = @_;
    return 0 unless defined $line;
    for my $seg (_split_top_semi($line)) {
        my $s = $seg;
        $s =~ s/\A\s+//; $s =~ s/\s+\z//;
        return 1 if lc($s) eq lc($term);
    }
    return 0;
}

# _inline_expand: turn a fully-inline control-structure physical line
# into the list of "logical lines" the multi-line block parsers expect.
# It splits on top-level ';' and then peels a leading 'then'/'do'/'else'
# keyword off its segment onto its own logical line (so "then echo a"
# becomes "then" + "echo a"), which is exactly the shape _parse_if /
# _parse_for / _parse_while consume line-by-line.
sub _inline_expand {
    my ($line) = @_;
    my @out;
    for my $seg (_split_top_semi($line)) {
        my $s = $seg;
        $s =~ s/\A\s+//; $s =~ s/\s+\z//;
        next if $s eq '';
        if ($s =~ /\A(then|do|else)\b\s*(.*)\z/is) {
            my ($kw, $tail) = (lc($1), $2);
            push @out, $kw;
            push @out, $tail if defined $tail && $tail =~ /\S/;
        }
        else {
            push @out, $s;
        }
    }
    return @out;
}

# _strip_sh_comment: remove a trailing "# ..." comment from one SH
# physical line.  A '#' introduces a comment only when it is unquoted,
# outside any $(...)/${...}/`...` region, and begins a word (preceded by
# the start of line or by whitespace / ; / & / | / '(' ).  This leaves
# parameter forms such as $#, ${#var}, ${var#pat} and an in-word '#'
# (echo a#b, http://h#frag) untouched, matching POSIX shells.  Pure Perl
# 5.005_03 (hand-rolled scan; no regex features).
sub _strip_sh_comment {
    my ($line) = @_;
    return $line unless defined $line && index($line, '#') >= 0;
    my @c     = split //, $line;
    my $n     = scalar @c;
    my $in_sq = 0;
    my $in_dq = 0;
    my $in_bt = 0;
    my $pdep  = 0;
    my $bdep  = 0;
    my $prev  = '';    # previous scanned char (for word-boundary test)
    my $i     = 0;
    while ($i < $n) {
        my $ch = $c[$i];
        if ($in_sq) { $in_sq = 0 if $ch eq "'"; $prev = $ch; $i++; next }
        if ($ch eq "'" && !$in_dq && !$in_bt) { $in_sq = 1; $prev = $ch; $i++; next }
        if ($ch eq '"' && !$in_bt) { $in_dq = !$in_dq; $prev = $ch; $i++; next }
        if ($ch eq '\\') { $prev = 'x'; $i += 2; next }
        if ($ch eq '`') { $in_bt = !$in_bt; $prev = $ch; $i++; next }
        if (!$in_dq && !$in_bt) {
            if ($ch eq '$' && $i+1 < $n && $c[$i+1] eq '{') { $bdep++; $prev = '{'; $i += 2; next }
            if ($bdep > 0 && $ch eq '}') { $bdep--; $prev = $ch; $i++; next }
            if ($ch eq '(') { $pdep++; $prev = $ch; $i++; next }
            if ($ch eq ')' && $pdep > 0) { $pdep--; $prev = $ch; $i++; next }
        }
        if ($ch eq '#' && !$in_sq && !$in_dq && !$in_bt && $pdep == 0 && $bdep == 0) {
            if ($prev eq '' || $prev =~ /\s/
                || $prev eq ';' || $prev eq '&' || $prev eq '|' || $prev eq '(') {
                my $out = ($i > 0) ? join('', @c[0 .. $i-1]) : '';
                $out =~ s/\s+\z//;
                return $out;
            }
        }
        $prev = $ch; $i++;
    }
    return $line;
}

# _if_depth_delta: net change in if/fi nesting contributed by one
# physical line, counting only command-position 'if' openers (+1) and
# 'fi' closers (-1).  A fully-inline "if ...; then ...; fi" nets to 0.
# Used by _parse_if's body collector so a nested if is not closed by the
# outer 'fi'.  Other block types (for/while/case) use different
# terminators (done/esac) and so never affect the if/fi balance.
sub _if_depth_delta {
    my ($line) = @_;
    my $d = 0;
    for my $seg (_split_top_semi($line)) {
        my $s = $seg;
        $s =~ s/\A\s+//;
        $s =~ s/\A(?:then|do|else)\b\s*//i;   # peel a leading block keyword
        my ($w) = ($s =~ /\A(\S+)/);
        $w = defined($w) ? lc($w) : '';
        $d++ if $w eq 'if';
        $d-- if $w eq 'fi';
    }
    return $d;
}

# _find_control_split: when a physical line does NOT begin with a
# control-structure keyword but a control opener (if/for/while/until/
# case/select) appears later in COMMAND position immediately after a
# top-level ';' separator (e.g.  x=""; if [ -z "$x" ]; then ...; fi),
# return the byte offset at which that opener begins so the caller can
# run the prefix and then re-dispatch the control structure through the
# normal block parser.  Only a ';' separator is honoured (sequential,
# so splitting is semantically safe); a control opener after && / || is
# left alone.  Returns undef when there is nothing to split.
sub _find_control_split {
    my ($line) = @_;
    return undef unless defined $line;
    my @c     = split //, $line;
    my $n     = scalar @c;
    my $in_sq = 0;
    my $in_dq = 0;
    my $in_bt = 0;
    my $pdep  = 0;
    my $bdep  = 0;
    my $i     = 0;
    my $cmd_pos = 1;     # are we at the start of a command word?

    while ($i < $n) {
        my $ch = $c[$i];

        if ($in_sq) { $in_sq = 0 if $ch eq "'"; $i++; next }
        if ($ch eq "'" && !$in_dq && !$in_bt) { $in_sq = 1; $cmd_pos = 0; $i++; next }
        if ($ch eq '"' && !$in_bt) { $in_dq = !$in_dq; $cmd_pos = 0; $i++; next }
        if ($ch eq '\\') { $i += 2; $cmd_pos = 0; next }
        if ($ch eq '`') { $in_bt = !$in_bt; $cmd_pos = 0; $i++; next }

        if (!$in_dq && !$in_bt) {
            if ($ch eq '$' && $i+1 < $n && $c[$i+1] eq '{') { $bdep++; $i += 2; $cmd_pos = 0; next }
            if ($bdep > 0 && $ch eq '}') { $bdep--; $i++; next }
            if ($ch eq '(') { $pdep++; $i++; $cmd_pos = 1; next }
            if ($ch eq ')' && $pdep > 0) { $pdep--; $i++; next }
        }

        if (!$in_dq && !$in_bt && $pdep == 0 && $bdep == 0) {
            if ($ch eq ';') { $cmd_pos = 1; $i++; next }
            if ($ch eq '&' && $i+1 < $n && $c[$i+1] eq '&') { $cmd_pos = 0; $i += 2; next }
            if ($ch eq '|' && $i+1 < $n && $c[$i+1] eq '|') { $cmd_pos = 0; $i += 2; next }
            if ($ch eq '|' || $ch eq '&') { $cmd_pos = 0; $i++; next }
            if ($ch =~ /\s/) { $i++; next }   # whitespace keeps command position

            # A non-space, non-separator byte: if we are at command
            # position and NOT at the very start (offset 0), test for a
            # control opener keyword here.
            if ($cmd_pos && $i > 0) {
                my $tail = join('', @c[$i .. $n-1]);
                if ($tail =~ /\A(if|for|while|until|case|select)\b/i) {
                    return $i;
                }
            }
            $cmd_pos = 0; $i++; next;
        }

        $i++;
    }
    return undef;
}

# ----------------------------------------------------------------
sub _split_sh_compound {
    my ($line) = @_;
    my @parts;
    my $cur   = '';
    my $in_sq = 0;
    my $in_dq = 0;
    my $depth = 0;   # $( / <( / >( nesting
    my $ctl   = 0;   # control-structure nesting: if/for/while/until/case/
                     # select ... fi/done/esac.  While >0, a ';' / && / ||
                     # belongs to the compound command and is NOT a
                     # top-level separator (so  cmd | while x; do y; done
                     # and  a && for i in ..; do ..; done  stay intact).
    my $cmdpos = 1;  # true when the next word is in command position
    my @chars = split //, $line;
    my $n     = scalar @chars;
    my $i     = 0;

    while ($i < $n) {
        my $ch = $chars[$i];

        # Single-quote region
        if ($in_sq) {
            if ($ch eq "'") { $in_sq = 0 }
            $cur .= $ch; $i++; next;
        }
        if ($ch eq "'" && !$in_dq) { $in_sq = 1; $cur .= $ch; $i++; $cmdpos = 0; next }

        # Double-quote toggle
        if ($ch eq '"' && !$in_sq) { $in_dq = !$in_dq; $cur .= $ch; $i++; $cmdpos = 0; next }

        # $( nesting inside double-quotes
        if ($in_dq) {
            if ($ch eq '$' && $i+1 < $n && $chars[$i+1] eq '(') { $depth++ }
            elsif ($ch eq ')' && $depth > 0) { $depth-- }
            $cur .= $ch; $i++; next;
        }

        # Track $( nesting outside quotes
        if ($ch eq '$' && $i+1 < $n && $chars[$i+1] eq '(') {
            $depth++; $cur .= $ch; $i++; $cmdpos = 0; next;
        }

        # Track <( / >( process-substitution nesting outside quotes
        if (($ch eq '<' || $ch eq '>') && $i+1 < $n && $chars[$i+1] eq '(') {
            $depth++; $cur .= $ch; $i++; $cmdpos = 0; next;
        }
        if ($ch eq ')' && $depth > 0) {
            $depth--; $cur .= $ch; $i++; $cmdpos = 0; next;
        }

        # Inside $(...) don't split on operators or track control words
        if ($depth > 0) { $cur .= $ch; $i++; next }

        # Backslash escape
        if ($ch eq '\\') {
            $cur .= $ch; $i++;
            $cur .= $chars[$i] if $i < $n; $i++; $cmdpos = 0; next;
        }

        # && operator
        if ($ch eq '&' && $i+1 < $n && $chars[$i+1] eq '&') {
            if ($ctl == 0) {
                push @parts, { op => '', cmd => $cur };
                push @parts, { op => '&&', cmd => '' };
                $cur = '';
            }
            else { $cur .= '&&' }
            $i += 2; $cmdpos = 1; next;
        }

        # || operator
        if ($ch eq '|' && $i+1 < $n && $chars[$i+1] eq '|') {
            if ($ctl == 0) {
                push @parts, { op => '', cmd => $cur };
                push @parts, { op => '||', cmd => '' };
                $cur = '';
            }
            else { $cur .= '||' }
            $i += 2; $cmdpos = 1; next;
        }

        # ; separator (not inside any quote or subst)
        if ($ch eq ';') {
            if ($ctl == 0) {
                push @parts, { op => '', cmd => $cur };
                push @parts, { op => ';', cmd => '' };
                $cur = '';
            }
            else { $cur .= ';' }
            $i++; $cmdpos = 1; next;
        }

        # Single | (pipe): not a compound separator here, but the word that
        # follows it is in command position (so  x | while ...  is tracked).
        if ($ch eq '|') { $cur .= $ch; $i++; $cmdpos = 1; next }

        # '(' opens a group; the next word is in command position.
        if ($ch eq '(') { $cur .= $ch; $i++; $cmdpos = 1; next }

        # Whitespace: preserved; does not itself change command position.
        if ($ch =~ /\s/) { $cur .= $ch; $i++; next }

        # A word starting in command position may be a control keyword.
        if ($cmdpos && $ch =~ /[A-Za-z]/) {
            my $j = $i;
            my $w = '';
            while ($j < $n && $chars[$j] =~ /[A-Za-z]/) { $w .= $chars[$j]; $j++ }
            my $after = ($j < $n) ? $chars[$j] : '';
            # A full word only if the next char terminates it.
            if ($after eq '' || $after =~ /[\s;&|)]/) {
                my $lw = lc $w;
                if (   $lw eq 'if'   || $lw eq 'for'  || $lw eq 'while'
                    || $lw eq 'until'|| $lw eq 'case' || $lw eq 'select') {
                    $ctl++;
                }
                elsif ($lw eq 'fi' || $lw eq 'done' || $lw eq 'esac') {
                    $ctl-- if $ctl > 0;
                }
                $cur .= $w;
                $i = $j;
                # do/then/else/elif introduce a fresh command position.
                $cmdpos = ($lw eq 'do' || $lw eq 'then'
                           || $lw eq 'else' || $lw eq 'elif') ? 1 : 0;
                next;
            }
        }

        # Ordinary character (part of a word / argument).
        $cur .= $ch; $i++; $cmdpos = 0;
    }
    push @parts, { op => '', cmd => $cur };

    # If only one cmd part with no operators, return single element
    my $has_op = 0;
    for my $p (@parts) { $has_op = 1 if $p->{op} ne '' }
    return @parts if $has_op;
    return ({ op => '', cmd => $line });
}

# ----------------------------------------------------------------
# _exec_sh_compound: execute && / || / ; compound SH commands
# ----------------------------------------------------------------
sub _exec_sh_compound {
    my ($class, $parts, $opts_ref) = @_;
    my $pending_op = '';
    my $rc = 0;

    # set -e semantics for lists: a command is EXEMPT when a && or ||
    # operator appears anywhere AFTER it in the list (bash: every command
    # of a && / || list except the one following the final && or ||).
    # Commands separated only by ; are ordinary statements and DO trigger.
    # Adjudication happens here, per member, so _run_lines must not check
    # the list's overall status again: signal that via $_ERREXIT_DONE.
    my $ncmd = 0;
    for my $part (@{$parts}) { $ncmd++ if $part->{op} eq '' }
    $_ERREXIT_DONE = 1 if $ncmd > 1;

    my $seen_cmds = 0;
    for my $k (0 .. $#{$parts}) {
        my $part = $parts->[$k];
        my $op  = $part->{op};
        my $cmd = $part->{cmd};
        $cmd =~ s/\A\s+//; $cmd =~ s/\s+\z//;

        # A prior member executed exit / errexit / break / return: stop.
        last if defined $_EXIT_CODE || $_BREAK || $_RETURN;

        if ($op eq '') {
            $seen_cmds++;
            # Exempt from set -e when a && or || follows later in the list
            my $exempt = 0;
            for my $j ($k + 1 .. $#{$parts}) {
                my $later = $parts->[$j]{op};
                if ($later eq '&&' || $later eq '||') { $exempt = 1; last }
            }
            my $ran = 0;
            # Execute according to pending operator
            if ($pending_op eq '') {
                if ($cmd =~ /\S/) { $ran = 1 }
            }
            elsif ($pending_op eq '&&') {
                if ($LAST_STATUS == 0 && $cmd =~ /\S/) { $ran = 1 }
            }
            elsif ($pending_op eq '||') {
                if ($LAST_STATUS != 0 && $cmd =~ /\S/) { $ran = 1 }
            }
            elsif ($pending_op eq ';') {
                if ($cmd =~ /\S/) { $ran = 1 }
            }
            if ($ran) {
                if ($exempt) {
                    $_ERREXIT_HOLD++;
                    $rc = _exec_line($class, $cmd, $opts_ref);
                    $_ERREXIT_HOLD--;
                }
                else {
                    $rc = _exec_line($class, $cmd, $opts_ref);
                    _errexit_check($rc);
                }
            }
            $pending_op = '';
        }
        else {
            $pending_op = $op;
        }
    }
    return $rc;
}

# ----------------------------------------------------------------
sub _split_sh_pipe {
    my ($line) = @_;
    my @segs;
    my $cur   = '';
    my $in_sq = 0;   # inside single quotes
    my $in_dq = 0;   # inside double quotes
    my $depth = 0;   # $( nesting depth
    my @chars = split //, $line;
    my $n     = scalar @chars;
    my $i     = 0;

    while ($i < $n) {
        my $ch = $chars[$i];

        # Single-quote region: nothing special until closing '
        if ($in_sq) {
            if ($ch eq "'") { $in_sq = 0 }
            $cur .= $ch; $i++; next;
        }

        # Toggle double-quote
        if ($ch eq '"' && !$in_sq) {
            $in_dq = !$in_dq;
            $cur .= $ch; $i++; next;
        }

        # Inside double-quotes only $( nesting matters
        if ($in_dq) {
            if ($ch eq '$' && $i+1 < $n && $chars[$i+1] eq '(') {
                $depth++; $cur .= $ch; $i++; next;
            }
            if ($ch eq ')' && $depth > 0) {
                $depth--; $cur .= $ch; $i++; next;
            }
            # backslash escape inside "
            if ($ch eq '\\') {
                $cur .= $ch; $i++;
                $cur .= $chars[$i] if $i < $n; $i++; next;
            }
            $cur .= $ch; $i++; next;
        }

        # Enter single-quote
        if ($ch eq "'") { $in_sq = 1; $cur .= $ch; $i++; next }

        # $( command substitution: consume BOTH characters and bump the
        # nesting depth exactly ONCE here, so the standalone-'(' handler
        # below does not double-count the '(' of a $( and leave depth
        # stuck at 1 after the matching ')'.  (That stale depth made a
        # bare '|' following a nested $(...) fail to split as a pipe.)
        if ($ch eq '$' && $i+1 < $n && $chars[$i+1] eq '(') {
            $depth++; $cur .= '$('; $i += 2; next;
        }

        # <( / >( process substitution (v0.07): same "consume both
        # characters, bump depth exactly once" treatment as $( above, so
        # a '|' inside its body is not mistaken for the outer pipeline's
        # separator.
        if (($ch eq '<' || $ch eq '>') && $i+1 < $n && $chars[$i+1] eq '(') {
            $depth++; $cur .= $ch . '('; $i += 2; next;
        }
        if ($ch eq '(' ) { $depth++ if $depth > 0; $cur .= $ch; $i++; next }
        if ($ch eq ')' ) {
            if ($depth > 0) { $depth-- }
            $cur .= $ch; $i++; next;
        }

        # Bare | outside any quote/subst => pipeline separator
        if ($ch eq '|' && $depth == 0) {
            # Peek: || is logical-or, not a pipe
            if ($i+1 < $n && $chars[$i+1] eq '|') {
                $cur .= '||'; $i += 2; next;
            }
            push @segs, $cur;
            $cur = '';
            $i++; next;
        }

        # Backslash escape (outside quotes)
        if ($ch eq '\\') {
            $cur .= $ch; $i++;
            $cur .= $chars[$i] if $i < $n; $i++; next;
        }

        $cur .= $ch; $i++;
    }
    push @segs, $cur;
    return @segs;
}

# ----------------------------------------------------------------
# _seg_is_control: true when a pipeline segment is a compound/control
# construct that must be run through _run_lines (the block dispatcher)
# rather than _exec_line (which would try to exec "while"/"for"/... as an
# external command).  Recognises the command-position control keywords and
# a "( subshell )" group.  Enables the common  cmd | while read ... ; done
# and  cmd | for x in ...; done  idioms.  Pure Perl 5.005_03.
sub _seg_is_control {
    my ($seg) = @_;
    my $s = defined($seg) ? $seg : '';
    $s =~ s/\A\s+//;
    my ($w) = ($s =~ /\A(\S+)/);
    return 0 unless defined $w;
    $w = lc $w;
    return 1 if $w eq 'while' || $w eq 'until' || $w eq 'for'
             || $w eq 'if'    || $w eq 'case'  || $w eq 'select';
    return 1 if $s =~ /\A\(/ && $s !~ /\A\(\(/;   # ( subshell ) group
    return 0;
}

# _exec_sh_pipe: run a SH pipeline via temporary files.
# Each segment's stdout feeds the next segment's stdin.
# Perl 5.005_03 compatible: bareword FHs, 2-arg open.
# ----------------------------------------------------------------
sub _exec_sh_pipe {
    my ($class, $segs_ref, $opts_ref) = @_;
    my @segs   = @{$segs_ref};
    my $n_segs = scalar @segs;
    # Tag the stage files with the active pipeline-nesting depth so a nested
    # pipeline (reached when a segment contains a $(...) that is itself a
    # pipeline) gets distinct stage files and does not clobber this one.
    local $_PIPE_DEPTH = $_PIPE_DEPTH + 1;
    my $base   = File::Spec->catfile(File::Spec->tmpdir(),
                                     'batsh_shp_' . $$ . '_' . $_PIPE_DEPTH);
    # Localize the dup/stage filehandle globs so that a nested pipeline
    # (a segment whose $(...) body is itself a pipeline) does not overwrite
    # this pipeline's saved STDOUT/STDIN handles.  Perl 5.005_03 compatible.
    local (*_SH_PIPE_RFH, *_SH_PIPE_WFH, *_SH_PIPE_SAVIN, *_SH_PIPE_SAVOUT);
    my $rc     = 0;
    my $input_f = undef;   # tmpfile that feeds this segment's STDIN

    for my $idx (0 .. $n_segs - 1) {
        my $seg = $segs[$idx];
        $seg =~ s/\A\s+//; $seg =~ s/\s+\z//;
        next unless $seg =~ /\S/;

        my $is_last  = ($idx == $n_segs - 1) ? 1 : 0;
        my $output_f = undef;

        # --- redirect STDIN from previous segment's output ---
        my $saved_in = 0;
        if (defined $input_f && -f $input_f) {
            open(_SH_PIPE_RFH, $input_f)
                or do { warn "SH pipe: open $input_f: $!\n"; last };
            open(_SH_PIPE_SAVIN, '<&STDIN')
                or do { close(_SH_PIPE_RFH); last };
            open(STDIN, '<&_SH_PIPE_RFH')
                or do {
                    close(_SH_PIPE_RFH);
                    open(STDIN, '<&_SH_PIPE_SAVIN'); close(_SH_PIPE_SAVIN);
                    last;
                };
            close(_SH_PIPE_RFH);
            $saved_in = 1;
        }

        # --- redirect STDOUT to next segment's input file ---
        my $saved_out = 0;
        unless ($is_last) {
            $output_f = _shp_tempfile("${base}_${idx}");
            if (!defined $output_f) {
                if ($saved_in) {
                    open(STDIN, '<&_SH_PIPE_SAVIN'); close(_SH_PIPE_SAVIN);
                }
                warn "SH pipe: cannot create stage temp file\n";
                last;
            }
            open(_SH_PIPE_SAVOUT, '>&STDOUT')
                or do {
                    close(_SH_PIPE_WFH);
                    if ($saved_in) {
                        open(STDIN, '<&_SH_PIPE_SAVIN'); close(_SH_PIPE_SAVIN);
                    }
                    last;
                };
            open(STDOUT, '>&_SH_PIPE_WFH')
                or do {
                    close(_SH_PIPE_WFH);
                    open(STDOUT, '>&_SH_PIPE_SAVOUT'); close(_SH_PIPE_SAVOUT);
                    if ($saved_in) {
                        open(STDIN, '<&_SH_PIPE_SAVIN'); close(_SH_PIPE_SAVIN);
                    }
                    last;
                };
            close(_SH_PIPE_WFH);
            $saved_out = 1;
        }

        # --- execute the segment as a SH line ---
        # (_exec_line_impl routes a control/compound segment such as
        #  "while read ...; do ...; done" through the block runner, so the
        #  common  cmd | while read ...  idiom works.)
        $rc = _exec_line($class, $seg, $opts_ref);

        # --- restore STDOUT ---
        if ($saved_out) {
            open(STDOUT, '>&_SH_PIPE_SAVOUT');
            close(_SH_PIPE_SAVOUT);
        }

        # --- restore STDIN and remove input tmpfile ---
        if ($saved_in) {
            open(STDIN, '<&_SH_PIPE_SAVIN');
            close(_SH_PIPE_SAVIN);
            unlink $input_f;
            @_SHP_TMPFILES = grep { $_ ne $input_f } @_SHP_TMPFILES;
        }

        $input_f = $output_f;
    }

    if (defined $input_f && -f $input_f) {
        unlink $input_f;
        @_SHP_TMPFILES = grep { $_ ne $input_f } @_SHP_TMPFILES;
    }
    return $rc;
}

# _shp_tempfile: create a unique, empty temp file for one pipeline stage's
# stdout->stdin bridge, using sysopen(...O_CREAT|O_EXCL...) to avoid symlink
# races (mirrors _bg_tempfile / _hd_tempfile / _subst_tempfile).  Opens the
# package bareword filehandle _SH_PIPE_WFH and returns the final path, or
# undef on failure.  $stub is the depth/index-tagged path prefix so stage
# files stay distinguishable for debugging; a sequence number is appended
# to make the final name unique and unpredictable.
sub _shp_tempfile {
    my ($stub) = @_;
    my $attempt = 0;
    while ($attempt < 1000) {
        $_PIPE_SEQ++;
        $attempt++;
        my $path = $stub . '_' . $_PIPE_SEQ . '.tmp';
        if (sysopen(_SH_PIPE_WFH, $path, O_WRONLY | O_CREAT | O_EXCL, 0600)) {
            push @_SHP_TMPFILES, $path;
            return $path;
        }
        # EEXIST or transient error: retry with next sequence number
    }
    return undef;
}

# ----------------------------------------------------------------
# Pattern helpers for ${var%pat}, ${var#pat}, ${var/pat/rep}
# Converts glob-style pattern to Perl regex (*, ?, [abc]).
# ----------------------------------------------------------------
# ----------------------------------------------------------------
# _glob_expand: expand a single word that contains unquoted glob
# metacharacters (* ? [...]) into a sorted list of matching pathnames.
# Returns the original word unchanged if no matches are found (POSIX
# "nullglob off" behaviour, which is the shell default).
# Only words that were NOT wrapped in quotes are eligible; the caller
# is responsible for passing only unquoted words.
# ----------------------------------------------------------------
sub _glob_expand {
    my ($word) = @_;
    # Fast path: no metacharacters
    return ($word) unless $word =~ /[*?\[]/;
    my @matches = map { BATsh::MB::enc($_) } glob(BATsh::MB::dec($word));
    return @matches ? @matches : ($word);
}

# ----------------------------------------------------------------
# _raw_has_glob: true when the RAW (pre-expansion) argument text contains
# a genuine, eligible filename-glob metacharacter (*, ?, [) -- one that
# was actually written in the script and would trigger pathname
# expansion.  Used by the "echo" builtin to decide whether to run its
# arguments through glob expansion, WITHOUT being fooled by:
#   * a metacharacter inside single or double quotes (echo "*.txt" is
#     literal in bash),
#   * the '*' of the $* / "$*" special parameter or the '?' of $? (these
#     are parameter references, not globs), or
#   * a metacharacter inside a ${...} parameter expansion (${arr[*]},
#     ${VAR?}), which is likewise not a glob.
# The previous test -- a plain /[*?\[]/ match on the raw text -- fired on
# all of these, so "echo \"  x: $*\"" was needlessly re-parsed and its
# leading whitespace and internal spacing collapsed.
# Perl 5.005_03 compatible: single character scan, no regex features.
# ----------------------------------------------------------------
sub _raw_has_glob {
    my ($raw) = @_;
    return 0 unless defined $raw && $raw =~ /\S/;
    my @c    = split //, $raw;
    my $n    = scalar @c;
    my $in_sq = 0; my $in_dq = 0;
    my $bdep  = 0;          # depth inside ${ ... }
    my $i     = 0;
    while ($i < $n) {
        my $ch = $c[$i];
        if ($in_sq) { $in_sq = 0 if $ch eq "'"; $i++; next }
        if ($ch eq "'" && !$in_dq) { $in_sq = 1; $i++; next }
        if ($ch eq '"') { $in_dq = !$in_dq; $i++; next }
        if ($ch eq '\\') { $i += 2; next }          # backslash escape
        # Parameter expansion: $* $? $@ ... and ${ ... }
        if ($ch eq '$' && $i + 1 < $n) {
            if ($c[$i+1] eq '{') { $bdep++; $i += 2; next }
            # $ followed by a single special char (including * and ?) is a
            # parameter reference, not a glob -- skip both characters.
            $i += 2; next;
        }
        if ($bdep > 0) {
            $bdep-- if $ch eq '}';
            $i++; next;
        }
        # An unquoted, non-parameter glob metacharacter counts.
        if (!$in_sq && !$in_dq && ($ch eq '*' || $ch eq '?' || $ch eq '[')) {
            return 1;
        }
        $i++;
    }
    return 0;
}

# ----------------------------------------------------------------
# _glob_expand_args: apply filename globbing to each unquoted word in
# an already-split argument list.  Words that were originally quoted
# (single or double) must already have their quotes stripped by the
# caller; we cannot distinguish them at this stage, so we re-check
# for glob metacharacters and call _glob_expand only when present.
# ----------------------------------------------------------------
sub _glob_expand_args {
    my (@words) = @_;
    my @result;
    for my $w (@words) {
        push @result, _glob_expand($w);
    }
    return @result;
}

sub _glob_to_re {
    my ($pat, $greedy) = @_;
    my $re = '';
    my @chars = split //, $pat;
    my $n = scalar @chars;
    my $i = 0;
    while ($i < $n) {
        my $c = $chars[$i];
        if ($_OPT_EXTGLOB && $c =~ /[?*+\@!]/ && $i+1 < $n && $chars[$i+1] eq '(') {
            my @eg = _extglob_scan(\@chars, $i, sub { _glob_to_re($_[0], $greedy) });
            if (@eg) { $re .= $eg[1]; $i = $eg[0]; next }
        }
        if ($c eq '*') {
            $re .= $greedy ? '.*' : '.*?';
        }
        elsif ($c eq '?') { $re .= '.' }
        elsif ($c eq '[') {
            my $cls = '[';
            $i++;
            while ($i < $n && $chars[$i] ne ']') {
                $cls .= $chars[$i]; $i++;
            }
            $cls .= ']';
            $re .= $cls;
        }
        else { $re .= quotemeta($c) }
        $i++;
    }
    return $re;
}

sub _sh_remove_suffix {
    my ($val, $pat, $greedy) = @_;
    # %  (greedy=0, shortest suffix): keep longest prefix
    #    => /\A(.*) PATTERN \z/s  with greedy prefix  => $1
    # %% (greedy=1, longest suffix):  keep shortest prefix
    #    => /\A(.*?)PATTERN \z/s  with lazy   prefix  => $1
    my $re = _glob_to_re($pat, 1);  # pattern itself is always greedy for suffix
    if ($greedy) {
        # longest suffix removed: lazy prefix
        return ($val =~ /\A(.*?)$re\z/s) ? $1 : $val;
    }
    else {
        # shortest suffix removed: greedy prefix
        return ($val =~ /\A(.*)$re\z/s) ? $1 : $val;
    }
}

sub _sh_remove_prefix {
    my ($val, $pat, $greedy) = @_;
    # #  (greedy=0, shortest prefix): keep longest suffix
    #    => /\A PATTERN(.*) \z/s  with lazy   pattern  => $1
    # ## (greedy=1, longest prefix):  keep shortest suffix
    #    => /\A PATTERN(.*) \z/s  with greedy pattern  => $1
    my $re = _glob_to_re($pat, $greedy);
    return ($val =~ /\A$re(.*)\z/s) ? $1 : $val;
}

sub _sh_replace {
    my ($val, $pat, $rep, $global) = @_;
    my $re = _glob_to_re($pat, 1);
    if ($global) { $val =~ s/$re/$rep/g }
    else          { $val =~ s/$re/$rep/ }
    return $val;
}

# ----------------------------------------------------------------
# Shell function registry  { name => \@body_lines }
# ----------------------------------------------------------------

# ----------------------------------------------------------------
# _inline_body_has_control: true when a single-line function body
# (the text between the braces of "name() { ... }") contains a shell
# control-structure keyword in command position -- if/for/while/until/
# case/select as the first word, or after a ';', '&&', '||' or '|'.
# Such a body must not be torn apart on ';' (that would split
# "while C; do B; done" into unusable fragments); the caller keeps it
# as one line so _run_lines()'s inline-control handling parses it.
# Quotes, $(...), `...` and ${...} are skipped so a keyword appearing
# only inside them (echo "done", VAR=$(case ...)) does not count.
# Perl 5.005_03 compatible: character scan, no regex features beyond
# \A and \b.
# ----------------------------------------------------------------
sub _inline_body_has_control {
    my ($body) = @_;
    return 0 unless defined $body && $body =~ /\S/;
    my @c    = split //, $body;
    my $n    = scalar @c;
    my $in_sq = 0; my $in_dq = 0; my $in_bt = 0;
    my $pdep = 0;  my $bdep = 0;
    my $i    = 0;
    my $cmd_pos = 1;
    while ($i < $n) {
        my $ch = $c[$i];
        if ($in_sq) { $in_sq = 0 if $ch eq "'"; $i++; next }
        if ($ch eq "'" && !$in_dq && !$in_bt) { $in_sq = 1; $cmd_pos = 0; $i++; next }
        if ($ch eq '"' && !$in_bt) { $in_dq = !$in_dq; $cmd_pos = 0; $i++; next }
        if ($ch eq '\\') { $i += 2; $cmd_pos = 0; next }
        if ($ch eq '`') { $in_bt = !$in_bt; $cmd_pos = 0; $i++; next }
        if (!$in_dq && !$in_bt) {
            if ($ch eq '$' && $i+1 < $n && $c[$i+1] eq '{') { $bdep++; $i += 2; $cmd_pos = 0; next }
            if ($bdep > 0 && $ch eq '}') { $bdep--; $i++; next }
            if ($ch eq '$' && $i+1 < $n && $c[$i+1] eq '(') { $pdep++; $i += 2; $cmd_pos = 0; next }
            if ($ch eq '(') { $pdep++; $i++; $cmd_pos = 1; next }
            if ($ch eq ')' && $pdep > 0) { $pdep--; $i++; next }
        }
        if (!$in_dq && !$in_bt && $pdep == 0 && $bdep == 0) {
            if ($ch eq ';') { $cmd_pos = 1; $i++; next }
            if ($ch eq '&' && $i+1 < $n && $c[$i+1] eq '&') { $cmd_pos = 1; $i += 2; next }
            if ($ch eq '|' && $i+1 < $n && $c[$i+1] eq '|') { $cmd_pos = 1; $i += 2; next }
            if ($ch eq '|') { $cmd_pos = 1; $i++; next }
            if ($ch eq '&') { $cmd_pos = 1; $i++; next }
            if ($ch =~ /\s/) { $i++; next }
            if ($cmd_pos) {
                my $tail = join('', @c[$i .. $n-1]);
                if ($tail =~ /\A(?:if|for|while|until|case|select)\b/i) {
                    return 1;
                }
            }
            $cmd_pos = 0; $i++; next;
        }
        $i++;
    }
    return 0;
}

# ----------------------------------------------------------------
# _parse_function: parse "name() {" or "function name {" blocks
# Returns ($status, $new_i).
# ----------------------------------------------------------------
sub _parse_function {
    my ($class, $lines_ref, $start, $opts_ref) = @_;
    my @lines = @{$lines_ref};
    my $line  = $lines[$start];
    $line =~ s/\r?\n\z//;
    $line =~ s/\A\s+//;

    my $name = '';
    if ($line =~ /\A([A-Za-z_][A-Za-z0-9_]*)\s*\(\s*\)\s*(?:\{.*)?\z/) {
        $name = $1;
    }
    elsif ($line =~ /\Afunction\s+([A-Za-z_][A-Za-z0-9_]*)\s*(?:\(\s*\))?\s*(?:\{.*)?\z/i) {
        $name = $1;
    }
    else {
        return (0, $start + 1);
    }

    my @body;
    my $depth = ($line =~ /\{/) ? 1 : 0;
    my $i = $start + 1;

    # Check if the function body is on the same line as the definition
    # e.g. "name() { cmd1; cmd2; }"
    if ($depth >= 1 && $line =~ /\{(.*)\}\s*\z/s) {
        my $inline = $1;
        $inline =~ s/\A\s+//; $inline =~ s/\s+\z//;
        # A trailing ';' just before the closing brace (name() { ...; })
        # is an empty separator; drop it so an inline control structure's
        # "; done"/"; fi"/"; esac" terminator sits at end-of-string where
        # the block parsers expect it.
        $inline =~ s/;\s*\z//;
        $inline =~ s/\s+\z//;
        # A naive split on ';' is correct for a body of simple commands
        # (name() { cmd1; cmd2; }) but WRONG for an inline control
        # structure: "while C; do B; done" would be torn into the four
        # pieces "while C" / "do B" / ... / "done", and the reassembled
        # multi-line form ("do" glued to a command on one line) is not a
        # shape the block parsers accept, so the loop silently ran
        # nothing.  When the inline body contains a control-structure
        # keyword in command position, keep it as a SINGLE body line and
        # let _run_lines() apply the same inline-control handling it uses
        # for a control structure typed directly on one physical line
        # (this also drives the "prefix; control" split via
        # _find_control_split, so "cmd; while ...; do ...; done" works).
        if (_inline_body_has_control($inline)) {
            push @body, $inline if $inline =~ /\S/;
        }
        else {
            # Split on ; to get individual commands
            for my $part (split /;/, $inline) {
                $part =~ s/\A\s+//; $part =~ s/\s+\z//;
                push @body, $part if $part =~ /\S/;
            }
        }
        $_SH_FUNCTIONS{$name} = [ @body ];
        return (0, $i);
    }

    if ($depth == 0) {
        while ($i <= $#lines) {
            my $l = $lines[$i]; $l =~ s/\r?\n\z//; $l =~ s/\A\s+//;
            $i++;
            if ($l =~ /\{/) { $depth = 1; last }
        }
    }

    while ($i <= $#lines) {
        my $l = $lines[$i]; $l =~ s/\r?\n\z//;
        $i++;
        my $opens  = () = ($l =~ /\{/g);
        my $closes = () = ($l =~ /\}/g);
        $depth += $opens - $closes;
        if ($depth <= 0) {
            my $before = $l;
            $before =~ s/\}\s*\z//;
            push @body, $before if $before =~ /\S/;
            last;
        }
        push @body, $l;
    }

    $_SH_FUNCTIONS{$name} = [ @body ];
    return (0, $i);
}

# ----------------------------------------------------------------
# _call_sh_function: execute a registered SH function
# ----------------------------------------------------------------
sub _call_sh_function {
    my ($class, $name, $args_str, $opts_ref) = @_;
    return 1 unless exists $_SH_FUNCTIONS{$name};

    my @args = _parse_args($args_str);

    my @saved_arg;
    for my $n (1 .. 9) {
        push @saved_arg, BATsh::Env->get("BATSH_ARG$n");
        BATsh::Env->set("BATSH_ARG$n",
            defined($args[$n-1]) ? $args[$n-1] : '');
    }
    my @saved_pct;
    for my $n (1 .. 9) {
        push @saved_pct, BATsh::Env->get("%$n");
        BATsh::Env->set("%$n", defined($args[$n-1]) ? $args[$n-1] : '');
    }
    my $saved_star = BATsh::Env->get('%*');
    BATsh::Env->set('%*', join(' ', @args));

    push @FUNCTION_STACK, {};
    my $saved_ret = $_RETURN;
    $_RETURN = 0;

    my $rc = _run_lines($class, $_SH_FUNCTIONS{$name}, $opts_ref);

    $_RETURN = $saved_ret;

    # Restore local variables saved in this function's scope
    if (@FUNCTION_STACK) {
        my $frame = $FUNCTION_STACK[-1];
        for my $var (keys %{$frame}) {
            my $old = $frame->{$var};
            if (defined $old) { BATsh::Env->set($var, $old) }
            else              { BATsh::Env->unset($var) }
        }
    }
    pop @FUNCTION_STACK;

    for my $n (1 .. 9) {
        my $v = $saved_arg[$n-1];
        BATsh::Env->set("BATSH_ARG$n", defined $v ? $v : '');
    }
    for my $n (1 .. 9) {
        my $v = $saved_pct[$n-1];
        BATsh::Env->set("%$n", defined $v ? $v : '');
    }
    BATsh::Env->set('%*', defined $saved_star ? $saved_star : '');

    $LAST_STATUS = $rc;
    return $rc;
}

# ----------------------------------------------------------------
# _parse_args: split a string into arguments respecting quotes
# ----------------------------------------------------------------
sub _parse_args {
    my ($str) = @_;
    $str = '' unless defined $str;
    $str =~ s/\A\s+//; $str =~ s/\s+\z//;
    return () unless $str =~ /\S/;
    my @args;
    my @quoted;   # parallel array: 1 if word was quoted, 0 if bare
    my $cur = '';
    my $word_quoted = 0;
    my $in_sq = 0;
    my $in_dq = 0;
    for my $ch (split //, $str) {
        if ($in_sq) {
            if ($ch eq "'") { $in_sq = 0 } else { $cur .= $ch; $word_quoted = 1 }
            next;
        }
        if ($ch eq "'" && !$in_dq) { $in_sq = 1; $word_quoted = 1; next }
        if ($ch eq '"'  && !$in_sq) { $in_dq = !$in_dq; $word_quoted = 1; next }
        if ($ch =~ /\s/ && !$in_sq && !$in_dq) {
            push @args,   $cur;
            push @quoted, $word_quoted;
            $cur = ''; $word_quoted = 0;
            next;
        }
        $cur .= $ch;
    }
    push @args,   $cur          if $cur ne '' || @args;
    push @quoted, $word_quoted  if $cur ne '' || @quoted;
    # Apply filename globbing to unquoted words containing metacharacters
    my @result;
    for my $i (0 .. $#args) {
        if (!$quoted[$i] && $args[$i] =~ /[*?\[]/) {
            push @result, _glob_expand($args[$i]);
        }
        else {
            push @result, $args[$i];
        }
    }
    return @result;
}

# ----------------------------------------------------------------
# ----------------------------------------------------------------
sub _cmd_external {
    my ($cmd, $rest) = @_;
    $rest = '' unless defined $rest;
    $rest =~ s/\A\s+//;
    my $full = $rest ne '' ? "$cmd $rest" : $cmd;
    $full = BATsh::MB::dec($full);
    BATsh::Env->sync_to_env();
    my $rc = system($full);
    if ($rc == -1) {
        # system() could not launch the command (not found / exec failed).
        # bash reports 127 for "command not found"; without this guard the
        # old ($rc >> 8) arithmetic on -1 produced a huge garbage status.
        $LAST_STATUS = 127;
    }
    else {
        $LAST_STATUS = ($rc == 0) ? 0 : (($rc >> 8) || 1);
    }
    return $LAST_STATUS;
}

# ----------------------------------------------------------------
# let / type / command  (v0.08)
# ----------------------------------------------------------------
# Prior to v0.08 these three POSIX/bash builtins fell through to the
# external-command path and were handed to whatever real shell (if any)
# happened to exist -- which failed on systems without that shell, and
# defeated BATsh's "no external shell required" design.  They are now
# evaluated internally in pure Perl.

# let EXPR [EXPR ...]
#   Each argument is evaluated as a shell-arithmetic expression (reusing
#   _eval_arith, so assignments and ++/-- write back to the variable store).
#   The exit status is 0 when the LAST expression is non-zero, else 1 --
#   the inverse-of-truth convention bash's "let" and "(( ))" both use.
#   Arguments are quote-stripped but NOT filename-globbed, so `let "x=1*2"`
#   and `let x=1+2` both behave as arithmetic rather than pathname patterns.
sub _cmd_let {
    my ($rest) = @_;
    $rest = '' unless defined $rest;
    my @exprs = map { _arr_dequote($_) } _arr_split_words($rest);
    if (!@exprs) {
        print STDERR "sh: let: expression expected\n";
        $LAST_STATUS = 1;
        return 1;
    }
    my $last = 0;
    for my $e (@exprs) {
        $last = _eval_arith($e);
    }
    $LAST_STATUS = ($last != 0) ? 0 : 1;
    return $LAST_STATUS;
}

# _sh_name_kind(NAME): classify NAME the way "type" / "command -v" do,
# in bash's precedence order (alias, keyword, function, builtin, file).
# Returns (KIND, DETAIL) where KIND is one of
#   'alias' (DETAIL = alias body), 'keyword', 'function', 'builtin',
#   'file'  (DETAIL = resolved path), or '' (not found; DETAIL undef).
sub _sh_name_kind {
    my ($name) = @_;
    return ('', undef) unless defined $name && $name ne '';

    return ('alias', $_SH_ALIAS{$name}) if exists $_SH_ALIAS{$name};

    my $lc = lc($name);
    my %kw = map { ($_ => 1) } qw(
        if then else elif fi for while until do done
        case esac function in select time
    );
    return ('keyword', undef) if $kw{$lc};

    return ('function', undef) if exists $_SH_FUNCTIONS{$name};

    return ('builtin', undef) if $name eq '[' || $name eq ':' || $name eq '.';
    my %bi = map { ($_ => 1) } qw(
        alias break cd command continue declare echo eval exec exit export
        false getopts hash let local mapfile printf pwd read readarray
        readonly return set shift shopt source test true trap type typeset
        umask unalias unset
    );
    return ('builtin', undef) if $bi{$lc};

    my $path = _sh_find_on_path($name);
    return ('file', $path) if defined $path;

    return ('', undef);
}

# _sh_find_on_path(NAME): locate an executable NAME the way a shell would.
# A NAME containing a directory separator is tested directly; otherwise each
# PATH element is searched (';'-separated and PATHEXT-aware on Windows-like
# systems, ':'-separated and -x-tested elsewhere).  Returns the full path,
# or undef when not found.  Pure-Perl and Perl 5.005_03 safe.
sub _sh_find_on_path {
    my ($name) = @_;
    return undef unless defined $name && $name ne '';
    my $is_win = ($^O =~ /MSWin32|dos|os2|cygwin/i) ? 1 : 0;

    if ($name =~ m{[/\\]}) {
        return $name if -f $name && ($is_win || -x $name);
        return undef;
    }

    my $path = BATsh::Env->get('PATH');
    $path = $ENV{'PATH'} unless defined $path && $path ne '';
    return undef unless defined $path && $path ne '';

    my $sep  = $is_win ? ';' : ':';
    my @exts = ('');
    if ($is_win) {
        my $pe = BATsh::Env->get('PATHEXT');
        $pe = $ENV{'PATHEXT'} unless defined $pe && $pe ne '';
        $pe = '.COM;.EXE;.BAT;.CMD' unless defined $pe && $pe ne '';
        push @exts, split(/;/, $pe);
    }

    my @dirs = split(/\Q$sep\E/, $path);
    for my $dir (@dirs) {
        $dir = '.' if $dir eq '';
        for my $ext (@exts) {
            my $cand = File::Spec->catfile($dir, $name . $ext);
            if ($is_win) {
                return $cand if -f $cand;
            }
            else {
                return $cand if -f $cand && -x $cand;
            }
        }
    }
    return undef;
}

# _print_type_verbose(NAME, KIND, DETAIL): emit the "type NAME" / "command -V
# NAME" description line.  Returns 1 when found, 0 (with a STDERR diagnostic)
# when NAME is unknown.
sub _print_type_verbose {
    my ($name, $kind, $detail) = @_;
    if ($kind eq 'alias') {
        print "$name is aliased to `" . (defined $detail ? $detail : '') . "'\n";
    }
    elsif ($kind eq 'keyword')  { print "$name is a shell keyword\n" }
    elsif ($kind eq 'function') { print "$name is a function\n" }
    elsif ($kind eq 'builtin')  { print "$name is a shell builtin\n" }
    elsif ($kind eq 'file')     { print "$name is $detail\n" }
    else {
        print STDERR "sh: type: $name: not found\n";
        return 0;
    }
    return 1;
}

# type [-t|-p|-a] NAME [NAME ...]
#   Default: describe how each NAME would be interpreted.
#   -t: print only the one-word kind (alias/keyword/function/builtin/file).
#   -p: print only the path when NAME is an external file (else nothing).
#   -a: describe all matches (this interpreter reports the single primary
#       match, so -a behaves like the default form).
#   Exit status is non-zero when any NAME is not found.
sub _cmd_type {
    my ($rest) = @_;
    $rest = '' unless defined $rest;
    my @w = map { _arr_dequote($_) } _arr_split_words($rest);

    my $mode = '';   # '', 't', 'p', 'a'
    while (@w && $w[0] =~ /\A-[atpP]+\z/) {
        my $opt = shift @w;
        $mode = 'a' if $opt =~ /a/;
        $mode = 't' if $opt =~ /t/;
        $mode = 'p' if $opt =~ /[pP]/;
    }
    if (!@w) { $LAST_STATUS = 0; return 0 }

    my $status = 0;
    for my $name (@w) {
        my ($kind, $detail) = _sh_name_kind($name);
        if ($mode eq 't') {
            if ($kind eq '') { $status = 1 }
            else { print $kind, "\n" }
        }
        elsif ($mode eq 'p') {
            if    ($kind eq 'file') { print $detail, "\n" }
            elsif ($kind eq '')     { $status = 1 }
            # builtin/function/keyword/alias: print nothing (bash -p)
        }
        else {
            _print_type_verbose($name, $kind, $detail) or $status = 1;
        }
    }
    $LAST_STATUS = $status;
    return $status;
}

# command [-p] [-v|-V] NAME [ARG ...]
#   -v: print how NAME would be invoked (name for a builtin/function/keyword,
#       "alias NAME='...'" for an alias, full path for an external file);
#       exit non-zero if NAME is not found -- the ubiquitous feature-detection
#       idiom `if command -v foo >/dev/null; then ...`.
#   -V: verbose description, like "type NAME".
#   plain: run NAME bypassing any shell function of that name.
#   -p is accepted and ignored (PATH is always searched).
sub _cmd_command {
    my ($class, $rest, $raw_pre, $opts_ref) = @_;
    $rest = '' unless defined $rest;
    my @w = map { _arr_dequote($_) } _arr_split_words($rest);

    my $mode = '';   # '', 'v', 'V'
    while (@w && $w[0] =~ /\A-[pvV]+\z/) {
        my $opt = shift @w;
        $mode = 'v' if $opt =~ /v/;
        $mode = 'V' if $opt =~ /V/;
        # -p: accepted, no effect
    }
    # A bare "--" ends option parsing.
    shift @w if @w && $w[0] eq '--';

    if (!@w) { $LAST_STATUS = ($mode ne '') ? 1 : 0; return $LAST_STATUS }

    if ($mode eq 'v' || $mode eq 'V') {
        my $status = 0;
        for my $name (@w) {
            my ($kind, $detail) = _sh_name_kind($name);
            if ($mode eq 'V') {
                _print_type_verbose($name, $kind, $detail) or $status = 1;
            }
            else {   # -v
                if    ($kind eq 'alias') { print "alias $name='" . (defined $detail ? $detail : '') . "'\n" }
                elsif ($kind eq 'file')  { print $detail, "\n" }
                elsif ($kind eq '')      { $status = 1 }
                else                     { print $name, "\n" }   # keyword/function/builtin
            }
        }
        $LAST_STATUS = $status;
        return $status;
    }

    # Plain run form: re-dispatch the raw remainder with function lookup
    # suppressed.  Recover the text after the leading "command" word (and any
    # -p / -- options) from the pre-expansion source so _expand() runs once.
    my $raw = defined $raw_pre ? $raw_pre : $rest;
    $raw =~ s/\A\s*//;
    $raw =~ s/\A[Cc][Oo][Mm][Mm][Aa][Nn][Dd]\b//;
    $raw =~ s/\A\s+//;
    while ($raw =~ /\A(-[pvV]+|--)\s/) {
        my $tok = $1;
        $raw =~ s/\A(?:-[pvV]+|--)\s+//;
        last if $tok eq '--';
    }
    local $_CMD_NO_FUNC = 1;
    return _exec_line($class, $raw, $opts_ref);
}

# ----------------------------------------------------------------
# Background execution helpers (v1)
# ----------------------------------------------------------------
# ----------------------------------------------------------------
# umask / hash / readonly / mapfile  (v0.08)
# ----------------------------------------------------------------
# _sh_is_readonly(NAME): true when NAME carries the readonly attribute.
sub _sh_is_readonly {
    my ($name) = @_;
    return 0 unless defined $name;
    return $_SH_READONLY{ uc($name) } ? 1 : 0;
}

# _sh_store_scalar(NAME, VALUE): the single choke point for a plain scalar
# assignment.  Honours the readonly attribute (refused, status source
# returns 0) and the integer attribute (VALUE evaluated as arithmetic).
# Returns 1 when the value was stored, 0 when a readonly variable blocked
# it.  All the ordinary assignment paths (VAR=val, prefix VAR=val cmd,
# export VAR=val) funnel through here so the attributes are enforced
# uniformly.
sub _sh_store_scalar {
    my ($name, $val) = @_;
    my $ik = uc($name);
    if ($_SH_READONLY{$ik}) {
        print STDERR "sh: $name: readonly variable\n";
        return 0;
    }
    if ($_SH_INTATTR{$ik}) {
        $val = _eval_arith(defined $val ? $val : '');
    }
    BATsh::Env->set($name, $val);
    return 1;
}

# umask [-S] [MODE]
#   With no MODE, print the current file-creation mask (octal, or symbolic
#   with -S).  A numeric (octal) MODE sets the mask.  Uses Perl's umask, so
#   it is a genuine process mask on Unix-like systems (a no-op reflecting
#   whatever the C library reports on Win32).
sub _cmd_umask {
    my ($rest) = @_;
    $rest = '' unless defined $rest;
    $rest =~ s/\A\s+//; $rest =~ s/\s+\z//;

    # Seed the shell mask from the real process umask on first use.
    if (!$_SH_UMASK_INIT) {
        my $u = umask();
        $_SH_UMASK = defined $u ? $u : 0;
        $_SH_UMASK_INIT = 1;
    }

    my $symbolic = 0;
    if ($rest =~ s/\A-S\b\s*//) { $symbolic = 1 }

    if ($rest eq '') {
        if ($symbolic) { print _umask_symbolic($_SH_UMASK), "\n" }
        else           { printf "%04o\n", $_SH_UMASK }
        $LAST_STATUS = 0;
        return 0;
    }
    if ($rest =~ /\A[0-7]+\z/) {
        $_SH_UMASK = oct($rest) & 0777;
        umask($_SH_UMASK);   # honoured on Unix, harmless where it is not
        $LAST_STATUS = 0;
        return 0;
    }
    # Symbolic mode: "u=rwx,g=rx,o=rx" (and +/- ops).  The operand names the
    # permissions to LEAVE enabled; the mask is their complement.
    my $sym = _umask_apply_symbolic($_SH_UMASK, $rest);
    if (defined $sym) {
        $_SH_UMASK = $sym;
        umask($_SH_UMASK);
        $LAST_STATUS = 0;
        return 0;
    }
    print STDERR "sh: umask: $rest: invalid mask\n";
    $LAST_STATUS = 1;
    return 1;
}

# _umask_apply_symbolic(MASK, SPEC): apply a chmod-style symbolic SPEC
# ("[ugoa]*[-+=][rwx]*", comma-separated) to the numeric umask MASK, in
# terms of the permissions the mask leaves ENABLED.  Returns the new
# numeric mask, or undef when SPEC is not valid symbolic syntax.
sub _umask_apply_symbolic {
    my ($mask, $spec) = @_;
    return undef unless defined $spec && $spec ne '';
    my @allow = (
        (~ (($mask >> 6) & 7)) & 7,
        (~ (($mask >> 3) & 7)) & 7,
        (~ ($mask & 7)) & 7,
    );
    my %idx = ('u' => 0, 'g' => 1, 'o' => 2);
    for my $clause (split /,/, $spec) {
        return undef unless $clause =~ /\A([ugoa]*)([-+=])([rwx]*)\z/;
        my ($who, $op, $pstr) = ($1, $2, $3);
        my $perm = 0;
        $perm |= 4 if $pstr =~ /r/;
        $perm |= 2 if $pstr =~ /w/;
        $perm |= 1 if $pstr =~ /x/;
        my @classes;
        if ($who eq '' || $who =~ /a/) { @classes = (0, 1, 2) }
        else {
            for my $w (split //, $who) { push @classes, $idx{$w} }
        }
        for my $ci (@classes) {
            if    ($op eq '=') { $allow[$ci] = $perm }
            elsif ($op eq '+') { $allow[$ci] |= $perm }
            else               { $allow[$ci] &= (~ $perm) & 7 }
        }
    }
    my $newmask = 0;
    $newmask |= ((~ $allow[0]) & 7) << 6;
    $newmask |= ((~ $allow[1]) & 7) << 3;
    $newmask |=  (~ $allow[2]) & 7;
    return $newmask & 0777;
}

# _umask_symbolic(MASK): render a numeric umask as the bash-style symbolic
# form "u=rwx,g=rx,o=rx" (the permissions the mask LEAVES enabled).
sub _umask_symbolic {
    my ($mask) = @_;
    my @cls = ('u', 'g', 'o');
    my @sh  = (($mask >> 6) & 7, ($mask >> 3) & 7, $mask & 7);
    my @out;
    for my $i (0 .. 2) {
        my $allow = (~ $sh[$i]) & 7;
        my $s = '';
        $s .= 'r' if $allow & 4;
        $s .= 'w' if $allow & 2;
        $s .= 'x' if $allow & 1;
        push @out, $cls[$i] . '=' . $s;
    }
    return join(',', @out);
}

# hash [-r] [-l] [-t] [-d name] [-p path name] [NAME ...]
#   BATsh resolves commands through PATH on every call and keeps no
#   location cache, so the maintenance forms (-r clear, -l/-t list, -d/-p)
#   are accepted as successful no-ops.  "hash NAME ..." verifies each NAME
#   is found on PATH (status 1 if any is missing), matching the observable
#   result of bash caching a lookup.
sub _cmd_hash {
    my ($rest) = @_;
    $rest = '' unless defined $rest;
    $rest =~ s/\A\s+//; $rest =~ s/\s+\z//;
    return _sh_set_status(0) if $rest eq '';
    return _sh_set_status(0) if $rest =~ /\A-[rlt]\b\s*\z/;
    return _sh_set_status(0) if $rest =~ /\A-[dp]\b/;

    my @tok = map { _arr_dequote($_) } _arr_split_words($rest);
    my $status = 0;
    for my $name (@tok) {
        next if $name =~ /\A-/;
        if (!defined _sh_find_on_path($name)) {
            print STDERR "sh: hash: $name: not found\n";
            $status = 1;
        }
    }
    return _sh_set_status($status);
}

sub _sh_set_status {
    my ($s) = @_;
    $LAST_STATUS = $s;
    return $s;
}

# readonly [-p] [NAME[=VALUE] ...]
#   Mark each NAME read-only (optionally assigning VALUE first).  With no
#   NAME, or with -p, list the current readonly variables in a form that
#   can be re-read.
sub _cmd_readonly {
    my ($class, $rest) = @_;
    $rest = '' unless defined $rest;
    $rest =~ s/\A\s+//; $rest =~ s/\s+\z//;

    if ($rest eq '' || $rest eq '-p') {
        for my $ik (sort keys %_SH_READONLY) {
            my $v = BATsh::Env->get($ik);
            $v = '' unless defined $v;
            $v =~ s/'/'\\''/g;
            print "readonly $ik='$v'\n";
        }
        return _sh_set_status(0);
    }

    my @tok = map { _arr_dequote($_) } _arr_split_words($rest);
    my $status = 0;
    for my $t (@tok) {
        next if $t eq '-p' || $t eq '';
        if ($t =~ /\A([A-Za-z_][A-Za-z0-9_]*)=(.*)\z/s) {
            my ($name, $val) = ($1, $2);
            if (_sh_is_readonly($name)) {
                print STDERR "sh: $name: readonly variable\n";
                $status = 1;
                next;
            }
            BATsh::Env->set($name, $val);
            $_SH_READONLY{ uc($name) } = 1;
        }
        elsif ($t =~ /\A([A-Za-z_][A-Za-z0-9_]*)\z/) {
            $_SH_READONLY{ uc($1) } = 1;
        }
    }
    return _sh_set_status($status);
}

# mapfile / readarray [-t] [-d DELIM] [-n COUNT] [-O ORIGIN] [-s SKIP] [ARRAY]
#   Read lines from standard input into the indexed array ARRAY (default
#   MAPFILE).  -t strips the trailing delimiter from each line; -d sets the
#   line delimiter (default newline); -n COUNT copies at most COUNT lines
#   (0 = all); -s SKIP discards the first SKIP lines; -O ORIGIN stores the
#   first line at index ORIGIN.  STDIN is whatever the surrounding
#   redirection supplied (e.g. "mapfile arr < file").
sub _cmd_mapfile {
    my ($class, $rest) = @_;
    $rest = '' unless defined $rest;
    my @tok = map { _arr_dequote($_) } _arr_split_words($rest);

    my $strip  = 0;
    my $delim  = "\n";
    my $count  = 0;    # 0 = unlimited
    my $skip   = 0;
    my $origin = 0;
    while (@tok) {
        my $t = $tok[0];
        if    ($t eq '-t') { shift @tok; $strip = 1 }
        elsif ($t eq '-n') { shift @tok; $count  = @tok ? int(_arr_num(shift @tok)) : 0 }
        elsif ($t eq '-s') { shift @tok; $skip   = @tok ? int(_arr_num(shift @tok)) : 0 }
        elsif ($t eq '-O') { shift @tok; $origin = @tok ? int(_arr_num(shift @tok)) : 0 }
        elsif ($t eq '-d') { shift @tok; $delim  = @tok ? shift @tok : "\n" }
        elsif ($t =~ /\A-d(.+)\z/s) { shift @tok; $delim = $1 }
        elsif ($t eq '-u' || $t eq '-c' || $t eq '-C') { shift @tok; shift @tok if @tok }
        elsif ($t =~ /\A-/) { shift @tok }   # unknown flag: ignore
        else { last }
    }
    my $name = @tok ? shift @tok : 'MAPFILE';
    $name = 'MAPFILE' unless defined $name && $name ne '';

    my $sep = (defined $delim && length $delim) ? substr($delim, 0, 1) : "\n";
    my @lines;
    {
        local $/ = $sep;
        while (defined(my $l = <STDIN>)) { push @lines, $l }
    }

    if ($skip > 0) {
        if ($skip >= @lines) { @lines = () }
        else { splice(@lines, 0, $skip) }
    }
    if ($count > 0 && @lines > $count) { @lines = @lines[0 .. $count - 1] }
    if ($strip) { for my $l (@lines) { $l =~ s/\Q$sep\E\z// } }
    @lines = map { BATsh::MB::enc($_) } @lines;

    my $k = _arr_name($name);
    $_SH_ARRAY{$k}      = {};
    $_SH_ARRAY_TYPE{$k} = 'indexed';
    BATsh::Env->unset($name);
    my $ix = $origin;
    for my $l (@lines) { $_SH_ARRAY{$k}{$ix} = $l; $ix++ }

    return _sh_set_status(0);
}

# _arr_num(S): integer value of a leading numeric prefix (0 otherwise).
sub _arr_num {
    my ($s) = @_;
    $s = '' unless defined $s;
    return ($s =~ /\A\s*([-+]?\d+)/) ? int($1) : 0;
}


# Rules:
#   * only the last non-space character may be the background &
#   * it must not be part of && (i.e. preceding char must not be &)
#   * it must not be an fd-duplication >&  (preceding char must not be >)
#   * it must be outside single/double quotes
#   * the remaining command must be non-empty
sub _split_trailing_bg {
    my ($line) = @_;
    return (0, $line) unless defined $line;

    # Find the index of the last character, ignoring trailing whitespace.
    my $rtrim = $line;
    $rtrim =~ s/\s+\z//;
    return (0, $line) if $rtrim eq '';

    my @chars = split //, $rtrim;
    my $last  = $#chars;
    return (0, $line) unless $chars[$last] eq '&';

    # && is a compound operator, not background.
    return (0, $line) if $last >= 1 && $chars[$last-1] eq '&';
    # >& is fd duplication, not background.
    return (0, $line) if $last >= 1 && $chars[$last-1] eq '>';

    # Verify the trailing & is outside quotes and not backslash-escaped by
    # scanning up to it.  $esc_last becomes true if the char at $last is
    # escaped by an immediately preceding (unquoted) backslash.
    my $in_sq    = 0;
    my $in_dq    = 0;
    my $esc_last = 0;
    my $i        = 0;
    while ($i < $last) {
        my $ch = $chars[$i];
        if ($in_sq) {
            $in_sq = 0 if $ch eq "'";
            $i++; next;
        }
        if ($ch eq '\\' && !$in_sq) {       # backslash escapes next char
            $esc_last = 1 if $i + 1 == $last;
            $i += 2; next;
        }
        if ($ch eq "'" && !$in_dq) { $in_sq = 1; $i++; next }
        if ($ch eq '"' && !$in_sq) { $in_dq = !$in_dq; $i++; next }
        $i++;
    }
    return (0, $line) if $in_sq || $in_dq;   # & is inside a quote
    return (0, $line) if $esc_last;          # & is backslash-escaped

    # Strip the trailing & (and surrounding whitespace before it).
    my $stripped = join('', @chars[0 .. $last-1]);
    $stripped =~ s/\s+\z//;
    return (0, $line) if $stripped eq '';     # nothing to run

    return (1, $stripped);
}

# _sh_word_is_foreground: true when the first word of a backgrounded line
# is a BATsh builtin, defined SH function, control keyword, or a variable
# assignment.  Such commands run in the foreground and the trailing &
# is ignored (documented limitation: only external commands background).
sub _sh_word_is_foreground {
    my ($w) = @_;
    return 0 unless defined $w && $w ne '';

    # VAR=value assignment
    return 1 if $w =~ /\A[A-Za-z_][A-Za-z0-9_]*=/;

    # test bracket and no-op
    return 1 if $w eq '[' || $w eq ':' || $w eq '.';

    my $lc = lc($w);

    my %builtin = (
        export => 1, unset => 1, echo => 1, printf => 1, cd => 1,
        pwd => 1, exit => 1, 'true' => 1, 'false' => 1, read => 1,
        test => 1, source => 1, 'return' => 1, 'break' => 1,
        'continue' => 1, shift => 1, local => 1, set => 1,
        let => 1, type => 1, command => 1,
        umask => 1, hash => 1, readonly => 1, mapfile => 1, readarray => 1,
    );
    return 1 if $builtin{$lc};

    # Control keywords (defensive; these are normally handled in _run_lines)
    my %kw = (
        'if' => 1, then => 1, 'else' => 1, elif => 1, fi => 1,
        'for' => 1, 'while' => 1, until => 1, 'do' => 1, done => 1,
        case => 1, esac => 1, function => 1, in => 1,
    );
    return 1 if $kw{$lc};

    # Defined SH function (case-sensitive, as in _exec_line dispatch)
    return 1 if exists $_SH_FUNCTIONS{$w};

    return 0;
}

# _bg_tempfile: create a unique, empty temp file (O_CREAT|O_EXCL to avoid
# symlink races) for capturing a background job's PID on Unix-like systems.
# Returns the path, or undef on failure.
sub _bg_tempfile {
    my $dir = $ENV{'TMPDIR'} || $ENV{'TEMP'} || $ENV{'TMP'} || '';
    $dir = '/tmp' if $dir eq '' && -d '/tmp';
    $dir = '.'    if $dir eq '';
    $dir =~ s{[\\/]+\z}{};
    $dir = '.' if !(-d $dir && -w $dir);

    my $attempt = 0;
    while ($attempt < 1000) {
        $_BG_SEQ++;
        $attempt++;
        my $path = $dir . '/' . 'batsh_bg_' . $$ . '_' . $_BG_SEQ;
        if (sysopen(_BG_TMP, $path, O_WRONLY | O_CREAT | O_EXCL, 0600)) {
            close(_BG_TMP);
            push @_BG_TMPFILES, $path;
            return $path;
        }
        # EEXIST or transient error: retry with next sequence number
    }
    warn "sh: cannot create background pidfile in $dir: $!\n";
    return undef;
}

# _bg_launch: start $cmdline asynchronously.
#   Win32      : system(1, STRING) spawns via the command shell (P_NOWAIT)
#                and returns the PID directly.
#   Unix-like  : delegate to /bin/sh so the job is backgrounded without a
#                Perl fork; the shell's $! (the job PID) is written to a
#                temp file and read back into BATsh's own $!.
# On a successful launch $? (LAST_STATUS) is 0; the exit code of the
# background job itself is not awaited (sh semantics).
# _bg_launch: un-guard the command line, then hand it to the platform-
# specific spawner below (system(1,...) on Win32, "&" on POSIX).
sub _bg_launch {
    my ($class, $cmdline) = @_;
    return _bg_launch_decoded($class, BATsh::MB::dec($cmdline));
}

sub _bg_launch_decoded {
    my ($class, $cmdline) = @_;
    $cmdline = '' unless defined $cmdline;
    return 0 if $cmdline =~ /\A\s*\z/;
    BATsh::Env->sync_to_env();

    if ($^O =~ /MSWin32/i) {
        my $pid = system(1, $cmdline);
        if (defined $pid && $pid > 0) {
            $_LAST_BG_PID = $pid;
            $LAST_STATUS  = 0;
        }
        else {
            warn "sh: failed to start background process\n";
            $LAST_STATUS = 1;
        }
        return $LAST_STATUS;
    }

    # Unix-like
    my $pidfile = _bg_tempfile();
    my $rc;
    if (defined $pidfile) {
        # Group the command so that the whole list (pipelines, &&, ...) is
        # backgrounded as a unit, then echo the job PID ($!) to the file.
        $rc = system("{ $cmdline ; } & echo \$! > '$pidfile'");
        if (open(_BG_PIDFH, "< $pidfile")) {
            local $/;
            my $buf = <_BG_PIDFH>;
            close(_BG_PIDFH);
            $buf = '' unless defined $buf;
            my $pid = '';
            ($pid) = ($buf =~ /(\d+)/);
            $_LAST_BG_PID = $pid if defined $pid && $pid ne '';
        }
        unlink $pidfile;
        @_BG_TMPFILES = grep { $_ ne $pidfile } @_BG_TMPFILES;
    }
    else {
        $rc = system("{ $cmdline ; } &");
    }
    $LAST_STATUS = (defined $rc && $rc != -1) ? 0 : 1;
    return $LAST_STATUS;
}


# ----------------------------------------------------------------
# Split "cmd rest" honouring quoted strings
# ----------------------------------------------------------------
sub _split_sh {
    my ($line) = @_;
    if ($line =~ /\A(\S+)\s*(.*)\z/s) {
        return ($1, $2);
    }
    return ($line, '');
}

# ----------------------------------------------------------------
# _sh_assign_prefix: detect POSIX assignment prefixes on a RAW (un-expanded)
# command line, e.g. `IFS= read -r LINE` or `LC_ALL=C sort file`.
#
# Parses one or more leading VAR=VALUE words, where VALUE is read with
# quote / $(...) / backtick awareness so that an assignment whose value
# merely *contains* spaces (e.g. UPPER=$(echo "a b")) is NOT mistaken for
# a prefix followed by a command.
#
# Returns (\@pairs, $remainder):
#   - @pairs is a list of [VAR, RAW_VALUE] (value still un-expanded)
#   - $remainder is the rest of the line (the command to run), '' if none
# Returns () when the line does not begin with an assignment.
# ----------------------------------------------------------------
sub _sh_assign_prefix {
    my ($line) = @_;
    my @chars = split //, $line;
    my $n     = scalar @chars;
    my $i     = 0;
    my @pairs = ();

    while (1) {
        # Skip leading spaces between successive assignments.
        $i++ while $i < $n && ($chars[$i] eq ' ' || $chars[$i] eq "\t");
        last if $i >= $n;

        # Match a variable name followed by '='.
        my $j    = $i;
        my $name = '';
        if ($chars[$j] =~ /[A-Za-z_]/) {
            $name .= $chars[$j]; $j++;
            while ($j < $n && $chars[$j] =~ /[A-Za-z0-9_]/) { $name .= $chars[$j]; $j++ }
        }
        last unless length($name) && $j < $n && $chars[$j] eq '=';
        $j++;   # consume '='

        # Read the value with quote / $() / backtick awareness.
        my $val   = '';
        my $in_sq = 0;
        my $in_dq = 0;
        my $depth = 0;   # $( ) nesting
        my $in_bt = 0;   # backticks
        while ($j < $n) {
            my $c = $chars[$j];
            if ($in_sq) { $val .= $c; $in_sq = 0 if $c eq "'"; $j++; next }
            # Backslash escape (outside single quotes): the backslash and
            # the char it protects are both kept verbatim -- so "\ " does
            # not end the value word.  _arr_dequote() resolves them later.
            if ($c eq "\\" && !$in_sq) {
                $val .= $c; $j++;
                $val .= $chars[$j] if $j < $n;
                $j++; next;
            }
            if ($c eq "'" && !$in_dq && !$in_bt) { $in_sq = 1; $val .= $c; $j++; next }
            if ($c eq '"' && !$in_bt) { $in_dq = !$in_dq; $val .= $c; $j++; next }
            if (!$in_dq && $c eq '`') { $in_bt = !$in_bt; $val .= $c; $j++; next }
            if (!$in_dq && !$in_bt && $c eq '$' && $j + 1 < $n && $chars[$j+1] eq '(') {
                $depth++; $val .= '$('; $j += 2; next;
            }
            if (!$in_dq && !$in_bt && $depth > 0 && $c eq ')') {
                $depth--; $val .= ')'; $j++; next;
            }
            if (!$in_sq && !$in_dq && !$in_bt && $depth == 0
                && ($c eq ' ' || $c eq "\t")) {
                last;   # end of this value word
            }
            $val .= $c; $j++;
        }

        push @pairs, [$name, $val];
        $i = $j;

        # Peek: is there a following non-space token?
        my $k = $i;
        $k++ while $k < $n && ($chars[$k] eq ' ' || $chars[$k] eq "\t");
        last if $k >= $n;   # nothing follows: trailing pure assignment(s)

        # Is the next token another assignment?  If so, loop; otherwise the
        # remainder is the command.
        my $m    = $k;
        my $nm2  = '';
        if ($chars[$m] =~ /[A-Za-z_]/) {
            $nm2 .= $chars[$m]; $m++;
            while ($m < $n && $chars[$m] =~ /[A-Za-z0-9_]/) { $nm2 .= $chars[$m]; $m++ }
        }
        if (length($nm2) && $m < $n && $chars[$m] eq '=') {
            $i = $k;   # next assignment; continue the loop
            next;
        }

        # Remainder is a command.
        my $remainder = join('', @chars[$k .. $n-1]);
        return (\@pairs, $remainder);
    }

    # No command remainder: either not an assignment at all, or pure
    # assignment(s) which the normal post-expansion path handles.
    return () unless @pairs;
    return (\@pairs, '');
}

# ----------------------------------------------------------------
# Here-document support (Perl 5.005_03 compatible)
# ----------------------------------------------------------------
# _hd_detect: scan a command line for an *unquoted* << operator.
# Returns () if none found, otherwise:
#   ($cmd_part, $dash, $delim, $quoted)
# where $cmd_part is the command with the "<< DELIM" token removed
# (text after the delimiter, e.g. trailing redirections, is preserved),
# $dash is 1 for <<- (strip leading tabs), $delim is the delimiter word,
# and $quoted is 1 when the delimiter was quoted (suppresses expansion).
sub _hd_detect {
    my ($line) = @_;
    my @chars = split //, $line;
    my $n     = scalar @chars;
    my $in_sq = 0;
    my $in_dq = 0;
    my $arith = 0;   # inside $(( ... )): << there is a shift, not a heredoc
    my $i     = 0;

    while ($i < $n) {
        my $ch = $chars[$i];

        if ($in_sq) {
            $in_sq = 0 if $ch eq "'";
            $i++; next;
        }
        if ($ch eq "'" && !$in_dq) { $in_sq = 1; $i++; next }
        if ($ch eq '"' && !$in_sq) { $in_dq = !$in_dq; $i++; next }
        if ($ch eq '\\') { $i += 2; next }

        # Arithmetic expansion $(( ... )): skip its body entirely
        if ($ch eq '$' && $i+2 < $n && $chars[$i+1] eq '(' && $chars[$i+2] eq '(') {
            $arith++; $i += 3; next;
        }
        if ($arith && $ch eq ')' && $i+1 < $n && $chars[$i+1] eq ')') {
            $arith--; $i += 2; next;
        }
        if ($arith) { $i++; next }

        # Unquoted << starts a here-document; unquoted <<< is a
        # here-string (v0.07: handled later, after expansion, by
        # _sh_strip_herestring -- skip all three characters here so the
        # scan does not re-match starting at the second '<').
        if (!$in_dq && $ch eq '<' && $i+1 < $n && $chars[$i+1] eq '<'
                && $i+2 < $n && $chars[$i+2] eq '<') {
            $i += 3; next;
        }
        if (!$in_dq && $ch eq '<' && $i+1 < $n && $chars[$i+1] eq '<') {
            my $cmd_part = join('', @chars[0 .. $i-1]);
            my $j = $i + 2;
            my $dash = 0;
            if ($j < $n && $chars[$j] eq '-') { $dash = 1; $j++ }
            $j++ while $j < $n && ($chars[$j] eq ' ' || $chars[$j] eq "\t");

            my $quoted = 0;
            my $q = '';
            if ($j < $n && ($chars[$j] eq "'" || $chars[$j] eq '"')) {
                $quoted = 1; $q = $chars[$j]; $j++;
            }
            my $delim = '';
            if ($quoted) {
                while ($j < $n && $chars[$j] ne $q) { $delim .= $chars[$j]; $j++ }
                $j++ if $j < $n;   # skip closing quote
            }
            else {
                while ($j < $n && $chars[$j] =~ /\w/) { $delim .= $chars[$j]; $j++ }
            }
            return () if $delim eq '';   # malformed; treat as ordinary line

            my $rest = join('', @chars[$j .. $n-1]);
            $cmd_part .= $rest;          # preserve trailing tokens
            return ($cmd_part, $dash, $delim, $quoted);
        }

        $i++;
    }
    return ();
}

# _hd_tempfile: write $body to a uniquely-named temp file using
# sysopen(... O_CREAT|O_EXCL ...) to avoid symlink races.
# Returns the path, or undef on failure.
sub _hd_tempfile {
    my ($body) = @_;

    my $dir = $ENV{'TMPDIR'} || $ENV{'TEMP'} || $ENV{'TMP'} || '';
    $dir = '/tmp' if $dir eq '' && -d '/tmp';
    $dir = '.'    if $dir eq '';
    $dir =~ s{[\\/]+\z}{};
    $dir = '.' if !(-d $dir && -w $dir);

    my $attempt = 0;
    while ($attempt < 1000) {
        $_HD_SEQ++;
        $attempt++;
        my $path = $dir . '/' . 'batsh_hd_' . $$ . '_' . $_HD_SEQ;
        if (sysopen(_HD_TMP, $path, O_WRONLY | O_CREAT | O_EXCL, 0600)) {
            binmode(_HD_TMP);
            print _HD_TMP $body;
            close(_HD_TMP);
            push @_HD_TMPFILES, $path;
            return $path;
        }
        # EEXIST or transient error: retry with next sequence number
    }
    warn "sh: cannot create here-document temp file in $dir: $!\n";
    return undef;
}

# _hd_run: materialise the here-document body and run the command with
# its STDIN connected to the body, reusing the existing redirect path.
sub _hd_run {
    my ($class, $cmd_part, $body_ref, $quoted, $opts_ref) = @_;

    my @body = @{$body_ref};
    if (!$quoted) {
        for my $b (@body) { $b = _expand($class, $b) }
    }
    my $text = '';
    for my $b (@body) { $text .= BATsh::MB::dec($b) . "\n" }

    my $tmp = _hd_tempfile($text);
    if (!defined $tmp) { $LAST_STATUS = 2; return 2 }

    my @redir = ( [0, 0, $tmp] );   # fd=0 (stdin), append=0, source=tmp
    my $rc = _sh_exec_with_redirs($class, $cmd_part, \@redir, $opts_ref);

    unlink $tmp;
    @_HD_TMPFILES = grep { $_ ne $tmp } @_HD_TMPFILES;
    return $rc;
}

# Failsafe: remove any here-document temp files left behind on abnormal exit.
END { for my $f (@_HD_TMPFILES) { unlink $f if defined $f } }
END { for my $f (@_SUBST_TMPFILES) { unlink $f if defined $f } }
END { for my $f (@_SHP_TMPFILES) { unlink $f if defined $f } }
END { for my $f (@_PROCSUB_TMPFILES) { unlink $f if defined $f } }

# Failsafe: remove any background-job pidfiles left behind on abnormal exit.
END { for my $f (@_BG_TMPFILES) { unlink $f if defined $f } }


# ----------------------------------------------------------------
# Array / associative-array support (v0.06)
# ----------------------------------------------------------------
# Array names are case-insensitive, matching the scalar store: the key
# stored in %_SH_ARRAY is always the uppercased name.
sub _arr_name { return uc($_[0]) }

sub _arr_exists {
    my ($name) = @_;
    return exists $_SH_ARRAY{ _arr_name($name) } ? 1 : 0;
}

sub _arr_is_assoc {
    my ($name) = @_;
    my $k = _arr_name($name);
    return (exists $_SH_ARRAY_TYPE{$k} && $_SH_ARRAY_TYPE{$k} eq 'assoc') ? 1 : 0;
}

# Evaluate an indexed-array subscript as an integer.  Plain integers are
# taken verbatim; anything else is run through the arithmetic evaluator so
# that subscripts such as "1+1" or a bare variable name work like bash.
sub _arr_index {
    my ($s) = @_;
    $s = '' unless defined $s;
    $s =~ s/\A\s+//; $s =~ s/\s+\z//;
    return 0 if $s eq '';
    return int($s) if $s =~ /\A-?\d+\z/;
    my $v = _eval_arith($s);
    return ($v =~ /\A-?\d+\z/) ? int($v) : 0;
}

# Resolve $VAR / ${VAR} inside a subscript (no command substitution, no
# arithmetic -- those are applied later for indexed subscripts).
sub _arr_expand_sub {
    my ($class, $s) = @_;
    return '' unless defined $s;
    $s =~ s/\$\{([A-Za-z_][A-Za-z0-9_]*)\}/
        do { my $v = BATsh::Env->get($1); defined $v ? $v : '' }
    /ge;
    $s =~ s/\$([A-Za-z_][A-Za-z0-9_]*)/
        do { my $v = BATsh::Env->get($1); defined $v ? $v : '' }
    /ge;
    return $s;
}

# Element keys in display order: ascending numeric (indexed) or sorted
# string (assoc).
sub _arr_ordered_keys {
    my ($name) = @_;
    my $k = _arr_name($name);
    return () unless exists $_SH_ARRAY{$k};
    my $h = $_SH_ARRAY{$k};
    if ((defined $_SH_ARRAY_TYPE{$k} && $_SH_ARRAY_TYPE{$k} eq 'assoc')) {
        return sort keys %{$h};
    }
    return sort { $a <=> $b } keys %{$h};
}

sub _arr_values {
    my ($name) = @_;
    my $k = _arr_name($name);
    return () unless exists $_SH_ARRAY{$k};
    my $h = $_SH_ARRAY{$k};
    return map { $h->{$_} } _arr_ordered_keys($name);
}

sub _arr_count {
    my ($name) = @_;
    my $k = _arr_name($name);
    return 0 unless exists $_SH_ARRAY{$k};
    return scalar keys %{$_SH_ARRAY{$k}};
}

# Fetch a single element.  $sub is already $VAR-expanded by the caller.
# Returns undef when the element is unset.
sub _arr_get_element {
    my ($name, $sub) = @_;
    my $k = _arr_name($name);
    return undef unless exists $_SH_ARRAY{$k};
    my $h = $_SH_ARRAY{$k};
    if ((defined $_SH_ARRAY_TYPE{$k} && $_SH_ARRAY_TYPE{$k} eq 'assoc')) {
        return exists $h->{$sub} ? $h->{$sub} : undef;
    }
    my $idx = _arr_index($sub);
    if ($idx < 0) {
        # Negative subscript: count back over the ordered set of set indices.
        my @keys = _arr_ordered_keys($name);
        return undef unless @keys;
        my $kk = $keys[$idx];
        return defined $kk ? $h->{$kk} : undef;
    }
    return exists $h->{$idx} ? $h->{$idx} : undef;
}

# Remove shell quoting from a value: drop unescaped quote characters while
# honouring single- vs double-quote regions.  Handles whole-token quotes
# ("a b") and partial quotes (foo"a b"bar) alike.
sub _arr_dequote {
    my ($v) = @_;
    return '' unless defined $v;
    my $out   = '';
    my $in_sq = 0;
    my $in_dq = 0;
    my @c     = split //, $v;
    my $n     = scalar @c;
    my $i     = 0;
    while ($i < $n) {
        my $c = $c[$i];
        # Single quotes: everything literal, no escapes, until the closer.
        if ($in_sq) {
            if ($c eq "'") { $in_sq = 0 } else { $out .= $c }
            $i++; next;
        }
        if ($c eq "'" && !$in_dq) { $in_sq = 1; $i++; next }
        # Backslash: escape processing (POSIX).
        if ($c eq '\\') {
            my $nx = ($i+1 < $n) ? $c[$i+1] : '';
            if ($in_dq) {
                # Inside "..." backslash is literal EXCEPT before $ ` " \.
                if ($nx eq '"' || $nx eq '\\' || $nx eq '`' || $nx eq '$') {
                    $out .= $nx; $i += 2; next;
                }
                $out .= '\\'; $i++; next;
            }
            # Unquoted: backslash quotes the following char (so \" is a
            # literal quote and does NOT open a quoted region).
            if ($nx ne '') { $out .= $nx; $i += 2; next }
            $out .= '\\'; $i++; next;
        }
        if ($c eq '"' && !$in_sq) { $in_dq = !$in_dq; $i++; next }
        $out .= $c; $i++;
    }
    return $out;
}

# Split a string on unquoted whitespace, KEEPING the quote characters in
# each returned token (so the caller can tell whether a token was quoted).
sub _arr_split_words {
    my ($s) = @_;
    $s = '' unless defined $s;
    my @words;
    my $cur   = '';
    my $have  = 0;
    my $in_sq = 0;
    my $in_dq = 0;
    my $in_bt = 0;    # backtick `...`
    my $pdep  = 0;    # $( ...  and  <( >(  and plain ( )  depth
    my $bdep  = 0;    # ${ ... } depth
    my @chars = split //, $s;
    my $n     = scalar @chars;
    my $i     = 0;
    while ($i < $n) {
        my $c = $chars[$i];
        if ($in_sq) { $cur .= $c; $in_sq = 0 if $c eq "'"; $have = 1; $i++; next }
        if ($c eq "'" && !$in_dq && !$in_bt) { $in_sq = 1; $cur .= $c; $have = 1; $i++; next }
        if ($c eq '"' && !$in_bt) { $in_dq = !$in_dq; $cur .= $c; $have = 1; $i++; next }
        # Backslash escape keeps the next char attached to this word.
        if ($c eq '\\') { $cur .= $c; $have = 1; $i++; $cur .= $chars[$i] if $i < $n; $i++; next }
        if ($c eq '`') { $in_bt = !$in_bt; $cur .= $c; $have = 1; $i++; next }
        # Command / parameter substitution regions are opaque so their
        # internal whitespace does not word-split (e.g. $(echo a b c)).
        if (!$in_dq) {
            if ($c eq '$' && $i+1 < $n && $chars[$i+1] eq '{') { $bdep++; $cur .= '${'; $have = 1; $i += 2; next }
            if ($bdep > 0 && $c eq '}') { $bdep--; $cur .= $c; $have = 1; $i++; next }
            if ($c eq '(') { $pdep++; $cur .= $c; $have = 1; $i++; next }
            if ($c eq ')' && $pdep > 0) { $pdep--; $cur .= $c; $have = 1; $i++; next }
        }
        if (!$in_sq && !$in_dq && !$in_bt && $pdep == 0 && $bdep == 0 && $c =~ /\s/) {
            if ($have) { push @words, $cur; $cur = ''; $have = 0 }
            $i++; next;
        }
        $cur .= $c; $have = 1; $i++;
    }
    push @words, $cur if $have;
    return @words;
}

# Parse the body of a (...) array literal into a list of [subscript, value]
# pairs.  $subscript is undef for positional elements and a string for
# explicit [sub]=value elements.
sub _arr_parse_elements {
    my ($class, $body) = @_;
    my @raw = _arr_split_words($body);
    my @out;
    for my $tok (@raw) {
        my ($sub, $vpart);
        if ($tok =~ /\A\[(.*?)\]=(.*)\z/s) {
            ($sub, $vpart) = ($1, $2);
        }
        else {
            ($sub, $vpart) = (undef, $tok);
        }
        my $raw_has_quote = ($vpart =~ /['"]/) ? 1 : 0;
        my $exp = _expand($class, $vpart);
        if (defined $sub) {
            $sub = _arr_dequote(_expand($class, $sub));
            push @out, [$sub, _arr_dequote($exp)];
        }
        elsif (!$raw_has_quote && $exp =~ /\s/) {
            # Unquoted expansion is subject to word splitting.
            for my $w (split /\s+/, $exp) {
                next if $w eq '';
                push @out, [undef, $w];
            }
        }
        else {
            push @out, [undef, _arr_dequote($exp)];
        }
    }
    return @out;
}

# arr=( ... )  /  arr+=( ... )   whole-array assignment or append.
sub _arr_assign_literal {
    my ($class, $name, $body, $append) = @_;
    my $k     = _arr_name($name);
    my $assoc = _arr_is_assoc($name);   # honour a prior 'declare -A'

    if (!$append) {
        $_SH_ARRAY{$k}      = {};
        $_SH_ARRAY_TYPE{$k} = $assoc ? 'assoc' : 'indexed';
    }
    else {
        $_SH_ARRAY{$k}      = {} unless exists $_SH_ARRAY{$k};
        $_SH_ARRAY_TYPE{$k} = ($assoc ? 'assoc' : 'indexed')
            unless exists $_SH_ARRAY_TYPE{$k};
    }
    BATsh::Env->unset($name);   # a name is array OR scalar, not both

    my $is_assoc = ($_SH_ARRAY_TYPE{$k} eq 'assoc');
    my @elems    = _arr_parse_elements($class, $body);

    if ($is_assoc) {
        for my $e (@elems) {
            my ($sub, $val) = @{$e};
            $sub = '' unless defined $sub;
            $_SH_ARRAY{$k}{$sub} = $val;
        }
    }
    else {
        my $next = 0;
        for my $ix (keys %{$_SH_ARRAY{$k}}) {
            $next = $ix + 1 if $ix =~ /\A-?\d+\z/ && $ix + 1 > $next;
        }
        for my $e (@elems) {
            my ($sub, $val) = @{$e};
            if (defined $sub && $sub ne '') {
                my $ix = _arr_index($sub);
                $_SH_ARRAY{$k}{$ix} = $val;
                $next = $ix + 1;
            }
            else {
                $_SH_ARRAY{$k}{$next} = $val;
                $next++;
            }
        }
    }
    $LAST_STATUS = 0;
    return 0;
}

# arr[sub]=value  /  arr[sub]+=value   single-element assignment or append.
sub _arr_assign_element {
    my ($class, $name, $sub, $rawval, $append) = @_;
    my $val = _expand($class, $rawval);
    $val =~ s/\A"(.*)"\z/$1/s;
    $val =~ s/\A'(.*)'\z/$1/s;
    my $k = _arr_name($name);
    $sub = _arr_expand_sub($class, $sub);
    if (!exists $_SH_ARRAY{$k}) {
        $_SH_ARRAY{$k}      = {};
        $_SH_ARRAY_TYPE{$k} = 'indexed';
    }
    BATsh::Env->unset($name);
    my $key = (defined $_SH_ARRAY_TYPE{$k} && $_SH_ARRAY_TYPE{$k} eq 'assoc')
        ? $sub : _arr_index($sub);
    if ($append) {
        my $old = exists $_SH_ARRAY{$k}{$key} ? $_SH_ARRAY{$k}{$key} : '';
        $_SH_ARRAY{$k}{$key} = $old . $val;
    }
    else {
        $_SH_ARRAY{$k}{$key} = $val;
    }
    $LAST_STATUS = 0;
    return 0;
}

# declare / typeset [-aA] NAME[=(...)] ...   array (and scalar) declaration.
sub _cmd_declare {
    my ($class, $rest) = @_;
    $rest = '' unless defined $rest;
    $rest =~ s/\A\s+//;

    my $type;   # 'assoc' | 'indexed' | undef
    my $intattr = 0;
    my $roattr  = 0;
    while ($rest =~ s/\A(-[A-Za-z]+)\s+//) {
        my $flag = $1;
        if    ($flag =~ /A/) { $type = 'assoc' }
        elsif ($flag =~ /a/) { $type = 'indexed' unless defined $type }
        $intattr = 1 if $flag =~ /i/;
        $roattr  = 1 if $flag =~ /r/;
    }

    while ($rest ne '') {
        $rest =~ s/\A\s+//;
        last if $rest eq '';
        if ($rest =~ /\A([A-Za-z_][A-Za-z0-9_]*)\+?=\((.*)\)\s*(.*)\z/s) {
            my ($name, $body, $tail) = ($1, $2, $3);
            my $k = _arr_name($name);
            $_SH_ARRAY_TYPE{$k} = $type if defined $type;
            _arr_assign_literal($class, $name, $body, 0);
            $rest = $tail;
        }
        elsif ($rest =~ /\A([A-Za-z_][A-Za-z0-9_]*)=((?:"[^"]*"|'[^']*'|\S)*)\s*(.*)\z/s) {
            my ($name, $val, $tail) = ($1, $2, $3);
            if (defined $type) {
                # Typed array declared with a scalar initialiser: seed [0].
                my $k = _arr_name($name);
                $_SH_ARRAY_TYPE{$k} = $type;
                _arr_assign_element($class, $name, '0', $val, 0);
            }
            else {
                $val = _expand($class, $val);
                $val =~ s/\A"(.*)"\z/$1/s;
                $val =~ s/\A'(.*)'\z/$1/s;
                my $ik = uc($name);
                $_SH_INTATTR{$ik} = 1 if $intattr;
                # "declare -i x=EXPR" evaluates the right hand side as
                # arithmetic; _sh_store_scalar re-applies this for any
                # later plain "x=..." assignment because the attribute
                # sticks in %_SH_INTATTR.
                $val = _eval_arith($val) if $_SH_INTATTR{$ik};
                if (_sh_is_readonly($name)) {
                    print STDERR "sh: $name: readonly variable\n";
                    $LAST_STATUS = 1;
                }
                else {
                    BATsh::Env->set($name, $val);
                }
                $_SH_READONLY{$ik} = 1 if $roattr;
            }
            $rest = $tail;
        }
        elsif ($rest =~ /\A([A-Za-z_][A-Za-z0-9_]*)\s*(.*)\z/s) {
            my ($name, $tail) = ($1, $2);
            if (($intattr || $roattr) && !defined $type) {
                # Attribute-only declaration: mark the variable, do NOT
                # turn it into an (empty) array.
                my $ik = uc($name);
                $_SH_INTATTR{$ik}  = 1 if $intattr;
                $_SH_READONLY{$ik} = 1 if $roattr;
            }
            else {
                my $k = _arr_name($name);
                $_SH_ARRAY{$k}      = {} unless exists $_SH_ARRAY{$k};
                $_SH_ARRAY_TYPE{$k} = (defined $type ? $type : 'indexed');
            }
            $rest = $tail;
        }
        else {
            last;
        }
    }
    $LAST_STATUS = 0 unless $LAST_STATUS;
    return $LAST_STATUS;
}

# _sh_try_array_op: detect and perform an array operation on the RAW line.
# Returns (1, $status) when it handled the line, or () otherwise.
sub _sh_try_array_op {
    my ($class, $line, $opts_ref) = @_;
    my $s = $line;
    $s =~ s/\A\s+//; $s =~ s/\s+\z//;
    $s =~ s/\s*;\s*\z//;   # tolerate one trailing ';'

    # declare / typeset / local with array semantics
    if ($s =~ /\A(declare|typeset|local)\b\s*(.*)\z/is) {
        my ($kw, $args) = ($1, $2);
        my $is_local      = (lc($kw) eq 'local');
        my $has_arr_flag  = ($args =~ /\A-[A-Za-z]*[aA]/) ? 1 : 0;
        my $has_arr_init  = ($args =~ /=\(/) ? 1 : 0;
        if (!$is_local || $has_arr_flag || $has_arr_init) {
            return (1, _cmd_declare($class, $args));
        }
        return ();   # plain 'local x=1' -> handled by _cmd_local
    }

    # NAME=( ... )  or  NAME+=( ... )  -- whole-line array literal
    if ($s =~ /\A([A-Za-z_][A-Za-z0-9_]*)(\+?)=\((.*)\)\z/s) {
        my ($name, $plus, $body) = ($1, $2, $3);
        return (1, _arr_assign_literal($class, $name, $body,
                                       ($plus eq '+') ? 1 : 0));
    }

    # NAME[SUB]=VALUE  or  NAME[SUB]+=VALUE  -- single-element assignment
    if ($s =~ /\A([A-Za-z_][A-Za-z0-9_]*)\[([^\]]*)\](\+?)=(.*)\z/s) {
        my ($name, $sub, $plus, $val) = ($1, $2, $3, $4);
        return (1, _arr_assign_element($class, $name, $sub, $val,
                                       ($plus eq '+') ? 1 : 0));
    }

    return ();
}

# _expand_word_list: turn a for-loop list string into a list of items.
# Resolves variables / command substitution, applies filename globbing to
# unquoted glob words, and expands a whole-word ${arr[@]} / ${arr[*]}
# reference (quoted or not) to one item per array element.
sub _expand_word_list {
    my ($class, $list_str) = @_;
    $list_str = _brace_expand_line($list_str) if defined $list_str && $list_str =~ /\{/;
    my @raw = _arr_split_words($list_str);
    my @items;
    for my $tok (@raw) {
        # Whole-word ${arr[@]} / ${arr[*]} -> one item per element value.
        if ($tok =~ /\A"?\$\{([A-Za-z_][A-Za-z0-9_]*)\[[\@*]\]\}"?\z/
            && _arr_exists($1)) {
            push @items, _arr_values($1);
            next;
        }
        # Whole-word ${!arr[@]} / ${!arr[*]} -> one item per index / key.
        if ($tok =~ /\A"?\$\{!([A-Za-z_][A-Za-z0-9_]*)\[[\@*]\]\}"?\z/
            && _arr_exists($1)) {
            push @items, _arr_ordered_keys($1);
            next;
        }
        my $raw_has_quote = ($tok =~ /['"]/) ? 1 : 0;
        my $exp = _arr_dequote(_expand($class, $tok));
        if (!$raw_has_quote) {
            if ($exp =~ /[*?\[]/) {
                push @items, _glob_expand($exp);
            }
            elsif ($exp =~ /\s/) {
                push @items, grep { $_ ne '' } split /\s+/, $exp;
            }
            elsif ($exp ne '') {
                push @items, $exp;
            }
            # an empty unquoted word expands to nothing
        }
        else {
            push @items, $exp;
        }
    }
    return @items;
}

# ----------------------------------------------------------------
# Accessors
# ----------------------------------------------------------------
sub last_status     { return $LAST_STATUS }
sub set_last_status { $LAST_STATUS = $_[1] }

# Need Cwd
BEGIN {
    eval { require Cwd };
    if ($@) {
        eval 'sub Cwd::cwd { return $ENV{PWD} || "." }';
    }
}

1;

__END__

=head1 NAME

BATsh::SH - Pure Perl bash/sh interpreter for BATsh

=head1 SYNOPSIS

  # Used internally by BATsh; not normally called directly.
  # BATsh::SH implements the SH-mode interpreter invoked when BATsh
  # detects a bash/sh section in a .batsh script.

  # Executed via BATsh:
  use BATsh;
  BATsh->run_string(<<'END');
  x=hello
  greet() {
      echo "Hello, $1 -- ${#1} chars"
  }
  greet world
  echo ${x^^}
  for i in 1 2 3; do
      echo item $i
  done
  ls /tmp | perl -ne "print"
  echo out > /tmp/out.txt
  END

=head1 DESCRIPTION

=head2 Executive Summary

BATsh::SH is the sh/bash interpreter component of BATsh.  It handles any
script section whose first token contains a lowercase letter, executing it
entirely in Pure Perl -- no external shell required.  It supports pipelines
(|), I/O redirection (> >> 2>&1), functions, compound commands (&&/||/;),
and rich parameter expansion: ${var%pat}, ${var^^}, ${var:N:L}, ${#var}.

=head2 Mixed-Mode Sample (via BATsh)

  use BATsh;
  BATsh->run_string(<<'SCRIPT');
  :: CMD section: uppercase first token
  SET CITY=Tokyo

  # SH section: lowercase first token
  greet() { echo "Hello from $1!"; }
  greet $CITY
  echo "lower: ${CITY,,}"
  echo $CITY | perl -ne "print uc"
  SCRIPT

=head1 FULL DESCRIPTION

BATsh::SH implements the POSIX sh / bash command set entirely in Perl.
No external sh or bash is required.

=head2 Supported Features

  VAR=value, export VAR=value, unset VAR
  echo, printf
  if/then/elif/else/fi
  for VAR in list; do ... done
  while condition; do ... done
  until condition; do ... done
  (for/while/until accept the loop body either on following lines or fully
   inline on one line, e.g. "for i in 1 2 3; do echo $i; done")
  case $var in pat) ... ;; pat1|pat2) ... ;; *) ... ;; esac
  (case: |-separated patterns, * ? [abc] [a-z] [!abc] globs, quoted/literal
   patterns, and the bash ;& / ;;& fall-through terminators)
  test / [ ... ]  (file tests, string, integer comparisons)
  cd, pwd, exit, true, false, :, read, shift, local, set, eval
  shift [N]  -- shift positional parameters left by N (default 1)
  let EXPR [EXPR ...]  -- arithmetic evaluation builtin (v0.08)
  type [-t|-p] NAME ...  -- report how NAME resolves (v0.08)
  command [-v|-V] NAME [ARG ...]  -- run bypassing functions / look up NAME (v0.08)
  getopts optstring name [arg ...]  -- POSIX option parser (v0.07)
  umask [-S] [MODE]  -- print or set the file-creation mask (v0.08)
  hash [-r] [NAME ...]  -- PATH lookup; cache maintenance is a no-op (v0.08)
  readonly [-p] [NAME[=VALUE] ...]  -- mark variables read-only (v0.08)
  mapfile / readarray [-t] [-d D] [-n N] [-O O] [-s S] [ARR]
                       -- read lines of STDIN into an indexed array (v0.08)
  set -e / -u / -x, +e/+u/+x, set -o errexit|nounset|xtrace
  trap 'cmd' SIG... / trap - SIG / trap '' SIG / trap [-p]
  $(( arithmetic )) -- full C-style operator set (see Arithmetic
   Expansion below); supports $1..$9 positional params
  $( command substitution ), `backtick substitution`
  $VAR, ${VAR}, $1..$9, $@, $*, $#, $?, $$, $0, $!
  ${VAR:-default}, ${VAR:=default}, ${VAR:+alt}
  ${VAR%pat}, ${VAR%%pat}  -- suffix removal (shortest/longest)
  ${VAR#pat}, ${VAR##pat}  -- prefix removal (shortest/longest)
  ${VAR/pat/rep}, ${VAR//pat/rep}  -- substitution (first/all)
  ${VAR^^}, ${VAR^}, ${VAR,,}, ${VAR,}  -- case conversion
  ${VAR:offset:length}, ${VAR:offset}  -- substring
  ${#VAR}  -- string length
  arr=(a b c), arr+=(d e)  -- indexed array assignment / append
  arr[i]=v, arr[i]+=v      -- indexed element assignment / append
  declare -a arr, declare -A map, typeset ...  -- array declaration
  declare -i n=EXPR, declare -r VAR  -- integer / read-only attributes (v0.08)
  map=([k1]=v1 [k2]=v2), map[k]=v  -- associative array assignment
  ${arr[i]}, ${map[key]}, $arr (== ${arr[0]})  -- element access
  ${arr[@]}, ${arr[*]}     -- all elements
  ${#arr[@]}, ${#map[@]}   -- element count
  ${#arr[i]}               -- length of one element
  ${!arr[@]}, ${!map[@]}   -- indices / keys
  unset arr, unset arr[i]  -- whole array / single element
  source / . file
  name() { ... }, function name { ... }  -- function definition
  cmd1 | cmd2 [| cmd3 ...]  (pipeline via temporary file)
  cmd1 && cmd2  (run cmd2 only if cmd1 succeeds)
  cmd1 || cmd2  (run cmd2 only if cmd1 fails)
  cmd1 ; cmd2   (sequential execution)
  > file, >> file, < file  (I/O redirection)
  2> file, 2>> file        (stderr redirect)
  2>&1                     (merge stderr into stdout)
  cmd << DELIM ... DELIM   (here-document on STDIN)
  cmd <<-DELIM             (here-document, strip leading tabs)
  cmd <<'DELIM'            (here-document, no expansion)
  cmd &                    (background execution; external commands)
  echo *.txt               (filename glob expansion: *, ?, [abc])
  for f in *.pl; do ...    (glob expansion in for-loop word list)
  {a,b,c}, {1..5}, {a..e}[..step]  -- brace expansion (v0.07)
  shopt -s/-u extglob; ?(),*(),+(),@(),!()  -- extended pattern matching
   in case patterns and ${VAR%pat}-family patterns (v0.07)
  cmd <<< word              -- here-string (v0.07)
  <(cmd), >(cmd)            -- process substitution via temp file (v0.07)
  select VAR in list; do ... done  -- menu loop (v0.07)
  alias name=value, alias, unalias  (v0.07)
  exec cmd, exec > file ...  (v0.07)
  ( cmd1; cmd2 )            -- subshell command group, isolated scope (v0.07)

=head2 Variable Expansion

C<$VAR>, C<${VAR}>, and positional parameters C<$1>..C<$9> are expanded
before each line executes.  C<$@> and C<$*> expand to all positional
parameters space-joined; C<$#> gives their count.  The special parameters
C<$?> (last exit status), C<$$> (process id), C<$0> (script name) and
C<$!> (process id of the most recent background job, empty before any) are
also expanded.

The following parameter expansion forms are supported:

  ${VAR:-default}   value if set, else default
  ${VAR:=default}   set and use default if unset
  ${VAR:+alt}       alt if set, else empty
  ${VAR%pat}        remove shortest suffix matching pat
  ${VAR%%pat}       remove longest suffix matching pat
  ${VAR#pat}        remove shortest prefix matching pat
  ${VAR##pat}       remove longest prefix matching pat
  ${VAR/pat/rep}    replace first match of pat with rep
  ${VAR//pat/rep}   replace all matches of pat with rep
  ${VAR^^}          convert to uppercase
  ${VAR^}           uppercase first character
  ${VAR,,}          convert to lowercase
  ${VAR,}           lowercase first character
  ${VAR:N:L}        substring from offset N, length L
  ${VAR:N}          substring from offset N to end
  ${#VAR}           length of value

Patterns use shell glob syntax: C<*> matches any string, C<?>
matches any single character, C<[abc]> matches a character class.

=head2 Arithmetic Expansion

C<$(( expression ))> is evaluated by a recursive-descent parser with the
full C-style operator set, in decreasing precedence:

  ( )  grouping
  var++ var--        postfix increment / decrement (write back)
  ++var --var + - ! ~  prefix (~ is signed bitwise NOT: -v-1)
  **                 exponentiation (right-associative)
  * / %              / and % truncate toward zero (-7/2=-3, -7%2=-1)
  + -
  << >>              bit shifts
  < <= > >=          comparisons (result 0 or 1)
  == !=
  &                  bitwise AND
  ^                  bitwise XOR
  |                  bitwise OR
  &&                 logical AND (result 0 or 1)
  ||                 logical OR  (result 0 or 1)
  ?:                 ternary conditional
  = += -= *= /= %= <<= >>= &= ^= |=   assignment (write back)
  ,                  comma (evaluate both, yield the right)

Operands are decimal, hexadecimal C<0xNN>, or octal C<0NN> literals,
variable names (an unset variable reads as 0), and C<$1>..C<$9>.
Assignment and C<++>/C<--> write the result back to the variable store.
A syntax error emits a warning and the expression yields 0.

=head2 Shell Options (set -e / -u / -x)

C<set> with option letters controls execution modes; letters combine
(C<set -eux>), C<+> turns an option off, and the long forms
C<set -o errexit>, C<set -o nounset>, C<set -o xtrace> are accepted.

C<set -e> (errexit): a simple command that exits with a non-zero status
terminates the script with that status.  Exempt, as in POSIX shells: the
condition of C<if>/C<while>/C<until>, and every member of a C<&&> / C<||>
list except the last (so C<false && echo x> does not stop the script,
while C<true && false> does).

C<set -u> (nounset): expanding an unset variable (C<$VAR> or C<${VAR}>)
prints C<sh: VAR: unbound variable> on STDERR and stops the script with
status 1.  Forms with a fallback such as C<${VAR:-default}> are exempt.
Limitation: the command containing the expansion first completes with the
empty string before the script stops.

C<set -x> (xtrace): each simple command is traced to STDERR with a
C<+ > prefix before execution.  Limitation: the B<raw pre-expansion>
line is traced (tracing an expanded copy would execute C<$(...)>
command substitutions twice).

All three options are reset at the start of each top-level
C<BATsh-E<gt>run> / C<run_string> / C<run_lines>, so C<set -e> in one
script does not leak into a later run in the same process.

=head2 eval

C<eval [args...]> removes one level of quoting from its (already
expanded) arguments, concatenates them, and executes the result as a new
command line -- which is parsed and expanded again, giving the double
expansion C<eval> exists for:

  a=b
  b=deep
  eval echo \$$a     # prints "deep"

C<eval> with no arguments does nothing and sets status 0.

=head2 getopts

C<getopts optstring name [arg ...]> is the POSIX option parser.  Called
repeatedly (usually as the condition of a C<while> loop), it walks the
argument list one option at a time, setting the variable named by
C<name> to the option letter found and, for an option that takes an
argument, setting C<OPTARG> to that argument.  C<OPTIND> holds the index
(1-based) of the next argument to be processed; it starts at 1 and must
be reset to 1 by hand before a second, independent parse (for example at
the top of a function that parses its own arguments).  C<getopts> returns
0 while an option was found and non-zero when the options are exhausted,
so the loop ends naturally.

C<optstring> lists the recognised option letters; a letter followed by
C<:> takes an argument.  When no C<[arg ...]> operands are given, the
positional parameters are parsed.

  while getopts "ab:c" opt; do
      case $opt in
          a) all=1 ;;
          b) file=$OPTARG ;;
          c) count=1 ;;
          \?) echo "usage: ..." >&2; exit 2 ;;
      esac
  done
  shift $((OPTIND - 1))     # drop the parsed options; "$@" is the operands

Both option-argument forms are accepted: C<-b file> (separate word) and
C<-bfile> (attached).  Flags may be clustered: C<-ac> is the same as
C<-a -c>.  A C<--> argument ends option processing (and is consumed); the
first non-option word ends it too (and is left in place).

Error reporting has two modes.  By default C<getopts> prints a diagnostic
to STDERR and sets C<name> to C<?> for an unknown option or a missing
required argument.  If C<optstring> begins with a colon (C<:ab:c>),
"silent" mode is selected instead: no message is printed, C<name> is set
to C<?> (unknown option) or C<:> (missing argument), and C<OPTARG>
receives the offending option letter, so the script can report the error
itself.

=head2 let / type / command

C<let EXPR [EXPR ...]> evaluates each argument as a shell-arithmetic
expression, using the same evaluator as C<$(( ))>, so assignments and the
C<++> / C<--> operators write back to the variable store.  The exit status
is 0 when the last expression evaluates to a non-zero value and 1 when it
is zero -- the same "success == non-zero" convention as C<(( ))>.  Quote an
expression that contains spaces or a C<*>: C<let "x = 1 * 2">.

C<type [-t|-p] NAME ...> reports how each C<NAME> would be interpreted, in
bash's precedence order: alias, shell keyword, function, builtin, then an
executable found on C<PATH>.  With C<-t> only the one-word kind is printed
(C<alias> / C<keyword> / C<function> / C<builtin> / C<file>); with C<-p>
only the path of an external file is printed.  The status is non-zero if
any name is unknown.

C<command [-v|-V] NAME [ARG ...]> runs C<NAME> as if no shell function of
that name existed (builtins and external programs are unaffected).  With
C<-v> it prints how C<NAME> would be invoked -- the name for a builtin,
function or keyword, an C<alias NAME='...'> line for an alias, or the full
path for an external file -- which is the portable feature-detection idiom
C<if command -v foo E<gt>/dev/null; then ...>.  With C<-V> it prints a
verbose description, like C<type>.  C<-p> is accepted and ignored.

=head2 printf

C<printf FORMAT [ARG ...]> formats and prints its arguments.  The FORMAT is
reused ("recycled") until every argument has been consumed, so

  printf '%s\n' one two three

prints three lines.  The conversions C<%d %i %o %u %x %X %e %E %f %g %G
%c %s %b %q %%> are supported, with the usual flags, field width and
precision, including the dynamic C<%*d> form that takes the width from an
argument.  C<%b> interprets backslash escapes in its argument (and a C<\c>
there ends all output); C<%q> quotes its argument so it reads back as a
single shell word.  The format string itself understands the C/POSIX
escapes C<\\ \a \b \f \n \r \t \v \e>, octal C<\NNN> and hex C<\xHH>.

C<printf -v VAR FORMAT ...> stores the formatted result in the shell
variable C<VAR> instead of printing it.  A non-numeric argument given to a
numeric conversion is treated as C<0> (bash prints a warning; BATsh stays
quiet).

=head2 umask / hash / readonly / mapfile / declare attributes

C<umask [-S] [MODE]> prints the current file-creation mask (four octal
digits, or the symbolic C<u=rwx,g=rx,o=rx> form with C<-S>) or, given a
MODE, sets it.  MODE may be octal (C<022>) or symbolic
(C<u=rwx,g=rx,o=rx>, with C<+> / C<-> operations such as C<g-w>).  The
shell keeps its own copy of the mask so C<umask MODE; umask> round-trips on
every platform; a set value is also pushed to the OS umask, which affects
file modes on Unix-like systems.

C<hash [-r] [NAME ...]> exists for script compatibility: BATsh resolves
commands through C<PATH> on every call and keeps no location cache, so the
maintenance forms (C<-r>, C<-l>, C<-t>, C<-d>, C<-p>) are accepted as
successful no-ops, while C<hash NAME> verifies that NAME is found on
C<PATH>.

C<readonly [-p] [NAME[=VALUE] ...]> marks each NAME read-only; a subsequent
assignment or C<unset> is refused with a diagnostic and non-zero status.
The attribute is honoured at every assignment path -- a plain C<VAR=value>,
a prefix C<VAR=value command>, C<export>, and C<declare> -- and, like the
shell options, is reset between top-level runs.

C<mapfile> / C<readarray> C<[-t] [-d DELIM] [-n COUNT] [-O ORIGIN] [-s SKIP]
[ARRAY]> reads lines from standard input into the indexed array ARRAY
(default C<MAPFILE>).  C<-t> strips the trailing delimiter, C<-d> sets it
(default newline), C<-n> limits the count (0 means all), C<-s> skips
leading lines, and C<-O> chooses the first index.  The input is whatever
the surrounding redirection provides, e.g. C<mapfile -t lines E<lt> file>.

C<declare -i NAME[=EXPR]> gives NAME the integer attribute: the initialiser
(and any later plain C<NAME=...> assignment) is evaluated as shell
arithmetic, so C<declare -i n=3+4> stores C<7>.  A quoted initialiser with
spaces is accepted too, e.g. C<declare -i s="1 + 2">.  C<declare -r> marks
the variable read-only.

=head2 Arrays and Associative Arrays

Indexed arrays are created by a parenthesised list, by an explicit element
assignment, or by C<declare -a>:

  arr=(alpha beta gamma)    # arr[0]=alpha arr[1]=beta arr[2]=gamma
  arr[3]=delta              # element assignment
  arr+=(epsilon)            # append at the next index
  arr[0]+=X                 # append to one element's string value
  declare -a empty          # declare an empty indexed array

Associative arrays must be declared with C<declare -A> (or C<typeset -A>)
before use, then keyed by arbitrary strings:

  declare -A color
  color[red]=FF0000
  color=([green]=00FF00 [blue]=0000FF)   # whole-array (re)assignment

Element and bulk access mirror bash:

  ${arr[2]}        one element (indexed subscript is evaluated arithmetically)
  ${color[red]}    one element (associative subscript is a literal string)
  $arr             shorthand for ${arr[0]}
  ${arr[-1]}       negative index counts back from the last set element
  ${arr[@]}        all element values
  ${arr[*]}        all element values (same as [@] here)
  ${#arr[@]}       number of set elements
  ${#arr[2]}       length of one element's value
  ${!arr[@]}       list of indices (indexed) or keys (associative)

C<unset arr> removes the whole array; C<unset arr[i]> removes one element.

Element values that contain spaces survive a quoted whole-array reference:
in a C<for> list C<"${arr[@]}"> and C<"${!arr[@]}"> expand to one item per
element or key.  Elsewhere C<${arr[@]}> joins elements with a single space,
consistent with the word-splitting model used throughout BATsh::SH.  Array
names are case-insensitive (like scalar variables); a name is either a
scalar or an array, never both.  Element order for C<${arr[@]}> is ascending
numeric index for indexed arrays and sorted key order for associative arrays
(bash leaves associative order unspecified, so a deterministic order is used
for portable output).

=head2 Case Statements

C<case WORD in ... esac> selects a clause by matching C<WORD> against shell
glob patterns:

  case $fruit in
      apple)         echo "an apple" ;;
      pear|quince)   echo "pome fruit" ;;     # | separates alternatives
      a*)            echo "starts with a" ;;  # * ? globbing
      [0-9])         echo "a digit" ;;        # character classes
      [!aeiou]*)     echo "not a vowel" ;;    # [!...] negated class
      *)             echo "something else" ;; # default catch-all
  esac

Each clause is C<pattern) commands TERMINATOR>.  Patterns are separated by
C<|>; a clause matches if any of its patterns matches the word.  Pattern
syntax is shell glob: C<*> (any string), C<?> (any character), C<[abc]>,
ranges C<[a-z]>, and negation C<[!abc]> or C<[^abc]>.  Quoted or
backslash-escaped metacharacters match literally (e.g. C<"*")> matches a
literal asterisk).  C<*)> is the conventional default clause.

Three clause terminators are supported, matching bash:

  ;;    stop after this clause (the normal case)
  ;&    fall through: run the NEXT clause's body unconditionally
  ;;&   continue: keep testing the remaining patterns against the word

The construct may be written across lines or fully inline on one line
(C<case $x in a) echo a ;; *) echo b ;; esac>).  A leading C<(> before the
pattern list (C<(pattern)>) is accepted.

=head2 Traps and Signals

C<trap> registers a handler to run on a signal or on the C<EXIT> pseudo-signal:

  trap 'COMMANDS' SIGSPEC...   run COMMANDS when each SIGSPEC fires
  trap - SIGSPEC...            reset to the default action
  trap '' SIGSPEC...           ignore the signal
  trap            (or trap -p) list the current traps

A C<SIGSPEC> is a signal name with or without a leading C<SIG> (C<INT>,
C<SIGINT>), a signal number (C<2>), or the C<EXIT> pseudo-signal (also
spelled C<0>).  Real signals are bridged to Perl's C<%SIG>: C<trap 'cmd' INT>
installs a C<%SIG{INT}> handler that runs C<cmd>, C<trap '' INT> sets it to
C<IGNORE>, and C<trap - INT> restores C<DEFAULT>.  The C<EXIT> trap is run
internally when the script finishes or when C<exit> is called.

The handler command is stored unexpanded and expanded when it fires, so

  tmp=$(mktemp); trap 'rm -f $tmp' EXIT

removes the file named by C<$tmp> as it stood at exit.  Handlers run at the
next safe point after a signal is delivered.  C<EXIT> / C<ERR> / C<DEBUG> /
C<RETURN> are treated as pseudo-signals and never touch C<%SIG>; of these,
only C<EXIT> currently runs a handler.  Signal names unsupported by the host
(common on Windows) are accepted but degrade quietly.

=head2 Function Definitions

Shell functions are defined with C<name() { ... }> or
C<function name { ... }>.  Inline single-line bodies are also
supported: C<name() { cmd; }>.  Functions receive arguments as
C<$1>..C<$9> and C<$@>.  The caller's positional parameters are
saved before the call and restored on return.

=head2 Pipeline

The C<|> operator is supported in SH mode.  The left side's standard output
is written to a temporary file (C<File::Spec-E<gt>tmpdir()>), which is then
fed as standard input to the right side.  Multiple pipes (cmd1 | cmd2 | cmd3)
are handled by chaining temporary files.  All temporary files are removed
after use.  This implementation is Pure Perl and Perl 5.005_03 compatible.

=head2 I/O Redirection

  cmd > file      stdout overwrite (create or truncate)
  cmd >> file     stdout append
  cmd < file      stdin from file
  cmd 2> file     stderr overwrite
  cmd 2>> file    stderr append
  cmd 2>&1        merge stderr into stdout (current stdout target)
  cmd 1>&2        merge stdout into stderr

Redirections are parsed B<after> variable expansion, so filenames may
contain variables (e.g. C<echo text E<gt> $outfile>).  All file handles
use bareword globs for Perl 5.005_03 compatibility.

=head2 Here-Documents

A here-document attaches the lines following the command, up to a line
equal to a delimiter word, to the command's standard input:

  cat <<EOF
  line one
  line two
  EOF

Three forms are recognised:

  cmd <<DELIM      body is variable-expanded
  cmd <<'DELIM'    body is literal (no expansion); "DELIM" also works
  cmd <<-DELIM     leading tab characters are stripped from body and
                   from the line carrying the closing delimiter

When the delimiter is unquoted, each body line is expanded exactly like
an ordinary SH line (C<$VAR>, C<${...}>, C<$(...)>).  When the delimiter
is quoted, the body is passed through verbatim.

The body is written to a uniquely named temporary file created with
C<sysopen(...,O_CREAT|O_EXCL,...)> to avoid symlink races, and that file
is supplied as standard input through the same redirection path used by
C<E<lt> file>.  Both built-ins (e.g. C<read>) and external commands run
via C<system()> therefore see the body on STDIN.  The temporary file is
removed immediately after the command finishes, with an C<END> block as a
failsafe.  This implementation is Pure Perl and Perl 5.005_03 compatible.

The closing delimiter must appear on a line by itself and match exactly
(after tab stripping for C<<-E<lt>E<lt>->>); trailing whitespace is not
ignored.  If no matching delimiter is found before end of input, a
warning is issued and C<$?> is set to a non-zero value.

=head3 Here-Document Limitations

The following are B<not> supported in this release and are documented as
known limitations:

=over 4

=item *

Here-documents are recognised only in SH mode.  The C<E<lt>E<lt>>
sequence has no special meaning in CMD mode (C<BATsh::CMD>) and is left
untouched there.

=item *

Only a single here-document per command line is handled.  Multiple
here-documents on one line (C<cmd E<lt>E<lt>A E<lt>E<lt>B>) are not
supported.

=item *

C<E<lt>E<lt>E<lt>> is deliberately not treated as a here-document opener
(it is a here-string -- see L</Here-Strings> below -- which is handled
separately, after expansion, once the ordinary C<E<lt>E<lt>> scan here
has stepped past it).

=item *

Combining a here-document with a pipeline or compound operator on the
same line (e.g. C<cmd E<lt>E<lt>EOF | other>) is best-effort only and not
guaranteed; use a separate command for portable behaviour.

=item *

The delimiter word is matched literally; the C<E<lt>E<lt>"a b"> form with
an embedded space in the delimiter is not supported.

=item *

A here-document body line that looks like a BATsh subroutine marker
(a line of the form C<:LABEL> later followed by C<RET>/C<RETURN>) may be
consumed by subroutine extraction, which runs before mode dispatch.
Avoid such lines inside here-document bodies.

=back

=head2 Background Execution

An unquoted C<&> at the very end of an SH command line starts the command
asynchronously and returns control immediately, in the style of POSIX
shells:

  longjob &
  echo "next prompt"

Only the single C<&> at the end of the line is consumed.  An C<&> that is
part of C<&&>, of an fd-duplication such as C<2E<gt>&1> or C<1E<gt>&2>,
inside single or double quotes, or backslash-escaped (C<\&>) is B<not>
treated as a background operator and is left in place.

The launch is Pure Perl and Perl 5.005_03 compatible, with a portable
split by platform:

=over 4

=item *

On Win32, the command is spawned through the command shell with
C<system(1, ...)> (P_NOWAIT), which returns the process id directly.

=item *

On Unix-like systems the command is started by delegating to F</bin/sh>
(no Perl C<fork> is used), and the background job's process id is captured
through the shell's own C<$!> into a uniquely named temporary file created
with C<sysopen(...,O_CREAT|O_EXCL,...)>.  The temporary file is removed
immediately, with an C<END> block as a failsafe.

=back

On a successful launch C<$?> is set to C<0>; the exit status of the
background job itself is B<not> awaited.  The process id of the most
recently started background job is available through C<$!>, which expands
to the empty string before any background job has been started.

=head3 Background Execution Limitations

The following are B<not> supported in this release and are documented as
known limitations:

=over 4

=item *

Background execution applies only to B<external> commands in SH mode.
A trailing C<&> on a built-in, a defined function, a variable assignment,
or a control keyword is ignored and the command runs in the foreground.
In CMD mode (C<BATsh::CMD>) C<&> keeps its cmd.exe meaning as a sequential
command separator and is unchanged.

=item *

Only a trailing C<&> is recognised.  A mid-line C<&> that backgrounds part
of a line (e.g. C<a & b>) is not supported; write C<a> on its own line
with a trailing C<&> instead.

=item *

There is no job control: C<jobs>, C<wait>, C<wait %n>, C<fg>, C<bg> and
job-specification (C<%n>) syntax are not implemented.  Signals are not
delivered to background jobs by BATsh.

=item *

A backgrounded pipeline or compound list is delegated as a unit to the
underlying OS shell; BATsh expands variables and command substitutions
first, then hands the resulting line to that shell, so redirections and
operators inside a backgrounded line follow OS-shell rules rather than
BATsh's own redirection engine.

=item *

When the command word is supplied by a variable (e.g. C<$CMD &>), the
foreground/background decision is made on the literal first token before
expansion; such lines are treated as external and backgrounded.

=back

=head2 Compound Commands

  cmd1 && cmd2    run cmd2 only if cmd1 exits with status 0
  cmd1 || cmd2    run cmd2 only if cmd1 exits with non-zero status
  cmd1 ; cmd2     run cmd2 unconditionally after cmd1

These are detected B<before> variable expansion to ensure short-circuit
logic works correctly.  Quoting (C<'>, C<">) and C<$(...)> nesting are
respected when splitting.

=head2 Function Definitions

  name() { body }
  function name { body }
  name() { cmd1; cmd2; }   # inline single-line body

Functions are registered in a package-level hash C<%_SH_FUNCTIONS>.
The caller's positional parameters (C<$1>..C<$9>, C<$*>) are saved before
the call and restored on return.  C<local VAR=value> saves the existing
value of C<VAR> in the function's stack frame and restores it on return.

=head2 Brace Expansion

  echo a{b,c,d}e        # abe ace ade
  echo {1..5}            # 1 2 3 4 5
  echo {5..1}             # 5 4 3 2 1
  echo {01..03}            # 01 02 03  (zero-padded from the wider operand)
  echo {a..e}               # a b c d e
  echo {1..10..2}            # 1 3 5 7 9  (numeric step)
  echo {a..e..2}               # a c e     (alpha step)
  echo pre{a,b}mid{c,d}post      # preamidcpost preamidcpost ...

Brace expansion (v0.07) runs lexically on the raw source line, before any
other expansion, exactly like tilde expansion.  A brace group is only
expanded when it contains a top-level comma or a valid C<..> range;
otherwise it -- and any earlier literal braces on the same word -- is
left untouched (C<echo x{foo}y> prints C<x{foo}y>).  Quoted text and
C<${...}>, C<$(...)>, C<$((...))>, C<`...`>, C<E<lt>(...)>, C<E<gt>(...)>
regions are protected and copied through unexpanded, matching the fact
that these are not brace-expansion syntax even though some of them also
use C<{> C<}> or C<(> C<)>.  Nested and nested nested groups are
supported (each alternative is itself recursively brace-expanded).

=head2 Extended Pattern Matching (extglob)

  shopt -s extglob        # enable; "shopt -u extglob" disables (the default)
  shopt extglob            # query; "shopt" alone lists all known options
  shopt -p extglob          # print in "shopt -s/-u extglob" form

  case $f in
    @(*.tar.gz|*.tgz)) echo archive ;;
    !(*.jpg|*.png))     echo not-an-image ;;
  esac

  echo ${name%%+([0-9])}   # strip a trailing run of digits

While C<shopt -s extglob> is active, C<?(list)>, C<*(list)>, C<+(list)>,
C<@(list)>, and C<!(list)> pattern-list operators (C<|>-separated
alternatives, each itself an ordinary glob or a nested extglob group) are
recognised in case patterns and in the C<${VAR%pat}> / C<${VAR%%pat}> /
C<${VAR#pat}> / C<${VAR##pat}> / C<${VAR/pat/rep}> / C<${VAR//pat/rep}>
pattern operand.  C<extglob> is off by default, matching bash, and is
reset to off by C<reset_sh_options()> between top-level runs, alongside
C<set -e> / C<-u> / C<-x>.

=head3 Extended Pattern Matching Limitations

=over 4

=item *

Extglob operators are recognised in case patterns and in the
C<${VAR#pat}>-family parameter-expansion patterns only; pathname
(filename) globbing (C<echo *.@(jpg|png)>) does not expand them, since
filename globbing is delegated to Perl's built-in C<glob()>, which has
no extglob support of its own.

=item *

C<!(list)> is approximated with a repeated negative-lookahead regex
fragment ("any run of characters that never forms a complete match of
one of the alternatives").  This matches the common "exclude these whole
patterns" usage exactly, but is not a byte-for-byte reimplementation of
bash's extglob matcher when C<!(...)> is combined with further pattern
text after it in the same glob.

=back

=head2 Here-Strings

  cat <<< "$greeting"
  read LINE <<< hello

A here-string (C<E<lt>E<lt>E<lt> word>, v0.07) supplies I<word> -- after
tilde, parameter, command, and arithmetic expansion, and quote removal,
exactly like any other word -- as the command's standard input, with a
trailing newline appended.  Unlike a here-document body, I<word> is not
further word-split.  Implementation-wise this reuses the here-document
temporary-file machinery: the expanded content is written to a uniquely
named C<sysopen(...,O_CREAT|O_EXCL,...)> temp file and supplied through
the same redirection path as C<E<lt> file>, removed immediately after the
command finishes.  As with here-documents, only one here-string (or
here-document) per command line is handled.

=head2 Process Substitution

  diff <(sort a.txt) <(sort b.txt)
  generate | tee >(gzip > out.gz)

This interpreter never forks (see L</Background Execution> above), so
neither form of process substitution (v0.07) uses a real named pipe:

=over 4

=item C<E<lt>(cmd)>

I<cmd> is run immediately, its standard output captured into a fresh
temporary file (exactly like C<$(cmd)>, but the file is kept rather than
read back into a scalar), and C<E<lt>(cmd)> is replaced by that file's
path -- suitable for anything that wants a filename to read from.

=item C<E<gt>(cmd)>

An empty temporary file is created immediately and C<E<gt>(cmd)> is
replaced by its path; I<cmd> itself is deferred and run with that file as
its standard input only after the current simple command has finished.
Because I<cmd> runs after, rather than concurrently with, the writer,
this is a best-effort approximation of real streaming C<E<gt>(...)> and
does not suit a writer that expects the reader to keep up in real time.

=back

Both temporary files are removed once the current simple command (and,
for C<E<gt>(cmd)>, its deferred job) has finished; a process substitution
used inside a nested command substitution or loop condition is cleaned
up at that inner level, not held open for the rest of the script.

=head2 select

  select CHOICE in one two three
  do
      echo "you picked: $CHOICE"
      break
  done

C<select> (v0.07) prints a numbered menu of I<list> -- one item per line,
to STDERR -- prompts with C<$PS3> (default C<"#? ">), and reads one line
from STDIN into C<REPLY>: a number in range sets I<VAR> to the
corresponding item and runs the body; anything else (including a blank
line) sets I<VAR> to the empty string and still runs the body, after
which the menu is shown again.  End of input on STDIN ends the loop, as
does C<break>.  Unlike bash, the menu is always one item per line; there
is no terminal-width-based multi-column layout.

=head2 alias / unalias

  alias ll='ls -la'
  alias grep='grep --color=auto'
  alias
  unalias ll
  unalias -a

C<alias> (v0.07) with no arguments lists all aliases; C<alias NAME>
prints one; C<alias NAME=VALUE ...> defines one or more (quote-aware,
like a normal command line).  C<unalias NAME ...> removes the named
aliases; C<unalias -a> removes all of them.  Only the first word of a
simple command is checked against the alias table, with chained aliases
(an alias whose value's first word is itself an alias) resolved up to a
bounded number of times; a name is only ever expanded once per line, so
a self-referential alias (C<alias ls=ls>) cannot loop forever.  Unlike
bash, a trailing space in the alias value does not make the following
word alias-eligible as well.

=head2 exec

  exec > logfile 2>&1     # (stderr-merge form not yet honoured; see below)
  exec > logfile
  exec cmd arg1 arg2

C<exec> (v0.07) with only redirections (no command word) applies them
I<permanently> to the current shell -- future output goes to the new
target for the rest of the script, with no save/restore.  C<exec cmd>
runs I<cmd> (with its own redirections, if any) and then terminates the
whole script with I<cmd>'s exit status, approximating "exec replaces the
shell" without a real fork/exec.  Only C<E<gt>>, C<E<gt>E<gt>>, and
C<E<lt>> trailers on C<exec> are honoured; C<2E<gt>>, C<2E<gt>&1>, and
C<1E<gt>&2> forms are not yet supported on C<exec> itself (they work
normally on an ordinary command).

=head2 Subshell Command Groups

  ( cd /tmp; VAR=1; echo "in subshell: $VAR" )
  echo "back out here: $VAR"    # unaffected by the subshell's VAR=1 and cd

  (
      f() { echo "defined only inside"; }
      f
  )
  f    # "f: command not found" -- the function did not leak out

A parenthesised command group (v0.07) runs its body with an isolated
scope: variable assignments, array changes, function and alias
definitions, and C<cd> made inside C<( ... )> do not affect the calling
shell.  Because this interpreter never forks, isolation is approximated
by snapshotting C<BATsh::Env>, the array tables, C<%_SH_FUNCTIONS>,
C<%_SH_ALIAS>, and the working directory before running the body, and
restoring all of it afterward regardless of how the body finished.  An
C<exit> inside the group ends only the group (its status becomes the
group's exit status, and the script continues after it); C<break> /
C<continue> / C<return> still propagate outward to an enclosing loop or
function, since bash's C<( ... )> does not stop them either.  Both the
single-line form (C<( cmd1; cmd2 )>) and the multi-line form (a bare
C<(> ending one line, a matching bare C<)> ending a later one) are
recognised; a trailing C<E<gt>>, C<E<gt>E<gt>>, or C<E<lt>> redirection
on the closing C<)> line is honoured, but a trailing C<&> and C<2>>-style
redirections on that line are not (documented limitations, mirroring the
ones noted for C<exec> above).

=head1 AUTHOR

INABA Hitoshi E<lt>ina.cpan@gmail.comE<gt>

=head1 LICENSE

Same as Perl itself.

=cut
