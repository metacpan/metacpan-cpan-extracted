#!/usr/bin/perl -w

package main;

use warnings;
use strict;
use CAM::PDF;
use Getopt::Long;
use Pod::Usage;

our $VERSION = '1.60';

my %opts = (
            verbose    => 0,
            decode     => 0,
            askforpass => 0,
            help       => 0,
            version    => 0,
            );

Getopt::Long::Configure('bundling');
GetOptions('v|verbose'  => \$opts{verbose},
           'd|decode'   => \$opts{decode},
           'p|pass'     => \$opts{askforpass},
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

my $file = shift || q{-};
my $doc = CAM::PDF->new($file, q{}, q{},
                        { prompt_for_password => $opts{askforpass} })
    || die "$CAM::PDF::errstr\n";

if ($opts{decode})
{
   foreach my $objnode (keys %{$doc->{xref}})
   {
      $doc->decodeObject($objnode);
   }
}
if ($opts{verbose})
{
   $doc->cacheObjects(); # to force parsing of whole file
   print $doc->toString();
}

__END__

=for stopwords readpdf.pl

=head1 NAME

readpdf.pl - Read a PDF document

=head1 SYNOPSIS

 readpdf.pl [options] file.pdf

 Options:
   -d --decode         uncompress internal PDF components
   -p --pass           prompt for a user password if needed
   -v --verbose        print the internal representation of the PDF
   -h --help           verbose help message
   -V --version        print CAM::PDF version

=head1 DESCRIPTION

Read a PDF document into memory and, optionally, output it's internal
representation.  This is primarily useful for debugging, but it can
also be a way to validate a PDF document.

=head1 SEE ALSO

CAM::PDF

F<rewritepdf.pl>

=head1 AUTHOR

See L<CAM::PDF>

=cut
