package Chart::GGPlot::Backend::Plotly::Geom::Path;

# ABSTRACT: Chart::GGPlot's Plotly support for Geom::Bar

use Chart::GGPlot::Class qw(:pdl);

our $VERSION = '0.0001'; # VERSION

with qw(Chart::GGPlot::Backend::Plotly::Geom);

use Module::Load;

use Chart::GGPlot::Backend::Plotly::Util qw(cex_to_px to_rgb group_to_NA);
use Chart::GGPlot::Util qw(ifelse);

sub mode {
    return 'lines';
}

classmethod marker ($df, %rest) {
    return;
}

classmethod to_trace ($df, %rest) {
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
    my $marker = $class->marker( $df, %rest );

    my $mode = $class->mode;
    my $line;
    if ( $mode eq 'lines' ) {

        # TODO: plotly does not yet support gradient line color and width
        #  See https://github.com/plotly/plotly.js/issues/581

        my $color = to_rgb( $df->at('color')->slice( pdl(0) ) );
        my $size  = cex_to_px( $df->at('size')->slice( pdl(0) ) );
        $size = ifelse( $size < 2, 2, $size );

        # plotly supports solid, dashdot, dash, dot
        my $linetype = $df->at('linetype')->at(0);

        $line = {
            color => $color->at(0),
            width => $size->at(0),
            ( $linetype ne 'solid' ? ( dash => $linetype ) : () ),
        };
    }

    return $plotly_trace_class->new(
        x    => $x->unpdl,
        y    => $y->unpdl,
        mode => $mode,
        maybe
          line => $line,
        maybe
          marker => $marker,

        # TODO: hovertext for webgl does not seem to work. Maybe it's
        #  because of large data count. To revisit this in future.
        (
            $use_webgl
            ? ()
            : (
                hovertext => $df->at('hovertext')->unpdl,
                hoverinfo => 'text',
            )
        ),
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Backend::Plotly::Geom::Path - Chart::GGPlot's Plotly support for Geom::Bar

=head1 VERSION

version 0.0001

=head1 SEE ALSO

L<Chart::GGPlot::Backend::Plotly::Geom>,
L<Chart::GGPlot::Geom::Path>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
