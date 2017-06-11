package CracTools::Interval::Query;

{
  $CracTools::Interval::Query::DIST = 'CracTools';
}
# ABSTRACT: Store and query genomics intervals.
#
$CracTools::Interval::Query::VERSION = '1.251';
use strict;
use warnings;

use CracTools::Utils;
use Set::IntervalTree 0.10;
use Carp;


sub new {
  my $class = shift;

  my %args = @_;

  my $self = bless {
    interval_trees => {},
    }, $class;

  return $self;
}


sub addInterval {
  my $self = shift;
  my ($chr,$start,$end,$strand,$value) = @_;

  my $interval_tree = $self->_getIntervalTree($chr,$strand);
  # If there is no already existing IntervalTree for this ("chr","strand") pair
  if(!defined $interval_tree) {
    # We create a new one
    $interval_tree = Set::IntervalTree->new;
    # We add this new interval tree with the others
    $self->_addIntervalTree($chr,$strand,$interval_tree);
  }

  # We insert the given interval in the IntervalTree
  # pos_end +1 because Interval tree use [a,b) intervals
  #$interval_tree->insert($value,$start,$end+1);
  $interval_tree->insert({value => $value, start => $start, end => $end},$start,$end+1);
}


sub fetchByRegion {
  my ($self,$chr,$pos_start,$pos_end,$strand,$windowed) = @_;

  my $interval_tree = $self->_getIntervalTree($chr,$strand);
  
  if(defined $interval_tree) {
    if(defined $windowed && $windowed) {
      # pos_end +1 because Interval tree use [a,b) intervals
      return $self->_processReturnValues($interval_tree->fetch_window($pos_start,$pos_end+1));
    } else {
      # pos_end +1 because Interval tree use [a,b) intervals
      return $self->_processReturnValues($interval_tree->fetch($pos_start,$pos_end+1));
    }
  }
  return [];
}


sub fetchByLocation {
  my ($self,$chr,$position,$strand) = @_;
  return $self->fetchByRegion($chr,$position,$position,$strand);
}


sub fetchNearestDown {
  my ($self,$chr,$position,$strand) = @_;

  my $interval_tree = $self->_getIntervalTree($chr,$strand);
  
  if(defined $interval_tree) {
    my $nearest_down = $interval_tree->fetch_nearest_down($position);
    if(defined $nearest_down) {
      return ({start => $nearest_down->{start}, end => $nearest_down->{end}},
        $self->_processReturnValue($nearest_down->{value})
      );
    }
  }
  return [];
}


sub fetchNearestUp {
  my ($self,$chr,$position,$strand) = @_;

  my $interval_tree = $self->_getIntervalTree($chr,$strand);
  
  if(defined $interval_tree) {
    my $nearest_up = $interval_tree->fetch_nearest_up($position);
    if(defined $nearest_up) {
      return ({start => $nearest_up->{start}, end => $nearest_up->{end}},
        $self->_processReturnValue($nearest_up->{value})
      );
    }
  }
  return [];
}


sub fetchAllNearestDown {
  my ($self,$chr,$position,$strand) = @_;

  my ($nearest_down_interval,$nearest_down) = $self->fetchNearestDown($chr,$position,$strand); 
  if(defined $nearest_down) {
    # We return all lines that belong to this
    my ($hits_interval,$hits) = $self->fetchByLocation($chr,$nearest_down_interval->{end},$strand);
    my @valid_hits;
    my @valid_hits_interval;
    for (my $i = 0; $i < @$hits; $i++) {
      # if this inteval as the same "end" boudaries as the nearest down interval
      if($hits_interval->[$i]->{end} == $nearest_down_interval->{end}) {
        push @valid_hits, $hits->[$i];
        push @valid_hits_interval, $hits_interval->[$i];
      }
    }
    return (\@valid_hits_interval,\@valid_hits);
  }
  return [];
}


sub fetchAllNearestUp {
  my ($self,$chr,$position,$strand) = @_;

  my ($nearest_up_interval,$nearest_up) = $self->fetchNearestUp($chr,$position,$strand); 

  if(defined $nearest_up) {
    # We return all lines that belong to this
    my ($hits_interval,$hits) = $self->fetchByLocation($chr,$nearest_up_interval->{start},$strand);
    my @valid_hits;
    my @valid_hits_interval;
    for (my $i = 0; $i < @$hits; $i++) {
      # if this inteval as the same "end" boudaries as the nearest down interval
      if($hits_interval->[$i]->{start} == $nearest_up_interval->{start}) {
        push @valid_hits, $hits->[$i];
        push @valid_hits_interval, $hits_interval->[$i];
      }
    }
    return (\@valid_hits_interval,\@valid_hits);
  }

  return [];
}


sub _getIntervalTree {
  my ($self,$chr,$strand) = @_;
  $strand = 1 if !defined $strand;
  return $self->{interval_trees}{_getIntervalTreeKey($chr,$strand)};
}


sub _addIntervalTree {
  my ($self,$chr,$strand,$interval_tree) = @_;
  $strand = 1 if !defined $strand;
  $self->{interval_trees}{_getIntervalTreeKey($chr,$strand)} = $interval_tree;
}


sub _getIntervalTreeKey {
  my ($chr,$strand) = @_;
  $strand = 1 if !defined $strand;
  return "$chr"."@"."$strand";
}


sub _processReturnValues {
  my $self = shift;
  my $return_values = shift;
  my @processed_return_values = ();
  my @processed_return_intervals = ();
  foreach (@{$return_values}) {
    push(@processed_return_values, $self->_processReturnValue($_->{value}));
    push(@processed_return_intervals, { 
        start => $_->{start},
        end => $_->{end}
      }
    );
  }
  return (\@processed_return_intervals,\@processed_return_values);
}


sub _processReturnValue {
  my $self = shift;
  my $val = shift;
  return $val;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CracTools::Interval::Query - Store and query genomics intervals.

=head1 VERSION

version 1.251

=head1 SYNOPSIS

  my $interval_query = CracTools::Interval::Query->new();

  $interval_query->addInterval("chr1",1,12,1,"geneA");
  $interval_query->addInterval("chr2",5,14,1,"geneB");

  @results = @{$intervalQuery->fetchByRegion("chr1",12,15,1)};

  foreach my $gene (@results) {
    print STDERR "Found $gene overlapping gene\n";
  }

=head1 DESCRIPTION

This module stores and query genomic intervals associated with variables. It
is based on the interval tree datastructure provided by L<Set::IntervalTree>.

L<CracTools::Interval::Query> query methods all returns a Array reference with all the
scalar associated to the retrieved intervals. But it also return an ArrayRef with the
intervals (start,end) themself, see L</_processReturnValues> for more informations.

All L<CracTools::Interval::Query> method can be used without the strand argument (or undef).
In this case, we will only consider the forward strand.

This class can be easily overloaded with L</_processReturnValue> hook method.

=head1 SEE ALSO

You may want to check L<CracTools::Interval::Query::File> that is an implementation
of L<CracTools::Interval::Query> that directly retrieve intervals from standard files
(BED,SAM,GTF,GFF) and returns the lines associated to the queried intervals.

=head1 METHODS

=head2 new

  Example     : my $intervalQuery = CracTools::Interval::Query->new();
  Description : Create a new CracTools::Interval::Query object
  ReturnType  : CracTools::Interval::Query
  Exceptions  : none

=head2 addInterval

  Arg [1] : String              - Chromosome
  Arg [2] : Integer             - Start position
  Arg [3] : Integer             - End position
  Arg [4] : (Optional) Integer  - Strand
  Arg [5] : Scalar              - The value to be hold by this interval. It can
                                  be anything, an Integer, a String, a hash 
                                  reference, an array reference, ...

  Example     : $interval_query->addInterval("chr1",12,30,-1,"geneA")
  Description : Add a new genomic interval, with an associated value to the interval_query.

=head2 fetchByRegion

  Arg [1] : String              - Chromosome
  Arg [2] : Integer             - Start position
  Arg [3] : Integer             - End position
  Arg [4] : (Optional) Integer  - Strand
  Arg [5] : (Optional) Boolean  - Windowed query, only return intervals which
                                  are completely contained in the queried region.

  Example     : my @values = $IntervalQuery->fetchByRegion('1',298345,309209,'+');
  Description : Retrieves intervals that belong to the region.
  ReturnType  : ArrayRef of scalar

=head2 fetchByLocation

  Arg [1] : String              - Chromosome
  Arg [2] : Integer             - Positon
  Arg [3] : (Optional) Integer  - Strand

  Example     : my @values = $intervalQuery->fetchByLocation('1',298345,'+');
  Description : Retrieves lines that overlapped the given location.
  ReturnType  : ArrayRef of Scalar

=head2 fetchNearestDown

  Arg [1] : String              - Chromosome
  Arg [2] : Integer             - Position
  Arg [3] : (Optional) Integer  - Strand

  Example     : my @values = $interval_query->fetchNearestDown('1',298345,'+');
  Description : Search for the closest interval in downstream that does not contain the query
                and returns the line associated to this interval. 
  ReturnType  : Scalar

=head2 fetchNearestUp

  Arg [1] : String             - Chromosome
  Arg [2] : Integer            - Position
  Arg [3] : (Optional) Integer - Strand

  Example     : my @values = $interval_query->fetchNearestDown('1',298345,'+');
  Description : Search for the closest interval in upstream that does not contain the query
                and returns the line associated to this interval. 
  ReturnType  : Scalar

=head2 fetchAllNearestDown

  Arg [1] : String             - Chromosome
  Arg [2] : Integer            - Position
  Arg [3] : (Optional) Integer - Strand

  Example     : my @values = $interval_query->fetchNearestDown('1',298345,'+');
  Description : Search for all the closest interval in downstream that does not contain the query
                and returns the line associated to this interval. 
  ReturnType  : ArrayRef of Scalar

=head2 fetchAllNearestUp

  Arg [1] : String             - Chromosome
  Arg [2] : Integer            - Position
  Arg [3] : (Optional) Integer - Strand

  Example     : my @values = $interval_query->fetchNearestDown('1',298345,'+');
  Description : Search for all the closest interval in upstream that does not contain the query
                and returns the line associated to this interval. 
  ReturnType  : ArrayRef of Scalar

=head1 PRIVATE METHODS

=head2 _getIntervalTree 

  Arg [1] : String             - Chromosome
  Arg [2] : (Optional) Integer - Strand

  Description : Return the Set::IntervalTree reference for the chromosome and strand (Default : 1)
  ReturnType  : Set::IntervalTree

=head2 _addIntervalTree

  Arg [1] : String             - Chromosome
  Arg [2] : (Optional) Integer - Strand
  Arg [3] : Set::IntervalTree  - Interval tree

  Description : Add an Set::IntervalTree object for a specific ("chr","strand") pair.
                Strand is set to 1 if none (or undef) is provided

=head2 _getIntervalTreeKey

  Arg [1] : String             - Chromosome
  Arg [2] : (Optional) Integer - Strand

  Description : Static method that return and unique key for the ("chr","strand") pair passed in arguements.
                Strand is set to 1 if none (or undef) is provided
  ReturnType  : String

=head2 _processReturnValues

  Arg [1] : ArrayRef - Values returned by Set::IntervalTree

  Example     : # Either get only the values holded by the retrieved intervals
                my @values = @{$interval_query->_processReturnValues($interval_results)};
                # Or also get the intervals themselves
                my ($intervals,$values) = $interval_query->_processReturnValues($interval_results);
  Description : Call _processReturnValue() method on each values of the array ref passed in parameters.
  ReturnType  : Array(ArrayRef({start => .., end => ..}),ArrayRef(Scalar))
                (
                  [ { start => 12, end => 20 }, ... ],
                  [ "geneA", ...]
                )

=head2 _processReturnValue

  Arg [1] : Scalar - Value holded by an interval

  Description : This method process the values contains by each intervals that
                match a query before returning it.  It is designed to be
                overloaded by doughter classes.
  ReturnType  : Scalar (ArrayRef,HashRef,String,Integer...)

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
