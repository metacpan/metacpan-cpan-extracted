use Test::More qw(no_plan);

my $outdir = 't/test-data/out';
mkdir $outdir unless (-d $outdir);
my $out_file = "$outdir/tmp"; 

my $output = `perl -w bin/alvisXSL --xsl t/test-data/alvisXSL/alvis2titles.xsl t/test-data/original/0/101.alvis > $out_file`;

ok (-e $out_file);
open(FP, $out_file) or die $!;
my $str = <FP>;
chomp $str;
ok ($str =~ /D http:\/\/battellemedia.com\/archives\/2004_08.php 0717FBB236A4A067DC9BE4FA48801BE3/ ); 
ok ($str =~ /John Battelle's Searchblog/ );
close FP;


`rm -rf $outdir`;
