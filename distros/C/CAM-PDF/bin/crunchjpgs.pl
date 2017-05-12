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
            # Hardcoded:
            template   => 'crunchjpg_tmpl.pdf',

            # User settable values:
            justjpgs   => 0,
            quality    => 50,
            scale      => undef,
            scalemin   => 0,
            skip       => {},
            only       => {},
            Verbose    => 0,
            verbose    => 0,
            order      => 0,
            help       => 0,
            version    => 0,

            # Temporary values:
            onlyval    => [],
            skipval    => [],
            qualityval => undef,
            scaleminval=> undef,
            scaleval   => undef,
            scales     => {1 => undef, 2 => '50%', 4 => '25%', 8 => '12.5%'},
           );

Getopt::Long::Configure('bundling');
GetOptions('S|skip=s'     => \@{$opts{skipval}},
           'O|only=s'     => \@{$opts{onlyval}},
           'q|quality=i'  => \$opts{qualityval},
           's|scale=i'    => \$opts{scaleval},
           'm|scalemin=i' => \$opts{scaleminval},
           'j|justjpgs'   => \$opts{justjpgs},
           'veryverbose'  => \$opts{Verbose},
           'v|verbose'    => \$opts{verbose},
           'o|order'      => \$opts{order},
           'h|help'       => \$opts{help},
           'V|version'    => \$opts{version},
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

## Fix up and validate special options:

if ($opts{Verbose})
{
   $opts{verbose} = 1;
}
if (defined $opts{scaleval})
{
   if (exists $opts{scales}->{$opts{scaleval}})
   {
      $opts{scale} = $opts{scales}->{$opts{scaleval}};
   }
   else
   {
      die "Invalid value for --scale switch\n";
   }
}
if (defined $opts{scaleminval})
{
   if ($opts{scaleminval} =~ m/\A\d+\z/xms && $opts{scaleminval} > 0)
   {
      $opts{scalemin} = $opts{scaleminval};
   }
   else
   {
      die "Invalid value for --scalemin switch\n";
   }
}
if (defined $opts{qualityval})
{
   if ($opts{qualityval} =~ m/\A\d+\z/xms && $opts{qualityval} >= 1 && $opts{qualityval} <= 100)
   {
      $opts{quality} = $opts{qualityval};
   }
   else
   {
      die "The JPEG --quality setting must be between 1 and 100\n";
   }
}
foreach my $flag (qw( skip only ))
{
   foreach my $val (@{$opts{$flag.'val'}})
   {
      foreach my $key (split /\D+/xms, $val)
      {
         $opts{$flag}->{$key} = 1;
      }
   }
}
if (!-f $opts{template})
{
   die "Cannot find the template pdf called $opts{template}\n";
}

# Start work:

if (@ARGV < 1)
{
   pod2usage(1);
}

my $infile = shift;
my $outfile = shift || q{-};

my $doc = CAM::PDF->new($infile) || die "$CAM::PDF::errstr\n";

if (!$doc->canModify())
{
   die "This PDF forbids modification\n";
}

my $pages = $doc->numPages();
my $nimages = 0;
my $rimages = 0;

my %doneobjs;

my $oldcontentsize = $doc->{contentlength};
my $oldtotsize = 0;
my $newtotsize = 0;

for my $p (1..$pages)
{
   my $c = $doc->getPageContent($p);
   my @parts = split /(\/[\w]+\s*Do)\b/xms, $c;
   foreach my $part (@parts)
   {
      if ($part =~ m/\A(\/[\w]+)\s*Do\z/xms)
      {
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

         next if (exists $doneobjs{$objnum});

         $nimages++;
         _inform("Image $nimages page $p, $ref = object $objnum, (w,h)=($w,$h), length $l", $opts{verbose});

         if (exists $opts{skip}->{$objnum} ||
             (0 < scalar keys %{$opts{only}} && !exists $opts{only}->{$objnum}))
         {
            _inform("Skipping object $objnum", $opts{verbose});
            next;
         }

         my $isjpg = _isjpg($im);

         if ((!$isjpg) && $opts{justjpgs})
         {
            _inform('Not a jpeg', $opts{verbose});
         }
         else
         {
            my $oldsize = $doc->getValue($im->{Length});
            if (!$oldsize)
            {
               die "PDF error: Failed to get size of image\n";
            }
            $oldtotsize += $oldsize;

            my $tmpl = CAM::PDF->new($opts{template}) || die "$CAM::PDF::errstr\n";

            # Get a handle on the needed data bits from the template
            my $media_array = $tmpl->getValue($tmpl->getPage(1)->{MediaBox});
            my $rawpage = $tmpl->getPageContent(1);

            $media_array->[2]->{value} = $w;
            $media_array->[3]->{value} = $h;
            my $page = $rawpage;
            $page =~ s/xxx/$w/igxms;
            $page =~ s/yyy/$h/igxms;
            $tmpl->setPageContent(1, $page);
            $tmpl->replaceObject(9, $doc, $objnum, 1);

            my $ofile = "/tmp/crunchjpg.$$";
            $tmpl->cleanoutput($ofile);

            my $cmd = ('convert ' .
                       ($opts{scale} && $w > $opts{scalemin} && $h > $opts{scalemin} ?
                        "-scale '$opts{scale}' " : q{}) .
                       "-quality $opts{quality} " .
                       '-density 72x72 ' .
                       "-page ${w}x$h " .
                       "pdf:$ofile jpg:- | " .
                       'convert jpg:- pdf:- |');

            _inform($cmd, $opts{Verbose});

            # TODO: this should use IPC::Open3 or the like
            open my $pipe, $cmd  ## no critic (ProhibitTwoArgOpen)
                or die "Failed to convert object $objnum to a jpg and back\n";
            my $content = do { local $RS = undef; <$pipe>; };
            close $pipe
                or die "Failed to convert object $objnum to a jpg and back\n";

            my $jpg = CAM::PDF->new($content) || die "$CAM::PDF::errstr\n";
            my $jpgim   = $jpg->getObjValue(8);
            my $jpgsize = $jpg->getValue($jpgim->{Length});

            if ($jpgsize < $oldsize) {
              $doc->replaceObject($objnum, $jpg, 8, 1);

              $newtotsize += $jpgsize;

              my $percent = sprintf '%.1f', 100 * ($oldsize - $jpgsize) / $oldsize;
              _inform("\tcompressed $oldsize -> $jpgsize ($percent%)", $opts{verbose});
            $doneobjs{$objnum} = 1;
            $rimages++;
            } else {
              _inform("\tskipped $oldsize -> $jpgsize", $opts{verbose});
            }

         }
      }
   }
}

_inform("Crunched $rimages of $nimages images", $opts{verbose});
$doc->cleanoutput($outfile);

my $newcontentsize = $doc->{contentlength};

if ($opts{verbose})
{
   my $contentpercent = sprintf '%.1f', $oldcontentsize ? 100 * ($oldcontentsize - $newcontentsize) / $oldcontentsize : 0;
   my $totpercent = sprintf '%.1f', $oldtotsize ? 100 * ($oldtotsize - $newtotsize) / $oldtotsize : 0;
   _inform('Compression summary:', 1);
   _inform("  Document: $oldcontentsize -> $newcontentsize ($contentpercent%)", 1);
   _inform("  Images: $oldtotsize -> $newtotsize ($totpercent%)", 1);
}

sub _isjpg
{
   my $im = shift;
   return if (!$im->{Filter});

   my $f = $im->{Filter};
   my @names = $f->{type} eq 'array' ? @{$f->{value}} : $f;
   for my $e (@names)
   {
      my $name = $doc->getValue($e);
      if (ref $name)
      {
         $name = $name->{value};
      }
      #warn "Checking $name\n";
      if ($name eq 'DCTDecode')
      {
         return 1;
      }
   }
   return;
}

sub _inform
{
   my $str     = shift;
   my $verbose = shift;

   if ($verbose)
   {
      print STDERR $str, "\n";
   }
   return;
}

__END__

=for stopwords crunchjpgs.pl ImageMagick JPG rescaling

=head1 NAME

crunchjpgs.pl - Compress all JPG images in a PDF

=head1 SYNOPSIS

 crunchjpgs.pl [options] infile.pdf [outfile.pdf]

 Options:
   -j --justjpgs       make script skip non-JPGs
   -q --quality        select JPG output quality (default 50)
   -s --scale=num      select a rescaling factor for the JPGs (default 100%)
   -m --scalemin=size  don't scale JPGs smaller than this pixel size (width or height)
   -O --only=imnum     only change the specified images (can be used mutliple times)
   -S --skip=imnum     don't change the specified images (can be used mutliple times)
   -o --order          preserve the internal PDF ordering for output
      --veryverbose    increases the verbosity
   -v --verbose        print diagnostic messages
   -h --help           verbose help message
   -V --version        print CAM::PDF version

The available values for --scale are:

    1  100%
    2   50%
    4   25%
    8   12.5%

C<imnum> is a comma-separated list of integers indicating the images
in order that they appear in the PDF.  Use F<listimages.pl> to retrieve
the image numbers.

=head1 DESCRIPTION

Requires the ImageMagick B<convert> program to be available

Tweak all of the JPG images embedded in a PDF to reduce their size.
This reduction can come from increasing the compression and/or
rescaling the whole image.  Various options give you full control over
which images are altered.

=head1 SEE ALSO

CAM::PDF

F<listimages.pl>

F<extractallimages.pl>

F<extractjpgs.pl>

F<uninlinepdfimages.pl>

=head1 AUTHOR

See L<CAM::PDF>

=cut
