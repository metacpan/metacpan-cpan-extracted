#!/install/perl/live/bin/perl -w
#
# This program creates a file containing all 256 byte values
# in ascending order.
# 1) set tblpath to were the file transferred from your EBCDIC system
# 2) Run this on the ASCII based system
# You now have a file containing the translation table
#
use integer;

my $tblpath = 'tbl';

open(CTBL, "<$tblpath") || die "opening $tblpath\n";
$/ = '';
my @e2a_tbl = unpack("C256", <CTBL>);
my @a2e_tbl = ();
my $nul_str = "";
my $a2e_str = "";
my $e2a_str = "";
close(CTBL);
foreach $i ( 0 .. 255 ) {
    $nul_str .= sprintf("\\%03o", $i);
    $nul_str .= "\\\n" if ($i % 16) == 15;
    $e2a_str .= sprintf("\\%03o", $e2a_tbl[$i]);
    $e2a_str .= "\\\n" if ($i % 16) == 15;
    $a2e_tbl[$e2a_tbl[$i]] = $i;
}
foreach $i ( 0 .. 255 ) {
    $a2e_str .= sprintf("\\%03o", $a2e_tbl[$i]);
    $a2e_str .= "\\\n" if ($i % 16) == 15;
}
print "NULL translation\n";
print $nul_str, "\n";
print "EBCDIC to ASCII\n";
print $e2a_str, "\n";
print "ASCII to EBCDIC\n";
print $a2e_str, "\n";
