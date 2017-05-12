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

foreach my $objnum (keys %{$doc->{xref}})
{
   my $objnode = $doc->dereference($objnum);
   $doc->changeString($objnode, {$fromstr => $tostr});
}

if (!scalar %{$doc->{changes}} && exists $doc->{contents})
{
   print $doc->{contents};
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

=for stopwords changepdfstring.pl

=head1 NAME

changepdfstring.pl - Search and replace in PDF metadata

=head1 SYNOPSIS

 changepdfstring.pl [options] infile.pdf search-str replace-str [outfile.pdf]

 Options:
   -o --order          preserve the internal PDF ordering for output
   -v --verbose        print diagnostic messages
   -h --help           verbose help message
   -V --version        print CAM::PDF version

=head1 DESCRIPTION

Searches through a PDF file's metadata for instances of C<search-str> and
inserts C<replace-str>.  Note that this does not change the actual PDF
page layout, but only interactive features, like forms and annotation.
To change page layout strings, use instead F<changepagestring.pl>.

The C<search-str> can be a literal string, or it can be a Perl regular
expression by wrapping it in C<regex(...)>.  For example:

  changepdfstring.pl in.pdf 'regex(CAM-PDF-(\d.\d+))' 'version=$1' out.pdf

=head1 SEE ALSO

CAM::PDF

F<changepagestring.pl>

=head1 AUTHOR

See L<CAM::PDF>

=cut
