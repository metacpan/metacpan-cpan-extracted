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
            help       => 0,
            version    => 0,
            );

Getopt::Long::Configure('bundling');
GetOptions('v|verbose'  => \$opts{verbose},
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

my $doc = CAM::PDF->new($file) || die "$CAM::PDF::errstr\n";

foreach my $p (split /\D+/xms, $pagenum)
{
   if ($p !~ m/\A\d+\z/xms || $p < 1)
   {
      die "The page number must be an integer greater than 0\n";
   }

   print $doc->getPageContent($p);
}


__END__

=for stopwords getpdfpage.pl

=head1 NAME

getpdfpage.pl - Print the PDF page layout commands

=head1 SYNOPSIS

 getpdfpage.pl [options] infile.pdf pagenum

 Options:
   -v --verbose        print diagnostic messages
   -h --help           verbose help message
   -V --version        print CAM::PDF version

=head1 DESCRIPTION

Retrieves the page content from the PDF and prints it to STDOUT.

=head1 SEE ALSO

CAM::PDF

F<getpdfpageobject.pl>

F<setpdfpage.pl>

=head1 AUTHOR

See L<CAM::PDF>

=cut
