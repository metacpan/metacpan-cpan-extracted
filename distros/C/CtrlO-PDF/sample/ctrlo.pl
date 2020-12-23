use warnings;
use strict;
# not shipped as part of package
# update synopsis to write out $file to "out.pdf"

use CtrlO::PDF;
use Text::Lorem;

my $pdf = CtrlO::PDF->new(
    logo        => "sample/logo.png",
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
# output the file
#$pdf->end;

open my $pdf_out, '>', 'out.pdf';
binmode $pdf_out;
print $pdf_out $file;
close $pdf_out;
