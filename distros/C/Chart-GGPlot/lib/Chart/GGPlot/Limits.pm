package Chart::GGPlot::Limits;

# ABSTRACT: Functions for applying limits to the scales

use Chart::GGPlot::Setup qw(:base :pdl);

our $VERSION = '0.0007'; # VERSION

use Data::Frame;
use List::AllUtils qw(pairmap); 
use Type::Params;
use Types::Standard;
use Types::PDL qw(Piddle1D PiddleFromAny);

use Chart::GGPlot::Aes::Functions qw(aes_all);
use Chart::GGPlot::Geom::Blank;
use Chart::GGPlot::Types;
use Chart::GGPlot::Util qw(:all);
use Chart::GGPlot::Scale::Functions qw(find_scale);

use parent qw(Exporter::Tiny);

my @export_ggplot = qw(
  lims xlim ylim limits expand_limits );
our @EXPORT_OK = @export_ggplot;
our %EXPORT_TAGS = (
    all    => \@EXPORT_OK,
    ggplot => \@export_ggplot,
);


fun lims (%pairs) {
    my @mapped = pairmap { limits( $a => $b ) } ( %pairs );
    return \@mapped;
}


fun xlim (@v) { limits( x => \@v ); }
fun ylim (@v) { limits( y => \@v ); }


fun limits ( $var, $lims ) {
    state $check =
      Type::Params::compile( Piddle1D->plus_coercions(PiddleFromAny) );
    ($lims) = $check->($lims);

    if (is_discrete($lims)) {
        return _limits_factor( $var, $lims );
    }
    elsif ( $lims->$_DOES('PDL::DateTime') ) {
        return _limits_date( $var, $lims );
    }
    else {
        return _limits_numeric( $var, $lims );
    }
}

fun _check_limits_size ( $lims, $expected_size = 2 ) {
    unless ( $lims->length == $expected_size ) {
        croak "size of limits is not 2";
    }
}

fun _limits_numeric ( $var, $lims ) {
    state $check = Type::Params::compile(
            Piddle1D->plus_coercions(PiddleFromAny)
        );
    ($lims) = $check->($lims);

    _check_limits_size($lims);

    my $trans =
      ( $lims->nbad == 0 && $lims->at(0) > $lims->at(1) )
      ? "reverse"
      : "identity";
    return _make_scale( "continuous", $var, limits => $lims, trans => $trans );
}

fun _limits_factor ( $var, $lims ) {
    return _make_scale( "discrete", $var, limits => $lims );
}

fun _limits_date ( $var, $lims ) {
    _check_limits_size($lims);

    return _make_scale( "discrete", $var, limits => $lims );
}

fun _make_scale ( $type, $var, @rest ) {
    my $scale_name = "scale_${var}_${type}";
    my $scale_f;
    {
        no strict 'refs';
        $scale_f = \&{"Chart::GGPlot::Scale::Functions::$scale_name"};
    }
    return $scale_f->(@rest);
}


fun expand_limits (%params) {
    my $data = Data::Frame->new( columns => \%params );
    return Chart::GGPlot::Geom::Blank->new(
        mapping     => aes_all( $data->names ),
        data        => $data,
        inherit_aes => false,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Limits - Functions for applying limits to the scales

=head1 VERSION

version 0.0007

=head1 SYNOPSIS

    use Chart::GGPlot qw(:all);

    my $plot1 = ggplot(data => $mtcars, 
                       mapping => aes(x => 'mpg', y => 'wt')) + 
                    geom_point() + xlim(15, 20);

    # if the larger value comes first, the scale will be reversed
    my $plot2 = ggplot(data => $mtcars, 
                       mapping => aes('mpg', 'wt')) + 
                    geom_point() + xlim(20, 15);

    # you can leave one value as NA to compute from the range of the data
    my $plot3 = ggplot(data => $mtcars,
                       mapping => aes('mpg', 'wt')) + 
                    geom_point() + xlim(NA, 20);

=head1 DESCRIPTION

The module provides some functions for specifying limits of a plot.
By default, any values outside limits will be not plottted.

=head1 FUNCTIONS

=head2 lims

    lims(%pairs)

Call C<limits()> on each kv pair in C<%pairs>.
Returns an array ref like C<[ limits($key1, $value1), ... ]>.

=head2 xlim

    xlim($a, $b)

This is a shortcut of 

    limits(x => [$a, $b]);

=head2 ylim

    ylim($a, $b)

This is a shortcut of 

    limits(y => [$a, $b]);

=head2 limits

    limits($var, $lims)

=head2 expand_limits

    expand_limits(%params)

Expand the plot limits, using data.

    my $p = ggplot($mtcars, aes( x=> 'mpg', y => 'wt')) + geom_point();
    $p->expand_limits(x => 0);
    $p->expand_limits(y => [1, 9]);

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
