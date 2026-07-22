######################################################################
#
# 0025-sh-assign-quoting.t   SH variable-assignment value dequoting
#
# Regression tests for value dequoting in SH assignments.  Through 0.07
# the value was dequoted by stripping only a single OUTERMOST "..." or
# '...' pair, which mishandled concatenated quotes and backslash escapes:
#
#   y=a'b'c     stored  a'b'c   (should be abc)
#   w=a\ b      split at the escaped space -> tried to run "b" as a command
#
# The value is now dequoted with the same _arr_dequote() used for command
# words, so quotes anywhere in the word are removed, adjacent quoted and
# unquoted runs concatenate, and "\ " stays one word.
#
# AQ01  double-quoted run inside a word:  x=a"b"c      -> abc
# AQ02  single-quoted run inside a word:  y=a'b'c      -> abc
# AQ03  quoted span with a space + tail:  z="a b"cd    -> a bcd
# AQ04  backslash-escaped space:          w=a\ b       -> a b
# AQ05  fully double-quoted value:        p="hello world"
# AQ06  same fixes on a PREFIX assignment reaching a builtin
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

# Run SH source through BATsh->run_string, returning captured STDOUT.
sub _run_out {
    my ($source) = @_;
    BATsh::Env::init();
    my $cap = "$FindBin::Bin/_aq_out_$$.tmp";
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

# AQ01: a double-quoted run inside an otherwise bare word.
sub {
    my $out = _run_out("x=a\"b\"c\necho \"[\$x]\"\n");
    ok_is($out, "[abc]\n", 'AQ01 x=a"b"c -> abc');
},

# AQ02: a single-quoted run inside an otherwise bare word.
sub {
    my $out = _run_out("y=a'b'c\necho \"[\$y]\"\n");
    ok_is($out, "[abc]\n", 'AQ02 y=a\'b\'c -> abc');
},

# AQ03: a quoted span containing a space, with a bare tail.
sub {
    my $out = _run_out("z=\"a b\"cd\necho \"[\$z]\"\n");
    ok_is($out, "[a bcd]\n", 'AQ03 z="a b"cd -> a bcd');
},

# AQ04: a backslash-escaped space keeps the value as one word.
sub {
    my $out = _run_out("w=a\\ b\necho \"[\$w]\"\n");
    ok_is($out, "[a b]\n", 'AQ04 w=a\\ b -> a b');
},

# AQ05: a fully double-quoted value with an embedded space.
sub {
    my $out = _run_out("p=\"hello world\"\necho \"[\$p]\"\n");
    ok_is($out, "[hello world]\n", 'AQ05 p="hello world" preserved');
},

# AQ06: the same dequoting applies to a PREFIX assignment (VAR=val cmd),
# here feeding the builtin `echo` its environment-free argument list.
sub {
    my $out = _run_out("v=a'b'c echo \"[\$v seen]\"\necho \"[after \$v]\"\n");
    # After the prefix-assignment command runs, the assignment's own value
    # must have been dequoted to "abc" wherever BATsh exposes it.
    ok_is($out, "[abc seen]\n[after abc]\n",
          'AQ06 prefix assignment value dequoted (abc)');
},

);

$main::fail = 0;
print "1.." . scalar(@tests) . "\n";
$_->() for @tests;

END { $? = 1 if $main::fail }

__END__
