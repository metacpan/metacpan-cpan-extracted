package Bio::DOOP::Util::Run::GeneMerge;

use strict;
use warnings;
use POSIX;

=head1 NAME

Bio::DOOP::Util::Run::GeneMerge - GeneMerge based GO analyzer

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

  #!/usr/bin/perl -w

  use Bio::DOOP::DOOP;

  $test = Bio::DOOP::Util::Run::GeneMerge->new();

  if ($test->getDescFile("GO/use/GO.BP.use") < 0){
     print"Desc error\n"
  }

  if ($test->getAssocFile("GO/assoc/A_thaliana.converted.BP") < 0){
     print"Assoc error\n"
  }

  if ($test->getPopFile("GO/pop.500") < 0){
     print"Pop error\n"
  }

  if ($test->getStudyFile("GO/study.500/combined1314.list") < 0){
     print"Study error\n"
  }

  $results = $test->getResults();

  foreach $res (@{$results}) {
     print $$res{'GOterm'}," ",$$res{'RawEs'},"\n";
  }

=head1 DESCRIPTION

This is a module based on GeneMerge v1.2.

Original program described in:

Cristian I. Castillo-Davis and Daniel L. Hartl
GeneMerge - post-genomic analysis, data mining, and hypothesis testing
Bioinformatics Vol. 19 no. 7 2003, Pages 891-892

The original program is not really good for large scale analysis, 
because the design uses a lot of I/O processes. This version fetches
everything into memory at start.

=head1 AUTHORS

Tibor Nagy, Godollo, Endre Sebestyen, Martonvasar,

=head1 METHODS

=head2 new

Create new GeneMerge object.

   $genemerge = Bio::DOOP::Util::Run::GeneMerge->new;

=cut

sub new {
  my $self                       = {};
  my $dummy                      = shift;

  $self->{HoAssoc}               = ();
  $self->{HoPopAssocCount}       = ();
  $self->{HoPopAssocFreq}        = ();
  $self->{PopGeneNo}             = 0;
  $self->{HoDesc}                = ();
  $self->{StudyGeneNo}           = 0;
  $self->{StudyGeneNoAssoc}      = 0;
  $self->{HoStudyGeneAssocCount} = ();
  $self->{HoAssocStudyGene}      = ();
  $self->{StudyGeneUniqAssoc}    = 0;
  $self->{BonferroniCorr}        = 0;
  $self->{HoStudyGeneAssocPVal}  = ();

  bless $self;
  return ($self);
}

=head2 getAssocFile

The method loads the GO association file and stores it in memory.
The file format is the following. Each line starts with a cluster id, and after some whitespace
the associated GO ids are enumerated, separated by semicolons.

81001020 GO:0016020;GO:0003674;GO:0008150                                                                                                                    
81001110 GO:0005739;GO:0003674

   $genemerge->getAssocFile('/tmp/assoc.txt');

=cut

sub getAssocFile {
   my $self                = shift;
   my $filename            = shift;

   open ASSOC, $filename or return(-1);

   while(<ASSOC>){
      chomp;
      my @assoc_line = split;
      my $assoc_gene = $assoc_line[0];
      my @assoc_go   = ();

      if ($assoc_line[1]) {
         @assoc_go = split /;/, $assoc_line[1];
         @{$self->{HoAssoc}{$assoc_gene}} = @assoc_go;
      }

   }
   close ASSOC;

   return(0);
}

=head2 getPopFile

The method loads the population file and stores it in memory.
The file format is the following. Each line contains one and only one
cluster id.

81001020
81001110

   $genemerge->getPopFile('/tmp/pop.txt');

=cut

sub getPopFile {
   my $self                = shift;
   my $filename            = shift;

   open POP, $filename or return(-1);
   while (<POP>) {
      chomp;
      my $PopGene = $_;
      $self->{PopGeneNo}++;

      if (exists $self->{HoAssoc}{$PopGene}) {
         foreach my $AssocGO (@{$self->{HoAssoc}{$PopGene}})  {
            $self->{HoPopAssocCount}{$AssocGO}++;
         }
      }
   }
   close POP;

   $self->popFreq();

   return(0);
}

=head2 popFreq

The method calculates the population frequency. Do not use it directly.

=cut

sub popFreq {
   my $self                = shift;

   foreach my $PopAssocCountKey (keys %{$self->{HoPopAssocCount}}) {
      my $freq = $self->{HoPopAssocCount}{$PopAssocCountKey} / $self->{PopGeneNo};
      $self->{HoPopAssocFreq}{$PopAssocCountKey} = $freq;
   }
}

=head2 getDescFile

The method loads the GO description file.
The file format is the following. Each line starts with the GO id, and separated by a tab,
the description of the GO id.

GO:0000007      low-affinity zinc ion transporter activity                                                                                                   
GO:0000008      thioredoxin

   $genemerge->getDescFile('/tmp/desc.txt');

=cut

sub getDescFile {
   my $self                = shift;
   my $filename            = shift;

   open DESC, $filename or return(-1);
   while (<DESC>) {
      chomp;
      my @desc_line = split /\s/, $_, 2;
      $self->{HoDesc}{$desc_line[0]} = $desc_line[1];
   }
   close DESC;

   return(0);
}

=head2 getStudyFile

The method loads the study data set, counts GO frequencies, calculates P values
based on the hypergeometric distribution, and corrects P values, based on the
Bonferroni method.

The file format of the study file is the following. Each line contains one and only one
cluster id.

81001020
81001110

   $genemerge->getStudyFile('/tmp/study.txt');

=cut

sub getStudyFile {
   # TODO we should split this in 2 or 3.
   my $self                = shift;
   my $filename            = shift;

   open STUDY, $filename or return(-1);
   while(<STUDY>) {
      chomp;
      $self->{StudyGeneNo}++;
      my $StudyGene = $_;
      if (exists $self->{HoAssoc}{$StudyGene}) {
         foreach my $StudyGeneGO (@{$self->{HoAssoc}{$StudyGene}}) {
            $self->{HoStudyGeneAssocCount}{$StudyGeneGO}++;
            push @{$self->{HoAssocStudyGene}{$StudyGeneGO}}, $StudyGene;
         }
      } else {
         $self->{StudyGeneNoAssoc}++;
      }

   }
   close STUDY;

   #Bonferroni correction
   foreach my $StudyGeneAssocCountKey (keys %{$self->{HoStudyGeneAssocCount}}){
      $self->{StudyGeneUniqAssoc}++;
      if($self->{HoPopAssocFreq}{$StudyGeneAssocCountKey} > (1 / $self->{PopGeneNo})) {
         $self->{BonferroniCorr}++;
      }
   }

   #Calculate P-values based on hypergeometric distribution
   my $PVal = 0;
   my $PValC = 0;
   my $N = $self->{PopGeneNo};
   my $K = $self->{StudyGeneNo};

   foreach my $StudyGeneAssocCountKey (keys %{$self->{HoStudyGeneAssocCount}}){
      my $P = $self->{HoPopAssocFreq}{$StudyGeneAssocCountKey};
      my $R = $self->{HoStudyGeneAssocCount}{$StudyGeneAssocCountKey};
      if ($R != 1) {
         $PVal  = $self->hypergeometric($N,$P,$K,$R);
         $PValC = ($PVal * $self->{BonferroniCorr} >= 1) ? 1 : $PVal * $self->{BonferroniCorr};
      } else {
         $PVal  = 'NA';
         $PValC = 'NA';
      }
      ${$self->{HoStudyGeneAssocPVal}{$StudyGeneAssocCountKey}}[0] = $PVal;
      ${$self->{HoStudyGeneAssocPVal}{$StudyGeneAssocCountKey}}[1] = $PValC;
   }

   return(0);
}

=head2 getResults

The method gives back all the results as an arrayref of hashes.

  $results = $genemerge->getResults();
  foreach $result (@{$results}) {
    $goterm       = $$result{'GOterm'};
    $popfreq      = $$result{'PopFreq'};
    $popfrac      = $$result{'PopFrac'};
    $studyfrac    = $$result{'StudyFrac'};
    $studyfracall = $$result{'StudyFracAll'};
    $raw_escore   = $$result{'RawEs'};
    $escore       = $$result{'EScore'};
    $desc         = $$result{'Desc'};
    @contrib      = @{$$result{'Contrib'}};
  }

=cut

sub getResults {
   my $self                = shift;
   my @results;

   foreach my $goterm (sort keys %{$self->{HoStudyGeneAssocCount}}) {
      my %result;
      $result{'GOterm'}       = $goterm;
      $result{'PopFreq'}      = $self->{HoPopAssocFreq}{$goterm};
      $result{'PopFrac'}      = $self->{HoPopAssocCount}{$goterm};
      $result{'PopFracAll'}   = $self->{PopGeneNo};
      $result{'StudyFrac'}    = $self->{HoStudyGeneAssocCount}{$goterm};
      $result{'StudyFracAll'} = $self->{StudyGeneNo};
      $result{'RawEs'}        = ${$self->{HoStudyGeneAssocPVal}{$goterm}}[0];
      $result{'EScore'}       = ${$self->{HoStudyGeneAssocPVal}{$goterm}}[1];
      $result{'Desc'}         = $self->{HoDesc}{$goterm};
      $result{'Contrib'}      = \@{$self->{HoAssocStudyGene}{$goterm}};
      push @results, \%result;
   }

   return(\@results);
}

=head2 hypergeometric

This is an internal function to calculate the hypergeometric distribution. Do not use it directly.

=cut

sub hypergeometric {
   my $self             = shift;
   my $n                = shift;
   my $p                = shift;
   my $k                = shift;
   my $r                = shift;

   my $i    = '0';
   my $q    = '0';
   my $np   = '0';
   my $nq   = '0';
   my $top  = '0';
   my $sum  = '0';
   my $lfoo = '0';

   my $logNchooseK = '0';

   $q = 1 - $p;

   $np = floor( $n * $p + 0.5 );
   $nq = floor( $n * $q + 0.5 );

   $logNchooseK = &logNchooseK( $n, $k );

   $top = ($np < $k) ? $np : $k;

   $lfoo = &logNchooseK($np, $top) + &logNchooseK($n * (1 - $p), $k - $top);

   for ($i = $top ; $i >= $r ; $i--) {
      $sum += exp($lfoo - $logNchooseK);
      if ($i > $r) { $lfoo = $lfoo + log($i / ($np - $i + 1)) + log(($nq - $k + $i) / ($k - $i + 1)) }
   }
   return $sum;
}

=head2 logNchooseK

Another internal function for the correct statistical results. Do not use it directly.

=cut

sub logNchooseK {
	my $n = shift;
	my $k = shift;

	my $i = '0';
	my $result = '0';

	$k = ($k > ($n - $k)) ? $n - $k : $k;

	for ($i = $n ; $i > ($n - $k) ; $i--) { $result += log($i) }

	$result -= &lFactorial($k);

	return $result;
}

=head2 lFactorial

Factorial calculating function. Do not use it directly.

=cut

sub lFactorial {
	my $number = shift;
	my $result = 0;
	my $i;

	for ($i = 2 ; $i <= $number ; $i++) { $result += log($i) }

	return $result;
}

1;
