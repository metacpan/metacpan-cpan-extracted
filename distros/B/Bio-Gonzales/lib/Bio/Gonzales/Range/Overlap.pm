package Bio::Gonzales::Range::Overlap;

use Mouse;

use warnings;
use strict;
use Carp;
use Set::IntervalTree;

use 5.010;

our $VERSION = '0.0546'; # VERSION

has _tree => ( is => 'rw', default => sub { Set::IntervalTree->new } );
has keep_coords => ( is => 'rw', default => 1 );

sub BUILD {
  my $self = shift;
  my $args = shift;

  if ( $args->{ranges} ) {
    $self->insert( $args->{ranges} );
  }
}

sub insert {
  my $self = shift;

  if ( @_ == 1 && ref $_[0] eq 'ARRAY' ) {
    for my $r ( @{ $_[0] } ) {
      $self->_insert(@$r);
    }
  } else {
    $self->_insert(@_);
  }

  return;
}

sub _insert {
  my ( $self, $start, $end, @rest ) = @_;

  ( $start, $end ) = ( $end, $start )
    if ( $start > $end );

  my $obj;
  if ( $self->keep_coords ) {
    $obj = [ $start, $end, @rest ];
  } elsif ( @rest > 1 ) {
    $obj = \@rest;
  } else {
    $obj = $rest[0];
  }

  $self->_tree->insert( $obj, $start, $end );

  return;
}

sub contained_in {
  my ( $self, $from, $to ) = @_;

  ( $from, $to ) = ( $to, $from )
    if ( $from > $to );
  #$to--;
  #$from++;

  return $self->_tree->fetch_window( $from, $to );
}

sub overlaps_with {
  my ( $self, $from, $to ) = @_;

  ( $from, $to ) = ( $to, $from )
    if ( $from > $to );
  $from--;
  $to++;

  return $self->_tree->fetch( $from, $to );
}

__PACKAGE__->meta->make_immutable();

__END__

=head1 NAME

Bio::Gonzales::Range::Overlap - find overlapping ranges

=head1 SYNOPSIS

  use 5.010;
  use Bio::Gonzales::Range::Overlap;
  use Data::Dumper;

  my @ranges1 = (
    [ 0, 5, 'some', 'information' ],
    [ 6, 8,  'some',     'other', 'information' ],
    [ 7, 10, 'nonsense', 'information' ],
    [ 11, 100, { 'very' => 'complicated', "data" => 'structure' } ],
  );

  my $ro = Bio::Gonzales::Range::Overlap->new;

  #build query db from 1st set of intervals
  for my $r (@ranges1) {
    $ro->insert(@$r);
  }

  # in this case (from and to are elements 0 and 1)
  # insert could be called with all ranges
  #$ro->insert(\@ranges1);

  my @ranges2 = ( [ 8, 10 ], [ 1, 3 ], [99,200],);

  # query the db with ranges
  for my $r (@ranges2) {
    say "Range (" . join(",", @$r) . ") overlaps with:";
    say Dumper $ro->overlaps_with(@$r);
  }

=head1 DESCRIPTION

A C<@range> has the form C<($from, $to, @additional elements)>. Lists of
ranges have the form C<([$from, $to, @add_elems], [$from, $to, @add_elems], ...)>.

=head1 OPTIONS

=head1 METHODS

=over 4

=item B<< $ro->insert(@range) >>

=item B<< $ro->insert(\@list_of_ranges) >>

=item B<< \@ranges_contained_in_given_range = $ro->contained_in(@range) >>

=item B<< \@ranges_that_overlap_with_given_range = $ro->overlaps_with(@range) >>

=back

=head1 SEE ALSO

=over 4

=item L<Bio::Gonzales::Matrix::IO> for reading in ranges from files

=item L<Bio::Gonzales::Range::GroupedOverlap> for grouped ranges such as genes
that are grouped by chromosomes.

=back

=head1 AUTHOR

jw bargsten, C<< <jwb at cpan dot org> >>

=cut
