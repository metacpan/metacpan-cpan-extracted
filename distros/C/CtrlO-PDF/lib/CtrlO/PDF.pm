package CtrlO::PDF;

use strict;
use warnings;
use utf8;

use Carp qw/croak/;
use Image::Info qw(image_info image_type);
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use PDF::API2;
use PDF::Table;
use PDF::TextBlock;

our $VERSION = '0.01';

=head1 NAME 

CtrlO::PDF - high level PDF creator

=head1 SYNOPSIS

  use CtrlO::PDF;
  use Text::Lorem;

  my $pdf = CtrlO::PDF->new(
      logo        => "logo.png",
      orientation => "portrait", # Default
      footer      => "My PDF document footer",
  );

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

=head1 DESCRIPTION

This module tries to make it easy to create PDFs by providing a high level
interface to a number of existing PDF modules. It aims to "do the right thing"
by default, allowing minimal coding to create long PDFs. It includes
pagination, headings, paragraph text, images and tables. Although there are a
number of other modules to create PDFs with a high-level interface, I found
that these each lack certain features (e.g. image insertion, paragraph text).
This module tries to include each of those features through another existing
module. Also, it is built on PDF::API2, and provides access to that object, so
content can also be added directly using that, thereby providing any powerful
features required.

=head1 METHODS

=cut

=head2 pdf

Returns the C<PDF::API2> object used to create the PDF.

=cut

has pdf => (
    is => 'lazy',
);

sub _build_pdf
{   my $self = shift;
    PDF::API2->new;
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

Sets or returns the page orientation (portrait or landscape). Portrait is default.

=cut

has orientation => (
    is      => 'ro',
    isa     => Str,
    default => 'portrait',
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
    $self->orientation eq 'portrait' ? 595 : 842;
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
    $self->orientation eq 'portrait' ? 842 : 595;
}

=head2 margin

Sets or returns the page margin. Default 40 pixels.

=cut

has margin => (
    is      => 'ro',
    isa     => Int,
    default => 40,
);

=head2 top_padding

Sets or returns the top padding (additional to the margin). Default 0.

=cut

has top_padding => (
    is      => 'ro',
    isa     => Int,
    default => 0,
);

=head2 footer

Sets or returns the footer text. Page numbers are added automatically.

=cut

has footer => (
    is => 'ro',
);

=head2 font

Sets or returns the font. This is based on PDF::API2 ttfont which returns a
TrueType or OpenType font object. By default it assumes the font is available
in the exact path C<truetype/liberation/LiberationSans-Regular.ttf>. A future
version may make this more flexible.

=cut

has font => (
    is => 'lazy',
);

sub _build_font
{   my $self = shift;
    $self->pdf->ttfont('truetype/liberation/LiberationSans-Regular.ttf');
}

=head2 fontbold

As font, but a bold font.

=cut

has fontbold => (
    is => 'lazy',
);

sub _build_fontbold
{   my $self = shift;
    $self->pdf->ttfont('truetype/liberation/LiberationSans-Bold.ttf');
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
    $self->_logo_info->{height} * $self->logo_scaling;
}

has logo_width => (
    is => 'lazy',
);

sub _build_logo_width
{   my $self = shift;
    $self->_logo_info->{width} * $self->logo_scaling;
}

has _logo_info => (
    is => 'lazy',
);

sub _build__logo_info
{   my $self = shift;
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

has _y => (
    is      => 'rwp',
    lazy    => 1,
    builder => sub { $_[0]->_y_start_default },
);

sub _y_start_default
{   my $self = shift;
    $self->height - $self->margin - $self->top_padding;
}

=head2 heading($text, %options)

Add a heading. If called on a new page, will automatically move the cursor down
to account for the heading's height (based on the assumption that one pixel
equals one point). Options available are C<size>, C<topmargin> and
C<bottommargin>.

=cut

sub heading
{   my ($self, $string, %options) = @_;
    $self->_down($options{topmargin}) if $options{topmargin};
    $self->add_page if $self->_y < 150; # Make sure there is room for following paragraph text
    my $size = $options{size} || 16;
    if ($self->is_new_page)
    {
        $self->_down($size);
        $self->_set_is_new_page(0);
    }
    my $tb  = PDF::TextBlock->new({
        pdf  => $self->pdf,
        page => $self->page,
        x    => $self->_x,
        y    => $self->_y,
        fonts => {
            b => PDF::TextBlock::Font->new({
                pdf  => $self->pdf,
                font => $self->fontbold,
                size => $size,
            }),
        },
    });
    $tb->text('<b>'.$string.'</b>');
    my ($endw, $ypos) = $tb->apply;
    $self->_set__y($ypos);
    my $bottommargin = defined $options{bottommargin} ? $options{bottommargin} : 10; # Allow zero
    $self->_down($bottommargin) if $bottommargin;
}

=head2 text($text, %options)

Add paragraph text. This will automatically paginate. Options available are C<color>.

=cut

sub text
{   my ($self, $string, %options) = @_;
    my $text = $self->page->text;
    my $size = 10;
    $text->font($self->font, $size);
    $text->translate($self->_x, $self->_y);
    $text->fillcolor($options{color}) if $options{color};

    if ($self->is_new_page)
    {
        $self->_down($size);
        $self->_down($self->logo_height);
        $self->_down($self->logo_padding);
        $self->_set_is_new_page(0);
    }

    my $tb  = PDF::TextBlock->new({
        pdf   => $self->pdf,
        page  => $self->page,
        x     => $self->_x,
        y     => $self->_y,
        w     => $self->_width_print,
        h     => $self->_y - $self->margin - 30,
        align => 'left',
        fonts => {
            b => PDF::TextBlock::Font->new({
                pdf  => $self->pdf,
                font => $self->fontbold,
            }),
        },
    });
    while (1)
    {
        # For reasons I do not understand, $string manages to gain newlines
        # between the end and beginning of this loop. Chop them off, and end if
        # there's nothing left
        $string =~ s/\s+$//;
        !$string and last;
        $tb->text($string);
        my $endw; my $ypos;
        ($endw, $ypos, $string) = $tb->apply;
        $self->_set__y($ypos);
        last unless $string; # while loop does not work with $string
        $self->add_page;
        $self->_down($size);
        $self->_down($self->logo_height);
        $self->_down($self->logo_padding);
        $tb  = PDF::TextBlock->new({
            pdf   => $self->pdf,
            page  => $self->page,
            x     => $self->_x,
            y     => $self->_y,
            w     => $self->_width_print,
            h     => $self->_y - $self->margin - 30,
            align => 'left',
            fonts => {
                b => PDF::TextBlock::Font->new({
                    pdf  => $self->pdf,
                    font => $self->fontbold,
                }),
            },
        });
    }

    $text->fillcolor('black') if $options{color}; # Reset color
    $self->_down(5);
}

=head2 table(%options)

Add a table, based on PDF::Table. Options available are C<data> to pass in the
data for the table; all other options are passed to the table method of
PDF::Table.

=cut

sub table
{   my ($self, %options) = @_;

    my $table = PDF::Table->new;

    my $data = delete $options{data};

    # Keep separate so easy to dump for debug
    my %dimensions = (
        next_h    => $self->height - $self->margin - ($self->height - $self->_y_start_default) - $self->margin,
        x         => $self->_x,
        w         => $self->_width_print,
        font_size => 10,
        padding   => 5,
        start_y   => $self->_y,
        start_h   => $self->height - ($self->height - $self->_y) - $self->margin - 40, # additional space for footer
        next_y    => $self->height - $self->margin - ($self->height - $self->_y_start_default),
    );
    my ($final_page, $number_of_pages, $final_y) = $table->table(
        $self->pdf,
        $self->page,
        $data,
        %dimensions,
        horizontal_borders => 2,
        vertical_borders   => 0,
        border_color => '#dddddd',
        background_color_odd => '#f9f9f9',
        new_page_func => sub { $self->add_page },
        font          => $self->font,
        header_props => {
            font       => $self->fontbold,
            repeat     => 1,
            justify    => 'left',
            font_size  => 10,
            bg_color   => 'white',
            font_color => 'black',
        },
        %options,
    );
    $self->_set__y($final_y);
    $self->_down(20);
}

sub _image_type
{   my $file = shift;
    my $type = image_type($file);
    croak "Unable to identify image type for $file: ".$type->{Errno}
        if $type->{error};
    return $type->{file_type};
}

=head2 image($file, %options)

Add an image. Options available are C<scaling>.

=cut

sub image
{   my ($self, $file, %options) = @_;
    my $scaling  = $options{scaling} || 0.5;
    my $info = image_info($file);
    my $width = $info->{width};
    my $height = $info->{height};
    $height = $height * $scaling;
    $width  = $width * $scaling;
    $self->add_page if $height > $self->_y;
    $self->_down($height);
    my $x = ($self->width / 2) - ($width / 2);
    my $type = lc 'image_'._image_type($file);
    my $image = $self->pdf->$type($file);
    my $gfx = $self->page->gfx;
    $gfx->image($image, $x, $self->_y, $scaling);
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

Copyright 2018 Ctrl O Ltd

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
