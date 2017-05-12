package Algorithm::LineSegments;
use 5.012000;
use strict;
use warnings;
use List::Util qw/min max/;
use Heap::Priority;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
  line_segment_points
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
  line_segment_points
);

our $VERSION = '0.04';

sub _normalised_euclidean {
  my ($left, $right, $p) = @_;
  my $y0 = $left->[0];
  my $y1 = $right->[-1];
  my $cl = @{ $left };
  my $cr = @{ $right };
  my $xx = ($y1 - $y0) / ($cl + $cr - 1);

  my $sum = 0;
  for (0 .. $cl - 1) {
    my $pi = $y0 + $xx * $_;
    my $pr = $left->[$_];
    $sum += ($p->($pr) - $p->($pi))**2;
  }
  
  for (0 .. $cr - 1) {
    my $pi = $y0 + $xx * ($_ + $cl);
    my $pr = $right->[$_];
    $sum += ($p->($pr) - $p->($pi))**2;
  }
  
  sqrt $sum;
}

sub line_segment_points {

  my (%o) = @_;
  
  die unless $o{points};
  my @d = @{ $o{points} };

  my @q;

  for (my $ix = 0; $ix < @d - 1; $ix += 2) {
    push @q, [$d[$ix], $d[$ix+1]];
  }

  my $min = min @d;
  my $max = max @d;

  ###################################################################
  # This function projects values from $min to $max to 0 to 1. This
  # is useful in order to keep the cost values similar.
  ###################################################################
  my $scale_to_unit = sub {
    my $v = shift;
    return ($v - $min) / ($max - $min);
  };

  $o{cost} //= sub {
    my ($left, $right) = @_;
    _normalised_euclidean($q[$left], $q[$right], $scale_to_unit);
  };

  $o{continue} //= sub {
    my ($count, $cost) = @_;
    return 0 if $count <= 3; 
    return 1;
  };
  
  my $heap = Heap::Priority->new;
  $heap->lowest_first;
  $heap->add($_, $o{cost}->($_, $_+1)) for 0 .. $#q - 1;

  ###################################################################
  # I haven't found a good solution to maintain the heap and modify
  # the list, so as a workaround the heap identifies a mergable pair
  # with the key and when merging elements of a pair, the second
  # element is replaced by `undef` to maintain the size of the list,
  # so the heap keys, indices into the list, remain valid. This has
  # the consequence of producing gaps in the list, and the variables
  # below maintain how the gaps can be skipped.
  ###################################################################
  my %next = map { $_ => $_ + 1 } 0 .. $#q - 1;
  my %prev = map { $_ => $_ - 1 } 1 .. $#q - 1;

  for (my $count = @q;;) {
    my $ix = $heap->pop;
    last unless defined $ix;

    #################################################################
    # Ordinarily it should be possible to obtain the priority of the
    # element on top of the heap, but the chosen module can report
    # only the priorities of all elements, which is a bit costly, so
    # instead the cost is re-computed here for now.
    #################################################################
    my $cost = $o{cost}->($ix, $next{$ix});
    
    #################################################################
    # The callback can be by calling code to stop the merging process 
    #################################################################
    last unless $o{continue}->($count, $cost);

    my $k = $ix;
    my $j = $next{$k};
    
    next unless defined $j;
    
    my @merged = map { @{ $q[$_] } } $k, $j;
    $q[$k] = undef;
    $q[$j] = undef;
    splice @q, $k, 2, [@merged], undef;
    $count--;
    
    #################################################################
    # Now that $k has changed, merging $k with the element before or
    # after has a different cost, so those elements are removed from
    # the heap and added again with the newly calculated cost factor.
    #################################################################
    $heap->delete_item($next{$k}) if defined $next{$k};
    $heap->delete_item($prev{$k}) if defined $prev{$k};

    $next{$k} = $next{$j};

    $heap->add($prev{$k}, $o{cost}->($prev{$k}, $k)) if defined $prev{$k};
    $heap->add($k, $o{cost}->($k, $next{$k})) if defined $next{$k};

    $prev{$next{$j}} = $k if defined $next{$j};
    
    delete $next{$j};
    delete $prev{$j};
  }

  my @temp = grep { defined } @q;
  my @result;
  my $pos = 0;
  for (my $ix = 0; $ix < @temp; ++$ix) {
    push @result, [
      [ $pos, $temp[$ix][0] ],
      [ $pos + scalar(@{$temp[$ix]}) - 1, $temp[$ix][-1] ]
    ];
    $pos += scalar(@{$temp[$ix]})
  }
  
  return @result;
}

1;

__END__

=head1 NAME

Algorithm::LineSegments - Piecewise linear function approximation

=head1 SYNOPSIS

  use Algorithm::LineSegments;
  my @points = line_segment_points(
    points => \@numbers,
    continue => sub {
      my ($segment_count, $cost_factor) = @_;
      return 0 if $segment_count <= 10;
      return 1;
    },
  );

=head1 DESCRIPTION

This module takes discrete data points like time series data and
computes a piecewise linear function, line segments, approximating
them. It does this by merging groups of adjacent points into lines,
always picking the pair that produces the smallest error, until it
is told to stop.

=head2 FUNCTIONS

=over

=item line_segment_points(%options)

Returns a list of [[$x0, $y0], [$x1, $y1]] pairs describing line
segments. Options are

=over

=item C<points>

Array of numbers, the input data.

=item C<continue>

A callback function that is called with the number of remaining
segments and the cost of the current merge with the expectation
the callback returns a true value if it should perform the merge
and continue, and a false value if it should stop merging and
return. The default is to merge until only three line segments
are left.

=item C<cost>

A callback function that is called with two list references of
points and it should return a number indicating how costly it
is, how much of an error it introduces, if all points are made
into a single line segment. The default projects all data points
to the unit range 0 .. 1 based on the maximum and minimum value
and computes the euclidean distance between the points and the
corresponding points on a line that would cover them all.

=back

=back

=head2 EXPORTS

The function C<line_segment_points> by default.

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright (c) 2014 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut
