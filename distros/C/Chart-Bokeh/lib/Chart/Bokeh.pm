package Chart::Bokeh;

use strict;
use warnings;
use utf8;

use Exporter 'import';
use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(show_plot);

use JSON;
use Params::Validate qw(:all);
use Text::Template;
use Module::Load;
use Ref::Util;
use HTML::Show;

our $VERSION = '0.001';    # VERSION

# ABSTRACT: Generate html/javascript charts from perl data using javascript library BokehJS

sub render_full_html {
    my %params = @_;

    my $data     = $params{'data'};
    my $chart_id = 'bokeh_graph';
    my $html;
    if ( Ref::Util::is_blessed_ref($data) && $data->isa('Chart::Bokeh::Plot') ) {
        $html = _render_html_wrap( $data->html( div_id => $chart_id ) );
    } else {
        $html = _render_html_wrap( _render_cell( _process_data($data), $chart_id ) );
    }
    return $html;
}

sub _render_html_wrap {
    my $body       = shift;
    my $html_begin = <<'HTML_BEGIN';
<html>
<head>
<link rel="stylesheet" type="text/css" href="http://cdn.pydata.org/bokeh/release/bokeh-0.12.3.min.css"/>
</head>
<body>
HTML_BEGIN
    my $html_end = <<'HTML_END';
</body>
</html>
HTML_END
    return $html_begin . $body . $html_end;
}

sub _render_cell {
    my $data_string = shift();
    my $chart_id    = shift();
    my $template    = <<'TEMPLATE';
<div id="{$chart_id}"></div>
<script src="http://cdn.pydata.org/bokeh/release/bokeh-0.12.3.min.js"></script>
<script src="http://cdn.pydata.org/bokeh/release/bokeh-api-0.12.3.min.js"></script>
<script>

var source = new Bokeh.ColumnDataSource(\{
    data: {$data}
\});
var tools = "pan,crosshair,wheel_zoom,box_zoom,reset,save";
var p = Bokeh.Plotting.figure(\{ title: "", tools: tools \});
const line = new Bokeh.Line(\{x: \{field: "x"\}, y: \{field: "y"\}, line_color: "#666699", line_width: 2\});
p.add_glyph(line, source);
Bokeh.Plotting.show(p);
</script>
TEMPLATE

    my $template_variables = { data     => $data_string,
                               chart_id => $chart_id,
    };
    return Text::Template::fill_in_string( $template, HASH => $template_variables );
}

sub _process_data {
    my $data           = shift;
    my $json_formatter = JSON->new->utf8->allow_blessed(1)->convert_blessed(1);
    local *PDL::TO_JSON = sub { $_[0]->unpdl };
    my $data_string = $json_formatter->encode($data);
    return $data_string;
}

my $poc = '

// set up some data
var M = 100;
var xx = [];
var yy = [];
var colors = [];
var radii = [];
for (var y = 0; y <= M; y += 4) \{
    for (var x = 0; x <= M; x += 4) \{
        xx.push(x);
        yy.push(y);
        colors.push(Bokeh.Plotting.color(50+2*x, 30+2*y, 150));
        radii.push(Math.random() * 0.4 + 1.7)
    \}
\}

// create a data source
var source = new Bokeh.ColumnDataSource(\{
    data: \{ x: xx, y: yy, radius: radii, colors: colors \}
\});

// make the plot and add some tools
var tools = "pan,crosshair,wheel_zoom,box_zoom,reset,save";
var p = Bokeh.Plotting.figure(\{ title: "Colorful Scatter", tools: tools \});

// call the circle glyph method to add some circle glyphs
var circles = p.circle(\{ field: "x" \}, \{ field: "y" \}, \{
    source: source,
    radius: radii,
    fill_color: colors,
    fill_alpha: 0.6,
    line_color: null
\});

// show the plot
Bokeh.Plotting.show(p);
';

sub show_plot {
    my @data_to_plot = @_;

    my $rendered_cells = "";
    my $numeric_id     = 0;
    for my $data (@data_to_plot) {
        my $id = 'chart_' . $numeric_id++;
        if ( Ref::Util::is_blessed_ref($data) && $data->isa('Chart::Bokeh::Plot') ) {
            $rendered_cells .= $data->html( div_id => $id );
        } else {
            $rendered_cells .= _render_cell( _process_data($data), $id );
        }
    }
    my $plot = _render_html_wrap($rendered_cells);
    HTML::Show::show($plot);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Bokeh - Generate html/javascript charts from perl data using javascript library BokehJS

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 use Chart::Bokeh qw(show_plot);
 
 my $plot_data = {x => [0..10], y => [map {rand 10} 0..10]};
 
 show_plot($plot_data);

=head1 DESCRIPTION

Generate html/javascript charts from perl data using javascript library BokehJS. The result
is a file that you could see in your favourite browser.

The interface is "sub" oriented, but the API is subject to changes.

=head1 FUNCTIONS

=head2 render_full_html

=head3 Parameters

=over

=item * data:

Data to be represented. It could be:

=over

=item Perl data structure of the json expected by BokehJS: L<http://plot.ly/javascript/reference/> (this data would be serialized to JSON)

=item Anything that could be serialized to JSON with the json expected by BokehJS 

=back

=back

=head2 show_plot

Opens the plot in a browser locally

=head3 Parameters

Data to be represented. The format is the same as the parameter data in render_full_html

=head1 DISCLAIMER

This is an unofficial Bokeh Perl module. Currently I'm not affiliated in any way with Bokeh, nor Continuum Analytics, Inc. 
But I think bokeh.js is a great library and I want to use it with perl. Please see: L<http://bokeh.pydata.org/en/latest/>

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Pablo Rodríguez González.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
