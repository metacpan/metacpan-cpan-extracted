#!/usr/bin/perl -w

package main;

use warnings;
use strict;
use CAM::PDF;
use Getopt::Long;
use Pod::Usage;
use English qw(-no_match_vars);

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
my $pagetext = shift;
my $pagenum = shift;
my $outfile = shift || q{-};

my $doc = CAM::PDF->new($infile) || die "$CAM::PDF::errstr\n";

my $content;
if ($pagetext eq q{-})
{
   $content = do { local $RS = undef; <STDIN>; }; ## no critic(InputOutput::ProhibitExplicitStdin)
}
else
{
   open my $in_fh, '<', $pagetext or die "Failed to open $pagetext: $ERRNO\n";
   $content = do { local $RS = undef; <$in_fh>; };
   close $in_fh or die "Failed to read $pagetext: $ERRNO\n";
}

$doc->setPageContent($pagenum, $content);

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

=for stopwords setpdfpage.pl

=head1 NAME

setpdfpage.pl - Replace a page of PDF layout

=head1 SYNOPSIS

 setpdfpage.pl [options] infile.pdf page.txt pagenum [outfile.pdf]

 Options:
   -o --order          preserve the internal PDF ordering for output
   -v --verbose        print diagnostic messages
   -h --help           verbose help message
   -V --version        print CAM::PDF version

=head1 DESCRIPTION

Assign the specified ASCII file to be the page content for the PDF
page indicated.  The existing page layout is discarded.

=head1 SEE ALSO

CAM::PDF

F<getpdfpage.pl>

=head1 AUTHOR

See L<CAM::PDF>

=cut
