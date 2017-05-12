#!perl

# $Id: KDB_pm.PL,v 1.2 2002/04/19 18:42:59 steiner Exp $

my $Usage = "Usage: $0 <path for kdb5_util> [ <target> ]\n";
my $kdb_in = "KDB.in";
my $kdb_out = "KDB.pm";

my $path = shift;
if ($path !~ /^KDB5_UTIL_PATH=(.*)$/) {
    die "Missing KDB5_UTIL_PATH argument\n$Usage";
} else {
    $path = $1;
}
if (not $path) { die "Missing KDB5_UTIL_PATH argument\n$Usage"; }
if ($path =~ m|/kdb5_util$|) { die "Don't include program in KDB5_UTIL_PATH\n$Usage"; }

$kdb_out = shift  if (@ARGV);	# newer MakeMaker's will add target to ARGV

open(IN, "<$kdb_in") or die "$0: Can't open $kdb_in: !$\n";
open(OUT, ">$kdb_out") or die "$0: Can't open $kdb_out: !$\n";

print OUT <<"EOH";
#
# This file is auto-generated. ***ANY*** changes here will be lost
# This file is generated from $kdb_in by $0.
#

EOH

while (<IN>) {

    # fix up path
    s/%%K_SBIN_PATH%%/$path/g;

    # remove comments only meant for KDB.in
    s/^#%%.*\n$//;

    print OUT $_;
}

close OUT;
close IN;
