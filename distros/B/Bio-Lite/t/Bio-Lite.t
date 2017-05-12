use strict;
use warnings;

use Test::More tests => 51;

use Bio::Lite;
use Inline::Files 0.68;
use File::Temp;

is(reverseComplemente("AGCTGCGTnGTA"),"TACnACGCAGCT");

is(convertStrand(1),'+');
is(convertStrand(-1),'-');
is(convertStrand('+'),1);
is(convertStrand('-'),-1);


# __FASTQ__ => seqFileIterator($file,'fastq')
{
  # Create a temp file with the FASTQ lines described below
  my $fastq_file = new File::Temp( SUFFIX => '.fastq', UNLINK => 1);
  while(<FASTQ>) {print $fastq_file $_;}
  close $fastq_file;
  my $fastq_it = seqFileIterator($fastq_file);
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

  my $fasta_it = seqFileIterator($fasta_file);
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

  my $fasta_it = seqFileIterator($fasta_file);
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

  my $paired_end_it = pairedEndSeqFileIterator($fastq_file_1,$fastq_file_2);
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

  my $gff_it = gffFileIterator($gff_file,'gff3');
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
