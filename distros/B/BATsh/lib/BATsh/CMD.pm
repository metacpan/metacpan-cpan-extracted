package BATsh::CMD;
######################################################################
#
# BATsh::CMD - Pure Perl cmd.exe interpreter
#
# Implements the cmd.exe command set in Perl.
# No external cmd.exe or shell required.
#
# Supported:
#   ECHO, @ECHO OFF/ON
#   SET VAR=value, SET /A expr
#   IF string==string, IF EXIST, IF NOT, IF ERRORLEVEL, IF DEFINED
#   IF (...) ELSE (...)
#   FOR %%V IN (list) DO cmd
#   FOR /L %%V IN (start,step,end) DO cmd
#   FOR /F ... (limited)
#   GOTO :label, :label
#   CALL :label [args], CALL file.batsh
#   SETLOCAL, ENDLOCAL
#   CD / CHDIR
#   DIR
#   COPY, DEL / ERASE, MOVE, MKDIR / MD, RMDIR / RD, REN / RENAME
#   TYPE
#   PAUSE
#   EXIT [/B] [code]
#   CLS
#   REM / :: (comments)
#   TITLE
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
$VERSION = '0.01';
$VERSION = $VERSION;

require BATsh::Env;

# ----------------------------------------------------------------
# State
# ----------------------------------------------------------------
my $ECHO_ON    = 1;   # @ECHO OFF sets to 0
my $ERRORLEVEL = 0;   # last command exit code

# For GOTO support: set by exec_block, read by exec_line
my $_GOTO_LABEL = '';   # '' means no pending GOTO

# ----------------------------------------------------------------
# Public: execute an array of CMD lines
# Returns exit code (0 = success)
# ----------------------------------------------------------------
sub exec_block {
    my ($class, $lines_ref, %opts) = @_;
    my @lines = @{$lines_ref};

    # Build label index: label name (uppercase) -> line index
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

        my $rc = _exec_line($class, $raw, \@lines, \%labels, \$i, \%opts);

        # GOTO: jump to label
        if ($_GOTO_LABEL ne '') {
            my $lbl = $_GOTO_LABEL;
            $_GOTO_LABEL = '';
            if (exists $labels{$lbl}) {
                $i = $labels{$lbl} + 1;
            }
            elsif ($lbl eq 'EOF') {
                last;   # GOTO :EOF exits the block
            }
            else {
                _warn("GOTO: label :$lbl not found");
            }
            next;
        }

        # EXIT /B or EXIT with code
        if (defined $rc && $rc eq '__EXIT__') {
            return $ERRORLEVEL;
        }
    }
    return $ERRORLEVEL;
}

# ----------------------------------------------------------------
# Execute one logical line (may recurse for IF bodies, FOR bodies)
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
    return 0 if $line =~ /\A#/;   # SH-style comment inside CMD block

    if (!$pre_expanded) {
        # For FOR lines: protect %%V AND defer DO-part expansion to the loop
        if ($line =~ /\AFOR\s/i) {
            # Only expand the IN(list) portion; protect the DO part
            if ($line =~ /\A(FOR\s+(?:\/[A-Za-z]\s+)?%%[A-Za-z]\s+(?:\/[A-Za-z]\s+)?IN\s*\([^)]*\)\s+DO\s+)(.*)\z/i) {
                my ($for_head, $do_part) = ($1, $2);
                # Protect %%V in head
                $for_head =~ s/%%([A-Za-z])/"\x00FOR_$1\x00"/ge;
                $for_head = BATsh::Env->expand_cmd($for_head);
                $for_head =~ s/\x00FOR_([A-Za-z])\x00/%%$1/g;
                # Protect ALL %VAR% in do_part with placeholder so loop re-expands them
                $do_part =~ s/%%([A-Za-z])/"\x00FOR_$1\x00"/ge;
                $do_part =~ s/%([^%\r\n]+)%/"\x00PCT_$1\x00"/ge;
                $line = $for_head . $do_part;
            }
            else {
                $line =~ s/%%([A-Za-z])/"\x00FOR_$1\x00"/ge;
                $line = BATsh::Env->expand_cmd($line);
                $line =~ s/\x00FOR_([A-Za-z])\x00/%%$1/g;
            }
        }
        else {
            $line =~ s/%%([A-Za-z])/"\x00FOR_$1\x00"/ge;
            $line = BATsh::Env->expand_cmd($line);
            $line =~ s/\x00FOR_([A-Za-z])\x00/%%$1/g;
        }
    }

    return _dispatch($class, $line, $lines_ref, $labels_ref, $i_ref, $opts_ref);
}

# ----------------------------------------------------------------
# Command dispatcher
# ----------------------------------------------------------------
sub _dispatch {
    my ($class, $line, $lines_ref, $labels_ref, $i_ref, $opts_ref) = @_;

    # Tokenize: first word is the command
    my ($cmd, $rest) = _split_cmd($line);
    return 0 unless defined $cmd && $cmd ne '';

    my $CMD = uc($cmd);

    if ($CMD eq 'ECHO') {
        return _cmd_echo($rest);
    }
    if ($CMD eq '@ECHO') {
        # already stripped @ above; should not reach here
        return _cmd_echo($rest);
    }
    if ($CMD eq 'SET') {
        return _cmd_set($rest);
    }
    if ($CMD eq 'IF') {
        return _cmd_if($class, $line, $lines_ref, $labels_ref, $i_ref, $opts_ref);
    }
    if ($CMD eq 'FOR') {
        return _cmd_for($class, $line, $lines_ref, $labels_ref, $i_ref, $opts_ref);
    }
    if ($CMD eq 'GOTO') {
        $rest =~ s/\A\s+//;
        $rest =~ s/\s+\z//;
        $rest =~ s/\A://;
        $_GOTO_LABEL = uc($rest);
        return 0;
    }
    if ($CMD eq 'CALL') {
        return _cmd_call($class, $rest, $opts_ref);
    }
    if ($CMD eq 'SETLOCAL') {
        BATsh::Env::setlocal();
        return 0;
    }
    if ($CMD eq 'ENDLOCAL') {
        BATsh::Env::endlocal();
        return 0;
    }
    if ($CMD eq 'CD' || $CMD eq 'CHDIR') {
        return _cmd_cd($rest);
    }
    if ($CMD eq 'DIR') {
        return _cmd_dir($rest);
    }
    if ($CMD eq 'COPY') {
        return _cmd_copy($rest);
    }
    if ($CMD eq 'DEL' || $CMD eq 'ERASE') {
        return _cmd_del($rest);
    }
    if ($CMD eq 'MOVE') {
        return _cmd_move($rest);
    }
    if ($CMD eq 'MKDIR' || $CMD eq 'MD') {
        return _cmd_mkdir($rest);
    }
    if ($CMD eq 'RMDIR' || $CMD eq 'RD') {
        return _cmd_rmdir($rest);
    }
    if ($CMD eq 'REN' || $CMD eq 'RENAME') {
        return _cmd_rename($rest);
    }
    if ($CMD eq 'TYPE') {
        return _cmd_type($rest);
    }
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
    if ($CMD eq 'CLS') {
        print "\033[2J\033[H";   # ANSI clear screen
        return 0;
    }
    if ($CMD eq 'TITLE') {
        # Set terminal title (best-effort)
        print "\033]0;$rest\007";
        return 0;
    }
    if ($CMD eq 'VER') {
        print "BATsh [Version $BATsh::VERSION]\n";
        return 0;
    }
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

    # Unknown command: try as external executable
    return _cmd_external($cmd, $rest);
}

# ----------------------------------------------------------------
# ECHO
# ----------------------------------------------------------------
sub _cmd_echo {
    my ($rest) = @_;
    $rest =~ s/\A\s+//;

    # @ECHO OFF / ON
    if ($rest =~ /\AOFF\s*\z/i) { $ECHO_ON = 0; return 0; }
    if ($rest =~ /\AON\s*\z/i)  { $ECHO_ON = 1; return 0; }

    # ECHO. (empty line)
    if ($rest =~ /\A\.\s*\z/) { print "\n"; return 0; }

    # ECHO with no args: show state
    if ($rest =~ /\A\s*\z/) {
        print "ECHO is " . ($ECHO_ON ? "on" : "off") . "\n";
        return 0;
    }

    print "$rest\n";
    $ERRORLEVEL = 0;
    return 0;
}

# ----------------------------------------------------------------
# SET
# ----------------------------------------------------------------
sub _cmd_set {
    my ($rest) = @_;
    $rest =~ s/\A\s+//;

    # SET /A arithmetic
    if ($rest =~ s/\A\/A\s*//i) {
        # Check for VAR=expr form
        if ($rest =~ /\A\s*([A-Za-z_][A-Za-z0-9_]*)\s*=(.*)\z/) {
            my ($var, $expr) = ($1, $2);
            my $result = _eval_arith($expr);
            BATsh::Env->set($var, $result);
        }
        else {
            my $result = _eval_arith($rest);
            print "$result\n";
        }
        $ERRORLEVEL = 0;
        return 0;
    }

    # SET with no args: display all variables
    if ($rest =~ /\A\s*\z/) {
        for my $k (sort keys %BATsh::Env::STORE) {
            print "$k=$BATsh::Env::STORE{$k}\n";
        }
        return 0;
    }

    # SET VAR=value
    if ($rest =~ /\A([A-Za-z_][A-Za-z0-9_]*)\s*=(.*)/) {
        BATsh::Env->set($1, $2);
        $ERRORLEVEL = 0;
        return 0;
    }

    # SET VAR (display matching)
    if ($rest =~ /\A([A-Za-z_][A-Za-z0-9_]*)\s*\z/) {
        my $prefix = $1;
        for my $k (sort keys %BATsh::Env::STORE) {
            if (index(uc($k), uc($prefix)) == 0) {
                print "$k=$BATsh::Env::STORE{$k}\n";
            }
        }
        return 0;
    }

    return 0;
}

# ----------------------------------------------------------------
# Arithmetic evaluator for SET /A
# Supports: + - * / %% () and variable references
# ----------------------------------------------------------------
sub _eval_arith {
    my ($expr) = @_;
    # Replace variable names with their numeric values
    $expr =~ s/([A-Za-z_][A-Za-z0-9_]*)/
        do { my $v = BATsh::Env->get($1); defined $v && $v =~ m|^\d+$| ? $v : 0 }
    /ge;
    # %% in cmd.exe is modulo
    $expr =~ s/%%/%/g;
    # Evaluate safely: only allow digits, operators, parens, whitespace
    if ($expr =~ /\A[\d\s\+\-\*\/\%\(\)]+\z/) {
        my $result = eval $expr;
        return defined $result ? int($result) : 0;
    }
    return 0;
}

# ----------------------------------------------------------------
# IF
# ----------------------------------------------------------------
sub _cmd_if {
    my ($class, $line, $lines_ref, $labels_ref, $i_ref, $opts_ref) = @_;

    # Strip "IF" from front
    (my $rest = $line) =~ s/\AIF\s+//i;

    my $negate = 0;
    if ($rest =~ s/\ANOT\s+//i) { $negate = 1; }

    my $condition = 0;

    # IF ERRORLEVEL n
    if ($rest =~ s/\AERRORLEVEL\s+(\d+)\s*//i) {
        $condition = ($ERRORLEVEL >= int($1)) ? 1 : 0;
    }
    # IF EXIST path
    elsif ($rest =~ s/\AEXIST\s+(\S+)\s*//i) {
        $condition = (-e $1) ? 1 : 0;
    }
    # IF DEFINED var
    elsif ($rest =~ s/\ADEFINED\s+([A-Za-z_][A-Za-z0-9_]*)\s*//i) {
        $condition = BATsh::Env->exists_var($1) ? 1 : 0;
    }
    # IF "str1"=="str2" or IF str1==str2
    elsif ($rest =~ s/\A("?[^"]*"?)\s*==\s*("?[^"]*"?)\s*//) {
        my ($a, $b) = ($1, $2);
        $a =~ s/\A"//; $a =~ s/"\z//;
        $b =~ s/\A"//; $b =~ s/"\z//;
        $condition = ($a eq $b) ? 1 : 0;
    }
    # IF /I "str1"=="str2" (case-insensitive)
    elsif ($rest =~ s/\A\/I\s+("?[^"]*"?)\s*==\s*("?[^"]*"?)\s*//i) {
        my ($a, $b) = ($1, $2);
        $a =~ s/\A"//; $a =~ s/"\z//;
        $b =~ s/\A"//; $b =~ s/"\z//;
        $condition = (lc($a) eq lc($b)) ? 1 : 0;
    }

    $condition = !$condition if $negate;

    # Parse the THEN body (may be parenthesised block)
    my ($then_body, $else_body) = _parse_if_bodies($rest, $lines_ref, $i_ref);

    if ($condition) {
        return _exec_body($class, $then_body, $lines_ref, $labels_ref, $i_ref, $opts_ref);
    }
    elsif (defined $else_body) {
        return _exec_body($class, $else_body, $lines_ref, $labels_ref, $i_ref, $opts_ref);
    }
    return 0;
}

# Parse IF then/else bodies from the rest of the line and possibly
# subsequent lines (parenthesised multi-line blocks).
sub _parse_if_bodies {
    my ($rest, $lines_ref, $i_ref) = @_;

    my ($then_body, $else_body);
    $rest =~ s/\A\s+//;

    if ($rest =~ s/\A\(//) {
        # Multi-line parenthesised THEN block; _read_paren_block handles ) ELSE (
        $then_body = _read_paren_block($rest, $lines_ref, $i_ref, \$else_body);
    }
    else {
        # Single-line: IF cond cmd [ELSE cmd]
        if ($rest =~ s/\s+ELSE\s+(.+)\z//i) { $else_body = $1 }
        $then_body = $rest;
    }

    return ($then_body, $else_body);
}

# Read lines until closing ) for a parenthesised block.
# Returns the body content.  On exit, $$i_ref points past the closing line.
# If the closing line is ") ELSE (" we also return the else body.
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

        # Check for ) ELSE ( or ) ELSE cmd pattern before counting parens
        if ($depth == 1 && $ls =~ /\A\)\s*ELSE\s*\(\s*\z/i) {
            # Collect else body
            if (defined $else_ref) {
                $$else_ref = _read_paren_block('', $lines_ref, $i_ref);
            }
            last;
        }
        if ($depth == 1 && $ls =~ /\A\)\s*ELSE\s+(.+)\z/i) {
            if (defined $else_ref) { $$else_ref = $1 }
            last;
        }

        # Count parens
        my $delta = 0; my $in_q = 0;
        for my $ch (split //, $l) {
            if ($ch eq '"') { $in_q = !$in_q }
            elsif (!$in_q) {
                $delta++ if $ch eq '(';
                $delta-- if $ch eq ')';
            }
        }
        $depth += $delta;

        if ($depth <= 0) {
            # Plain closing )
            $l =~ s/\)\s*\z//;
            push @body, $l if $l =~ /\S/;
            last;
        }
        push @body, $l;
    }

    return join("\n", @body);
}

# Execute a body (string of lines or single command)
sub _exec_body {
    my ($class, $body, $lines_ref, $labels_ref, $i_ref, $opts_ref, $expanded) = @_;
    return 0 unless defined $body && $body =~ /\S/;
    $expanded = 0 unless defined $expanded;
    # Use a private lines array and i_ref so that nested _read_paren_block
    # calls inside the body do not consume lines from the parent block.
    my @sub_lines = split /\n/, $body;
    my $sub_i = 0;
    my %sub_labels = ();
    for my $j (0 .. $#sub_lines) {
        my $ls = $sub_lines[$j]; $ls =~ s/\r?\n\z//; $ls =~ s/\A\s+//;
        if ($ls =~ /\A:([A-Za-z_][A-Za-z0-9_]*)\s*\z/) {
            $sub_labels{uc($1)} = $j;
        }
    }
    while ($sub_i <= $#sub_lines) {
        my $sl = $sub_lines[$sub_i];
        $sub_i++;
        my $rc = _exec_line($class, $sl, \@sub_lines, \%sub_labels, \$sub_i, $opts_ref, $expanded);
        return $rc if defined $rc && $rc eq '__EXIT__';
        if ($_GOTO_LABEL ne '') {
            my $lbl = $_GOTO_LABEL;
            $_GOTO_LABEL = '';
            if (exists $sub_labels{$lbl}) {
                $sub_i = $sub_labels{$lbl} + 1;
            } else {
                # propagate GOTO to parent
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

    # FOR %%V IN (list) DO command
    if ($line =~ /\AFOR\s+(?:%%|\x00FOR_)([A-Za-z])(?:\x00)?\s+IN\s*\(([^)]*)\)\s+DO\s+(.*)/i) {
        my ($var, $list_str, $do_part) = ($1, $2, $3);
        my @items = split /[\s,]+/, $list_str;
        # Expand wildcards
        my @expanded = ();
        for my $item (@items) {
            $item =~ s/\A\s+//; $item =~ s/\s+\z//;
            next if $item eq '';
            if ($item =~ /[*?]/) {
                my @glob = glob($item);
                push @expanded, @glob ? @glob : ($item);
            }
            else {
                push @expanded, $item;
            }
        }
        # Detect paren block and read it ONCE before the loop
        my $for_in_paren_body = undef;
        {
            # probe: check if do_part is just "(" after stripping placeholders
            my $probe = $do_part;
            $probe =~ s/\x00FOR_[A-Za-z]\x00//g;
            $probe =~ s/\x00PCT_[^\x00]+\x00//g;
            $probe =~ s/%%[A-Za-z]//g;
            if ($probe =~ /\A\s*\(\s*\z/) {
                $for_in_paren_body = _read_paren_block('', $lines_ref, $i_ref);
            }
        }
        for my $val (@expanded) {
            BATsh::Env->set("%%$var", $val);
            if (defined $for_in_paren_body) {
                # Paren block: substitute loop var + PCT placeholders, then per-line expand
                my @body_lines = split /\n/, $for_in_paren_body;
                for my $bl (@body_lines) {
                    $bl =~ s/%%$var/$val/g;
                    $bl =~ s/\x00FOR_$var\x00/$val/g;
                    $bl =~ s/\x00PCT_([^\x00]+)\x00/%$1%/g;
                }
                _exec_body($class, join("\n", @body_lines),
                           $lines_ref, $labels_ref, $i_ref, $opts_ref, 0);
            }
            else {
                my $do_line = $do_part;
                $do_line =~ s/%%$var/$val/g;
                $do_line =~ s/\x00FOR_([A-Za-z])\x00/%%$1/g;
                $do_line =~ s/\x00PCT_([^\x00]+)\x00/%$1%/g;
                $do_line = BATsh::Env->expand_cmd($do_line);
                _exec_line($class, $do_line, $lines_ref, $labels_ref, $i_ref, $opts_ref, 1);
            }
            last if $_GOTO_LABEL ne '';
        }
        return 0;
    }

    # FOR /L %%V IN (start,step,end) DO command
    if ($line =~ /\AFOR\s+\/L\s+(?:%%|\x00FOR_)([A-Za-z])(?:\x00)?\s+IN\s*\(([^)]*)\)\s+DO\s+(.*)/i) {
        my ($var, $range, $do_part) = ($1, $2, $3);
        my ($start, $step, $end) = split /,/, $range;
        $start = defined $start ? int($start) : 0;
        $step  = defined $step  ? int($step)  : 1;
        $end   = defined $end   ? int($end)   : 0;
        $step  = 1 if $step == 0;
        # If do_part is a paren block, read it once before looping
        my $paren_body_l = undef;
        {
            my $probe = $do_part;
            $probe =~ s/%%$var/0/g;
            $probe =~ s/\x00FOR_([A-Za-z])\x00/%%$1/g;
            $probe =~ s/\x00PCT_([^\x00]+)\x00/%$1%/g;
            # No expand_cmd needed just to check if it's a (
            if ($probe =~ /\A\s*\(\s*\z/) {
                $paren_body_l = _read_paren_block('', $lines_ref, $i_ref);
            }
        }
        my $i = $start;
        while (($step > 0 && $i <= $end) || ($step < 0 && $i >= $end)) {
            BATsh::Env->set("%%$var", $i);
            if (defined $paren_body_l) {
                my @body_lines = split /\n/, $paren_body_l;
                for my $bl (@body_lines) {
                    $bl =~ s/%%$var/$i/g;
                    $bl =~ s/\x00FOR_$var\x00/$i/g;   # placeholder form
                    $bl =~ s/\x00PCT_([^\x00]+)\x00/%$1%/g;
                }
                _exec_body($class, join("\n", @body_lines),
                           $lines_ref, $labels_ref, $i_ref, $opts_ref, 0);
            }
            else {
                my $do_line = $do_part;
                $do_line =~ s/%%$var/$i/g;
                $do_line =~ s/\x00FOR_([A-Za-z])\x00/%%$1/g;
                $do_line =~ s/\x00PCT_([^\x00]+)\x00/%$1%/g;
                $do_line = BATsh::Env->expand_cmd($do_line);
                _exec_line($class, $do_line, $lines_ref, $labels_ref, $i_ref, $opts_ref, 1);
            }
            last if $_GOTO_LABEL ne '';
            $i += $step;
        }
        return 0;
    }

    _warn("FOR: unsupported syntax: $line");
    return 1;
}

# ----------------------------------------------------------------
# CALL
# ----------------------------------------------------------------
sub _cmd_call {
    my ($class, $rest, $opts_ref) = @_;
    $rest =~ s/\A\s+//;

    # CALL :label [args]
    if ($rest =~ /\A:([A-Za-z_][A-Za-z0-9_]*)(.*)/i) {
        my ($lbl, $argstr) = (uc($1), $2);
        $argstr =~ s/\A\s+//;
        my @args = split /\s+/, $argstr;
        # Store args as %1 %2 ...
        for my $n (1 .. 9) {
            BATsh::Env->set("%$n", defined($args[$n-1]) ? $args[$n-1] : '');
        }
        # Delegate to BATsh (sub-routine call)
        if (defined $opts_ref->{'_batsh'}) {
            $opts_ref->{'_batsh'}->call_sub($lbl);
        }
        return 0;
    }

    # CALL file.batsh
    if ($rest =~ /(\S+\.batsh)(.*)/i) {
        my $file = $1;
        if (defined $opts_ref->{'_batsh'}) {
            $opts_ref->{'_batsh'}->source_file($file);
        }
        return 0;
    }

    # CALL external command
    return _cmd_external($rest, '');
}

# ----------------------------------------------------------------
# CD / CHDIR
# ----------------------------------------------------------------
sub _cmd_cd {
    my ($rest) = @_;
    $rest =~ s/\A\s+//;
    $rest =~ s/\s+\z//;
    if ($rest eq '' || $rest eq '/D') {
        # Print current directory
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
    $rest =~ s/\A\s+//;
    $rest =~ s/\s+\z//;
    my $target = $rest eq '' ? '.' : $rest;
    # Strip switches
    $target =~ s/\s*\/[A-Za-z:]+//g;
    $target =~ s/\s+\z//;
    $target = '.' if $target eq '';
    unless (-e $target) {
        print "File Not Found\n";
        $ERRORLEVEL = 1;
        return 1;
    }
    local *DH;
    if (-d $target) {
        opendir(DH, $target) or do { print "Access denied.\n"; return 1 };
        my @entries = sort readdir(DH);
        closedir(DH);
        print " Directory of $target\n\n";
        for my $e (@entries) {
            next if $e eq '.' || $e eq '..';
            my $full = "$target/$e";
            if (-d $full) {
                printf "%-40s <DIR>\n", $e;
            }
            else {
                my $size = -s $full;
                printf "%-40s %12d\n", $e, $size;
            }
        }
    }
    else {
        my $size = -s $target;
        printf "%-40s %12d\n", $target, $size;
    }
    $ERRORLEVEL = 0;
    return 0;
}

# ----------------------------------------------------------------
# COPY
# ----------------------------------------------------------------
sub _cmd_copy {
    my ($rest) = @_;
    $rest =~ s/\A\s+//;
    $rest =~ s/\s*\/[YN]\s*//gi;
    my ($src, $dst) = split /\s+/, $rest, 2;
    unless (defined $src && defined $dst) {
        print "The syntax of the command is incorrect.\n";
        return 1;
    }
    unless (File::Copy::copy($src, $dst)) {
        print "The system cannot find the file specified.\n";
        $ERRORLEVEL = 1;
        return 1;
    }
    print "        1 file(s) copied.\n";
    $ERRORLEVEL = 0;
    return 0;
}

# ----------------------------------------------------------------
# DEL / ERASE
# ----------------------------------------------------------------
sub _cmd_del {
    my ($rest) = @_;
    $rest =~ s/\A\s+//;
    $rest =~ s/\s*\/[A-Za-z:]+//g;
    $rest =~ s/\s+\z//;
    my @files = glob($rest);
    @files = ($rest) unless @files;
    my $count = 0;
    for my $f (@files) {
        if (unlink($f)) { $count++ }
        else { print "Could not find $f\n" }
    }
    $ERRORLEVEL = 0;
    return 0;
}

# ----------------------------------------------------------------
# MOVE
# ----------------------------------------------------------------
sub _cmd_move {
    my ($rest) = @_;
    $rest =~ s/\A\s+//;
    $rest =~ s/\s*\/[YN]\s*//gi;
    my ($src, $dst) = split /\s+/, $rest, 2;
    unless (defined $src && defined $dst) {
        print "The syntax of the command is incorrect.\n";
        return 1;
    }
    unless (File::Copy::move($src, $dst)) {
        print "The system cannot find the file specified.\n";
        $ERRORLEVEL = 1;
        return 1;
    }
    print "        1 file(s) moved.\n";
    $ERRORLEVEL = 0;
    return 0;
}

# ----------------------------------------------------------------
# MKDIR / MD
# ----------------------------------------------------------------
sub _cmd_mkdir {
    my ($rest) = @_;
    $rest =~ s/\A\s+//;
    $rest =~ s/\s+\z//;
    if (-d $rest) {
        print "A subdirectory or file $rest already exists.\n";
        $ERRORLEVEL = 1;
        return 1;
    }
    File::Path::mkpath($rest);
    $ERRORLEVEL = 0;
    return 0;
}

# ----------------------------------------------------------------
# RMDIR / RD
# ----------------------------------------------------------------
sub _cmd_rmdir {
    my ($rest) = @_;
    $rest =~ s/\A\s+//;
    my $recurse = ($rest =~ s/\s*\/S\s*//i) ? 1 : 0;
    $rest =~ s/\s*\/Q\s*//i;
    $rest =~ s/\s+\z//;
    if ($recurse) {
        File::Path::rmtree($rest);
    }
    else {
        unless (rmdir($rest)) {
            print "The directory is not empty.\n";
            $ERRORLEVEL = 1;
            return 1;
        }
    }
    $ERRORLEVEL = 0;
    return 0;
}

# ----------------------------------------------------------------
# REN / RENAME
# ----------------------------------------------------------------
sub _cmd_rename {
    my ($rest) = @_;
    $rest =~ s/\A\s+//;
    my ($src, $dst) = split /\s+/, $rest, 2;
    unless (defined $src && defined $dst) {
        print "The syntax of the command is incorrect.\n";
        return 1;
    }
    unless (rename($src, $dst)) {
        print "Could not rename $src to $dst: $!\n";
        $ERRORLEVEL = 1;
        return 1;
    }
    $ERRORLEVEL = 0;
    return 0;
}

# ----------------------------------------------------------------
# TYPE
# ----------------------------------------------------------------
sub _cmd_type {
    my ($rest) = @_;
    $rest =~ s/\A\s+//;
    $rest =~ s/\s+\z//;
    local *TFH;
    unless (open(TFH, $rest)) {
        print "The system cannot find the file specified.\n";
        $ERRORLEVEL = 1;
        return 1;
    }
    while (<TFH>) { print }
    close(TFH);
    $ERRORLEVEL = 0;
    return 0;
}

# ----------------------------------------------------------------
# External command (run as child process via Perl system())
# ----------------------------------------------------------------
sub _cmd_external {
    my ($cmd, $rest) = @_;
    $rest = '' unless defined $rest;
    $rest =~ s/\A\s+//;
    my $full = $rest ne '' ? "$cmd $rest" : $cmd;
    BATsh::Env->sync_to_env();
    my $rc = system($full);
    $ERRORLEVEL = ($rc == 0) ? 0 : (($rc >> 8) || 1);
    return $ERRORLEVEL;
}

# ----------------------------------------------------------------
# Split "COMMAND rest" from a line
# ----------------------------------------------------------------
sub _split_cmd {
    my ($line) = @_;
    if ($line =~ /\A(\S+)\s*(.*)\z/s) {
        return ($1, $2);
    }
    return ($line, '');
}

# ----------------------------------------------------------------
# Warn helper
# ----------------------------------------------------------------
sub _warn {
    my ($msg) = @_;
    print STDERR "[BATsh::CMD] $msg\n";
}

# ----------------------------------------------------------------
# Accessors for state (used by tests and BATsh.pm)
# ----------------------------------------------------------------
sub errorlevel      { return $ERRORLEVEL }
sub set_errorlevel  { $ERRORLEVEL = $_[1] }
sub echo_on         { return $ECHO_ON }

# Need Cwd for cd/dir
BEGIN {
    eval { require Cwd };
    if ($@) {
        # Cwd not available (very old Perl): provide minimal fallback
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

=head1 DESCRIPTION

BATsh::CMD implements the Windows cmd.exe command set entirely in Perl.
No external cmd.exe is required.

=head2 Supported Commands

  ECHO, @ECHO OFF/ON
  SET VAR=value, SET /A expr
  IF "A"=="B" ... ELSE ..., IF EXIST, IF DEFINED, IF ERRORLEVEL, IF NOT
  FOR %%V IN (list) DO ..., FOR /L %%V IN (s,step,e) DO ...
  GOTO :label, :label
  CALL :label [args], CALL file.batsh
  SETLOCAL, ENDLOCAL
  CD / CHDIR, DIR
  COPY, DEL / ERASE, MOVE, MKDIR / MD, RMDIR / RD, REN / RENAME
  TYPE, PAUSE, EXIT [/B] [code], CLS, TITLE, VER, PUSHD, POPD

=head2 Variable Expansion

C<%VAR%> references are expanded before each line executes.
C<%%V> in FOR loops is protected from premature expansion and
substituted with the loop value on each iteration.

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt>

=head1 LICENSE

Same as Perl itself.

=cut
