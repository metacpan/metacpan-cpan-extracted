use strict;
use Test::More qw(no_plan);

my $outdir = 't/test-data/out';
mkdir $outdir unless (-d $outdir);
`rm -f $outdir/*`;

`perl -w bin/alvisXMLsplit t/test-data/to-split/29.xml 3 $outdir`;

ok (-e $outdir.'/1.xml');
ok (-e $outdir.'/2.xml');
ok (-e $outdir.'/3.xml');
ok (-e $outdir.'/4.xml');
ok (-e $outdir.'/5.xml');
ok (-e $outdir.'/6.xml');
ok (not -e $outdir.'/7.xml');

`rm -rf $outdir`;
