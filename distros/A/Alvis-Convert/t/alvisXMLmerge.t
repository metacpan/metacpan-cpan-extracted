use strict;
use Test::More qw(no_plan);

my $outdir = 't/test-data/out';
mkdir $outdir unless (-d $outdir);
`rm -rf $outdir/*`;

`perl -w bin/alvisXMLmerge -e t/test-data/extra/ -o $outdir -c bin/merger.config t/test-data/original/`;

ok (-e $outdir.'/0/101.alvis');
ok (-e $outdir.'/0/0.alvis');
ok (-e $outdir.'/1/1000.alvis');

`rm -rf $outdir/*`;

 

`perl -w bin/alvisXMLmerge -extra-file t/test-data/extra-all.xml -o $outdir -c bin/merger.config t/test-data/original/`;
ok (-e $outdir.'/0/101.alvis');
ok (-e $outdir.'/0/0.alvis');
ok (-e $outdir.'/1/1000.alvis');

open(FP, $outdir.'/0/101.alvis') or die $!;
while(defined(my $str = <FP>)) {
	chomp $str;
	if ($str =~ /<\/acquisition>/) {
		$str = <FP>; ok ($str =~ /\s*<relevance>/);
		$str = <FP>; ok ($str =~ /\s*<scoreset type="sa50">/);
		$str = <FP>; ok ($str =~ /\s*<score topicId="Untitled_1">2.953086<\/score>/);
		$str = <FP>; ok ($str =~ /\s*<score topicId="E-mail spam">21.113569<\/score>/);
		$str = <FP>; ok ($str =~ /\s*<\/scoreset>/);
		$str = <FP>; ok ($str =~ /\s*<\/relevance>/);
	}
}
close FP;

`rm -rf $outdir`;
