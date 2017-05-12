#! /usr/bin/perl
#

use strict;
use warnings;

use Test::More tests => 65;
use CracTools::SAMReader::SAMline;

my $test_line = "HWI-ST225:407:C0KV8ACXX:1:1101:2576:2209\t161\t17\t41594644\t254\t45M2807N56M\t17\t41597762\t0\tCGGAAATCCAGAGAACCAACTTAGCAAGCACAGTGCTGTCACTCAAGGCCATGGGTATCAATGATCTGCTGTCCTTTGATTTCATGGATGCCCCACCTATG\t".'@B@FDFDFGHDHDBEE=EBFGGIJCHIEGGIIH9CFGHGIJECG>BDGGFD8DHG)=FHGGGCGIIIEGHDCCEEHED7;?@ECCEA;3>ACDDB?BBAAC'."\tXU:i:1\tXD:i:0\tXM:i:0\tXN:i:0\tXO:Z:17|1,41597512\tXQ:i:62\tXC:i:1\tXE:Z:0:0:Junction:normal:44:17|1,41594690:2807\tXR:Z:p_support=1,1233,1244,1250,1251,1232,1223,1234,1165,1166,1145,1052,1031,1131,1158,1156,1133,1115,1138,1169,1154,1152,1073,1072,945,1115,1044,1032,1019,958,924;p_loc=0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1\tXP:Z:chimera:1|-1,26607676:1|1,26606650\tXP:Z:loc:1:1:0\tSA:Z:X,989,+,5S6M,30,1;3,45,-,34M1X2S;\tNH:i:2";

# Testing static methods
ok(CracTools::SAMReader::SAMline::hasEvent($test_line,'junction'),'hasEvent (1)');
ok(!CracTools::SAMReader::SAMline::hasEvent($test_line,'chimera'),'hasEvent (2)');

my $sam_line = CracTools::SAMReader::SAMline->new($test_line);

ok($sam_line->isFlagged(128),"isFlagged()");
ok(!$sam_line->isFlagged(64),"isFlagged()");
ok($sam_line->isFlagged($CracTools::SAMReader::SAMline::flags{MULTIPLE_SEGMENTS}),"isFlagged()");

# Testing getters
ok($sam_line->line eq $test_line, "line()");
ok($sam_line->qname eq 'HWI-ST225:407:C0KV8ACXX:1:1101:2576:2209',"qname");
ok($sam_line->flag eq '161',"flag");
ok($sam_line->rname eq '17',"rname");
ok($sam_line->chr eq '17',"chr");
ok($sam_line->pos eq '41594644',"pos");
ok($sam_line->mapq eq '254',"mapq");
ok($sam_line->cigar eq '45M2807N56M',"cigar");
ok($sam_line->rnext eq '17',"rnext");
ok($sam_line->pnext eq '41597762',"pnext");
ok($sam_line->tlen eq '0',"tlen");
ok($sam_line->seq eq 'CGGAAATCCAGAGAACCAACTTAGCAAGCACAGTGCTGTCACTCAAGGCCATGGGTATCAATGATCTGCTGTCCTTTGATTTCATGGATGCCCCACCTATG',"seq");
ok($sam_line->qual eq '@B@FDFDFGHDHDBEE=EBFGGIJCHIEGGIIH9CFGHGIJECG>BDGGFD8DHG)=FHGGGCGIIIEGHDCCEEHED7;?@ECCEA;3>ACDDB?BBAAC',"qual");
is($sam_line->getOptionalField("NH"),2,'getOptionalField()');

$sam_line->genericInfo("foo","bar");
ok($sam_line->genericInfo("foo") eq "bar","genericInfo()");
ok($sam_line->isClassified('unique'),"isClassified");
ok(!$sam_line->isClassified('multiple'),"isClassified");

# Testing events
# TODO test each types of events
my @junctions = @{$sam_line->events('Junction')};
ok(@junctions == 1, "events()");
ok($junctions[0]->{type} eq 'normal', "events()");
ok($junctions[0]->{pos} == 44, "events()");
my ($chr,$pos,$strand) = @{$junctions[0]->{loc}}{'chr','pos','strand'};
ok($junctions[0]->{loc}{chr} eq '17', "events()");
ok($junctions[0]->{loc}{pos} eq '41594690', "events()");
ok($junctions[0]->{loc}{strand} eq '1', "events()");
ok($junctions[0]->{gap} == 2807, "events()");
$sam_line->updateEvent($junctions[0],'Junction',(type => 'toto',
                           pos => '1',
                           loc => {chr => 'X', pos => '12', strand => -1},
                           gap => 20)); 
ok($sam_line->updatedLine =~ 'XE:Z:0:0:Junction:toto:1:X|-1,12:20','updateEvent'); 
@junctions = @{$sam_line->events('Junction')};
$sam_line->removeEvent($junctions[0]);
is(@{$sam_line->events('Junction')},0,'removeEvent');

# Testing Sam detailed fields
is($sam_line->pSupport,'1,1233,1244,1250,1251,1232,1223,1234,1165,1166,1145,1052,1031,1131,1158,1156,1133,1115,1138,1169,1154,1152,1073,1072,945,1115,1044,1032,1019,958,924','pSupport');
is($sam_line->pLoc,'0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1','pLoc');

# Testing paired fields (XP:Z:...)
my($chr1,$pos1,$strand1,$chr2,$pos2,$strand2) = $sam_line->pairedChimera();
#1|-1,26607676:1|1,26606650
is($chr1,"1",'pairedChimera(1)');
is($pos1,26607676,'pairedChimera(2)');
is($strand1,-1,'pairedChimera(3)');
is($chr2,"1",'pairedChimera(4)');
is($pos2,26606650,'pairedChimera(4)');
is($strand2,1,'pairedChimera(6)');
is($sam_line->isPairedClassified('unique'),1);
is($sam_line->isPairedClassified('duplicated'),1);
is($sam_line->isPairedClassified('multiple'),0);

#Testing chimeric alignments
my @alignements = @{ $sam_line->getChimericAlignments()};
my $nb_alignements = scalar @alignements;
is($nb_alignements,2,'chimericAlignements(1)');
for (my $i=0 ; $i < $nb_alignements ; $i++){
    my %hash = %{ $alignements[$i] };
    if ($i == 0){
	is($hash{chr},"X",'chimericAlignements(2)');
	is($hash{pos},989,'chimericAlignements(3)');
	is($hash{strand},1,'chimericAlignements(4)');
	is($hash{cigar},"5S6M",'chimericAlignements(5)');
	is($hash{mapq},30,'chimericAlignements(6)');
	is($hash{edist},1,'chimericAlignements(7)');
    }
}

# Testing cigar operations
# Cigar is : 45M2807N56M
my %ops_count = %{$sam_line->getCigarOperatorsCount()};
is(keys %ops_count, 2, 'getCigarOperatorsCount(1)');
is($ops_count{M}, 101, 'getCigarOperatorsCount(2)');
is($ops_count{N}, 2807, 'getCigarOperatorsCount(3)');

# Testing setters
$sam_line->qname('toto');
is($sam_line->qname,'toto',"set qname");
$sam_line->flag(21);
is($sam_line->flag,21,"set flag");
$sam_line->rname('X');
is($sam_line->rname,'X',"set rname");
$sam_line->chr('Y');
is($sam_line->chr('Y'),'Y', "set chr");
$sam_line->pos(12);
is($sam_line->pos, 12,"set pos");
$sam_line->mapq(12);
is($sam_line->mapq, 12,"set mapq");
$sam_line->cigar('12M');
is($sam_line->cigar,'12M',"set cigar");
$sam_line->rnext('X');
is($sam_line->rnext,'X',"set rnext");
$sam_line->pnext(34);
is($sam_line->pnext,34,"set pnext");
$sam_line->tlen(12);
is($sam_line->tlen,12,"set tlen");
$sam_line->seq('ATGC');
is($sam_line->seq,'ATGC',"set seq");
$sam_line->qual('BBBB');
is($sam_line->qual,'BBBB',"qual");

# Testing "chr" prefix removal function
$test_line = "chr_line\t0\tchr3\t1\t254\t10M\t*\t*\t0\tCGGAAATCCA\tDFDFGHDHDBE";
$sam_line = CracTools::SAMReader::SAMline->new($test_line);
is($sam_line->rname,3,"chr prefix removal");
