#!/usr/bin/perl
# 03_Larry.t (was limit.t)

use strict;
use Acme::EyeDrops qw(sightly regex_eval_sightly);

select(STDERR);$|=1;select(STDOUT);$|=1;  # autoflush

# --------------------------------------------------

sub build_file {
   my ($f, $d) = @_;
   local *F; open(F, '>'.$f) or die "open '$f': $!";
   print F $d or die "write '$f': $!"; close(F);
}

# --------------------------------------------------

print "1..45\n";

# Exact fit is 215 characters.
my $exact = 215;

my $tmpf = 'bill.tmp';

# --------------------------------------------------

my $itest = 0;
my $prog;
my $last;

sub test_one {
   my ($e, $ostr, $enlf) = @_;
   build_file($tmpf, $prog);
   my $outstr = `$^X -w -Mstrict $tmpf`;
   my $rc = $? >> 8;
   $rc == 0 or print "not ";
   ++$itest; print "ok $itest - $e rc\n";
   $outstr eq $ostr or print "not ";
   ++$itest; print "ok $itest - $e output\n";
   $prog =~ s/^.+\n// if $] >= 5.017;   # remove leading use re 'eval' line
   my $nlf = $prog =~ tr/\n//;
   $nlf == $enlf or print "not ";
   ++$itest; print "ok $itest - $e nlf $enlf\n";
   $last = chop($prog);
   $last eq "\n" or print "not ";
   ++$itest; print "ok $itest - $e last is newline\n";
}

# --------------------------------------------------

my $srcstr = qq#print "abc\\n";\n#;
my $sightlystr = regex_eval_sightly($srcstr);
length($sightlystr) == $exact or print "not ";
++$itest; print "ok $itest - exact 215\n";

# Exact fit abc ------------------------------------

$prog = sightly({ Width         => $exact,
                  SourceString  => $srcstr,
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('Exact fit abc', "abc\n", 1);
length($prog) == $exact or print "not ";
++$itest; print "ok $itest\n";
$prog eq $sightlystr or print "not ";
++$itest; print "ok $itest\n";
$last = chop($prog);
$last eq ')' or print "not ";
++$itest; print "ok $itest\n";

# One more  abc ------------------------------------

$prog = sightly({ Width         => $exact+1,
                  SourceString  => $srcstr,
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('One more abc', "abc\n", 1);
length($prog) == $exact+1 or print "not ";
++$itest; print "ok $itest\n";
$last = chop($prog);
$last eq ';' or print "not ";
++$itest; print "ok $itest\n";
$prog eq $sightlystr or print "not ";
++$itest; print "ok $itest\n";

# One less  abc ------------------------------------

$prog = sightly({ Width         => $exact-1,
                  SourceString  => $srcstr,
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('One less abc', "abc\n", 2);
my @lines = split(/^/, $prog, -1); chop(@lines);
scalar(@lines) == 2 or print "not ";
++$itest; print "ok $itest\n";
my $fchar = substr($lines[1], 0, 1);
$fchar eq ')' or print "not ";
++$itest; print "ok $itest\n";
length($prog) == 2*($exact-1)+1 or print "not ";
++$itest; print "ok $itest\n";
my $nprog = $lines[0] . $fchar;
$nprog eq $sightlystr or print "not ";
++$itest; print "ok $itest\n";

# --------------------------------------------------
# Test with FillerVar = '#'

# Exact fit abc ------------------------------------

$prog = sightly({ Width         => $exact,
                  SourceString  => $srcstr,
                  FillerVar     => '#',
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('Exact fit abc, FillerVar=#', "abc\n", 1);
length($prog) == $exact or print "not ";
++$itest; print "ok $itest\n";
$prog eq $sightlystr or print "not ";
++$itest; print "ok $itest\n";
$last = chop($prog);
$last eq ')' or print "not ";
++$itest; print "ok $itest\n";

# One more  abc ------------------------------------

$prog = sightly({ Width         => $exact+1,
                  SourceString  => $srcstr,
                  FillerVar     => '#',
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('One more abc, FillerVar=#', "abc\n", 1);
length($prog) == $exact+1 or print "not ";
++$itest; print "ok $itest\n";
$last = chop($prog);
$last eq ';' or print "not ";
++$itest; print "ok $itest\n";
$prog eq $sightlystr or print "not ";
++$itest; print "ok $itest\n";

# One less  abc ------------------------------------

$prog = sightly({ Width         => $exact-1,
                  SourceString  => $srcstr,
                  FillerVar     => '#',
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('One less abc, FillerVar=#', "abc\n", 2);
@lines = split(/^/, $prog, -1); chop(@lines);
scalar(@lines) == 2 or print "not ";
++$itest; print "ok $itest\n";
$fchar = substr($lines[1], 0, 1);
$fchar eq ')' or print "not ";
++$itest; print "ok $itest\n";
length($prog) == 2*($exact-1)+1 or print "not ";
++$itest; print "ok $itest\n";
$nprog = $lines[0] . $fchar;
$nprog eq $sightlystr or print "not ";
++$itest; print "ok $itest\n";

# --------------------------------------------------

unlink($tmpf) or die "error: unlink '$tmpf': $!";
