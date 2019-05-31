#!/usr/bin/perl -w

eval 'exec /usr/bin/perl -w -S $0 ${1+"$@"}'
    if 0; # not running under some shell

package main;

use warnings;
use strict;
use CAM::PDFTaxforms;
use Getopt::Long;
use Pod::Usage;

our $VERSION = '1.00';

my %opts = (
            sort       => 0,
            verbose    => 0,
            data       => 0,   #JWT:ADDED 20100921 TO DISPLAY FIELD VALUES ALSO.
            help       => 0,
            version    => 0,
            );

Getopt::Long::Configure('bundling');
GetOptions('s|sort'     => \$opts{sort},
           'v|verbose'  => \$opts{verbose},
           'd|data'     => \$opts{data},
           'h|help'     => \$opts{help},
           'V|version'  => \$opts{version},
           ) or pod2usage(1);
pod2usage(1)  if ($opts{help});
#{
#   pod2usage(-exitstatus => 0, -verbose => 2);
#}
if ($opts{version})
{
   print "CAM::PDFTaxforms v$CAM::PDFTaxforms::VERSION\n";
   print "CAM::PDF v$CAM::PDF::VERSION\n";
   exit 0;
}

if (@ARGV < 1)
{
   pod2usage(1);
}

my $infile = shift;

my $doc = CAM::PDFTaxforms->new($infile) || die "$CAM::PDF::errstr\n";

my @list = $doc->getFormFieldList();
my $fieldHash;
$fieldHash = $doc->getFieldValue(@list)  if ($opts{data});
if ($opts{'sort'})
{
   @list = sort @list;
}
foreach my $name (@list)
{
   print $name, (($opts{data} && defined($$fieldHash{$name})) ? "\t$$fieldHash{$name}" : ''), "\n";
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
   -d --data           print values along with field names
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
