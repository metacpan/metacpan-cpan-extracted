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

if (@ARGV < 2)
{
   pod2usage(1);
}

my $infile = shift;
my $stampfile = shift;
my $outfile = shift || q{-};

my $doc = CAM::PDF->new($infile) || die "$CAM::PDF::errstr\n";

my $stampdoc = CAM::PDF->new($stampfile) || die "$CAM::PDF::errstr\n";

my $stamp = "q\n" . $stampdoc->getPageContent(1) . "Q\n";
foreach my $p (1 .. $doc->numPages())
{
   $doc->appendPageContent($p, $stamp);
}

if (!$doc->canModify())
{
   die "This PDF forbids modification\n";
}
$doc->cleanoutput($outfile);


__END__

=for stopwords stamppdf.pl

=head1 NAME

stamppdf.pl - Apply a mark to each page of a PDF

=head1 SYNOPSIS

 stamppdf.pl [options] infile.pdf stamp.pdf [outfile.pdf]

 Options:
   -o --order          preserve the internal PDF ordering for output
   -v --verbose        print diagnostic messages
   -h --help           verbose help message
   -V --version        print CAM::PDF version

=head1 DESCRIPTION

Add the contents of C<stamp.pdf> page 1 to each page of C<infile.pdf>.  If
the two PDFs have different page sizes, this likely won't work very
well.

=head1 SEE ALSO

CAM::PDF

=head1 AUTHOR

See L<CAM::PDF>

=cut
