#renoves quotes from a db to tab file

my $inFile = '1980_1984_window1_retest_data.txt';
my $outFile = '1980_1984_window1_restest_DELETEME';


open IN, $inFile or die ("unable to open inFile: $inFile\n");
open OUT, '>'.$outFile or die ("unable to open outFile: $outFile\n");

while (my $line  = <IN>) {
    $line =~ s/"//g;
    #print $line;
    print OUT $line;
}
close IN;
close OUT;
