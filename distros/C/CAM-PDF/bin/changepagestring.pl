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
            order      => 0,
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

my $infile = shift;
my $fromstr = shift;
my $tostr = shift;
my $outfile = shift || q{-};

my $doc = CAM::PDF->new($infile) || die "$CAM::PDF::errstr\n";

foreach my $p (1 .. $doc->numPages())
{
   my $content = $doc->getPageContent($p);
   if ($content =~ s/$fromstr/$tostr/gxms)
   {
      $doc->setPageContent($p, $content);
   }
}

if (!scalar %{$doc->{changes}} && exists $doc->{contents})
{
   $doc->output($outfile);
}
else
{
   if ($opts{order})
   {
      $doc->preserveOrder();
   }
   if (!$doc->canModify())
   {
      die "This PDF forbids modification\n";
   }
   $doc->cleanoutput($outfile);
}

__END__

=for stopwords changepagestring.pl

=head1 NAME

changepagestring.pl - Search and replace in all PDF pages

=head1 SYNOPSIS

 changepagestring.pl [options] infile.pdf search-regex replace-str [outfile.pdf]

 Options:
   -o --order          preserve the internal PDF ordering for output
   -v --verbose        print diagnostic messages
   -h --help           verbose help message
   -V --version        print CAM::PDF version

=head1 DESCRIPTION

Searches through all pages of a PDF file for instances of C<search-regex>
and inserts C<replace-str>.  The regex should be a form that Perl
understands.  Note that this does not change the PDF metadata like
forms and annotation.  To change metadata, use instead
F<changepdfstring.pl>.

=head1 SEE ALSO

CAM::PDF

F<changepdfstring.pl>

=head1 AUTHOR

See L<CAM::PDF>

=cut
