package Bio::Gonzales::Range::Util;

use warnings;
use strict;
use Carp;

use 5.010;

use base 'Exporter';
our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
our $VERSION = '0.0546'; # VERSION

@EXPORT      = qw();
%EXPORT_TAGS = ();
@EXPORT_OK   = qw(overlaps cluster_overlapping_ranges);

sub overlaps {
  my ( $r, $q, $c ) = @_;
  my $offset = defined $c->{offset} ? $c->{offset} : 0;
  $offset = 1 if ( $c->{book_ended} );

  # not ( ref start greater than query end or ref end less than query start )
  return not( $r->[0] - $offset > $q->[1] or $r->[1] < $q->[0] - $offset );
}

sub cluster_overlapping_ranges {
  my ( $ranges, $c ) = @_;

  #[ start, stop, @whatever]

  carp "empty ranges" and return unless ( $ranges && @$ranges > 0 );

  my @sorted_ranges = sort { $a->[0] <=> $b->[0] or $a->[1] <=> $b->[1] } @$ranges;
  my @range_clusters;

  my $i = 0;

  while (1) {
    if ( $i >= @sorted_ranges - 1 ) {
      push @range_clusters, [ $sorted_ranges[$i] ]
        if ( $i == @sorted_ranges - 1 );
      last;
    }

    my $range = $sorted_ranges[$i];

    my @current_cluster = ($range);

    my $next_range = $sorted_ranges[ $i + 1 ];
    my $max_end    = $range->[1];
    while ( $next_range->[0] <= $max_end
      || overlaps( $range, $next_range, $c ) )
    {
      push @current_cluster, $next_range;

      $i++;
      $max_end = $next_range->[1] if ( $next_range->[1] > $max_end );
      $range = $next_range;

      if ( $i + 1 >= @sorted_ranges ) {
        last;
      }

      $next_range = $sorted_ranges[ $i + 1 ];
    }
    $i++;
    push @range_clusters, \@current_cluster;
  }
  return \@range_clusters;
}



1;
