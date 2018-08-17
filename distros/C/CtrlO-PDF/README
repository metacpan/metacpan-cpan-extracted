# NAME 

CtrlO::PDF - high level PDF creator

# SYNOPSIS

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

# DESCRIPTION

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

# METHODS

## pdf

Returns the `PDF::API2` object used to create the PDF.

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

Sets or returns the page orientation (portrait or landscape). Portrait is default.

## width

Sets or returns the width. Default is A4.

## height

Sets or returns the height. Default is A4.

## margin

Sets or returns the page margin. Default 40 pixels.

## top\_padding

Sets or returns the top padding (additional to the margin). Default 0.

## footer

Sets or returns the footer text. Page numbers are added automatically.

## font

Sets or returns the font. This is based on PDF::API2 ttfont which returns a
TrueType or OpenType font object. By default it assumes the font is available
in the exact path `truetype/liberation/LiberationSans-Regular.ttf`. A future
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

## heading($text, %options)

Add a heading. If called on a new page, will automatically move the cursor down
to account for the heading's height (based on the assumption that one pixel
equals one point). Options available are `size`, `topmargin` and
`bottommargin`.

## text($text, %options)

Add paragraph text. This will automatically paginate. Options available are `color`.

## table(%options)

Add a table, based on PDF::Table. Options available are `data` to pass in the
data for the table; all other options are passed to the table method of
PDF::Table.

## image($file, %options)

Add an image. Options available are `scaling`.

## content

Return the PDF content.

# LICENSE AND COPYRIGHT

Copyright 2018 Ctrl O Ltd

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
