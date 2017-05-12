#!/install/perl/live/bin/perl -w
#
# This program creates a file containing all 256 byte values
# in ascending order.
# 1) set tblpath as appropriate for your EBCDIC system
# 2) Run this on the EBCDIC based system
# 3) Transfer the resulting file using ascii translation
# You now have a file containing the translation table
#
use integer;

my $tblpath = '/home/leachcj/tbl';

open(RTBL, ">$tblpath") || die "opening $tblpath\n";
print RTBL pack("C256", ( 0 .. 255 ));
close(RTBL);
