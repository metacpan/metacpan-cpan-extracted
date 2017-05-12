#!/usr/bin/perl
# 06_not.t (was reshape.t)

use strict;
use Acme::EyeDrops qw(sightly get_eye_string);

# -------------------------------------------------

select(STDERR);$|=1;select(STDOUT);$|=1;  # autoflush

# --------------------------------------------------

sub build_file {
   my ($f, $d) = @_;
   local *F; open(F, '>'.$f) or die "open '$f': $!";
   print F $d or die "write '$f': $!"; close(F);
}

# --------------------------------------------------

print "1..47\n";

my $hellostr = <<'HELLO';
print "hello world\n";
HELLO
my $camelstr = get_eye_string('camel');
my $indent_camelstr = $camelstr; $indent_camelstr =~ s/^/ /mg;
my $tmpf = 'bill.tmp';
my $tmpeye = 'tmpeye.eye';

# --------------------------------------------------

my $itest = 0;
my $prog;

sub test_one {
   my ($e, $ostr) = @_;
   build_file($tmpf, $prog);
   my $outstr = `$^X -w -Mstrict $tmpf`;
   my $rc = $? >> 8;
   $rc == 0 or print "not ";
   ++$itest; print "ok $itest - $e rc\n";
   $outstr eq $ostr or print "not ";
   ++$itest; print "ok $itest - $e output\n";
}

# -------------------------------------------------

$prog = sightly({ Shape         => 'camel',
                  SourceString  => $hellostr,
                  Expand        => 1,
                  InformHandler => sub {},
                  Regex         => 1 } );
my $bigprog = $prog;
test_one('big camel', "hello world\n");
$bigprog =~ tr/!-~/#/;
$bigprog eq $camelstr and print "not ";
++$itest; print "ok $itest - bigprog\n";

# -------------------------------------------------

build_file($tmpeye, $camelstr);
$prog = sightly({ Shape         => 'tmpeye',
                  EyeDir        => '.',
                  SourceString  => $hellostr,
                  Expand        => 1,
                  InformHandler => sub {},
                  Regex         => 1 } );
$bigprog = $prog;
test_one('big camel', "hello world\n");
$bigprog =~ tr/!-~/#/;
$bigprog eq $camelstr and print "not ";
++$itest; print "ok $itest - bigprog EyeDir\n";

# -------------------------------------------------

$prog = sightly({ ShapeString   => $bigprog,
                  SourceString  => $hellostr,
                  Reduce        => 1,
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('camel', "hello world\n");
# XXX: Test fails as at perl 5.18
# $prog =~ s/^use re 'eval';\n// if $] >= 5.017;   # remove leading use re 'eval' line
# $prog =~ tr/!-~/#/;
# $prog eq $camelstr or print "not ";
# ++$itest; print "ok $itest - prog\n";

# -------------------------------------------------

$prog = sightly({ Shape         => 'camel',
                  SourceString  => $hellostr,
                  Rotate        => 90,
                  InformHandler => sub {},
                  Regex         => 1 } );
my $rotprog = $prog;
test_one('rot 90 camel', "hello world\n");
$rotprog =~ tr/!-~/#/;
$rotprog eq $camelstr and print "not ";
++$itest; print "ok $itest - rotprog\n";

# -------------------------------------------------

$prog = sightly({ Shape         => 'camel',
                  SourceString  => $hellostr,
                  Rotate        => 90,
                  RotateFlip    => 1,
                  InformHandler => sub {},
                  Regex         => 1 } );
my $rot90_flipprog = $prog;
test_one('rot 90 flip camel', "hello world\n");
$rot90_flipprog =~ tr/!-~/#/;
$rot90_flipprog eq $camelstr and print "not ";
++$itest; print "ok $itest - rot 90 flip prog\n";

$prog = sightly({ Shape         => 'camel',
                  SourceString  => $hellostr,
                  Rotate        => 90,
                  Reflect       => 1,
                  InformHandler => sub {},
                  Regex         => 1 } );
my $rot90_refprog = $prog;
test_one('rot 90 reflect camel', "hello world\n");
$rot90_refprog =~ tr/!-~/#/;
$rot90_refprog eq $camelstr and print "not ";
++$itest; print "ok $itest - rot 90 ref prog\n";

$rot90_flipprog eq $rot90_refprog or print "not ";
++$itest; print "ok $itest - flip eq reflect\n";

# -------------------------------------------------

$prog = sightly({ Shape         => 'camel',
                  SourceString  => $hellostr,
                  Rotate        => 270,
                  RotateFlip    => 1,
                  InformHandler => sub {},
                  Regex         => 1 } );
my $rot270_flipprog = $prog;
test_one('rot 270 flip camel', "hello world\n");
$rot270_flipprog =~ tr/!-~/#/;
$rot270_flipprog eq $camelstr and print "not ";
++$itest; print "ok $itest - rot 270 flip prog\n";

$prog = sightly({ Shape         => 'camel',
                  SourceString  => $hellostr,
                  Rotate        => 270,
                  Reflect       => 1,
                  InformHandler => sub {},
                  Regex         => 1 } );
my $rot270_refprog = $prog;
test_one('rot 270 reflect camel', "hello world\n");
$rot270_refprog =~ tr/!-~/#/;
$rot270_refprog eq $camelstr and print "not ";
++$itest; print "ok $itest - rot 270 ref prog\n";

$rot270_flipprog eq $rot270_refprog or print "not ";
++$itest; print "ok $itest - flip eq reflect\n";

# -------------------------------------------------

$prog = sightly({ Shape          => 'camel',
                  SourceString  => $hellostr,
                  Rotate         => 90,
                  TrailingSpaces => 1,
                  InformHandler => sub {},
                  Regex          => 1 } );
$rotprog = $prog;
test_one('rot 90 trail camel', "hello world\n");
$rotprog =~ tr/!-~/#/;
$rotprog eq $camelstr and print "not ";
++$itest; print "ok $itest - prog\n";

# -------------------------------------------------

$prog = sightly({ ShapeString   => $rotprog,
                  SourceString  => $hellostr,
                  Rotate        => 270,
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('rot 270 camel', "hello world\n");
# XXX: Test fails as at perl 5.18
# $prog =~ tr/!-~/#/;
# $prog eq $bigprog or print "not ";
# ++$itest; print "ok $itest - bigprog\n";

# -------------------------------------------------

$prog = sightly({ Shape         => 'camel',
                  SourceString  => $hellostr,
                  Rotate        => 90,
                  RotateType    => 1,
                  InformHandler => sub {},
                  Regex         => 1 } );
$rotprog = $prog;
test_one('rot 90 camel', "hello world\n");
# XXX: Test fails as at perl 5.18
# $rotprog =~ tr/!-~/#/;
# $rotprog eq $camelstr and print "not ";
# ++$itest; print "ok $itest - bigprog\n";

# -------------------------------------------------

$prog = sightly({ Shape         => 'camel',
                  SourceString  => $hellostr,
                  Rotate        => 90,
                  RotateType    => 0,
                  Reduce        => 1,
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('rot 90 camel', "hello world\n");
# XXX: Test fails as at perl 5.18
# $prog =~ tr/!-~/#/;
# $prog eq $rotprog or print "not ";
# ++$itest; print "ok $itest - rotprog\n";

# -------------------------------------------------

$prog = sightly({ Shape         => 'camel',
                  SourceString  => $hellostr,
                  Rotate        => 180,
                  InformHandler => sub {},
                  Regex         => 1 } );
$rotprog = $prog;
test_one('rot 180 camel', "hello world\n");
# XXX: Test fails as at perl 5.18
# $rotprog =~ tr/!-~/#/;
# $rotprog eq $camelstr and print "not ";
# ++$itest; print "ok $itest - rotprog\n";

# -------------------------------------------------

$prog = sightly({ ShapeString   => $rotprog,
                  SourceString  => $hellostr,
                  Rotate        => 180,
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('rot 180 camel', "hello world\n");
# XXX: Test fails as at perl 5.18
# $prog =~ s/^use re 'eval';\n// if $] >= 5.017;   # remove leading use re 'eval' line
# $prog =~ tr/!-~/#/;
# $prog eq $camelstr or print "not ";
# ++$itest; print "ok $itest - rotprog\n";

# -------------------------------------------------

$prog = sightly({ Shape         => 'camel',
                  SourceString  => $hellostr,
                  Indent        => 1,
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('indent 1 camel', "hello world\n");
$prog =~ s/^use re 'eval';\n// if $] >= 5.017;   # remove leading use re 'eval' line
$prog =~ tr/!-~/#/;
$prog eq $indent_camelstr or print "not ";
++$itest; print "ok $itest - indent 1 prog\n";

# -------------------------------------------------

my $testshape     = "########         ##########\n" x 50;
my $inv_testshape = "        #########\n"           x 50;
my $ref_testshape = "##########         ########\n" x 50;

$prog = sightly({ ShapeString   => $testshape,
                  SourceString  => $hellostr,
                  Invert        => 1,
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('inverted test shape', "hello world\n");
$prog =~ s/^use re 'eval';\n// if $] >= 5.017;   # remove leading use re 'eval' line
$prog =~ tr/!-~/#/;
$prog eq $inv_testshape or print "not ";
++$itest; print "ok $itest - inverted test shape prog\n";

$prog = sightly({ ShapeString   => $testshape,
                  SourceString  => $hellostr,
                  Reflect       => 1,
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('reflected test shape', "hello world\n");
$prog =~ s/^use re 'eval';\n// if $] >= 5.017;   # remove leading use re 'eval' line
$prog =~ tr/!-~/#/;
$prog eq $ref_testshape or print "not ";
++$itest; print "ok $itest - reflected test shape prog\n";

# -------------------------------------------------

unlink($tmpf)   or die "error: unlink '$tmpf': $!";
unlink($tmpeye) or die "error: unlink '$tmpeye': $!";
