package BATsh::SH;
######################################################################
#
# BATsh::SH - Pure Perl sh/bash interpreter
#
# Implements sh/bash command set in Perl.
# No external sh or bash required.
#
# Supported:
#   Variable assignment: VAR=value
#   export VAR=value, export VAR, unset VAR
#   echo, printf
#   if/then/else/elif/fi
#   for VAR in list; do ... done
#   while condition; do ... done
#   until condition; do ... done
#   case $var in pattern) ... ;; esac
#   test / [ ... ]  (file tests, string, integer comparisons)
#   cd, pwd, exit
#   true, false, :
#   read VAR
#   $(( arithmetic ))
#   $(...) command substitution (recursive BATsh execution)
#   source / . file
#   local VAR=value  (inside function context)
#
######################################################################

use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }

use File::Spec ();
use Carp qw(croak);
use vars qw($VERSION);
$VERSION = '0.01';
$VERSION = $VERSION;

require BATsh::Env;

# ----------------------------------------------------------------
# State
# ----------------------------------------------------------------
my $LAST_STATUS = 0;   # $?
my @FUNCTION_STACK = ();   # for 'local' variable scoping

# Signal: pending exit
my $_EXIT_CODE    = undef;   # undef = no exit pending
my $_BREAK        = 0;       # break out of loop
my $_CONTINUE     = 0;       # continue next iteration
my $_RETURN       = 0;       # return from function/source

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

    # Expand variables and command substitutions
    $line = _expand($class, $line);

    # Strip trailing ;
    $line =~ s/\s*;\s*\z//;

    my ($cmd, $rest) = _split_sh($line);
    return 0 unless defined $cmd && $cmd ne '';

    my $lc_cmd = lc($cmd);

    # Simple assignment: VAR=value (no spaces around =)
    if ($cmd =~ /\A([A-Za-z_][A-Za-z0-9_]*)=(.*)\z/s) {
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
    if ($lc_cmd eq 'echo')    { return _cmd_echo($rest) }
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

    # Unknown: try as external (runs via Perl system)
    return _cmd_external($cmd, $rest);
}

# ----------------------------------------------------------------
# Variable / arithmetic expansion
# ----------------------------------------------------------------
sub _expand {
    my ($class, $str) = @_;
    return '' unless defined $str;

    # $(( arithmetic ))
    $str =~ s/\$\(\(\s*(.*?)\s*\)\)/_eval_arith($1)/ge;

    # $( command ) substitution
    $str =~ s/\$\(([^)]*)\)/_cmd_subst($class, $1)/ge;

    # ${VAR:-default} ${VAR:=default} ${VAR:+alt} ${VAR}
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
    $str =~ s/\$\{([A-Za-z_][A-Za-z0-9_]*)\}/
        do { my $v = BATsh::Env->get($1); defined $v ? $v : '' }
    /ge;

    # $? last status
    $str =~ s/\$\?/$LAST_STATUS/g;

    # $VAR
    $str =~ s/\$([A-Za-z_][A-Za-z0-9_]*)/
        do { my $v = BATsh::Env->get($1); defined $v ? $v : '' }
    /ge;

    return $str;
}

# ----------------------------------------------------------------
# Arithmetic evaluator
# ----------------------------------------------------------------
sub _eval_arith {
    my ($expr) = @_;
    # Replace VAR names with numeric values
    $expr =~ s/([A-Za-z_][A-Za-z0-9_]*)/_arith_var($1)/ge;
    # Safe eval: digits, operators, parens only
    if ($expr =~ /\A[\d\s\+\-\*\/\%\(\)]+\z/) {
        my $result = eval $expr;
        return defined $result ? int($result) : 0;
    }
    return 0;
}

sub _arith_var {
    my ($name) = @_;
    my $v = BATsh::Env->get($name);
    return (defined $v && $v =~ /\A-?\d+\z/) ? $v : 0;
}

# ----------------------------------------------------------------
# Command substitution $( cmd )
# ----------------------------------------------------------------
sub _cmd_subst {
    my ($class, $cmd_str) = @_;
    # Capture stdout via temporary file (5.005_03 compatible)
    my $tmpfile = File::Spec->catfile(
        File::Spec->tmpdir(), "batsh_cap_$$.tmp");
    local *OLD_STDOUT;
    open(OLD_STDOUT, '>&STDOUT') or return '';
    local *CAPFH;
    open(CAPFH, "> $tmpfile") or do { open(STDOUT, '>&OLD_STDOUT'); return '' };
    open(STDOUT, '>&CAPFH');
    eval {
        my @sub_lines = split /\n/, $cmd_str;
        _run_lines($class, \@sub_lines, {});
    };
    open(STDOUT, '>&OLD_STDOUT');
    close(CAPFH);
    close(OLD_STDOUT);
    my $output = '';
    if (open(READFH, "< $tmpfile")) {
        local $/;
        $output = <READFH>;
        close(READFH);
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
        BATsh::Env->unset($var) if $var ne '';
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
    # Strip surrounding quotes
    $rest =~ s/\A"(.*)"\z/$1/s;
    $rest =~ s/\A'(.*)'\z/$1/s;
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
    $_EXIT_CODE = $code;
    $LAST_STATUS = $code;
    return $code;
}

# ----------------------------------------------------------------
# read
# ----------------------------------------------------------------
sub _cmd_read {
    my ($rest) = @_;
    $rest =~ s/\A\s+//;
    $rest =~ s/\s+\z//;
    my $line = <STDIN>;
    $line = '' unless defined $line;
    chomp $line;
    my @vars = split /\s+/, $rest;
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
    # Shift positional params $1..$9
    for my $n (1 .. 8) {
        my $next = BATsh::Env->get('BATSH_ARG' . ($n + 1));
        BATsh::Env->set('BATSH_ARG' . $n, defined($next) ? $next : '');
    }
    BATsh::Env->set('BATSH_ARG9', '');
    $LAST_STATUS = 0;
    return 0;
}

# ----------------------------------------------------------------
# local
# ----------------------------------------------------------------
sub _cmd_local {
    my ($rest) = @_;
    $rest =~ s/\A\s+//;
    if ($rest =~ /\A([A-Za-z_][A-Za-z0-9_]*)=(.*)\z/s) {
        BATsh::Env->set($1, $2);
    }
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

    # for VAR in item1 item2 ...; do
    my ($var, $list_str) = ('', '');
    if ($for_line =~ /\Afor\s+([A-Za-z_][A-Za-z0-9_]*)\s+in\s+(.*?)\s*(?:;\s*do)?\s*\z/i) {
        ($var, $list_str) = ($1, $2);
    }

    # Collect body until 'done'
    my @body = ();
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

    # Expand list items
    my @items = split /\s+/, $list_str;
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

    # Extract condition
    my $cond_str = $while_line;
    $cond_str =~ s/\A(?:while|until)\s+//i;
    $cond_str =~ s/\s*;\s*do\s*\z//i;
    $cond_str =~ s/\s+do\s*\z//i;

    # Collect body
    my @body = ();
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

    # case WORD in
    my $word = '';
    if ($case_line =~ /\Acase\s+(.*?)\s+in\s*\z/i) {
        $word = _expand(undef, $1);
    }

    # Read patterns and bodies until esac
    my $status = 0;
    my $matched = 0;

    while ($i <= $#lines) {
        my $pl = $lines[$i]; $i++;
        $pl =~ s/\r?\n\z//; $pl =~ s/\A\s+//;
        next if $pl =~ /\A\s*\z/;
        my $lc_f = lc( ($pl =~ /\A(\S+)/) ? $1 : '' );
        last if $lc_f eq 'esac';
        next if $pl =~ /\A\s*;;\s*\z/;  # stray ;; between patterns

        # Case 1: pattern) body ;; -- all on one line
        if ($pl =~ /\A(.*?)\)\s*(.+?)\s*;;\s*\z/) {
            my ($pattern_str, $inline_body) = ($1, $2);
            if (!$matched) {
                for my $pat (split /\|/, $pattern_str) {
                    $pat =~ s/\A\s+//; $pat =~ s/\s+\z//;
                    if (_match_pattern($word, $pat)) {
                        $status = _run_lines($class, [$inline_body], $opts_ref);
                        $matched = 1;
                        last;
                    }
                }
            }
            next;
        }

        # Case 2: pattern) -- pattern only, body on next lines until ;;
        if ($pl =~ /\A(.*?)\)\s*\z/) {
            my $pattern_str = $1;
            my @body = ();
            while ($i <= $#lines) {
                my $bl = $lines[$i]; $i++;
                $bl =~ s/\r?\n\z//;
                last if $bl =~ /\A\s*;;\s*\z/;
                if ($bl =~ /\A(.+?)\s*;;\s*\z/) { push @body, $1; last }
                push @body, $bl;
            }
            if (!$matched) {
                for my $pat (split /\|/, $pattern_str) {
                    $pat =~ s/\A\s+//; $pat =~ s/\s+\z//;
                    if (_match_pattern($word, $pat)) {
                        $status = _run_lines($class, \@body, $opts_ref);
                        $matched = 1;
                        last;
                    }
                }
            }
        }
    }

    return ($status, $i);
}

# Shell glob pattern matching
sub _match_pattern {
    my ($word, $pat) = @_;
    return 1 if $pat eq '*';
    # Convert shell glob to regex
    my $re = quotemeta($pat);
    $re =~ s/\\\*/.*/g;
    $re =~ s/\\\?/./g;
    return ($word =~ /\A$re\z/) ? 1 : 0;
}

# ----------------------------------------------------------------
# External command
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
  BATsh::SH::exec_block('BATsh::SH', \@lines, _batsh => $batsh);

=head1 DESCRIPTION

BATsh::SH implements the POSIX sh / bash command set entirely in Perl.
No external sh or bash is required.

=head2 Supported Features

  VAR=value, export VAR=value, unset VAR
  echo, printf
  if/then/elif/else/fi
  for VAR in list; do ... done
  while condition; do ... done
  until condition; do ... done
  case $var in pattern) ... ;; esac
  test / [ ... ]  (file tests, string, integer comparisons)
  cd, pwd, exit, true, false, :, read, shift, local, set
  $(( arithmetic ))
  $( command substitution )
  ${VAR}, ${VAR:-default}, ${VAR:=default}
  source / . file

=head2 Variable Expansion

C<$VAR> and C<${VAR}> references are expanded before each line executes.
Arithmetic expressions C<$(( expr ))> support +, -, *, /, % and
parentheses.

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt>

=head1 LICENSE

Same as Perl itself.

=cut
