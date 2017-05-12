#! /usr/bin/perl

use strict;
use warnings;

use Test::More tests => 14;

use CracTools::Annotator;

use File::Temp 0.23;
use Inline::Files 0.68;  

# Create a temp file with the GFF lines described below
my $gff_file = new File::Temp( SUFFIX => '.gff', UNLINK => 1);
while(<GFF>) {print $gff_file $_;}
close $gff_file;

# Creating the Annotator if fast mode
my $annotator = CracTools::Annotator->new($gff_file,"fast");

# Testing accessors
is($annotator->mode,"fast");

# Testing Queries
# candidat(chr,pos_start,post_end,strand)
{
  my @candidates = @{ $annotator->getAnnotationCandidates(1,30,78,1)}; # Convert to 0-based coordinate system
  is(scalar @candidates, 4, 'getAnnotationCandidates');
}

{
  my ($annot,$priority,$type) = $annotator->getBestAnnotationCandidate(1,44,60,1);
  is($type,'INTRON','getBestAnnotationCandidate (2)');
  is($annot->{gene}->attribute('Name'),'TOTO','getBestAnnotationCandidate (1)');
  my ($priority2,$type2) = CracTools::Annotator::getCandidatePriorityDefault(44,60,$annot);
  is($priority2,$priority,"getCandidatePriorityDefault (1)");
  is($type2,$type,"getCandidatePriorityDefault (2)");
}

{
  ok($annotator->foundAnnotation(1,12,42,1),'foundAnnotation');
  ok($annotator->foundGene(1,72,102,1),'foundGene');
  ok($annotator->foundSameGene(1,12,42,72,102,1),'foundSameGene (1)');
  is($annotator->foundSameGene(1,12,102,112,127,-1),0,'foundSameGene (2)');
}

{
  my @candidates_down = @{ $annotator->getAnnotationNearestDownCandidates(1,200,1)};
  foreach my $candidate (@candidates_down){
    if (defined $candidate->{exon}){
      is($candidate->{exon}->end,101,'getAnnotationNearestDownCandidates (1)');
    }
  } 
}

{
  my @candidates_up = @{ $annotator->getAnnotationNearestUpCandidates(1,10,-1)}; 
  foreach my $candidate (@candidates_up){
    if (defined $candidate->{exon}){
      is($candidate->{exon}->start,11,'getAnnotationNearestDownCandidates (1)');
    }
  } 
}

# bug 17618 (submitted by T. Guignard) 
ok($annotator->foundSameGene(7,98984392,98984412,98985657,98985677,1),'foundSameGene (3)');

__GFF__
1	Ensembl_CORE	exon	12	42	.	+	.	ID=ENSE00002706393;Parent=ENST00000578939
1	Ensembl_CORE	exon	72	102	.	+	.	ID=ENSE00002706394;Parent=ENST00000578939,ENST00000578940
1	Ensembl_CORE	cds	12	102	.	+	.	ID=ENST00000578939.cds;Parent=ENST00000578939
1	Ensembl_CORE	mRNA	12	102	.	+	.	ID=ENST00000578939;Parent=ENSG00000266142;Exons_NB=1;type=protein_coding
1	Ensembl_CORE	mRNA	72	102	.	+	.	ID=ENST00000578940;Parent=ENSG00000266142;Exons_NB=1;type=protein_coding
1	Ensembl_CORE	gene	12	102	.	+	.	ID=ENSG00000266142;Name=TOTO;Transcripts_NB=2
1	Ensembl_CORE	exon	12	102	.	-	.	ID=ENSE00002706395;Parent=ENST00000578941
1	Ensembl_CORE	mRNA	12	42	.	-	.	ID=ENST00000578941;Parent=ENSG00000266143;Exons_NB=1;type=protein_coding
1	Ensembl_CORE	gene	12	102	.	-	.	ID=ENSG00000266143;Name=INVTOTO;Transcripts_NB=1
7	Ensembl_CORE	exon	98957168	98957361	.	+	.	ID=ENSE00003632159;Parent=ENST00000262942,ENST00000432884;exon_rank=6
7	Ensembl_CORE	exon	98951532	98951744	.	+	.	ID=ENSE00003627403;Parent=ENST00000262942,ENST00000432786,ENST00000432884;exon_rank=7
7	Ensembl_CORE	exon	98930948	98931040	.	+	.	ID=ENSE00003557955;Parent=ENST00000432884;exon_rank=9
7	Ensembl_CORE	exon	98933076	98933107	.	+	.	ID=ENSE00003489116;Parent=ENST00000432884;exon_rank=10
7	Ensembl_CORE	exon	98984308	98984412	.	+	.	ID=ENSE00003466137;Parent=ENST00000432884;exon_rank=11
7	Ensembl_CORE	exon	98961166	98961256	.	+	.	ID=ENSE00003628680;Parent=ENST00000262942,ENST00000432884;exon_rank=12
7	Ensembl_CORE	exon	98937481	98937632	.	+	.	ID=ENSE00003668136;Parent=ENST00000432884;exon_rank=15
7	Ensembl_CORE	exon	98935804	98935908	.	+	.	ID=ENSE00003521456;Parent=ENST00000432884;exon_rank=19
7	Ensembl_CORE	exon	98985662	98985787	.	+	.	ID=ENSE00001664745;Parent=ENST00000441989,ENST00000432884;exon_rank=20
7	Ensembl_CORE	exon	98955963	98956038	.	+	.	ID=ENSE00003546812;Parent=ENST00000262942,ENST00000432884;exon_rank=22
7	Ensembl_CORE	exon	98923521	98923627	.	+	.	ID=ENSE00001683310;Parent=ENST00000441989,ENST00000432884;exon_rank=23
7	Ensembl_CORE	exon	98983325	98983401	.	+	.	ID=ENSE00003496371;Parent=ENST00000432884;exon_rank=27
7	Ensembl_CORE	exon	98941916	98942138	.	+	.	ID=ENSE00003481841;Parent=ENST00000262942,ENST00000432786,ENST00000432884;exon_rank=30
7	Ensembl_CORE	exon	98946475	98946582	.	+	.	ID=ENSE00003668403;Parent=ENST00000262942,ENST00000432786,ENST00000432884;exon_rank=37
7	Ensembl_CORE	mRNA	98923521	98985787	.	+	.	ID=ENST00000441989;Parent=ENSG00000241685;exons_nb=14;type=protein_coding:protein_coding
7	Ensembl_CORE	mRNA	98923533	98963880	.	+	.	ID=ENST00000262942;Parent=ENSG00000241685;exons_nb=10;type=protein_coding:protein_coding
7	Ensembl_CORE	mRNA	98923550	98963849	.	+	.	ID=ENST00000432786;Parent=ENSG00000241685;exons_nb=10;type=protein_coding:protein_coding
7	Ensembl_CORE	mRNA	98951558	98957865	.	+	.	ID=ENST00000471960;Parent=ENSG00000241685;exons_nb=4;type=protein_coding:protein_coding
7	Ensembl_CORE	mRNA	98956289	98963837	.	+	.	ID=ENST00000463009;Parent=ENSG00000241685;exons_nb=4;type=protein_coding:protein_coding
7	Ensembl_CORE	mRNA	98961088	98963885	.	+	.	ID=ENST00000477240;Parent=ENSG00000241685;exons_nb=2;type=protein_coding:protein_coding
7	Ensembl_CORE	mRNA	98923521	98985787	.	+	.	ID=ENST00000432884;Parent=ENSG00000241685;exons_nb=14;type=protein_coding:protein_coding
7	Ensembl_CORE	gene	98923521	98985787	.	+	.	ID=ENSG00000241685;Name=ARPC1A;transcripts_nb=7;exons_nb=39
