#!usr/bin/perl

#This test tests that an output file is created.  The other tests check more specific conversion data.

use FindBin qw($Bin);

use feature "say";
use Test::Simple tests => 2;
use Path::Tiny;

path("$Bin/Corpus/Output.test")->remove;

my $utx2tbx = path("$Bin/../bin/utx2tbx");
my $tbx2utx = path("$Bin/../bin/tbx2utx");
my $utx_datafile = path("$Bin/Corpus/Sample.utx");
my $tbx_datafile = path("$Bin/Corpus/Sample.tbx");

my $outfile = path("$Bin/Corpus", "Output.test");

system(qq{"$^X" -Ilib "$utx2tbx" "$utx_datafile" "$outfile"});
ok( path("$Bin/Corpus/Output.test")->exists, "TBX Output" );
path("$Bin/Corpus/Output.test")->remove;


system(qq{"$^X" -Ilib "$tbx2utx" "$tbx_datafile" "$outfile"});
ok( path("$Bin/Corpus/Output.test")->exists, "UTX Output" );
path("$Bin/Corpus/Output.test")->remove;