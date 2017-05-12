#! /usr/bin/perl
#
use strict;
use warnings;


use Bio::Lite;

use Bio::Perl; # for revcom()
use Bio::SeqIO; # for Bio::SeqIO->new()
use Bio::Tools::GFF; # for Bio::Tools::GFF->new()

use File::Temp;
use Inline::Files 0.68;
use Benchmark qw(:all) ;

print "READING A FASTQ FILE\n";
{
  my $nb_fastq_entries = 50000;
  my $fastq_file = new File::Temp( SUFFIX => '.fastq', UNLINK => 1);
  my $i = 0;
  my $fastq_entry;
  my ($t_bioperl, $t_biolite);

  {
    local $/;
    $fastq_entry = <FASTQ>;
  }
  while($i < $nb_fastq_entries) {
    print $fastq_file $fastq_entry;
    $i++;
  }
  close $fastq_file;

  {
    my $fastq_it = seqFileIterator($fastq_file);
    my $nb_seq = 0;
    my $code = sub {
     while(my $entry = $fastq_it->()) { $nb_seq++; }
    };

    $t_biolite = timeit($nb_fastq_entries,$code);
    print "Bio::Lite\t$nb_fastq_entries loops of other code took:",timestr($t_biolite),"\n";
  }


  {
    my $inseq = Bio::SeqIO->new(
      -file   => $fastq_file,
      -format => "fastq",
    );
    my $nb_seq = 0;
    my $code = sub {
      while (my $seq = $inseq->next_seq) {$nb_seq++;};
    };
    $t_bioperl = timeit($nb_fastq_entries,$code);
    print "Bio::Perl\t$nb_fastq_entries loops of other code took:",timestr($t_bioperl),"\n";
  }

  #print "Bio::Lite acceleration: ".(($t_biolite->cpu_a -$t_bioperl->cpu_a)/$t_bioperl->cpu_a*100)."%\n";
  print "Bio::Lite acceleration: ".($t_bioperl->cpu_a/$t_biolite->cpu_a)."x faster\n";
}

print "\nREADING A FASTA FILE\n";
{
  my $nb_fasta_entries = 100000;
  my $fasta_file = new File::Temp( SUFFIX => '.fasta', UNLINK => 1);
  my $i = 0;
  my $fasta_entry;
  my ($t_bioperl, $t_biolite);

  {
    local $/;
    $fasta_entry = <FASTA>;
  }
  while($i < $nb_fasta_entries) {
    print $fasta_file $fasta_entry;
    $i++;
  }
  close $fasta_file;

  {
    my $fasta_it = seqFileIterator($fasta_file);
    my $nb_seq = 0;
    my $code = sub {
     while(my $entry = $fasta_it->()) { $nb_seq++; }
    };

    $t_biolite = timeit($nb_fasta_entries,$code);
    print "Bio::Lite\t$nb_fasta_entries loops of other code took:",timestr($t_biolite),"\n";
  }


  {
    my $inseq = Bio::SeqIO->new(
      -file   => $fasta_file,
      -format => "fasta",
    );
    my $nb_seq = 0;
    my $code = sub {
      while (my $seq = $inseq->next_seq) {$nb_seq++;};
    };
    $t_bioperl = timeit($nb_fasta_entries,$code);
    print "Bio::Perl\t$nb_fasta_entries loops of other code took:",timestr($t_bioperl),"\n";
  }
  #print "Bio::Lite acceleration: ".(($t_biolite->cpu_a -$t_bioperl->cpu_a)/$t_bioperl->cpu_a*100)."%\n";
  print "Bio::Lite acceleration: ".($t_bioperl->cpu_a/$t_biolite->cpu_a)."x faster\n";
}

print "\nREADING A GFF3 FILE\n";
{
  my $nb_gff_entries = 100000;
  my $gff_file = new File::Temp( SUFFIX => '.gff', UNLINK => 1);
  my $i = 0;
  my $gff_entry;
  my ($t_bioperl, $t_biolite);

  {
    local $/;
    $gff_entry = <GFF3>;
  }
  while($i < $nb_gff_entries) {
    print $gff_file $gff_entry;
    $i++;
  }
  close $gff_file;

  {
    my $gff_it = gffFileIterator($gff_file,'gff3');
    my $nb_annot = 0;
    my $code = sub {
     while(my $entry = $gff_it->()) { $nb_annot++; }
    };

    $t_biolite = timeit($nb_gff_entries,$code);
    print "Bio::Lite\t$nb_gff_entries loops of other code took:",timestr($t_biolite),"\n";
  }


  {
    my $gffio = Bio::Tools::GFF->new(-file => $gff_file, -gff_version => 3);
    my $feature;
    my $nb_annot = 0;
    my $code = sub { 
      while($feature = $gffio->next_feature()) {
      $nb_annot++;
      }
      $gffio->close();
    };
    $t_bioperl = timeit($nb_gff_entries,$code);
    print "Bio::Perl\t$nb_gff_entries loops of other code took:",timestr($t_bioperl),"\n";
  }
  #print "Bio::Lite acceleration: ".(($t_biolite->cpu_a -$t_bioperl->cpu_a)/$t_bioperl->cpu_a*100)."%\n";
  print "Bio::Lite acceleration: ".($t_bioperl->cpu_a/$t_biolite->cpu_a)."x faster\n";
}

print "\nREVERSE COMPLEMENTING\n";
{
  my $seq = "TTAATTGGTAAATAAATCTCCTAATAGCTTAGATNTTACCTTNNNNNNNNNNTAGTTTCTTGAGATTTGTTGGGGGAGACATTTTTGTGATTGCCTTGAT";
  my $nb_revcomp = 100000;
  my ($t_bioperl, $t_biolite);

  {
    my $code = sub { my $reverse_complement = reverseComplemente( $seq ); };
    $t_biolite = timeit($nb_revcomp,$code);
    print "Bio::Lite\t$nb_revcomp loops of other code took:",timestr($t_biolite),"\n";
  }

  {
    my $code = sub { my $reverse_complement = revcom_as_string( $seq ); };
    $t_bioperl = timeit($nb_revcomp,$code);
    print "Bio::Perl\t$nb_revcomp loops of other code took:",timestr($t_bioperl),"\n";
  }
  #print "Bio::Lite acceleration: ".(($t_biolite->cpu_a -$t_bioperl->cpu_a)/$t_bioperl->cpu_a*100)."%\n";
  print "Bio::Lite acceleration: ".($t_bioperl->cpu_a/$t_biolite->cpu_a)."x faster\n";
}

__FASTQ__
@HWI-EAS209_0006_FC706VJ:5:58:5894:21141#ATCACG/1
TTAATTGGTAAATAAATCTCCTAATAGCTTAGATNTTACCTTNNNNNNNNNNTAGTTTCTTGAGATTTGTTGGGGGAGACATTTTTGTGATTGCCTTGAT
+HWI-EAS209_0006_FC706VJ:5:58:5894:21141#ATCACG/1
efcfffffcfeefffcffffffddf`feed]`]_Ba_^__[YBBBBBBBBBBRTT\]][]dddd`ddd^dddadd^BBBBBBBBBBBBBBBBBBBBBBBB
__FASTA__
>gi|224384757|gb|CM000674.1| Homo sapiens chromosome 12, GRC primary reference assembly
TCAGAGCCCTTGCCTGAGGGCCTGGCCTGGCAGCTCTGCTGTTAGAAGCAGGAGGTGTGCAGGGGGTGGG
GAGCAGCCCAGCCTCTGTGATCTTCTCCATGGCAGGATCTCCCAGCAGGTAGAGCAGAGCCGGAGCCAGG
TGCAGGCCATTGGAGAGAAGGTCTCCTTGGCCCAGGCCAAGATTGAGAAGATCAAGGGCAGCAAGAAGGC
CATCAAGGTAGTCCCCATACCCCTGTGTCCTGAGACTTTTCCCCGTGCCTCTGAGGCCGCCCATTCTCTG
CCCTGCTGCCCACCTGTACCTTGGGCTTTCTTCTCGCCCAGGCTTCCAACTCCACCCTCTCCTGCCAAGC
AATCCTAGCCCTCTGAGCCTCTTAGGGCCCCCTCAGACTTGTCCCTGTGTCCACAGGTGTTCTCCAGTGC
CAAGTACCCTGCTCCAGAGCACCTGCAGGAATATGGCTCCATCTTCACGGGCGCCCAGGACCCTGGCCTG
CAGAGACGCTCCCGCCACAGGATCCAGAGCAAGCACCGCCCCCTGGACGAGCGGGCCCTGCAGGTCTGCT
GGCTGCGCACATAACTTAGCCTGTCACACACCAGGAGGACTGGATACTGGGGAGGAGCCGGGGCCACCAT
AGGGTTCTGTCCCCCAGAGGAGGCTGACTGGGATGGGGTGGCAGCTGATTAGGCCCAGCACCAAATATTC
ACCATCCCTTGGCCATCCTGGCCCTCCCAGGAGAAGCTGAAGGAATTTCCTGTGTGCGTGAGCACCAAGC
CGGAGCCTGAGGACGATGCAGAAGAGGGACTTGGGGGTCTTCCCAGCAACATCAGCTCTGTCAGCTCCTT
GCTGCTTTTCAACACCACCGAGAACCTGTATGGCCAGAAGGCAGGGCCGAGGGGTGTGGGCGGGAGGCCC
GGCCTGGCTTAGTGGGGACCCAGGGCATCAGACACAGGTACAGCACATAGCCCAGGAGCCAGGGGGTGAC
TGGGGTGGCTCGGCTTGGGAGGCCTGGGACCCCACAGTGCACGCTGTGCCCCTGATGATGTGGGAGAGGA
ACATGGGCTCAGGACAGCGGGTGTCATCTTGCCTGACCCCCATGTCGCCTCTGTAGGTAGAAGAAGTATG
TCTTCCTGGACCCCCTGGCTGGTGCTGTAACAAAGACCCATGTGATGCTGGGGGCAGAGACAGAGGAGAA
GCTGTTTGATGCCCCCTTGTCCATCAGCAAGAGAGAGCAGCTGGAACAGCAGGTGGGAGGGGTGGGACAG
AGGTGGAGACAGGTGCAGTGGCCCAGGGCCTTGCCAGAGCTCCTCTCCAGTCAAGGCTGTTGGGCCCCTT
ATTCCACCCATGGGAGGTGCACACAAGGTCTTGTTGGCTGCCCCTGCAGGTCCCTGTCACCTCTCACATG
TCCCTGCCTAATCTTGCAGGTCCCAGAGAACTACTTCTATGTGCCAGACCTGGGCCAGGTGCCTGAGATT
GATGTTCCATCCTACCTGCCTGACCTGCCCAGCATTGCCAACGACCTCATGTACATTGCCGACCTGGGCC
CCGGCATTGCCCCCTCTGCCCCTGGCACCATTCCAGAACTGCCCACCTTCCACACTGAGGTAGCCGAGCC
TCTCAAGGCAGGTGAGCTGGGTTCTGGGATGGGAGCTGTGCCGGGGACCTCCCTGCTGACACACCTTCTT
CCCTAGACACCCCACACTTTGTGTTTCAGACCTACAAGATGGGGTACTAACACCACCCCCACCGCCCCCA
CCACCACCCCCAGCTCCTGAGGTGCTGGCCAGTGCACCCCCACTCCCACCCTCAACCGCGGCCCCTGTAG
GCCAAGGCGCCAGGCAGGACGACAGCAGCAGCAGCACGTCTCCTTCAGGTGGGAGCAGCTCTTTGAGGCC
ACCTGATTTCTGGCGTGCTCAGTGCACTCGGGTGGATTTTCTGTGGGTTTGTTAAGTGGTCAGAAATTCT
CAATTTTTTGAATAGTTTCCATTTCAAATATCTTGTTCTACTTGGTTCATAAAATAGTGGCTTTCAAACT
GTAGAGCTCTGGACTTCTCACTTCTAGGGCAGAGGGAGCCTGAACAAGTGAGGCTCTGGGTTCCTCATTC
CTAATTAAACCAATGGAAAGAAGGGGTCTAATAACAAACTACAGCAACACATTTTTCATTTCAGCTTCAC
TGCTGTATCTCCCAGTGTAACCCTAGCATCCAGAAGTGGCACAAAACCCCTCTGCTGGCTCATGTGTGCA
ACTGAGACTGTCAGAGCATGGCTAGCTCAGGGGTCCAGCTCTGCAGGGTGGGGGCTAGAGAGGAAGCAGG
GAGTATCTGCACACAGGATGCCCGCGCTCAGGTGGTTGCAGAAGTCAGTGCCCAGGCCCCACACAGTCTC
CAAAGGTCCGGCCTCCCCAGCGCGGGGCTCCTCGTTTGAGGGG
__GFF3__
HSCHR6_MHC_MANN	Ensembl_CORE	mRNA	30051790	30051922	.	-	.	ID=ENST00000578939;Parent=ENSG00000266142;exons_nb=1;type=small_ncRNA:miRNA
