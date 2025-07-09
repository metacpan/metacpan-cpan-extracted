package CtrlO::PDF;

use strict;
use warnings;
use utf8;

use Carp qw/croak carp/;
use Image::Info qw(image_info image_type);
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use PDF::Table;

our $VERSION = '0.33';

=head1 NAME

CtrlO::PDF - high level PDF creator

=head1 SYNOPSIS

  use CtrlO::PDF;
  use Text::Lorem;

  my $pdf = CtrlO::PDF->new(
      logo         => "sample/logo.png", # optional
      logo_scaling => 0.5,               # Default
      width        => 595,               # Default (A4, portrait mode)
      height       => 842,               # Default (A4, portrait mode)
      orientation  => "portrait",        # Default
      margin       => 40,                # Default, all 4 sides
      top_padding  => 0,                 # Default
      header       => "My PDF document header",  # optional
      footer       => "My PDF document footer",  # optional
  );
  # width, height page dimensions in points (default A4 paper)
  # orientation defaults to portrait (taller than wide)
  # margin in points on all four sides
  # top padding below header in points
  # header, footer text line to place at top or bottom
  # PDFlib actually checked only for '[aA]' or '[bB]', permitting a wide
  #   range of formats to specify the PDF support library

  # Add a page
  $pdf->add_page;

  # Add headings
  $pdf->heading('This is the main heading');
  $pdf->heading('This is a sub-heading', size => 12);

  # Add paragraph text
  my $lorem = Text::Lorem->new();
  my $paras = $lorem->paragraphs(30);
  $pdf->text($paras);

  # Add a table
  my $data =[
      ['Fruit', 'Quantity'], # Table header
      ['Apples', 120],
      ['Pears', 90],
      ['Oranges', 30],
  ];

  my $hdr_props = {
      repeat     => 1,
      justify    => 'center',
      font_size  => 8,
  };

  $pdf->table(
      data => $data,
      header_props => $hdr_props,
  );

  my $file = $pdf->content;

  # output the file
  open my $pdf_out, '>', 'out.pdf';
  binmode $pdf_out;
  print $pdf_out $file;
  close $pdf_out;

=head1 DESCRIPTION

This module tries to make it easy to create PDFs by providing a high level
interface to a number of existing PDF modules. It aims to "do the right thing"
by default, allowing minimal coding to create long PDFs. It includes
pagination, headings, paragraph text, images and tables. Although there are a
number of other modules to create PDFs with a high-level interface, I found
that these each lack certain features (e.g. image insertion, paragraph text).
This module tries to include each of those features through another existing
module. Also, as it is built on PDF::Builder, it provides access to that
object, so content can also be added directly using that, thereby providing any
powerful features required.

B<Updates in v0.20> Note that version 0.20 contains a number breaking changes
to improve the default layout and spacing of a page. This better ensures that
content added to a page "just works" in terms of its layout, without needing
tweaks to its spacing. For example, headers have better spacing above and below
by default. This means that PDFs produced with this version will be laid out
differently to those produced with earlier versions. In the main, old code
should be able to be updated by simply removing any manual spacing fudges (e.g.
manual spacing for headers).

B<Updates in v0.30> Version 0.30 has some fairly major changes, dropping
support of PDF::API2 and requiring use of PDF::Builder version 3.025. The
latter contains many updates and powerful new features to create feature-rich
PDF documents and means that PDF::TextBlock is no longer required for this
module, which uses PDF::Builder's new column() method instead.

=head1 METHODS

=cut

=head2 pdf

Returns the C<PDF::Builder> object used to create the PDF.

=cut

has pdf => (
    is => 'lazy',
);

sub _build_pdf
{   my $self = shift;

    # Now only supports PDF::Builder
    croak "Sorry, CtrlO::PDF no longer supports use of PDF::API2"
        if $self->PDFlib && $self->PDFlib =~ /api2/i;

    my $rc = eval {
        require PDF::Builder;# 3.025;
        1;
    };
    croak "CtrlO::PDF requires PDF::Builder 3.025"
        if !$rc;

    my $pdf = PDF::Builder->new;

    $pdf->add_font_path('/usr/share/fonts');
    # Retained for backwards compatibility and moved from being built in the
    # font() and fontbold() properties
    $pdf->add_font(
        face  => 'liberation-sans',
        type  => 'ttf',
        style => 'sans-serif',
        width => 'proportional',
        file  => {
            'roman'       => 'truetype/liberation/LiberationSans-Regular.ttf',
            'italic'      => 'truetype/liberation/LiberationSans-Italic.ttf',
            'bold'        => 'truetype/liberation/LiberationSans-Bold.ttf',
            'bold-italic' => 'truetype/liberation/LiberationSans-BoldItalic.ttf'
        },
    );

    $pdf;
}

=head2 page

Returns the current PDF page.

=cut

# Current page
has page => (
    is      => 'rwp',
    lazy    => 1,
    builder => sub { $_[0]->add_page },
);

=head2 add_page

Adds a PDF page and returns it.

Note that when a PDF page is added (either via this method or automatically)
the is_new_page flag records that a new page is in use with no content. See
that method for more details.

=cut

sub add_page
{   my $self = shift;
    my $page = $self->pdf->page;
    $page->mediabox(0, 0, $self->width, $self->height);
    $self->_set_page($page);
    $self->_set__y($self->_y_start_default); # Reset y cursor
    # Flag that we have just started a new page. Because text is positioned from
    # its bottom-left corner, we will need to move the cursor down further to
    # account for the font size of the text, but we don't know that yet.
    $self->_set_is_new_page(1);
    return $page;
}

=head2 is_new_page

Whether the current page is new with no content. When the heading or text
methods are called and this is true, additional top margin is added to account
for the height of the text being added. Any other content manually added will
not include this margin and will leave the internal new page flag as true.

=cut

has is_new_page => (
    is      => 'rwp',
    isa     => Bool,
    default => 1,
);

=head2 clear_new_page

Manually clears the is_new_page flag.

=cut

sub clear_new_page
{   my $self = shift;
    $self->_set_is_new_page(0);
}

=head2 orientation

Sets or returns the page orientation (portrait or landscape). The default is
Portrait (taller than wide).

=cut

has orientation => (
    is      => 'ro',
    isa     => Str,
    default => 'portrait',
);

=head2 PDFlib

Sets or returns the PDF-building library in use. The choices are "PDF::Builder"
and "PDF::API2" (case-insensitive). "PDF::Builder" is the default, indicating
that PDF::Builder will be used I<unless> it is not found, in which case
PDF::API2 will be used. If neither is found, CtrlO::PDF will fail.

=cut

has PDFlib => (
    is      => 'ro',
    isa     => Str,
    default => 'PDF::Builder',
);

=head2 font_size

Sets or returns the font size. Default is 10 (points).

=cut

has font_size => (
    is      => 'ro',
    isa     => Int,
    default => 10,
);

=head2 width

Sets or returns the width. Default is A4.

=cut

has width => (
    is  => 'lazy',
    isa => Int,
);

sub _build_width
{   my $self = shift;
    $self->orientation eq 'portrait' ? 595 : 842;  # A4 media
}

has _width_print => (
    is  => 'lazy',
    isa => Int,
);

sub _build__width_print
{   my $self = shift;
    $self->width - $self->margin * 2;
}

=head2 height

Sets or returns the height. Default is A4.

=cut

has height => (
    is  => 'lazy',
    isa => Int,
);

sub _build_height
{   my $self = shift;
    $self->orientation eq 'portrait' ? 842 : 595;  # A4 media
}

=head2 margin

Sets or returns the page margin. Default 40 pixels.

=cut

has margin => (
    is      => 'ro',
    isa     => Int,
    default => 40,
);

=head2 margin_top

Sets or returns the top margin. Defaults to the margin + top_padding +
room for the header (if defined) + room for the logo (if defined).

=cut

has margin_top => (
    is      => 'lazy',
    isa     => Num,
);

sub _build_margin_top
{   my $self = shift;
    my $size = $self->margin + $self->top_padding;
    $size += $self->_line_height($self->font_size) if $self->header;
    if ($self->logo)
    {
        $size += $self->logo_height;
        $size += $self->logo_padding;
    }
    return int $size;
};

=head2 margin_bottom

Sets or returns the bottom margin. Defaults to the margin + room for the
footer.

=cut

has margin_bottom => (
    is      => 'lazy',
    isa     => Int,
);

sub _build_margin_bottom
{   my $self = shift;
    return $self->margin + $self->_line_height($self->font_size);
};

=head2 top_padding

Sets or returns the top padding (additional to the margin). Default 0.

=cut

has top_padding => (
    is      => 'ro',
    isa     => Int,
    default => 0,
);

=head2 header

Sets or returns the header text.

=cut

has header => (
    is => 'ro',
);

=head2 footer

Sets or returns the footer text. Page numbers are added automatically.

=cut

has footer => (
    is => 'ro',
);

=head2 font

Sets or returns the font. This is based on PDF::Builder or PDF::API2 ttfont,
which returns a TrueType or OpenType font object. By default it assumes the
font is available in the exact path
C<truetype/liberation/LiberationSans-Regular.ttf>. A future
version may make this more flexible.

=cut

has font => (
    is => 'lazy',
);

sub _build_font
{   my $self = shift;
    $self->pdf->get_font(face => 'liberation-sans', 'italic' => 0, bold => 0);
}

=head2 fontbold

As font, but a bold font.

=cut

has fontbold => (
    is => 'lazy',
);

sub _build_fontbold
{   my $self = shift;
    $self->pdf->get_font(face => 'liberation-sans', 'italic' => 0, bold => 1);
}

=head2 logo

The path to a logo to include in the top-right corner of every page (optional).

=cut

has logo => (
    is  => 'ro',
    isa => Str,
);

=head2 logo_scaling

The scaling of the logo. For best results a setting of 0.5 is recommended (the
default).

=cut

has logo_scaling => (
    is      => 'ro',
    default => 0.5,
);

=head2 logo_padding

The padding below the logo before the text. Defaults to 10 pixels.

=cut

has logo_padding => (
    is      => 'ro',
    default => 10,
);

has logo_height => (
    is => 'lazy',
);

sub _build_logo_height
{   my $self = shift;
    return 0 if !$self->_logo_info;
    $self->_logo_info->{height} * $self->logo_scaling;
}

has logo_width => (
    is => 'lazy',
);

sub _build_logo_width
{   my $self = shift;
    return 0 if !$self->_logo_info;
    $self->_logo_info->{width} * $self->logo_scaling;
}

has _logo_info => (
    is => 'lazy',
);

sub _build__logo_info
{   my $self = shift;
    return if !$self->logo;
    image_info($self->logo);
}

has _x => (
    is      => 'rwp',
    lazy    => 1,
    builder => sub { $_[0]->margin },
);

sub _down
{   my ($self, $points) = @_;
    my $y = $self->_y;
    $self->_set__y($y - $points);
}

=head2 y_position

Returns the current y position on the page. This value updates as the page is
written to, and is the location that content will be positioned at the next
write. Note that the value is measured from the bottom of the page.

=cut

sub y_position
{   my $self = shift;
    $self->_y;
}

=head2 set_y_position($pixels)

Sets the current Y position. See L</y_position>.

=cut

sub set_y_position
{   my ($self, $y) = @_;
    $y && $y =~ /^-?[0-9]+(\.[0-9]+)?$/
        or croak "Invalid y value for set_y_position: $y";
    $self->_set__y($y);
}

=head2 move_y_position($pixels)

Moves the current Y position, relative to its current value. Positive values
will move the cursor up the page, negative values down. See L</y_position>.

=cut

sub move_y_position
{   my ($self, $y) = @_;
    $y && $y =~ /^-?[0-9]+(\.[0-9]+)?$/
        or croak "Invalid y value for move_y_position: $y";
    $self->_set__y($self->_y + $y);
}

has _y => (
    is      => 'rwp',
    lazy    => 1,
    builder => sub { $_[0]->_y_start_default },
);

sub _y_start_default
{   my $self = shift;
    return $self->height - $self->margin_top;
}

=head2 heading($text, %options)

Add a heading. If called on a new page, will automatically move the cursor down
to account for the heading's height (based on the assumption that one pixel
equals one point). Options available are:

=over

=item size I<n>

C<n> is the font size in points, B<default 16>

=item indent I<n>

C<n> is the amount (in points) to indent the text, B<default 0>

=item topmargin I<n>

C<n> is the amount (in points) of vertical skip for the margin I<above> the
heading, B<default:> calculated automatically based on font size

=item bottommargin I<n>

C<n> is the amount (in points) of vertical skip for the margin I<below> the
heading, B<default:> calculated automatically based on the font size

=back

=cut

# Return the line height based on a font size, with optional ratio
sub _line_height {
    my ($self, $size, $ratio) = @_;
    $size * ($ratio || 1.5);
}

# Return the spacing above/below a line based on font size and line height
sub _line_spacing {
    my ($self, $size) = @_;
    my $spacing = $self->_line_height($size);
    ($spacing - $size) / 2;
}

sub heading
{   my ($self, $string, %options) = @_;

    my $page = $self->page; # Ensure that page is built and cursor adjusted for first use

    $page = $self->add_page if $self->_y < 150; # Make sure there is room for following paragraph text
    my $size = $options{size} || 16;

    if ($options{topmargin}) {
        # Always let override take precedence
        $self->_down($options{topmargin}) if $options{topmargin};
    }
    elsif ($self->is_new_page)
    {
        # If a new page then move down just enough to fit in the font size
        $self->_down($size);
        $self->_set_is_new_page(0);
    }
    else {
        # Default to top margin based on font size, with slightly higher
        # spacing ratio than normal text
        $self->_down($self->_line_height($size, 1.8));
    }

    my $text   = $page->text;
    my $grfx   = $page->gfx;
    my $x      = $self->_x + ($options{indent} || 0),
    my $height = $self->_y - $self->margin_bottom;
    $text->font($self->fontbold, $size);
    $text->translate($x, $self->_y);
    $text->text($string);

    # Unless otherwise defined, add a bottom margin relative to the font size,
    # but smaller than the top margin
    my $bottommargin = defined $options{bottommargin}
        ? $options{bottommargin}
        : $self->_line_height($size, 0.4);

    $self->_down($bottommargin);
}

=head2 text($text, %options)

Add paragraph text. This will automatically paginate. Available options are
shown below. Any unrecogised options will be passed to C<PDF::Builder>'s Column
method.

=over

=item format I<name>

C<name> is the format of the text, in accordance with available formats in
C<PDF::Builder>. At the time of writing, supported options are C<none>, C<pre>,
C<md1> and C<html>. If unspecified defaults to C<none>.

=item size I<n>

C<n> is the font size in points, B<default 10>

=item indent I<n>

C<n> is the amount (in points) to indent the paragraph first line, B<default 0>

=item top_padding I<n>

C<n> is the amount (in points) of padding above the paragraph, only applied if
not at the top of a page. Defaults to half the line height.

=item color I<name>

C<name> is the string giving the text color, B<default 'black'>

=back

=cut

sub text
{   my ($self, $string, %options) = @_;

    $string or return;

    my $size = delete $options{size} || $self->font_size;
    my $color = delete $options{color} || 'black';
    my $format = delete $options{format} || 'none';

    my $page = $self->page; # Ensure that page is built and cursor adjusted for first use

    # Add new page if already at the bottom from previous operation (e.g.
    # rendering table)
    $page = $self->add_page
        if $self->_y - $self->_line_height($size) < $self->margin_bottom;

    my $text   = $page->text;
    my $grfx   = $page->gfx;
    my $x      = $self->_x + ($options{indent} || 0),
    my $height = $self->_y - $self->margin_bottom;

    $text->font($self->font, 10); # Any size, overridden below

    my $top_padding = defined $options{top_padding}
        ? $options{top_padding}
        : $self->_line_height($size) - $size;

    # Only create spacing if below other content
    if ($self->is_new_page)
    {
        $self->_set_is_new_page(0);
    }
    else {
        $self->_down($top_padding);
    }

    my ($rc, $next_y, $unused) = $text->column(
        $page, $text, $grfx, $format, $string,
        rect => [$x, $self->_y, $self->_width_print, $height],
        para => [0, $top_padding],
        font_size => $size,
        %options
    );

    my @last_unused;
    while ($rc) {
        # new page
        $page   = $self->add_page;
        $height = $self->_y - $self->margin_bottom;
        $text   = $page->text;
        $grfx   = $page->gfx;

        ($rc, $next_y, $unused) = $text->column($page, $text, $grfx, 'pre', $unused,
            rect => [$x, $self->_y, $self->_width_print, $height],
            para => [0, $top_padding],
            font_size => $size,
            %options,
        );
        $self->_set_is_new_page(0);
        last unless grep length $_->{text}, @$unused;

        # We need a safety mechanism in case column() does not successfully
        # print any of the text. In this situation, an infinite loop would
        # occur, so look for this condition and bail out if so.
        my @this_unused = grep length $_, map $_->{text}, @$unused;
        croak "Unable to print text to PDF: @this_unused"
            if "@last_unused" eq "@this_unused";
        @last_unused = @this_unused;
    }

    $self->_set__y($next_y);
}

=head2 table(%options)

Add a table, based on PDF::Table. Options available are C<data> to pass in the
data for the table; all other options are passed to the table method of
PDF::Table.

=cut

sub table
{   my ($self, %options) = @_;

    # Make sure we've got a page if this was the first time we've been called.
    $self->page;

    # Add a blank line above the table if we'd printed anything previously
    if ($self->is_new_page) {
        $self->_down($self->_line_height($self->font_size));
    }

    # Work out what sort of table we'd normally produce. Take a copy of the data because
    # it's passed by reference to PDF::Table, which chews through its arguments.
    my $table = PDF::Table->new;
    my @data = @{ delete $options{data} };
    my %dimensions = (
        next_h    => $self->_y_start_default - $self->margin_bottom,
        x         => $self->_x,
        w         => $self->_width_print,
        font_size => $self->font_size,
        padding   => 5,
        y         => $self->_y,
        h         => $self->_y - $self->margin_bottom,
        next_y    => $self->_y_start_default,
    );
    %options = (
        %dimensions,
        h_border_w    => 2,
        v_border_w    => 0,
        border_c      => '#dddddd',
        bg_color_odd  => '#f9f9f9',
        new_page_func => sub { $self->add_page },
        font          => $self->font,
        header_props => {
            font       => $self->fontbold,
            repeat     => 1,
            justify    => 'left',
            font_size  => $self->font_size,
            bg_color   => 'white',
            fg_color   => 'black',
        },
        %options,
    );

    # Would the table fit on the page in its current position? PDF::Table 1.006 crashes if the
    # header spans two page boundaries, and in any case we want at least the first row of the
    # table to fit on the page.
    # Returns: (0) total height of table, (1) height of header, (2) 0, (3) height of first
    # row, (4) height of second row etc. - note that "first row" means the first non-header
    # row.
    my @vsizes = $table->table($self->pdf, $self->page, [@data], %options, ink => 0);
    my $first_two_rows_height = $vsizes[1] + $vsizes[3];
    if ($self->y_position - $first_two_rows_height < $self->margin_bottom) {
        $self->add_page;
        $options{y} = $self->_y;
        $options{h} = $self->_y - $self->margin_bottom;
    }

    my ($final_page, $number_of_pages, $final_y) = $table->table(
        $self->pdf,
        $self->page,
        [@data],
        %options,
        ink => 1,
    );

    # Remember where we got to, and add another blank line below the table. This is definitely
    # not the start of a new page now.
    $self->_set__y($final_y);
    $self->_down($self->_line_height($self->font_size));
    $self->clear_new_page;
}

sub _image_type
{   my $file = shift;
    my $type = image_type($file);
    croak "Unable to identify image type for $file: ".$type->{Errno}
        if $type->{error};
    return $type->{file_type};
}

=head2 image($file, %options)

Add an image. Options available are:

=over

=item scaling I<n>

C<n> is the scaling factor for the image, B<default 0.5> (50%)

=item alignment I<name>

C<name> is the horizontal alignment, B<default center>

=back

=cut

sub image
{   my ($self, $file, %options) = @_;
    my $scaling  = $options{scaling} || 0.5;
    my $info = image_info($file);
    my $width = $info->{width};
    my $height = $info->{height};
    my $alignment = $options{alignment} || 'center';
    $height = $height * $scaling;
    $width  = $width * $scaling;
    $self->add_page if $height > $self->_y;
    $self->_down($height);
    my $x = $alignment eq 'left'
        ? $self->margin
        : $alignment eq 'right'
        ? $self->width - $self->margin - $width
        : ($self->width / 2) - ($width / 2);
    my $type = lc 'image_'._image_type($file);
    my $image = $self->pdf->$type($file);
    my $gfx = $self->page->gfx;
    $gfx->image($image, $x, $self->_y, $scaling);
    $self->clear_new_page;
}

=head2 content

Return the PDF content.

=cut

sub content
{   my $self = shift;

    my $logo;
    if ($self->logo)
    {
        my $type = lc 'image_'._image_type($self->logo);
        $logo = $self->pdf->$type($self->logo);
    }
    my $count  = $self->pdf->pages;
    foreach my $p (1..$count)
    {
        my $page = $self->pdf->openpage($p);
        if ($logo)
        {
            my $gfx   = $page->gfx;
            $gfx->image($logo, $self->width - $self->margin - $self->logo_width, $self->height - $self->margin - $self->logo_height, $self->logo_scaling);
        }
        my $text = $page->text;
        $text->font($self->font, 10);
        # Specify the header and footer color, otherwise it takes the color of
        # the last text block which can lead to unexpected behaviour. TODO:
        # Allow this to be defined somehow.
        $text->fillcolor('black');
        if (my $header = $self->header)
        {
            $text->translate(int($self->width / 2), $self->height - $self->margin);
            $text->text_center($header);
        }
        $text->translate($self->width - $self->margin, $self->margin);
        $text->text_right("Page $p of $count");
        if (my $footer = $self->footer)
        {
            $text->translate($self->margin, $self->margin);
            $text->text($footer);
        }
    }

    $self->pdf->stringify;
}

=head1 LICENSE AND COPYRIGHT

Copyright 2018-2021 Ctrl O Ltd

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License (GPL) as published by the
Free Software Foundation; or the Perl Artistic License (PAL).

See http://dev.perl.org/licenses/ for more information.

=cut

1;
