package Bio::Gonzales::Util::Math::kNN::via::Distances;

use Mouse;

use warnings;
use strict;
use List::Util qw/max min/;
use List::MoreUtils qw/indexes/;
use Data::Dumper;

use 5.010;
our $VERSION = '0.0546'; # VERSION

=head1 NAME

Bio::Gonzales::Util::Math::kNN::via::Distances - Calculate kNN clusterings from already calculated distances

=head1 SYNOPSIS

    use Bio::Gonzales::Util::Math::kNN::via::Distances;

    my $k = Bio::Gonzales::Util::Math::kNN::via::Distances->new(
        distances => [ [1], [ 2, 3 ], ... ],
        groups => [ 'group1 row1', 'group row2', undef, 'group row4' ]
    );
    my $result = $k->calc(1);

=head1 DESCRIPTION

=head1 METHODS

=head2 Bio::Gonzales::Util::Math::kNN::via::Distances->new(...)

=over 4

=item distances

Distances in lower triangular form (array of arrays).

=item groups

Groups in array, undef for "test" rows.

=back

=cut

#array of arrays (distances in lower triangular matrix form)
has distances => ( is => 'rw', required => 1 );
#array of groupnames with undef for test
has groups => ( is => 'rw', required => 1 );

sub calc {
  my ( $self, $k ) = @_;

  my @training_idx = indexes {$_} @{ $self->groups };
  say STDERR "Training idx: " . Dumper( \@training_idx );

  my @lies_in_group;
  for ( my $i = 0; $i < @{ $self->distances }; $i++ ) {
    my $d = $self->distances->[$i];

    # here we have a training 'row', so skip it
    if ( $self->groups->[$i] ) {
      $lies_in_group[$i] = undef;
      next;
    }

    # get index of $k distances from training set
    my @k_nearest
      = ( sort { $self->_distance_between( $a, $i ) <=> $self->_distance_between( $b, $i ) } @training_idx )
      [ 0 .. ( $k - 1 ) ];
    say STDERR "$i -> " . Dumper( \@k_nearest );

    $lies_in_group[$i] = $self->_vote( \@k_nearest );
  }
  return \@lies_in_group;
}

sub _distance_between {
  my ( $self, $i, $a ) = @_;

  my $dist;
  if ( $a > $i ) {
    $dist = $self->distances->[$a][$i];
  } else {
    $dist = $self->distances->[$i][$a];
  }

  say STDERR "($i, $a) => $dist";
  return $dist;
}

sub _vote {
  my ( $self, $k_nearest ) = @_;

  my %votes;
  for my $idx ( @{$k_nearest} ) {
    $votes{ $self->groups->[$idx] }++;
  }

  my $group = ( sort { $votes{$b} <=> $votes{$a} } keys %votes )[0];

  return $group;
}

1;
__END__

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <joachim.bargsten at wur.nl> >>

=cut
