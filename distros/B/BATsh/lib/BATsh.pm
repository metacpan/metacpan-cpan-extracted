package BATsh;
######################################################################
#
# BATsh - Bilingual Shell for cmd.exe and bash in one script
#
# https://metacpan.org/dist/BATsh
#
# Copyright (c) 2026 INABA Hitoshi <ina.cpan@gmail.com>
#
# This version implements both cmd.exe and sh/bash command sets
# entirely in Perl.  No external cmd.exe, bash, or sh is required.
#
######################################################################

use 5.00503;
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }

use File::Spec ();
BEGIN { eval { require Cwd } }
use Carp qw(croak);
use vars qw($VERSION);
$VERSION = '0.08';
$VERSION = $VERSION;

require BATsh::MB;
require BATsh::Env;
require BATsh::CMD;
require BATsh::SH;

###############################################################################
# Architecture
###############################################################################
#
# BATsh is a bilingual shell interpreter.
#
# It splits a script into CMD sections and SH sections, then executes
# each section using its own pure-Perl interpreter:
#
#   BATsh::CMD  -- cmd.exe command set (SET, ECHO, IF, FOR, GOTO, ...)
#   BATsh::SH   -- sh/bash command set (echo, export, if/fi, for/done, ...)
#   BATsh::Env  -- shared variable store (bridge between both modes)
#
# MODE DETECTION: first non-empty, non-comment token of each section.
#   CMD: token is [A-Z 0-9 _ - \ / : . @ %]+ with at least one A-Z
#   SH:  anything else
#
# SECTION BOUNDARY:
#   CMD: parenthesis ( ) depth returns to 0
#   SH:  keyword depth (if/fi, for/done, ...) returns to 0
#
# ENV BRIDGE:
#   BATsh::Env::STORE is the single variable table.
#   CMD %VAR% and SH $VAR both read/write the same store.
#
###############################################################################

###############################################################################
# Global state
###############################################################################
my $_TMPCOUNT = 0;

# Subroutine registry: { LABEL => \@lines }
my %_SUBROUTINES = ();

# Script-level exit state: set (to the exit code) the moment an SH "exit"
# or a CMD "EXIT" executes in any section, including inside a sourced file
# or a CALL'd subroutine.  Once set, no further section is executed, and
# run()/run_string()/run_lines() return this code.  Reset at the start of
# each top-level run.
my $_SCRIPT_EXIT = undef;

###############################################################################
# Constructor
###############################################################################
sub new {
    my ($class, %args) = @_;
    BATsh::Env::init();
    return bless { verbose => $args{verbose} || 0 }, $class;
}

###############################################################################
# Public run interface
###############################################################################
sub run {
    my ($class_or_self, $file, %args) = @_;
    unless (-f $file) { croak "BATsh->run: file not found: $file" }
    local *SRCFH;
    open(SRCFH, $file) or croak "BATsh->run: cannot open $file: $!";
    my @lines = <SRCFH>;
    close(SRCFH);
    _prepare_source(\@lines, $args{encoding});
    _ensure_env_init();
    # Set batch positional parameters: %0 = script path, %1..%9 = args, %* = all args
    my @script_args = defined($args{args}) ? @{$args{args}} : ();
    _set_batch_args($file, @script_args);
    $_SCRIPT_EXIT = undef;
    BATsh::SH::reset_sh_options() if defined &BATsh::SH::reset_sh_options;
    _process_lines(@lines);
    my $rc = _final_status();
    BATsh::SH::fire_exit_trap("BATsh::SH") if defined &BATsh::SH::fire_exit_trap;
    return $rc;
}

sub run_string {
    my ($class_or_self, $source, %args) = @_;
    croak "BATsh->run_string: source required" unless defined $source;
    my @lines = map { "$_\n" } split(/\n/, $source, -1);
    _prepare_source(\@lines, $args{encoding});
    _ensure_env_init();
    # Optional positional parameters (used by "batsh - args..." and by
    # callers that feed a script body as a string): %0 defaults to '-'.
    if (defined $args{args}) {
        _set_batch_args(defined $args{script_name} ? $args{script_name} : '-',
                        @{$args{args}});
    }
    $_SCRIPT_EXIT = undef;
    BATsh::SH::reset_sh_options() if defined &BATsh::SH::reset_sh_options;
    _process_lines(@lines);
    my $rc = _final_status();
    BATsh::SH::fire_exit_trap("BATsh::SH") if defined &BATsh::SH::fire_exit_trap;
    return $rc;
}

sub run_lines {
    my ($class_or_self, @lines) = @_;
    _prepare_source(\@lines, undef);
    _ensure_env_init();
    $_SCRIPT_EXIT = undef;
    BATsh::SH::reset_sh_options() if defined &BATsh::SH::reset_sh_options;
    _process_lines(@lines);
    my $rc = _final_status();
    BATsh::SH::fire_exit_trap("BATsh::SH") if defined &BATsh::SH::fire_exit_trap;
    return $rc;
}

# ----------------------------------------------------------------
# _final_status -- the exit status of the run just finished: the code of
# an executed exit/EXIT if any, else the last command's status.  After
# every section flush both interpreters hold the same value (see
# _flush_cmd/_flush_sh), so the SH side is authoritative here.
# ----------------------------------------------------------------
sub _final_status {
    return $_SCRIPT_EXIT if defined $_SCRIPT_EXIT;
    return BATsh::SH::get_status();
}

# ----------------------------------------------------------------
# last_status -- public accessor: the unified $? / %ERRORLEVEL% value.
# ----------------------------------------------------------------
sub last_status { return _final_status() }

sub _ensure_env_init {
    # Init only once per process
    BATsh::Env::init() unless %BATsh::Env::STORE;
}

###############################################################################
# set_encoding -- select the script encoding for multibyte-safe execution
#   BATsh->set_encoding('cp932');   # also: sjis gbk uhc big5 utf8 none auto
# The default is 'auto': a non-UTF-8 script containing bytes >= 0x80 is
# treated as CP932 and guarded (see BATsh::MB).  The environment variable
# BATSH_ENCODING, when set, overrides the default before the first run.
###############################################################################
my $_ENV_ENCODING_APPLIED = 0;

sub set_encoding {
    my ($class_or_self, $enc) = @_;
    $enc = $class_or_self
        if !defined($enc) && defined($class_or_self)
        && $class_or_self !~ /\ABATsh\b/;
    $_ENV_ENCODING_APPLIED = 1;   # explicit choice beats BATSH_ENCODING
    return BATsh::MB::set_encoding($enc);
}

sub encoding { return BATsh::MB::encoding() }

###############################################################################
# _prepare_source -- per-run encoding setup on the raw script lines
#   1. strip a UTF-8 BOM from the first line
#   2. apply an explicit per-run encoding, or BATSH_ENCODING (once),
#      or leave the current ('auto' by default) setting in place
#   3. under 'auto', detect the source encoding and activate the guard
#   4. guard-transform every line in place (identity when inactive)
###############################################################################
sub _prepare_source {
    my ($lines_ref, $encoding) = @_;
    $lines_ref->[0] = BATsh::MB::strip_bom($lines_ref->[0]) if @{$lines_ref};
    if (defined $encoding && $encoding ne '') {
        BATsh::MB::set_encoding($encoding);
        $_ENV_ENCODING_APPLIED = 1;
    }
    elsif (!$_ENV_ENCODING_APPLIED
        && defined $ENV{BATSH_ENCODING} && $ENV{BATSH_ENCODING} ne '') {
        BATsh::MB::set_encoding($ENV{BATSH_ENCODING});
        $_ENV_ENCODING_APPLIED = 1;
    }
    BATsh::MB::activate_for(join('', @{$lines_ref}));
    if (BATsh::MB::active()) {
        for my $l (@{$lines_ref}) { $l = BATsh::MB::enc($l) }
    }
    return 1;
}

###############################################################################
# _set_batch_args -- populate %0..%9 and %* in the Env store
#   %0  = script path (as passed to run())
#   %1  = first argument, ..., %9 = ninth argument
#   %*  = all arguments joined by single space (does not include %0)
###############################################################################
sub _set_batch_args {
    my ($script, @args) = @_;
    # Arguments arrive as RAW bytes from outside the interpreter
    # (command line / caller); guard them before they enter the store.
    @args = map { BATsh::MB::enc(defined $_ ? $_ : '') } @args;
    # Normalise $0: resolve to absolute path using File::Spec
    my $abs_script = defined $script ? $script : '';
    if ($abs_script ne '' && !File::Spec->file_name_is_absolute($abs_script)) {
        my $cwd = defined(&Cwd::cwd) ? Cwd::cwd() : '.';
        $abs_script = File::Spec->catfile($cwd, $abs_script);
    }
    BATsh::Env->set('%0', BATsh::MB::enc($abs_script));
    for my $n (1 .. 9) {
        BATsh::Env->set("%$n", defined($args[$n - 1]) ? $args[$n - 1] : '');
    }
    BATsh::Env->set('%*', join(' ', @args));
}

###############################################################################
# classify_token
###############################################################################
sub classify_token {
    my ($class_or_token, $token) = @_;
    unless (defined $token) { $token = $class_or_token }
    if ($token =~ /\A[A-Z0-9_\-\\\/\.:@%]+\z/ && $token =~ /[A-Z]/) {
        return 'CMD';
    }
    return 'SH';
}

###############################################################################
# Line parser
# Returns ($mode, $stripped_line, $first_token)
###############################################################################
sub _parse_line {
    my ($line) = @_;
    (my $s = $line) =~ s/\r?\n\z//;
    return ('EMPTY', $s, '')   if $s =~ /\A\s*\z/;
    return ('COMMENT', $s, '') if $s =~ /\A\s*(?:::|\@?REM(?:\s|\z))/i;
    return ('COMMENT', $s, '') if $s =~ /\A\s*#(?!!)/;
    (my $t = $s) =~ s/\A\s+//;
    my $first = ($t =~ /\A(\S+)/) ? $1 : '';
    return (classify_token($first), $s, $first);
}

###############################################################################
# CMD section depth: count unquoted ( )
###############################################################################
sub _cmd_paren_delta {
    my ($line) = @_;
    my ($delta, $in_q) = (0, 0);
    for my $ch (split //, $line) {
        if ($ch eq '"')     { $in_q = !$in_q }
        elsif (!$in_q) {
            $delta++ if $ch eq '(';
            $delta-- if $ch eq ')';
        }
    }
    return $delta;
}

###############################################################################
# SH section depth
###############################################################################
my %_SH_OPEN  = map { $_ => 1 } qw(if for while until case function select);
my %_SH_CLOSE = map { $_ => 1 } qw(fi done esac);

# Net SH block-depth change for an ENTIRE line.
#
# A single physical line may both open and close a block, e.g.
#   for i in 1 2 3; do echo $i; done      (net 0)
#   while COND; do ...; done; done         (net -1, nested close)
# Looking only at the first token (as earlier versions did) counted the
# leading "for"/"while" but never the inline "done", so the SH section was
# left open and a following CMD line (e.g. ECHO ...%VAR%...) was wrongly
# absorbed into the SH section and run by the SH interpreter.
#
# Opener keywords (if for while until case function select) and "{" add 1;
# closer keywords (fi done esac) and "}" subtract 1, but only when they are in
# command position (line start, or just after ; & | ( ) { } or do/then/else/
# elif).  Single- and double-quoted text, $( ... ) command substitutions and
# `...` backticks are skipped so that a "done" inside a string or substitution
# does not affect the depth.  Perl 5.005_03 compatible (no regex features
# beyond character classes; substr/index style scanning).
sub _sh_depth_delta {
    my ($line) = @_;
    return 0 unless defined $line;

    # Fast path: a bare single keyword token (the common multi-line case).
    if ($line !~ /[\s;&|(){}'"`]/) {
        my $l = lc($line);
        return  1 if exists $_SH_OPEN{$l};
        return -1 if exists $_SH_CLOSE{$l};
        return  0;
    }

    my $delta  = 0;
    my $cmdpos = 1;            # next bareword starts a new statement?
    my $i      = 0;
    my $n      = length($line);
    while ($i < $n) {
        my $c = substr($line, $i, 1);

        if ($c eq "'") {                      # single-quoted region
            $i++;
            $i++ while $i < $n && substr($line, $i, 1) ne "'";
            $i++; $cmdpos = 0; next;
        }
        if ($c eq '"') {                      # double-quoted region
            $i++;
            while ($i < $n && substr($line, $i, 1) ne '"') {
                if (substr($line, $i, 1) eq '\\') { $i += 2; next }
                $i++;
            }
            $i++; $cmdpos = 0; next;
        }
        if ($c eq '`') {                      # backtick substitution
            $i++;
            $i++ while $i < $n && substr($line, $i, 1) ne '`';
            $i++; $cmdpos = 0; next;
        }
        if ($c eq '$' && $i + 1 < $n && substr($line, $i + 1, 1) eq '(') {
            $i += 2;                          # $( ... ) -- skip balanced parens
            my $d = 1;
            while ($i < $n && $d > 0) {
                my $ch = substr($line, $i, 1);
                $d++ if $ch eq '(';
                $d-- if $ch eq ')';
                $i++;
            }
            $cmdpos = 0; next;
        }
        if ($c =~ /\s/)                 { $i++; next }
        if ($c eq ';' || $c eq '&' || $c eq '|') { $cmdpos = 1; $i++; next }
        if ($c eq '(')                 { $cmdpos = 1; $i++; next }
        if ($c eq ')')                 { $cmdpos = 1; $i++; next }
        if ($c eq '{') { $delta++ if $cmdpos; $cmdpos = 1; $i++; next }
        if ($c eq '}') { $delta-- if $cmdpos; $cmdpos = 1; $i++; next }

        # Bareword
        my $word = '';
        while ($i < $n) {
            my $wc = substr($line, $i, 1);
            last if $wc =~ /[\s;&|(){}'"`]/;
            $word .= $wc; $i++;
        }
        if ($cmdpos) {
            my $lw = lc($word);
            if    (exists $_SH_OPEN{$lw})  { $delta++ }
            elsif (exists $_SH_CLOSE{$lw}) { $delta-- }
            # do/then/else/elif keep the FOLLOWING word in command position so
            # that an opener directly after them (e.g. "do for ...") is counted.
            $cmdpos = ($lw eq 'do' || $lw eq 'then'
                    || $lw eq 'else' || $lw eq 'elif') ? 1 : 0;
        }
        else {
            $cmdpos = 0;
        }
    }
    return $delta;
}

###############################################################################
# Subroutine extraction
###############################################################################
sub _extract_subroutines {
    my (@lines) = @_;
    my @out = (); my $in_sub = ''; my @sub_body = ();

    # Determine which :LABEL lines are subroutine ENTRY points (to be lifted
    # out of the main stream and stored in %_SUBROUTINES) versus ordinary
    # GOTO labels (which stay in the stream for the CMD interpreter).
    #
    # Two independent signals are unioned:
    #
    #   (a) CALL targets: any label named by a "CALL :LABEL" anywhere in the
    #       script is an entry point.  This is the decisive signal -- a label
    #       you CALL is a subroutine -- and it lets a subroutine contain its
    #       own internal GOTO labels without being mis-split.
    #
    #   (b) The RET heuristic: a label whose block ends in RET/RETURN before
    #       the next label.  Kept for backward compatibility so a subroutine
    #       invoked only indirectly is still recognised.
    #
    # A label is opened as a subroutine ONLY at the top level (not while
    # already inside a subroutine body); once inside a body, every :LABEL is
    # an internal label that travels with the body so that GOTO within the
    # subroutine resolves, and only RET/RETURN closes the body.
    my %is_sub_label = ();

    # (a) CALL targets (matched anywhere on the line, e.g. "IF .. CALL :X").
    for my $line (@lines) {
        (my $s = $line) =~ s/\r?\n\z//;
        while ($s =~ /\bCALL\s+:([A-Za-z_][A-Za-z0-9_]*)/ig) {
            $is_sub_label{uc($1)} = 1;
        }
    }

    # (b) RET heuristic.
    {
        my $cur = '';
        for my $line (@lines) {
            (my $s = $line) =~ s/\r?\n\z//;
            $s =~ s/\A\s+//;
            if ($s =~ /\A:([A-Za-z_][A-Za-z0-9_]*)\s*\z/) {
                $cur = uc($1);
            }
            elsif ($cur ne '' && $s =~ /\A(?:RET|RETURN)\s*\z/i) {
                $is_sub_label{$cur} = 1;
                $cur = '';
            }
            elsif ($cur ne '' && $s =~ /\A:([A-Za-z_][A-Za-z0-9_]*)\s*\z/) {
                # New label before RET: previous one is a GOTO label, not sub
                $cur = uc($1);
            }
        }
    }

    for my $line (@lines) {
        (my $s = $line) =~ s/\r?\n\z//;
        $s =~ s/\A\s+//;
        if ($s =~ /\A:([A-Za-z_][A-Za-z0-9_]*)\s*\z/) {
            my $lbl = uc($1);
            if ($in_sub ne '') {
                # Inside a subroutine: this is an internal label of the body
                # (a GOTO target), not a new subroutine.  Keep it with the
                # body so the CMD interpreter can resolve GOTO :internal.
                push @sub_body, $line;
                next;
            }
            if ($is_sub_label{$lbl}) {
                # Top-level subroutine entry: lift it out of the main stream.
                $in_sub = $lbl; @sub_body = ();
                next;   # remove the entry-label line from the stream
            }
            # Top-level GOTO label: keep in stream for the CMD interpreter.
            push @out, $line;
            next;
        }
        if ($in_sub ne '') {
            if ($s =~ /\A(?:RET|RETURN)\s*\z/i) {
                $_SUBROUTINES{$in_sub} = [@sub_body];
                $in_sub = ''; @sub_body = ();
            }
            else {
                push @sub_body, $line;
            }
            next;
        }
        push @out, $line;
    }
    $_SUBROUTINES{$in_sub} = [@sub_body] if $in_sub ne '';
    return @out;
}

###############################################################################
# call_sub / source_file
###############################################################################
sub call_sub {
    my ($class_or_self, $label, @args) = @_;
    $label = uc($label); $label =~ s/^://;
    croak "BATsh->call_sub: undefined subroutine :$label"
        unless exists $_SUBROUTINES{$label};

    # --- Save the caller's positional-parameter frame -----------------
    # CALL :label is a true subroutine call: the callee gets its own
    # %0..%9 / %* (and the SH-side BATSH_ARG* mirror), and the caller's
    # parameters are restored on return.  An undef snapshot means the key
    # was absent and must be removed again on restore.
    my @frame_keys = ('%0','%1','%2','%3','%4','%5','%6','%7','%8','%9','%*',
                      'BATSH_ARGC',
                      'BATSH_ARG1','BATSH_ARG2','BATSH_ARG3','BATSH_ARG4',
                      'BATSH_ARG5','BATSH_ARG6','BATSH_ARG7','BATSH_ARG8',
                      'BATSH_ARG9');
    my %saved;
    for my $k (@frame_keys) {
        $saved{$k} = exists $BATsh::Env::STORE{$k} ? $BATsh::Env::STORE{$k}
                                                   : undef;
    }

    # --- Install the subroutine's own arguments -----------------------
    # %0 is the label token (":LABEL"), matching cmd.exe, so that %~..0
    # modifiers and %0 inside the subroutine refer to the label, not the
    # outer script.  %1..%9 are the call arguments; %* is their join.
    BATsh::Env->set('%0', ":$label");
    for my $n (1 .. 9) {
        BATsh::Env->set("%$n", defined($args[$n-1]) ? $args[$n-1] : '');
    }
    BATsh::Env->set('%*', join(' ', @args));

    # SH-side mirror so a subroutine body written in SH mode still sees
    # $1..$9 / $@.  Keys beyond the supplied argument count are removed so
    # a shorter call does not inherit the caller's stale BATSH_ARG* values.
    $BATsh::Env::STORE{'BATSH_ARGC'} = scalar @args;
    for my $n (1 .. 9) {
        if ($n <= scalar @args) {
            $BATsh::Env::STORE{"BATSH_ARG$n"} = $args[$n-1];
        }
        else {
            delete $BATsh::Env::STORE{"BATSH_ARG$n"};
        }
    }

    # --- Run the body, then always restore the caller frame -----------
    my $ok  = eval { _process_lines(@{$_SUBROUTINES{$label}}); 1 };
    my $err = $@;
    for my $k (@frame_keys) {
        if (defined $saved{$k}) { $BATsh::Env::STORE{$k} = $saved{$k} }
        else                    { delete $BATsh::Env::STORE{$k} }
    }
    die $err unless $ok;
    return 1;
}

sub source_file {
    my ($class_or_self, $file) = @_;
    # The filename may arrive guard-transformed (from a CALL/source line
    # inside a DBCS script); un-guard it before touching the filesystem.
    $file = BATsh::MB::dec($file);
    croak "BATsh->source_file: file not found: $file" unless -f $file;
    local *SFHH;
    open(SFHH, $file) or croak "BATsh->source_file: cannot open $file: $!";
    my @src = <SFHH>;
    close(SFHH);
    _prepare_source(\@src, undef);
    _process_lines(@src);
    return 1;
}

###############################################################################
# SETLOCAL / ENDLOCAL  (public API)
###############################################################################
sub setlocal  { BATsh::Env::setlocal()  }
sub endlocal  { BATsh::Env::endlocal()  }

###############################################################################
# _exec_cmd_section -- run CMD lines through BATsh::CMD
###############################################################################
sub _exec_cmd_section {
    my (@lines) = @_;
    return if defined $_SCRIPT_EXIT;   # exit/EXIT already executed
    # Handle BATsh-native directives before CMD interpreter
    my @batch = ();
    for my $line (@lines) {
        (my $s = $line) =~ s/\r?\n\z//;
        $s =~ s/\A\s+//;
        if ($s =~ /\ASETLOCAL(?:\s+(.*))?\z/i) {
            my $opts = defined $1 ? $1 : '';
            # Pass the whole line through to CMD interpreter so it sees
            # ENABLEDELAYEDEXPANSION etc; also update Env flags here.
            push @batch, $line;
            next;
        }
        if ($s =~ /\AENDLOCAL\s*\z/i) {
            # Handled inside CMD.pm / _dispatch
            push @batch, $line;
            next;
        }
        # NOTE: CALL :label and CALL file.batsh are intentionally NOT
        # intercepted here.  They are handled by the CMD interpreter's
        # _cmd_call (which delegates to call_sub / source_file).  Letting
        # CALL stay inside the batch keeps the whole CMD section in one
        # exec_block, so a GOTO whose loop body contains a CALL still finds
        # its label, and a subroutine body may use its own internal labels.
        push @batch, $line;
    }
    _flush_cmd(\@batch) if @batch;
}

sub _flush_cmd {
    my ($lines_ref) = @_;
    return unless @{$lines_ref};
    return if defined $_SCRIPT_EXIT;
    BATsh::CMD::exec_block('BATsh::CMD', $lines_ref,
        _batsh => __PACKAGE__,
        _pushd_stack => [],
    );
    # Status bridge: mirror the CMD-side ERRORLEVEL into the SH-side $?
    # so the next SH section sees the outcome of this CMD section.
    BATsh::SH::set_status(BATsh::CMD::_get_errorlevel());
    # EXIT executed: terminate the whole script with ERRORLEVEL.
    if (BATsh::CMD::_exit_requested()) {
        BATsh::CMD::_clear_exit_requested();
        $_SCRIPT_EXIT = BATsh::CMD::_get_errorlevel();
    }
}

###############################################################################
# _exec_sh_section -- run SH lines through BATsh::SH
###############################################################################
sub _exec_sh_section {
    my (@lines) = @_;
    return if defined $_SCRIPT_EXIT;   # exit/EXIT already executed
    my @batch = ();
    for my $line (@lines) {
        (my $s = $line) =~ s/\r?\n\z//;
        $s =~ s/\A\s+//;
        if ($s =~ /\A(?:source|\.)\s+(\S+\.batsh)/) {
            my $bfile = $1;
            _flush_sh(\@batch) if @batch; @batch = ();
            eval { source_file('', $bfile) };
            warn $@ if $@;
            next;
        }
        push @batch, $line;
    }
    _flush_sh(\@batch) if @batch;
}

sub _flush_sh {
    my ($lines_ref) = @_;
    return unless @{$lines_ref};
    return if defined $_SCRIPT_EXIT;
    BATsh::SH::exec_block('BATsh::SH', $lines_ref,
        _batsh => __PACKAGE__,
    );
    # Status bridge: mirror the SH-side $? into the CMD-side ERRORLEVEL
    # so the next CMD section sees the outcome of this SH section
    # (ECHO %ERRORLEVEL%, IF ERRORLEVEL n, ...).
    BATsh::CMD::_set_errorlevel(BATsh::SH::get_status());
    # exit executed: terminate the whole script with its code.
    my $ec = BATsh::SH::exit_code_pending();
    $_SCRIPT_EXIT = $ec if defined $ec;
}

###############################################################################
# _process_lines -- main dispatcher
###############################################################################
sub _process_lines {
    my (@source) = @_;
    @source = _extract_subroutines(@source);

    my @pending = (); my $cur_mode = ''; my $depth = 0;

    # Here-document tracking: while a here-document body is being collected,
    # body lines are appended to the current section verbatim and are NOT
    # reclassified (so an uppercase-leading body line is not misrouted to CMD).
    # Activation is deferred by one line so the trigger line itself is
    # classified normally.
    my $hd_delim         = undef;   # active delimiter (collecting body)
    my $hd_dash          = 0;
    my $pending_hd_delim = undef;   # set on the trigger line, activated next iter
    my $pending_hd_dash  = 0;

    for my $raw (@source) {
        chomp $raw;

        # Promote a pending here-document to active (trigger line already pushed)
        if (defined $pending_hd_delim) {
            $hd_delim         = $pending_hd_delim;
            $hd_dash          = $pending_hd_dash;
            $pending_hd_delim = undef;
        }

        # Collecting a here-document body: pass through unclassified.
        if (defined $hd_delim) {
            push @pending, $raw;
            my $probe = $raw;
            $probe =~ s/\A\t+// if $hd_dash;
            $hd_delim = undef if $probe eq $hd_delim;
            next;
        }

        my ($mode, $line, $first) = _parse_line($raw);

        # Detect a here-document opener on an SH line; defer activation so the
        # trigger line is classified normally this iteration.
        if ($mode eq 'SH') {
            my @hd = BATsh::SH::_hd_detect($raw);
            if (@hd) {
                $pending_hd_delim = $hd[2];
                $pending_hd_dash  = $hd[1];
            }
        }

        if ($mode eq 'EMPTY' || $mode eq 'COMMENT') {
            # A comment carries no execution effect, so it must never be handed
            # to an interpreter verbatim.  A CMD-style comment (":: ..." or
            # "REM ...") carried into an SH section would be dispatched to the
            # external shell (SH treats only "#" as a comment), and any "( )" or
            # other shell metacharacter in the comment then makes /bin/sh fail
            # with a syntax error.  The reverse ("# ..." into CMD) is likewise
            # not a CMD comment.  Routing it as a BLANK line is skipped
            # identically by both interpreters and in every nesting depth, and
            # avoids the real cmd.exe quirk of "::" inside a "( )" block.
            push @pending, '' if $cur_mode ne '';
            next;
        }

        if ($cur_mode eq '') {
            $cur_mode = $mode; $depth = 0;
            push @pending, $line;
            $depth += ($mode eq 'CMD') ? _cmd_paren_delta($line) : _sh_depth_delta($line);
        }
        elsif ($mode eq $cur_mode) {
            push @pending, $line;
            $depth += ($mode eq 'CMD') ? _cmd_paren_delta($line) : _sh_depth_delta($line);
            $depth = 0 if $depth < 0;
        }
        else {
            if ($depth > 0) {
                push @pending, $line;
                $depth += ($cur_mode eq 'CMD') ? _cmd_paren_delta($line) : _sh_depth_delta($line);
                $depth = 0 if $depth < 0;
            }
            else {
                _flush_section($cur_mode, @pending) if @pending;
                @pending = ($line); $cur_mode = $mode; $depth = 0;
                $depth += ($mode eq 'CMD') ? _cmd_paren_delta($line) : _sh_depth_delta($line);
            }
        }
    }
    _flush_section($cur_mode, @pending) if @pending;
}

sub _flush_section {
    my ($mode, @lines) = @_;
    return unless @lines;
    if ($mode eq 'CMD') { _exec_cmd_section(@lines) }
    else                { _exec_sh_section(@lines) }
}

###############################################################################
# REPL
###############################################################################
sub repl {
    my ($class_or_self) = @_;
    _ensure_env_init();
    $_SCRIPT_EXIT = undef;
    BATsh::SH::reset_sh_options() if defined &BATsh::SH::reset_sh_options;
    print "BATsh $VERSION - Bilingual Shell\n";
    print "Uppercase => CMD mode, lowercase => SH mode. EXIT/exit to quit.\n\n";

    my (@buf, $depth, $cur_mode) = ((), 0, '');
    my ($hd_delim, $hd_dash, $pending_hd_delim, $pending_hd_dash)
        = (undef, 0, undef, 0);
    while (1) {
        print $depth > 0 || defined($hd_delim) ? '    +> ' : 'BATsh> ';
        my $line = <STDIN>;
        last unless defined $line;
        chomp $line;

        # Guard-transform DBCS input (auto-activates on first DBCS line)
        BATsh::MB::activate_for($line);
        $line = BATsh::MB::enc($line);

        # Promote pending here-document (trigger already buffered)
        if (defined $pending_hd_delim) {
            $hd_delim = $pending_hd_delim; $hd_dash = $pending_hd_dash;
            $pending_hd_delim = undef;
        }
        # Collecting here-document body: buffer verbatim, do not flush/classify
        if (defined $hd_delim) {
            push @buf, $line;
            my $probe = $line;
            $probe =~ s/\A\t+// if $hd_dash;
            $hd_delim = undef if $probe eq $hd_delim;
            if (!defined($hd_delim) && $depth == 0) {
                _flush_section($cur_mode, @buf);
                @buf = (); $cur_mode = ''; $depth = 0;
                last if defined $_SCRIPT_EXIT;   # "exit N" ends the REPL
            }
            next;
        }

        if ($line =~ /\A\s*(?:EXIT|exit)\s*\z/) { print "Bye.\n"; last }
        next if $depth == 0 && $line =~ /\A\s*\z/;
        push @buf, $line;
        my (undef, undef, $first) = _parse_line($line);
        $cur_mode = classify_token($first) if $depth == 0 && $cur_mode eq '';
        # Detect here-document opener (SH only); defer activation one line
        if ($cur_mode eq 'SH') {
            my @hd = BATsh::SH::_hd_detect($line);
            if (@hd) { $pending_hd_delim = $hd[2]; $pending_hd_dash = $hd[1] }
        }
        $depth += ($cur_mode eq 'CMD') ? _cmd_paren_delta($line) : _sh_depth_delta($line);
        $depth = 0 if $depth < 0;
        if ($depth == 0 && !defined($pending_hd_delim)) {
            _flush_section($cur_mode, @buf);
            @buf = (); $cur_mode = ''; $depth = 0;
            last if defined $_SCRIPT_EXIT;   # "exit N" / "EXIT N" ends the REPL
        }
    }
    return _final_status();
}

###############################################################################
# Accessors
###############################################################################
sub version      { return $VERSION }
sub sh_available { return 1 }   # always: built-in SH interpreter

###############################################################################
# main -- command-line entry point (used by bin/batsh.pl and the modulino).
# Returns the process exit code.
###############################################################################
sub main {
    my ($class_or_self, @argv) = @_;
    BATsh::Env::init();
    # --encoding=ENC / --encoding ENC : cp932 sjis gbk uhc big5 utf8 none auto
    while (@argv && $argv[0] =~ /\A--encoding(?:=(.*))?\z/) {
        my $e = $1;
        shift @argv;
        $e = shift @argv if !defined $e && @argv;
        BATsh->set_encoding($e) if defined $e;
    }
    if (@argv && ($argv[0] eq '--version' || $argv[0] eq '-v')) {
        print "BATsh $VERSION\n";
        return 0;
    }
    if (@argv && ($argv[0] eq '--help' || $argv[0] eq '-h')) {
        print <<"END_OF_USAGE";
usage: batsh [--encoding=ENC] script.batsh [args...]
       batsh [--encoding=ENC] -            (read the script from STDIN)
       batsh [--encoding=ENC] -e 'source'  (run inline source)
       batsh                               (interactive REPL)
       batsh --version | --help

ENC: cp932 sjis gbk uhc big5 utf8 none auto (default: auto)
The process exit code is the script's exit code (exit N / EXIT [/B] N,
or the status of the last command).
END_OF_USAGE
        return 0;
    }
    if (@argv == 0) { return BATsh->repl() }
    if ($argv[0] eq '-e') {
        shift @argv;
        return BATsh->run_string(join("\n", @argv));
    }
    if ($argv[0] eq '-') {
        shift @argv;
        my @lines = <STDIN>;
        return BATsh->run_string(join('', @lines),
                                 script_name => '-', args => [@argv]);
    }
    my $f = shift @argv;
    return BATsh->run($f, args => [@argv]);
}

###############################################################################
# Run as script
###############################################################################
unless (caller) {
    exit(BATsh->main(@ARGV));
}

1;

__END__

=head1 NAME

BATsh - Bilingual Shell for cmd.exe and bash in one script

=head1 VERSION

Version 0.08

=head1 SYNOPSIS

  use BATsh;

  # Run a bilingual .batsh script; the return value is the script's
  # exit status ("exit 3" -> 3, "EXIT /B 5" -> 5, else last command)
  my $rc = BATsh->run('myscript.batsh');
  BATsh->run('myscript.batsh', args => ['arg1', 'arg2']);
  print BATsh->last_status;    # same value, queried later

  # From the command line (bin/batsh.pl is installed as "batsh"):
  #   batsh script.batsh arg1 arg2      exit code = script status
  #   batsh -e 'echo hi'                run inline source
  #   ... | batsh - arg1                read the script from STDIN
  #   batsh --help / --version

  # CP932 (Shift_JIS) scripts on Japanese Windows: auto-detected,
  # or select the encoding explicitly
  BATsh->run('nihongo.batsh', encoding => 'cp932');
  BATsh->set_encoding('cp932');    # also: sjis gbk uhc big5 utf8 auto

  # Run source inline
  BATsh->run_string('echo hello from sh');
  BATsh->run_string("SET MSG=hello\nECHO %MSG%");

  # Interactive REPL
  BATsh->repl();

  # CMD features: pipe, tilde modifiers, SET /P
  BATsh->run_string('ECHO hello | perl -ne "print uc"');
  BATsh->run_string("SET /P NAME=Enter name: ");

  # SH features: functions, expansions, pipelines, redirection
  BATsh->run_string(<<'BATSH');
  greet() {
      echo "Hello, \$1"
  }
  greet world
  x=\$(echo hello | perl -ne "print uc")
  echo \$x
  echo out > /tmp/out.txt
  BATSH

  # Perl 5.005_03 and later; pure-Perl, no external shell required.

=head1 DESCRIPTION

=head2 Executive Summary

BATsh is a bilingual shell interpreter written in pure Perl.
It runs cmd.exe batch syntax and bash/sh syntax in the B<same script file>,
switching automatically between CMD mode and SH mode on a line-by-line basis.
No external cmd.exe, bash, or sh is required -- everything runs inside Perl.

=head2 Mixed-Mode Sample

The following script demonstrates cmd.exe and bash sections coexisting and
sharing variables through the common BATsh::Env variable store.

  :: -- CMD section: sets a variable and calls a SH function via bridge --
  @ECHO OFF
  SET LANG=BATsh
  SET COUNT=3

  # -- SH section: reads CMD variables, uses functions and pipeline --
  greet() {
      echo "Hello from $1 (bash/sh mode)"
  }
  greet $LANG
  for i in 1 2 3; do echo "  item $i of $COUNT"; done
  result=$(echo "$LANG" | perl -ne "print uc")
  echo "Uppercase: $result"
  echo "log line" >> /tmp/batsh_demo.txt

  :: -- CMD section again: reads variable set by SH side --
  ECHO Back in CMD mode
  ECHO Uppercase result: %result%

BATsh features (both modes): pipelines (|), I/O redirection (> >> < 2>&1),
variable expansion (${var%pat} ${var^^} ${#var}), functions, shift, local.

=head1 FULL DESCRIPTION

BATsh is a bilingual shell interpreter written in pure Perl.
It implements both the cmd.exe command set and the sh/bash command set
entirely in Perl -- no external cmd.exe, bash, or sh is required.

Scripts are divided into CMD sections (uppercase first token) and SH sections
(lowercase first token). Both sections share a common variable store via
BATsh::Env, so variables set in a CMD section are immediately visible in the
next SH section and vice versa.

=head1 CMD MODE

Any line whose first token is all uppercase (A-Z, 0-9, path chars) is a CMD
line. CMD sections are executed by BATsh::CMD, which implements:

  ECHO, @ECHO OFF/ON
  SET VAR=value, SET /A expr (arithmetic)
  SET /P VAR=Prompt  (interactive prompt input from STDIN)
  IF "A"=="B" ... ELSE ..., IF /I (case-insensitive), IF NOT
  IF EXIST "path with spaces", IF DEFINED var, IF ERRORLEVEL n
  FOR %%V IN (list) DO ..., FOR /L %%V IN (s,step,e) DO ...
  FOR /F "tokens= delims= skip= eol= usebackq" %%V IN (src) DO ...
  GOTO :label, :label, GOTO :EOF
  CALL :label [args], CALL file.batsh
  SHIFT, SHIFT /N
  SETLOCAL [ENABLEDELAYEDEXPANSION|DISABLEDELAYEDEXPANSION], ENDLOCAL
  CD, DIR, COPY, DEL, MOVE, MKDIR, RMDIR, REN, TYPE
  PAUSE, EXIT [/B] [code], CLS, TITLE, VER, PUSHD, POPD
  cmd1 | cmd2  (pipeline via temporary file)
  &, &&, ||  (sequential, conditional-and, conditional-or)

=head2 Variable Expansion

C<%VAR%> references are expanded before each line is dispatched.
Variable names are B<case-insensitive> (C<SET foo=x> is visible as C<%FOO%>).

Inside parenthesised IF and FOR blocks, C<%VAR%> is expanded B<at parse time>
(before any commands in the block run), matching cmd.exe behaviour.  To see
a value updated inside a block, use delayed expansion:

  SETLOCAL ENABLEDELAYEDEXPANSION
  SET X=old
  IF 1==1 (
      SET X=new
      ECHO !X!       &:: prints "new" (delayed)
      ECHO %X%       &:: prints "old" (parse-time)
  )
  ENDLOCAL

=head2 Batch Parameters

C<%0> is the script path (absolute); C<%1>..C<%9> are positional arguments;
C<%*> is all arguments joined by space.

C<CALL :label arg1 arg2 ...> invokes a subroutine as a true call frame: the
subroutine receives its own C<%0> (the C<:label> token), C<%1>..C<%9> (the
call arguments) and C<%*> (their join), and the caller's parameters are
saved before the call and restored on return.  Arguments are C<%>-expanded
before the call and split with double-quote awareness, so
C<CALL :sub "a b" %FILE%> passes C<a b> as one argument and the expanded
value of C<%FILE%> as the next.  Nested calls each get an independent frame.
The same arguments are also visible as C<$1>..C<$9> / C<$@> when the
subroutine body is written in SH mode.

C<SHIFT> moves C<%2> into C<%1>, C<%3> into C<%2>, and so on, clears C<%9>,
and rebuilds C<%*>; C<SHIFT /N> begins the shift at C<%N> (C<%1>..C<%(N-1)>
are left unchanged).

Batch-parameter tilde modifiers expand C<%0>..C<%9> components:

  %~0    dequote (strip surrounding "...")
  %~f1   full absolute path of %1
  %~d1   drive letter only   (e.g. C:)
  %~p1   directory path only (with trailing /)
  %~n1   filename without extension
  %~x1   extension only       (e.g. .bat)
  %~dp0  drive + directory    (most common usage)
  %~nx1  filename + extension

=head2 Redirection and Compound Commands

  ECHO text > file      stdout overwrite
  ECHO text >> file     stdout append
  prog 2> err.txt       stderr redirect
  & cmd                 sequential execution
  cmd1 && cmd2          run cmd2 only if cmd1 succeeded (ERRORLEVEL 0)
  cmd1 || cmd2          run cmd2 only if cmd1 failed   (ERRORLEVEL != 0)

The C<^> character escapes the next character:

  ECHO a^&b    prints  a&b   (& not treated as compound separator)
  ECHO a^^b    prints  a^b
  ECHO text^   next line is joined (line continuation)

=head1 SH MODE

Any line whose first token contains a lowercase letter is a SH line.
SH sections are executed by BATsh::SH, which implements:

  VAR=value, export VAR=value, unset VAR
  echo, printf
  if/then/elif/else/fi
  for VAR in list; do ... done
  while condition; do ... done
  until condition; do ... done
  case $var in pat1|pat2) ... ;; *) ... ;; esac
    (|-patterns, * ? [abc] [a-z] [!abc] globs, ;& and ;;& fall-through)
  test / [ ... ]  (file, string, and integer comparisons)
  cd, pwd, exit, true, false, :, read, shift [N], local VAR=value
  eval  (quote removal + re-execution with a second expansion)
  set -e / -u / -x, set +e/+u/+x, set -o errexit|nounset|xtrace
  trap 'cmd' SIG... / trap - SIG / trap '' SIG / trap [-p]  (EXIT + %SIG)
  $(( arithmetic )) -- full C-style operator set:
    + - * / % **  (** right-assoc; / % truncate toward zero)
    == != < <= > >=  && || !  (results 0/1)
    & ^ | ~ << >>  (bitwise; ~ is signed)
    = += -= *= /= %= <<= >>= &= ^= |=  (write back to the variable)
    ++ --  (prefix and postfix), ?: (ternary), comma
    0xNN hex and 0NN octal literals, $1..$9 inside
  $( command ) and `command`  (command substitution, nested)
  cmd1 | cmd2 [| cmd3 ...]  (pipeline via temporary file)
  cmd1 && cmd2, cmd1 || cmd2, cmd1 ; cmd2  (compound commands)
  > >> < 2> 2>> 2>&1 1>&2  (I/O redirection)
  name() { ... }, function name { ... }  (function definitions)
  $VAR, ${VAR}, $1..$9, $@, $*, $#, $?, $$, $0
  ${VAR:-default}, ${VAR:=default}, ${VAR:+alt}
  ${VAR%pat}, ${VAR%%pat}   -- shortest/longest suffix removal
  ${VAR#pat}, ${VAR##pat}   -- shortest/longest prefix removal
  ${VAR/pat/rep}, ${VAR//pat/rep}  -- first/all substitution
  ${VAR^^}, ${VAR^}, ${VAR,,}, ${VAR,}  -- case conversion
  ${VAR:N:L}, ${VAR:N}  -- substring
  ${#VAR}  -- string length
  arr=(a b c), arr+=(d e), arr[i]=v, arr[i]+=v  -- indexed arrays
  declare -a arr, declare -A map, typeset ...   -- array declaration
  map=([k]=v ...), map[k]=v                     -- associative arrays
  ${arr[i]}, ${map[key]}, $arr (== ${arr[0]})   -- element access
  ${arr[@]}, ${arr[*]}, ${#arr[@]}, ${#arr[i]}, ${!arr[@]}
  unset arr, unset arr[i]
  source / . file

=head1 ENCODING (CP932 / Shift_JIS SUPPORT)

Scripts written in CP932 -- the ANSI encoding of Japanese Windows --
run correctly as of version 0.07, including the notorious "dame-moji"
whose second byte collides with an ASCII shell metacharacter:

  SO   (0x83 0x5C)  trail byte = backslash
  HYOU (0x95 0x5C)  trail byte = backslash
  PO   (0x83 0x7C)  trail byte = pipe
  CHI  (0x83 0x60)  trail byte = backtick
  DA   (0x83 0x5E)  trail byte = caret (the cmd.exe escape)

The encoding is B<auto-detected> by default: a non-UTF-8 source
containing bytes above 0x7F is treated as CP932.  Pure-ASCII and
UTF-8 scripts are unaffected.  Explicit selection:

  BATsh->run($file, encoding => 'cp932');   # per run
  BATsh->set_encoding('cp932');             # for the process
  set BATSH_ENCODING=cp932                  # environment variable
  perl lib/BATsh.pm --encoding=cp932 script.batsh

Supported names: cp932 (sjis), gbk (cp936), uhc (cp949), big5
(cp950), utf8, none, auto.  Under an active DBCS encoding the
substring and length operators C<${#VAR}>, C<${VAR:N:L}> and
C<%VAR:~n,m%> count characters rather than bytes.  A UTF-8 BOM on
the first line is stripped.  See L<BATsh::MB> for the mechanism.

=head1 EXIT STATUS

C<run>, C<run_string> and C<run_lines> return the script's B<final exit
status> as an integer: the argument of SH C<exit N> or CMD C<EXIT [/B] N>
if one was executed, otherwise the status of the last command.  C<EXIT>
with no code keeps the current C<ERRORLEVEL> (so C<false> then C<EXIT /B>
returns 1).  The same value is available afterwards as
C<BATsh-E<gt>last_status>.

At every CMD/SH section boundary the status is mirrored in both
directions, so an SH failure is immediately visible as C<%ERRORLEVEL%>
(and C<IF ERRORLEVEL n>) in the following CMD section, and a CMD failure
is visible as C<$?> in the following SH section.

C<BATsh-E<gt>main(@ARGV)> implements the command-line interface used by
the modulino (C<perl lib/BATsh.pm ...>) and by F<bin/batsh.pl> (installed
as C<batsh>): C<--help>, C<--version>, C<-e 'source'>, a script filename,
or C<-> to read the script from STDIN; remaining arguments become
C<%1>..C<%9> / C<$1>..C<$9>.  The modulino calls
C<exit(BATsh-E<gt>main(@ARGV))>, so the OS-level exit code of the process
is the script's own status.  In the REPL, C<exit N> / C<EXIT N> ends the
session.

=head1 REQUIREMENTS

Perl 5.005_03 or later. Core modules only. No external shell required.

=head1 BUGS AND LIMITATIONS

Commands that are not built in -- C<FINDSTR>, C<SORT>, C<MORE>, C<CHOICE>,
C<TIMEOUT>, C<XCOPY>, C<ROBOCOPY> and the like in CMD mode, and any
non-builtin program in SH mode -- are B<not> reimplemented in Perl. They
are invoked as external programs (via Perl's C<system>), so they work only
where the host operating system provides the corresponding executable
(e.g. F<FINDSTR.EXE> on Windows). This is by design: only the built-in
command set is guaranteed to run identically on every platform.

The built-in CMD interpreter does not implement:

=over

=item * C<FOR /F> with C<usebackq> backtick-quoted commands on Windows
(the C<cmd /c> subprocess path is untested on Windows).

=back

Variable substring C<%VAR:~n,m%> / C<%VAR:~n%> / C<%VAR:~-n%> / C<%VAR:~n,-m%>
and in-place substitution C<%VAR:str1=str2%> / C<%VAR:*str1=str2%> are B<now
supported> as of version 0.05 (see L<BATsh::Env>).

Dynamic pseudo-variables C<%DATE%> (YYYY-MM-DD), C<%TIME%> (HH:MM:SS.cc),
C<%CD%> (current directory), C<%RANDOM%> (0-32767), C<%ERRORLEVEL%>, and
C<%CMDCMDLINE%> are B<now supported> as of version 0.05.

Indexed and associative arrays -- C<arr=(a b c)>, C<arr+=(...)>,
C<arr[i]=v>, C<declare -A map>, C<map=([k]=v ...)>, C<${arr[i]}>,
C<${arr[@]}>, C<${#arr[@]}>, C<${!arr[@]}>, and C<unset arr[i]> -- are
B<now supported> as of version 0.06 (see L<BATsh::SH>).  Element ordering
for C<${arr[@]}> is ascending numeric index for indexed arrays and sorted
key order for associative arrays (bash leaves the latter unspecified);
C<"${arr[@]}"> word-splits to one item per element in C<for> lists.

Tilde expansion C<~/path> and C<~user/path> B<are supported> as of
version 0.07: word-initial, unquoted C<~> in C<cd>, in unquoted words
produced by word-splitting (external command arguments, C<echo>,
C<eval>), in C<test>/C<[> file-test operands, and in the right-hand
side of a plain C<VAR=value> or prefix C<VAR=value command> assignment.
C<~user> resolves via C<getpwnam> and is therefore Unix-like only (a
no-op on Win32, where the word is left literal, matching bash's
behaviour for an unresolvable login name). B<Not> implemented: tilde
expansion after C<:> in colon-list assignments such as
C<PATH=~/a:~/b> (bash expands each colon-separated tilde in
C<PATH>/C<CDPATH>/C<MAILPATH> specifically); such values pass through
unexpanded.

Brace expansion C<{a,b,c}> and C<{1..5}>/C<{a..e}[..step]>, extended
pattern matching (C<shopt -s extglob>; C<?()>, C<*()>, C<+()>, C<@()>,
C<!()> in case patterns and in C<${VAR%pat}>-family patterns),
here-strings (C<E<lt>E<lt>E<lt> word>), process substitution
(C<E<lt>(cmd)>, C<E<gt>(cmd)>), and the C<select>, C<alias>/C<unalias>,
and C<exec> builtins B<are now supported> as of version 0.07 (see
L<BATsh::SH>).

The builtin C<getopts> B<is supported> as of version 0.07: it parses
single-character options with the usual C<OPTIND>/C<OPTARG> protocol,
clustered flags (C<-abc>), attached (C<-oVALUE>) and separate
(C<-o VALUE>) option arguments, the C<--> end-of-options marker, and
both the default (diagnostic on STDERR) and silent (leading C<:> in the
optstring) error-reporting modes.  See L<BATsh::SH/"getopts">.

The shell options C<set -e> (errexit), C<set -u> (nounset) and C<set -x>
(xtrace) B<are supported> as of version 0.07, including the long forms
C<set -o errexit|nounset|xtrace>, the C<+e/+u/+x> off switches, and
combined letters (C<set -eux>).  Known limitations: C<set -x> traces the
B<raw pre-expansion> command line (tracing an expanded copy would execute
C<$(...)> substitutions twice), and under C<set -u> the offending command
first completes with the empty expansion before the script stops with
status 1.  The options are reset at the start of each top-level
C<run>/C<run_string>/C<run_lines>, so C<set -e> does not leak into a
later run in the same process.

The builtin C<eval> B<is supported> as of version 0.07: one level of
quote removal, concatenation, and re-execution with a second round of
expansion (POSIX semantics).

C<trap> B<is> supported in SH mode: C<trap 'cmd' SIGSPEC...> registers a
handler, C<trap - SIGSPEC> resets to default, C<trap '' SIGSPEC> ignores,
and C<trap> / C<trap -p> lists.  Real signals are bridged to Perl's C<%SIG>;
the C<EXIT> pseudo-signal (also C<0>) runs when the script ends or on
C<exit>.  The handler is expanded when it fires.  See L<BATsh::SH/"Traps and
Signals">.

In SH mode, a parenthesised group C<( ... )> B<is> a subshell command
group as of version 0.07: variable, array, function, and alias changes,
and C<cd>, made inside it do not affect the calling shell (approximated
by snapshot/restore around the body, since this interpreter never
forks -- see L<BATsh::SH/"Subshell Command Groups">).  In CMD mode,
C<( ... )> is only recognised as an C<IF>/C<FOR> block delimiter (as in
cmd.exe); it is not a general-purpose command group and has no
associated variable-scope isolation.

Pipeline (C<|>), I/O redirection (C<E<gt>> C<E<gt>E<gt>> C<E<lt>>
C<2E<gt>> C<2E<gt>E<gt>> C<2E<gt>&1>), compound commands
(C<&&> C<||> C<;>), and function definitions are supported in both modes.

Here-documents (C<E<lt>E<lt>EOF>, C<E<lt>E<lt>'EOF'>, C<E<lt>E<lt>-EOF>)
B<are> supported in SH mode, with the limitations described in
L<BATsh::SH>: one here-document per command line, and best-effort
behaviour when combined with a pipeline or compound operator on the
same line.  Here-strings (C<E<lt>E<lt>E<lt> word>) are a separate
feature (also supported as of version 0.07; see above).

Background execution (a trailing C<&>) B<is> supported in SH mode for
B<external> commands only, with the limitations described in
L<BATsh::SH>: only a trailing C<&> is recognised, built-ins/functions/
assignments/control words ignore it, there is no job control
(C<jobs>, C<wait>, C<fg>, C<bg>, C<%n>), and no signals are delivered to
background jobs. In CMD mode C<&> keeps its cmd.exe meaning as a
sequential separator.

Section boundary detection is token-based (uppercase vs. lowercase first
token). Mixed-case first tokens are treated as SH.

Please report bugs via the issue tracker:
L<https://github.com/ina-cpan/BATsh/issues>

=head1 SEE ALSO

L<BATsh::CMD>, L<BATsh::SH>, L<BATsh::Env>

=head1 AUTHOR

INABA Hitoshi E<lt>ina.cpan@gmail.comE<gt>

=head1 LICENSE

This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
