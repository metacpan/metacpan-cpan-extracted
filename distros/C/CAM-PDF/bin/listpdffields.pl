#!/usr/bin/perl -w

package main;

use warnings;
use strict;
use CAM::PDF;
use Getopt::Long;
use Pod::Usage;

our $VERSION = '1.60';

my %opts = (
            sort       => 0,
            verbose    => 0,
            help       => 0,
            version    => 0,
            );

Getopt::Long::Configure('bundling');
GetOptions('s|sort'     => \$opts{sort},
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

my $infile = shift;

my $doc = CAM::PDF->new($infile) || die "$CAM::PDF::errstr\n";

my @list = $doc->getFormFieldList();
if ($opts{sort})
{
   @list = sort @list;
}
foreach my $name (@list)
{
   print $name, "\n";
}


__END__

=for stopwords listpdffields.pl

=head1 NAME

listpdffields.pl - Print the PDF form field names

=head1 SYNOPSIS

 listpdffields.pl [options] infile.pdf

 Options:
   -s --sort           sort the output list alphabetically
   -v --verbose        print diagnostic messages
   -h --help           verbose help message
   -V --version        print CAM::PDF version

=head1 DESCRIPTION

Outputs to STDOUT all of the field names for any forms in the PDF document.

=head1 SEE ALSO

CAM::PDF

F<fillpdffields.pl>

=head1 AUTHOR

See L<CAM::PDF>

=cut
