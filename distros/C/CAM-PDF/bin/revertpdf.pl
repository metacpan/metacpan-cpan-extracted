#!/usr/bin/perl -w

package main;

use warnings;
use strict;
use Getopt::Long;
use Pod::Usage;
use English qw(-no_match_vars);

our $VERSION = '1.60';

my %opts = (
            count      => 0,
            verbose    => 0,
            help       => 0,
            version    => 0,
            );

Getopt::Long::Configure('bundling');
GetOptions('c|count'      => \$opts{count},
           'v|verbose'    => \$opts{verbose},
           'h|help'       => \$opts{help},
           'V|version'    => \$opts{version},
           ) or pod2usage(1);
if ($opts{help})
{
   pod2usage(-exitstatus => 0, -verbose => 2);
}
if ($opts{version})
{
   require CAM::PDF;
   print "CAM::PDF v$CAM::PDF::VERSION\n";
   exit 0;
}

if (@ARGV < 1)
{
   pod2usage(1);
}

my $infile = shift;
my $outfile = shift || q{-};

my $content;
if ($infile eq q{-})
{
   $content = do { local $RS = undef; <STDIN>; }; ## no critic(InputOutput::ProhibitExplicitStdin)
}
else
{
   open my $in_fh, '<', $infile or die "Failed to open file $infile: $ERRNO\n";
   $content = do { local $RS = undef; <$in_fh>; };
   close $in_fh or die "Failed to read $infile: $ERRNO\n";
}

my @matches = ($content =~ m/ [\015\012]%%EOF *[\015\012] /gxms);
my $revs = @matches;

if ($opts{count})
{
   print "$revs\n";
}
elsif ($revs < 1)
{
   die "Error: this does not seem to be a PDF document\n";
}
elsif ($revs == 1)
{
   die "Error: there is only one revision in this PDF document.  It cannot be reverted.\n";
}
else
{
   # Figure out line end character
   my ($lineend) = $content =~ m/ (.)%%EOF.*?\z /xms;
   if (!$lineend)
   {
      die "Cannot find the end-of-file marker\n";
   }
   my $eof = $lineend.'%%EOF';

   my $i = rindex $content, $eof;
   my $j = rindex $content, $eof, $i-1;
   $content = (substr $content, 0, $j) . $eof . $lineend;

   if ($outfile eq q{-})
   {
      print STDOUT $content;
   }
   else
   {
      open my $fh, '>', $outfile or die "Cannot write to $outfile: $ERRNO\n";
      print {$fh} $content;
      close $fh or die "Failed to write $outfile: $ERRNO\n";
   }
}


__END__

=for stopwords revertpdf.pl unoptimized

=head1 NAME

revertpdf.pl - Remove the last edits to a PDF document

=head1 SYNOPSIS

 revertpdf.pl [options] infile.pdf [outfile.pdf]

 Options:
   -c --count          just print the number of revisions and exits
   -v --verbose        print diagnostic messages
   -h --help           verbose help message
   -V --version        print CAM::PDF version

=head1 DESCRIPTION

PDF documents have the interesting feature that edits can be applied
just to the end of the file without altering the original content.
This makes it possible to recover previous versions of a document.
This is only possible if the editor writes out an 'unoptimized'
version of the PDF.

This program removes the last layer of edits from the PDF document.  If
there is just one revision, we emit a message and abort.

The C<--count> option just prints the number of generations the document
has endured and applies no changes.

=head1 SEE ALSO

CAM::PDF

=head1 AUTHOR

See L<CAM::PDF>

=cut
