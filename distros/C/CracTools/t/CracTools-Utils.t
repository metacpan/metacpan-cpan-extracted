use strict;
use warnings;

use Test::More tests => 95;
use CracTools::Utils;
use Inline::Files 0.68;
use File::Temp;
use Data::Dumper;

is(CracTools::Utils::reverseComplement("ATGCAG"), "CTGCAT", 'reverseComplement()');
is(CracTools::Utils::reverse_tab("1,2,0,1"), "1,0,2,1", 'reverse_tab()');

is(CracTools::Utils::convertStrand(1),'+');
is(CracTools::Utils::convertStrand(-1),'-');
is(CracTools::Utils::convertStrand('+'),1);
is(CracTools::Utils::convertStrand('-'),-1);

# __FASTQ__ => seqFileIterator($file,'fastq')
{
  # Create a temp file with the FASTQ lines described below
  my $fastq_file = new File::Temp( SUFFIX => '.fastq', UNLINK => 1);
  while(<FASTQ>) {print $fastq_file $_;}
  close $fastq_file;
  my $fastq_it = CracTools::Utils::seqFileIterator($fastq_file);
  my $entry = $fastq_it->();
  is($entry->{name},'HWI-EAS209_0006_FC706VJ:5:58:5894:21141#ATCACG/1');
  is($entry->{seq},'TTAATTGGTAAATAAATCTCCTAATAGCTTAGATNTTACCTTNNNNNNNNNNTAGTTTCTTGAGATTTGTTGGGGGAGACATTTTTGTGATTGCCTTGAT');
  is($entry->{qual},'efcfffffcfeefffcffffffddf`feed]`]_Ba_^__[YBBBBBBBBBBRTT\]][]dddd`ddd^dddadd^BBBBBBBBBBBBBBBBBBBBBBBB');
  $entry = $fastq_it->();
  is($entry->{name},'SRR1107833.1 DHCDZDN1:5:1101:1102:1069 length=101');
  is($entry->{seq},'GTGGGGAAGGATCGCAGGCGAGATTACGAGGCGAGGCTCGCGCGCCCGCCCCCGCCCTGGCCCCCAGTGCCCACCCGGTCGGCCCGGCACAGCCATGATCA');
  is($entry->{qual},'@@CFFFDAHHDHHGGBEEAFGGHHIJCD?DG6FG<ADDE;8\'2,59505<57950795A?88A;;08>C::A><>>59)50935<509<B??1?BA:>>3:');
  $entry = $fastq_it->();
  is($entry,undef);
}

# __FASTA__ => seqFileIterator($file,'fasta')
{
  # Create a temp file with the FASTA lines described below
  my $fasta_file = new File::Temp( SUFFIX => '.fasta', UNLINK => 1);
  while(<FASTA>) {print $fasta_file $_;}
  close $fasta_file;

  my $fasta_it = CracTools::Utils::seqFileIterator($fasta_file);
  my $entry = $fasta_it->();
  is($entry->{name},"HSBGPG");
  is($entry->{seq},"GGCAGATTCCCCCTAGACCCGCCCGCACCATGGTCAGGCATGCCCCTCCTCATCGCTGGGCACAGCCCAGAGGGT");
  is($entry->{qual},undef);
  $entry = $fasta_it->();
  is($entry->{name},"HSGLTH1");
  is($entry->{seq},"CTTCTTGCCGTGCTCTCTCGAGGTCAGGACGCGAGAGGAAGGCGC");
  is($entry->{qual},undef);
  $entry = $fasta_it->();
  is($entry->{name},"HDJEJA");
  is($entry->{seq},"ATGAGAGCCCTCACACTCCTCGCCCTATTGGCCCTGGCCGCACTTTGCATCGCTGGCCAGGCAGGTGAGTGCCCC");
  is($entry->{qual},undef);
  $entry = $fasta_it->();
  is($entry,undef);
}

# __FASTALONG__ => seqFileIterator(file,'fasta')
{
  # Create a temp file with the FASTA lines described below
  my $fasta_file = new File::Temp( SUFFIX => '.fasta', UNLINK => 1);
  while(<FASTALONG>) {print $fasta_file $_;}
  close $fasta_file;

  my $fasta_it = CracTools::Utils::seqFileIterator($fasta_file);
  my $entry = $fasta_it->();
  is($entry->{name},"HSBGPG Human gene for bone gla protein (BGP)");
  is($entry->{seq},"GGCAGATTCCCCCTAGACCATAAACAGTGCTGGAGGCTCTCCAGGCACCCTTCTTTCATCCCAGCTGC");
  is($entry->{qual},undef);
  $entry = $fasta_it->();
  is($entry->{name},"HSGLTH1 Human theta 1-globin gene");
  is($entry->{seq},"CCACTGCACTCACCGCACCCGCGGGGGGCCTTGGATCCAGGGCTTCTTGCCGT");
  is($entry->{qual},undef);
  $entry = $fasta_it->();
  is($entry,undef);
}

# __FASTQ_{1,2}__ => pairedEndSeqFileIterator
{
  my $fastq_file_1 = new File::Temp( SUFFIX => '.fastq', UNLINK => 1);
  while(<FASTQ_1>) {print $fastq_file_1 $_;}
  close $fastq_file_1;
  my $fastq_file_2 = new File::Temp( SUFFIX => '.fastq', UNLINK => 1);
  while(<FASTQ_2>) {print $fastq_file_2 $_;}
  close $fastq_file_2;

  my $paired_end_it = CracTools::Utils::pairedEndSeqFileIterator($fastq_file_1,$fastq_file_2);
  my $entry = $paired_end_it->();
  is($entry->{read1}->{name},"PAN_0059_FC62WP0AAXX:1:1:1107:937#0/1");
  is($entry->{read2}->{name},"PAN_0059_FC62WP0AAXX:1:1:1107:937#0/2");
  is($entry->{read1}->{seq},"GCAGGCGTCCACGGAGTCCAGGCGGGCCGGCAGCTCACGGCCGGCACCCGGGTGCTGGCTGATCACCTCCGCCGC");
  is($entry->{read2}->{seq},"AGGTGGCTGTGCAAATAACTGATGTGGCCAGCTTCGTGCCCAGGGACGGGGTGCTGGACGGGGAGGCGCGCAGGCA");
  is($entry->{read1}->{qual},"BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB");
  is($entry->{read2}->{qual},'d_b[e]cfcccaaLacJZ\daede`ffcSaYaac^aaKKLdScaRf_^f_^J_ZdX`BBBBBBBBBBBBBBBBBBB');
  $entry = $paired_end_it->();
  is($entry->{read1}->{name},"PAN_0059_FC62WP0AAXX:1:1:1350:944#0/1");
  is($entry->{read2}->{name},"PAN_0059_FC62WP0AAXX:1:1:1350:944#0/2");
  is($entry->{read1}->{seq},"GGAGATTGAGAAGAGGAAGCAAGGGTAGCCAAATGTGATTCAGTTAATGCGAGAGGTGCTTGTGCATTTTTAGAG");
  is($entry->{read2}->{seq},"TGCTTGTAGAATATGACTTACCAGCACTCCTGGACCAAGAGCTCTTTGAGTTACTTTTTAATTGGTCCATGTCTCT");
  is($entry->{read1}->{qual},"KKKIOPQQQ____________W__WXXXWWWWTWVVVSVWWTWW_____YYYYYWWWWWb__bbYYWVY______");
  is($entry->{read2}->{qual},'dhhhhhhhfhhahchhhhcfgghhhhhfhhfa_afhhhhaghhghhaffhhffhhf]fdfhhhhgafhdfhhhhhg');
}

# __GFF3__ => gffFileIterator
{
  my $gff_file = new File::Temp( SUFFIX => '.gff', UNLINK => 1);
  while(<GFF3>) {print $gff_file $_;}
  close $gff_file;

  my $gff_it = CracTools::Utils::gffFileIterator($gff_file,'gff3');
  my $annot = $gff_it->();
  is($annot->{chr},"HSCHR6_MHC_MANN");
  is($annot->{source},"Ensembl_CORE");
  is($annot->{start},30051790);
  is($annot->{end},30051922);
  is($annot->{strand},'-');
  is($annot->{frame},'.');
  is($annot->{attributes}->{ID},"ENSG00000266142");
  is($annot->{attributes}->{Name},"CT009552.1");
  is($annot->{attributes}->{transcripts_nb},1);
  is($annot->{attributes}->{exons_nb},1);
}

# __BED__ => bedFileIterator
{

  my $bed_file = new File::Temp( SUFFIX => '.bed', UNLINK => 1);
  while(<BED>) {print $bed_file $_;}
  close $bed_file;

  my $bed_it = CracTools::Utils::bedFileIterator($bed_file);
  my $annot = $bed_it->();
  is($annot->{chr},"chr22");
  is($annot->{start},1000);
  is($annot->{end},5000);
  is($annot->{blocks}[0]->{size},567);
  is($annot->{blocks}[0]->{start},0);
  is($annot->{blocks}[0]->{end},567);
  is($annot->{blocks}[0]->{ref_start},1000);
  is($annot->{blocks}[0]->{ref_end},1567);
  is($annot->{blocks}[1]->{size},488);
  is($annot->{blocks}[1]->{start},3512);
  is($annot->{blocks}[1]->{end},4000);
  is($annot->{blocks}[1]->{ref_start},4512);
  is($annot->{blocks}[1]->{ref_end},5000);
  is($annot->{seek_pos},0);
}

# __VCF__ => vcfFileIterator
{

  my $vcf_file = new File::Temp( SUFFIX => '.vcf', UNLINK => 1);
  while(<VCF>) {print $vcf_file $_;}
  close $vcf_file;

  my $vcf_it = CracTools::Utils::vcfFileIterator($vcf_file);
  my $mutation = $vcf_it->();
  is($mutation->{chr},"20");
  is($mutation->{pos},14370);
  is($mutation->{id},"rs6054257");
  is($mutation->{ref},'G');
  is($mutation->{alt}[0],'A');
  is($mutation->{alt}[1],'C');
  is($mutation->{qual},29);
  is($mutation->{filter},'PASS');
  is($mutation->{info}->{NS},3);
  is($mutation->{info}->{DP},14);
  is($mutation->{info}->{AF},0.5);
}

# parseSAMLineLite
{
  my $sam_line = "HWI-ST225:407:C0KV8ACXX:1:1101:2576:2209\t161\t17\t41594644\t254\t45M2807N56M\t17\t41597762\t0\tCGGAAATCCAGAGAACCAACTTAGCAAGCACAGTGCTGTCACTCAAGGCCATGGGTATCAATGATCTGCTGTCCTTTGATTTCATGGATGCCCCACCTATG\t".'@B@FDFDFGHDHDBEE=EBFGGIJCHIEGGIIH9CFGHGIJECG>BDGGFD8DHG)=FHGGGCGIIIEGHDCCEEHED7;?@ECCEA;3>ACDDB?BBAAC'."\tNH:i:2";
  my $parsed_line =CracTools::Utils::parseSAMLineLite($sam_line);
  #print STDERR Dumper($parsed_line);
}

# parseCigarChain
{
  my $cigar_chain = "12S5M1X2I3M";
  my @cigar = @{CracTools::Utils::parseCigarChain($cigar_chain)};
  is(@cigar, 5);
  is($cigar[0]->{op}, 'S');
  is($cigar[0]->{nb}, 12);
  is($cigar[1]->{op}, 'M');
  is($cigar[1]->{nb},  5);
  is($cigar[2]->{op}, 'X');
  is($cigar[2]->{nb},  1);
  is($cigar[3]->{op}, 'I');
  is($cigar[3]->{nb},  2);
  is($cigar[4]->{op}, 'M');
  is($cigar[4]->{nb},  3);
}

# Encoding in Base64
{
  my $encoded_list = CracTools::Utils::encodePosListToBase64(1,3,5,8,12,32);
  my @decoded_list = CracTools::Utils::decodePosListInBase64($encoded_list);
  is(@decoded_list,6);
  is($decoded_list[0],1);
  is($decoded_list[1],3);
  is($decoded_list[2],5);
  is($decoded_list[3],8);
  is($decoded_list[4],12);
  is($decoded_list[5],32);
}


__FASTQ__
@HWI-EAS209_0006_FC706VJ:5:58:5894:21141#ATCACG/1
TTAATTGGTAAATAAATCTCCTAATAGCTTAGATNTTACCTTNNNNNNNNNNTAGTTTCTTGAGATTTGTTGGGGGAGACATTTTTGTGATTGCCTTGAT
+HWI-EAS209_0006_FC706VJ:5:58:5894:21141#ATCACG/1
efcfffffcfeefffcffffffddf`feed]`]_Ba_^__[YBBBBBBBBBBRTT\]][]dddd`ddd^dddadd^BBBBBBBBBBBBBBBBBBBBBBBB
@SRR1107833.1 DHCDZDN1:5:1101:1102:1069 length=101
GTGGGGAAGGATCGCAGGCGAGATTACGAGGCGAGGCTCGCGCGCCCGCCCCCGCCCTGGCCCCCAGTGCCCACCCGGTCGGCCCGGCACAGCCATGATCA
+SRR1107833.1 DHCDZDN1:5:1101:1102:1069 length=101
@@CFFFDAHHDHHGGBEEAFGGHHIJCD?DG6FG<ADDE;8'2,59505<57950795A?88A;;08>C::A><>>59)50935<509<B??1?BA:>>3:
__FASTA__
>HSBGPG
GGCAGATTCCCCCTAGACCCGCCCGCACCATGGTCAGGCATGCCCCTCCTCATCGCTGGGCACAGCCCAGAGGGT
>HSGLTH1
CTTCTTGCCGTGCTCTCTCGAGGTCAGGACGCGAGAGGAAGGCGC
>HDJEJA
ATGAGAGCCCTCACACTCCTCGCCCTATTGGCCCTGGCCGCACTTTGCATCGCTGGCCAGGCAGGTGAGTGCCCC
__FASTALONG__
>HSBGPG Human gene for bone gla protein (BGP)
GGCAGATTCCCCCTAGACC
ATAAACAGTGCTGGAGGCT
CTCCAGGCACCCTTCTTTC
ATCCCAGCTGC
>HSGLTH1 Human theta 1-globin gene
CCACTGCACTCACCGCACCCG
CGGGGGGCCTTGGATCCAGGG
CTTCTTGCCGT
__FASTQ_1__
@PAN_0059_FC62WP0AAXX:1:1:1107:937#0/1
GCAGGCGTCCACGGAGTCCAGGCGGGCCGGCAGCTCACGGCCGGCACCCGGGTGCTGGCTGATCACCTCCGCCGC
+
BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
@PAN_0059_FC62WP0AAXX:1:1:1350:944#0/1
GGAGATTGAGAAGAGGAAGCAAGGGTAGCCAAATGTGATTCAGTTAATGCGAGAGGTGCTTGTGCATTTTTAGAG
+
KKKIOPQQQ____________W__WXXXWWWWTWVVVSVWWTWW_____YYYYYWWWWWb__bbYYWVY______
__FASTQ_2__
@PAN_0059_FC62WP0AAXX:1:1:1107:937#0/2
AGGTGGCTGTGCAAATAACTGATGTGGCCAGCTTCGTGCCCAGGGACGGGGTGCTGGACGGGGAGGCGCGCAGGCA
+
d_b[e]cfcccaaLacJZ\daede`ffcSaYaac^aaKKLdScaRf_^f_^J_ZdX`BBBBBBBBBBBBBBBBBBB
@PAN_0059_FC62WP0AAXX:1:1:1350:944#0/2
TGCTTGTAGAATATGACTTACCAGCACTCCTGGACCAAGAGCTCTTTGAGTTACTTTTTAATTGGTCCATGTCTCT
+
dhhhhhhhfhhahchhhhcfgghhhhhfhhfa_afhhhhaghhghhaffhhffhhf]fdfhhhhgafhdfhhhhhg
__GFF3__
##gff-version 3
# The organism is Homo Sapiens
# The API version used is 73
HSCHR6_MHC_MANN	Ensembl_CORE	gene	30051790	30051922	.	-	.	ID=ENSG00000266142;Name=CT009552.1;transcripts_nb=1;exons_nb=1
HSCHR6_MHC_MANN	Ensembl_CORE	mRNA	30051790	30051922	.	-	.	ID=ENST00000578939;Parent=ENSG00000266142;exons_nb=1;type=small_ncRNA:miRNA
HSCHR6_MHC_MANN	Ensembl_CORE	exon	30051790	30051922	.	-	.	ID=ENSE00002706393;Parent=ENST00000578939;exon_rank=1
HSCHR6_MHC_MANN	Ensembl_CORE	gene	30068180	30077657	.	+	.	ID=ENSG00000237050;Name=TRIM31-AS1;transcripts_nb=1;exons_nb=4
HSCHR6_MHC_MANN	Ensembl_CORE	mRNA	30068180	30077657	.	+	.	ID=ENST00000412479;Parent=ENSG00000237050;exons_nb=4;type=other_lncRNA:processed_transcript
HSCHR6_MHC_MANN	Ensembl_CORE	exon	30068180	30068327	.	+	.	ID=ENSE00001672229;Parent=ENST00000412479;exon_rank=1
HSCHR6_MHC_MANN	Ensembl_CORE	exon	30077504	30077657	.	+	.	ID=ENSE00001649832;Parent=ENST00000412479;exon_rank=2
HSCHR6_MHC_MANN	Ensembl_CORE	exon	30070604	30070728	.	+	.	ID=ENSE00001723795;Parent=ENST00000412479;exon_rank=3
HSCHR6_MHC_MANN	Ensembl_CORE	exon	30074651	30074772	.	+	.	ID=ENSE00001734310;Parent=ENST00000412479;exon_rank=4
__BED__
chr22	1000	5000	cloneA	960	+	1000	5000	0	2	567,488,	0,3512
__VCF__
##fileformat=VCFv4.2
##fileDate=20090805
##source=myImputationProgramV3.1
##reference=file:///seq/references/1000GenomesPilot-NCBI36.fasta
##contig=<ID=20,length=62435964,assembly=B36,md5=f126cdf8a6e0c7f379d618ff66beb2da,species="Homo sapiens",taxonomy=x>
##phasing=partial
##INFO=<ID=NS,Number=1,Type=Integer,Description="Number of Samples With Data">
##INFO=<ID=DP,Number=1,Type=Integer,Description="Total Depth">
##INFO=<ID=AF,Number=A,Type=Float,Description="Allele Frequency">
##INFO=<ID=AA,Number=1,Type=String,Description="Ancestral Allele">
##INFO=<ID=DB,Number=0,Type=Flag,Description="dbSNP membership, build 129">
##INFO=<ID=H2,Number=0,Type=Flag,Description="HapMap2 membership">
##FILTER=<ID=q10,Description="Quality below 10">
##FILTER=<ID=s50,Description="Less than 50% of samples have data">
##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
##FORMAT=<ID=GQ,Number=1,Type=Integer,Description="Genotype Quality">
##FORMAT=<ID=DP,Number=1,Type=Integer,Description="Read Depth">
##FORMAT=<ID=HQ,Number=2,Type=Integer,Description="Haplotype Quality">
#CHROM POS ID REF ALT QUAL FILTER INFO FORMAT NA00001 NA00002 NA00003
20	14370	rs6054257	G	A,C	29	PASS	NS=3;DP=14;AF=0.5;DB;H2	GT:GQ:DP:HQ	0|0:48:1:51,51	1|0:48:8:51,51	1/1:43:5:.,.
20	17330	.	T	A	3	q10	NS=3;DP=11;AF=0.017	GT:GQ:DP:HQ	0|0:49:3:58,50	0|1:3:5:65,3	0/0:41:3
20	1110696	rs6040355	A	G,T	67	PASS	NS=2;DP=10;AF=0.333,0.667;AA=T;DB	GT:GQ:DP:HQ	1|2:21:6:23,27	2|1:2:0:18,2	2/2:35:4
20	1230237	.	T	.	47	PASS	NS=3;DP=13;AA=T	GT:GQ:DP:HQ	0|0:54:7:56,60	0|0:48:4:51,51	0/0:61:2
20	1234567	microsat1	GTC	G,GTCT	50	PASS	NS=3;DP=9;AA=G	GT:GQ:DP	0/1:35:4	0/2:17:2	1/1:40:3
