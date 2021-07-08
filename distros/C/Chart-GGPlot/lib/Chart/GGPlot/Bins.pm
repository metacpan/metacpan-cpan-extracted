package Chart::GGPlot::Bins;

# ABSTRACT: Class for histogram bins

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;

our $VERSION = '0.0016'; # VERSION

use Data::Frame;
use List::AllUtils qw(reduce pairmap);
use Math::SimpleHisto::XS;
use POSIX qw(floor);
use Types::Standard qw(ArrayRef CodeRef Enum Int Num Str);
use Types::PDL -types;

use Chart::GGPlot::Util qw(is_discrete seq_by);

has breaks => ( is => 'ro' );

has fuzz => (
    is      => 'ro',
    builder => sub { $_[0]->breaks->diff->median * 1e-8 },
);
has fuzzy => (
    is      => 'lazy',
    builder => sub {
        my $self = shift;
        die if ( is_discrete( $self->breaks ) );

        my $breaks = $self->breaks->qsort;
        my $fuzz   = $self->fuzz;

        # this protects from floating point rounding errors.
        my $fuzzes = pdl( [ ( -$fuzz ) x ( $breaks->length - 1 ), $fuzz ] );
        return ( $breaks + $fuzzes );
    },
);

classmethod bin_breaks ($breaks) {
    return $class->new( breaks => $breaks );
}

classmethod bin_breaks_width ($x_range, $width=undef,
                             :$center=undef, :$boundary=undef) {
    state $check = Type::Params::compile( Num->where( sub { $_ > 0 } ) );
    ($width) = $check->($width);

    die unless $x_range->length == 2;

    if ( defined $boundary and defined $center ) {
        die "Only one of 'boundary' and 'center' may be specified.";
    }
    elsif ( not defined $boundary ) {
        if ( not defined $center ) {
            $boundary = $width / 2;
        }
        else {
            $boundary = $center - $width / 2;
        }
    }

    # Find the left side of left-most bin.
    my $shift  = floor( ( $x_range->at(0) - $boundary ) / $width );
    my $origin = $boundary + $shift * $width;

    # Small correction factor so that we don't get an extra bin when, for
    # example, origin = 0, max(x) = 20, width = 10.
    my $max_x  = $x_range->at(1) + ( 1 - 1e-8 ) * $width;
    my $breaks = seq_by( $origin, $max_x, $width );

    return $class->bin_breaks($breaks);
}

my $GreaterThanOne = Int->where( sub { $_ >= 1 } );

classmethod bin_breaks_bins ($x_range, $bins,
                            :$center=undef, :$boundary=undef) {
    state $check = Type::Params::compile( Int->where( sub { $_ >= 1 } ) );
    my ($bins) = $check->( $bins // 30 );

    die unless $x_range->length == 2;

    my $width;
    if ( $bins == 1 ) {
        $width    = $x_range->at(1) - $x_range->at(0);
        $boundary = $x_range->at(0);
    }
    else {
        $width = ( $x_range->at(1) - $x_range->at(0) ) / ( $bins - 1 );
    }

    return $class->bin_breaks_width(
        $x_range, $width,
        boundary => $boundary,
        center   => $center,
    );
}

method bin_vector ($x, :$weight=undef, :$pad=false) {
    if ( $x->isbad->all ) {
        return $self->bin_out( $x->length );
    }

    # PDL's histgram functions does not support variable length bins.
    # 
    # NOTE: Math::SimpleHisto::XS's bin range is left-closed and right-open,
    # while R ggplot2's bin range is defautly right-closed and left-open.
    # This can cause some differences.
    my $hist = Math::SimpleHisto::XS->new( bins => $self->fuzzy->unpdl );
    if ( defined $weight ) {
        $weight->inplace->setbadtoval(0);
        $hist->fill( $x->unpdl, $weight->unpdl );
    }
    else {
        $hist->fill( $x->unpdl );
    }

    my $bin_count = pdl( $hist->all_bin_contents );
    my $breaks    = $self->breaks;
    my $bin_x     = ( $breaks->slice( pdl( [ 0 .. $breaks->length - 2 ] ) ) +
          $breaks->slice( pdl( [ 1 .. $breaks->length - 1 ] ) ) ) / 2;
    my $bin_widths = $breaks->diff;

    # Pad row of 0s at start and end
    if ($pad) {
        $bin_count = pdl( 0, $bin_count->list, 0 );
        my $width1 = $bin_widths->at(0);
        my $widthn = $bin_widths->at(-1);
        $bin_widths = pdl( $width1, $bin_widths->list, $widthn );
        $bin_x      = pdl( $bin_x->at(0) - $width1,
            $bin_x->list, $bin_x->at(-1) + $widthn );
    }

    # Add row for missings
    #if ( $bins->badflag ) {
    #    $bin_count  = pdl( $bin_count, $bins->isbad->sum );
    #    $bin_widths = $bin_widths->glue( 0, NA() );
    #    $bin_x      = $bin_x->glue( 0, NA() );
    #}

    return $self->bin_out( $bin_count, $bin_x, $bin_widths );
}

classmethod bin_out (Piddle $count, Piddle $x, Piddle $width,
                    :$xmin=$x-$width/2, :$xmax=$x+$width/2) {
    my $density = $count / $width / $count->abs->sum;

    return Data::Frame->new(
        columns => [
            count    => $count,
            x        => $x,
            xmin     => $xmin,
            xmax     => $xmax,
            width    => $width,
            density  => $density,
            ncount   => $count / $count->abs->max,
            ndensity => $density / $density->abs->max,

            # set x to x_raw as there is no longer one-to-one mapping from original data
            x_raw => $x,
        ],
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Bins - Class for histogram bins

=head1 VERSION

version 0.0016

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2021 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
