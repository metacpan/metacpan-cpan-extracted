package CtrlO::PDF;

use strict;
use warnings;
use utf8;

use Carp qw/croak carp/;
use Image::Info qw(image_info image_type);
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use PDF::Table;
use PDF::TextBlock 0.13;

our $VERSION = '0.20';

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
      PDFlib       => "API2",            # Default is Builder
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
module. Also, it is built on either PDF::Builder or PDF::API2, and provides
access to that object, so content can also be added directly using that,
thereby providing any powerful features required.

B<Updates in v0.20> Note that version 0.20 contains a number breaking changes
to improve the default layout and spacing of a page. This better ensures that
content added to a page "just works" in terms of its layout, without needing
tweaks to its spacing. For example, headers have better spacing above and below
by default. This means that PDFs produced with this version will be laid out
differently to those produced with earlier versions. In the main, old code
should be able to be updated by simply removing any manual spacing fudges (e.g.
manual spacing for headers).

=head1 METHODS

=cut

=head2 pdf

Returns the C<PDF::Builder> or C<PDF::API2> object used to create the PDF.

=cut

has pdf => (
    is => 'lazy',
);

sub _build_pdf
{   my $self = shift;

    # what's available?
    my ($rc);
    if (lc($self->PDFlib) =~ m/b/) {
        # PDF::Builder preferred, try to see if it's installed
        $rc = eval {
            require PDF::Builder;
            1;
        };
        if (!defined $rc) {
            # PDF::Builder not available, try PDF::API2
            $rc = eval {
                require PDF::API2;
                1;
            };
            if (!defined $rc) {
                die "Neither PDF::Builder nor PDF::API2 is installed!\n";
            } else {
                #print "PDF::Builder requested, but was not available. Using PDF::API2\n";
                PDF::API2->new;
            }
        } else {
            PDF::Builder->new;
        }

    } else {
        # PDF::API2 preferred, try to see if it's installed
        $rc = eval {
            require PDF::API2;
            1;
        };
        if (!defined $rc) {
            # PDF::API2 not available, try PDF::Builder
            $rc = eval {
                require PDF::Builder;
                1;
            };
            if (!defined $rc) {
                die "Neither PDF::API2 nor PDF::Builder is installed!\n";
            } else {
                #print "PDF::API2 requested, but was not available. Using PDF::Builder\n";
                PDF::Builder->new;
            }
        } else {
            PDF::API2->new;
        }

    }

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
    isa     => Int,
);

sub _build_margin_top
{   my $self = shift;
    my $size = $self->margin + $self->top_padding;
    $size += 15 if $self->header; # Arbitrary number to allow 10px of header text
    if ($self->logo)
    {
        $size += $self->logo_height;
        $size += $self->logo_padding;
    }
    return $size;
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
    my $size = $self->margin;
    $size += 15; # Arbitrary number to allow 10px of footer text
    return $size;
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
    $y && $y =~ /^[0-9]+$/
        or croak "Invalid y value for set_y_position: $y";
    $self->_set__y($y);
}

=head2 move_y_position($pixels)

Moves the current Y position, relative to its current value. Positive values
will move the cursor up the page, negative values down. See L</y_position>.

=cut

sub move_y_position
{   my ($self, $y) = @_;
    $y && $y =~ /^[0-9]+$/
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

    $self->page; # Ensure that page is built and cursor adjusted for first use

    $self->add_page if $self->_y < 150; # Make sure there is room for following paragraph text
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
    my $tb  = PDF::TextBlock->new({
        pdf  => $self->pdf,
        page => $self->page,
        x    => $self->_x + ($options{indent} || 0),
        y    => $self->_y,
        lead => $self->_line_height($size, 1.6),
        fonts => {
            # Workaround a bug in PDF::TextBlock which defines word spacing
            # based on the default font. This can lead to spacing that is too
            # small if only using a bold font with a large font size. Define
            # the default font to be the same as the bold font that we will
            # use.
            default => PDF::TextBlock::Font->new({
                pdf  => $self->pdf,
                font => $self->fontbold,
                size => $size,
            }),
            b => PDF::TextBlock::Font->new({
                pdf  => $self->pdf,
                font => $self->fontbold,
                size => $size,
            }),
        },
    });
    $tb->text('<b>'.$string.'</b>');
    my ($endw, $ypos) = $tb->apply;
    $self->_set__y($ypos + $self->_line_height($size)); # Move cursor back to end of last line printed

    # Unless otherwise defined, add a bottom margin relative to the font size,
    # but smaller than the top margin
    my $bottommargin = defined $options{bottommargin} ? $options{bottommargin} : $self->_line_height($size, 0.4);;

    $self->_down($bottommargin);
}

=head2 text($text, %options)

Add paragraph text. This will automatically paginate. Options available are:

=over

=item size I<n>

C<n> is the font size in points, B<default 10>

=item indent I<n>

C<n> is the amount (in points) to indent the paragraph first line, B<default 0>

=item color I<name>

C<name> is the string giving the text color, B<default 'black'>

=back

=cut

sub text
{   my ($self, $string, %options) = @_;
    my $text = $self->page->text;
    my $size = $options{size} || 10;
    my $color = $options{color} || 'black';

    $self->page; # Ensure that page is built and cursor adjusted for first use

    if ($self->is_new_page)
    {
        $self->_set_is_new_page(0);
    }
    else {
        # Only create spacing if below other content
        $self->_down($self->_line_spacing($size));
    }

    # Line spacing already accounted for above, now allow enough room for actual font size
    $self->_down($size);

    my $tb  = PDF::TextBlock->new({
        pdf   => $self->pdf,
        page  => $self->page,
        x     => $self->_x + ($options{indent} || 0),
        y     => $self->_y,
        w     => $self->_width_print,
        h     => $self->_y - $self->margin_bottom,
        lead  => $self->_line_height($size),
        align => 'left',
        fonts => {
            default => PDF::TextBlock::Font->new({
                pdf       => $self->pdf,
                font      => $self->font,
                size      => $size,
                fillcolor => $color,
            }),
            b => PDF::TextBlock::Font->new({
                pdf       => $self->pdf,
                font      => $self->fontbold,
                size      => $size,
                fillcolor => $color,
            }),
        },
    });
    while (1)
    {
        # First check whether there is any room on the page for the text. If
        # not, start a new page. This code is copied directly from the same
        # check in PDF::TextBlock, with 15 being the default lead. We can no
        # longer rely on PDF::TextBlock returning the same $string to know to
        # insert a new page, as we now use that to check for words that are too
        # long
        if ($tb->y >= $tb->y - $tb->h + 15) # Same condition as PDF::TextBlock
        {
            # For reasons I do not understand, $string manages to gain newlines
            # between the end and beginning of this loop. Chop them off, and end if
            # there's nothing left
            $string =~ s/\s+$//;
            !$string and last;
            $tb->text($string);
            my $endw; my $ypos;
            my $string_before = $string;
            ($endw, $ypos, $string) = $tb->apply;
            # Check whether no text has been added to the page. This happens if the
            # word is too long. If so, warn, chop-off and retry, otherwise an
            # infinite loop occurs. Ideally the word would be broken - issue will
            # be raised in PDF::TextBlock to see if this is possible.
            if ($string_before eq $string)
            {
                carp "Unable to fit text onto line: $string";
                # If no more breaks then skip
                last if $string !~ /\s/;
                # Otherwise start from after next break
                $string =~ s/\S+\s//;
                $tb->text($string);
                ($endw, $ypos, $string) = $tb->apply;
            }

            # Set y cursor to be where the textblock finished, but move cursor
            # back up to remove new line
            $self->_set__y($ypos + $tb->lead);
            # Now shift down the actual line spacing distance
            $self->_down($self->_line_spacing($size));
            last unless $string; # while loop does not work with $string
        }
        $self->add_page;
        $self->_down($size);
        $tb  = PDF::TextBlock->new({
            pdf   => $self->pdf,
            page  => $self->page,
            x     => $self->_x,
            y     => $self->_y,
            w     => $self->_width_print,
            h     => $self->_y - $self->margin_bottom,
            lead  => $self->_line_height($size),
            align => 'left',
            fonts => {
                default => PDF::TextBlock::Font->new({
                    pdf       => $self->pdf,
                    font      => $self->font,
                    size      => $size,
                    fillcolor => $color,
                }),
                b => PDF::TextBlock::Font->new({
                    pdf       => $self->pdf,
                    font      => $self->fontbold,
                    size      => $size,
                    fillcolor => $color,
                }),
            },
        });
    }
}

=head2 table(%options)

Add a table, based on PDF::Table. Options available are C<data> to pass in the
data for the table; all other options are passed to the table method of
PDF::Table.

=cut

sub table
{   my ($self, %options) = @_;

    $self->page; # Ensure that page is built and cursor adjusted for first use

    # Move onto new page if little space left on this one.
    # TODO Change arbitary "60" to something calculated? Needs to be able to
    # fit header and one row as a minimum.
    $self->add_page if $self->_y < 60 + $self->margin_bottom;

    my $table = PDF::Table->new;

    my $data = delete $options{data};

    # Create spacing above and below table based on the line spacing for text
    # of 10 points
    $self->_down($self->_line_height(10));

    # Keep separate so easy to dump for debug
    my %dimensions = (
        next_h    => $self->_y_start_default - $self->margin_bottom,
        x         => $self->_x,
        w         => $self->_width_print,
        font_size => 10,
        padding   => 5,
        y         => $self->_y,
        h         => $self->_y - $self->margin_bottom,
        next_y    => $self->_y_start_default,
    );
    my ($final_page, $number_of_pages, $final_y) = $table->table(
        $self->pdf,
        $self->page,
        $data,
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
            font_size  => 10,
            bg_color   => 'white',
            fg_color   => 'black',
        },
        %options,
    );
    $self->clear_new_page;
    $self->_set__y($final_y);
    # As above, padding below table
    $self->_down($self->_line_height(10));
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
