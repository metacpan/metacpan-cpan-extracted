######################################################################
#
# 0018-sh-set-options.t  SH shell options: set -e / -u / -x (v0.07)
#
# SO01-SO03  set -e stops on failure, propagates rc, set +e releases
# SO04-SO06  errexit exemptions: if condition, non-final && member;
#            true && false (final member) fires
# SO07       false ; echo under -e: echo is not reached
# SO08       set -o errexit (long form)
# SO09-SO10  set -u: unset variable warns and stops with rc=1;
#            ${V:-default} does not trigger -u
# SO11       set -x traces commands to STDERR with "+ " prefix
# SO12       reset_sh_options: set -e does not leak into the next run
# SO13-SO14  eval builtin: double expansion; eval respects set -e
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
use File::Spec ();
use lib "$FindBin::Bin/../lib";

eval { require BATsh } or die "Cannot load BATsh: $@";

# Run source through BATsh->run_string, capturing STDOUT and STDERR;
# return (rc, out, err).
sub _run_capture {
    my ($source) = @_;
    BATsh::Env::init();
    my $cap_out = "$FindBin::Bin/_so_out_$$.tmp";
    my $cap_err = "$FindBin::Bin/_so_err_$$.tmp";
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

my @tests = (

# SO01: set -e stops at the first failing command
sub {
    my ($rc, $out, $err) = _run_capture(
        "set -e\necho before\nfalse\necho after\n");
    ok_is((($out =~ /before/) && ($out !~ /after/)) ? 1 : 0, 1,
          'SO01 set -e stops execution after a failure');
},

# SO02: set -e propagates the failing status as the script rc
sub {
    my ($rc, $out, $err) = _run_capture("set -e\nfalse\necho after\n");
    ok_is($rc, 1, 'SO02 set -e propagates rc=1');
},

# SO03: set +e releases errexit
sub {
    my ($rc, $out, $err) = _run_capture(
        "set -e\nset +e\nfalse\necho after\n");
    ok_is(($out =~ /after/) ? 1 : 0, 1,
          'SO03 set +e releases errexit');
},

# SO04: a failing "if" condition is exempt from errexit
sub {
    my ($rc, $out, $err) = _run_capture(
        "set -e\nif false; then\necho then-part\nfi\necho reached\n");
    ok_is(($out =~ /reached/) ? 1 : 0, 1,
          'SO04 if-condition failure is exempt from set -e');
},

# SO05: a non-final member of && is exempt (false && echo)
sub {
    my ($rc, $out, $err) = _run_capture(
        "set -e\nfalse && echo skipped\necho reached\n");
    ok_is(($out =~ /reached/) ? 1 : 0, 1,
          'SO05 false && ... is exempt from set -e');
},

# SO06: the final member of && does fire errexit (true && false)
sub {
    my ($rc, $out, $err) = _run_capture(
        "set -e\ntrue && false\necho after\n");
    ok_is((($rc == 1) && ($out !~ /after/)) ? 1 : 0, 1,
          'SO06 true && false fires set -e (rc=1)');
},

# SO07: sequential list: false ; echo does fire under -e
sub {
    my ($rc, $out, $err) = _run_capture(
        "set -e\nfalse; echo after\n");
    ok_is(($out !~ /after/) ? 1 : 0, 1,
          'SO07 "false; echo" stops before echo under set -e');
},

# SO08: set -o errexit (long form) behaves like set -e
sub {
    my ($rc, $out, $err) = _run_capture(
        "set -o errexit\nfalse\necho after\n");
    ok_is((($rc == 1) && ($out !~ /after/)) ? 1 : 0, 1,
          'SO08 set -o errexit stops with rc=1');
},

# SO09: set -u: an unset variable warns on STDERR and stops with rc=1
sub {
    my ($rc, $out, $err) = _run_capture(
        "set -u\necho \$UNDEFINED_SO09\necho after\n");
    ok_is((($rc == 1) && ($err =~ /unbound variable/) && ($out !~ /after/))
              ? 1 : 0, 1,
          'SO09 set -u: unset variable warns and stops (rc=1)');
},

# SO10: set -u: ${V:-default} does not trigger nounset
sub {
    my ($rc, $out, $err) = _run_capture(
        "set -u\necho val=\${UNDEFINED_SO10:-fallback}\n");
    ok_is((($rc == 0) && ($out =~ /val=fallback/)) ? 1 : 0, 1,
          'SO10 set -u: ${V:-default} is not an error');
},

# SO11: set -x traces the raw command line to STDERR with "+ "
sub {
    my ($rc, $out, $err) = _run_capture(
        "set -x\necho traced-so11\n");
    ok_is(($err =~ /^\+ echo traced-so11/m) ? 1 : 0, 1,
          'SO11 set -x traces "+ echo ..." on STDERR');
},

# SO12: set -e does not leak into the next run (reset_sh_options)
sub {
    my ($rc1, $out1, $err1) = _run_capture("set -e\nfalse\necho one\n");
    my ($rc2, $out2, $err2) = _run_capture("false\necho two\n");
    ok_is((($out1 !~ /one/) && ($out2 =~ /two/)) ? 1 : 0, 1,
          'SO12 set -e is reset between runs');
},

# SO13: eval builtin performs a second round of expansion
sub {
    my ($rc, $out, $err) = _run_capture(
        "a=b\nb=deep\neval echo \\\$\$a\n");
    ok_is(($out =~ /deep/) ? 1 : 0, 1,
          'SO13 eval double-expands its arguments');
},

# SO14: a failing eval'ed command fires set -e
sub {
    my ($rc, $out, $err) = _run_capture(
        "set -e\neval false\necho after\n");
    ok_is((($rc == 1) && ($out !~ /after/)) ? 1 : 0, 1,
          'SO14 eval false fires set -e (rc=1)');
},

);

$main::fail = 0;
print "1.." . scalar(@tests) . "\n";
$_->() for @tests;

END { $? = 1 if $main::fail }

__END__
