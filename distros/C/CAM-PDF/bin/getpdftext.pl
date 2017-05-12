#!/usr/bin/perl -w

package main;

use warnings;
use strict;
use CAM::PDF;
use Getopt::Long;
use Pod::Usage;

our $VERSION = '1.60';

my %opts = (
            check      => 0,
            geom       => 0,
            verbose    => 0,
            help       => 0,
            version    => 0,
            );

Getopt::Long::Configure('bundling');
GetOptions('g|geometry' => \$opts{geom},
           'c|check'    => \$opts{check},
           'v|verbose'  => \$opts{verbose},
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

if (@ARGV < 1)
{
   pod2usage(1);
}

my $file = shift;
my $pagelist = shift;

my $doc = CAM::PDF->new($file) || die "$CAM::PDF::errstr\n";

foreach my $p ($doc->rangeToArray(1,$doc->numPages(),$pagelist))
{
   if ($opts{check})
   {
      print "Checking page $p\n";
      my $tree = $doc->getPageContentTree($p, $opts{verbose});
      if (!$tree || !$tree->validate())
      {
         print "  Failed\n";
      }
      if ($opts{geom})
      {
         $tree->computeGS();
      }
   }
   else
   {
      my $str = $doc->getPageText($p, $opts{verbose});
      if (defined $str)
      {
         CAM::PDF->asciify(\$str);
         print $str;
      }
   }
}


__END__

=for stopwords getpdftext.pl

=head1 NAME

getpdftext.pl - Extracts and print the text from one or more PDF pages

=head1 SYNOPSIS

 getpdftext.pl [options] infile.pdf [<pagenums>]

 Options:
   -c --check          just validates the page instead of printing it
   -g --geometry       just computes geometry, prints nothing
   -v --verbose        print diagnostic messages
   -h --help           verbose help message
   -V --version        print CAM::PDF version

 <pagenums> is a comma-separated list of page numbers.
      Ranges like '2-6' allowed in the list
      Example: 4-6,2,12,8-9

=head1 DESCRIPTION

Extracts all of the text from the specified PDF page(s) and prints
them to STDOUT.  If no pages are specified, all pages are processed.

The C<--check> and C<--geometry> modes are distinctly different.  They are
used primarily for debugging.

=head1 SEE ALSO

CAM::PDF

F<renderpdf.pl>

=head1 AUTHOR

See L<CAM::PDF>

=cut
