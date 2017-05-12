package Chart::OFC;
$Chart::OFC::VERSION = '0.12';
use strict;
use warnings;


use Moose 0.56;
use MooseX::StrictConstructor;
use Chart::OFC::Types;

with 'Chart::OFC::Role::OFCDataLines';

has title =>
    ( is        => 'ro',
      isa       => 'Str',
      predicate => '_has_title',
    );

has title_style =>
    ( is      => 'ro',
      isa     => 'Str',
      default => 'font-size: 25px',
    );

has tool_tip =>
    ( is        => 'ro',
      isa       => 'Str',
      predicate => '_has_tool_tip',
    );

has bg_color =>
    ( is        => 'ro',
      isa       => 'Chart::OFC::Type::Color',
      coerce    => 1,
      predicate => '_has_bg_color',
    );

{
    my $CRLF = "\r\n";
    sub as_ofc_data
    {
        my $self = shift;

        my @lines = $self->_ofc_data_lines();

        return join '', map { $_ . $CRLF } @lines;
    }
}

sub _ofc_data_lines
{
    my $self = shift;

    my @lines;

    push @lines, $self->_data_line( 'title', $self->title(), '{ ' . $self->title_style() . ' }' )
        if $self->_has_title();

    for my $key ( qw( tool_tip bg_color ) )
    {
        my $pred = '_has_' . $key;

        push @lines, $self->_data_line( $key, $self->$key() )
            if $self->$pred();
    }

    return @lines;
}

# Moose gets weird if these things are loaded before various subs are
# defined.

# If these requires are changed to a use some tests start failing in
# weird ways. WTF?

require Chart::OFC::Grid;
require Chart::OFC::Pie;

require Chart::OFC::AxisLabel;
require Chart::OFC::XAxis;
require Chart::OFC::YAxis;

require Chart::OFC::Dataset::3DBar;
require Chart::OFC::Dataset::Area;
require Chart::OFC::Dataset::Bar;
require Chart::OFC::Dataset::Candle;
require Chart::OFC::Dataset::FadeBar;
require Chart::OFC::Dataset::OutlinedBar;
require Chart::OFC::Dataset::GlassBar;
require Chart::OFC::Dataset::HighLowClose;
require Chart::OFC::Dataset::Line;
require Chart::OFC::Dataset::LineWithDots;
require Chart::OFC::Dataset::Scatter;
require Chart::OFC::Dataset::SketchBar;

no Moose;

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Generate data files for use with Open Flash Chart

__END__

=pod

=head1 NAME

Chart::OFC - Generate data files for use with Open Flash Chart

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    use Chart::OFC;    # loads all the other classes

    my $set = Chart::OFC::Dataset->new( values => [ 1 .. 10 ] );
    my $pie = Chart::OFC::Pie->new(
        title   => 'Pie!',
        dataset => $set,
        labels  => [ 'a' .. 'j' ],
    );

    print $pie->as_ofc_data();

=head1 DESCRIPTION

B<NOTE: You probably want to use L<Chart::OFC2> instead, or maybe just use
some client-side JS library and skip the flash entirely.>

This class lets you generate data for the Open Flash Chart
library. OFC produces very attractive charts, but it's data format is
byzantine and hard to understand. This library lets you generate that
data with a high level API.

OFC can display pie charts, lines and/or bars on a grid, and area
charts on a grid.

If you haven't explored OFC yet, you might want to stop now and go the
OFC home page at http://teethgrinder.co.uk/open-flash-chart/. There
are many examples of what it can do with OFC there, and seeing them
will help you understand exactly what kind of charts you want to
generate with this library.

Also note that this library simply generates data for OFC. You still
need to embed the OFC flash in something and feed it the data to
actually make a chart. This library does not generate Flash or HTML or
anything like that.

This library was tested with OFC 1.9.7, and follows the format defined
for that version. The OFC zip file is included in this distribution's
tarball, under the F<ofc> directory.

=head2 Classes

The functionality for generating charts is split across a number of
classes, each of which encapsulates one piece of a chart.

=head3 Datasets

Each data set represents one chunk of data to be displayed on your
chart. There are a number of dataset subclasses for representing data
in different formats (lines, bars, etc). You can also use the dataset
base class, C<Chart::OFC::Dataset>, when creating a pie chart.

The dataset classes provided are:

=over 4

=item * Chart::OFC::Dataset

The base class for all datasets. It has no formatting, and can only be
used with pie charts.

=item * Chart::OFC::Dataset::Bar

=item * Chart::OFC::Dataset::FadeBar

=item * Chart::OFC::Dataset::OutlinedBar

=item * Chart::OFC::Dataset::GlassBar

=item * Chart::OFC::Dataset::3DBar

=item * Chart::OFC::Dataset::SketchBar

Formats your data as a set of bars. There are many different styles of
bars.

=item * Chart::OFC::Dataset::Line

=item * Chart::OFC::Dataset::LineWithDots

Formats your data as a line, with optional dots marking each value.

=item * Chart::OFC::Dataset::Area

Like a line with dots, but this dataset also fills in the area between
the line and the X axis with a color.

=back

=head3 Axes and Axis Labels

When you are creating a non-pie chart, you will want to create an X
and Y axis for the chart. These are represented by the
C<Chart::OFC::XAxis> and C<Chart::OFC::YAxis> classes.

These classes in turn can take a C<Chart::OFC::AxisLabel> class to
define the label for the entire label.

=head3 Grid Charts

A grid chart can contain any number of datasets, in any combination of
bars and lines.

=head3 Pie Charts

A pie chart displays a single dataset, with each value as a pie slice.

=head2 Colors

Many attributes in different classes expect a color. Colors can be
provided as an RGB hex string with a leading "#" symbol, or as color
names. Names are translated into RGB by use of the
C<Graphics::ColorNames> module, using the "X" scheme. See that
module's docs for more details.

=head2 Opacity

Several classes accept an opacity value for an attribute. This should
be a value from 0 (completely transparent) to 100 (completely opaque).

=head1 ATTRIBUTES

This class has a number of attributes which may be passed to the
C<new()> method.

=head2 title

This is shown as the title of the chart.

This attribute is optional.

=head2 title_style

This should be a chunk of CSS specifying attributes that apply to
text, such as "font-size", "color", etc.

This defaults to the string "font-size: 25px". Without a default
specifying a sane size, the default size OFC uses seems to 1px or so.

=head2 tool_tip

This defines how tool tips are generated for data points. It uses a
simple templating language. See
http://teethgrinder.co.uk/open-flash-chart/gallery-tool-tip.php for
details.

This attribute is optional.

=head2 bg_color

The background color for the chart and surrounding text.

This attribute is optional.

=head1 METHODS

All of the above named may be accessed as read-only accessors on an
object.

This class also provide several additional methods.

=head2 as_ofc_data

Returns a textual representation of the chart suitable for delivering
to OFC.

=head1 ROLES

This class does the C<Chart::OFC::Role::OFCDataLines> role.

=head1 TODO

This distribution does not yet support all of the features of OFC.

There are a few items left to do, notably grid charts with 2 Y axes,
and background images.

It would also be nice to generate embeddable Javascript for populating
charts, since this lets you create a chart without making an
additional server request for the data.

Patches are welcome.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module,
please consider making a "donation" to me via PayPal. I spend a lot of
free time creating free software, and would appreciate any support
you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order
for me to continue working on this particular software. I will
continue to do so, inasmuch as I have in the past, for as long as it
interests me.

Similarly, a donation made in this way will probably not make me work
on this software much more, unless I get so many donations that I can
consider working on free software full time, which seems unlikely at
best.

To donate, log into PayPal and send money to autarch@urth.org or use
the button on this page:
L<http://www.urth.org/~autarch/fs-donation.html>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-chart-ofc@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
