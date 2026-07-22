######################################################################
#
# 0026-sh-cd-and-redir-fail.t   cd dequoting; subshell redirect failure
#
# Two fixes:
#
#   (A) The `cd` builtin dequotes its argument, so a quoted directory
#       (cd "a b", cd 'dir', cd "$VAR/x") reaches chdir() as a plain
#       path.  Previously the quotes were kept and chdir failed.
#
#   (B) A subshell whose redirection cannot be opened, e.g.
#           ( read L ) < /no/such/file
#       reports the error and returns non-zero WITHOUT running its body.
#       Previously it fell through and ran the body with the inherited
#       stdin, which blocks forever when the body reads stdin.  We detect
#       the fix deterministically: the body must NOT run (no side effect)
#       and the status must be non-zero -- so it cannot reach a blocking
#       read in the first place.
#
# CD01  cd to a double-quoted path
# CD02  cd to a single-quoted path
# CD03  cd to a quoted path containing a space
# RF01  subshell with a failed input redirect does not run its body
# RF02  subshell with a working input redirect still reads the file
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

sub _run_out {
    my ($source) = @_;
    BATsh::Env::init();
    my $cap = "$FindBin::Bin/_cf_out_$$.tmp";
    local *OLDOUT;
    open(OLDOUT, ">&STDOUT") or die "cannot dup STDOUT: $!";
    close(STDOUT);
    open(STDOUT, "> $cap")
        or do { open(STDOUT, ">&OLDOUT"); die "cannot redirect STDOUT: $!" };
    eval { BATsh->run_string($source) };
    my $err = $@;
    close(STDOUT);
    open(STDOUT, ">&OLDOUT") or die "cannot restore STDOUT: $!";
    close(OLDOUT);
    my $out = '';
    local *RF;
    if (open(RF, $cap)) { local $/; $out = <RF>; close(RF) }
    unlink($cap);
    $out = '' unless defined $out;
    $out =~ s/\r\n/\n/g; $out =~ s/\r//g;   # portability: ignore CR (Win)
    warn $err if $err;
    return $out;
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

# CD01: a double-quoted directory path is entered (quotes stripped).
sub {
    my $d = "$DIR/_cd01_$$";
    mkdir $d, 0777;
    my $out = _run_out("cd \"$d\"\npwd\n");
    chdir($DIR);   # restore process cwd before removing the temp dir
    rmdir $d;
    ok_is((index($out, "_cd01_$$") >= 0) ? 1 : 0, 1,
          'CD01 cd to a double-quoted path');
},

# CD02: a single-quoted directory path is entered.
sub {
    my $d = "$DIR/_cd02_$$";
    mkdir $d, 0777;
    my $out = _run_out("cd '$d'\npwd\n");
    chdir($DIR);   # restore process cwd before removing the temp dir
    rmdir $d;
    ok_is((index($out, "_cd02_$$") >= 0) ? 1 : 0, 1,
          'CD02 cd to a single-quoted path');
},

# CD03: a quoted path containing a space is one argument.
sub {
    my $d = "$DIR/_cd 03_$$";
    mkdir $d, 0777;
    my $out = _run_out("cd \"$d\"\npwd\n");
    chdir($DIR);   # restore process cwd before removing the temp dir
    rmdir $d;
    ok_is((index($out, "_cd 03_$$") >= 0) ? 1 : 0, 1,
          'CD03 cd to a quoted path with a space');
},

# RF01: a subshell whose input redirect fails must NOT run its body.  The
# body would create a marker file if it ran; after the fix it does not,
# and the status is non-zero.  (This also proves the body never reaches a
# blocking stdin read.)
sub {
    my $missing = "$DIR/_rf_missing_$$";   # guaranteed absent
    my $marker  = "$DIR/_rf_marker_$$";
    unlink $missing, $marker;
    my $out = _run_out(
        "( echo RAN > \"$marker\" ) < \"$missing\"\necho \"rc=\$?\"\n");
    my $body_ran = (-e $marker) ? 1 : 0;
    unlink $marker;
    my $ok_status = (index($out, "rc=1") >= 0) ? 1 : 0;
    ok_is("$body_ran/$ok_status", "0/1",
          'RF01 failed subshell redirect: body skipped, status non-zero');
},

# RF02: a subshell with a WORKING input redirect still reads the file
# (guard against the abort path firing on success).
sub {
    my $f = "$DIR/_rf_ok_$$.txt";
    my $out1 = _run_out("echo payload > \"$f\"\n");   # create via builtin
    my $out  = _run_out("( read L; echo \"got=\$L\" ) < \"$f\"\n");
    unlink $f;
    ok_is($out, "got=payload\n",
          'RF02 working subshell input redirect still reads the file');
},

);

$main::fail = 0;
print "1.." . scalar(@tests) . "\n";
$_->() for @tests;

END { $? = 1 if $main::fail }

__END__
