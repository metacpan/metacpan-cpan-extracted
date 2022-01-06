package Chart::GGPlot::Backend::Plotly::Geom::Path;

# ABSTRACT: Chart::GGPlot's Plotly implementation for Geom::Path

use Chart::GGPlot::Class qw(:pdl);

our $VERSION = '0.002000'; # VERSION

with qw(Chart::GGPlot::Backend::Plotly::Geom);

use Module::Load;

use Chart::GGPlot::Backend::Plotly::Util qw(
  to_px to_rgb group_to_NA pdl_to_plotly
);
use Chart::GGPlot::Util qw(ifelse);

classmethod split_on () { [qw(fill color size)] }

sub mode {
    return 'lines';
}

classmethod scatter_marker ($df, @rest) {
    return;
}

classmethod scatter_line ($df, $params, $plot) {
    my $use_webgl = $class->use_webgl($df);
    my $plotly_trace_class =
      $use_webgl
      ? 'Chart::Plotly::Trace::Scattergl'
      : 'Chart::Plotly::Trace::Scatter';

    my $line_class = "${plotly_trace_class}::Line";
    load $line_class;

    # TODO: plotly does not yet support gradient line color and width
    #  See https://github.com/plotly/plotly.js/issues/581

    my $color = to_rgb( $df->at('color'), $df->at('alpha') )->at(0);
    my $size  = to_px( $df->at('size')->slice( pdl(0) ) );
    $size->where($size < 2) .= 2;

    # plotly supports solid, dashdot, dash, dot
    my $linetype = $df->at('linetype')->at(0);

    return $line_class->new(
        color => $color,
        width => $size->at(0),
        ( $linetype ne 'solid' ? ( dash => $linetype ) : () ),
    );
}

classmethod to_traces ($df, $params, $plot) {
    $df = group_to_NA($df);

    my $use_webgl = $class->use_webgl($df);
    my $plotly_trace_class =
      $use_webgl
      ? 'Chart::Plotly::Trace::Scattergl'
      : 'Chart::Plotly::Trace::Scatter';

    load $plotly_trace_class;

    if ( $log->is_debug ) {
        $log->debug( $use_webgl ? "to use webgl" : "not to use webgl" );
    }

    my ( $x, $y ) = map { $df->at($_) } qw(x y);
    my $mode = $class->mode;
    my $marker =
        $mode eq 'markers'
      ? $class->scatter_marker( $df, $params, $plot )
      : undef;
    my $line =
        $mode eq 'lines'
      ? $class->scatter_line( $df, $params, $plot )
      : undef;

    my $trace = $plotly_trace_class->new(
        x    => $x,
        y    => $y,
        mode => $mode,
        maybe
          line => $line,
        maybe
          marker => $marker,
        hovertext => pdl_to_plotly( $df->at('hovertext') ),
        hoverinfo => 'text',
        hoveron   => $class->hover_on,
    );
    return [ $class->_adjust_trace_for_flip($trace, $plot) ];
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Backend::Plotly::Geom::Path - Chart::GGPlot's Plotly implementation for Geom::Path

=head1 VERSION

version 0.002000

=head1 SEE ALSO

L<Chart::GGPlot::Backend::Plotly::Geom>,
L<Chart::GGPlot::Geom::Path>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2021 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
