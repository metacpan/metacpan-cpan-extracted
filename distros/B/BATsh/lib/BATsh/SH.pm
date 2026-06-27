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
#
######################################################################

use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }

use File::Spec ();
use Carp qw(croak);
use Fcntl qw(O_WRONLY O_CREAT O_EXCL);
use vars qw($VERSION);
$VERSION = '0.06';
$VERSION = $VERSION;

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
# ----------------------------------------------------------------
my $LAST_STATUS = 0;   # $?
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

# ----------------------------------------------------------------
# Public: execute an array of SH lines
# Returns exit status (0 = success)
# ----------------------------------------------------------------
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
        if ($first eq 'while' || $first eq 'until') {
            ($status, $i) = _parse_while($class, \@lines, $i - 1, $opts_ref);
            next;
        }
        if ($first eq 'case') {
            ($status, $i) = _parse_case($class, \@lines, $i - 1, $opts_ref);
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

        $status = _exec_line($class, $line, $opts_ref);
        $_CONTINUE = 0 if $_CONTINUE;
    }
    return $status;
}

# ----------------------------------------------------------------
# Execute one SH line
# ----------------------------------------------------------------
sub _exec_line {
    my ($class, $raw, $opts_ref) = @_;

    my $line = $raw;
    $line =~ s/\A\s+//;
    return 0 if $line =~ /\A\s*\z/;
    return 0 if $line =~ /\A\s*#/;

    # Shebang: treat as comment
    return 0 if $line =~ /\A#!/;

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

    # Detect pipeline BEFORE variable expansion to avoid expanding
    # pipe-like characters inside command substitutions prematurely.
    # _split_sh_pipe returns >1 segment only when bare | is present.
    my @pipe_segs = _split_sh_pipe($line);
    if (@pipe_segs > 1) {
        return _exec_sh_pipe($class, \@pipe_segs, $opts_ref);
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
            for my $p (@{$pairs_ref}) {
                my ($var, $rawval) = @{$p};
                my $val = _expand($class, $rawval);
                $val =~ s/\A"(.*)"\z/$1/s;
                $val =~ s/\A'(.*)'\z/$1/s;
                BATsh::Env->set($var, $val);
            }
            return _exec_line($class, $remainder, $opts_ref);
        }
    }

    # Expand variables and command substitutions
    $line = _expand($class, $line);

    # Strip trailing ;
    $line =~ s/\s*;\s*\z//;

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
        # Strip outermost quotes from value
        $val =~ s/\A"(.*)"\z/$1/s;
        $val =~ s/\A'(.*)'\z/$1/s;
        BATsh::Env->set($var, $val);
        $LAST_STATUS = 0;
        return 0;
    }

    if ($lc_cmd eq 'export')  { return _cmd_export($rest) }
    if ($lc_cmd eq 'unset')   { return _cmd_unset($rest) }
    if ($lc_cmd eq 'echo') {
        # Apply word-splitting and glob expansion to unquoted tokens
        if ($rest =~ /[*?\[]/) {
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
    if ($lc_cmd eq 'shift')   { return _cmd_shift() }
    if ($lc_cmd eq 'local')   { return _cmd_local($rest) }
    if ($lc_cmd eq 'set')     { return _cmd_set_sh($rest) }

    # Defined SH function
    if (exists $_SH_FUNCTIONS{$cmd}) {
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

    # ${#VAR} -- length of value
    $str =~ s/\$\{#([A-Za-z_][A-Za-z0-9_]*)\}/
        do { my $v = BATsh::Env->get($1); defined $v ? length($v) : 0 }
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
            my $off = int($2); my $len = int($3);
            $off = length($v) + $off if $off < 0;
            $off = 0 if $off < 0;
            substr($v, $off, $len)
        }
    /ge;
    $str =~ s/\$\{([A-Za-z_][A-Za-z0-9_]*):(-?\d+)\}/
        do {
            my $v = BATsh::Env->get($1); $v = defined $v ? $v : '';
            my $off = int($2);
            $off = length($v) + $off if $off < 0;
            $off = 0 if $off < 0;
            substr($v, $off)
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
                my $v = BATsh::Env->get($n); defined $v ? $v : ''
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

    # $@ and $* all positional parameters
    $str =~ s/\$\@/do { my $v=BATsh::Env->get('%*'); defined $v ? $v : '' }/ge;

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
                my $v = BATsh::Env->get($n); defined $v ? $v : ''
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
sub _eval_arith {
    my ($expr) = @_;
    # Expand $1..$9 positional params before further processing
    $expr =~ s/\$([1-9])/_arith_pos($1)/ge;
    # Expand $VAR names with numeric values
    $expr =~ s/\$([A-Za-z_][A-Za-z0-9_]*)/_arith_var($1)/ge;
    # Replace bare VAR names with numeric values
    $expr =~ s/([A-Za-z_][A-Za-z0-9_]*)/_arith_var($1)/ge;
    # Safe eval: digits, operators, parens, spaces only
    if ($expr =~ /\A[\d\s\+\-\*\/\%\(\)]+\z/) {
        my $result = eval $expr;
        return defined $result ? int($result) : 0;
    }
    return 0;
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
    my $tmpfile = File::Spec->catfile(
        File::Spec->tmpdir(),
        'batsh_cap_' . $$ . '_' . $_SUBST_DEPTH . '.tmp');
    local *_SUBST_SAVOUT;
    open(_SUBST_SAVOUT, '>&STDOUT') or return '';
    local *_SUBST_CAPFH;
    open(_SUBST_CAPFH, "> $tmpfile")
        or do { open(STDOUT, '>&_SUBST_SAVOUT'); return '' };
    open(STDOUT, '>&_SUBST_CAPFH')
        or do { close(_SUBST_CAPFH); open(STDOUT, '>&_SUBST_SAVOUT'); return '' };
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
    $output = '' unless defined $output;
    $output =~ s/\n+\z//;   # strip trailing newlines (like shell)
    return $output;
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
            BATsh::Env->set($1, $2);
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
    for my $var (split /\s+/, $rest) {
        $var =~ s/\A\s+//; $var =~ s/\s+\z//;
        next if $var eq '';
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
    $LAST_STATUS = 0;
    return 0;
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
    if ($no_newline) { print $rest }
    else             { print "$rest\n" }
    $LAST_STATUS = 0;
    return 0;
}

# ----------------------------------------------------------------
# printf
# ----------------------------------------------------------------
sub _cmd_printf {
    my ($rest) = @_;
    $rest =~ s/\A\s+//;
    # Extract format string (first quoted arg or first word)
    my ($fmt, @args);
    if ($rest =~ s/\A"((?:[^"\\]|\\.)*)"\s*//) {
        $fmt = $1;
    }
    elsif ($rest =~ s/\A'([^']*)'\s*//) {
        $fmt = $1;
    }
    else {
        ($fmt, $rest) = split /\s+/, $rest, 2;
        $rest = '' unless defined $rest;
    }
    @args = split /\s+/, $rest;
    $fmt =~ s/\\n/\n/g;
    $fmt =~ s/\\t/\t/g;
    eval { printf $fmt, @args };
    $LAST_STATUS = 0;
    return 0;
}

# ----------------------------------------------------------------
# cd
# ----------------------------------------------------------------
sub _cmd_cd {
    my ($rest) = @_;
    $rest =~ s/\A\s+//;
    $rest =~ s/\s+\z//;
    if ($rest eq '' || $rest eq '~') {
        $rest = $ENV{'HOME'} || BATsh::Env->get('HOME') || '.';
    }
    unless (chdir($rest)) {
        print STDERR "cd: $rest: No such file or directory\n";
        $LAST_STATUS = 1;
        return 1;
    }
    BATsh::Env->set('PWD', Cwd::cwd());
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
    # set -e, set +e, set -x, set +x: accepted silently
    $LAST_STATUS = 0;
    return 0;
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

    # Extract condition (after 'if', before 'then' or ';')
    my $cond_str = $if_line;
    $cond_str =~ s/\Aif\s+//i;

    # 1-line form: if COND; then BODY [; BODY ...]; fi
    # Detect by presence of "; then " and trailing "; fi" on the same line
    if ($cond_str =~ /\A(.+?)\s*;\s*then\s+(.+?)\s*;\s*fi\s*\z/i) {
        my ($cond_part, $body_part) = ($1, $2);
        my $cond_status = _run_lines($class, [$cond_part], $opts_ref);
        if ($cond_status == 0) {
            _run_lines($class, [split /\s*;\s*/, $body_part], $opts_ref);
        }
        return ($cond_status, $i);
    }

    $cond_str =~ s/\s*;\s*then\s*\z//i;
    $cond_str =~ s/\s+then\s*\z//i;

    my @cond_lines = ($cond_str);
    my @body_lines = ();
    my $state = 'body';   # reading body of if

    while ($i <= $#lines) {
        my $l = $lines[$i]; $i++;
        $l =~ s/\r?\n\z//;
        my $ls = $l; $ls =~ s/\A\s+//;
        my $lc_first = lc( ($ls =~ /\A(\S+)/) ? $1 : '' );

        if ($lc_first eq 'fi') {
            push @branches, [ [@cond_lines], [@body_lines] ];
            last;
        }
        elsif ($lc_first eq 'elif') {
            push @branches, [ [@cond_lines], [@body_lines] ];
            $cond_str = $ls;
            $cond_str =~ s/\Aelif\s+//i;
            $cond_str =~ s/\s*;\s*then\s*\z//i;
            $cond_str =~ s/\s+then\s*\z//i;
            @cond_lines = ($cond_str);
            @body_lines = ();
        }
        elsif ($lc_first eq 'else') {
            push @branches, [ [@cond_lines], [@body_lines] ];
            @body_lines = ();
            # Read until fi
            while ($i <= $#lines) {
                my $el = $lines[$i]; $i++;
                $el =~ s/\r?\n\z//;
                my $els = $el; $els =~ s/\A\s+//;
                if (lc(($els =~ /\A(\S+)/) ? $1 : '') eq 'fi') { last }
                push @body_lines, $el;
            }
            $else_body = [@body_lines];
            last;
        }
        elsif ($lc_first eq 'then') {
            # 'then' on its own line: continue collecting body
            next;
        }
        else {
            push @body_lines, $l;
        }
    }

    # Evaluate branches
    my $status = 0;
    my $executed = 0;
    for my $branch (@branches) {
        my ($cond_ref, $body_ref) = @{$branch};
        my $cond_status = _run_lines($class, $cond_ref, $opts_ref);
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
                if (open(_WH_REDIR_SRC, "< $in_file")) {
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
        my $cond_status = _run_lines($class, [$cond_str], $opts_ref);
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
    my $i = 0; my $sq = 0; my $dq = 0; my $cls = 0;
    my $found = -1;
    while ($i < $n) {
        my $ch = $c[$i];
        if ($sq) { $sq = 0 if $ch eq "'"; $i++; next }
        if ($ch eq "'" && !$dq) { $sq = 1; $i++; next }
        if ($ch eq '"') { $dq = !$dq; $i++; next }
        if (!$sq && !$dq) {
            if    ($ch eq '[') { $cls = 1 }
            elsif ($ch eq ']') { $cls = 0 }
            elsif ($ch eq ')' && !$cls) { $found = $i; last }
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
    my $i = 0; my $sq = 0; my $dq = 0; my $cls = 0;
    while ($i < $n) {
        my $ch = $c[$i];
        if ($sq) { $cur .= $ch; $sq = 0 if $ch eq "'"; $i++; next }
        if ($ch eq "'" && !$dq) { $sq = 1; $cur .= $ch; $i++; next }
        if ($ch eq '"') { $dq = !$dq; $cur .= $ch; $i++; next }
        if (!$sq && !$dq) {
            if    ($ch eq '[') { $cls = 1 }
            elsif ($ch eq ']') { $cls = 0 }
            elsif ($ch eq '|' && !$cls) { push @out, $cur; $cur = ''; $i++; next }
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
            my $file = '';
            while ($j < $n && $chars[$j] !~ /[\s<>]/) { $file .= $chars[$j]; $j++ }
            push @found, [0, 0, $file] if $file ne '';
            $i = $j; next;
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
            my $file = '';
            # Read filename (stop at space unless quoted)
            while ($i < $n && $chars[$i] !~ /[\s<>]/) {
                $file .= $chars[$i]; $i++;
            }
            push @found, [$redir_fd, $append, $file] if $file ne '';
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
        open(_SH_REDIR_SRC, $in_file)
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
        my $mode = $out_app ? '>>' : '>';
        open(_SH_REDIR_DST, "$mode$out_file")
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
        my $mode = $err_app ? '>>' : '>';
        open(_SH_REDIR_DST, "$mode$err_file")
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
sub _split_sh_compound {
    my ($line) = @_;
    my @parts;
    my $cur   = '';
    my $in_sq = 0;
    my $in_dq = 0;
    my $depth = 0;   # $( nesting
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
        if ($ch eq "'" && !$in_dq) { $in_sq = 1; $cur .= $ch; $i++; next }

        # Double-quote toggle
        if ($ch eq '"' && !$in_sq) { $in_dq = !$in_dq; $cur .= $ch; $i++; next }

        # $( nesting inside double-quotes
        if ($in_dq) {
            if ($ch eq '$' && $i+1 < $n && $chars[$i+1] eq '(') { $depth++ }
            elsif ($ch eq ')' && $depth > 0) { $depth-- }
            $cur .= $ch; $i++; next;
        }

        # Track $( nesting outside quotes
        if ($ch eq '$' && $i+1 < $n && $chars[$i+1] eq '(') {
            $depth++; $cur .= $ch; $i++; next;
        }
        if ($ch eq ')' && $depth > 0) {
            $depth--; $cur .= $ch; $i++; next;
        }

        # Inside $(...) don't split on operators
        if ($depth > 0) { $cur .= $ch; $i++; next }

        # Backslash escape
        if ($ch eq '\\') {
            $cur .= $ch; $i++;
            $cur .= $chars[$i] if $i < $n; $i++; next;
        }

        # && operator
        if ($ch eq '&' && $i+1 < $n && $chars[$i+1] eq '&') {
            push @parts, { op => '', cmd => $cur };
            push @parts, { op => '&&', cmd => '' };
            $cur = ''; $i += 2; next;
        }

        # || operator
        if ($ch eq '|' && $i+1 < $n && $chars[$i+1] eq '|') {
            push @parts, { op => '', cmd => $cur };
            push @parts, { op => '||', cmd => '' };
            $cur = ''; $i += 2; next;
        }

        # ; separator (not inside any quote or subst)
        if ($ch eq ';') {
            push @parts, { op => '', cmd => $cur };
            push @parts, { op => ';', cmd => '' };
            $cur = ''; $i++; next;
        }

        $cur .= $ch; $i++;
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

    for my $part (@{$parts}) {
        my $op  = $part->{op};
        my $cmd = $part->{cmd};
        $cmd =~ s/\A\s+//; $cmd =~ s/\s+\z//;

        if ($op eq '') {
            # Execute according to pending operator
            if ($pending_op eq '') {
                $rc = _exec_line($class, $cmd, $opts_ref) if $cmd =~ /\S/;
            }
            elsif ($pending_op eq '&&') {
                if ($LAST_STATUS == 0 && $cmd =~ /\S/) {
                    $rc = _exec_line($class, $cmd, $opts_ref);
                }
            }
            elsif ($pending_op eq '||') {
                if ($LAST_STATUS != 0 && $cmd =~ /\S/) {
                    $rc = _exec_line($class, $cmd, $opts_ref);
                }
            }
            elsif ($pending_op eq ';') {
                $rc = _exec_line($class, $cmd, $opts_ref) if $cmd =~ /\S/;
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
        my $output_f = $is_last ? undef : "${base}_${idx}.tmp";

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
        if (defined $output_f) {
            open(_SH_PIPE_WFH, ">$output_f")
                or do {
                    if ($saved_in) {
                        open(STDIN, '<&_SH_PIPE_SAVIN'); close(_SH_PIPE_SAVIN);
                    }
                    warn "SH pipe: open $output_f: $!\n";
                    last;
                };
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
        }

        $input_f = $output_f;
    }

    unlink $input_f if defined $input_f && -f $input_f;
    return $rc;
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
    my @matches = glob($word);
    return @matches ? @matches : ($word);
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
        # Split on ; to get individual commands
        for my $part (split /;/, $inline) {
            $part =~ s/\A\s+//; $part =~ s/\s+\z//;
            push @body, $part if $part =~ /\S/;
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
    BATsh::Env->sync_to_env();
    my $rc = system($full);
    $LAST_STATUS = ($rc == 0) ? 0 : (($rc >> 8) || 1);
    return $LAST_STATUS;
}

# ----------------------------------------------------------------
# Background execution helpers (v1)
# ----------------------------------------------------------------
# _split_trailing_bg: detect an unquoted single & at the very end of a
# line.  Returns (1, $line_without_amp) when present, else (0, $line).
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
sub _bg_launch {
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

        # Unquoted << (but not <<<, which is a here-string: not supported)
        if (!$in_dq && $ch eq '<' && $i+1 < $n && $chars[$i+1] eq '<'
                && !($i+2 < $n && $chars[$i+2] eq '<')) {
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
    for my $b (@body) { $text .= $b . "\n" }

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
    for my $c (split //, $v) {
        if ($in_sq) { if ($c eq "'") { $in_sq = 0 } else { $out .= $c } next }
        if ($c eq "'" && !$in_dq) { $in_sq = 1; next }
        if ($c eq '"' && !$in_sq) { $in_dq = !$in_dq; next }
        $out .= $c;
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
    my @chars = split //, $s;
    my $n     = scalar @chars;
    my $i     = 0;
    while ($i < $n) {
        my $c = $chars[$i];
        if ($in_sq) { $cur .= $c; $in_sq = 0 if $c eq "'"; $have = 1; $i++; next }
        if ($c eq "'" && !$in_dq) { $in_sq = 1; $cur .= $c; $have = 1; $i++; next }
        if ($c eq '"' && !$in_sq) { $in_dq = !$in_dq; $cur .= $c; $have = 1; $i++; next }
        if (!$in_sq && !$in_dq && $c =~ /\s/) {
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
    while ($rest =~ s/\A(-[A-Za-z]+)\s+//) {
        my $flag = $1;
        if    ($flag =~ /A/) { $type = 'assoc' }
        elsif ($flag =~ /a/) { $type = 'indexed' unless defined $type }
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
        elsif ($rest =~ /\A([A-Za-z_][A-Za-z0-9_]*)=(\S*)\s*(.*)\z/s) {
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
                BATsh::Env->set($name, $val);
            }
            $rest = $tail;
        }
        elsif ($rest =~ /\A([A-Za-z_][A-Za-z0-9_]*)\s*(.*)\z/s) {
            my ($name, $tail) = ($1, $2);
            my $k = _arr_name($name);
            $_SH_ARRAY{$k}      = {} unless exists $_SH_ARRAY{$k};
            $_SH_ARRAY_TYPE{$k} = (defined $type ? $type : 'indexed');
            $rest = $tail;
        }
        else {
            last;
        }
    }
    $LAST_STATUS = 0;
    return 0;
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
  cd, pwd, exit, true, false, :, read, shift, local, set
  trap 'cmd' SIG... / trap - SIG / trap '' SIG / trap [-p]
  $(( arithmetic )) -- supports $1..$9 positional params
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

Here-strings (C<E<lt>E<lt>E<lt> word>) are not supported; C<E<lt>E<lt>E<lt>>
is deliberately not treated as a here-document opener.

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

=head1 AUTHOR

INABA Hitoshi E<lt>ina.cpan@gmail.comE<gt>

=head1 LICENSE

Same as Perl itself.

=cut
