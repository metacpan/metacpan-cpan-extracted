#!/usr/bin/perl

use warnings;
use strict;
use CAM::PDF;
use Getopt::Long;
use Pod::Usage;

our $VERSION = '1.60';

my %opts = (
   order      => 0,
   verbose    => 0,
   help       => 0,
   version    => 0,
);

Getopt::Long::Configure('bundling');
GetOptions('v|verbose'  => \$opts{verbose},
           'o|order'    => \$opts{order},
           'h|help'     => \$opts{help},
           'V|version'  => \$opts{version},
           ) or pod2usage(1);
if ($opts{help})
{
   pod2usage(-exitstatus => 0, -verbose => 2);
}
if ($opts{version})
{
   print "CAM::PDF v$CAM::PDF::VERSION\n";
   exit 0;
}
if (@ARGV < 3)
{
   pod2usage(1);
}

my $infile = shift || q{-};
my $pagenum  = shift || 1;
my $bgcolor  = shift || 'ffffff';
my $outfile  = shift || q{-};

my ($red, $blue, $green);

if ($bgcolor =~ m/ \A [\da-fA-F]{3} \z /xms)
{
   # For example, "f60" becomes "ff6600"
   my $rd = substr $bgcolor, 0, 1;
   my $gr = substr $bgcolor, 1, 1;
   my $bl = substr $bgcolor, 2, 1;
   $bgcolor = "$rd$rd$gr$gr$bl$bl";
}
if ($bgcolor =~ m/ \A [\da-fA-F]{6} \z /xms)
{
   $red   = hex substr $bgcolor, 0, 2;
   $green = hex substr $bgcolor, 2, 2;
   $blue  = hex substr $bgcolor, 4, 2;

   $red   /= 256.0;
   $green /= 256.0;
   $blue  /= 256.0;
}
else
{
   die 'Invalid color specified.  Should be "rrggbb" or "rgb"';
}

my $doc = CAM::PDF->new($infile) || die "$CAM::PDF::errstr\n";
my ($x,$y,$w,$h) = $doc->getPageDimensions($pagenum);

my $bg =
    'q ' .                    # Start a new graphics state
    "$red $blue $green rg " . # Set the fill color
    "$x $y $w $h re " .       # Mark a rectangle the size of the page
    'f ' .                    # Fill the rectangle
    'Q ';                     # End the graphics state

# Prepend the background fill
$doc->setPageContent($pagenum, $bg . $doc->getPageContent($pagenum));
if ($opts{order})
{
   $doc->preserveOrder();
}
if (!$doc->canModify())
{
   die "This PDF forbids modification\n";
}
$doc->cleanoutput($outfile);


__END__

=for stopwords setpdfbackground.pl Cowgill RGB

=head1 NAME

setpdfbackground.pl - Apply a background color to a PDF page

=head1 SYNOPSIS

 setpdfbackground.pl [options] file.pdf pagenum color [outfile]

 Options:
   -o --order          preserve the internal PDF ordering for output
   -v --verbose        print the internal representation of the PDF
   -h --help           verbose help message
   -V --version        print CAM::PDF version

The C<color> is specified as 3 or 6 character hexadecimal RGB.  For
example, C<f00> and C<ff0000> both mean pure red while C<999> and
C<999999> both mean medium gray.

=head1 DESCRIPTION

This program alters a PDF document to add a solid background color
behind the page contents.

=head1 CAVEATS

Some PDF creation programs assume a white background and draw bogus
white rectangles all over the screen that you usually cannot see.  If
your PDF has such rectangles, you I<can> sometimes fix it, but it is a
pain.  The best recommendation is to recreate the original PDF using a
smarter library, if possible.  Alternatively, you can contact Clotho
Advanced Media for a commercial solution to this problem.

=head1 CREDIT

This feature was originally requested by Brent Cowgill.

=head1 SEE ALSO

CAM::PDF

F<rewritepdf.pl>

=head1 AUTHOR

See L<CAM::PDF>

=cut
