package BATsh::CMD;
# Copyright (c) 2026 INABA Hitoshi <ina.cpan@gmail.com>
######################################################################
#
# BATsh::CMD - Pure Perl cmd.exe interpreter
#
# v0.02 changes (cmd.exe compatibility fixes):
#   1. Environment variable case-insensitivity (via Env.pm)
#   2. ^ escape character: protects & | < > and line continuation
#   3. Redirect/pipe: > >> 2> 2>> < | parsed before dispatch
#   4. SETLOCAL ENABLEDELAYEDEXPANSION + !VAR! (via Env.pm)
#   5. IF block pre-expansion: entire IF block expanded at parse time
#      (matching cmd.exe's "parse before execute" semantics)
#   6. FOR /F: tokens= delims= skip= eol= usebackq
#   7. IF /I must be parsed BEFORE plain == to avoid shadowing
#   8. ECHO no longer resets ERRORLEVEL
#   9. SETLOCAL passes option string to Env::setlocal()
#  10. IF EXIST handles quoted paths with spaces
#  11. Pipeline (|): _split_compound detects |, _exec_pipe chains via tmpfile
#  12. SET /P VAR=Prompt: reads one line from STDIN
#  13. SHIFT / SHIFT /N: shifts %1..%9 and %* positional parameters
#  14. Batch-parameter tilde modifiers via Env::expand_cmd():
#      %~0 %~f1 %~d0 %~p0 %~n1 %~x1 %~dp0 %~nx1 (f d p n x combinable)
#  15. & && || compound commands (_exec_compound)
#  16. %0..%9 and %* positional parameter expansion in expand_cmd()
#
######################################################################

use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }

use File::Spec ();
use File::Copy ();
use File::Path ();
use Carp qw(croak);
use vars qw($VERSION);
$VERSION = '0.05';
$VERSION = $VERSION;

require BATsh::Env;

# ----------------------------------------------------------------
# Module-level state
# ----------------------------------------------------------------
my $ECHO_ON    = 1;
my $ERRORLEVEL = 0;
my $_GOTO_LABEL = '';

# ----------------------------------------------------------------
# Public: execute an array of CMD lines
# ----------------------------------------------------------------
sub exec_block {
    my ($class, $lines_ref, %opts) = @_;
    my @lines = @{$lines_ref};

    # Preprocess: join ^ line-continuations
    @lines = _join_continuations(@lines);

    # Build label index
    my %labels = ();
    for my $i (0 .. $#lines) {
        my $l = $lines[$i];
        $l =~ s/\r?\n\z//;
        $l =~ s/\A\s+//;
        if ($l =~ /\A:([A-Za-z_][A-Za-z0-9_]*)\s*\z/) {
            $labels{uc($1)} = $i;
        }
    }

    my $i = 0;
    while ($i <= $#lines) {
        my $raw = $lines[$i];
        $i++;
        $raw =~ s/\r?\n\z//;
        my $rc = _exec_line($class, $raw, \@lines, { %labels }, \$i, { %opts });

        if ($_GOTO_LABEL ne '') {
            my $lbl = $_GOTO_LABEL;
            $_GOTO_LABEL = '';
            if (exists $labels{$lbl}) {
                $i = $labels{$lbl} + 1;
            }
            elsif ($lbl eq 'EOF') {
                last;
            }
            else {
                _warn("GOTO: label :$lbl not found");
            }
            next;
        }
        if (defined $rc && $rc eq '__EXIT__') {
            return $ERRORLEVEL;
        }
    }
    return $ERRORLEVEL;
}

# ----------------------------------------------------------------
# _get_errorlevel: public accessor for the current ERRORLEVEL value.
# Used by BATsh::Env::_expand_named_var for %ERRORLEVEL% expansion.
# ----------------------------------------------------------------
sub _get_errorlevel { return $ERRORLEVEL }

# ----------------------------------------------------------------
# _join_continuations: merge lines ending with bare ^ (not ^^ or "^")
# cmd.exe rule: ^ at end-of-line (outside quotes) joins next line,
# consuming the ^ and leading whitespace of the next line.
# ----------------------------------------------------------------
sub _join_continuations {
    my @in = @_;
    my @out;
    my $i = 0;
    while ($i <= $#in) {
        my $line = $in[$i]; $i++;
        $line =~ s/\r?\n\z//;
        # Count unescaped ^ at end: odd count = continuation
        while ($line =~ /\A((?:[^^]|\^\^)*)\^\z/) {
            # Strip the trailing ^, append next line (minus leading ws)
            $line = $1;
            if ($i <= $#in) {
                my $next = $in[$i]; $i++;
                $next =~ s/\r?\n\z//;
                $next =~ s/\A\s+//;
                $line .= $next;
            }
            else { last }
        }
        push @out, $line;
    }
    return @out;
}

# ----------------------------------------------------------------
# _unescape_caret: replace ^X with X (^ is escape char in cmd.exe)
# Called AFTER %VAR% expansion for non-block contexts.
# ----------------------------------------------------------------
sub _unescape_caret {
    my ($str) = @_;
    $str =~ s/\^(.)/$1/g;
    return $str;
}

# ----------------------------------------------------------------
# Execute one logical line
# $pre_expanded: if true, skip %VAR% expansion (already done by FOR)
# $block_expanded: if true, skip expansion entirely (IF block body)
# ----------------------------------------------------------------
sub _exec_line {
    my ($class, $raw, $lines_ref, $labels_ref, $i_ref, $opts_ref, $pre_expanded) = @_;
    $pre_expanded = 0 unless defined $pre_expanded;

    my $line = $raw;
    $line =~ s/\A\s+//;

    my $suppress_echo = 0;
    if ($line =~ s/\A\@//) { $suppress_echo = 1; }

    return 0 if $line =~ /\A\s*\z/;
    return 0 if $line =~ /\A::/;
    return 0 if $line =~ /\AREM(?:\s|\z)/i;
    return 0 if $line =~ /\A:[A-Za-z_]/;
    return 0 if $line =~ /\A\s*\)\s*(?:ELSE\s*.*)??\s*\z/i;
    return 0 if $line =~ /\A#/;

    if (!$pre_expanded) {
        $line = _expand_line($line);
    }
    elsif (BATsh::Env::delayed_expansion()) {
        # Even in pre_expanded blocks, !VAR! must be expanded at runtime
        $line = BATsh::Env->expand_cmd($line);
    }

    # Handle compound commands: & && || (outside quotes, after expansion)
    # Split on & / && / || and execute left to right
    if ($line =~ /[&|]/) {
        my @parts = _split_compound($line);
        if (@parts > 1) {
            return _exec_compound($class, \@parts, $lines_ref, $labels_ref, $i_ref, $opts_ref);
        }
    }

    # Handle redirection stripping before dispatch
    my ($clean_line, $redirs) = _strip_redirects($line);

    return _dispatch_with_redirs($class, $clean_line, $redirs, $lines_ref, $labels_ref, $i_ref, $opts_ref);
}

# ----------------------------------------------------------------
# _expand_line: %VAR% expansion protecting FOR loop variables
# ----------------------------------------------------------------
sub _expand_line {
    my ($line) = @_;
    if ($line =~ /\AFOR\s/i) {
        if ($line =~ /\A(FOR\s+(?:\/[A-Za-z]\s+(?:"[^"]*"\s+)?)?%%[A-Za-z]\s+(?:\/[A-Za-z]\s+)?IN\s*\([^)]*\)\s+DO\s+)(.*)\z/i) {
            my ($for_head, $do_part) = ($1, $2);
            $for_head =~ s/%%([A-Za-z])/"\x00FOR_$1\x00"/ge;
            $for_head = BATsh::Env->expand_cmd($for_head);
            $for_head =~ s/\x00FOR_([A-Za-z])\x00/%%$1/g;
            $do_part =~ s/%%([A-Za-z])/"\x00FOR_$1\x00"/ge;
            $do_part =~ s/%([^%\r\n]+)%/"\x00PCT_$1\x00"/ge;
            return $for_head . $do_part;
        }
        else {
            $line =~ s/%%([A-Za-z])/"\x00FOR_$1\x00"/ge;
            $line = BATsh::Env->expand_cmd($line);
            $line =~ s/\x00FOR_([A-Za-z])\x00/%%$1/g;
            return $line;
        }
    }
    else {
        $line =~ s/%%([A-Za-z])/"\x00FOR_$1\x00"/ge;
        $line = BATsh::Env->expand_cmd($line);
        $line =~ s/\x00FOR_([A-Za-z])\x00/%%$1/g;
        return $line;
    }
}

# ----------------------------------------------------------------
# _split_compound: split on bare & && || (respecting quotes and ^)
# Returns list of { op => '&'|'&&'|'||'|'', cmd => $str }
# ----------------------------------------------------------------
sub _split_compound {
    my ($line) = @_;
    my @parts;
    my $cur = '';
    my $in_q = 0;
    my @chars = split //, $line;
    my $n = scalar @chars;
    my $j = 0;
    while ($j < $n) {
        my $ch = $chars[$j];
        if ($ch eq '^' && !$in_q) {
            # escaped: take next char literally
            $j++;
            if ($j < $n) { $cur .= $chars[$j]; $j++ }
            next;
        }
        if ($ch eq '"') { $in_q = !$in_q; $cur .= $ch; $j++; next }
        if (!$in_q && $ch eq '&') {
            if ($j+1 < $n && $chars[$j+1] eq '&') {
                push @parts, { op => '', cmd => $cur }; $cur = ''; $j += 2;
                push @parts, { op => '&&', cmd => '' };
            }
            else {
                push @parts, { op => '', cmd => $cur }; $cur = ''; $j++;
                push @parts, { op => '&', cmd => '' };
            }
            next;
        }
        if (!$in_q && $ch eq '|') {
            if ($j+1 < $n && $chars[$j+1] eq '|') {
                push @parts, { op => '', cmd => $cur }; $cur = ''; $j += 2;
                push @parts, { op => '||', cmd => '' };
            }
            elsif ($j+1 < $n && $chars[$j+1] ne '>') {
                # pipe: record left side and mark as pipe op
                push @parts, { op => '', cmd => $cur }; $cur = ''; $j++;
                push @parts, { op => '|', cmd => '' };
            }
            else {
                $cur .= $ch; $j++; next;
            }
            next;
        }
        $cur .= $ch; $j++;
    }
    push @parts, { op => '', cmd => $cur } if $cur =~ /\S/;
    return @parts;
}

# ----------------------------------------------------------------
# _exec_compound: execute & / && / || compound commands
# ----------------------------------------------------------------
sub _exec_compound {
    my ($class, $parts, $lines_ref, $labels_ref, $i_ref, $opts_ref) = @_;

    # If any part uses pipe operator, delegate entirely to _exec_pipe
    # before executing any segment (so left-side stdout is captured first).
    for my $part (@{$parts}) {
        if ($part->{op} eq '|') {
            return _exec_pipe($class, $parts, $lines_ref, $labels_ref, $i_ref, $opts_ref);
        }
    }

    my $pending_op = '';
    my $rc = 0;
    for my $part (@{$parts}) {
        my $op  = $part->{op};
        my $cmd = $part->{cmd};
        $cmd =~ s/\A\s+//; $cmd =~ s/\s+\z//;

        if ($op eq '') {
            # This is a command to run, pending_op tells us under what condition
            if ($pending_op eq '') {
                $rc = _exec_single($class, $cmd, $lines_ref, $labels_ref, $i_ref, $opts_ref) if $cmd =~ /\S/;
            }
            elsif ($pending_op eq '&&') {
                $rc = _exec_single($class, $cmd, $lines_ref, $labels_ref, $i_ref, $opts_ref) if $ERRORLEVEL == 0 && $cmd =~ /\S/;
            }
            elsif ($pending_op eq '||') {
                $rc = _exec_single($class, $cmd, $lines_ref, $labels_ref, $i_ref, $opts_ref) if $ERRORLEVEL != 0 && $cmd =~ /\S/;
            }
            elsif ($pending_op eq '&') {
                $rc = _exec_single($class, $cmd, $lines_ref, $labels_ref, $i_ref, $opts_ref) if $cmd =~ /\S/;
            }
            $pending_op = '';
        }
        else {
            $pending_op = $op;
        }
    }
    return $rc;
}

sub _exec_single {
    my ($class, $cmd, $lines_ref, $labels_ref, $i_ref, $opts_ref) = @_;
    return 0 unless $cmd =~ /\S/;
    my ($clean, $redirs) = _strip_redirects($cmd);
    return _dispatch_with_redirs($class, $clean, $redirs, $lines_ref, $labels_ref, $i_ref, $opts_ref);
}

# ----------------------------------------------------------------
# _exec_pipe: execute cmd1 | cmd2 [| cmd3 ...] via temporary files.
# Left side stdout -> tmpfile; right side reads tmpfile as stdin.
# Perl 5.005_03 compatible: bareword filehandles, 2-arg open only.
# ----------------------------------------------------------------
use vars qw(*_PIPE_SAVOUT *_PIPE_SAVIN *_PIPE_WFH *_PIPE_RFH);

sub _exec_pipe {
    my ($class, $parts, $lines_ref, $labels_ref, $i_ref, $opts_ref) = @_;

    # Collect command segments from parts list.
    # parts layout (from _split_compound):
    #   { op=>'',  cmd=>'left_cmd ' }
    #   { op=>'|', cmd=>''          }
    #   { op=>'',  cmd=>' right_cmd'}
    # Segments are op='' chunks; '|' entries are separators.
    my @segments;
    my $cur = '';
    for my $part (@{$parts}) {
        my $op  = $part->{op};
        my $cmd = $part->{cmd};
        if ($op eq '|') {
            push @segments, $cur;
            $cur = '';
        }
        elsif ($op eq '') {
            $cur .= $cmd;
        }
        else {
            # &&, ||, & after a pipe: attach to current segment
            $cur .= " $op $cmd";
        }
    }
    push @segments, $cur;

    my $rc        = 0;
    my $base      = File::Spec->catfile(File::Spec->tmpdir(),
                                        "batsh_pipe_$$");
    my $input_f   = undef;   # tmpfile feeding this segment's stdin
    my $n_segs    = scalar @segments;

    for my $idx (0 .. $n_segs - 1) {
        my $seg = $segments[$idx];
        $seg =~ s/\A\s+//; $seg =~ s/\s+\z//;
        next unless $seg =~ /\S/;

        my $is_last  = ($idx == $n_segs - 1) ? 1 : 0;
        my $output_f = $is_last ? undef : "${base}_${idx}.tmp";

        # --- redirect STDIN from previous segment output ---
        my $saved_in = 0;
        if (defined $input_f && -f $input_f) {
            open(_PIPE_RFH, $input_f)
                or do { _warn("pipe: open $input_f: $!"); last };
            open(_PIPE_SAVIN, '<&STDIN')
                or do { close(_PIPE_RFH); last };
            open(STDIN, '<&_PIPE_RFH')
                or do { close(_PIPE_RFH); open(STDIN,'<&_PIPE_SAVIN'); close(_PIPE_SAVIN); last };
            close(_PIPE_RFH);
            $saved_in = 1;
        }

        # --- redirect STDOUT to next segment input file ---
        my $saved_out = 0;
        if (defined $output_f) {
            open(_PIPE_WFH, ">$output_f")
                or do {
                    if ($saved_in) { open(STDIN,'<&_PIPE_SAVIN'); close(_PIPE_SAVIN) }
                    _warn("pipe: open $output_f: $!");
                    last;
                };
            open(_PIPE_SAVOUT, '>&STDOUT')
                or do {
                    close(_PIPE_WFH);
                    if ($saved_in) { open(STDIN,'<&_PIPE_SAVIN'); close(_PIPE_SAVIN) }
                    last;
                };
            open(STDOUT, '>&_PIPE_WFH')
                or do {
                    close(_PIPE_WFH);
                    open(STDOUT,'>&_PIPE_SAVOUT'); close(_PIPE_SAVOUT);
                    if ($saved_in) { open(STDIN,'<&_PIPE_SAVIN'); close(_PIPE_SAVIN) }
                    last;
                };
            close(_PIPE_WFH);
            $saved_out = 1;
        }

        # --- run the segment ---
        $rc = _exec_single($class, $seg, $lines_ref, $labels_ref, $i_ref, $opts_ref);

        # --- restore STDOUT ---
        if ($saved_out) {
            open(STDOUT, '>&_PIPE_SAVOUT');
            close(_PIPE_SAVOUT);
        }

        # --- restore STDIN and clean up input tmpfile ---
        if ($saved_in) {
            open(STDIN, '<&_PIPE_SAVIN');
            close(_PIPE_SAVIN);
            unlink $input_f;
        }

        $input_f = $output_f;   # next segment reads what we just wrote
    }

    # Clean up any leftover tmpfile (e.g. if last segment was skipped)
    unlink $input_f if defined $input_f && -f $input_f;

    return $rc;
}

# ----------------------------------------------------------------
# _strip_redirects: parse > >> 2> 2>> < from end of command
# Returns ($clean_cmd, \@redirs) where @redirs = ([fd,mode,file], ...)
# ----------------------------------------------------------------
sub _strip_redirects {
    my ($line) = @_;
    my @redirs;
    # Parse redirects while respecting ^ escapes and quotes.
    # A > or < preceded by ^ is NOT a redirect.
    # Strategy: walk char-by-char to find bare (unescaped, unquoted) redirects.
    my @chars = split //, $line;
    my $n = scalar @chars;
    my ($in_q, $i) = (0, 0);
    my $clean = '';
    my @found;   # [pos_in_clean, fd, append, file_str]

    while ($i < $n) {
        my $ch = $chars[$i];
        if ($ch eq '^' && !$in_q) {
            # Escape: pass through both ^ and next char as literals
            $clean .= $ch;
            $i++;
            $clean .= $chars[$i] if $i < $n;
            $i++;
            next;
        }
        if ($ch eq '"') { $in_q = !$in_q; $clean .= $ch; $i++; next }
        if (!$in_q && ($ch eq '>' || $ch eq '<')) {
            my $fd = 1;
            my $is_in  = ($ch eq '<') ? 1 : 0;
            # Check if the character immediately before (in clean, ignoring trailing space)
            # is a bare fd digit that is not part of a word.
            # Only '2' (stderr) and '1' (stdout explicit) are valid fd numbers in cmd.exe.
            # We accept N> only if N is a single digit preceded by space/start-of-string.
            if ($clean =~ s/(?:\A|(?<=[ \t]))([12])[ \t]*\z//) {
                $fd = int($1);
            }
            my $append = 0;
            $i++;
            if (!$is_in && $i < $n && $chars[$i] eq '>') { $append = 1; $i++ }
            # Skip whitespace before filename
            $i++ while $i < $n && $chars[$i] =~ /[ \t]/;
            # Read filename (until space/tab or end)
            my $file = '';
            if ($i < $n && $chars[$i] eq '"') {
                $i++;
                while ($i < $n && $chars[$i] ne '"') { $file .= $chars[$i++] }
                $i++;   # closing "
            }
            else {
                while ($i < $n && $chars[$i] !~ /[ \t]/) { $file .= $chars[$i++] }
            }
            push @found, [$is_in ? 0 : $fd, $append, $file];
            next;
        }
        $clean .= $ch; $i++;
    }
    $clean =~ s/\s+\z//;
    return ($clean, \@found);
}

# ----------------------------------------------------------------
# _dispatch_with_redirs: set up redirections then dispatch
# Perl 5.005_03 compatible: fixed bareword FHs, 2-argument open.
# ----------------------------------------------------------------

# Fixed bareword filehandles used only inside _dispatch_with_redirs.
# Pre-declared at package level so they are valid under strict.
use vars qw(*_REDIR_SRC *_REDIR_DST *_REDIR_SAVOUT *_REDIR_SAVERR *_REDIR_SAVIN);

sub _dispatch_with_redirs {
    my ($class, $line, $redirs, $lines_ref, $labels_ref, $i_ref, $opts_ref) = @_;

    return _dispatch($class, $line, $lines_ref, $labels_ref, $i_ref, $opts_ref)
        unless @{$redirs};

    # Process redirections one at a time using fixed bareword FHs.
    # We support one redirect per fd (last one wins, matching cmd.exe).
    # Collect: stdin_file, stdout_file, stdout_append, stderr_file, stderr_append
    my ($in_file, $out_file, $out_app, $err_file, $err_app);
    for my $r (@{$redirs}) {
        my ($fd, $append, $file) = @{$r};
        if    ($fd == 0) { $in_file  = $file }
        elsif ($fd == 1) { $out_file = $file; $out_app = $append }
        else             { $err_file = $file; $err_app = $append }
    }

    my $ok = 1;
    my ($saved_in, $saved_out, $saved_err) = (0, 0, 0);

    # stdin
    if (defined $in_file && $ok) {
        open(_REDIR_SRC, $in_file) or do { _warn("Cannot open $in_file: $!"); $ok=0 };
        if ($ok) {
            open(_REDIR_SAVIN, '<&STDIN') or do { $ok=0 };
        }
        if ($ok) {
            open(STDIN, '<&_REDIR_SRC') or do { $ok=0 };
            close(_REDIR_SRC);
            $saved_in = 1;
        }
    }

    # stdout
    if (defined $out_file && $ok) {
        my $mode = $out_app ? '>>' : '>';
        open(_REDIR_DST, "$mode$out_file") or do { _warn("Cannot open $out_file: $!"); $ok=0 };
        if ($ok) {
            open(_REDIR_SAVOUT, '>&STDOUT') or do { $ok=0 };
        }
        if ($ok) {
            open(STDOUT, '>&_REDIR_DST') or do { $ok=0 };
            close(_REDIR_DST);
            $saved_out = 1;
        }
    }

    # stderr
    if (defined $err_file && $ok) {
        my $mode = $err_app ? '>>' : '>';
        open(_REDIR_DST, "$mode$err_file") or do { _warn("Cannot open $err_file: $!"); $ok=0 };
        if ($ok) {
            open(_REDIR_SAVERR, '>&STDERR') or do { $ok=0 };
        }
        if ($ok) {
            open(STDERR, '>&_REDIR_DST') or do { $ok=0 };
            close(_REDIR_DST);
            $saved_err = 1;
        }
    }

    my $rc = 0;
    $rc = _dispatch($class, $line, $lines_ref, $labels_ref, $i_ref, $opts_ref) if $ok;

    # Restore in reverse order
    if ($saved_err) { open(STDERR, '>&_REDIR_SAVERR'); close(_REDIR_SAVERR) }
    if ($saved_out) { open(STDOUT, '>&_REDIR_SAVOUT'); close(_REDIR_SAVOUT) }
    if ($saved_in)  { open(STDIN,  '<&_REDIR_SAVIN');  close(_REDIR_SAVIN)  }

    return $rc;
}

# ----------------------------------------------------------------
# Command dispatcher
# ----------------------------------------------------------------
sub _dispatch {
    my ($class, $line, $lines_ref, $labels_ref, $i_ref, $opts_ref) = @_;

    my ($cmd, $rest) = _split_cmd($line);
    return 0 unless defined $cmd && $cmd ne '';

    my $CMD = uc($cmd);

    if ($CMD eq 'ECHO')    { return _cmd_echo($rest) }
    if ($CMD eq '@ECHO')   { return _cmd_echo($rest) }
    if ($CMD eq 'SET')     { return _cmd_set($rest) }
    if ($CMD eq 'IF')      { return _cmd_if($class, $line, $lines_ref, $labels_ref, $i_ref, $opts_ref) }
    if ($CMD eq 'FOR')     { return _cmd_for($class, $line, $lines_ref, $labels_ref, $i_ref, $opts_ref) }
    if ($CMD eq 'GOTO') {
        $rest =~ s/\A\s+//; $rest =~ s/\s+\z//; $rest =~ s/\A://;
        $_GOTO_LABEL = uc($rest);
        return 0;
    }
    if ($CMD eq 'CALL')    { return _cmd_call($class, $rest, $opts_ref) }
    if ($CMD eq 'SETLOCAL') {
        $rest =~ s/\A\s+//; $rest =~ s/\s+\z//;
        BATsh::Env::setlocal($rest);
        return 0;
    }
    if ($CMD eq 'ENDLOCAL') { BATsh::Env::endlocal(); return 0 }
    if ($CMD eq 'CD' || $CMD eq 'CHDIR') { return _cmd_cd($rest) }
    if ($CMD eq 'DIR')     { return _cmd_dir($rest) }
    if ($CMD eq 'COPY')    { return _cmd_copy($rest) }
    if ($CMD eq 'DEL' || $CMD eq 'ERASE') { return _cmd_del($rest) }
    if ($CMD eq 'MOVE')    { return _cmd_move($rest) }
    if ($CMD eq 'MKDIR' || $CMD eq 'MD') { return _cmd_mkdir($rest) }
    if ($CMD eq 'RMDIR' || $CMD eq 'RD') { return _cmd_rmdir($rest) }
    if ($CMD eq 'REN' || $CMD eq 'RENAME') { return _cmd_rename($rest) }
    if ($CMD eq 'TYPE')    { return _cmd_type($rest) }
    if ($CMD eq 'PAUSE') {
        print "Press any key to continue . . . ";
        my $ch = '';
        eval { local $| = 1; require POSIX; POSIX::tcgetattr(0); read(STDIN, $ch, 1) };
        print "\n";
        return 0;
    }
    if ($CMD eq 'EXIT') {
        $rest =~ s/\A\s+//;
        my $is_b = ($rest =~ s{/B\s*}{}i) ? 1 : 0;
        $rest =~ s/\A\s+//;
        $ERRORLEVEL = ($rest =~ /\A\d+\z/) ? int($rest) : 0;
        return '__EXIT__';
    }
    if ($CMD eq 'CLS')   { print "\033[2J\033[H"; return 0 }
    if ($CMD eq 'TITLE') { print "\033]0;$rest\007"; return 0 }
    if ($CMD eq 'VER')   { print "BATsh [Version $BATsh::VERSION]\n"; return 0 }
    if ($CMD eq 'PUSHD') {
        $rest =~ s/\A\s+//; $rest =~ s/\s+\z//;
        push @{$opts_ref->{'_pushd_stack'}}, Cwd::cwd();
        return _cmd_cd($rest);
    }
    if ($CMD eq 'POPD') {
        if (defined $opts_ref->{'_pushd_stack'} && @{$opts_ref->{'_pushd_stack'}}) {
            chdir(pop @{$opts_ref->{'_pushd_stack'}});
        }
        return 0;
    }

    return _cmd_external($cmd, $rest);
}

# ----------------------------------------------------------------
# ECHO  (does NOT reset ERRORLEVEL -- cmd.exe compatible)
# ----------------------------------------------------------------
sub _cmd_echo {
    my ($rest) = @_;
    $rest =~ s/\A\s+//;

    if ($rest =~ /\AOFF\s*\z/i) { $ECHO_ON = 0; return 0; }
    if ($rest =~ /\AON\s*\z/i)  { $ECHO_ON = 1; return 0; }
    if ($rest =~ /\A\.\s*\z/)   { print "\n"; return 0; }
    if ($rest =~ /\A\s*\z/)     { print "ECHO is " . ($ECHO_ON ? "on" : "off") . "\n"; return 0; }

    # Remove ^ escapes for display (they were protection, not content)
    $rest = _unescape_caret($rest);
    print "$rest\n";
    # ERRORLEVEL intentionally NOT modified here
    return 0;
}

# ----------------------------------------------------------------
# SET
# ----------------------------------------------------------------
sub _cmd_set {
    my ($rest) = @_;
    $rest =~ s/\A\s+//;

    # SET /P VAR=PromptString  (interactive prompt input)
    if ($rest =~ s/\A\/P\s*//i) {
        if ($rest =~ /\A([A-Za-z_][A-Za-z0-9_]*)\s*=(.*)/) {
            my ($var, $prompt) = ($1, $2);
            print $prompt;
            my $input = <STDIN>;
            $input = '' unless defined $input;
            chomp $input;
            BATsh::Env->set($var, $input);
            $ERRORLEVEL = 0;
        }
        return 0;
    }

    # SET /A
    if ($rest =~ s/\A\/A\s*//i) {
        if ($rest =~ /\A\s*([A-Za-z_][A-Za-z0-9_]*)\s*=(.*)/) {
            BATsh::Env->set($1, _eval_arith($2));
        }
        else {
            print _eval_arith($rest) . "\n";
        }
        $ERRORLEVEL = 0;
        return 0;
    }

    # SET with no args: display all
    if ($rest =~ /\A\s*\z/) {
        for my $k (sort keys %BATsh::Env::STORE) {
            print "$k=$BATsh::Env::STORE{$k}\n";
        }
        return 0;
    }

    # SET VAR=value  (variable name may contain spaces before =)
    if ($rest =~ /\A([^=]+?)\s*=(.*)/) {
        BATsh::Env->set($1, $2);
        $ERRORLEVEL = 0;
        return 0;
    }

    # SET VAR (display matching prefix)
    if ($rest =~ /\A(\S+)\s*\z/) {
        my $prefix = uc($1);
        for my $k (sort keys %BATsh::Env::STORE) {
            if (index(uc($k), $prefix) == 0) {
                print "$k=$BATsh::Env::STORE{$k}\n";
            }
        }
        return 0;
    }

    return 0;
}

# ----------------------------------------------------------------
# SET /A arithmetic evaluator
# Supports: + - * / % ^ & | ~ << >> () hex (0x) and variable refs
# ----------------------------------------------------------------
sub _eval_arith {
    my ($expr) = @_;
    # Expand variable names
    $expr =~ s/([A-Za-z_][A-Za-z0-9_]*)/
        do { my $v = BATsh::Env->get($1); defined $v && $v =~ m|^-?\d+$| ? $v : 0 }
    /ge;
    # Convert 0xHEX literals
    $expr =~ s/0x([0-9A-Fa-f]+)/hex($1)/ge;
    # %% -> % (modulo)
    $expr =~ s/%%/%/g;
    # Safe eval: digits, operators, hex chars already substituted
    if ($expr =~ /\A[\d\s\+\-\*\/\%\(\)\^\&\|\~\<\>]+\z/) {
        # Perl ^ is XOR, same as cmd.exe SET /A
        my $result = eval $expr;
        return defined $result ? int($result) : 0;
    }
    return 0;
}

# ----------------------------------------------------------------
# IF
#
# cmd.exe parse order:
#   IF [NOT] /I "a"=="b" ...      (case-insensitive string)
#   IF [NOT] ERRORLEVEL n ...
#   IF [NOT] EXIST path ...
#   IF [NOT] DEFINED var ...
#   IF [NOT] "a"=="b" ...         (case-sensitive string)
#
# IMPORTANT: /I must be checked BEFORE plain == to avoid /I being
# consumed as part of the left-hand operand.
#
# Block expansion: the THEN/ELSE bodies of a parenthesised IF block
# are expanded at parse time (before any SET inside runs), matching
# cmd.exe's behaviour.  Only !VAR! (delayed) is deferred to runtime.
# ----------------------------------------------------------------
sub _cmd_if {
    my ($class, $line, $lines_ref, $labels_ref, $i_ref, $opts_ref) = @_;

    (my $rest = $line) =~ s/\AIF\s+//i;

    my $negate = 0;
    if ($rest =~ s/\ANOT\s+//i) { $negate = 1; }

    my $condition = 0;

    # /I must be tried first
    if ($rest =~ s/\A\/I\s+//i) {
        # Case-insensitive comparison
        if ($rest =~ s/\A("(?:[^"]*)"|[^\s=][^\s=]*)\s*==\s*("(?:[^"]*)"|[^\s=]*)\s*//) {
            my ($a, $b) = ($1, $2);
            $a =~ s/\A"//; $a =~ s/"\z//;
            $b =~ s/\A"//; $b =~ s/"\z//;
            $condition = (lc($a) eq lc($b)) ? 1 : 0;
        }
    }
    # ERRORLEVEL n
    elsif ($rest =~ s/\AERRORLEVEL\s+(\d+)\s*//i) {
        $condition = ($ERRORLEVEL >= int($1)) ? 1 : 0;
    }
    # EXIST path (handles quoted paths with spaces)
    elsif ($rest =~ s/\AEXIST\s+//i) {
        my $path;
        if ($rest =~ s/\A"([^"]+)"\s*//) {
            $path = $1;
        }
        elsif ($rest =~ s/\A(\S+)\s*//) {
            $path = $1;
        }
        $condition = (defined $path && -e $path) ? 1 : 0;
    }
    # DEFINED var
    elsif ($rest =~ s/\ADEFINED\s+(\S+)\s*//i) {
        $condition = BATsh::Env->exists_var($1) ? 1 : 0;
    }
    # "str"=="str" or str==str (case-sensitive)
    elsif ($rest =~ s/\A("(?:[^"]*)"|[^\s=][^\s=]*)\s*==\s*("(?:[^"]*)"|[^\s=]*)\s*//) {
        my ($a, $b) = ($1, $2);
        $a =~ s/\A"//; $a =~ s/"\z//;
        $b =~ s/\A"//; $b =~ s/"\z//;
        $condition = ($a eq $b) ? 1 : 0;
    }

    $condition = !$condition if $negate;

    my ($then_body, $else_body) = _parse_if_bodies($rest, $lines_ref, $i_ref);

    # Block expansion: expand %VAR% in the bodies NOW (parse-time),
    # before any commands inside the block execute.
    # !VAR! is NOT expanded here (that is deferred to execute-time via Env).
    $then_body = _block_expand($then_body) if defined $then_body;
    $else_body = _block_expand($else_body) if defined $else_body;

    if ($condition) {
        return _exec_body($class, $then_body, $lines_ref, $labels_ref, $i_ref, $opts_ref, 1);
    }
    elsif (defined $else_body) {
        return _exec_body($class, $else_body, $lines_ref, $labels_ref, $i_ref, $opts_ref, 1);
    }
    return 0;
}

# ----------------------------------------------------------------
# _block_expand: expand %VAR% in a block string at parse time.
# Protects %%V FOR loop variables and !VAR! delayed references.
# ----------------------------------------------------------------
sub _block_expand {
    my ($body) = @_;
    return $body unless defined $body;
    # Protect !VAR! -- replace with placeholder to survive %% pass
    $body =~ s/(!(?:[A-Za-z_][A-Za-z0-9_]*)!)/"\x00DELAY\x00$1\x00DELAY\x00"/ge;
    # Protect %%V
    $body =~ s/%%([A-Za-z])/"\x00FOR_$1\x00"/ge;
    # Expand %VAR%
    $body =~ s/%([^%\r\n]+)%/
        do { my $k=uc($1); exists($BATsh::Env::STORE{$k}) ? $BATsh::Env::STORE{$k} : '' }
    /ge;
    # %% -> %
    $body =~ s/%%/%/g;
    # Restore
    $body =~ s/\x00FOR_([A-Za-z])\x00/%%$1/g;
    $body =~ s/\x00DELAY\x00(!(?:[A-Za-z_][A-Za-z0-9_]*)!)\x00DELAY\x00/$1/g;
    return $body;
}

sub _parse_if_bodies {
    my ($rest, $lines_ref, $i_ref) = @_;
    my ($then_body, $else_body);
    $rest =~ s/\A\s+//;
    if ($rest =~ s/\A\(//) {
        $then_body = _read_paren_block($rest, $lines_ref, $i_ref, \$else_body);
    }
    else {
        if ($rest =~ s/\s+ELSE\s+(.+)\z//i) { $else_body = $1 }
        $then_body = $rest;
    }
    return ($then_body, $else_body);
}

sub _read_paren_block {
    my ($first_content, $lines_ref, $i_ref, $else_ref) = @_;
    my @body = ();
    push @body, $first_content if defined $first_content && $first_content =~ /\S/;
    my $depth = 1;
    while ($$i_ref <= $#{$lines_ref}) {
        my $l = $lines_ref->[$$i_ref];
        $$i_ref++;
        $l =~ s/\r?\n\z//;
        my $ls = $l; $ls =~ s/\A\s+//;
        if ($depth == 1 && $ls =~ /\A\)\s*ELSE\s*\(\s*\z/i) {
            if (defined $else_ref) { $$else_ref = _read_paren_block('', $lines_ref, $i_ref) }
            last;
        }
        if ($depth == 1 && $ls =~ /\A\)\s*ELSE\s+(.+)\z/i) {
            if (defined $else_ref) { $$else_ref = $1 }
            last;
        }
        my ($delta, $in_q) = (0, 0);
        for my $ch (split //, $l) {
            if ($ch eq '"') { $in_q = !$in_q }
            elsif (!$in_q)  { $delta++ if $ch eq '('; $delta-- if $ch eq ')' }
        }
        $depth += $delta;
        if ($depth <= 0) {
            $l =~ s/\)\s*\z//;
            push @body, $l if $l =~ /\S/;
            last;
        }
        push @body, $l;
    }
    return join("\n", @body);
}

sub _exec_body {
    my ($class, $body, $lines_ref, $labels_ref, $i_ref, $opts_ref, $pre_expanded) = @_;
    return 0 unless defined $body && $body =~ /\S/;
    $pre_expanded = 0 unless defined $pre_expanded;
    my @sub_lines = split /\n/, $body;
    my $sub_i = 0;
    my %sub_labels = ();
    for my $j (0 .. $#sub_lines) {
        my $ls = $sub_lines[$j]; $ls =~ s/\A\s+//;
        if ($ls =~ /\A:([A-Za-z_][A-Za-z0-9_]*)\s*\z/) {
            $sub_labels{uc($1)} = $j;
        }
    }
    while ($sub_i <= $#sub_lines) {
        my $sl = $sub_lines[$sub_i];
        $sub_i++;
        # For pre_expanded blocks: still need to handle !VAR! at runtime
        my $rc = _exec_line($class, $sl, \@sub_lines, { %sub_labels }, \$sub_i, $opts_ref, $pre_expanded);
        return $rc if defined $rc && $rc eq '__EXIT__';
        if ($_GOTO_LABEL ne '') {
            my $lbl = $_GOTO_LABEL;
            $_GOTO_LABEL = '';
            if (exists $sub_labels{$lbl}) {
                $sub_i = $sub_labels{$lbl} + 1;
            }
            else {
                $_GOTO_LABEL = $lbl;
                return 0;
            }
        }
    }
    return 0;
}

# ----------------------------------------------------------------
# FOR
# ----------------------------------------------------------------
sub _cmd_for {
    my ($class, $line, $lines_ref, $labels_ref, $i_ref, $opts_ref) = @_;

    # FOR /F "options" %%V IN (source) DO cmd
    if ($line =~ /\AFOR\s+\/F\s+("(?:[^"]*)"|'(?:[^']*)'|[^\s]+)\s+(?:%%|\x00FOR_)([A-Za-z])(?:\x00)?\s+IN\s*\(([^)]*)\)\s+DO\s+(.*)/i) {
        return _cmd_for_f($class, $1, $2, $3, $4, $lines_ref, $labels_ref, $i_ref, $opts_ref);
    }

    # FOR /L %%V IN (start,step,end) DO cmd
    if ($line =~ /\AFOR\s+\/L\s+(?:%%|\x00FOR_)([A-Za-z])(?:\x00)?\s+IN\s*\(([^)]*)\)\s+DO\s+(.*)/i) {
        my ($var, $range, $do_part) = ($1, $2, $3);
        my ($start, $step, $end) = split /,/, $range;
        $start = defined $start ? int($start) : 0;
        $step  = defined $step  ? int($step)  : 1;
        $end   = defined $end   ? int($end)   : 0;
        $step  = 1 if $step == 0;
        return _for_iterate($class, $var, $do_part, $lines_ref, $labels_ref, $i_ref, $opts_ref,
            sub { # generator: returns list of values
                my @vals;
                my $v = $start;
                while (($step > 0 && $v <= $end) || ($step < 0 && $v >= $end)) {
                    push @vals, $v;
                    $v += $step;
                }
                return @vals;
            });
    }

    # FOR %%V IN (list) DO cmd
    if ($line =~ /\AFOR\s+(?:%%|\x00FOR_)([A-Za-z])(?:\x00)?\s+IN\s*\(([^)]*)\)\s+DO\s+(.*)/i) {
        my ($var, $list_str, $do_part) = ($1, $2, $3);
        my @items = split /[\s,]+/, $list_str;
        my @expanded = ();
        for my $item (@items) {
            $item =~ s/\A\s+//; $item =~ s/\s+\z//;
            next if $item eq '';
            if ($item =~ /[*?]/) {
                my @g = glob($item);
                push @expanded, @g ? @g : ($item);
            }
            else { push @expanded, $item }
        }
        return _for_iterate($class, $var, $do_part, $lines_ref, $labels_ref, $i_ref, $opts_ref,
            sub { return @expanded });
    }

    _warn("FOR: unsupported syntax: $line");
    return 1;
}

# ----------------------------------------------------------------
# _for_iterate: common FOR loop body runner
# ----------------------------------------------------------------
sub _for_iterate {
    my ($class, $var, $do_part, $lines_ref, $labels_ref, $i_ref, $opts_ref, $gen) = @_;

    # Pre-read paren body if do_part is "("
    my $paren_body_template = undef;
    {
        my $probe = $do_part;
        $probe =~ s/\x00FOR_[A-Za-z]\x00//g;
        $probe =~ s/\x00PCT_[^\x00]+\x00//g;
        $probe =~ s/%%[A-Za-z]//g;
        if ($probe =~ /\A\s*\(\s*\z/) {
            $paren_body_template = _read_paren_block('', $lines_ref, $i_ref);
        }
    }

    # If we have a paren block, expand %VAR% ONCE at FOR-parse time
    # (cmd.exe expands the whole block before any iteration runs).
    # PCT placeholders (%%V protected vars) are restored to %VAR% first,
    # then _block_expand runs the single-pass %VAR% substitution.
    # The result is a template with loop-var placeholders still intact.
    my $paren_expanded = undef;
    if (defined $paren_body_template) {
        my $tpl = $paren_body_template;
        # Restore PCT placeholders -> %VAR% so _block_expand can see them
        $tpl =~ s/\x00PCT_([^\x00]+)\x00/%$1%/g;
        # But protect the loop variable itself from _block_expand
        # (it will be substituted per-iteration below)
        $tpl =~ s/%%$var/"\x00LOOPVAR\x00"/ge;
        $tpl =~ s/\x00FOR_$var\x00/"\x00LOOPVAR\x00"/ge;
        # Single-pass %VAR% expansion at FOR-line parse time
        $paren_expanded = _block_expand($tpl);
        # _block_expand already restored other %%X -> %%X, leave loop placeholder
    }

    my @values = $gen->();

    for my $val (@values) {
        BATsh::Env->set("%%$var", $val);

        if (defined $paren_expanded) {
            # Substitute loop variable placeholder with current value
            my $body = $paren_expanded;
            $body =~ s/\x00LOOPVAR\x00/$val/g;
            # At runtime: if delayed expansion is on, expand !VAR!
            # _exec_body with pre_expanded=1 handles this via _exec_line
            _exec_body($class, $body, $lines_ref, $labels_ref, $i_ref, $opts_ref, 1);
        }
        else {
            my $do_line = $do_part;
            # Replace loop variable placeholder/shorthand with current value
            $do_line =~ s/%%$var/$val/g;
            $do_line =~ s/\x00FOR_$var\x00/$val/g;
            # Restore other FOR-variable placeholders to %%X form
            $do_line =~ s/\x00FOR_([A-Za-z])\x00/%%$1/g;
            # Restore %VAR% placeholders so expand_cmd can expand them
            $do_line =~ s/\x00PCT_([^\x00]+)\x00/%$1%/g;
            $do_line = BATsh::Env->expand_cmd($do_line);
            _exec_line($class, $do_line, $lines_ref, $labels_ref, $i_ref, $opts_ref, 1);
        }
        last if $_GOTO_LABEL ne '';
    }
    return 0;
}

# ----------------------------------------------------------------
# FOR /F
#
# Options string (inside quotes): tokens= delims= skip= eol= usebackq
# Source:
#   "filename"    -- iterate lines of file (or usebackq: command output)
#   'command'     -- command output (or usebackq: literal filename)
#   ("string")    -- tokenize the string itself
# ----------------------------------------------------------------
sub _cmd_for_f {
    my ($class, $opts_str, $var, $source_str, $do_part, $lines_ref, $labels_ref, $i_ref, $opts_ref) = @_;

    # Strip outer quotes from opts_str
    $opts_str =~ s/\A"//; $opts_str =~ s/"\z//;

    # Parse options
    my $tokens_spec = '1';       # default: first token only
    my $delims      = " \t";     # default delimiters
    my $skip        = 0;
    my $eol         = ';';       # default: skip lines starting with ;
    my $usebackq    = 0;

    $usebackq = 1 if $opts_str =~ /usebackq/i;
    if ($opts_str =~ /tokens=(\S+)/i) {
        $tokens_spec = $1;
        $tokens_spec =~ s/,\z//;
    }
    if ($opts_str =~ /delims=([^\s"]*)/i) {
        $delims = $1;
        $delims = ' ' if $delims eq '';  # delims= (empty) means no split? No: empty = space only
    }
    elsif ($opts_str =~ /delims=\s*\z/i) {
        $delims = '';  # delims= with nothing = no delimiter (whole line = one token)
    }
    if ($opts_str =~ /skip=(\d+)/i)  { $skip = int($1) }
    if ($opts_str =~ /eol=(.)/i)     { $eol = $1 }

    # Parse tokens spec: e.g. "1,2,3" "1-3" "1,2*" "*"
    my @token_indices = _parse_tokens_spec($tokens_spec);
    my $want_star = ($tokens_spec =~ /\*/) ? 1 : 0;

    # Determine source lines
    my @lines_to_process;
    $source_str =~ s/\A\s+//; $source_str =~ s/\s+\z//;

    if ($source_str =~ /\A'([^']*)'\z/ || ($usebackq && $source_str =~ /\A`([^`]*)`\z/)) {
        # Command output
        my $cmd = $1;
        BATsh::Env->sync_to_env();
        local *CMDOUT;
        open(CMDOUT, "$cmd |") or return 1;
        @lines_to_process = <CMDOUT>;
        close(CMDOUT);
    }
    elsif ($usebackq && $source_str =~ /\A"([^"]*)"\z/) {
        # usebackq: "..." = filename
        my $file = $1;
        local *FFH;
        open(FFH, $file) or do { _warn("FOR /F: cannot open $file"); return 1 };
        @lines_to_process = <FFH>;
        close(FFH);
    }
    elsif ($source_str =~ /\A"([^"]*)"\z/ && !$usebackq) {
        # No usebackq: "string" = literal string to tokenize
        @lines_to_process = ("$1\n");
    }
    elsif ($source_str =~ /\A(\S+)\z/) {
        # Bare filename
        my $file = $1;
        local *FFH2;
        open(FFH2, $file) or do { _warn("FOR /F: cannot open $file"); return 1 };
        @lines_to_process = <FFH2>;
        close(FFH2);
    }
    else {
        _warn("FOR /F: cannot parse source: $source_str");
        return 1;
    }

    # Skip leading lines
    splice(@lines_to_process, 0, $skip) if $skip > 0;

    # Pre-read paren body if needed
    my $paren_body = undef;
    {
        my $probe = $do_part;
        $probe =~ s/%%[A-Za-z]//g;
        if ($probe =~ /\A\s*\(\s*\z/) {
            $paren_body = _read_paren_block('', $lines_ref, $i_ref);
        }
    }

    # Determine variable names: %%a and following letters for extra tokens
    my @var_names;
    for my $i (0 .. $#token_indices) {
        push @var_names, chr(ord($var) + $i);
    }
    # Star token goes to the next letter after the listed ones
    my $star_var = chr(ord($var) + scalar @token_indices);

    for my $src_line (@lines_to_process) {
        $src_line =~ s/\r?\n\z//;
        # Skip eol lines
        next if $eol ne '' && $src_line =~ /\A\Q$eol\E/;
        next if $src_line =~ /\A\s*\z/;

        # Tokenize
        my @tokens;
        if ($delims eq '') {
            @tokens = ($src_line);
        }
        else {
            my $escaped_delims = quotemeta($delims);
            @tokens = split /[$escaped_delims]+/, $src_line;
            # cmd.exe skips leading delimiters
            if ($src_line =~ /\A[$escaped_delims]/) {
                shift @tokens if @tokens && $tokens[0] eq '';
            }
        }

        # Assign to variables
        for my $i (0 .. $#token_indices) {
            my $tidx = $token_indices[$i] - 1;  # 0-based
            BATsh::Env->set("%%$var_names[$i]", defined $tokens[$tidx] ? $tokens[$tidx] : '');
        }
        if ($want_star && @tokens > $token_indices[-1]) {
            # Star: remainder from token N onwards joined by first delimiter
            my $delim1 = length($delims) > 0 ? substr($delims, 0, 1) : ' ';
            my $remainder = join($delim1, @tokens[$token_indices[-1] .. $#tokens]);
            BATsh::Env->set("%%$star_var", $remainder);
        }

        # Execute body
        if (defined $paren_body) {
            my $body = $paren_body;
            # Restore any \x00FOR_x\x00 placeholders before substituting values
            $body =~ s/\x00FOR_([A-Za-z])\x00/%%$1/g;
            for my $vn (@var_names, $want_star ? ($star_var) : ()) {
                my $val = defined(BATsh::Env->get("%%$vn")) ? BATsh::Env->get("%%$vn") : '';
                $body =~ s/%%$vn/$val/g;
            }
            $body = _block_expand($body);
            _exec_body($class, $body, $lines_ref, $labels_ref, $i_ref, $opts_ref, 1);
        }
        else {
            my $do_line = $do_part;
            # Restore \x00FOR_x\x00 -> %%x, then substitute values
            $do_line =~ s/\x00FOR_([A-Za-z])\x00/%%$1/g;
            for my $vn (@var_names, $want_star ? ($star_var) : ()) {
                my $val = defined(BATsh::Env->get("%%$vn")) ? BATsh::Env->get("%%$vn") : '';
                $do_line =~ s/%%$vn/$val/g;
            }
            $do_line = BATsh::Env->expand_cmd($do_line);
            _exec_line($class, $do_line, $lines_ref, $labels_ref, $i_ref, $opts_ref, 1);
        }
        last if $_GOTO_LABEL ne '';
    }
    return 0;
}

# ----------------------------------------------------------------
# _parse_tokens_spec: "1,2,3-5,*" -> (1,2,3,4,5)
# ----------------------------------------------------------------
sub _parse_tokens_spec {
    my ($spec) = @_;
    $spec =~ s/\*//g;   # star handled separately
    my @indices;
    for my $part (split /,/, $spec) {
        $part =~ s/\A\s+//; $part =~ s/\s+\z//;
        next unless $part =~ /\S/;
        if ($part =~ /\A(\d+)-(\d+)\z/) {
            push @indices, ($1 .. $2);
        }
        elsif ($part =~ /\A(\d+)\z/) {
            push @indices, $1;
        }
    }
    @indices = (1) unless @indices;
    return @indices;
}

# ----------------------------------------------------------------
# CALL
# ----------------------------------------------------------------
sub _cmd_call {
    my ($class, $rest, $opts_ref) = @_;
    $rest =~ s/\A\s+//;

    if ($rest =~ /\A:([A-Za-z_][A-Za-z0-9_]*)(.*)/i) {
        my ($lbl, $argstr) = (uc($1), $2);
        $argstr =~ s/\A\s+//;
        my @args = split /\s+/, $argstr;
        for my $n (1 .. 9) {
            BATsh::Env->set("%$n", defined($args[$n-1]) ? $args[$n-1] : '');
        }
        if (defined $opts_ref->{'_batsh'}) {
            $opts_ref->{'_batsh'}->call_sub($lbl);
        }
        return 0;
    }

    if ($rest =~ /(\S+\.batsh)(.*)/i) {
        my $file = $1;
        if (defined $opts_ref->{'_batsh'}) {
            $opts_ref->{'_batsh'}->source_file($file);
        }
        return 0;
    }

    # CALL cmd args: execute with double-expansion
    # Re-expand the already-expanded string (second pass)
    my $reexpanded = BATsh::Env->expand_cmd($rest);
    return _cmd_external($reexpanded, '');
}

# ----------------------------------------------------------------
# CD / CHDIR
# ----------------------------------------------------------------
sub _cmd_cd {
    my ($rest) = @_;
    $rest =~ s/\A\s+//; $rest =~ s/\s+\z//;
    $rest =~ s/\A"//; $rest =~ s/"\z//;
    if ($rest eq '' || $rest =~ /\A\/D\s*\z/i) {
        print Cwd::cwd(), "\n";
        return 0;
    }
    $rest =~ s/\A\/D\s*//i;
    unless (chdir($rest)) {
        print "The system cannot find the path specified.\n";
        $ERRORLEVEL = 1;
        return 1;
    }
    BATsh::Env->set('CD', Cwd::cwd());
    $ERRORLEVEL = 0;
    return 0;
}

# ----------------------------------------------------------------
# DIR
# ----------------------------------------------------------------
sub _cmd_dir {
    my ($rest) = @_;
    $rest =~ s/\A\s+//; $rest =~ s/\s+\z//;
    my $target = $rest eq '' ? '.' : $rest;
    $target =~ s/\s*\/[A-Za-z:]+//g;
    $target =~ s/\s+\z//;
    $target = '.' if $target eq '';
    $target =~ s/\A"//; $target =~ s/"\z//;
    unless (-e $target) { print "File Not Found\n"; $ERRORLEVEL = 1; return 1 }
    local *DH;
    if (-d $target) {
        opendir(DH, $target) or do { print "Access denied.\n"; return 1 };
        my @entries = sort readdir(DH);
        closedir(DH);
        print " Directory of $target\n\n";
        for my $e (@entries) {
            next if $e eq '.' || $e eq '..';
            my $full = "$target/$e";
            if (-d $full) { printf "%-40s <DIR>\n", $e }
            else          { printf "%-40s %12d\n", $e, (-s $full) }
        }
    }
    else { printf "%-40s %12d\n", $target, (-s $target) }
    $ERRORLEVEL = 0;
    return 0;
}

# ----------------------------------------------------------------
# File operations
# ----------------------------------------------------------------
sub _cmd_copy {
    my ($rest) = @_;
    $rest =~ s/\A\s+//; $rest =~ s/\s*\/[YN]\s*//gi;
    my ($src, $dst) = split /\s+/, $rest, 2;
    unless (defined $src && defined $dst) { print "The syntax of the command is incorrect.\n"; return 1 }
    $src =~ s/\A"//; $src =~ s/"\z//;
    $dst =~ s/\A"//; $dst =~ s/"\z//;
    unless (File::Copy::copy($src, $dst)) {
        print "The system cannot find the file specified.\n"; $ERRORLEVEL = 1; return 1
    }
    print "        1 file(s) copied.\n"; $ERRORLEVEL = 0; return 0;
}

sub _cmd_del {
    my ($rest) = @_;
    $rest =~ s/\A\s+//; $rest =~ s/\s*\/[A-Za-z:]+//g; $rest =~ s/\s+\z//;
    $rest =~ s/\A"//; $rest =~ s/"\z//;
    my @files = glob($rest);
    @files = ($rest) unless @files;
    for my $f (@files) {
        unlink($f) or print "Could not find $f\n";
    }
    $ERRORLEVEL = 0; return 0;
}

sub _cmd_move {
    my ($rest) = @_;
    $rest =~ s/\A\s+//; $rest =~ s/\s*\/[YN]\s*//gi;
    my ($src, $dst) = split /\s+/, $rest, 2;
    unless (defined $src && defined $dst) { print "The syntax of the command is incorrect.\n"; return 1 }
    $src =~ s/\A"//; $src =~ s/"\z//;
    $dst =~ s/\A"//; $dst =~ s/"\z//;
    unless (File::Copy::move($src, $dst)) {
        print "The system cannot find the file specified.\n"; $ERRORLEVEL = 1; return 1
    }
    print "        1 file(s) moved.\n"; $ERRORLEVEL = 0; return 0;
}

sub _cmd_mkdir {
    my ($rest) = @_;
    $rest =~ s/\A\s+//; $rest =~ s/\s+\z//; $rest =~ s/\A"//; $rest =~ s/"\z//;
    if (-d $rest) { print "A subdirectory or file $rest already exists.\n"; $ERRORLEVEL = 1; return 1 }
    File::Path::mkpath($rest); $ERRORLEVEL = 0; return 0;
}

sub _cmd_rmdir {
    my ($rest) = @_;
    $rest =~ s/\A\s+//;
    my $recurse = ($rest =~ s/\s*\/S\s*//i) ? 1 : 0;
    $rest =~ s/\s*\/Q\s*//i; $rest =~ s/\s+\z//; $rest =~ s/\A"//; $rest =~ s/"\z//;
    if ($recurse) { File::Path::rmtree($rest) }
    else {
        unless (rmdir($rest)) {
            print "The directory is not empty.\n"; $ERRORLEVEL = 1; return 1
        }
    }
    $ERRORLEVEL = 0; return 0;
}

sub _cmd_rename {
    my ($rest) = @_;
    $rest =~ s/\A\s+//;
    my ($src, $dst) = split /\s+/, $rest, 2;
    unless (defined $src && defined $dst) { print "The syntax of the command is incorrect.\n"; return 1 }
    unless (rename($src, $dst)) {
        print "Could not rename $src to $dst: $!\n"; $ERRORLEVEL = 1; return 1
    }
    $ERRORLEVEL = 0; return 0;
}

sub _cmd_type {
    my ($rest) = @_;
    $rest =~ s/\A\s+//; $rest =~ s/\s+\z//; $rest =~ s/\A"//; $rest =~ s/"\z//;
    local *TFH;
    unless (open(TFH, $rest)) {
        print "The system cannot find the file specified.\n"; $ERRORLEVEL = 1; return 1
    }
    while (<TFH>) { print }
    close(TFH);
    $ERRORLEVEL = 0; return 0;
}

# ----------------------------------------------------------------
# External command
# ----------------------------------------------------------------
sub _cmd_external {
    my ($cmd, $rest) = @_;
    $rest = '' unless defined $rest;
    $rest =~ s/\A\s+//;
    my $full = $rest ne '' ? "$cmd $rest" : $cmd;
    $full = _unescape_caret($full);
    BATsh::Env->sync_to_env();
    my $rc = system($full);
    $ERRORLEVEL = ($rc == 0) ? 0 : (($rc >> 8) || 1);
    return $ERRORLEVEL;
}

# ----------------------------------------------------------------
# _split_cmd: split "COMMAND rest" respecting quotes
# ----------------------------------------------------------------
sub _split_cmd {
    my ($line) = @_;
    if ($line =~ /\A(\S+)\s*(.*)\z/s) {
        return ($1, $2);
    }
    return ($line, '');
}

sub _warn { print STDERR "[BATsh::CMD] $_[0]\n" }

# ----------------------------------------------------------------
# Accessors
# ----------------------------------------------------------------
sub errorlevel      { return $ERRORLEVEL }
sub set_errorlevel  { $ERRORLEVEL = $_[1] }
sub echo_on         { return $ECHO_ON }

BEGIN {
    eval { require Cwd };
    if ($@) {
        eval 'sub Cwd::cwd { return $ENV{CD} || "." }';
    }
}

1;

__END__

=head1 NAME

BATsh::CMD - Pure Perl cmd.exe interpreter for BATsh

=head1 SYNOPSIS

  # Used internally by BATsh; not normally called directly.
  BATsh::CMD::exec_block('BATsh::CMD', \@lines, _batsh => $batsh);

  # Read ERRORLEVEL after execution
  my $rc = BATsh::CMD::errorlevel('BATsh::CMD');

=head1 DESCRIPTION

BATsh::CMD implements the Windows cmd.exe command set entirely in Perl.
No external cmd.exe is required.

=head2 Supported Commands

  ECHO text, ECHO., ECHO OFF/ON, @ECHO OFF
  SET VAR=value, SET /A expr (arithmetic with + - * / % ^ & | ~ << >>)
  SET /P VAR=PromptString (interactive prompt input)
  IF "A"=="B" ... ELSE ..., IF /I (case-insensitive), IF NOT
  IF EXIST "path with spaces", IF DEFINED var, IF ERRORLEVEL n
  FOR %%V IN (list) DO ...
  FOR /L %%V IN (start,step,end) DO ...
  FOR /F "options" %%V IN (source) DO ...
  GOTO :label, :label, GOTO :EOF
  CALL :label [args], CALL file.batsh
  SETLOCAL [ENABLEDELAYEDEXPANSION|DISABLEDELAYEDEXPANSION], ENDLOCAL
  CD [/D] [path], DIR, COPY [/Y], DEL, MOVE, MKDIR, RMDIR [/S /Q]
  REN, TYPE, PAUSE, EXIT [/B] [code], CLS, TITLE, VER, PUSHD, POPD
  SHIFT, SHIFT /N
  cmd1 | cmd2  (pipeline via temporary file)
  cmd1 & cmd2  (sequential)
  cmd1 && cmd2  (conditional-and)
  cmd1 || cmd2  (conditional-or)

I/O redirection:
  > file     stdout overwrite
  >> file    stdout append
  < file     stdin
  2> file    stderr overwrite
  2>> file   stderr append
  2>&1       stderr to stdout

=head2 Variable Expansion

C<%VAR%> references are expanded before each line executes.
Variable names are case-insensitive (stored in uppercase internally).

Inside parenthesised IF and FOR bodies, C<%VAR%> is expanded B<at parse
time> (before the block runs), matching cmd.exe's behaviour.  To observe
a value updated inside the same block, enable delayed expansion:

  SETLOCAL ENABLEDELAYEDEXPANSION
  SET X=old
  IF 1==1 (
      SET X=new
      ECHO !X!    &:: new  -- delayed, runtime
      ECHO %X%    &:: old  -- immediate, parse-time
  )
  ENDLOCAL

=head2 Escape Character

The C<^> character escapes the following character:

  ECHO a^&b      ->  a&b    (& not a compound separator)
  ECHO a^^b      ->  a^b    (literal ^)
  ECHO hello^    ->  helloworld  (^ at end-of-line joins next line)
  world

=head2 I/O Redirection

  CMD > file      stdout overwrite
  CMD >> file     stdout append
  CMD 2> file     stderr overwrite
  CMD 2>> file    stderr append
  CMD < file      stdin from file

C<^E<gt>> is an escaped C<E<gt>> and is B<not> treated as a redirect.

=head2 Compound Commands

  cmd1 & cmd2     run cmd2 unconditionally after cmd1
  cmd1 && cmd2    run cmd2 only if cmd1 succeeded (ERRORLEVEL 0)
  cmd1 || cmd2    run cmd2 only if cmd1 failed    (ERRORLEVEL != 0)

=head2 FOR /F Options

  tokens=1,2-4   which token columns to capture (1-based)
  tokens=1*       token 1 to %%a; remainder to %%b
  delims=CHARS    field separator characters (default: space and tab)
  skip=N          skip first N lines
  eol=C           skip lines beginning with C (default: ;)
  usebackq        "file" reads a file; 'cmd' runs a command

Sources: bare filename, C<"quoted filename">, C<'command'>,
or C<("literal string")>.

=head2 ERRORLEVEL

C<IF ERRORLEVEL n> is true when ERRORLEVEL E<gt>= n (not equality).
ECHO does B<not> reset ERRORLEVEL (unlike some broken implementations).

=head2 Accessors

  BATsh::CMD::errorlevel('BATsh::CMD')        -- current ERRORLEVEL
  BATsh::CMD::set_errorlevel('BATsh::CMD', n) -- set ERRORLEVEL
  BATsh::CMD::echo_on('BATsh::CMD')           -- current ECHO state

=head1 AUTHOR

INABA Hitoshi E<lt>ina.cpan@gmail.comE<gt>

=head1 LICENSE

Same as Perl itself.

=cut
