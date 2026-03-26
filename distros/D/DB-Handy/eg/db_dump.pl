######################################################################
# db_dump.pl - Educational tool to inspect DB::Handy .dat files
#
# Usage: perl db_dump.pl <schema_file> <dat_file>
######################################################################
use strict;
BEGIN { if ($] < 5.006) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";

my $sch_file = $ARGV[0];
my $dat_file = $ARGV[1];

if (!defined($sch_file) || !defined($dat_file)) {
    print "Usage: perl db_dump.pl <table.sch> <table.dat>\n";
    exit(1);
}

# 1. Read schema to find recsize
local *SCH;
open(SCH, "< $sch_file") or die("Cannot open schema $sch_file: $!\n");
my $recsize = 0;
while (my $line = <SCH>) {
    $line =~ s/\r?\n$//;
    if ($line =~ /^recsize=(\d+)$/) {
        $recsize = $1;
        last;
    }
}
close SCH;

if ($recsize == 0) {
    die("Could not find recsize in $sch_file\n");
}

print "Record Size: $recsize bytes\n";
print "-" x 50, "\n";

# 2. Read and dump .dat file
local *DAT;
open(DAT, "< $dat_file") or die("Cannot open data $dat_file: $!\n");
binmode DAT;

my $recno = 0;
while (1) {
    my $buf = '';
    my $n   = read(DAT, $buf, $recsize);
    last unless defined($n) && ($n == $recsize);

    # 1st byte: Active (0x01) or Deleted (0x00)
    my $flag   = ord(substr($buf, 0, 1));
    my $status = ($flag == 1) ? 'ACTIVE ' : (($flag == 0) ? 'DELETED' : 'UNKNOWN');

    printf("Rec %04d [%s] : ", $recno, $status);

    # Print first 16 bytes of data as Hex
    my $limit = ($recsize > 17) ? 17 : $recsize;
    for my $i (1 .. $limit - 1) {
        printf("%02X ", ord(substr($buf, $i, 1)));
    }
    print "...\n" if $recsize > 17;
    print "\n"    if $recsize <= 17;

    $recno++;
}
close DAT;
print "-" x 50, "\n";
print "Total $recno records processed.\n";
