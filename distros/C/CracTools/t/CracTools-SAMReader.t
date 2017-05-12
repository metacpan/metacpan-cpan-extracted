#! /usr/bin/perl
#
use Test::More tests => 7;
use CracTools::SAMReader;
use File::Temp;

my $sam = "\@HD\tVN:1.5\tSO:coordinate\n".
          "\@SQ\tSN:ref\tLN:45\n".
          "\@PG\tID:crac\tPN:crac\tVN:1.3.1\tCL:/data/projects/crac-dev/src/crac -k 20 --max-extension-length 2 --max-splice-length 1000 --detailed-sam --gz --sam K46_normal_BM_n25.sam --chimera K46_normal_BM_n25.chimera --nb-threads 20 --paired-end-chimera K46_normal_BM_n25.paired_chimera --stringent-chimera --no-ambiguity -i /data/indexes/crac/GRCh37 -r ../raw_renamed_filtered/K46_normal_BM_n25_1.fastq.gz --summary K46_normal_BM_n25.summary ../raw_renamed_filtered/K46_normal_BM_n25_2.fastq.gz\n".
          "r001\t163\tref\t7\t30\t8M2I4M1D3M\t=\t37\t39\tTTAGATAAAGGATACTG\t*\n".
          "r002\t0\tref\t9\t30\t3S6M1P1I4M\t*\t0\t0\tAAAAGATAAGGATA\t*\n".
          "r003\t0\tref\t9\t30\t5S6M\t*\t0\t0\tGCCTAAGCTAA\t*\tSA:Z:ref,29,-,6H5M,17,0;\n".
          "r004\t0\tref\t16\t30\t6M14N5M\t*\t0\t0\tATAGCTTCAGC\t*\n".
          "r003\t2064\tref\t29\t17\t6H5M\t*\t0\t0\tTAGGC\t*\tSA:Z:ref,9,+,5S6M,30,1;\n".
          "r001\t83\tref\t37\t30\t9M\t=\t7\t-39\tCAGCGGCAT\t*\tNM:i:1\n";

# Create a temp file with the SAM lines described above
my $sam_file = new File::Temp( SUFFIX => '.sam', UNLINK => 1);
print $sam_file $sam;
close $sam_file;

my $sam_reader = CracTools::SAMReader->new($sam_file);
my $it = $sam_reader->iterator();
my $first_align = $it->();
isa_ok($first_align, 'CracTools::SAMReader::SAMline');

ok($first_align->seq eq 'TTAGATAAAGGATACTG', 'Current read is the one we expect');

my $nb_alignements = 1;
while(my $align = $it->()) {
  $nb_alignements++;
}
ok($nb_alignements == 6, 'Every lines are readed');
is($sam_reader->getCracArgumentValue('max-extension-length'),2,'getCracArgumentValue (1)');
is($sam_reader->getCracArgumentValue('max-splice-length'),1000,'getCracArgumentValue (2)');
is($sam_reader->getCracVersionNumber(),'1.3.1','getCracVersionNumber');
is($sam_reader->refSeqLength("ref"),45);
