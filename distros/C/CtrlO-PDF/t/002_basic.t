use Test::More tests => 1;
use strict;
use warnings;

use CtrlO::PDF;

# The following tests don't actually check the output of a PDF, but check that
# it can be produced. TODO: Add image tests of valid and invalid image files.

my $pdf = CtrlO::PDF->new(
#  logo        => "logo.png", # XXX Where to put an image for testing?
  footer      => "My PDF document footer",
);

# Add a page
$pdf->add_page;

# Add headings
$pdf->heading('This is the main heading');
$pdf->heading('This is a sub-heading', size => 12);

# Add paragraph text
$pdf->text("Foobar");

ok($pdf->content, "Some PDF content produced");
