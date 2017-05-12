use strict;
use warnings;

use Test::More tests => 15;
use CracTools::GenomeMask;
use CracTools::SAMReader;

use File::Temp 0.23;
use Inline::Files 0.68;  

my $g_mask = CracTools::GenomeMask->new(genome => {chr1 => 10, chr2 => 20});

is($g_mask->getChrLength("chr1"),10);
$g_mask->setRegion("chr1",2,5);

is($g_mask->getPos("chr1",1),0);
is($g_mask->getPos("chr1",2),1);
is($g_mask->getPos("chr1",3),1);
is($g_mask->getPos("chr1",5),1);
is($g_mask->getPos("chr1",6),0);

is($g_mask->getNbBitsSetInRegion("chr1",3,6), 3);

$g_mask->setPos("chr2",4);
$g_mask->setPos("chr2",8);

my @pos_set = @{$g_mask->getPosSetInRegion("chr2",2,10)};
is($pos_set[0],4);
is($pos_set[1],8);

is($g_mask->rank("chr2",5),5);
my ($chr,$pos) = $g_mask->select(7);
is($chr,"chr2");
is($pos,8);
is($g_mask->rank("chr2",8),6);

my $sam_file = new File::Temp( SUFFIX => '.sam', UNLINK => 1);
while(<SAM>) {print $sam_file $_;}
close $sam_file;
$g_mask = CracTools::GenomeMask->new(sam_reader => CracTools::SAMReader->new($sam_file));
is($g_mask->getChrLength("2"),2421,"sam_reader constructor");

my $conf_file = new File::Temp( SUFFIX => '.conf', UNLINK => 1);
while(<CRACCONF>) {print $conf_file $_;}
close $conf_file;
$g_mask = CracTools::GenomeMask->new(crac_index_conf => $conf_file);
is($g_mask->getChrLength("2"),2421,"crac_index_conf constructor");

__SAM__
@HD	VN:1.5	SO:coordinate
@RG	ID:1	DT:2015-07-13T16:06:12
@PG	ID:1	PN:crac	VN:2.0.0	CL:crac -k 22 --bam -o - --stranded -r reads/ENCSR109IQO_rep1_1.fastq.gz -i /data/indexes/crac/GRCh38 --nb-threads 15 reads/ENCSR109IQO_rep1_2.fastq.gz
@SQ	SN:1	LN:2489
@SQ	SN:2	LN:2421
@SQ	SN:3	LN:1982
@SQ	SN:4	LN:1902
@SQ	SN:5	LN:1815
@SQ	SN:6	LN:1708
@SQ	SN:7	LN:1593
@SQ	SN:8	LN:1451
@SQ	SN:9	LN:1383
@SQ	SN:10	LN:1337
@SQ	SN:11	LN:1350
@SQ	SN:12	LN:1332
@SQ	SN:13	LN:1143
@SQ	SN:14	LN:1070
@SQ	SN:15	LN:1019
@SQ	SN:16	LN:9033
@SQ	SN:17	LN:8325
@SQ	SN:18	LN:8037
@SQ	SN:19	LN:5861
@SQ	SN:20	LN:6444
@SQ	SN:21	LN:4670
@SQ	SN:22	LN:5081
@SQ	SN:X	LN:1560
@SQ	SN:Y	LN:5722
__CRACCONF__
24
1
2489
2
2421
3
1982
4
1902
5
1815
6
1708
7
1593
8
1451
9
1383
10
1337
11
1350
12
1332
13
1143
14
1070
15
1019
16
9033
17
8325
18
8037
19
5861
20
6444
21
4670
22
5081
X
1560
Y
5722
