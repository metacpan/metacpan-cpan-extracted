#! /usr/bin/perl
#
use strict;
use warnings;

use Test::More tests => 25;
use CracTools::Interval::Query::File;
use File::Temp 0.23;
use Inline::Files 0.68;

my $gff_line = "1\tEnsembl\texon\t1\t10\t.\t+\t0\n";
my $sam_line = "HWI-ST170:310:8:1101:1477-2249/2\t161\t12\t49333532\t254\t30M217N35M\t12\t49334794\t0\tCGATCATTGCTGTCGACCACAAATATCAACCCTTGGGTGTTCTGGAAGTAGTGTCTCCAGAGGGG\t__[ceccececggfhhfhf^ggagghhiifhifhhf^^eeeeefdfhcf`aabfcddgggf^";
my $short_bed_line = "chr22\t1000\t5000";
my $bed_line = "chr22\t1000\t5000\tcloneA\t960\t+\t1000\t5000\t0\t2\t567,488,\t0,3512";

my $interval = CracTools::Interval::Query::File::_getIntervalsFromGFFLine($gff_line);


is($interval->[0]{low},1);
is($interval->[0]{high},10);

$interval = CracTools::Interval::Query::File::_getIntervalsFromSAMLine($sam_line);
is($interval->[0]{low},49333532);
is($interval->[0]{high},49333562);
is($interval->[1]{low},49333779);
is($interval->[1]{high},49333814);

$interval = CracTools::Interval::Query::File::_getIntervalsFromBEDLine($short_bed_line);
is($interval->[0]{low},1001);
is($interval->[0]{high},5000);

$interval = CracTools::Interval::Query::File::_getIntervalsFromBEDLine($bed_line);
is($interval->[0]{low},1001);
is($interval->[0]{high},1567);
is($interval->[1]{low},4513);
is($interval->[1]{high},5000);

# Create a temp file with the SAM lines described above
my $gff_file = new File::Temp( SUFFIX => '.gff', UNLINK => 1);
while(<GFF>) {print $gff_file $_;}
close $gff_file;

my $intervalQuery = CracTools::Interval::Query::File->new(file => $gff_file,
                                               type => 'gff',
                                             );

is(@{$intervalQuery->fetchByLocation(1,3,1)}, 3, 'fetchByLocation (1)');
is(@{$intervalQuery->fetchByLocation(1,3,'-1')}, 0, 'fetchByLocation (2)');
is(@{$intervalQuery->fetchByLocation(1,4,'1')}, 2, 'fetchByLocation (3)');
ok($intervalQuery->fetchByLocation(1,10,'1')->[0] =~ /line1/, 'fetchByLocation (4)');
is($intervalQuery->fetchByRegion(1,3,3,1)->[0],$intervalQuery->fetchByLocation(1,3,1)->[0],'fetchByRegion');
is(@{$intervalQuery->fetchAllNearestDown(2,9,1)},2,'fetchAllNearestDown (1)');
is(@{$intervalQuery->fetchAllNearestDown(1,4,1)},1,'fetchAllNearestDown (2)');
ok($intervalQuery->fetchAllNearestDown(1,4,1)->[0] =~ /line2/,'fetchAllNearestDown (3)');
is(@{$intervalQuery->fetchAllNearestUp(2,2,1)},2,'fetchAllNearestUp (1)');
ok($intervalQuery->fetchAllNearestUp(1,2,1)->[0] =~ /line3/,'fetchAllNearestUp (2)');
ok($intervalQuery->fetchAllNearestDown(2,120,-1)->[0] =~ /line7/,'fetchAllNearestDown (3)');
ok($intervalQuery->fetchAllNearestUp(2,20,-1)->[0] =~ /line7/,'fetchAllNearestUp (3)');

# Testing "chr" prefix removal function
ok($intervalQuery->fetchByLocation(3,1,1)->[0] =~ /line8/,'chr prefix removal');

__GFF__
1	line1	exon	1	10	.	+	0
1	line2	exon	2	3	.	+	0
1	line3	exon	3	9	.	+	0
1	line4	exon	1	2	.	-	0
2	line5	exon	4	8	.	+	0
2	line5	exon	5	10	.	+	0
2	line6	gene	4	8	.	+	0
2	line7	gene	34	48	.	-	0
chr3	line8	gene	1	10	.	+	0
