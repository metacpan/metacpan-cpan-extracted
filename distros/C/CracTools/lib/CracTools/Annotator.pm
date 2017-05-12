package CracTools::Annotator;
{
  $CracTools::Annotator::DIST = 'CracTools';
}
# ABSTRACT: Generic annotation base on CracTools::GFF::Query::File
$CracTools::Annotator::VERSION = '1.25';
use strict;
use warnings;

use Carp;
use List::Util qw[min max];

use CracTools::Const;
use CracTools::GFF::Annotation;
use CracTools::Interval::Query;
use CracTools::Interval::Query::File;


sub new {
  my $class = shift;
  my $gff_file = shift;
  my $mode = shift;

  $mode = 'light' if !defined $mode;

  if(!defined $gff_file) {
    croak "Missing GFF file argument in CracTools::Annotator constructor";
  }

  my $self = bless {
    gff_file => $gff_file,
    mode => $mode,
  }, $class;

  $self->_init();

  return $self;
}


sub mode {
  my $self = shift;
  return $self->{mode};
}


sub foundAnnotation {
  my $self = shift;
  #my ($chr,$pos_start,$pos_end,$strand) = @_;
  my @candidates = @{ $self->getAnnotationCandidates(@_)};
  return (scalar @candidates > 0);
}


sub foundGene {
  my $self = shift;
  my ($chr,$pos_start,$pos_end,$strand) = @_;
  my @candidates = @{ $self->getAnnotationCandidates($chr,$pos_start,$pos_end,$strand)};
  foreach my $candidate (@candidates) {
    return 1 if defined $candidate->{gene};
  }
  return 0;
}


sub foundSameGene {
  my $self = shift;
  my ($chr,$pos_start1,$pos_end1,$pos_start2,$pos_end2,$strand) = @_;
  my @candidates1 = @{ $self->getAnnotationCandidates($chr,$pos_start1,$pos_end1,$strand)};
  my @candidates2 = @{ $self->getAnnotationCandidates($chr,$pos_start2,$pos_end2,$strand)};
  my $found_same_gene = 0;
  my @genes1;
  my @genes2;
  foreach my $candi1 (@candidates1) {
    if(defined $candi1->{gene}) {
      push @genes1,$candi1->{gene}->attribute('ID');
    }
  }
  foreach my $candi2 (@candidates2) {
    if(defined $candi2->{gene}) {
      push @genes2,$candi2->{gene}->attribute('ID');
    }
  }
  foreach my $gene_id (@genes1) {
    foreach (@genes2) {
      if($gene_id eq $_) {
        $found_same_gene = 1;
        last;
      }
    }
    last if $found_same_gene == 1;
  }
  return $found_same_gene;
}


sub getBestAnnotationCandidate {
  my $self = shift;
  my ($best_candidates,$best_priority,$best_type) = $self->getBestAnnotationCandidates(@_);
  if(@{$best_candidates}) {
    return $best_candidates->[0],$best_priority,$best_type;
  } else {
    return undef,undef,undef;
  }
}


sub getBestAnnotationCandidates {
  my $self = shift;
  my ($chr,$pos_start,$pos_end,$strand,$prioritySub,$compareSub) = @_;

  if(!defined $prioritySub && !defined $compareSub) {
    $prioritySub = \&getCandidatePriorityDefault unless defined $prioritySub;
    $compareSub = \&compareTwoCandidatesDefault unless defined $compareSub;
  }

  my @candidates = @{ $self->getAnnotationCandidates($chr,$pos_start,$pos_end,$strand)};
  my @best_candidates;
  my ($best_priority,$best_type);
  foreach my $candi (@candidates) {
    my ($priority,$type);
    ($priority,$type) = $prioritySub->($pos_start,$pos_end,$candi) if defined $prioritySub;
    if(defined $priority && $priority != -1) {
      if(!defined $best_priority) {
        $best_priority = $priority;
        push @best_candidates, $candi;
        $best_type = $type;
      } elsif($priority < $best_priority) {
        @best_candidates = ($candi);
        $best_priority = $priority;
        $best_type = $type;
      }
      #we should compare two candidates with equal priority to always choose the one
      elsif (!defined $priority || $priority == $best_priority){
        my $candidate_chosen;
        my $found_better_candidate = 0;
        foreach my $best_candidate (@best_candidates) {
          $candidate_chosen = $compareSub->($best_candidate,$candi,$pos_start,$pos_end) if defined $compareSub;
          # They are both equal
          if (!defined $candidate_chosen) {
            # We cannnot say if this candidate is better
            next;
          } elsif ($candidate_chosen == $candi) {
            # We have found a better candidate that previously register ones
            # we save it and remove the others
            @best_candidates = ($candi);
            $found_better_candidate = 1;
            last;
          } else {
            # The better candidate is not "candi", so this candidates
            # does not belong the the best_candidate array.
            # We can stop looping
            $found_better_candidate = 1;
            last;
          }
        }
        push @best_candidates, $candi if !$found_better_candidate;
      }
    }
  }
  # TODO We should not return variable in that order,
  # it is not easy to only retrieve the best candidatse...
  return \@best_candidates,$best_priority,$best_type;
}


sub getAnnotationCandidates {
  my $self = shift;
  my ($chr,$pos_start,$pos_end,$strand) = @_;
  # TODO if no strand is provided we should return annotations from both strands

  # get GFF annotations that overlap the region to annotate
  my $annotations = $self->{gff_query}->fetchByRegion($chr,$pos_start,$pos_end,$strand);
  # get a ref of an array of hash of candidates
  my $candidatates = $self->_constructCandidatesFromAnnotation($annotations);
  return $candidatates;
}


sub getAnnotationNearestDownCandidates {
  my $self = shift;
  my ($chr,$pos_start,$strand) = @_;

  # get GFF annotations that overlap the pos_start to annotate
  my $annotations_overlap = $self->{gff_query}->fetchByLocation($chr,$pos_start,$strand);
  # get GFF annotations of nearest down intervals that not overlaped [pos_start,pos_end] pos 
  my @annotations_down;

  push @annotations_down, @{$self->{gff_query}->fetchAllNearestDown($chr,$pos_start,$strand)};

  # get a ref of an array of hash of candidates
  my @annotations = (@$annotations_overlap,@annotations_down);
  my $candidatates = $self->_constructCandidatesFromAnnotation(\@annotations);
  return $candidatates;
}


sub getAnnotationNearestUpCandidates {
  my $self = shift;
  my ($chr,$pos_end,$strand) = @_;

  # get GFF annotations that overlap the pos_end to annotate
  my $annotations_overlap = $self->{gff_query}->fetchByLocation($chr,$pos_end,$strand);
  # get GFF annotations of nearest up intervals that not overlaped [pos_start,pos_end] pos 
  my @annotations_up;

  push @annotations_up, @{$self->{gff_query}->fetchAllNearestUp($chr,$pos_end,$strand)};

  # get a ref of an array of hash of candidates
  my @annotations = (@$annotations_overlap,@annotations_up);
  my $candidatates = $self->_constructCandidatesFromAnnotation(\@annotations);
  return $candidatates;
}


sub getCandidatePriorityDefault {
  my ($pos_start,$pos_end,$candidate) = @_;
  my ($priority,$type) = (-1,'');
  my ($mRNA,$exon) = ($candidate->{mRNA},$candidate->{exon});
  if(defined $mRNA) {
    if(defined $mRNA->attribute('type') && $mRNA->attribute('type') =~ /protein_coding/i) {
      if(defined $exon) {
        if(($exon->start <= $pos_start) && ($exon->end >= $pos_end)) {
          $priority = 1;
          if(defined $candidate->{three}) {
            $type = '3PRIM_UTR';
          } elsif(defined $candidate->{five}) {
            $type = '5PRIM_UTR';
          # } elsif(defined $candidate->{cds}) {
          #   $type = 'CDS';
          } else {
            $type = 'EXON';
          }
        } else {
          $priority = 2;
          $type = 'INXON';
        }
      } else {
        $priority = 4;
        $type = 'INTRON';
      }
    } else {
      if(defined $exon) {
        if(($exon->start <= $pos_start) && ($exon->end >= $pos_end)) {
          $priority = 3;
          $type = 'NON_CODING';
        }
      }
    }
  }
  return ($priority,$type);
}

sub compareTwoCandidatesDefault{
  my ($candidate1,$candidate2,$pos_start) = @_;
  # If both candidates are exons we try to find wich one is closer to the pos_start of the region to annotate
  if ($candidate1->{exon} && $candidate2->{exon}) { 
    my $dist1= min(abs($candidate1->{exon}->end - $pos_start),abs($candidate1->{exon}->start - $pos_start));
    my $dist2= min(abs($candidate2->{exon}->end - $pos_start),abs($candidate2->{exon}->start - $pos_start));
    if ($dist1 > $dist2) {
      return $candidate2;
    } elsif ($dist1 < $dist2) {
      return $candidate1;
    }
  }
  # If we have not found a better candidate, we use the lexicographic order of the mRNA ID
  my ($mRNA1,$mRNA2) = ($candidate1->{mRNA},$candidate2->{mRNA});
  if(defined $mRNA1 && defined $mRNA1->attribute('ID') && defined $mRNA2 && defined $mRNA2->attribute('ID')) {
    if($mRNA1->attribute('ID') lt $mRNA2->attribute('ID')) {
      return $candidate1;
    } else {
      return $candidate2;
    }
  }
  # If nothing has worked we return "undef"
  return undef;
}


sub _init {
  my $self = shift;
  my $gff_query;

  # Create a GFF file to query exons
  if($self->mode eq "fast") {
    $gff_query = CracTools::Interval::Query->new();
    my $gff_it = CracTools::Utils::getFileIterator(file => $self->{gff_file},
      parsing_method => sub { CracTools::GFF::Annotation->new(@_) },
      header_regex => "^#",
    );
    while(my $gff_annot = $gff_it->()) {
      $gff_query->addInterval($gff_annot->chr,
        $gff_annot->start+1,
        $gff_annot->end+1,
        $gff_annot->strand,
        $gff_annot,
      );
    }
  } else {
    $gff_query = CracTools::Interval::Query::File->new(file => $self->{gff_file}, type => 'gff');
  }

  $self->{gff_query} = $gff_query;
}


sub _constructCandidates {
  my ($annot_id,$candidate,$annot_hash) = @_;

  # We init the "leaf_feature" value if this is the first recursion step
  $candidate->{leaf_feature} = $annot_hash->{$annot_id}->feature if !defined $candidate->{leaf_feature};

  my @candidates;
  if (!defined $annot_hash->{$annot_id}){
      carp("Missing feature for $annot_id in the gff file");
  }
  $candidate->{$annot_hash->{$annot_id}->feature} = $annot_hash->{$annot_id};
  my $parents = $annot_hash->{$annot_id}->parents;
  if(@$parents) {
    foreach my $parent (@{$parents}) {
      
      #Test to avoid a deep recursion
      if($parent eq $annot_id) {
  carp("Parent could not be the candidat itself, please check your gff file for $annot_id");
  next;
      # If there is already a parent with this feature type we duplicated
      # the candidate since we are branching in the annotation tree
      }elsif(!defined $annot_hash->{$parent}) {
        carp("Parent not found, please check your gff file for $annot_id (Parent: $parent)");
      
      }elsif(defined $candidate->{$annot_hash->{$parent}->feature}) {
        my %copy_candidate = %{$candidate}; 
        my %copy_parent_feature = %{$candidate->{parent_feature}};
        $copy_candidate{parent_feature} = \%copy_parent_feature; 
        # We register in parent_feature links
        $copy_candidate{parent_feature}->{$annot_hash->{$annot_id}->feature} = $annot_hash->{$parent}->feature;
        my $copy_ref = \%copy_candidate;
        push(@candidates,@{_constructCandidates($parent,$copy_ref,$annot_hash)});
      # If not we only go up to the parent node in order to continue candidate
      # construction
      } else {
        # We register in parent_feature links
        $candidate->{parent_feature}->{$annot_hash->{$annot_id}->feature} = $annot_hash->{$parent}->feature;
        push(@candidates,@{_constructCandidates($parent,$candidate,$annot_hash)});
      }
    }
    return \@candidates;
  } else {
    return [$candidate];
  }
}


sub _constructCandidatesFromAnnotation {
  my $self = shift;
  my $annotations = shift;
  my %annot_hash = ();
  my @candidates = ();

  # Construct annotation hash with annot ID as key
  foreach my $annot_line (@{$annotations}) {
    if($self->mode eq "fast") {
      $annot_hash{$annot_line->attribute('ID')} = $annot_line;
    } else {
      my $annot = CracTools::GFF::Annotation->new($annot_line,'gff3');
      $annot_hash{$annot->attribute('ID')} = $annot;
    }
  }

  # Find leaves in annotation tree
  my %hash_leaves; 
  foreach my $annot_id (keys %annot_hash) {
    #my @parents = $annot_hash{$annot_id}->parents;
    foreach my $parent (@{$annot_hash{$annot_id}->parents}){
      $hash_leaves{$parent} = 1 unless (defined $hash_leaves{$parent});
    }
  }
  foreach my $annot_id (keys %annot_hash) {
    # check if annot_id is a leaf
    if (!defined $hash_leaves{$annot_id}){
      # Get all possible path from this leaf to the root
      push @candidates, @{_constructCandidates($annot_id,my $new_candidate,\%annot_hash)};
    }
  }

  return \@candidates;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CracTools::Annotator - Generic annotation base on CracTools::GFF::Query::File

=head1 VERSION

version 1.25

=head1 SYNOPSIS

  # Construct tha annotator object that will index the GFF file in
  # a genomic interal-tree based structure
  my $annotator = CracTools::Annotator->new("annotation.gff");

  # Query the annotator object for overlapping annotations
  my $annot = $annotator->getBestAnnotationCandidate("chr1",12345,12380);

  if(defined $annot->{exon}) {
    print STDERR "Found overlapping exon\n";
  } else {
    # If no overlapping exons have been found, we check for the closest gene
    # in the downstream direction
    my $closest_annot = $annotator->getAnnotationNearestDownCandidates()->[0];
    if(defined $closest_annot && defined $closest_annot->{gene}) {
      print STDERR "Closest gene annotation is ".12345 - $closest_annot->{gene}->end."bp away\n";
    }
  }

=head1 DESCRIPTION

This module is based on L<CracTools::Interval::Query::File> and provides powerfull
methods to query annotation files and prioritize hits to fit specific
application needs.

Annotator work with 0-based coordinate system and closed [a,b] intervals.

The principle behind L<CracTools::Annotator> is to build a genomic interval
tree that holds the annotations. Then, the user can query this datastructure to
retrieve annotations. In order to organized the retrieved annotations, we
build candidates hashes that are a branch of the annotation tree. For a classic
GFF annotation file, if the queried interval overlap and exon, the branch of the
annotation tree, will go from an exon leaf up to the gene root passing by an mRNA internal node.

=head2 Candidate structure

An annotation candidate is a hash datastructure, where keys are GFF features (exon, gene, mRNA)
and values are L<CracTools::GFF::Annotation> object (a parsed GFF line).

It also contains an entry C<parent_feature> that holds the parenting links
between features, and an entry C<leaf_feature> that holds the feature name of
the leaf ("exon" for example).

  my $candidate = {
    "exon" => CracTools::GFF::Annotation, 
    "gene" => CracTools::GFF::Annotation,
    "feature" => CracTools::GFF::Annotation, ..., 
    parent_feature => {exon => mRNA, featureA => featureB, ...},
    leaf_feature => "exon",
  };

=head2 Priority methods

Each annotation query can be parametrized with priorization methods that will
choose a set of "best" annotation(s) to be returned to the user. In this module
we propose default priorization method, but you can create your own in order to 
fit your application needs.

There is two kind of priorization method, C<prioritySub> and C<comparSub>.

=head3 Priority subroutine

The priority subroutine (by default L</"getCandidatePriorityDefault">) recieve
as input the queried interval (start and end pos) and an annotation candidate.
As output the subroutine must return a priority level (the lower being more
important), and a string variable that is a literal version of the priority
level.

=head3 Compare subroutine

The compare subroutine (by default L</"compareTwoCandidatesDefault">) recieve as
input two annotation candidates and the queried interval.
As output the subroutine must return the best candidate between the two, or
neither (undef) if the subroutine cannot determine.

=head1 METHODS

=head2 new

  Arg [1] : String - $gff_file
            GFF file used to perform annotation
  Arg [2] : String - $mode
            Execution mode : "fast" or "light" ("light" by default)

  Example     : my $annotator = CracTools::GFF::Annotator->new($gff_file);
  Description : Create a new CracTools::GFF::Annotator object based on the
                provided GFF file. If "light" mode is specified, CracTools::Annotator
                will be less memory consuming but will have a time execution overhead.
  ReturnType  : CracTools::GFF::Annotator

=head2 mode 

  Description : Return the mode used to create the annotator
  ReturnType  : string ("light" or "fast")

=head2 foundAnnotation

  Arg [1] : String - chr
  Arg [2] : String - pos_start
  Arg [3] : String - pos_end
  Arg [4] : String - strand

  Description : Return true if any overlapping annotation has been found
  ReturnType  : Boolean

=head2 foundGene

  Arg [1] : String - chr
  Arg [2] : String - pos_start
  Arg [3] : String - pos_end
  Arg [4] : String - strand

  Description : Return true if an overlapping gene annotation has been found
  ReturnType  : Boolean

=head2 foundSameGene

  Arg [1] : String - chr
  Arg [2] : String - pos_start1
  Arg [3] : String - pos_end1
  Arg [4] : String - pos_start2
  Arg [5] : String - pos_end1
  Arg [6] : String - strand

  Description : Return true if a same gene overlaps the two intervals.
  ReturnType  : Boolean

=head2 getBestAnnotationCandidate

  Arg [1] : String - chr
  Arg [2] : String - pos_start
  Arg [3] : String - pos_end
  Arg [4] : String - strand
  Arg [5] : (Optional) Subroutine - see C<getCandidatePriorityDefault> for more details
  Arg [6] : (Optional) Subroutine - see C<compareTwoCandidatesDefault> for more details

  Description : Return best annotation candidate according to the priorities given
                by the subroutine(s) in argument.
  ReturnType  : AnnotationCandidate, Int(priority), String(type)

=head2 getBestAnnotationCandidates

  Arg [1] : String - chr
  Arg [2] : String - pos_start
  Arg [3] : String - pos_end
  Arg [4] : String - strand
  Arg [5] : (Optional) Subroutine - see C<getCandidatePriorityDefault> for more details
  Arg [6] : (Optional) Subroutine - see C<compareTwoCandidatesDefault> for more details

  Description : Return best annotation candidates according to the priorities given
                by the subroutine(s) in argument.
  ReturnType  : ArrayRef of AnnotationCandidates, Int(priority), String(type)

=head2 getAnnotationCandidates

  Arg [1] : String - chr
  Arg [2] : String - pos_start
  Arg [3] : String - pos_end
  Arg [4] : String - strand

  Description : Return an array with all annotation candidates overlapping the
                chromosomic region.
  ReturnType  : ArrayRef of AnnotationCandidate

=head2 getAnnotationNearestDownCandidates

  Arg [1] : String - chr
  Arg [2] : String - pos_start
  Arg [3] : String - strand

  Description : Return an array with all annotation candidates nearest down the
                query region (without overlap).
  ReturnType  : ArrayRef of AnnotationCandidate

=head2 getAnnotationNearestUpCandidates

  Arg [1] : String - chr
  Arg [2] : String - pos_end
  Arg [3] : String - strand

  Description : Return an array with all annotation candidates nearest up the
                query region (without overlap).
  ReturnType  : ArrayRef of AnnotationCandidate

=head2 getCandidatePriorityDefault

  Arg [1] : String - pos_start
  Arg [2] : String - pos_end
  Arg [3] : hash - candidate

  Description : Default method used to give a priority to a candidate.
                You can create your own priority method to fit your specific need
                for selecting the best annotation.
                The best priority is 0. A priority of -1 means that this candidate
                should be avoided.
  ReturnType  : Array($priority,$type) where $priority is an integer and $type a string

=head2 compareTwoCandidatesDefault

  Arg [1] : hash - candidate1
  Arg [2] : hash - candidate2
  Arg [3] : pos_start (position start that has been queried)
  Arg [4] : pos_end (position end that has been queried)

  Description : Default method used to chose the best candidat when priority are equals
                You can create your own priority method to fit your specific need
                for selecting the best candidat.
  ReturnType  : AnnotationCandidate - best candidate or undef if we cannot decide which candidate is the best

=head1 PRIVATE METHODS

=head2 _init

  Description : init method, load GFF annotation into a
                CracTools::GFF::Query object.

=head2 _constructCandidates

  Arg [1] : String - annot_id
  Arg [2] : Hash ref - candidate
            Since this method is recursive, this is the object that
            we are constructing
  Arg [3] : Hash ref - annot_hash
            annot_hash is a hash reference where keys are annotion IDs
            and values are CracTools::GFF::Annotation objects.

  Description : _constructCandidate is a recursive method that build a
                candidate hash. A candidate is defined as a path into the annotation
                (multi-rooted) tree from a leaf (ex: an exon) to a root (ex: a gene).
  ReturnType  : Candidate Hash ref where keys are GFF features and
                values are CracTools::GFF::Annotation objects :
                { "exon" => CracTools::GFF::Annotation, 
                  "gene" => CracTools::GFF::Annotation,
                  feature => CracTools::GFF::Annotation, ..., 
                  parent_feature => {featureA => featureB},
                  leaf_feature => "exon",
                }

=head2 _constructCandidatesFromAnnotation

  Arg [1] : Hash ref - annotations
            Annotions is a hash reference where keys are coordinates
            given by CracTools::Interval::Query::File objects.
  Description : _constructCandidate is a recursive method that build a
                candidate hash.
  ReturnType  : Candidate array ref of all candidates built by _constructCandidate

=head1 AUTHORS

=over 4

=item *

Nicolas PHILIPPE <nphilippe.research@gmail.com>

=item *

Jérôme AUDOUX <jaudoux@cpan.org>

=item *

Sacha BEAUMEUNIER <sacha.beaumeunier@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by IRMB/INSERM (Institute for Regenerative Medecine and Biotherapy / Institut National de la Santé et de la Recherche Médicale) and AxLR/SATT (Lanquedoc Roussilon / Societe d'Acceleration de Transfert de Technologie).

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut
