######################################################################
#
# 0027-let-type-command.t   SH let / type / command builtins (v0.08)
#
# Regression tests for three POSIX/bash builtins that, prior to v0.08,
# were handed to an external shell (and failed where none existed).
# They are now evaluated internally in pure Perl.
#
# LT01       let: simple assignment expression
# LT02       let: quoted expression with spaces and '*'
# LT03       let: grouped sub-expression
# LT04       let: postfix ++ writes back to the variable
# LT05       let: exit status 1 when the last expression is zero
# LT06       let: exit status 0 when the last expression is non-zero
# LT07       let: status comes from the LAST of several expressions
# LT08       let: no argument is an error (status 1)
# TY01       type: a builtin
# TY02       type -t: a shell keyword
# TY03       type -t: a defined function
# TY04       type -t: an external file on PATH
# TY05       type -p: prints the path of an external file
# TY06       type -t: an alias
# TY07       type: unknown name -> status 1, nothing on STDOUT
# CM01       command -v: a builtin prints its name
# CM02       command -v: an external file prints its path
# CM03       command -v: unknown name -> status 1
# CM04       command -V: verbose description (like type)
# CM05       command NAME: runs the builtin, bypassing a shell function
# CM06       command -v: a shell keyword prints its name
# CM07       command -v: an alias prints an "alias NAME='...'" line
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
    my $cap_out = "$FindBin::Bin/_lt_out_$$.tmp";
    my $cap_err = "$FindBin::Bin/_lt_err_$$.tmp";
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

# ---- let ----------------------------------------------------------

# LT01: a plain arithmetic assignment
sub {
    my (undef, $out) = _run_capture("let x=5+3\necho \$x\n");
    ok_is($out, "8\n", 'LT01 let simple assignment');
},

# LT02: quoted expression with spaces and a multiplication '*' (which
# must NOT be treated as a filename glob)
sub {
    my (undef, $out) = _run_capture("let \"y = 2 * 6\"\necho \$y\n");
    ok_is($out, "12\n", 'LT02 let quoted expression');
},

# LT03: parenthesised sub-expression honours precedence
sub {
    my (undef, $out) = _run_capture("let \"z = (3 + 4) * 2\"\necho \$z\n");
    ok_is($out, "14\n", 'LT03 let grouped sub-expression');
},

# LT04: postfix ++ writes the incremented value back to the variable
sub {
    my (undef, $out) = _run_capture("n=4\nlet n++\necho \$n\n");
    ok_is($out, "5\n", 'LT04 let postfix increment writes back');
},

# LT05: exit status is 1 when the last expression evaluates to zero
sub {
    my (undef, $out) = _run_capture("let q=0\necho rc=\$?\n");
    ok_is($out, "rc=1\n", 'LT05 let zero result -> status 1');
},

# LT06: exit status is 0 when the last expression is non-zero
sub {
    my (undef, $out) = _run_capture("let q=7\necho rc=\$?\n");
    ok_is($out, "rc=0\n", 'LT06 let non-zero result -> status 0');
},

# LT07: with several expressions the status reflects only the last
sub {
    my (undef, $out) = _run_capture("let a=1 b=0\necho \$a \$b rc=\$?\n");
    ok_is($out, "1 0 rc=1\n", 'LT07 let status from last expression');
},

# LT08: no argument is a usage error with non-zero status
sub {
    my (undef, $out) = _run_capture("let\necho rc=\$?\n");
    ok_is($out, "rc=1\n", 'LT08 let with no argument -> status 1');
},

# ---- type ---------------------------------------------------------

# TY01: a builtin is described as such
sub {
    my (undef, $out) = _run_capture("type echo\n");
    ok_is($out, "echo is a shell builtin\n", 'TY01 type builtin');
},

# TY02: a control keyword
sub {
    my (undef, $out) = _run_capture("type -t for\n");
    ok_is($out, "keyword\n", 'TY02 type -t keyword');
},

# TY03: a defined shell function
sub {
    my (undef, $out) =
        _run_capture("myfn() { echo hi; }\ntype -t myfn\n");
    ok_is($out, "function\n", 'TY03 type -t function');
},

# TY04: an external program found on PATH
sub {
    my (undef, $out) = _run_capture("type -t perl\n");
    ok_is($out, "file\n", 'TY04 type -t external file');
},

# TY05: -p prints the path of an external program
sub {
    my (undef, $out) = _run_capture("type -p perl\n");
    ok_like($out, qr/perl/, 'TY05 type -p prints a path');
},

# TY06: an alias
sub {
    my (undef, $out) =
        _run_capture("alias ll='ls -l'\ntype -t ll\n");
    ok_is($out, "alias\n", 'TY06 type -t alias');
},

# TY07: an unknown name sets a non-zero status and prints nothing
#       to STDOUT (the diagnostic goes to STDERR).
sub {
    my (undef, $out) =
        _run_capture("type nosuch_xyz_123\necho rc=\$?\n");
    ok_is($out, "rc=1\n", 'TY07 type unknown -> status 1, no stdout');
},

# ---- command ------------------------------------------------------

# CM01: -v of a builtin prints the name
sub {
    my (undef, $out) = _run_capture("command -v echo\n");
    ok_is($out, "echo\n", 'CM01 command -v builtin prints name');
},

# CM02: -v of an external program prints its path
sub {
    my (undef, $out) = _run_capture("command -v perl\n");
    ok_like($out, qr/perl/, 'CM02 command -v external prints path');
},

# CM03: -v of an unknown name -> non-zero status
sub {
    my (undef, $out) =
        _run_capture("command -v nope_xyz_123\necho rc=\$?\n");
    ok_is($out, "rc=1\n", 'CM03 command -v unknown -> status 1');
},

# CM04: -V gives the verbose (type-style) description
sub {
    my (undef, $out) = _run_capture("command -V echo\n");
    ok_is($out, "echo is a shell builtin\n", 'CM04 command -V verbose');
},

# CM05: "command NAME" runs the builtin even when a shell function of
#       the same name is defined (function is bypassed).
sub {
    my (undef, $out) =
        _run_capture("echo() { printf FN; }\ncommand echo hi\n");
    ok_is($out, "hi\n", 'CM05 command bypasses a shell function');
},

# CM06: -v of a shell keyword prints the name
sub {
    my (undef, $out) = _run_capture("command -v while\n");
    ok_is($out, "while\n", 'CM06 command -v keyword prints name');
},

# CM07: -v of an alias prints an "alias NAME='value'" line
sub {
    my (undef, $out) =
        _run_capture("alias gg='grep -n'\ncommand -v gg\n");
    ok_is($out, "alias gg='grep -n'\n", 'CM07 command -v alias line');
},

);

$main::fail = 0;
print "1.." . scalar(@tests) . "\n";
$_->() for @tests;

END { $? = 1 if $main::fail }

__END__
