# NAME

CtrlO::PDF - high level PDF creator

# SYNOPSIS

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

    # From version 0.34 (and PDF::Builder 3.028) it is possible to produce
    # internal links in PDFs. For example:
    $pdf->text(<<'__MARKDOWN', format => 'md1');
    Go to an [internal link](link-elsewhere) somewhere else in this PDF.

    ---

    # System2 Configuration - Overview {#link-elsewhere}
    __MARKDOWN

# DESCRIPTION

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

**Updates in v0.20** Note that version 0.20 contains a number breaking changes
to improve the default layout and spacing of a page. This better ensures that
content added to a page "just works" in terms of its layout, without needing
tweaks to its spacing. For example, headers have better spacing above and below
by default. This means that PDFs produced with this version will be laid out
differently to those produced with earlier versions. In the main, old code
should be able to be updated by simply removing any manual spacing fudges (e.g.
manual spacing for headers).

**Updates in v0.30** Version 0.30 has some fairly major changes, dropping
support of PDF::API2 and requiring use of PDF::Builder version 3.025. The
latter contains many updates and powerful new features to create feature-rich
PDF documents and means that PDF::TextBlock is no longer required for this
module, which uses PDF::Builder's new column() method instead.

# CONSTRUCTOR

## new

The constructor is called `new`, and accepts a optional hash of options.
Valid options are mainly the same as all the methods described below, for those
that get and set options. Some methods are read-only and must be set as options
to the constructor, others can be set later.

# METHODS

## pdf

Returns the `PDF::Builder` object used to create the PDF.

## page

Returns the current PDF page.

## add\_page

Adds a PDF page and returns it.

Note that when a PDF page is added (either via this method or automatically)
the is\_new\_page flag records that a new page is in use with no content. See
that method for more details.

## is\_new\_page

Whether the current page is new with no content. When the heading or text
methods are called and this is true, additional top margin is added to account
for the height of the text being added. Any other content manually added will
not include this margin and will leave the internal new page flag as true.

## clear\_new\_page

Manually clears the is\_new\_page flag.

## orientation

Sets or returns the page orientation (portrait or landscape). The default is
Portrait (taller than wide).

## PDFlib

Sets or returns the PDF-building library in use. The choices are "PDF::Builder"
and "PDF::API2" (case-insensitive). "PDF::Builder" is the default, indicating
that PDF::Builder will be used _unless_ it is not found, in which case
PDF::API2 will be used. If neither is found, CtrlO::PDF will fail.

## font\_size

Sets or returns the font size. Default is 10 (points).

## width

Sets or returns the width. Default is A4.

## height

Sets or returns the height. Default is A4.

## margin

Sets or returns the page margin. Default 40 pixels.

## margin\_top

Sets or returns the top margin. Defaults to the margin + top\_padding +
room for the header (if defined) + room for the logo (if defined).

## margin\_bottom

Sets or returns the bottom margin. Defaults to the margin + room for the
footer.

## top\_padding

Sets or returns the top padding (additional to the margin). Default 0.

## header

Sets or returns the header text.

## footer

Sets or returns the footer text. Page numbers are added automatically.

## font

Sets or returns the font. This is based on PDF::Builder or PDF::API2 ttfont,
which returns a TrueType or OpenType font object. By default it assumes the
font is available in the exact path
`truetype/liberation/LiberationSans-Regular.ttf`. A future
version may make this more flexible.

## fontbold

As font, but a bold font.

## logo

The path to a logo to include in the top-right corner of every page (optional).

## logo\_scaling

The scaling of the logo. For best results a setting of 0.5 is recommended (the
default).

## logo\_padding

The padding below the logo before the text. Defaults to 10 pixels.

## y\_position

Returns the current y position on the page. This value updates as the page is
written to, and is the location that content will be positioned at the next
write. Note that the value is measured from the bottom of the page.

## set\_y\_position($pixels)

Sets the current Y position. See ["y\_position"](#y_position).

## move\_y\_position($pixels)

Moves the current Y position, relative to its current value. Positive values
will move the cursor up the page, negative values down. See ["y\_position"](#y_position).

## heading($text, %options)

Add a heading. If called on a new page, will automatically move the cursor down
to account for the heading's height (based on the assumption that one pixel
equals one point). Options available are:

- size _n_

    `n` is the font size in points, **default 16**

- indent _n_

    `n` is the amount (in points) to indent the text, **default 0**

- topmargin _n_

    `n` is the amount (in points) of vertical skip for the margin _above_ the
    heading, **default:** calculated automatically based on font size

- bottommargin _n_

    `n` is the amount (in points) of vertical skip for the margin _below_ the
    heading, **default:** calculated automatically based on the font size

## text($text, %options)

Add paragraph text. This will automatically paginate. Available options are
shown below. Any unrecogised options will be passed to `PDF::Builder`'s Column
method.

- format _name_

    `name` is the format of the text, in accordance with available formats in
    `PDF::Builder`. At the time of writing, supported options are `none`, `pre`,
    `md1` and `html`. If unspecified defaults to `none`.

- size _n_

    `n` is the font size in points, **default 10**

- indent _n_

    `n` is the amount (in points) to indent the paragraph first line, **default 0**

- top\_padding _n_

    `n` is the amount (in points) of padding above the paragraph, only applied if
    not at the top of a page. Defaults to half the line height.

- color _name_

    `name` is the string giving the text color, **default 'black'**

## table(%options)

Add a table, based on PDF::Table. Options available are `data` to pass in the
data for the table; all other options are passed to the table method of
PDF::Table.

## image($file, %options)

Add an image. Options available are:

- scaling _n_

    `n` is the scaling factor for the image, **default 0.5** (50%)

- alignment _name_

    `name` is the horizontal alignment, **default center**

## has\_state

A boolean dictating whether the version of PDF::Builder in use supports state
functionality, to retain information across multiple pages.

## state

A hashref to configure and store the PDF::Builder state information. By default
this is built automatically using `PDF::Builder->init_state()` and includes
configuration for the use of id parameters in header tags (enabling internal
linking). See the [PDF::Builder](https://metacpan.org/pod/PDF%3A%3ABuilder%3A%3AContent%3A%3AColumn_docs#init_state)
documentation for more information.

## content

Return the PDF content.

# LICENSE AND COPYRIGHT

Copyright 2018-2026 Ctrl O Ltd

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License (GPL) as published by the
Free Software Foundation; or the Perl Artistic License (PAL).

See http://dev.perl.org/licenses/ for more information.
