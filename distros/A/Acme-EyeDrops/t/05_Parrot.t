#!/usr/bin/perl
# 05_parrot.t (was sightly.t)

use strict;
use Acme::EyeDrops qw(sightly get_eye_string make_siertri make_triangle
                      regex_eval_sightly regex_binmode_print_sightly);

$|=1;

# --------------------------------------------------

sub build_file {
   my ($f, $d) = @_;
   local *F; open(F, '>'.$f) or die "open '$f': $!";
   print F $d or die "write '$f': $!"; close(F);
}

# --------------------------------------------------

print "1..75\n";

my $hellostr = <<'HELLO';
print "hello world\n";
HELLO
my $helloteststr = <<'HELLOTEST';
# Just a test.
use strict;
for my $i (0..3) {
   print "hello test $i\n";
}
HELLOTEST
my $hellofile = 'helloworld.pl';
my $camelstr = get_eye_string('camel');
my $larrystr = get_eye_string('larry');
my $damianstr = get_eye_string('damian');
my $umlstr = get_eye_string('uml');
my $windowstr = get_eye_string('window');
my $japhstr = get_eye_string('japh');
my $yanick4str = get_eye_string('yanick4');
my $siertristr = make_siertri(5);
my $baldprogstr = regex_eval_sightly($hellostr);
# XXX: regex_binmode_print_sightly seems dodgy, this call is just to
# improve code coverage. Investigate later.
my $dodgyprogstr = regex_binmode_print_sightly($hellostr);
my $tmpf = 'bill.tmp';
my $tmpeye = 'tmpeye.eye';
my $tmpeye2 = 'tmpeye2.eye';

build_file($hellofile, $hellostr);

# --------------------------------------------------

my $itest = 0;
my $prog;

sub test_one {
   my ($e, $ostr, $sh) = @_;
   build_file($tmpf, $prog);
   my $outstr = `$^X -Tw -Mstrict $tmpf`;
   my $rc = $? >> 8;
   $rc == 0 or print "not ";
   ++$itest; print "ok $itest - $e rc\n";
   $outstr eq $ostr or print "not ";
   ++$itest; print "ok $itest - $e output\n";
   $prog =~ s/^use re 'eval';\n// if $] >= 5.017;   # remove leading use re 'eval' line
   $prog =~ s/^.*eval.*\n\n\n//;
   $prog =~ tr/!-~/#/;
   $prog eq $sh or print "not ";
   ++$itest; print "ok $itest - $e shape\n";
}

# Camel helloworld.pl ------------------------------

$prog = sightly({ Shape         => 'camel',
                  SourceString  => $hellostr,
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('Camel helloworld', "hello world\n", $camelstr);

# uml/window helloworld.pl -------------------------

$prog = sightly({ Shape         => 'uml,window',
                  SourceString  => $hellostr,
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('uml/window helloworld', "hello world\n", $umlstr . $windowstr);

# uml/window helloworld.pl -------------------------

build_file($tmpeye, $umlstr);
build_file($tmpeye2, $windowstr);

$prog = sightly({ Shape         => 'all',
                  EyeDir        => '.',
                  SourceString  => $hellostr,
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('uml/window all helloworld', "hello world\n", $umlstr . $windowstr);

$prog = sightly({ Shape         => 'all',
                  EyeDir        => '.',
                  Width         => 2,
                  SourceString  => $hellostr,
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('uml/window all width helloworld', "hello world\n",
   $umlstr . "\n\n" . $windowstr);

# Text string print --------------------------------

my $srcstr = "Bill Gates is a pest!\n";
$prog = sightly({ Shape         => 'window',
                  SourceString  => $srcstr,
                  Regex         => 1,
                  InformHandler => sub {},
                  Print         => 1 } );
test_one('Bill Gates is a pest!', $srcstr, $windowstr);

# Text string print (eval) -------------------------

$prog = sightly({ Shape         => 'window',
                  SourceString  => $srcstr,
                  Regex         => 0,
                  InformHandler => sub {},
                  Print         => 1 } );
test_one('Bill Gates is a pest!', $srcstr, $windowstr);

# Binary encode/decode -----------------------------

my $encodestr = qq#binmode(STDOUT);print eval '"'.\n\n\n#;
$encodestr =~ tr/!-~/#/;
$encodestr .= $camelstr x 5;
$srcstr = join("", map(chr(), 0..255));
$prog = sightly({ Shape         => 'camel',
                  SourceString  => $srcstr,
                  Binary        => 1,
                  Regex         => 0,
                  InformHandler => sub {},
                  Print         => 1 } );
build_file($tmpf, $prog);
# This seems to stop on CTRL-Z on Windows!
# Something to do with binmode ??
#   $outstr = `$^X -w -Mstrict $tmpf`;
# so use a temporary file instead.
my $tmpf2 = 'bill2.tmp';
system("$^X -Tw -Mstrict $tmpf >$tmpf2");
my $rc = $? >> 8;
$rc == 0 or print "not ";
++$itest; print "ok $itest - binary str encode rc\n";
open(TT, $tmpf2) or die "open '$tmpf2': $!";
binmode(TT);
my $outstr = do { local $/; <TT> };
close(TT);
$outstr eq $srcstr or print "not ";
++$itest; print "ok $itest - binary str encode output\n";
$prog =~ tr/!-~/#/;
$prog eq $encodestr or print "not ";
++$itest; print "ok $itest - binary str encode shape\n";

$prog = sightly({ Shape         => 'camel',
                  SourceFile    => $tmpf2,
                  Binary        => 1,
                  Regex         => 0,
                  InformHandler => sub {},
                  Print         => 1 } );
build_file($tmpf, $prog);
system("$^X -Tw -Mstrict $tmpf >$tmpf2");
$rc = $? >> 8;
$rc == 0 or print "not ";
++$itest; print "ok $itest - binary file encode rc\n";
open(TT, $tmpf2) or die "open '$tmpf2': $!";
binmode(TT);
$outstr = do { local $/; <TT> };
close(TT);
$outstr eq $srcstr or print "not ";
++$itest; print "ok $itest - binary file encode output\n";
$prog =~ tr/!-~/#/;
$prog eq $encodestr or print "not ";
++$itest; print "ok $itest - binary file encode shape\n";

# Self-printing JAPH -------------------------------

my $src = <<'PROG';
open 0;
$/ = undef;
$x = <0>;
close 0;
$x =~ tr/!-~/#/;
print $x;
PROG
$prog = sightly({ Shape         => 'japh',
                  SourceString  => $src,
                  InformHandler => sub {},
                  Regex         => 1 } );
build_file($tmpf, $prog);

# This one used to be OK with -Mstrict but not as of perl 5.8.4.
# From the perl 5.8.4 perldelta:
#   Pragmata are now correctly propagated into (?{...}) constructions in regexps.
#   Code such as
#     my $x = qr{ ... (??{ $x }) ... };
#   will now (correctly) fail under use strict.
#   (As the inner $x is and has always referred to $::x)
$outstr = `$^X -Tw $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
++$itest; print "ok $itest - self-printing japh rc\n";
$outstr =~ s/^.+\n// if $] >= 5.017;   # remove leading use re 'eval' line
$outstr eq $japhstr or print "not ";
++$itest; print "ok $itest - self-printing japh output\n";

# Camel helloworld.pl (FillerVar=';')---------------

$prog = sightly({ Shape         => 'camel',
                  SourceString  => $hellostr,
                  FillerVar     => ';',
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('Camel helloworld fillervar=;', "hello world\n", $camelstr);

# Camel helloworld.pl (FillerVar=';#')--------------

$prog = sightly({ Shape         => 'camel',
                  SourceString  => $hellostr,
                  FillerVar     => ';#',
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('Camel helloworld fillervar=;#', "hello world\n", $camelstr);

# Camel helloworld.pl (FillerVar='')----------------

$prog = sightly({ Shape         => 'camel',
                  SourceString  => $hellostr,
                  FillerVar     => '',
                  InformHandler => sub {},
                  Regex         => 1 } );
build_file($tmpf, $prog);
$outstr = `$^X -Tw -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
++$itest; print "ok $itest - Camel helloworld fillervar= rc\n";
$outstr eq "hello world\n" or print "not ";
++$itest; print "ok $itest - Camel helloworld fillervar= output\n";
$prog =~ s/^use re 'eval';\n// if $] >= 5.017;   # remove leading use re 'eval' line
length($prog) eq 472 or print "not ";
++$itest; print "ok $itest - Camel helloworld fillervar= length\n";

# Yanick4 hellotest.pl -----------------(3 shapes)--

$prog = sightly({ Shape         => 'yanick4',
                  SourceString  => $helloteststr,
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('Yanick4 hellotest',
   "hello test 0\nhello test 1\nhello test 2\nhello test 3\n",
   $yanick4str x 3);

# Yanick4 hellotest.pl (FillerVar=';')--(3 shapes)--

$prog = sightly({ Shape         => 'yanick4',
                  SourceString  => $helloteststr,
                  FillerVar     => ';',
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('Yanick4 hellotest FillerVar=;',
   "hello test 0\nhello test 1\nhello test 2\nhello test 3\n",
   $yanick4str x 3);

# Yanick4 hellotest.pl (FillerVar='')---(3 shapes)--

$prog = sightly({ Shape         => 'yanick4',
                  SourceString  => $helloteststr,
                  FillerVar     => '',
                  InformHandler => sub {},
                  Regex         => 1 } );
build_file($tmpf, $prog);
$outstr = `$^X -Tw -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
++$itest; print "ok $itest - Yanick4 hellotest FillerVar= rc\n";
$outstr eq "hello test 0\nhello test 1\nhello test 2\nhello test 3\n"
   or print "not ";
++$itest; print "ok $itest - Yanick4 helloworld fillervar= output\n";
$prog =~ tr/!-~/#/;
# Note: normal 'or' test is 'and' test on next line (hacky).
$prog eq $yanick4str x 3 and print "not ";
++$itest; print "ok $itest - Yanick4 helloworld fillervar= shape\n";

# siertri hellotest.pl (FillerVar=';')--(3 shapes)--

$prog = sightly({ Shape         => 'siertri',
                  Width         => 5,
                  SourceString  => $helloteststr,
                  FillerVar     => ';',
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('siertri hellotest FillerVar=;',
   "hello test 0\nhello test 1\nhello test 2\nhello test 3\n",
   $siertristr x 5);

# Camel helloworld.pl from local eye file ----------

build_file($tmpf2, $camelstr);
$prog = sightly({ Shape         => $tmpf2,
                  SourceString  => $hellostr,
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('Camel helloworld local eye file', "hello world\n", $camelstr);

# Shapeless helloworld.pl --------------------------

$prog = sightly({ SourceString  => $hellostr,
                  InformHandler => sub {},
                  Regex         => 1 } );
my $prog2 = $prog;
$prog2 =~ s/^use re 'eval';\n// if $] >= 5.017;   # remove leading use re 'eval' line
$prog2 eq $baldprogstr or print "not ";
++$itest; print "ok $itest - Shapeless helloworld bald\n";
build_file($tmpf, $prog);
$outstr = `$^X -Tw -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
++$itest; print "ok $itest - Shapeless helloworld rc\n";
$outstr eq "hello world\n" or print "not ";
++$itest; print "ok $itest - Shapeless helloworld output\n";
$prog =~ s/^use re 'eval';\n// if $] >= 5.017;   # remove leading use re 'eval' line
$prog =~ tr/!-~/#/;
my $nwhite = $prog =~ tr/\n //;
$nwhite == 0 or print "not ";
++$itest; print "ok $itest - Shapeless helloworld nwhite\n";

# Fixed width helloworld.pl ------------------------

$prog = sightly({ SourceString  => $hellostr,
                  Width         => 42,
                  InformHandler => sub {},
                  Regex         => 1 } );
my $ss = '#' x 42 . "\n";
test_one('Fixed width helloworld', "hello world\n", $ss x 8);

# --------------------------------------------------

$prog = sightly({ Shape         => 'larry',
                  SourceFile    => $hellofile,
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one("Larry helloworld", "hello world\n", $larrystr);

# ----------------------------------------------------

$prog = sightly({ Shape         => 'larry,damian',
                  SourceFile    => $hellofile,
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('Larry/Damian helloworld', "hello world\n", $larrystr . $damianstr);

# ----------------------------------------------------

$prog = sightly({ Shape         => 'damian,larry',
                  SourceFile    => $hellofile,
                  Gap           => 2,
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('Damian/Larry helloworld', "hello world\n",
   join("\n\n", $damianstr, $larrystr));

# ----------------------------------------------------

my $shape = "####################   \n   \n########## \n" x 11;
$prog = sightly({ ShapeString   => $shape,
                  SourceFile    => $hellofile,
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('Trailing spaces in shape', "hello world\n", $shape);

# ----------------------------------------------------

$prog = sightly({ Shape         => 'siertri,larry,siertri,larry',
                  SourceFile    => $hellofile,
                  Gap           => 2,
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('siertr/Larry x 2 helloworld', "hello world\n",
   join("\n\n", make_siertri(0), $larrystr,
                make_siertri(0), $larrystr));

# ----------------------------------------------------

$prog = sightly({ Shape         => "larry,triangle,$tmpf2",
                  SourceFile    => $hellofile,
                  Gap           => 2,
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('larry/triangle/camelshapefile helloworld', "hello world\n",
   join("\n\n", $larrystr, make_triangle(0), $camelstr));

# ----------------------------------------------------

unlink($tmpf) or die "error: unlink '$tmpf': $!";
unlink($tmpf2) or die "error: unlink '$tmpf2': $!";
unlink($tmpeye) or die "error: unlink '$tmpeye': $!";
unlink($tmpeye2) or die "error: unlink '$tmpeye2': $!";
unlink($hellofile) or die "error: unlink '$hellofile': $!";
