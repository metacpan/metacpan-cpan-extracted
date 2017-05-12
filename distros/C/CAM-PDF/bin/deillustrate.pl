#!/usr/bin/perl -w

package main;

use warnings;
use strict;
use CAM::PDF;
use Getopt::Long;
use Pod::Usage;

our $VERSION = '1.60';

my %opts = (
            verbose     => 0,
            order       => 0,
            help        => 0,
            version     => 0,
            );

Getopt::Long::Configure('bundling');
GetOptions('v|verbose'     => \$opts{verbose},
           'o|order'       => \$opts{order},
           'h|help'        => \$opts{help},
           'V|version'     => \$opts{version},
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

my $infile = shift;
my $outfile = shift || q{-};

my $doc = CAM::PDF->new($infile) || die "$CAM::PDF::errstr\n";

if (!$doc->canModify())
{
   die "This PDF forbids modification\n";
}

foreach my $objnum (keys %{$doc->{xref}})
{
   my $objnode = $doc->dereference($objnum);
   my $val = $objnode->{value};
   if ($val->{type} eq 'dictionary')
   {
      my $dict = $val->{value};
      my $changed = 0;
      foreach my $key (qw(Metadata
                          PieceInfo
                          LastModified
                          Thumb))
      {
         if (exists $dict->{$key})
         {
            delete $dict->{$key};
            $changed = 1;
         }
      }
      if ($changed)
      {
         $doc->{changes}->{$objnum} = 1;
      }
   }
}

$doc->cleanse();
if ($opts{order})
{
   $doc->preserveOrder();
}
$doc->cleanoutput($outfile);


__END__

=for stopwords deillustrate.pl

=head1 NAME

deillustrate.pl - Remove Adobe Illustrator metadata from a PDF file

=head1 SYNOPSIS

 deillustrate.pl [options] infile.pdf [outfile.pdf]\n";

 Options:
   -o --order          preserve the internal PDF ordering for output
   -v --verbose        print diagnostic messages
   -h --help           verbose help message
   -V --version        print CAM::PDF version

=head1 DESCRIPTION

Adobe Illustrator has a very handy feature that allows an author to
embed special metadata in a PDF that allows Illustrator to reopen the
file fully editable.  However, this extra data does increase the size
of the PDF unnecessarily if no further editing is expected, as is the
case for most PDFs that will be distributed on the web.  Depending on
the PDF, this can dramatically reduce the file size.

This program uses a few heuristics to find and delete the
Illustrator-specific data.  This program also removes embedded
thumbnail representations of the PDF for further byte savings.

=head1 SEE ALSO

CAM::PDF

=head1 AUTHOR

See L<CAM::PDF>

=cut
