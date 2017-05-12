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

if (@ARGV < 1)
{
   pod2usage(1);
}

my $file = shift;

my $doc = CAM::PDF->new($file) || die "$CAM::PDF::errstr\n";

my $pages = $doc->numPages();
my $nimages = 0;
for my $p (1..$pages)
{
   my $c = $doc->getPageContent($p);
   my @parts = split /(\/[\w]+\s*Do)\b/xms, $c;
   foreach my $part (@parts)
   {
      if ($part =~ /\A(\/[\w]+)\s*Do\z/xms)
      {
         $nimages++;
         my $ref = $1;
         my $xobj = $doc->dereference($ref, $p);
         my $objnum = $xobj->{objnum};
         my $im = $doc->getValue($xobj);
         my $l = $im->{Length} || $im->{L} || 0;
         if ($l)
         {
            $l = $doc->getValue($l);
         }
         my $w = $im->{Width} || $im->{W} || 0;
         if ($w)
         {
            $w = $doc->getValue($w);
         }
         my $h = $im->{Height} || $im->{H} || 0;
         if ($h)
         {
            $h = $doc->getValue($h);
         }
         print "Image $nimages page $p, (w,h)=($w,$h), ref $ref = object $objnum, length $l\n";
      }
      else
      {
         # Ths code may break if there is are legitimate strings "BI",
         # "ID" and "EI" in order in the page (which happened in the
         # PDF reference doc, of course!

       BI:
         while ($part =~ s/.*?\bBI\b\s*//xms)
         {
            my ($im) = $part =~ s/\A(.*?)\s*\bEI\b\s*//xms;
            next BI if (!$im);

            $im =~ s/\A.*\bBI\b//xms;  # this may get rid of a fake BI if there is one in the page

            # Easy tests:
            next BI if ($im =~ m/ \A [)] /xms);
            next BI if ($im =~ m/ [(] \z /xms);
            next BI if ($im !~ m/ \bID\b /xms);

            # make sure that there is an open paren before every close
            # if not, then the "BI" was part of a string
            my $test = $im;
            $test =~ s/ \\[()] //gxms; # get rid of escaped parens for the test
            while ($test =~ s/ \A(.*?) [)] //xms)
            {
               my $bit = $1;
               next BI if ($bit !~ m/ [(] /xms);
            }

            $nimages++;
            my $w = 0;
            my $h = 0;
            if ($im =~ m/ \/W(|idth)\s*(\d+) /xms)
            {
               $w = $2;
            }
            if ($im =~ m/ \/H(|eight)\s*(\d+) /xms)
            {
               $h = $2;
            }
            print "Image $nimages page $p, (w,h)=($w,$h), inline\n";
         }
      }
   }
}

__END__

=for stopwords listimages.pl

=head1 NAME

listimages.pl - Save copies of all PDF JPG images to a directory

=head1 SYNOPSIS

 listimages.pl [options] infile.pdf

 Options:
   -v --verbose        print diagnostic messages
   -h --help           verbose help message
   -V --version        print CAM::PDF version

=head1 DESCRIPTION

Searches the PDF for images and lists them on STDOUT in one of the
following formats:

  Image <n> page <p>, (w,h)=(<w>,<h>), ref <label> = object <objnum>, length <l>\n";
  Image <n> page <p>, (w,h)=(<w>,<h>), inline

=head1 SEE ALSO

CAM::PDF

F<crunchjpgs.pl>

F<extractallimages.pl>

F<extractjpgs.pl>

F<uninlinepdfimages.pl>

=head1 AUTHOR

See L<CAM::PDF>

=cut
