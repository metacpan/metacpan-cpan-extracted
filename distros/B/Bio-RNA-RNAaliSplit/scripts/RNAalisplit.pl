#!/usr/bin/env perl
# Last changed Time-stamp: <2019-04-05 22:54:35 mtw>
# -*-CPerl-*-
#
# usage: RNAalisplit.pl -a myfile.aln
#
# NB: Display ID handling in Bio::AlignIO is broken for Stockholm
# format. Use ClustalW format instead !!!

use version; our $VERSION = qv('0.10');
use strict;
use warnings;
use Bio::RNA::RNAaliSplit;
use Bio::RNA::RNAaliSplit::WrapRNAz;
use Bio::RNA::RNAaliSplit::WrapRscape;
use Bio::RNA::RNAaliSplit::WrapRNAalifold;
use Bio::RNA::RNAaliSplit::WrapAnalyseDists;
use Getopt::Long qw( :config posix_default bundling no_ignore_case );
use Data::Dumper;
use Pod::Usage;
use Path::Class;
use File::Basename;
use Carp;
use RNA;
use diagnostics;

#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^#
#^^^^^^^^^^ Variables ^^^^^^^^^^^#
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^#

my $format = "ClustalW";
my $method = "dHn"; # SCI | dHn | dHx | dBp | dBc | dHB
my $rscape_stat = "GTp";
my $outdir = "as";
my $verbose = undef;
my $rnaz=undef;
my @nseqs=();
my ($alifile,$fi);
my $scaleH = 1.;
my $scaleB = 1.;
my $ribosum = 1;
my $constraint=undef;
my $show_version = 0;
my %foldme = (); # HoH of folded input sequences for dBp/dBc computation

my %pair = ("AU" => 5,
	    "GC" => 1,
	    "CG" => 2,
	    "UA" => 6,
	    "GU" => 3,
	    "GT" => 3,
	    "TG" => 4,
	    "UG" => 4,
	    "AT" => 5,
	    "TA" => 6);


Getopt::Long::config('no_ignore_case');
pod2usage(-verbose => 1) unless GetOptions("aln|a=s"      => \$alifile,
					   "constraint|c=s" => \$constraint,
					   "method|m=s"   => \$method,
					   "noribosum"    => sub{$ribosum=0},
					   "out|o=s"      => \$outdir,
					   "rscapestat=s" => \$rscape_stat,
					   "scaleH"       => \$scaleH,
					   "scaleB"       => \$scaleB,
					   "verbose|v"    => sub{$verbose = 1},
					   "version"      => sub{$show_version = 1},
					   "man"          => sub{pod2usage(-verbose => 2)},
					   "help|h"       => sub{pod2usage(1)}
					   );

if ($show_version == 1){
  print "RNAalisplit $VERSION\n";
  exit(0);
}

unless (-f $alifile){
  warn "Could not find input file provided via --aln|-a option";
  pod2usage(-verbose => 0);
}

croak "ERROR: method dBc must be selected when using constraints, exiting ..."
  if (defined $constraint && $method ne "dBc");

if($method eq "dBp" || $method eq "dHB"){
  $fi = fold_input_alignment($alifile); # for later computation of BP dist
}
if($method eq "dBc"){
  $fi = fold_input_alignment_constrained($alifile,$constraint);
}


my $round = 1;
my $done = 0;
while ($done != 1){
  my $lround = sprintf("%03d", $round);
  my $current_round_name = "round_".$lround;
  my $odirname = dir($outdir,$current_round_name);
  print STDERR "Computing round $lround ...\n";
  alisplit($alifile,$odirname);
  $round++;
  $done = 1;
  #TODO sort output by RNAz SVM prob and re-run with the first few as input alignments
}


###############
# subroutines #
###############

sub alisplit {
  my ($alnfile,$odirn) = @_;
  my ($what,$alifold,$rscape);
  my $AlignSplitObject = Bio::RNA::RNAaliSplit->new(ifile => $alnfile,
						    format => $format,
						    odir => $odirn,
						    dump => 1);
  #print Dumper($AlignSplitObject);
  my $dim = $AlignSplitObject->next_aln->num_sequences;
  my $stkfile = $AlignSplitObject->alignment_stk;
  my $dmfile = make_distance_matrix($AlignSplitObject,$method,$odirn);

  # compute Neighbor Joining tree and do split decomposition
  print STDERR "Perform Split Decomposition ...\n";
  my $sd = Bio::RNA::RNAaliSplit::WrapAnalyseDists->new(ifile => $dmfile,
							odir => $AlignSplitObject->odir);
  print STDERR "Identified ".$sd->count." splits\n";
  print join "\t", ("#hint","RNAz prob","z-score","SCI","seqs","statistic","SSCBP","consensus structure","alignment"), "\n";

  # run RNAalifold for the input alignment
  $alifold = Bio::RNA::RNAaliSplit::WrapRNAalifold->new(ifile => $alnfile,
							odir => $AlignSplitObject->odir,
							ribosum => $ribosum);

  # run RNAz for the input alignment
  $rnaz = Bio::RNA::RNAaliSplit::WrapRNAz->new(ifile => $alnfile,
					       odir => $AlignSplitObject->odir);

  # run R-scape for the input alignment
  $rscape = Bio::RNA::RNAaliSplit::WrapRscape->new(ifile => $alifold->alignment_stk, # use RNAalifold-generated stk
						   odir => $AlignSplitObject->odir,
						   statistic => $rscape_stat,
						   nofigures => 1);
  $rscape->status == 0 ? $what = $rscape->TP : $what = "n/a";

  print join "\t", "-",$rnaz->P,$rnaz->z,$alifold->sci,$dim,$rscape->statistic,$what,
    $alifold->consensus_struc,$alnfile."\n";

  # extract split sets and run RNAz/RNAalifold/R-scape on each of them
  my $splitnr=1;
  while (my $sets = $sd->pop()){
    my ($sa1_c,$sa1_s,$sa2_c,$sa2_s); # subalignments in Clustal and Stockholm
    my $set1 = $$sets{S1};
    my $set2 = $$sets{S2};
    my $token = "split".$splitnr;
    #print "set1: @$set1\n"; #print "set2: @$set2\n";
    ($sa1_c,$sa1_s) = $AlignSplitObject->dump_subalignment("splits", $token.".set1", $set1);
    ($sa2_c,$sa2_s) = $AlignSplitObject->dump_subalignment("splits", $token.".set2", $set2);
    if( scalar(@$set1) > 1){evaluate_alignment($sa1_c,$sa1_s,$AlignSplitObject->odir,scalar(@$set1))}
    if( scalar(@$set2) > 1){evaluate_alignment($sa2_c,$sa2_s,$AlignSplitObject->odir,scalar(@$set2))}
    $splitnr++;
  }
}

sub evaluate_alignment {
  my ($aln, $stk, $odir, $count) = @_;
  my ($hint,$rnazo,$alifoldo,$rscapeo,$cs,$what);

  $rnazo =  Bio::RNA::RNAaliSplit::WrapRNAz->new(ifile => $aln,
						 odir => $odir);
  ($rnazo->P > $rnaz->P) ? ($hint = "?") : ($hint = "-");
  if($rnazo->P > 1.2*$rnaz->P){$hint = "x"};
  if($rnazo->P > 1.3*$rnaz->P){$hint = "X"};
  $alifoldo = Bio::RNA::RNAaliSplit::WrapRNAalifold->new(ifile => $aln,
							 odir => $odir,
							 ribosum => $ribosum);
  $cs = $alifoldo->consensus_struc;
  $rscapeo =  Bio::RNA::RNAaliSplit::WrapRscape->new(ifile => $alifoldo->alignment_stk, # use RNAalifold-generated stk
						     odir => $odir,
						     statistic => $rscape_stat,
						     nofigures => 1);
  if ($rscapeo->status == 0){ # all OK
    $what = $rscapeo->TP;
  }
  elsif ($rscapeo->status == 1){  # no significant basepairs
    $what = "0:no_sign";
  }
  elsif ($rscapeo->status == 2){  # covariation scores are almost constant, no further analysis
    $what = "0:no_data";
  }
  else { $what = "n/a" }

  print join "\t",($hint,$rnazo->P,$rnazo->z,$alifoldo->sci,$count,$rscapeo->statistic,$what,$cs,$aln), "\n";
}

sub make_distance_matrix {
  my ($ASO,$m,$od) = @_;
  my $this_function = (caller(0))[3];
  my ($i,$j,$Dfile,$dHn,$dHx,$dBp,$dHB);
  my @pw_alns = ();
  my @D = ();
  my $check = 1;
  my $dim = $ASO->next_aln->num_sequences;

  # extract all pairwise alignments
  print STDERR "Extracting pairwise alignments ...\n";
  for ($i=1;$i<$dim;$i++){
    for($j=$i+1;$j<=$dim;$j++){
      my $token = join "_", "pw",$i,$j;
      my ($sa_clustal,$sa_stockholm) = $ASO->dump_subalignment("pairwise", $token, [$i,$j]);
      push @pw_alns, $sa_clustal->stringify;
    }
  }

  # initialize distance matrix
  for($i=0;$i<$dim;$i++){
    for ($j=0;$j<$dim;$j++){
      $D[$dim*$i+$j] = 0.;
    }
  }

  # build distance matrix based on pairwise alignments
  print STDERR "Constructing distance matrix based on pairwise alignments ...\n";
  foreach my $ali (@pw_alns){
    my $pw_aso = Bio::RNA::RNAaliSplit->new(ifile => $ali,
					    format => "ClustalW",
					    odir => $od);
    my ($i,$j) = sort split /_/, $pw_aso->ifilebn;

    $dHn = $pw_aso->hammingdistN;
    $dHx = $pw_aso->hammingdistX;
    my $id1 = $pw_aso->next_aln->get_seq_by_pos(1)->display_id;
    my $id2 = $pw_aso->next_aln->get_seq_by_pos(2)->display_id;
   # my $seq1 = $so1->seq;
   # my $seq2 = $so2->seq;
   # my ($ss1,$mfe1) = RNA::fold($seq1);
   # my ($ss2,$mfe2) = RNA::fold($seq2);
    #print ">> \$seq1: $seq1\n          $ss1\n>> \$seq2: $seq2\n          $ss2\n\n";
 #   print Dumper($so1);

    if ($m eq "SCI"){
      # distance = -log( [normalized] pairwise SCI)
      my ($sci,$dsci);
      if($pw_aso->sci > 1){$sci = 1}
      elsif ($pw_aso->sci == 0.){$sci = 0.000001}
      else { $sci = $pw_aso->sci; }
      $dsci = -1*log($sci)/log(10);
      $D[$dim*($i-1)+($j-1)] =  $D[$dim*($j-1)+($i-1)] = $dsci;
      #  print "$i -> $j : $sci\t$dsci\n";
    }
    elsif ($m eq "dHn") { # hamming dist with gaps replaced by Ns
      $D[$dim*($i-1)+($j-1)] =  $D[$dim*($j-1)+($i-1)] = $dHn;
    }
    elsif ($m eq "dHx") { # hamming dist with all gap columns removed
      $D[$dim*($i-1)+($j-1)] =  $D[$dim*($j-1)+($i-1)] = $dHx;
    }
    elsif ($m eq "dBp") { # base pair distance
      carp "ERROR [$this_function] sequence \'display_id\' not found in input alignment"
	unless (exists $$fi{$id1} && exists $$fi{$id2});
      my $gss1 = $$fi{$id1}->{gss};
      my $gss2 = $$fi{$id2}->{gss};
      my $dBp = RNA::bp_distance($gss1,$gss2);
      $D[$dim*($i-1)+($j-1)] =  $D[$dim*($j-1)+($i-1)] = $dBp;
    }
    elsif ($m eq "dBc") { # constrained base pair distance
      carp "ERROR [$this_function] sequence \'display_id\' not found in input alignment"
	unless (exists $$fi{$id1} && exists $$fi{$id2});
      my $gss1 = $$fi{$id1}->{gss};
      my $gss2 = $$fi{$id2}->{gss};
      my $dBp = RNA::bp_distance($gss1,$gss2);
      $D[$dim*($i-1)+($j-1)] =  $D[$dim*($j-1)+($i-1)] = $dBp;
    }
    elsif($m eq "dHB") { # combined hamming + basepair distance
      carp "ERROR [$this_function] sequence \'display_id\' not found in input alignment"
	unless (exists $$fi{$id1} && exists $$fi{$id2});
      my $gss1 = $$fi{$id1}->{gss};
      my $gss2 = $$fi{$id2}->{gss};
      my $dBp = RNA::bp_distance($gss1,$gss2);
      my $dHB = $scaleH*$dHn + $scaleB*$dBp;
      $D[$dim*($i-1)+($j-1)] =  $D[$dim*($j-1)+($i-1)] = $dHB;
    }
    else {croak "Method $method not available ..please use any of SCI|dHn|dHx|dBp|dBc|dHB"}
  }

  # write matrix to file
  print STDERR "Writing distance matrix to file ...\n";
  if ($m eq "SCI"){ $Dfile = dump_matrix(\@D,$dim,1,1,"S",$ASO,$verbose)}
  elsif ($m eq "dHn"){$Dfile = dump_matrix(\@D,$dim,1,1,"dHn",$ASO,$verbose)}
  elsif ($m eq "dHx"){$Dfile = dump_matrix(\@D,$dim,1,1,"dHx",$ASO,$verbose)}
  elsif ($m eq "dBp"){$Dfile = dump_matrix(\@D,$dim,1,1,"dBp",$ASO,$verbose)}
  elsif ($m eq "dBc"){$Dfile = dump_matrix(\@D,$dim,1,1,"dBc",$ASO,$verbose)}
  elsif ($m eq "dHB"){$Dfile = dump_matrix(\@D,$dim,1,1,"dHB",$ASO,$verbose)}
  else { croak "Method $m not available ..please use SCI|dHn|dHx|dBp|dHB"}

  # check triangle inequality
  if ($check == 1){
    print STDERR "Checking triangle inequality ...\n";
    my $result = check_triangle($dim,\@D);
  }
  return $Dfile;
}


sub dump_matrix {
  my ($M,$d,$ad,$pd,$what,$aso,$verbos) = @_;
  my ($i,$j,$info);
  my $ad_mx = file($aso->odir,"ld.mx"); # AnalyseDists lower diagoinal distance matrix
  my $pd_mx = file($aso->odir,"phylip.dst"); # Phylip distance matrix
  if(defined($verbos)){
    print STDERR "Analysedists matrix \$ad_mx is $ad_mx\n";
    print STDERR "Phylip matrix \$pd_mx is $pd_mx\n";
  }
  if ($what eq "S"){$info="> S (SCI distance)"}
  elsif($what eq "dHn"){$info="> H (Hamming distance with gap Ns)"}
  elsif($what eq "dHx"){$info="> H (Hamming distance with gaps removed)"}
  elsif($what eq "dBp"){$info="> B (Base pair distance)"}
  elsif($what eq "dBc"){$info="> B (Base pair distance with constraints)"}
  else{$info="> H (unknown)"}

  if (defined $ad){ # print lower triangle matrix input for AanalyseDists
    open my $matrix, ">", $ad_mx or die $!;
    print $matrix $info,"\n";
    print $matrix "> X $d\n";
    for ($i=1;$i<$d;$i++){
      for($j=0;$j<$i;$j++){
	printf $matrix "%6.4f ", @$M[$d*$i+$j];
      }
      print $matrix "\n";
    }
    close $matrix;
  }
  else{ # print entire matrix
    for ($i=0;$i<$d;$i++){
      for($j=0;$j<$d;$j++){
	printf "%6.4f ", @$M[$d*$i+$j];
      }
      print "\n";
    }
  }
  if (defined $pd){ # print phylip distance matrix
    open my $matrix, ">", $pd_mx  or die $!;
    print $matrix "$d\n";
    for ($i=0;$i<$d;$i++){
      my $val = ${$aso->next_aln}{_order}->{$i};
      $val=~s/\//_/g;
      my $id = join '_', eval($i+1),$val;
      print $matrix $id." ";
	for($j=0;$j<$d;$j++){
	  printf $matrix "%6.4f ", @$M[$d*$i+$j];
	}
      print $matrix "\n";
    }
    close $matrix;
  }
  return $ad_mx;
}

sub check_triangle {
  my ($d,$dref) = @_;
  my $count = 0;
  my @M = @$dref;
  my ($i,$j,$k,$d_ij,$d_jk,$d_ik);
  for ($i=0;$i<$d;$i++){
    for($j=0;$j<$d;$j++){
      $d_ij = $M[$d*$i+$j];
      for($k=0;$k<$d;$k++){
	$d_jk = $M[$d*$j+$k];
	$d_ik = $M[$d*$i+$k];
	$count++;
	croak "ERROR triangle inequation not satisfied i:$i j:$j k:$k"
	  unless ($d_ij + $d_jk >= $d_ik);
      }
    }
  }
  print STDERR "Checked $count triangles ...\n";
}

sub fold_input_alignment {
  my $aln = shift;
  my %foldin = ();

  my $input_AlignIO = Bio::AlignIO->new(-file => $alifile,
				      -format => 'ClustalW'
				     );
  my $input_aln = $input_AlignIO->next_aln;
  foreach my $element ($input_aln->each_seq) {
    my @gappos = ();
    my $gseq = $element->seq;
    for (my $i=0;$i<length($gseq);$i++){
      push @gappos, $i if (substr($gseq,$i,1) eq "-"); # store gap positions
    }
    my $seq = $gseq;
    $seq =~ s/-//g; # get gap-free sequence
    my ($ss,$mfe) = RNA::fold($seq);
    my $gss = $ss;
    for (my $i=0;$i<=$#gappos;$i++){
      my $gaps_inserted = 0;
      substr($gss,$gappos[$i]+$gaps_inserted,0) = ".";
      $gaps_inserted++;
    }
    print $element->display_id."\n$gseq\n$gss\n$seq\n$ss\n";
    print join ",", @gappos,"\n---\n";
    unless (exists($foldin{$element->display_id})){
      $foldin{$element->display_id} = {
				       gseq => $gseq,
				       seq => $seq,
				       ss => $ss,
				       gss =>$gss,
				       mfe => $mfe,
				      }
    }
    else{
      croak "ERROR: duplicate sequence identifier in input: ".$element->display_id;
    }
  }
  return \%foldin;
}

sub fold_input_alignment_constrained {
  my ($aln,$constr) = @_;
  my %foldin = ();
  my @pt = make_pair_table($constr);
  my $input_AlignIO = Bio::AlignIO->new(-file => $alifile,
				      -format => 'ClustalW'
				     );
  my $input_aln = $input_AlignIO->next_aln;
  foreach my $element ($input_aln->each_seq) {
    my @gappos = ();
    my $cons=$constr;
    my $gseq = $element->seq;
    my $id = $element->display_id;
    if (length($constraint) != length($gseq)){
      print STDERR "ERROR: constraint length does not match alignment length ...\n$constraint \n $gseq";
      croak();
    }
    print STDERR "\n>$id\n";
    print STDERR "$gseq\n";
    for (my $p=0; $p<length($gseq);$p++) {
      # remove non-compatible pairs as well as pairs to a gap position
      my $c = substr($gseq,$p,1);
      if ($c eq '-') {
	push @gappos, $p;
	substr($cons,$p,1) = 'x'; # mark for removal
	substr($cons,$pt[$p],1) = '.'
	  if $pt[$p]>0  && substr($cons,$pt[$p],1) ne 'x';   # open pair
      }
      elsif ($pt[$p]>$p) {
	substr($cons,$p,1) = substr($cons,$pt[$p],1) = '.'
	  unless exists $pair{$c . substr($gseq,$pt[$p],1)};
      }
    } # end for

    print STDERR "$cons\n$gseq\n";
    # print STDERR length($seq), length($cons), "\n";
    $cons =~ s/x//g;
    my $seq = $gseq;
    $seq  =~ s/-//g;
    print STDERR "$cons\n$seq\n";

    # do constraint folding
    $RNA::fold_constrained = 1;
    my ($css,$cmfe) =  RNA::fold($seq, $cons);
    print STDERR "$css\t$cmfe\n";
    $RNA::fold_constrained = 0;

    # re-insert gaps into constraint-folded strcuture
    my $gcss = $css;
    for (my $i=0;$i<=$#gappos;$i++){
      my $gaps_inserted = 0;
      substr($gcss,$gappos[$i]+$gaps_inserted,0) = ".";
      $gaps_inserted++;
    }
    print "$gcss\n";
    print STDERR join ",", @gappos,"\n";

    unless (exists($foldin{$element->display_id})){
      $foldin{$element->display_id} = {
				       gseq => $gseq,
				       seq => $seq,
				       ss => $css,
				       gss =>$gcss,
				       mfe => $cmfe,
				      }
    }
    else{
      croak "ERROR: duplicate sequence identifier in input: ".$element->display_id;
    }
    print STDERR Dumper( $foldin{$element->display_id} );
    print STDERR "---\n";
  }
  return \%foldin;
}

sub make_pair_table {
   #indices start at 0 in this version!
  my $structure = shift;
  print ">>$structure<<\n";
   my (@olist, @table);
   my ($hx,$i) = (0,0);

   foreach my $c (split(//,$structure)) {
       if ($c eq '.') {
	  $table[$i]= -1;
     } elsif ($c eq '(') {
	  $olist[$hx++]=$i;
     } elsif ($c eq ')') {
	 my $j = $olist[--$hx];
	 die ("unbalanced brackets in make_pair_table") if ($hx<0);
	 $table[$i]=$j;
	 $table[$j]=$i;
     }
      $i++;
   }
   carp ("too few closed brackets in make_pair_table") if ($hx!=0);
   return @table;
}


__END__

=head1 NAME

RNAalisplit - Split and decompose RNA multiple sequence alignments

=head1 SYNOPSIS

RNAalisplit.pl [--aln|-a I<FILE>] [--method|-m I<OPTION>] [options]

=head1 DESCRIPTION

This tool splits multiple sequence alignments horizontally, thereby
extracting sets of sequences that group together according to a
decision value. The most natural decision value is the RNAz SVM
RNA-classs probability.

A neighbour joining tree is reconstructed from pairwise distances of
sequences in the input alignment and subsets of the alignment are
derived by splitting at each edge of the NJ tree as well as performing
a split decomposition of the matrix of pairwise distances. These
subsets/subalignments are then evaluated according to the same
decision value and a decision is made whether a subalignment performs
better than the original alignment.This can be used to discriminate
sequences that to not 'fit' in the input alignment.

Output is written to STDOUT and a directory containing all temporary
RNAalifold / RNAz / R-scape output files is created. Inside this
directory, the 'phylip.dst' file contains the distance matrix computed
from pairwise distances. It can be visualized e.g. with SplitsTree.

=head1 OPTIONS

=over

=item B<--aln|-a>

A multiple sequence alignment in ClustalW format

=item B<--constraint|-c>

Constraint structure, overriding the consensus structure of the
underlying alignment in case  B<--method|-m dBc> is selected.

=item B<--method|-m>

Method to compute pairwise ditances. Available options are 'dHn',
'dHx', 'dBp', 'dBc, 'dHB', and 'SCI'. The first and second compute
pairwise Hamming distances of sequences, where 'dHn' replaces gaps
with 'N', whereas 'dHx' removes all gap columns (not yet
implemented). 'dBp' folds RNA sequences into their MFE structures and
computes pairwise base pair distances. 'dBc' computes base pair
distances on constraint-folded RNA sequences. Here, the default is to
use the consensus structure of the underlying alignment as a
constraint, however, an alternative constraint structure can be
provided via the B<--constraint> option. 'SCI' computes the distance
as 1-log(SCI), based on a truncated strucure conservation index of two
sequences. The latter, however, is not a metric and therefore often
results in negative branch lengths in Neighbor Joining trees. Use with
caution. [default: 'dHn']

=item B<--noribosum>

Turn off ribosum scoring for RNAalifold computation. Default: ribosum
scoring on

=item B<--rscapestat>

R-scape covariation statistic. Allowed values are: 'GT', 'MI', 'MIr',
'MIg', 'CHI', 'OMES', 'RAF', 'RAFS'. Appending either 'p' or 'a' to
any of them calculates its average product correction and average sum
correction, respctively (e.g. GTp or GTa). See the R-scape manual for
details.

=item B<--out|-o>

Output base directory. Temporary data and results will be written to
this directory

=item B<--version>

Show RNAalisplit version and exit

=back

=head1 AUTHOR

Michael T. Wolfinger E<lt>michael@wolfinger.euE<gt> and
E<lt>michael.wolfinger@univie.ac.atE<gt>

=cut
(END)
