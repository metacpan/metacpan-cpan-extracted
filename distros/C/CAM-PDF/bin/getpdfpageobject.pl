#!/usr/bin/perl -w

package main;

use warnings;
use strict;
use CAM::PDF;
use Data::Dumper;
use Getopt::Long;
use Pod::Usage;

our $VERSION = '1.60';

my %opts = (
            decode     => 0,
            content    => 0,
            verbose    => 0,
            help       => 0,
            version    => 0,
            );

Getopt::Long::Configure('bundling');
GetOptions('d|decode'   => \$opts{decode},
           'c|content'  => \$opts{content},
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

if (@ARGV < 2)
{
   pod2usage(1);
}

my $file = shift;
my $pagenum = shift;

if ($pagenum !~ m/\A\d+\z/xms || $pagenum < 1)
{
   die "The page number must be an integer greater than 0\n";
}

my $doc = CAM::PDF->new($file) || die "$CAM::PDF::errstr\n";

my $page = $doc->getPage($pagenum);

if ($opts{content})
{
   if (!exists $page->{Contents})
   {
      die "No page content found\n";
   }
   $page = $doc->getValue($page->{Contents});
}

if ($opts{decode})
{
   $doc->decodeAll(CAM::PDF::Node->new('dictionary', $page));
}

if ($opts{verbose})
{
   print Data::Dumper->Dump([$page], ['page']);
}


__END__

=for stopwords getpdfpageobject.pl

=head1 NAME

getpdfpageobject.pl - Print the PDF page metadata

=head1 SYNOPSIS

 getpdfpageobject.pl [options] infile.pdf pagenum

 Options:
   -d --decode         uncompress any elements
   -c --content        show the page Contents field only
   -v --verbose        print diagnostic messages
   -h --help           verbose help message
   -V --version        print CAM::PDF version

=head1 DESCRIPTION

Retrieves the page metadata from the PDF.  If C<--verbose> is specified,
the memory representation is dumped to STDOUT.  Otherwise, the program
silently returns success or emits a failure message to STDERR.

=head1 SEE ALSO

CAM::PDF

F<getpdfpage.pl>

F<setpdfpage.pl>

=head1 AUTHOR

See L<CAM::PDF>

=cut
