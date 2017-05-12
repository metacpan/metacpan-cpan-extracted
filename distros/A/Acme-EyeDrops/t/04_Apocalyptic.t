#!/usr/bin/perl
# 04_Apocalyptic.t (was limit2.t)

use strict;
use Acme::EyeDrops qw(sightly);

select(STDERR);$|=1;select(STDOUT);$|=1;  # autoflush

# --------------------------------------------------

sub build_file {
   my ($f, $d) = @_;
   local *F; open(F, '>'.$f) or die "open '$f': $!";
   print F $d or die "write '$f': $!"; close(F);
}

# --------------------------------------------------

print "1..44\n";

my $tmpf = 'bill.tmp';

# --------------------------------------------------

my $itest = 0;
my $srcstr = '$x=9';

sub test_one {
   my ($e, $shapestr, $enlf) = @_;
   my $prog = sightly({ ShapeString   => $shapestr,
                        SourceString  => $srcstr,
                        InformHandler => sub {},
                        Regex         => 1 } );
   build_file($tmpf, $prog);
   my $outstr = `$^X -w -Mstrict $tmpf`;
   $? >> 8 == 0 or print "not ";
   ++$itest; print "ok $itest - $e rc\n";
   $outstr eq "" or print "not ";
   ++$itest; print "ok $itest - $e output\n";
   $prog =~ s/^.+\n// if $] >= 5.017;   # remove leading use re 'eval' line
   $prog =~ tr/\n// == $enlf or print "not ";
   ++$itest; print "ok $itest - $e nlf $enlf\n";
   $prog =~ tr/!-~/#/;
   $prog eq $shapestr or print "not ";
   ++$itest; print "ok $itest - $e shape\n";
}

sub test_one_empty {
   my $shapestr = shift;
   my $prog = sightly( { ShapeString   => $shapestr,
                         InformHandler => sub {} } );
   build_file($tmpf, $prog);
   my $outstr = `$^X -w -Mstrict $tmpf`;
   $? >> 8 == 0 or print "not ";
   ++$itest; print "ok $itest - rc\n";
   $outstr eq "" or print "not ";
   ++$itest; print "ok $itest - output\n";
   $prog =~ tr/\n// == 1 or print "not ";
   ++$itest; print "ok $itest - nlf\n";
   $prog =~ tr/!-~/#/;
   $prog eq $shapestr or print "not ";
   ++$itest; print "ok $itest - shape\n";
}

# --------------------------------------------------

my $bugshape =
'#######################################################' .
'#######################################################' .
"\n" . "# # #\n";

my $onetoomanyshape =
'#######################################################' .
'#######################################################' .
"\n" . "# # # #\n";

# -----------------------------------------------------

test_one('One too many bug', $onetoomanyshape, 2);
test_one('Invalid program bug', $bugshape, 2);

# more invalid program tests --------------------------

# This one failed prior to EyeDrops version 1.17.
test_one_empty("############  ######  ###  ###\n");

test_one_empty("############  ###  ###  #\n");
test_one_empty("############  #####  ###  #\n");
test_one_empty("############  ###  ####  #\n");
test_one_empty("############  #\n");
test_one_empty("############  ##\n");
test_one_empty("############  ###\n");
test_one_empty("############  ####\n");
test_one_empty("############\n");

# -----------------------------------------------------

unlink($tmpf) or die "error: unlink '$tmpf': $!";
