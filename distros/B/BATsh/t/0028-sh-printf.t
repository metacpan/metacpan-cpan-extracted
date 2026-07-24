######################################################################
#
# 0028-sh-printf.t   SH printf builtin (v0.08 rewrite)
#
# The v0.08 printf is a faithful pure-Perl implementation replacing the
# earlier naive version (which only understood \n and \t, split quoted
# arguments on whitespace, did not recycle the format, and leaked Perl
# "Redundant argument" / "isn't numeric" warnings to STDERR).
#
# PF01   format recycling (reused until arguments are exhausted)
# PF02   %b interprets backslash escapes in the argument
# PF03   %b with a trailing newline from the format
# PF04   field width and precision on a float
# PF05   -v VAR stores the result instead of printing
# PF06   %q quotes a value containing a space
# PF07   %q leaves a safe value bare
# PF08   a non-numeric %d argument becomes 0 with no STDERR noise
# PF09   %s with no arguments produces one (empty) pass
# PF10   dynamic width via '*'
# PF11   %x / %X hexadecimal
# PF12   %c prints the first character of each argument
# PF13   octal escape in the format (\101 -> 'A')
# PF14   \xHH hex escape in the format
# PF15   %% is a literal percent
# PF16   one-per-line recycling of several arguments
# PF17   \c in a %b argument ends output
# PF18   POSIX 'C argument yields the character's code
# PF19   -vVAR attached option form
# PF20   -- terminates option parsing
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
    my $cap_out = "$FindBin::Bin/_pf_out_$$.tmp";
    my $cap_err = "$FindBin::Bin/_pf_err_$$.tmp";
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

my $TAB = "\t";
my $NL  = "\n";

my @tests = (

# PF01: the format is reused until all arguments are consumed.
sub {
    my (undef, $out) = _run_capture("printf '%s-%s\\n' a b c d\n");
    ok_is($out, "a-b\nc-d\n", 'PF01 format recycling');
},

# PF02: %b interprets the argument's backslash escapes.
sub {
    my (undef, $out) = _run_capture("printf '%b' 'a\\tb'\n");
    ok_is($out, "a${TAB}b", 'PF02 %b interprets escapes');
},

# PF03: %b argument plus a newline from the format.
sub {
    my (undef, $out) = _run_capture("printf '%b\\n' 'x\\ny'\n");
    ok_is($out, "x\ny\n", 'PF03 %b with format newline');
},

# PF04: width and precision on a floating value.
sub {
    my (undef, $out) = _run_capture("printf '%6.2f\\n' 3.14159\n");
    ok_is($out, "  3.14\n", 'PF04 float width/precision');
},

# PF05: -v VAR stores the formatted result in a shell variable.
sub {
    my (undef, $out) =
        _run_capture("printf -v OUT '%03d' 7\necho \"[\$OUT]\"\n");
    ok_is($out, "[007]\n", 'PF05 -v stores in a variable');
},

# PF06: %q quotes a value with a space so it reads back as one word.
sub {
    my (undef, $out) = _run_capture("printf '%q\\n' 'a b'\n");
    ok_is($out, "'a b'\n", 'PF06 %q quotes a space');
},

# PF07: %q leaves a shell-safe value unquoted.
sub {
    my (undef, $out) = _run_capture("printf '%q\\n' abc\n");
    ok_is($out, "abc\n", 'PF07 %q leaves safe value bare');
},

# PF08: a non-numeric %d argument prints 0 and emits nothing on STDERR
#       (the old implementation leaked an "isn't numeric" warning).
sub {
    my (undef, $out) = _run_capture("printf '%d\\n' abc\n");
    ok_is($out, "0\n", 'PF08a non-numeric %d -> 0');
},
sub {
    my (undef, undef, $err) = _run_capture("printf '%d\\n' abc\n");
    ok_is($err, '', 'PF08b no STDERR warning leak');
},

# PF09: %s with no argument still runs the format once (empty string).
sub {
    my (undef, $out) = _run_capture("printf '%s\\n'\n");
    ok_is($out, "\n", 'PF09 %s with no argument');
},

# PF10: dynamic field width taken from an argument via '*'.
sub {
    my (undef, $out) = _run_capture("printf '%*d\\n' 4 7\n");
    ok_is($out, "   7\n", 'PF10 dynamic width via *');
},

# PF11: lower- and upper-case hexadecimal.
sub {
    my (undef, $out) = _run_capture("printf '%x/%X\\n' 255 255\n");
    ok_is($out, "ff/FF\n", 'PF11 %x and %X');
},

# PF12: %c uses only the first character of each argument.
sub {
    my (undef, $out) = _run_capture("printf '%c%c\\n' foo bar\n");
    ok_is($out, "fb\n", 'PF12 %c first character');
},

# PF13: an octal escape in the format string.
sub {
    my (undef, $out) = _run_capture("printf '\\101\\n'\n");
    ok_is($out, "A\n", 'PF13 octal escape \\101');
},

# PF14: a \xHH hex escape in the format string.
sub {
    my (undef, $out) = _run_capture("printf '\\x41\\n'\n");
    ok_is($out, "A\n", 'PF14 hex escape \\x41');
},

# PF15: %% is a literal percent sign.
sub {
    my (undef, $out) = _run_capture("printf '100%%\\n'\n");
    ok_is($out, "100%\n", 'PF15 literal percent');
},

# PF16: recycling one format per argument (the "%s\\n" idiom).
sub {
    my (undef, $out) =
        _run_capture("printf '%s\\n' one two three\n");
    ok_is($out, "one\ntwo\nthree\n", 'PF16 one-per-line recycling');
},

# PF17: \c inside a %b argument ends all output.
sub {
    my (undef, $out) = _run_capture("printf 'ab%b' 'X\\ccd'\n");
    ok_is($out, "abX", 'PF17 \\c in %b ends output');
},

# PF18: a leading quote selects the following character's code.
sub {
    my (undef, $out) = _run_capture("printf '%d\\n' \"'A\"\n");
    ok_is($out, "65\n", 'PF18 POSIX quoted-char code');
},

# PF19: the attached -vVAR option form.
sub {
    my (undef, $out) =
        _run_capture("printf -vX '%s' hi\necho \"[\$X]\"\n");
    ok_is($out, "[hi]\n", 'PF19 -vVAR attached form');
},

# PF20: -- ends option parsing so a format may start with '-'.
sub {
    my (undef, $out) = _run_capture("printf -- '%s\\n' -n\n");
    ok_is($out, "-n\n", 'PF20 -- terminates options');
},

);

$main::fail = 0;
print "1.." . scalar(@tests) . "\n";
$_->() for @tests;

END { $? = 1 if $main::fail }

__END__
