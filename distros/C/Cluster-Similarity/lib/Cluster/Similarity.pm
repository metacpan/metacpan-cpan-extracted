package Cluster::Similarity;


use English;
use warnings;
use strict;
use Carp;

use Math::Combinatorics;
use List::Util qw(sum min);

use Class::Std;

=head1 NAME

Cluster::Similarity - compute the similarity of two classifications.

=head1 VERSION

Version 0.02

=cut

use version; our $VERSION = qv('0.02');


=head1 SYNOPSIS

Compute similarity of two classifications following various cluster similarity evaluation schemes based on contingency tables.


    use Cluster::Similarity;


    my $sim_calculator = Cluster::Similarity->new( $classification_1, $classification_2 );


    my $pair_wise_recall = $sim_calculator->pair_wise_recall();
    my $pair_wise_precision = $sim_calculator->pair_wise_precision();
    my $pair_wise_f_score = $sim_calculator->pair_wise_fscore();

    my $mutual_information = $sim_calculator->mutual_information();
    
    my $rand_index = $sim_calculator->rand_index();

    my $rand_adj = $sim_calculator->rand_adjusted($max_index);
    
    my $matching = $sim_calculator->matching_index();


    my $contingency_table = $sim_calculator->contingency();
    
    my $pairs_matrix = $sim_calculator->pairs_matrix();

    my $pair_of_cell_12 = $sim_calculator->pairs(1,2);


=head1 DESCRIPTION

Computes the similarity of two word clusterings using several
clustering similarity measures.

Consider for eg. the following groupings:

clustering_1: { {a, b, c}, {d, e, f} }
clustering_2: { {a, b}, {c, d, e}, {f} }

Cluster similarity measures provide a numerical value helping to
assess the alikeness of two such groupings.

All cluster similarity measures implemented in this module are based
on the so-called contingency table of the two classifications
(clusterings). The contingency table is a matrix with a cell for each
pair of classes (one from each classification), containing the number
of objects present in both classes.

The similarity measures (and also examples and tests) are taken from
Chapter 4 of Susanne Schulte im Walde's Phd thesis:

Sabine Schulte im Walde. Experiments on the Automatic Induction of
German Semantic Verb Classes. PhD thesis, Institut für Maschinelle
Sprachverarbeitung, Universität Stuttgart, 2003. Published as AIMS
Report 9(2) L<http://www.schulteimwalde.de/phd-thesis.html>

Please see there for a more in depth description of the similarity
measures and further details.

=head1 INTERFACE

=head2 Constructor

=over

=item new()

Builds a new Cluster::Similarity object.

=back

=cut

{

  ############ Data ######################################################################

  my %classification1_of : ATTR( :get<classification_1> ); # hash of hashes 
  my %classification2_of : ATTR( :get<classification_2> ); # hash of hashes

  my %contingency_of : ATTR( :get<contingency_table> );
  my %pairs_contingency_of : ATTR( :get<pairs_contingency_table> );
  my %object_nbr_of : ATTR;
  my %objects_of : ATTR;

  my %tp_of : ATTR( :get<true_positives> );
  my %pairs_classification_1_of : ATTR;
  my %pairs_classification_2_of : ATTR;
  my %pair_wise_precision_of : ATTR;
  my %pair_wise_recall_of : ATTR;
  my %pair_wise_fscore_of : ATTR;

  my %mutual_information_of : ATTR;
  
  my %rand_index_of : ATTR;

  my %rand_index_adj_of : ATTR;

  my %matching_index_of : ATTR;

  ############ Utility subroutines #######################################################

  sub _check_dataset {
    my ($dataset_ref) = @_;

    croak "Need reference to classification\n"
      unless ($dataset_ref);


    if (ref($dataset_ref) eq 'ARRAY') {
      return { map { my $index = $_+1; "c_$index" => $dataset_ref->[$_] } 0 .. $#{ $dataset_ref } };
    } elsif (ref($dataset_ref) eq 'HASH') {
      return $dataset_ref;
    } else { 
      croak "Classifications must be passed as array or hash references\n";
    }
    return;

  }

  sub _reset_dependant_datastructures {
    my ($id) = @_;

    delete $contingency_of{$id};
    delete $pairs_contingency_of{$id};
    delete $object_nbr_of{$id};
    delete $objects_of{$id};
    delete $tp_of{$id};
    delete $pairs_classification_1_of{$id};
    delete $pairs_classification_2_of{$id};
    delete $pair_wise_precision_of{$id};
    delete $pair_wise_recall_of{$id};
    delete $pair_wise_fscore_of{$id};
    delete $mutual_information_of{$id};
    delete $rand_index_of{$id};
    delete $rand_index_adj_of{$id};
    delete $matching_index_of{$id};

    return;
  }


  sub _nC2 {
    my ($n) = @_;

    if ($n < 0) { return; }

    return $n * ($n - 1) / 2;
  }

  sub _pairs_in_classification {
    my ($class_ref) = @_;

    my %pairs; 
    foreach my $cluster (values %{ $class_ref }) {
      my @comb = combine(2, keys %{ $cluster });
      foreach my $pair (@comb) {
	$pairs{join(',', sort @{$pair})} = 1;
      }
    }

    return \%pairs;
  }


  # the sum of the cells of a matrix - represented by a hash of hashes.
  sub _cell_sum {
    my ($matrix) = @_;

    return sum map {values %{ $_ } } values %{ $matrix };
  }

  ############ Methods ###################################################################

=head1 FUNCTIONS

=head2 Providing the Data

=over

=item load_data(\@classification_1, \@classification_2)

=item load_data(\%classification_1, \%classification_2)

=cut
  
  sub load_data {
    my ($self, $class1_ref, $class2_ref) = @_;
    
    my $id = ident $self;
    
    $classification1_of{$id} = _check_dataset($class1_ref);
    $classification2_of{$id} = _check_dataset($class2_ref);
    
    _reset_dependant_datastructures($id);

    return;
  }


=item set_classification_1(\@classification_1), set_classification1(\@classification_2)

=cut



  sub set_classification_1 {
    my ($self, $class_ref) = @_;

    my $id = ident $self;

    $classification1_of{$id} = _check_dataset($class_ref);

    return;
  }


=item set_classification_2(\%classification_1), set_classification1(\%classification_2)


=back

When calling these methods, the contingency tables and all previously computed similarity values are reset. 

=cut

  sub set_classification_2 {
    my ($self, $class_ref) = @_;

    my $id = ident $self;

    $classification2_of{$id} = _check_dataset($class_ref);

    return;
  }

=head2 objects, object_number

Return (number of) objects in either classification

=cut

sub objects {
  my ($self) = @_;

  my $id = ident $self;

  croak "Please set/load classifications before calling objects method\n" unless ($classification1_of{$id} and $classification2_of{$id});
  
  if ($objects_of{$id}) {
    return $objects_of{$id};
  }

  my $objects;
  foreach my $cluster_ref (values %{ $classification1_of{$id} }, values %{ $classification2_of{$id} }) {
    foreach my $obj (keys %{ $cluster_ref }) {
      $objects->{$obj}++;
    }
  }

  $objects_of{$id} = $objects;
  $object_nbr_of{$id} = scalar(keys %{ $objects });

  return $objects;
}


sub object_number {
  my ($self) = @_;

  my $id = ident $self;

  croak "Please set/load classifications before calling object_number method\n" unless ($classification1_of{$id} and $classification2_of{$id});
  
  if ($object_nbr_of{$id}) {
    return $object_nbr_of{$id};
  }

  my $objects = $self->objects();

  $object_nbr_of{$id} = scalar(keys %{ $objects });

  return $object_nbr_of{$id};
}


=head2 contingency

Compute the contingency table for two classifications. The contingency table is a matrix with a cell for each pair of classes (one class from each classification). Each cell contains the number of objects present in both classes.

Eg. For the classifications

=over

=item 

 { {a, b, c}, {d, e, f} }

=item

 { {a, b}, {c, d, e}, {f} }

=back

the returned contingency table is:

 {
   'c_1' => {
	     'c_1' => 2,
	     'c_2' => 0
	    },
   'c_2' => {
	     'c_1' => 1,
	     'c_2' => 2
	    },
   'c_3' => {
	     'c_1' => 0,
	     'c_2' => 1
	    }
 }

Which is a hash representation of the matrix:

      2  0
      1  2
      0  1


with the columns indexed by the classes of the first classification and the rows by the classes of the second classification.


=cut

sub contingency {
  my ($self) = @_;

  my $id = ident $self;

  croak "Please set/load classifications before computing contingency table\n" unless ($classification1_of{$id} and $classification2_of{$id});

  if (exists $contingency_of{$id} and $contingency_of{$id}) {
    return $contingency_of{$id};
  }
  
  my $contingency;

  foreach my $row_cl (keys %{ $classification2_of{$id} }) {
    foreach my $col_cl (keys %{ $classification1_of{$id} }) {
      my %common;
      foreach my $cl_el (keys %{ $classification2_of{$id}->{$row_cl} }, keys %{ $classification1_of{$id}->{$col_cl} }) {
	$common{$cl_el}++;
      }
      $contingency->{$row_cl}->{$col_cl} = grep { $_ > 1 } values %common;
    }
  }

  $contingency_of{$id} = $contingency;

  return $contingency;
}

=head2 pairs_contingency

Compute the contingency table for the number of common element pairs in the two classifications.

For the example above this would be:

   1 0
   0 0
   0 1


=cut

sub pairs_contingency {
  my ($self) = @_;

  my $id = ident $self;

  croak "Please set/load classifications before computing contingency table\n" unless ($classification1_of{$id} and $classification2_of{$id});

  if (exists $pairs_contingency_of{$id} and $pairs_contingency_of{$id}) {
    return $pairs_contingency_of{$id};
  }
  

  my $contingency = $self->contingency();

  my $pairs_contingency;

  foreach my $row_cl (keys %{ $contingency }) {
    foreach my $col_cl (keys %{ $contingency->{$row_cl} }) {
      my $n = $contingency->{$row_cl}->{$col_cl};
      $pairs_contingency->{$row_cl}->{$col_cl} = _nC2($n);
    }
  }

  $pairs_contingency_of{$id} = $pairs_contingency;

  return $pairs_contingency;
}

=head2 true_positives

True positives are the number of object pairs which occur together in both classifications.

=cut

sub true_positives {
  my ($self) = @_;

  my $id = ident $self;

  croak "Please set/load classifications before true positives\n" unless ($classification1_of{$id} and $classification2_of{$id});

  if (exists $tp_of{$id}) {
    return $tp_of{$id};
  }

  my %pairs_1; 
  foreach my $cluster (values %{ $classification1_of{$id} }) {
    my @comb = combine(2, keys %{ $cluster });
    foreach my $pair (@comb) {
      $pairs_1{join(',', sort @{$pair})} = 1;
    }
  }


  my $tp = 0;
  foreach my $pair (keys %pairs_1) {
    my ($val1, $val2) = split(/,/, $pair);
    my $is_in_2 = grep { exists $_->{$val1} and exists $_->{$val2}} values %{ $classification2_of{$id} };
    if ($is_in_2) {
      $tp++;
    }
  }

  $tp_of{$id} = $tp;

  return $tp;

}


=head2 pairs_classification_1, pairs_classification_2

Number of pairs in classification.

=cut

sub pairs_classification_1 {
  my ($self) = @_;

  my $id = ident $self;

  croak ("Need data for classification 1\n") unless ($classification1_of{$id});

  if ($pairs_classification_1_of{$id}) {
    return $pairs_classification_1_of{$id};
  }

  my $pairs_ref = _pairs_in_classification($classification1_of{$id});


  my $pairs_nbr = scalar(keys %{ $pairs_ref });
  $pairs_classification_1_of{$id} = $pairs_nbr;

  return $pairs_nbr;
}

sub pairs_classification_2 {
  my ($self) = @_;

  my $id = ident $self;

  croak ("Need data for classification 2\n") unless ($classification2_of{$id});

  if ($pairs_classification_2_of{$id}) {
    return $pairs_classification_2_of{$id};
  }

  my $pairs_ref = _pairs_in_classification($classification2_of{$id});


  my $pairs_nbr = scalar(keys %{ $pairs_ref });
  $pairs_classification_2_of{$id} = $pairs_nbr;

  return $pairs_nbr;
}



=head2 pair_wise_precision, pair_wise_recall, pair_wise_fscore

Pair-wise recall is the number of true positives divided by the number of pairs in classification 1

Pair-wise precision is the number of true positives divided by the number of pairs in classification 2

Pair-wise F-score is the harmonic mean of precision and recall, i.e. 2*precision*recall / (precision + recall)

=cut

sub pair_wise_recall {
  my ($self) = @_;

  my $id = ident $self;

  if ($pair_wise_recall_of{$id}) {
    return $pair_wise_recall_of{$id};
  }

  my $tp = 0;
  $tp = $self->true_positives();
  my $pairs = $self->pairs_classification_1();
  
  if (not defined $pairs or $pairs == 0) {
    $pairs = 1;
  }

  my $recall = $tp/$pairs;

  $pair_wise_recall_of{$id} = $recall;

  return $recall;
}

sub pair_wise_precision {
  my ($self) = @_;

  my $id = ident $self;

  if ($pair_wise_precision_of{$id}) {
    return $pair_wise_precision_of{$id};
  }

  my $tp = $self->true_positives();
  my $pairs = $self->pairs_classification_2();
  
  if (not defined $pairs or $pairs == 0) {
    $pairs = 1;
  }
  
  my $precision = $tp/$pairs;

  $pair_wise_precision_of{$id} = $precision;

  return $precision;
}

sub pair_wise_fscore {
  my ($self) = @_; 

  my $id = ident $self;

  if ($pair_wise_fscore_of{$id}) {
    return $pair_wise_fscore_of{$id};
  }

  my $prec = $self->pair_wise_precision();
  my $recall = $self->pair_wise_recall();

  my $fscore = 0;
  
  if ($prec and $recall) {
    $fscore = 2*$prec*$recall/($prec+$recall);
  }

  $pair_wise_fscore_of{$id} = $fscore;

  return $fscore;
}

=head2 mutual_information

Mutual information is a symmetric measure for the degree of dependency between two classifications used here as introduced by Strehl et. al. (2000).

=cut

sub mutual_information {
  my ($self) = @_;

  my $id = ident $self;

  croak "Please set/load classifications before computing mutual information\n" unless ($classification1_of{$id} and $classification2_of{$id});

  if ($mutual_information_of{$id}) {
    return $mutual_information_of{$id};
  }

  my $contingency = $self->contingency();

  my $mi = 0;

  my @cluster1_names = keys %{ $classification1_of{$id} };
  my @cluster2_names = keys %{ $classification2_of{$id} };

  my %cluster1_sum;
  my %cluster2_sum;

  foreach my $cluster (@cluster2_names) {
    if (exists $contingency->{$cluster}) {
      $cluster2_sum{$cluster} = sum values %{ $contingency->{$cluster} };
    }
  }
  foreach my $cluster (@cluster1_names) {
    $cluster1_sum{$cluster} = sum map { $contingency->{$_}->{$cluster} } grep { exists $contingency->{$_} and exists $contingency->{$_}->{$cluster} } @cluster2_names;
  }

  my $n = _cell_sum($contingency);
  my $k = scalar(@cluster1_names);
  my $l = scalar(@cluster2_names);
  my $log_kl = log($k*$l);

#   print STDERR "n: $n, k: $k, l: $l\n";

  foreach my $i (keys %{ $contingency }) {
    foreach my $j (keys %{ $contingency->{$i} }) {

      next unless ($contingency->{$i}->{$j});
      my $tij = $contingency->{$i}->{$j};
#       print STDERR "t($i, $j): $tij\n";
#       print STDERR "t($i, .): $cluster2_sum{$i}\n";
#       print STDERR "t(., $j): $cluster1_sum{$j}\n";
      $mi += $tij * (log(($tij * $n) / ($cluster2_sum{$i} * $cluster1_sum{$j} )) / $log_kl);
    }
  }

  $mi = $mi / $n;

  $mutual_information_of{$id} = $mi;
  return $mi;
}

=head2 rand_index

The Rand index (defined by Rand, 1971) is based on the agreement vs. disagreement between object pairs in clusterings.



=cut

sub rand_index {
  my ($self) = @_;

  my $id = ident $self;

  croak "Please set/load classifications before computing rand index\n" unless ($classification1_of{$id} and $classification2_of{$id});

  if ($rand_index_of{$id}) {
    return $rand_index_of{$id};
  }

  my $objects = $self->objects();
  my @pairs = combine(2, keys %{ $objects });
  my $class1 = $classification1_of{$id};
  my $class2 = $classification2_of{$id};


  my %objects_by_class;

  foreach my $cluster (keys %{ $class1 }) {
    foreach my $object (keys %{ $class1->{$cluster} }) {
      $objects_by_class{$object}->[0]->{$cluster}++;
    }
  }
  foreach my $cluster (keys %{ $class2 }) {
    foreach my $object (keys %{ $class2->{$cluster} }) {
      $objects_by_class{$object}->[1]->{$cluster}++;
    }
  }

  my $rand = 0;

 PAIR:
  foreach my $pair (@pairs) {

    my $o1 = $pair->[0];
    my $o2 = $pair->[1];

    # classes Ca of Class_1 and Cb of Class_2 st o1 and o2 are both in Ca and Cb

    # classes of Class_1 containing o1 and o2:
    my %pair_in_class1;
    if (exists $objects_by_class{$o1}->[0] and exists $objects_by_class{$o2}->[0]) {
      foreach my $cluster (keys %{ $objects_by_class{$o1}->[0] }, keys %{ $objects_by_class{$o2}->[0] }) {
	$pair_in_class1{$cluster}++;
      }
    }

    %pair_in_class1 = map { $_ => 1 } grep { $pair_in_class1{$_} > 1 } keys %pair_in_class1;

    # classes of Class_2 containing o1 and o2:
    my %pair_in_class2;
    if (exists $objects_by_class{$o1}->[1] and exists $objects_by_class{$o2}->[1]) {
      foreach my $cluster (keys %{ $objects_by_class{$o1}->[1] }, keys %{ $objects_by_class{$o2}->[1] }) {
	$pair_in_class2{$cluster}++;
      }
    }

    %pair_in_class2 = map { $_ => 1 } grep { $pair_in_class2{$_} and $pair_in_class2{$_} > 1 } keys %pair_in_class1;

    foreach my $cluster (keys %pair_in_class1) {
      if (exists $pair_in_class2{$cluster}) {
	$rand++;
	next PAIR;
      }
    }

    # classes Ca of Class_1 and Cb of Class_2 st. o1 is in Ca and Cb and o2 is in neither Ca nor Cb

    if (exists $objects_by_class{$o1}->[0] and exists $objects_by_class{$o1}->[1]) {
      foreach my $cluster1 (keys %{ $objects_by_class{$o1}->[0] }) {
	foreach my $cluster2 (keys %{ $objects_by_class{$o1}->[1] }) {
	  # o2 is neither in cluster1 nor in cluster2

	  if (not( exists $objects_by_class{$o2}->[0] and exists $objects_by_class{$o2}->[0]->{$cluster1} )  and 
	      not( exists $objects_by_class{$o2}->[1] and exists $objects_by_class{$o2}->[1]->{$cluster2} ) ) {
	    $rand ++;
	    next PAIR;
	  }
	}
      }
    }

    if (exists $objects_by_class{$o2}->[0] and exists $objects_by_class{$o2}->[1]) {
      foreach my $cluster1 (keys %{ $objects_by_class{$o2}->[0] }) {
	foreach my $cluster2 (keys %{ $objects_by_class{$o2}->[1] }) {
	  # o1 is neither in cluster1 nor in cluster2
	  my $o1_in_1 = exists $objects_by_class{$o1}->[0] and exists $objects_by_class{$o1}->[0]->{$cluster1};
	  my $o1_in_2 = exists $objects_by_class{$o1}->[1] and exists $objects_by_class{$o1}->[1]->{$cluster2};
	  if (not $o1_in_1 and not $o1_in_2) {
	    $rand ++;
	    next PAIR;
	  }
	}
      }
    }
  }

  
  my $n = _cell_sum($self->contingency());

  if ($n > 1) {
    $rand = $rand / _nC2($n);
  } else {
    $rand = -1;
  }

  $rand_index_of{$id} = $rand;

  return $rand;
}

=head2 rand_adjusted

Rand index adjusted by chance (Hubert and Arabie 1985). The adopted
model for randomness assumes that the two classifications are picked
at random, given the original number of classes and objects - the
contingency table is constructed from the hyper-geometric
distribution. The general form of an index corrected for chance is:

  Index_adj = (Index - Expected Index) / (Maximum Index - Expected Index)

As maximum index I use the minimum of possible pairs in either classifications.

=cut

sub rand_adjusted {
  my ($self) = @_;

  my $id = ident $self;

  croak "Please set/load classifications before computing rand index (adjusted)\n" unless ($classification1_of{$id} and $classification2_of{$id});

  if ($rand_index_adj_of{$id}) {
    return $rand_index_adj_of{$id};
  }


  my $pairs_contingency = $self->pairs_contingency();
  my $contingency = $self->contingency();

  my $n = _cell_sum($contingency);

  my $index = 0;

  my %col_clusters;

  foreach my $row_cl (keys %{ $pairs_contingency }) {

    foreach my $col_cl (keys %{ $pairs_contingency->{$row_cl} }) {
      $col_clusters{$col_cl}++;
      $index += $pairs_contingency->{$row_cl}->{$col_cl};
    }
  }

  my $cont_row_sum = 0;
  foreach my $row_cl (keys %{ $contingency }) {
    $cont_row_sum += _nC2(sum values %{ $contingency->{$row_cl} });
  }
  
  my $cont_col_sum = 0;
  foreach my $col_cl (keys %col_clusters) {
    $cont_col_sum += _nC2(sum map { $contingency->{$_}->{$col_cl} } grep { exists $contingency->{$_}->{$col_cl} } keys %{ $contingency });
  }



  my $exp_index = 0;
  if ($n > 1 ) {
    $exp_index = $cont_row_sum * $cont_col_sum / _nC2($n);
  };

  my $max_index = min ($cont_row_sum, $cont_col_sum);

  my $rand_adj = -1;

  if ($max_index != $exp_index) {
    $rand_adj = ($index - $exp_index) / ($max_index - $exp_index);
  }

  $rand_index_adj_of{$id} = $rand_adj;

  return $rand_adj;
}

=head2 matching_index

Matching index (Fowlkes and Mallows, 1983).

=cut

sub matching_index {
  my ($self) = @_;

  my $id = ident $self;

  croak "Please set/load classifications before computing matching index\n" unless ($classification1_of{$id} and $classification2_of{$id});

  if ($matching_index_of{$id}) {
    return $matching_index_of{$id};
  }

  my $contingency = $self->contingency();

  my $n = 0;

  my ($Tk, $Pk, $Qk) = (0, 0, 0);


  my %col_sums;
  foreach my $row_cl (keys %{ $contingency }) {

    my $row_sum = 0;

    foreach my $col_cl (keys %{ $contingency->{$row_cl} }) {

      $n++;

      my $cell = $contingency->{$row_cl}->{$col_cl};

      $row_sum += $cell;

      if (exists $col_sums{$col_cl}) {
	$col_sums{$col_cl} += $cell;
      } else {
	$col_sums{$col_cl} = $cell;
      }

      $Tk += $cell*$cell;
    }

    $Pk += $row_sum * $row_sum;
  }

  $Qk = sum map { $_ * $_ } values %col_sums;

  $Tk = $Tk - $n;
  $Pk = $Pk - $n;
  $Qk = $Qk - $n;

  my $index = 0;
  
  my $PkQk = $Pk*$Qk;

  if ($PkQk > 0 ) {
    $index = $Tk / sqrt($Pk * $Qk);
  }

  $matching_index_of{$id} = $index;

  return $index;

}



1;

=head1 DIAGNOSTICS

=over

=item C<<Need reference to classification>>

When a L</"Providing the data"> method is called without enough arguments.

=item C<<Classifications must be passed as array or hash references>>

Argument of wrong type.

=item C<<Please set/load classifications before calling ... method>>

Method was called without providing classification data first, by calling one of the L</"Providing the data> methods.

=item C<<Need data for classification 1/2>>

Data for classification 1 (2 resp.) is missing.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Cluster::Similarity requires no configuration files or environment variables.

=head1 DEPENDENCIES

=over

=item Carp

=item Class::Std

=item List::Util qw(sum min)

=item Math::Combinatorics

=back


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-cluster-similarity@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 TO DO

=over

=item

find more suitable return values for when a given similarity measure is not applicable.

=item 

for the B<Rand adjusted> measure make the maximum index configurable.

=back

=head1 AUTHOR

Ingrid Falk, C<< <ingrid dot falk at loria dot fr> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cluster-similarity at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Cluster-Similarity>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Cluster::Similarity


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Cluster-Similarity>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Cluster-Similarity>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Cluster-Similarity>

=item * Search CPAN

L<http://search.cpan.org/dist/Cluster-Similarity/>

=back


=head1 SEE ALSO

=over

=item

For the description of the implemented clustering similarity measures:

Sabine Schulte im Walde. Experiments on the Automatic Induction of
German Semantic Verb Classes. PhD thesis, Institut für Maschinelle
Sprachverarbeitung, Universität Stuttgart, 2003. Published as AIMS
Report 9(2), L<http://www.schulteimwalde.de/phd-thesis.html>

=item * For building clusterings or classifications:

=over 2

=item L<Algorithm::Cluster> 

a I<Perl interface to the C Clustering Library>.

=item L<Text::SenseClusters>

I<Clusters similar contexts using co-occurrence matrices and Latent Semantic Analysis.>

=back

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Ingrid Falk, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

}

1; # End of Cluster::Similarity
