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

my $infile  = shift;
my @nums    = @ARGV;
my $outfile = q{-};

if (@nums % 2 != 0)
{
   $outfile = pop @nums;
}

my $doc = CAM::PDF->new($infile) || die "$CAM::PDF::errstr\n";

$doc->changeRefKeys(CAM::PDF::Node->new('dictionary', $doc->{trailer}), {@nums}, 1);
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

=for stopwords changerefkeys.pl

=head1 NAME

changerefkeys.pl - Search and replace PDF object numbers in the Trailer

=head1 SYNOPSIS

 changerefkeys.pl [options] infile.pdf old-objnum new-objnum
                  [old-objnum new-objnum ...] [outfile.pdf]

 Options:
   -o --order          preserve the internal PDF ordering for output
   -v --verbose        print diagnostic messages
   -h --help           verbose help message
   -V --version        print CAM::PDF version

=head1 DESCRIPTION

Changes a PDF to alter the object numbers in the PDF Trailer.  The
resulting edited PDF is output to a specified file or STDOUT.

This is a very low-level utility, and is not likely useful for general
users.

=head1 SEE ALSO

CAM::PDF

=head1 AUTHOR

See L<CAM::PDF>

=cut
