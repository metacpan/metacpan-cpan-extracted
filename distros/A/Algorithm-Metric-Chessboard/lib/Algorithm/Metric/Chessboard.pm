use strict;
package Algorithm::Metric::Chessboard;
use vars qw( $VERSION );
$VERSION = '0.01';

use Algorithm::Metric::Chessboard::Journey;
use Algorithm::Metric::Chessboard::Wormhole;
use Carp "croak";

=head1 NAME

Algorithm::Metric::Chessboard - Calculate distances on a square grid with optional wormholes (the 'chessboard metric').

=head1 DESCRIPTION

Calculates the minimum number of moves between two points in a game
played on a square grid, where one move is a jump from a point to a
horizontal, vertical or diagonal neighbour.

With no other features, the number of moves taken to go from
the point C<(x1, y1)> to C<(x2, y2)> I<would> be quite simple:

  d( (x1, y1), (x2, y2) ) = max( abs( x1 - x2 ), abs( y1 - y2) )

However within the space are "wormholes" which allow you to travel
between any two distant points, so the actual number of moves may be
smaller than the above.  Wormhole travel costs a fixed number of moves.

=head1 SYNOPSIS

  my @wormholes = (
    Algorithm::Metric::Chessboard::Wormhole->new( x => 5, y => 30 ),
    Algorithm::Metric::Chessboard::Wormhole->new( x => 98, y => 99 ),
  );

  my $grid = Algorithm::Metric::Chessboard->new(
                                   x_range       => [ 0, 99 ],
                                   y_range       => [ 0, 99 ],
                                   wormholes     => \@wormholes,
                                   wormhole_cost => 3,
                                               );

  my $wormhole = $grid->nearest_wormhole( x => 26, y => 53 );

  my $journey = $grid->shortest_journey(start => [1, 6], end => [80, 1]);

=head1 METHODS

=over

=item B<new>

  my @wormholes = (
    Algorithm::Metric::Chessboard::Wormhole->new(
                                                  x => 5,
                                                  y => 30,
                                                ),
    Algorithm::Metric::Chessboard::Wormhole->new(
                                                  x => 98,
                                                  y => 99,
                                                ),
  );

  my $grid = Algorithm::Metric::Chessboard->new(
                                   x_range       => [ 0, 99 ],
                                   y_range       => [ 0, 99 ],
                                   wormholes     => \@wormholes,
                                   wormhole_cost => 3,
                                               );

C<wormholes> is optional.  C<wormhole_cost> defaults to 0.

=cut

sub new {
    my ($class, %args) = @_;
    my $self = {};
    bless $self, $class;
    $self->x_range( $args{x_range} ) or croak "Bad 'x_range'";
    $self->y_range( $args{y_range} ) or croak "Bad 'y_range'";
    $self->wormholes( $args{wormholes} );
    $self->wormhole_cost( $args{wormhole_cost} );
    $self->calculate_wormhole_dists;
    return $self;
}

=item B<nearest_wormhole>

  my $wormhole = $grid->nearest_wormhole( x => 26, y => 53 );
  print "Nearest wormhole is " . $wormhole->id . " at ("
        . $wormhole->x . ", " . $wormhole->y . ")";

Returns a L<Algorithm::Metric::Chessboard::Wormhole> object.

=cut

sub nearest_wormhole {
    my ($self, %args) = @_;
    return $self->{nearest_wormhole}[$args{x}][$args{y}];
}

=item B<shortest_journey>

  my $journey = $grid->shortest_journey(
                                         start => [1, 6],
                                         end   => [80, 1],
                                       );
  my $distance = $journey->distance;
  my @via = $journey->via;
  print "Shortest journey is $distance move"
        . ( $distance == 1 ? "" : "s" );
  if ( scalar @via ) {
      print " via " . $via[0]->id . " and " . $via[1]->id;
  }

Returns a L<Algorithm::Metric::Chessboard::Journey> object.

=cut

sub shortest_journey {
    my ($self, %args) = @_;
    my ($start, $end) = @args{ qw( start end ) };
    my $straight_dist = $self->straight_distance(
                                                  start => $start,
                                                  end   => $end,
                                                );
    my $start_worm = $self->nearest_wormhole(
                                              x => $start->[0],
                                              y => $start->[1]  );
    my $end_worm   = $self->nearest_wormhole(
                                              x => $end->[0],
                                              y => $end->[1]  );
    if ( $start_worm and $end_worm ) {
        my $worm_dist = $self->straight_distance(
                                  start => $start,
                                  end   => [ $start_worm->x, $start_worm->y ]
                                                )
                      + $self->wormhole_cost
                      + $self->straight_distance(
                                  start  => $end,
                                  end    => [ $end_worm->x, $end_worm->y ]
                                                );
        if ( $worm_dist < $straight_dist ) {
            return Algorithm::Metric::Chessboard::Journey->new(
                start    => $start,
                end      => $end,
                via      => [ $start_worm, $end_worm ],
                distance => $worm_dist,
            );
        }
    }

    return Algorithm::Metric::Chessboard::Journey->new(
            start    => $start,
            end      => $end,
            distance => $straight_dist,
    );
}

sub calculate_wormhole_dists {
    my $self = shift;
    my @wormholes = @{ $self->wormholes };
    my ($x_min, $x_max) = @{ $self->x_range };
    my ($y_min, $y_max) = @{ $self->y_range };
    foreach my $x ( $x_min .. $x_max ) {
        foreach my $y ( $y_min .. $y_max ) {
            my ($nearest_wormhole, $nearest_dist);
            foreach my $wormhole ( @wormholes ) {
                my $dist = $self->straight_distance(
                    start => [ $x, $y ],
                    end   => [ $wormhole->x, $wormhole->y ],
                                                   );
                if ( ! defined $nearest_wormhole or $dist < $nearest_dist ) {
                    $nearest_wormhole = $wormhole; 
                    $nearest_dist = $dist;
                }
            }
            $self->{nearest_wormhole}[$x][$y] = $nearest_wormhole;
        }
    }
}

sub straight_distance {
    my ($self, %args) = @_;
    my ($x1, $y1) = @{ $args{start} };
    my ($x2, $y2) = @{ $args{end} };
    my $x_dist = abs( $x1 - $x2 );
    my $y_dist = abs( $y1 - $y2 );
    my $dist = $x_dist < $y_dist ? $y_dist : $x_dist;
    return $dist;
}

sub x_range {
    my ($self, $value) = @_;
    if ( defined $value ) {
        croak "Bad 'x_range'"
          unless ref $value eq "ARRAY" and scalar @$value == 2;
        $self->{x_range} = $value;
      }
    return $self->{x_range};
}

sub y_range {
    my ($self, $value) = @_;
    if ( defined $value ) {
        croak "Bad 'y_range'"
          unless ref $value eq "ARRAY" and scalar @$value == 2;
        $self->{y_range} = $value;
      }
    return $self->{y_range};
}

sub wormholes {
    my ($self, $value) = @_;
    $self->{wormholes} = $value if $value;
    return $self->{wormholes} || [];
}

sub wormhole_cost {
    my ($self, $value) = @_;
    $self->{wormhole_cost} = $value if $value;
    return $self->{wormhole_cost} || 0;
}

=back

=head1 AUTHOR

Kake Pugh (kake@earth.li).

=head1 COPYRIGHT

     Copyright (C) 2004 Kake Pugh.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 CREDITS

Jon Chin helped me figure out the name, Andy Armstrong and Mike
Stevens helped me clarify the statement of the problem.

=head1 SEE ALSO

Why I wrote this:

=over 4

=item * L<Gothador - Devilishly Good Fun!|http://www.gothador.com/index.php?ref=1086>

=item * L<Vampires! The Dark Alleyway|http://quiz.ravenblack.net/blood.pl?biter=Sleet>

=back

=cut

1;
