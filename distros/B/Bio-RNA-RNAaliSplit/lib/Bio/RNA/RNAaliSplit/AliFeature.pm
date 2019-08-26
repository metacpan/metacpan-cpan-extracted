# -*-CPerl-*-
# Last changed Time-stamp: <2019-04-24 00:47:47 mtw>
#
#  Derive features of an alignment, in particular scores to compare
#  different alignments of the same sequences

package Bio::RNA::RNAaliSplit::AliFeature;

use Moose;
use namespace::autoclean;
use version; our $VERSION = qv('0.11');
use diagnostics;
use Data::Dumper;
use Carp;

extends 'Bio::RNA::RNAaliSplit::AliHandler';

has 'sop' => ( # sum of pairs score
	      is => 'rw',
	      isa => 'Int',
	      predicate => 'has_sSOP',
	      init_arg => undef,
	     );

has '_csp' => ( # column sequence positions
	      is => 'ro', # read-only
	      isa => 'ArrayRef',
	      predicate => 'has_sCSP',
	      init_arg => undef,
	      writer => '_cspwriter', # private writer
	      );

has 'csp_hash' => (
		   is => 'ro',
		   isa => 'HashRef',
		   predicate => 'hash_csp_hash',
		   init_arg => undef,
		   writer => '_csp_hash_writer', # private writer 4 ro attribute
		  );

with 'FileDirUtil';

sub BUILD {
  my $self = shift;
   my $this_function = (caller(0))[3];
  confess "ERROR [$this_function] \$self->ifile not available"
    unless ($self->has_ifile);
  $self->alignment({-file => $self->ifile,
		    -format => $self->format,
		    -displayname_flat => 1} ); # discard position in sequence IDs
  $self->next_aln($self->alignment->next_aln);
  $self->next_aln->set_displayname_safe();
  $self->_get_alen();
  $self->_get_nrseq();
  $self->set_ifilebn;

  # compute sum of pairs score
  #$self->compute_sop();
  # compute sequence position for each column
  $self->_get_column_sequence_positions();
  # compute CSP hash
  $self->_csp_hash();
}

# Compute Sum of Pairs scoring for an alignment
sub compute_sop {
  my $self = shift;
  # print "### in ccompute_sop###\n";
  my @alignment=();
  my $sp=0;
  for (my $i=1;$i<=$self->nrseq;$i++){
    push @alignment, $self->next_aln->get_seq_by_pos($i)->seq;
  }
  # print Dumper (\@alignment);

  for (my $c=0;$c<eval($self->alen);$c++){ # loop over alignment columns
    my $colscore=0;
    # print "$c\n";

    for (my $i=0;$i<eval($self->nrseq);$i++){
      for (my $j=$i+1;$j<eval($self->nrseq);$j++){
 	my $ci = substr($alignment[$i],$c,1);
	my $cj = substr($alignment[$j],$c,1);
	if (1) { # if ($self->distancemeasure eq "e"){ # edit distance
 	  if ($ci ne $cj) {$colscore += 1}
 	}
 	# print " > $ci$i $cj$j $colscore <\n";
      } # end for j
    } # end for i
    # print " > ---------- <\n";
    $sp += $colscore;
  } # end for c
  $self->sop($sp);
}


sub _get_column_sequence_positions {
  my $self = shift;
  my @loclist = ();
  foreach my $i( 1..$self->nrseq ) {
    my @ll=();
    my $seq = $self->next_aln->get_seq_by_pos($i);
    # print $seq->seq."\n";
    $ll[0] =  $self->alen;
    for (my $j=1;$j<=$self->alen;$j++){
      my $pos=0; #default
      my $loc = $seq->location_from_column($j);
      if (defined ($loc)){
	if($loc->location_type() eq 'EXACT'){
	  $pos = $loc->to_FTstring();
	}
	elsif ($loc->location_type() eq 'IN-BETWEEN'){
	  $pos = 0;
	}
	else { croak "ERROR: this should not happen\n".Dumper($loc); }
      }
      else {
	  $pos = 0; # TODO check me
      }
      # print Dumper($loc);
      $ll[$j]=$pos;
    } # end for
    push @loclist, \@ll;
  } # end foreach
  $self->_cspwriter(\@loclist);
}

sub _csp_hash {
  my $self = shift;
  my %csp = ();
  for (my $j=1;$j<=$self->alen;$j++) { # loop over columns
    my $pstring;
    for (my $i=0;$i<$self->nrseq;$i++){ # loop over sequences
      $pstring .= eval(${$self->_csp}[$i]->[$j]).":";
    }
    #print ">> $pstring <<\n";
    unless (defined $csp{$pstring}){ $csp{$pstring}=1;}
    else {$csp{$pstring}+=1;}
  }
  $self->_csp_hash_writer(\%csp);
}


#sub _get_alen {
#  my $self = shift;
#  $self->alen($self->next_aln->length());
#}

#sub _get_nrseq {
#  my $self = shift;
#  $self->nrseq($self->next_aln->num_sequences());
#}

no Moose;

1;

__END__
