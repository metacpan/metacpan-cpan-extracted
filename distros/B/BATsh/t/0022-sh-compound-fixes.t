######################################################################
#
# 0022-sh-compound-fixes.t  compound-command / control-structure fixes
#
# Regression tests for practical-level fixes to the pure-Perl SH and CMD
# interpreters (v0.07).
#
# CF01       prefix command + control structure on one physical line
#            (x=""; if ...; then ...; fi)
# CF02       inline "if COND; then A; else B; fi" honours the else branch
# CF03       escaped double quotes inside a double-quoted word
# CF04       nested "if ... fi" (inner fi does not close the outer if)
# CF05       for-loop list built from $(...) command substitution
# CF06-CF10  SH trailing "# comment" stripping: removed after a command,
#            but kept inside quotes, kept in-word (a#b), not confused with
#            ${#var} parameter length, and whole-line comments ignored
# CF11-CF14  a control structure as a pipeline element / && operand:
#            cmd | while read ...; done, true && for ...; done,
#            cmd | for ...; done, and ';'-list precedence with a pipe
# CF15-CF16  single-line CMD "IF cond (body) ELSE (body)" both branches
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

# Run source through BATsh->run_string, capturing STDOUT and STDERR and
# optionally feeding STDIN from $stdin_text.  Returns (rc, out, err).
sub _run_capture {
    my ($source, $stdin_text) = @_;
    BATsh::Env::init();
    my $cap_out = "$FindBin::Bin/_cf_out_$$.tmp";
    my $cap_err = "$FindBin::Bin/_cf_err_$$.tmp";
    my $cap_in  = "$FindBin::Bin/_cf_in_$$.tmp";
    local *OLDOUT;
    local *OLDERR;
    local *OLDIN;
    my $saved_in = 0;
    if (defined $stdin_text) {
        local *WF;
        open(WF, "> $cap_in") or die "cannot write $cap_in: $!";
        print WF $stdin_text;
        close(WF);
        open(OLDIN, "<&STDIN") or die "cannot dup STDIN: $!";
        close(STDIN);
        open(STDIN, "< $cap_in")
            or do { open(STDIN, "<&OLDIN"); die "cannot redirect STDIN: $!" };
        $saved_in = 1;
    }
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
    if ($saved_in) {
        close(STDIN);
        open(STDIN, "<&OLDIN") or die "cannot restore STDIN: $!";
        close(OLDIN);
    }
    my $out = '';
    my $err = '';
    local *RF;
    if (open(RF, $cap_out)) { local $/; $out = <RF>; close(RF) }
    unlink($cap_out);
    if (open(RF, $cap_err)) { local $/; $err = <RF>; close(RF) }
    unlink($cap_err);
    unlink($cap_in) if $saved_in;
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

my @tests = (

# CF01: a simple-command prefix followed on the same physical line by a
# control structure introduced with ';'
sub {
    my (undef, $out) = _run_capture(
        "x=\"\"; if [ -z \"\$x\" ]; then echo empty; fi\n");
    ok_is($out, "empty\n", 'CF01 prefix command + inline if on one line');
},

# CF02: inline if/then/else/fi keeps the else branch
sub {
    my (undef, $out) = _run_capture("if false; then echo A; else echo B; fi\n");
    ok_is($out, "B\n", 'CF02 inline if ... else ... fi runs the else branch');
},

# CF03: escaped double quotes inside a double-quoted word
sub {
    my (undef, $out) = _run_capture("echo \"she said \\\"hi\\\"\"\n");
    ok_is($out, "she said \"hi\"\n", 'CF03 escaped quotes inside double quotes');
},

# CF04: nested if ... fi -- the inner fi must not close the outer if
sub {
    my (undef, $out) = _run_capture(
        "if true\nthen\n  if true; then echo inner; fi\nfi\n");
    ok_is($out, "inner\n", 'CF04 nested if/fi (inner fi is depth-aware)');
},

# CF05: for-loop list produced by $(...) command substitution
sub {
    my (undef, $out) = _run_capture("for f in \$(echo a b c); do echo \$f; done\n");
    ok_is($out, "a\nb\nc\n", 'CF05 for list from command substitution');
},

# CF06: a trailing "# comment" is stripped from a SH command line
sub {
    my (undef, $out) = _run_capture("echo hi   # trailing comment\n");
    ok_is($out, "hi\n", 'CF06 trailing # comment stripped');
},

# CF07: a '#' inside quotes is literal, not a comment
sub {
    my (undef, $out) = _run_capture("echo \"a # b\"\n");
    ok_is($out, "a # b\n", 'CF07 # inside quotes is literal');
},

# CF08: a '#' that is not at a word start stays part of the word
sub {
    my (undef, $out) = _run_capture("echo a#b\n");
    ok_is($out, "a#b\n", 'CF08 in-word # is not a comment');
},

# CF09: ${#var} parameter-length is not mistaken for a comment
sub {
    my (undef, $out) = _run_capture("s=hello; echo \${#s}\n");
    ok_is($out, "5\n", 'CF09 ${#var} length unaffected by comment stripping');
},

# CF10: a whole-line comment produces no output
sub {
    my (undef, $out) = _run_capture("# just a comment\necho after\n");
    ok_is($out, "after\n", 'CF10 whole-line # comment ignored');
},

# CF11: a while-read loop as the target of a pipe
sub {
    my (undef, $out) = _run_capture(
        "printf \"a\\nb\\nc\\n\" | while read L; do echo \"got \$L\"; done\n");
    ok_is($out, "got a\ngot b\ngot c\n", 'CF11 cmd | while read ...; done');
},

# CF12: a for loop as the right operand of &&
sub {
    my (undef, $out) = _run_capture(
        "true && for i in 1 2; do echo \"n=\$i\"; done\n");
    ok_is($out, "n=1\nn=2\n", 'CF12 true && for ...; done');
},

# CF13: a for loop as the target of a pipe
sub {
    my (undef, $out) = _run_capture(
        "echo x | for i in \$(echo a b); do echo \$i; done\n");
    ok_is($out, "a\nb\n", 'CF13 cmd | for ...; done');
},

# CF14: ';' list precedence -- "echo first" runs, then the pipeline
sub {
    my (undef, $out) = _run_capture(
        "echo first; printf \"p\\nq\\n\" | while read x; do echo \"got:\$x\"; done\n");
    ok_is($out, "first\ngot:p\ngot:q\n",
          'CF14 a; b | while ...  keeps ; at top level, pipe grouped');
},

# CF15: single-line CMD IF/ELSE -- the then-branch
sub {
    my (undef, $out) = _run_capture("IF 1==1 (ECHO yes) ELSE (ECHO no)\n");
    ok_is($out, "yes\n", 'CF15 CMD single-line IF (...) ELSE (...) then-branch');
},

# CF16: single-line CMD IF/ELSE -- the else-branch
sub {
    my (undef, $out) = _run_capture("IF 2==1 (ECHO a) ELSE (ECHO b)\n");
    ok_is($out, "b\n", 'CF16 CMD single-line IF (...) ELSE (...) else-branch');
},

);

$main::fail = 0;
print "1.." . scalar(@tests) . "\n";
$_->() for @tests;

END { $? = 1 if $main::fail }

__END__
