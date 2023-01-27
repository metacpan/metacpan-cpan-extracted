package Chart::GGPlot::Backend::Plotly::Geom::Text;

# ABSTRACT: Chart::GGPlot's Plotly implementation for Geom::Text

use Chart::GGPlot::Class;

our $VERSION = '0.002002'; # VERSION

extends qw(Chart::GGPlot::Backend::Plotly::Geom::Path);

use Chart::Plotly::Trace::Scatter::Textfont;
use List::AllUtils qw(pairwise);
use Module::Load;
use PDL::Primitive qw(which);

use Chart::GGPlot::Util qw(mm_to_pt);
use Chart::GGPlot::Backend::Plotly::Util
  qw(group_to_NA to_rgb pdl_to_plotly);

classmethod to_traces( $df, $params, $plot ) {
    $df = group_to_NA($df);

    my $use_webgl = $class->use_webgl($df);
    my $plotly_trace_class =
      $use_webgl
      ? 'Chart::Plotly::Trace::Scattergl'
      : 'Chart::Plotly::Trace::Scatter';

    if ( $log->is_debug ) {
        $log->debug( $use_webgl ? "to use webgl" : "not to use webgl" );
    }

    load $plotly_trace_class;

    my ( $x, $y, $label, $hjust, $vjust ) =
      map { $df->at($_) } qw(x y label hjust vjust);
    my $textfont = Chart::Plotly::Trace::Scatter::Textfont->new(
        color  => pdl_to_plotly( to_rgb( $df->at('color'), $df->at('alpha') ) ),
        size   => pdl_to_plotly( mm_to_pt( $df->at('size') ) ),
        family => pdl_to_plotly( $df->at('family') ),
    );
    my @computed_hjust = $class->_compute_hjust($hjust)->list;
    my @computed_vjust = $class->_compute_vjust($vjust)->list;
    my $textposition   = pairwise { "$a $b" } @computed_vjust, @computed_hjust;
    my $trace          = $plotly_trace_class->new(
        x            => $x,
        y            => $y,
        text         => pdl_to_plotly($label),
        mode         => 'text',
        textfont     => $textfont,
        textposition => $textposition,
        hovertext    => pdl_to_plotly( $df->at('hovertext') ),
        hoverinfo    => 'text',
        hoveron      => $class->hover_on,
    );
    return [$trace];
}

sub _compute_hjust {
    my ( $class, $just ) = @_;

    if ( $just->$_DOES('PDL::SV') ) {

        # Rename middle to center, because plotly needs left/center/right
        # Btw this is actually different from ggplot2 which is
        #  left/middle/right and bottom/center/top..
        my $new_just = $just->copy;
        $new_just->slice( which( $just == 'middle' ) ) .= 'center';
        return $just->copy;
    }
    else {
        my $new_just = PDL::SV->new( [ ("center") x $just->length ] );
        $new_just->slice( which( $just <= 0.25 ) ) .= 'right';
        $new_just->slice( which( $just >= 0.75 ) ) .= 'left';
        return $new_just;
    }
}

sub _compute_vjust {
    my ( $class, $just ) = @_;

    if ( $just->$_DOES('PDL::SV') ) {

        # Rename center to middle, because plotly needs bottom/middle/top
        my $new_just = $just->copy;
        $new_just->slice( which( $just == 'center' ) ) .= 'middle';
        return $new_just;
    }
    else {
        my $new_just = PDL::SV->new( [ ('middle') x $just->length ] );
        $new_just->slice( which( $just <= 0.25 ) ) .= 'top';
        $new_just->slice( which( $just >= 0.75 ) ) .= 'bottom';
        return $new_just;
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Backend::Plotly::Geom::Text - Chart::GGPlot's Plotly implementation for Geom::Text

=head1 VERSION

version 0.002002

=head1 SEE ALSO

L<Chart::GGPlot::Backend::Plotly::Geom>,
L<Chart::GGPlot::Geom::Point>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2023 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
