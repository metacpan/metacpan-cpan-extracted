
package Astro::Montenbruck::Ephemeris;

use 5.22.0;
use strict;
use warnings;
no warnings qw/experimental/;
use Readonly;
use Module::Load;
use Memoize;
memoize qw/_create_constructor/;

use Exporter qw/import/;

our %EXPORT_TAGS = (
    all  => [ qw/iterator find_positions/ ],
);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} }, );
our $VERSION = 0.03;

use Math::Trig qw/deg2rad/;
use List::Util qw/any/;
use Astro::Montenbruck::Ephemeris::Planet qw/:ids/;
use Astro::Montenbruck::NutEqu qw/mean2true/;
use Astro::Montenbruck::MathUtils qw/diff_angle/;

Readonly our $DAY_IN_CENT => 1 / 36525;

# Factory function. Loads given class and returns function that wraps
# its constructor.
#
# Example:
# my $f = _create_constructor('Astro::Montenbruck::Ephemeris::Planets::Sun');
# my $sun = $f->(); # instantiate the object
# my @pos = $sun->position($t); # calculate coordinates for the moment $t
sub _create_constructor {
    my $pkg = shift;
    load $pkg;
    sub { $pkg->new(@_) }
}

# shortcut for _create_constructor
sub _construct {
    _create_constructor(join('::', qw/Astro Montenbruck Ephemeris/, @_))
}


sub _iterator {
    my $t = shift;
    my $ids_ref = shift;
    my @items = @{$ids_ref};
    my %arg = @_;


    my $sun = _construct('Planet', $SU)->();
    my @sun_pos = $sun->sunpos($t);
    my $sun_lbr = {
        l => deg2rad($sun_pos[0]),
        b => deg2rad($sun_pos[1]),
        r => $sun_pos[2]
    };

    my $nut_func = mean2true($t);

    # Calculate required position. Sun's coordinates are calculated only once.
    my $get_position = sub {
        my $id = shift;
        given ($id) {
            when ($SU) {
                return [
                    $sun->apparent($t, \@sun_pos, $nut_func)
                ]
            }
            when ($MO) {
                my $moo = _construct('Planet', $id)->();
                return [
                    $moo->apparent([$moo->moonpos($t)], $nut_func)
                ]
            }
            default {
                my $pla = _construct('Planet', $id)->();
                my @lbr = $pla->heliocentric($t);
                # planets
                return [
                    $pla->apparent($t, \@lbr, $sun_lbr, $nut_func)
                ]
            }
        }
    };

    sub {
    NEXT:
        return unless @items;  # no more items, stop iteration
        my $id = shift @items;
        goto NEXT if $id eq $PL && ($t < -1.1 || $t > 1.0);
        [ $id, $get_position->($id) ]
    }
}


sub iterator {
    my $t       = shift;
    my $ids_ref = shift;
    my %arg     = (with_motion => 0, @_);

    my $iter_1 = _iterator($t, $ids_ref, %arg);
    return $iter_1 unless $arg{with_motion};

    # to calculate mean daily motion, we need another iterator, for the next day
    my $iter_2 = _iterator($t + $DAY_IN_CENT, $ids_ref, %arg);

    return sub {
        my $res = $iter_1->() or return;
        $res->[2] = diff_angle($res->[1]->[0], $iter_2->()->[1]->[0]);
        $res
    }
}

sub find_positions {
    my $t        = shift;
    my $ids_ref  = shift;
    my $callback = shift;

    my $iter = iterator($t, $ids_ref, @_);
    while ( my $res = $iter->() ) {
        my ($id, $pos, $motion) = @$res;
        $callback->( $id, @$pos, $motion );
    }
}


1;
__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::Ephemeris - calculate planetary positions.

=head1 SYNOPSIS

=head2 Iterator interface

  use Astro::Montenbruck::Ephemeris::Planet qw/@PLANETS/;
  use Astro::Montenbruck::Ephemeris qw/iterator/;
  use Data::Dumper;

  my $jd = 2458630.5; # Standard Julian date for May 27, 2019, 00:00 UTC.
  my $t  = ($jd - 2451545) / 36525; # Convert Julian date to centuries since epoch 2000.0
                                    # for better accuracy, convert $t to Ephemeris (Dynamic) time.
  my $iter = iterator( $t, \@PLANETS ); # get iterator function for Sun. Moon and the planets.

  while ( my $result = $iter->() ) {
      my ($id, $co) = @$result;
      print $id, "\n", Dumper($co), "\n"; # geocentric longitude, latitude and distance from Earth
  }

=head2 Callback interface

  use Astro::Montenbruck::Ephemeris::Planet qw/@PLANETS/;
  use Astro::Montenbruck::Ephemeris qw/find_positions/;

  my $jd = 2458630.5; # Standard Julian date for May 27, 2019, 00:00 UTC.
  my $t  = ($jd - 2451545) / 36525; # Convert Julian date to centuries since epoch 2000.0
                                    # for better accuracy, convert $t to Ephemeris (Dynamic) time.

  find_positions($t, \@PLANETS, sub {
      my ($id, $lambda, $beta, $delta) = @_;
      say "$id $lambda, $beta, $delta";
  })


=head1 DESCRIPTION

Calculates apparent geocentric ecliptic coordinates  of the Sun, the Moon, and
the 8 planets. Algorithms are based on I<"Astronomy on the Personal Computer">
by O.Montenbruck and Th.Pfleger. The results are supposed to be precise enough
for amateur's purposes:

  "The errors in the fundamental routines for determining the coordinates
  of the Sun, the Moon, and the planets amount to about 1″-3″."

  -- Introduction to the 4-th edition, p.2.

You may use one of two interfaces: iterator and callback.

The coordinates are referred to the I<true equinox of date> and contain corrections
for I<precession>, I<nutation>, I<aberration> and I<light-time>.

=head2 Implementation details

This module is implemented as a "factory". User may not need all the planets
at once, so each class is loaded lazily, by demand.

=head2 Mean daily motion

To calculate mean daily motion along with the celestial coordinates, use
C<with_motion> option:

  iterator( $t, \@PLANETS, with_motion => 1 );
  # Or:
  find_positions($t, \@PLANETS, $callback, with_motion => 1);

That will slow down the program.

=head2 Pluto

Pluto's position is calculated only between years B<1890> and B<2100>.
See L<Astro::Montenbruck::Ephemeris::Planet::Pluto>.

=head2 Universal Time vs Ephemeris Time

For better accuracy the time must be given in I<Ephemeris Time (ET)>. To convert
I<UT> to I<ET>, use C<delta_t> function from L<Astro::Montenbruck::Time::DeltaT> module.

=head1 SUBROUTINES

=head2 iterator($t, $ids, %options)

Returns iterator function, which, on its turn, when called returns either C<undef>,
when exhausted, or arrayref, containing:

=over

=item *

identifier of the celestial body, a string

=item *

arrayref, containing ecliptic coordinates: I<longitude> (arc-degrees),
I<latitude> (arc-degrees) and distance from Earth (AU).

=item * mean daily motion, double, if C<with_motion> option is I<true>

=back

=head3 Positional Arguments

=over

=item *

B<$t> — time in centuries since epoch 2000.0; for better precision UTC should be
converted to Ephemeris time, see L</Universal Time vs Ephemeris Time>.

=item *

B<$ids> — reference to an array of ids of celestial bodies to be calculated.

=back

=head3 Options

=over

=item *

B<with_motion> — optional flag; when set to I<true>, there is additional B<motion>
field in the result;  I<false> by default.

=back

=head2 find_positions($t, $ids, $callback, %options)

The arguments and options are the same as for the L<iterator|/iterator($t, $ids, %options)>,
except the third argument, which is a B<callback function>, called on each iteration:

  $callback->($id, $lambda, $beta, $delta [, $daily_motion])

I<$lambda>, I<$beta>, I<$delta> are ecliptic coordinates: I<longitude> (arc-degrees),
I<latitude> (arc-degrees) and distance from Earth (AU). The fifth argument,
I<$daily_motion> is defined only when C<with_motion> option is on; it is the
mean daily motion (arc-degrees).


=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2022 by Sergey Krushinsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
