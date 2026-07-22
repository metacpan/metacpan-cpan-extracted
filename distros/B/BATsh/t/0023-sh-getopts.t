######################################################################
#
# 0023-sh-getopts.t   SH getopts builtin (and the shift N fix)
#
# Regression tests for the POSIX getopts option parser added in v0.07,
# and for the accompanying fix to the SH "shift N" builtin (which had
# been ignoring its count argument and always shifting by one).
#
# GO01       single flag option (-a)
# GO02       option with a separate argument (-o value)
# GO03       option with an attached argument (-ovalue)
# GO04       clustered flags (-ac)
# GO05       clustered flags followed by an attached-argument option
# GO06       OPTIND advances to the first non-option word
# GO07       "--" terminates option parsing and is consumed
# GO08       a non-option word terminates option parsing (not consumed)
# GO09       unknown option, non-silent: name '?', diagnostic on STDERR
# GO10       unknown option, silent (leading ':'): name '?', OPTARG=letter,
#            no STDERR diagnostic
# GO11       missing argument, non-silent: name '?', diagnostic on STDERR
# GO12       missing argument, silent: name ':', OPTARG=letter
# GO13       OPTARG is cleared for a flag (no-argument) option
# GO14       OPTIND=1 reset restarts a fresh loop (function reuse)
# GO15       positional parameters are parsed when no explicit args given
# GO16       shift $((OPTIND - 1)) leaves the correct remaining arguments
# GO17       shift N honours its count (regression: was always 1)
# GO18       too few operands: usage error to STDERR, non-zero status
# GO19       $* expands to the positional parameters (was left literal)
# GO20       echo "...$*" preserves whitespace (raw '*' not globbed)
# GO21       echo "*" is literal (quoted glob metacharacter not expanded)
#
# COMPATIBILITY: Perl 5.005_03 and later
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";

eval { require BATsh } or die "Cannot load BATsh: $@";

# Run source through BATsh->run_string, capturing STDOUT and STDERR.
# Returns (rc, out, err).
sub _run_capture {
    my ($source) = @_;
    BATsh::Env::init();
    my $cap_out = "$FindBin::Bin/_go_out_$$.tmp";
    my $cap_err = "$FindBin::Bin/_go_err_$$.tmp";
    local *OLDOUT;
    local *OLDERR;
    open(OLDOUT, ">&STDOUT") or die "cannot dup STDOUT: $!";
    open(OLDERR, ">&STDERR") or die "cannot dup STDERR: $!";
    close(STDOUT);
    open(STDOUT, "> $cap_out")
        or do { open(STDOUT, ">&OLDOUT"); die "cannot redirect STDOUT: $!" };
    close(STDERR);
    open(STDERR, "> $cap_err")
        or do { open(STDERR, ">&OLDERR");
                open(STDOUT, ">&OLDOUT");
                die "cannot redirect STDERR: $!" };
    my $rc = eval { BATsh->run_string($source) };
    my $err_eval = $@;
    close(STDOUT);
    close(STDERR);
    open(STDOUT, ">&OLDOUT") or die "cannot restore STDOUT: $!";
    open(STDERR, ">&OLDERR") or die "cannot restore STDERR: $!";
    close(OLDOUT);
    close(OLDERR);
    my $out = '';
    my $err = '';
    local *RF;
    if (open(RF, $cap_out)) { local $/; $out = <RF>; close(RF) }
    unlink($cap_out);
    if (open(RF, $cap_err)) { local $/; $err = <RF>; close(RF) }
    unlink($cap_err);
    $out = '' unless defined $out;
    $err = '' unless defined $err;
    warn $err_eval if $err_eval;
    return ($rc, $out, $err);
}

my $test = 0;
sub ok_is {
    my ($got, $expected, $name) = @_;
    $test++;
    $got      = '(undef)' unless defined $got;
    $expected = '(undef)' unless defined $expected;
    if ($got eq $expected) { print "ok $test - $name\n"; return 1 }
    print "not ok $test - $name (got [$got] expected [$expected])\n";
    $main::fail++;
    return 0;
}

sub ok_like {
    my ($got, $re, $name) = @_;
    $test++;
    $got = '' unless defined $got;
    if ($got =~ $re) { print "ok $test - $name\n"; return 1 }
    print "not ok $test - $name (got [$got] did not match $re)\n";
    $main::fail++;
    return 0;
}

my @tests = (

# GO01: a single flag option
sub {
    my (undef, $out) = _run_capture(
        "while getopts \"ab\" o -a; do echo \"\$o\"; done\n");
    ok_is($out, "a\n", 'GO01 single flag option');
},

# GO02: option with a separate argument (-o value)
sub {
    my (undef, $out) = _run_capture(
        "while getopts \"b:\" o -b val; do echo \"\$o=\$OPTARG\"; done\n");
    ok_is($out, "b=val\n", 'GO02 option with separate argument');
},

# GO03: option with an attached argument (-ovalue)
sub {
    my (undef, $out) = _run_capture(
        "while getopts \"b:\" o -bval; do echo \"\$o=\$OPTARG\"; done\n");
    ok_is($out, "b=val\n", 'GO03 option with attached argument');
},

# GO04: clustered flags -ac
sub {
    my (undef, $out) = _run_capture(
        "while getopts \"ac\" o -ac; do echo \"\$o\"; done\n");
    ok_is($out, "a\nc\n", 'GO04 clustered flag options');
},

# GO05: clustered flags then an attached-argument option
sub {
    my (undef, $out) = _run_capture(
        "while getopts \"acb:\" o -ac -bVAL; do echo \"\$o=\$OPTARG\"; done\n");
    ok_is($out, "a=\nc=\nb=VAL\n", 'GO05 cluster + attached-arg option');
},

# GO06: OPTIND advances to the first non-option word
sub {
    my (undef, $out) = _run_capture(
        "while getopts \"ab:\" o -a -b x file; do :; done\n"
      . "echo \"\$OPTIND\"\n");
    ok_is($out, "4\n", 'GO06 OPTIND points at first operand');
},

# GO07: "--" terminates parsing and is consumed (OPTIND past it)
sub {
    my (undef, $out) = _run_capture(
        "while getopts \"a\" o -a -- -a; do echo \"\$o\"; done\n"
      . "echo \"OPTIND=\$OPTIND\"\n");
    ok_is($out, "a\nOPTIND=3\n", 'GO07 -- ends options and is consumed');
},

# GO08: a non-option word terminates parsing (not consumed)
sub {
    my (undef, $out) = _run_capture(
        "while getopts \"a\" o -a plain -a; do echo \"\$o\"; done\n"
      . "echo \"OPTIND=\$OPTIND\"\n");
    ok_is($out, "a\nOPTIND=2\n", 'GO08 operand stops parsing, not consumed');
},

# GO09: unknown option, non-silent -- name '?' and a STDERR diagnostic
sub {
    my (undef, $out) = _run_capture(
        "while getopts \"a\" o -x; do echo \"[\$o]\"; done\n");
    ok_is($out, "[?]\n", 'GO09a unknown option sets name to ?');
},
sub {
    my (undef, undef, $err) = _run_capture(
        "while getopts \"a\" o -x; do echo \"[\$o]\"; done\n");
    ok_like($err, qr/illegal option/, 'GO09b unknown option warns on STDERR');
},

# GO10: unknown option, silent mode (leading ':') -- '?', OPTARG=letter,
# no STDERR
sub {
    my (undef, $out) = _run_capture(
        "while getopts \":a\" o -x; do echo \"\$o:\$OPTARG\"; done\n");
    ok_is($out, "?:x\n", 'GO10a silent unknown: name ? OPTARG letter');
},
sub {
    my (undef, undef, $err) = _run_capture(
        "while getopts \":a\" o -x; do echo \"\$o:\$OPTARG\"; done\n");
    ok_is($err, '', 'GO10b silent unknown: no STDERR diagnostic');
},

# GO11: missing argument, non-silent -- name '?' and a STDERR diagnostic
sub {
    my (undef, $out) = _run_capture(
        "while getopts \"b:\" o -b; do echo \"[\$o]\"; done\n");
    ok_is($out, "[?]\n", 'GO11a missing arg (non-silent) sets name ?');
},
sub {
    my (undef, undef, $err) = _run_capture(
        "while getopts \"b:\" o -b; do echo \"[\$o]\"; done\n");
    ok_like($err, qr/requires an argument/, 'GO11b missing arg warns on STDERR');
},

# GO12: missing argument, silent mode -- name ':', OPTARG=letter
sub {
    my (undef, $out) = _run_capture(
        "while getopts \":b:\" o -b; do echo \"\$o:\$OPTARG\"; done\n");
    ok_is($out, "::b\n", 'GO12a silent missing arg: name : OPTARG letter');
},
sub {
    my (undef, undef, $err) = _run_capture(
        "while getopts \":b:\" o -b; do echo \"\$o:\$OPTARG\"; done\n");
    ok_is($err, '', 'GO12b silent missing arg: no STDERR diagnostic');
},

# GO13: OPTARG is cleared for a flag option that takes no argument
sub {
    my (undef, $out) = _run_capture(
        "while getopts \"b:a\" o -b val -a; do echo \"\$o[\$OPTARG]\"; done\n");
    ok_is($out, "b[val]\na[]\n", 'GO13 OPTARG cleared for flag option');
},

# GO14: OPTIND=1 reset restarts a fresh loop (function reuse)
sub {
    my (undef, $out) = _run_capture(
        "parse() { OPTIND=1; while getopts \"a:\" o; do echo \"\$o=\$OPTARG\"; done; }\n"
      . "parse -a one\n"
      . "parse -a two\n");
    ok_is($out, "a=one\na=two\n", 'GO14 OPTIND=1 restarts getopts loop');
},

# GO15: positional parameters are parsed when no explicit args are given
# (a function installs $1.. from its call arguments)
sub {
    my (undef, $out) = _run_capture(
        "parse() { while getopts \"a:c\" o; do echo \"\$o=\$OPTARG\"; done; }\n"
      . "parse -a hi -c\n");
    ok_is($out, "a=hi\nc=\n", 'GO15 parses positional parameters by default');
},

# GO16: shift \$((OPTIND - 1)) leaves the correct remaining arguments
# (integration test that also exercises the shift-N fix)
sub {
    my (undef, $out) = _run_capture(
        "work() {\n"
      . "  while getopts \"ab:\" o; do :; done\n"
      . "  shift \$((OPTIND - 1))\n"
      . "  echo \"rest: \$1 \$2\"\n"
      . "}\n"
      . "work -a -b val one two\n");
    ok_is($out, "rest: one two\n", 'GO16 shift $((OPTIND-1)) drops options');
},

# GO17: shift N honours its count (regression -- previously always 1)
sub {
    my (undef, $out) = _run_capture(
        "f() { shift 3; echo \"\$1 \$2\"; }\n"
      . "f a b c d e\n");
    ok_is($out, "d e\n", 'GO17 shift N shifts by N, not 1');
},

# GO18: too few operands -- usage error to STDERR, non-zero status
sub {
    my (undef, $out) = _run_capture(
        "getopts \"a\"\n"
      . "echo \"done\"\n");
    ok_is($out, "done\n", 'GO18a getopts continues after usage error');
},
sub {
    my (undef, undef, $err) = _run_capture(
        "getopts \"a\"\n"
      . "echo \"done\"\n");
    ok_like($err, qr/usage: getopts/, 'GO18b usage error printed to STDERR');
},

# GO19: $* expands to the space-joined positional parameters (previously
# it was left literal; only $@ was substituted).  This is the parameter
# a getopts loop leaves in place after "shift $((OPTIND - 1))".
sub {
    my (undef, $out) = _run_capture(
        "f() { echo \"[\$*]\"; }\n"
      . "f a b c\n");
    ok_is($out, "[a b c]\n", 'GO19 \$* expands to positional parameters');
},

# GO20: a double-quoted "$*" in an echo argument preserves the argument's
# leading and internal whitespace -- the raw '*' of \$* must not be
# mistaken for a filename glob and trigger a re-split.
sub {
    my (undef, $out) = _run_capture(
        "f() { echo \"  operands: \$*\"; }\n"
      . "f x y\n");
    ok_is($out, "  operands: x y\n", 'GO20 echo "...$*" keeps whitespace');
},

# GO21: a quoted glob metacharacter in echo is literal (echo "*" prints
# a star), confirming the raw-text glob decision is quote-aware.
sub {
    my (undef, $out) = _run_capture("echo \"*\"\n");
    ok_is($out, "*\n", 'GO21 echo "*" is literal (quoted, not globbed)');
},

);

$main::fail = 0;
print "1.." . scalar(@tests) . "\n";
$_->() for @tests;

END { $? = 1 if $main::fail }

__END__
