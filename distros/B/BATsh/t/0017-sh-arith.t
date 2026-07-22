######################################################################
#
# 0017-sh-arith.t  SH $(( )) arithmetic: comparison, logical, bitwise,
#                  assignment, ++/--, ternary, bases (v0.07)
#
# AR01-AR04  comparison operators yield 1/0
# AR05-AR08  logical && || ! and ternary ?:
# AR09-AR12  assignment operators write back to the variable store
# AR13-AR16  prefix/postfix ++ and --
# AR17-AR21  bitwise & | ^ ~ << >>
# AR22-AR25  / and % truncate toward zero; ** is right-associative
# AR26-AR28  hex/octal literals and the comma operator
# AR29-AR30  errors (division by zero, unknown token) yield 0 + warning
# AR31       << inside $(( )) is not taken for a here-document
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

# Run source through BATsh->run_string, capturing STDOUT (and discarding
# STDERR so expected warnings do not pollute the TAP stream); return output.
sub _run_capture {
    my ($source) = @_;
    BATsh::Env::init();
    my $cap = "$FindBin::Bin/_ar_cap_$$.tmp";
    local (*OLDOUT, *OLDERR);
    open(OLDOUT, ">&STDOUT") or die "cannot dup STDOUT: $!";
    open(OLDERR, ">&STDERR") or die "cannot dup STDERR: $!";
    close(STDOUT);
    open(STDOUT, "> $cap")
        or do { open(STDOUT, ">&OLDOUT"); die "cannot redirect STDOUT: $!" };
    close(STDERR);
    open(STDERR, "> $cap.err");
    eval { BATsh->run_string($source) };
    my $err = $@;
    close(STDOUT);
    open(STDOUT, ">&OLDOUT") or die "cannot restore STDOUT: $!";
    close(OLDOUT);
    close(STDERR);
    open(STDERR, ">&OLDERR");
    close(OLDERR);
    my $out = '';
    local *RF;
    if (open(RF, $cap)) { local $/; $out = <RF>; close(RF) }
    unlink($cap);
    unlink("$cap.err");
    $out = '' unless defined $out;
    warn $err if $err;
    return $out;
}

my $test = 0;
sub ok_out {
    my ($source, $expected, $name) = @_;
    $test++;
    my $out = _run_capture($source);
    $out =~ s/\r?\n\z//;
    if ($out eq $expected) { print "ok $test - $name\n"; return 1 }
    print "not ok $test - $name (got [$out] expected [$expected])\n";
    $main::fail++;
    return 0;
}

my @tests = (
sub { ok_out('echo $((3<5))',  '1', 'AR01 < true yields 1') },
sub { ok_out('echo $((5<3))',  '0', 'AR02 < false yields 0') },
sub { ok_out('echo $((4>=4))', '1', 'AR03 >= boundary') },
sub { ok_out('echo $((4!=4))', '0', 'AR04 != false') },
sub { ok_out('echo $((10>3 && 2))', '1', 'AR05 && normalizes to 1') },
sub { ok_out('echo $((0||0))',      '0', 'AR06 || both false') },
sub { ok_out('echo $((!0))',        '1', 'AR07 ! inverts') },
sub { ok_out('echo $((5>3?7:9))',   '7', 'AR08 ternary true branch') },
sub { ok_out("i=1\necho \$((i+=2))",  '3',  'AR09 += returns new value') },
sub { ok_out("i=1\ni=\$((i+=2))\necho \$i", '3', 'AR10 += writes back') },
sub { ok_out("x=7\necho \$((x=42))\necho \$x", "42\n42", 'AR11 = assigns') },
sub { ok_out("x=10\necho \$((x<<=2))\necho \$x", "40\n40", 'AR12 <<= compound') },
sub { ok_out("j=5\necho \$((j++))\necho \$j", "5\n6", 'AR13 postfix ++ returns old') },
sub { ok_out("j=5\necho \$((++j))\necho \$j", "6\n6", 'AR14 prefix ++ returns new') },
sub { ok_out("j=5\necho \$((j--))\necho \$j", "5\n4", 'AR15 postfix --') },
sub { ok_out("j=5\necho \$((--j))\necho \$j", "4\n4", 'AR16 prefix --') },
sub { ok_out('echo $((6&3))',  '2',  'AR17 bitwise &') },
sub { ok_out('echo $((6|1))',  '7',  'AR18 bitwise |') },
sub { ok_out('echo $((6^3))',  '5',  'AR19 bitwise ^') },
sub { ok_out('echo $((~5))',   '-6', 'AR20 bitwise ~ is signed') },
sub { ok_out('echo $((32>>2))', '8', 'AR21 >> shift') },
sub { ok_out('echo $((-7/2))', '-3', 'AR22 / truncates toward zero') },
sub { ok_out('echo $((-7%2))', '-1', 'AR23 % follows the dividend sign') },
sub { ok_out('echo $((2**10))', '1024', 'AR24 ** exponent') },
sub { ok_out('echo $((2**3**2))', '512', 'AR25 ** right-associative') },
sub { ok_out('echo $((0x1f))', '31', 'AR26 hex literal') },
sub { ok_out('echo $((010))',  '8',  'AR27 octal literal') },
sub { ok_out('echo $((1+1, 2+2))', '4', 'AR28 comma operator') },
sub { ok_out('echo $((1/0))',  '0',  'AR29 division by zero yields 0') },
sub { ok_out('echo $((3 @ 5))', '0', 'AR30 unknown token yields 0') },
sub { ok_out('echo $((1<<4))', '16', 'AR31 << in arithmetic, not a heredoc') },
);

$main::fail = 0;
print "1.." . scalar(@tests) . "\n";
$_->() for @tests;

END { $? = 1 if $main::fail }

__END__
