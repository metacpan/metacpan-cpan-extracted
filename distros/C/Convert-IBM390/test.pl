# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'.

################## We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..15\n"; }
END {print "not ok 1\n" unless $loaded;}
use Convert::IBM390 qw(:all);
$loaded = 1;
print "ok 1\n";

################## End of black magic.

$VERBOSE = $ENV{TEST_VERBOSE};

print Convert::IBM390::version(), "\n";

my $failed = 0;
#----- asc2eb
print "asc2eb.............";
my ($asc, $eb);
$asc = '';
$eb = asc2eb($asc);
was_it_ok(2, $eb , '');
print "      .............";
$asc = ".<(+|!\$*%\@=[]A2";
$eb = asc2eb($asc);
was_it_ok(3, $eb, "KLMNOZ[\\l|~\xAD\xBD\xC1\xF2");

#----- eb2asc
print "eb2asc.............";
$eb = "";
$asc = eb2asc($eb);
was_it_ok(4, $asc, "");
print "      .............";
$eb = "KLMNOZ[\\l|~\xAD\xBD\xC1\xF2";
$asc = eb2asc($eb);
was_it_ok(5, $asc, ".<(+|!\$*%\@=[]A2");

#----- eb2ascp
print "eb2ascp............";
$eb = "";
$asc = eb2ascp($eb);
was_it_ok(6, $asc, "");
print "       ............";
$eb = "KLMNOZ[\\l|~\xAD\xBD\xC1\xF2\x00\xFE";
$asc = eb2ascp($eb);
was_it_ok(7, $asc, ".<(+|!\$*%\@=[]A2  ");

#----- hexdump
print "hexdump............";
my ($string, @hdump);
$string = "Now is the time for all good Perls to come to the aid of
their systems";
@hdump = hexdump($string, 4);
was_it_ok(8, $hdump[0],
  "000004: 4E6F7720 69732074 68652074 696D6520  666F7220 616C6C20 676F6F64 20506572  *Now is the time for all good Per*\n");

#----- packeb
print "packeb.............";
$ptempl = $in = $hexes = '';
open(PT, "./packtests")  or die "test.pl: could not open packtests: $!";
while (1) {
   chomp ($a = <PT>);
   last if length($a) == 0;
   $ptempl .= $a;
   chomp ($b = <PT>);
   $in .= " $b";
   chomp ($c = <PT>);
   $hexes .= $c;
}
close PT;
@input = split(' ', $in);
$expected = pack("H*", $hexes);
$ebrecord = packeb($ptempl, @input);
was_it_ok(9, $ebrecord, $expected);

#----- unpackeb
print "unpackeb...........";
$utempl = $hexes = $expected = '';
open(UT, "./unptests")  or die "test.pl: could not open unptests: $!";
while (1) {
   chomp ($a = <UT>);
   last if length($a) == 0;
   $utempl .= $a;
   chomp ($b = <UT>);
   $hexes .= $b;
   chomp ($c = <UT>);
   $expected .= " $c";
}
close UT;
$expected = substr($expected, 1); # Remove leading blank.
$ebrecord = pack("H*", $hexes);
@unp = unpackeb($utempl, $ebrecord);
was_it_ok(10, "@unp", $expected);

#----- unpackeb with undefined results
print "        ...........";
$ebrecord = pack("H12", "C500FFFEC1C2");
($pp, $vv) = unpackeb("p2v", $ebrecord);
was_it_ok_b(11, !defined($pp) && !defined($vv));

#----- packeb with over-large numbers
print "packeb crash.......";
eval { packeb('p16', 1.0e99) };
was_it_ok_b(12, $@ && $@ =~ /too long/);

print "            .......";
eval { packeb('z32', 1.0e99) };
was_it_ok_b(13, $@ && $@ =~ /too long/);

#----- asc2eb with a different codepage
print "asc2eb.............";
set_codepage('CP01141');
$asc = ".<(+|!\$*%\@=[]A2";
$eb = asc2eb($asc);
was_it_ok(14, $eb, "KLMN\xBBO[\\l\xB5~c\xFC\xC1\xF2");

#----- eb2asc with a different codepage
print "eb2asc.............";
set_codepage('CP01142');
$eb = "KLMNOZ[\\l|~\xAD\xBD\xC1\xF2";
$asc = eb2asc($eb);
was_it_ok(15, $asc, ".<(+!\xA4\xC5*%\xD8=\xDD\xA8A2");

if ($failed == 0) { print "All tests successful.\n"; }
else {
   $tt = ($failed == 1) ? "1 test" : "$failed tests";
   print "$tt failed!  There is no joy in Mudville.\n";
}


#--- Was it okay?  Arguments: test number, result, expected result.
sub was_it_ok {
 my ($num, $res, $exp) = @_;

 if ($res eq $exp) { print "ok $num\n"; }
 else   { print "not ok $num\n"; $failed++; }
 if ($VERBOSE) {
    if ($exp =~ /[\x00-\x07\x0E-\x1E]/) {
       print "  expected: <",unpack("H*",$exp), ">\n";
       print "  actual:   <",unpack("H*",$res), ">\n";
    } else {
       print "  expected: <$exp>\n  actual:   <$res>\n";
    }
 }
}

#--- The same, but just a number and one Boolean argument.
sub was_it_ok_b {
 my ($num, $okay) = @_;

 if ($okay) { print "ok $num\n"; }
 else       { print "not ok $num\n"; $failed++; }
}
