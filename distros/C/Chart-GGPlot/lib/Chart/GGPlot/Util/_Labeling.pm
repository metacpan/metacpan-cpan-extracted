#TODO: make this a standalone CPAN distribution

package Chart::GGPlot::Util::_Labeling;

# ABSTRACT: R 'labeling' package functions used by Chart::GGPlot

use Chart::GGPlot::Setup;

our $VERSION = '0.002003'; # VERSION

use Chart::GGPlot::Util::_Base qw(:all);

use parent qw(Exporter::Tiny);

our @EXPORT_OK = qw(
  labeling_extended
);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use List::AllUtils;
use Machine::Epsilon qw(machine_epsilon);
use POSIX qw(ceil floor fmod);

my $eps = machine_epsilon() * 100;

fun _simplicity( $q, $Q, $j, $lmin, $lmax, $lstep ) {
    my $n = @$Q;
    my $i = List::AllUtils::firstidx { $_ == $q } @$Q;
    my $v =
         ( fmod($lmin, $lstep) < $eps || $lstep - fmod( $lmin, $lstep ) < $eps )
      && $lmin <= 0
      && $lmax >= 0 ? 1 : 0;
    return ( 1 - $i / ( $n - 1 ) - $j + $v );
}

fun _simplicity_max( $q, $Q, $j ) {
    my $n = @$Q;
    my $i = List::AllUtils::firstidx { $_ == $q } @$Q;
    my $v = 1;
    return ( 1 - $i / ( $n - 1 ) - $j + $v );
}

fun _coverage( $dmin, $dmax, $lmin, $lmax ) {
    my $range = $dmax - $dmin;
    return ( 1 - 0.5 * ( ( $dmax - $lmax )**2 + ( $dmin - $lmin )**2 ) /
          ( ( 0.1 * $range )**2 ) );
}

fun _coverage_max( $dmin, $dmax, $span ) {
    my $range = $dmax - $dmin;
    if ( $span > $range ) {
        my $half = ( $span - $range ) / 2;
        return ( 1 - 0.5 * ( $half**2 + $half**2 ) / ( ( 0.1 * $range )**2 ) );
    }
    else {
        return 1;
    }
}

fun _density( $k, $m, $dmin, $dmax, $lmin, $lmax ) {
    my $r = ( $k - 1 ) / ( $lmax - $lmin );
    my $rt =
      ( $m - 1 ) /
      ( List::AllUtils::max( $lmax, $dmax ) -
          List::AllUtils::min( $dmin, $lmin ) );
    return ( 2 - List::AllUtils::max( $r / $rt, $rt / $r ) );
}

fun _density_max( $k, $m ) {
    ( $k >= $m ) ? ( 2 - ( $k - 1 ) / ( $m - 1 ) ) : 1;
}

fun _legibility( $lmin, $lmax, $lstep ) {
    1    ## did all the legibility tests in C#, not in R.
}

# An Extension of Wilkinson’s Algorithm for Position Tick Labels on Axes
fun labeling_extended(
    $dmin, $dmax, $m,
    $Q          = [ 1, 5, 2, 2.5, 4, 3 ],
    $only_loose = false,
    $w          = [ 0.25, 0.2, 0.5, 0.05 ]
  )
{
    if ( $dmin > $dmax ) {
        ( $dmin, $dmax ) = ( $dmax, $dmin );
    }
    if ( $dmax - $dmin < $eps ) {
        return seq_n( $dmin, $dmax, $m );
    }
    my $n    = @$Q;
    my %best = ( score => -2 );
    my $j    = 1;
    while ( $j < 'Inf' ) {
        for my $q (@$Q) {
            my $sm = _simplicity_max( $q, $Q, $j );
            if (
                ( $w->[0] * $sm + $w->[1] + $w->[2] + $w->[3] ) < $best{score} )
            {
                $j = 'Inf';
                last;
            }
            my $k = 2;
            while ( $k < 'Inf' ) {
                my $dm = _density_max( $k, $m );
                if ( ( $w->[0] * $sm + $w->[1] + $w->[2] * $dm + $w->[3] ) <
                    $best{score} )
                {
                    last;
                }
                my $delta = ( $dmax - $dmin ) / ( $k + 1 ) / $j / $q;
                my $z = ceil( log($delta) / log(10) );
                while ( $z < 'Inf' ) {
                    my $step = $j * $q * ( 10**$z );
                    my $cm = _coverage_max( $dmin, $dmax, $step * ( $k - 1 ) );
                    if (
                        (
                            $w->[0] * $sm +
                            $w->[1] * $cm +
                            $w->[2] * $dm +
                            $w->[3]
                        ) < $best{score}
                      )
                    {
                        last;
                    }
                    my $min_start =
                      floor( $dmax / ($step) ) * $j - ( $k - 1 ) * $j;
                    my $max_start = ceil( $dmin / ($step) ) * $j;
                    if ( $min_start > $max_start ) {
                        $z += 1;
                        next;
                    }
                    for my $start ( $min_start .. $max_start ) {
                        my $lmin = $start * ( $step / $j );
                        my $lmax = $lmin + $step * ( $k - 1 );
                        my $lstep = $step;
                        my $s = _simplicity( $q, $Q, $j, $lmin, $lmax, $lstep );
                        my $c = _coverage( $dmin, $dmax, $lmin, $lmax );
                        my $g = _density( $k, $m, $dmin, $dmax, $lmin, $lmax );
                        my $l = _legibility( $lmin, $lmax, $lstep );
                        my $score =
                          $w->[0] * $s +
                          $w->[1] * $c +
                          $w->[2] * $g +
                          $w->[3] * $l;
                        if (
                            $score > $best{score}
                            && ( !$only_loose
                                || ( $lmin <= $dmin && $lmax >= $dmax ) )
                          )
                        {
                            %best = (
                                lmin  => $lmin,
                                lmax  => $lmax,
                                lstep => $lstep,
                                score => $score
                            );
                        }
                    }
                    $z += 1;
                }
                $k += 1;
            }
        }
        $j += 1;
    }
    return seq_by( $best{lmin}, $best{lmax}, $best{lstep} );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Util::_Labeling - R 'labeling' package functions used by Chart::GGPlot

=head1 VERSION

version 0.002003

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2023 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
