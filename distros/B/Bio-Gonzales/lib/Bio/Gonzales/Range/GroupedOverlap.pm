package Bio::Gonzales::Range::GroupedOverlap;

use Mouse;

use warnings;
use strict;
use Carp;

use 5.010;

use Bio::Gonzales::Range::Overlap;

our $VERSION = '0.0546'; # VERSION

has _trees => ( is => 'rw', default => sub { {} } );
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
  my ( $self, $grp_id, $start, $end, @rest ) = @_;

  $self->_trees->{$grp_id} //= Bio::Gonzales::Range::Overlap->new( keep_coords => $self->keep_coords );
  $self->_trees->{$grp_id}->insert( $start, $end, @rest );

  return $self;
}

sub contained_in {
  my $self = shift;

  my ( $grp_id, $from, $to );
  if ( @_ == 1 && ref $_[0] eq 'ARRAY' ) {
    ( $grp_id, $from, $to ) = @{ $_[0] };
  } else {
    ( $grp_id, $from, $to ) = @_;
  }

  return unless ( $self->_trees->{$grp_id} );
  ( $from, $to ) = ( $to, $from )
    if ( $from > $to );
  #$to--;
  #$from++;

  return $self->_trees->{$grp_id}->contained_in( $from, $to );
}

sub overlaps_with {
  my $self = shift;

  my ( $grp_id, $from, $to );
  if ( @_ == 1 && ref $_[0] eq 'ARRAY' ) {
    ( $grp_id, $from, $to ) = @{ $_[0] };
  } else {
    ( $grp_id, $from, $to ) = @_;
  }

  return unless ( $self->_trees->{$grp_id} );

  ( $from, $to ) = ( $to, $from )
    if ( $from > $to );
  $from--;
  $to++;

  return $self->_trees->{$grp_id}->overlaps_with( $from, $to );
}

__PACKAGE__->meta->make_immutable();

__END__

=head1 NAME

Bio::Gonzales::Range::GroupedOverlap - cluster overlapping ranges that are in the same group

=head1 SYNOPSIS

  use Bio::Gonzales::Range::GroupedOverlap;

  my $gol = Bio::Gonzales::Range::GroupedOverlap->new(
    ranges => [ 
      [ 'group_1',   1, 100, ... ],
      [ 'group_2',  60, 200, ... ],
      [ 'group_1', 300, 400, ... ] 
    ]
  );

=head1 DESCRIPTION

=head1 OPTIONS

=head1 SUBROUTINES
=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <jwb at cpan dot org> >>

=cut
