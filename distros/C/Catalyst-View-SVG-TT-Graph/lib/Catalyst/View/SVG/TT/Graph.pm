package Catalyst::View::SVG::TT::Graph;

use Moose;
BEGIN { extends 'Catalyst::View'; }

use Carp;
use Image::LibRSVG;
use MIME::Types;

our $VERSION = 0.0226;

has 'format' => ( is => 'ro', isa => 'Str', default => 'svg' );

has 'chart_conf' => ( is => 'ro', isa => 'HashRef', default => sub {{}} );

has 't' => ( is => 'ro', isa => 'MIME::Types', default => sub { MIME::Types->new } );

=head1 NAME

Catalyst::View::SVG::TT::Graph - SVG::TT::Graph charts (in svg/png/gif/jpeg..) for your Catalyst application

=head1 SYNOPSIS

Create your view class:

    ./script/myapp_create.pl view Chart SVG::TT::Graph

Set your chart preferences in your config:

    <View::Chart>
        format         png
        <chart_conf>
            style_sheet         /path/to/stylesheet.css
            show_graph_title    1
        </chart_conf>
    </View::Chart>

Stash your chart data in your controller:

    $c->stash->{chart_title} = 'Sales data'; # optional
    
    $c->stash->{chart_type} = 'Bar'; # or Pie/Line/BarHorizontal
    
    $c->stash->{chart_conf} = {
        height  => 400,
        width   => 600
    };
    
    $c->stash->{chart_fields} = [ qw(Jan Feb March ..) ];
    $c->stash->{chart_data} = [ 120, 102, ..];

In your end method:

    $c->forward($c->view('Chart'));

If you want, say a comparative line graph of mutiple sets of data:

    $c->stash->{chart_type} = 'Line';
    
    $c->stash->{chart_data} = [
        { title => 'Barcelona', data => [ ... ] },
        { title => 'Atletico', data => [ ... ] },
    ];

=cut

=head1 METHODS

=head2 process

Generate the SVG::TT::Graph chart

=cut

sub process {
    my ( $self, $c ) = @_;

    my ( $type, $fields, $data ) = map {
        $c->stash->{"chart_" . $_} or croak("\$c->stash->{chart_$_} not set")
    } qw(type fields data);

    $type =~ m/^(Bar(Horizontal)?|Pie|Line)$/ or croak("Invalid chart type $type");

    my $conf = {
        %{ $self->chart_conf },
        %{ $c->stash->{chart_conf} }
    };

    $conf->{fields} = $fields;
    
    if (my $title = $c->stash->{chart_title} || $conf->{graph_title}) {
        $conf->{graph_title} = $title;
        $conf->{show_graph_title} = 1;
    }

    my $class = "SVG::TT::Graph::$type";

    Catalyst::Utils::ensure_class_loaded($class);
    my $svgttg = $class->new($conf);
    if ('HASH' eq ref($data)) {
        $svgttg->add_data($data);
    } elsif ('ARRAY' eq ref($data)) {
        if ('HASH' eq ref($data->[0])) {
            foreach my $datum (@$data) {
                $svgttg->add_data($datum);
            }
        } else {
            $svgttg->add_data( { data => $data } );
        }
    }

    my @formats = qw(gif jpeg png bmp ico pnm xbm xpm);
    my $frestr = '^(' . join('|', @formats) . ')$';
    my $format = $c->stash->{format} || $self->format;

    if ($format =~ m/$frestr/) {
        Image::LibRSVG->isFormatSupported($format)
            or croak("Format $format is not supported");
        $svgttg->compress(0);
        my $img = $svgttg->burn;
        my $rsvg = Image::LibRSVG->new();
        $rsvg->loadImageFromString($img);
        my $mtype = $self->t->mimeTypeOf($format);
        $c->res->content_type($mtype);
        $c->res->body($rsvg->getImageBitmap($format));
    } elsif ($format eq 'svg') {
        $c->res->content_type("image/svg+xml");
        $c->res->content_encoding("gzip");
        $c->res->body($svgttg->burn);
    }
}

=head1 CONFIG OPTIONS

B<Note:> These can be overridden by stashing parameters with the same name

=head2 format

Can be svg, png, gif, jpeg or any other format supported by L<Image::LibRSVG>

=head2 chart_conf

A hashref that takes all options to L<SVG::TT::Graph>::type . For the correct
options, see the corresponding documentation:

L<Bar Options|SVG::TT::Graph::Bar/new()>,

L<Pie Options|SVG::TT::Graph::Pie/new()>,

L<Line Options|SVG::TT::Graph::Line/new()>,

L<BarLine Options|SVG::TT::Graph::BarLine/new()>,

L<TimeSeries Options|SVG::TT::Graph::TimeSeries/new()>,

L<BarHorizontal Options|SVG::TT::Graph::BarHorizontal/new()>

=head1 STASHED PARAMETERS

=head2 format

An optional output format (svg/png/gif/jpeg..). Overrides config format

=head2 chart_title

An optional title for your chart

=head2 chart_type

Bar / Pie / Line / BarHorizontal / BarLine / TimeSeries

=head2 chart_conf

Any options taken by L<SVG::TT::Graph>

=head2 chart_fields

A list (array reference) of fields to show in your graph:

    $c->stash->{fields} = [ 'Jan', 'Feb', 'March' .. ];

=head2 chart_data

If all you want is a singe data set, can be a hash reference of the form:

    $c->stash->{chart_data} = { title => 'sales', values => [ 1.4, 2.2, ... ] }

or a simple ArrayRef if you don't want a title

    $c->stash->{chart_data} = [ 1.4, 2.2, ... ]

If you want multiple data sets, use an array reference with each set in a hashref:

    $c->stash->{chart_data} = [
        { title => 'Barcelona', data => [ .. ] },
        { title => 'Atletico', data => [ .. ] }
    ];

=head1 SAMPLE CHARTS

See L<http://leo.cuckoo.org/projects/SVG-TT-Graph/>

=head1 KNOWN BUGS

For jpeg pie charts, background color transparency doesn't work

=head1 REPOSITORY

See L<git://github.com/terencemo/Catalyst--View--SVG--TT--Graph.git>

=head1 SEE ALSO

L<SVG::TT::Graph>, L<Image::LibRSVG>

=head1 AUTHOR

Terence Monteiro <terencemo[at]cpan.org>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;

1;
