######################################################################
#
# 0024-sh-redirect-quoting.t   SH redirection target quoting / safety
#
# Regression tests for two defects in the pure-Perl SH interpreter's
# redirection handling (present through v0.07):
#
#   (A) A quoted redirection target keeps its quote characters and is
#       split on internal whitespace, so
#           echo hi > "out.txt"
#       writes to a file literally named  "out.txt"  (quotes included)
#       instead of  out.txt , and
#           echo hi > "a b.txt"
#       breaks at the space.  (The CMD interpreter already dequotes its
#       redirection targets correctly; only SH was affected.)
#
#   (B) Redirection targets reach a 2-argument open() unprotected, so a
#       name that ends in "|" (or otherwise looks like a mode/pipe spec)
#       is interpreted by open() rather than treated as a filename --
#       a command-injection path:
#           f="date|"; cat < $f      # ran `date` as a pipe
#
# RQ01  double-quoted output target -> quotes stripped
# RQ02  single-quoted output target -> quotes stripped
# RQ03  quoted target containing a space -> one filename, space kept
# RQ04  double-quoted input target -> quotes stripped, file is read
# RQ05  append (>>) to a quoted target -> quotes stripped
# RQ06  injection: input redirect from a "cmd|" name must NOT run a pipe
# RQ07  injection: output redirect to a ">real" name must NOT be re-parsed
# RQ08  subshell "( ... ) > TARGET" honours a quoted target with a space
# RQ09  injection: subshell redirect to a "name|" target is a filename
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

# Run SH source through BATsh->run_string, capturing STDOUT+STDERR.
sub _run_capture {
    my ($source) = @_;
    BATsh::Env::init();
    my $cap_out = "$FindBin::Bin/_rq_out_$$.tmp";
    my $cap_err = "$FindBin::Bin/_rq_err_$$.tmp";
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
    $out =~ s/\r\n/\n/g; $out =~ s/\r//g;   # portability: ignore CR (Win)
    $err =~ s/\r\n/\n/g; $err =~ s/\r//g;
    warn $err_eval if $err_eval;
    return ($rc, $out, $err);
}

# Read a whole file.  Uses the protected 2-arg read form ("< NAME\0")
# so it can read a name that itself begins with ">" or ends in "|" and
# never (mis)interprets the target as a mode/pipe spec.
sub _slurp {
    my ($path) = @_;
    local *FH;
    open(FH, "< $path\0") or return undef;
    local $/;
    my $data = <FH>;
    close(FH);
    return undef unless defined $data;
    $data =~ s/\r\n/\n/g; $data =~ s/\r//g;   # portability: ignore CR (Win)
    return $data;
}

my $DIR = $FindBin::Bin;

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

# RQ01: a double-quoted output target must be written without the quotes.
sub {
    my $p = "$DIR/_rq_dq_$$.txt";
    unlink $p, "\"$p\"";
    _run_capture("echo hi > \"$p\"\n");
    my $got = _slurp($p);
    unlink $p, "\"$p\"";
    ok_is($got, "hi\n", 'RQ01 double-quoted output target -> quotes stripped');
},

# RQ02: a single-quoted output target must be written without the quotes.
sub {
    my $p = "$DIR/_rq_sq_$$.txt";
    unlink $p, "'$p'";
    _run_capture("echo hi > '$p'\n");
    my $got = _slurp($p);
    unlink $p, "'$p'";
    ok_is($got, "hi\n", 'RQ02 single-quoted output target -> quotes stripped');
},

# RQ03: a quoted target containing a space is ONE filename (space kept).
sub {
    my $p = "$DIR/_rq sp_$$.txt";
    unlink $p;
    _run_capture("echo hi > \"$p\"\n");
    my $got = _slurp($p);
    unlink $p;
    ok_is($got, "hi\n", 'RQ03 quoted target with space -> single filename');
},

# RQ04: a double-quoted input target is read (quotes stripped).  Written
# and read entirely with BATsh builtins (echo out, read in) so the check
# mirrors the passing output tests and depends on no external command.
sub {
    my $p = "$DIR/_rq_in_$$.txt";
    unlink $p, "\"$p\"";
    my (undef, $out) =
        _run_capture("echo payload > \"$p\"\nread LINE < \"$p\"\necho \"[\$LINE]\"\n");
    unlink $p, "\"$p\"";
    ok_is($out, "[payload]\n", 'RQ04 double-quoted input target -> file is read');
},

# RQ05: append (>>) to a quoted target appends without the quotes.
sub {
    my $p = "$DIR/_rq_ap_$$.txt";
    unlink $p, "\"$p\"";
    _run_capture("echo a > \"$p\"\necho b >> \"$p\"\n");
    my $got = _slurp($p);
    unlink $p, "\"$p\"";
    ok_is($got, "a\nb\n", 'RQ05 append to quoted target -> quotes stripped');
},

# RQ06: SECURITY -- input redirect from a name ending in "|" must be
# treated as a (missing) filename, never run as a pipe command.  Uses the
# `read` builtin (no external cat): if the pre-fix bug ran "date|" as a
# pipe, LINE would hold date's output; with the fix the open fails and
# LINE stays empty.
sub {
    my (undef, $out) = _run_capture("f=\"date|\"\nread LINE < \$f\necho \"[\$LINE]\"\n");
    ok_is($out, "[]\n", 'RQ06 input redirect "cmd|" is a filename, not a pipe');
},

# RQ07: SECURITY -- an output target whose basename begins with ">" must
# not be re-parsed by open().  The pre-fix bug turned '>' . ">name" into
# ">>name", silently APPENDING to a *different* file "name" (leading ">"
# stripped).  We verify that stray file "name" is never created.  Run in
# a private temp dir so the ">"-prefixed name is a plain basename.
sub {
    my $sub = "$DIR/_rq7_$$";
    mkdir $sub, 0777;
    my $stray  = "$sub/gtname.txt";     # the wrong file the bug would make
    my $target = ">gtname.txt";         # basename beginning with '>'
    _run_capture("cd $sub\necho hi > \"$target\"\n");
    my $leaked = (-e $stray) ? 1 : 0;
    # Clean up whatever was produced.
    unlink $stray, "$sub/>gtname.txt";
    local *D;
    if (opendir(D, $sub)) {
        my @rest = grep { $_ ne '.' && $_ ne '..' } readdir(D);
        closedir(D);
        unlink "$sub/$_" for @rest;
    }
    rmdir $sub;
    ok_is($leaked, 0, 'RQ07 target basename ">name" not re-parsed to "name"');
},

# RQ08: a subshell "( ... ) > TARGET" honours a quoted target that
# contains a space (parsed through the same quote-aware code path).
sub {
    my $p = "$DIR/_rq8 sp_$$.txt";
    unlink $p;
    _run_capture("( echo one; echo two ) > \"$p\"\n");
    my $got = _slurp($p);
    unlink $p;
    ok_is($got, "one\ntwo\n", 'RQ08 subshell redirect target with space');
},

# RQ09: a subshell "( ... ) >> TARGET" appends to a quoted target with
# the quotes stripped (exercises the append flag through the same
# quote-aware path).  Portable: no special characters in the name.
sub {
    my $p = "$DIR/_rq9_$$.txt";
    unlink $p, "\"$p\"";
    _run_capture("( echo a ) > \"$p\"\n( echo b ) >> \"$p\"\n");
    my $got = _slurp($p);
    unlink $p, "\"$p\"";
    ok_is($got, "a\nb\n", 'RQ09 subshell append to quoted target');
},

);

$main::fail = 0;
print "1.." . scalar(@tests) . "\n";
$_->() for @tests;

END { $? = 1 if $main::fail }

__END__
