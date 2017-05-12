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
            help       => 0,
            version    => 0,
            );

Getopt::Long::Configure('bundling');
GetOptions('v|verbose'    => \$opts{verbose},
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

if (@ARGV < 1)
{
   pod2usage(1);
}

while (@ARGV > 0)
{
   my $file = shift;

   # prompt for password
   my $doc = CAM::PDF->new($file, q{}, q{}, 1) || die "$CAM::PDF::errstr\n";

   if ($file eq q{-})
   {
      $file = 'STDIN';
   }
   my $size = length $doc->{content};
   my $pages = $doc->numPages();
   my @prefs = $doc->getPrefs();
   my $pdfversion = $doc->{pdfversion};
   my $pdfinfo = $doc->{trailer}->{Info};
   $pdfinfo &&= $doc->getValue($pdfinfo);

   my @pagesize = (0,0);
   my $p = $doc->{Pages};
   my $box = $p->{MediaBox};
   if ($box)
   {
      $box = $box->{value};
      @pagesize = ($box->[2]->{value} - $box->[0]->{value},
                   $box->[3]->{value} - $box->[1]->{value});
   }

   print "File:         $file\n";
   print "File Size:    $size bytes\n";
   print "Pages:        $pages\n";
   if ($pdfinfo)
   {
      my $date = qr/(\d{4})(\d{2})(\d{2})/xms;
      my $time = qr/(\d{2})(\d{2})(\d{2})/xms;
      my $tz = qr/([+-Z])(\d{2})\'(\d{2})\'/xms;
      foreach my $key (sort keys %{$pdfinfo})
      {
         my $val = $pdfinfo->{$key}->{value};
         if ($pdfinfo->{$key}->{type} eq 'string' && $val &&
             $val =~ m{ \A
                        D: $date $time $tz
                        \z
                      }xms)
         {
            my ($Y,$M,$D,$h,$m,$s,$sign,$tzh,$tzm) = ($1,$2,$3,$4,$5,$6,$7,$8,$9);
            if ($sign eq 'Z')
            {
               $sign = q{+};
            }
            require Time::Local;
            my $timegm = Time::Local::timegm($s,$m,$h,$D,$M-1,$Y-1900);
            my $tzshift = $sign . ($tzh*3600 + $tzm*60);
            $timegm += $tzshift;
            $val = localtime $timegm;
         }
         printf "%-13s %s\n", $key.q{:}, $val;
      }
   }
   print 'Page Size:    '.($pagesize[0] ? "$pagesize[0] x $pagesize[1] pts" : 'variable')."\n";
   print 'Optimized:    '.($doc->isLinearized()?'yes':'no')."\n";
   print "PDF version:  $pdfversion\n";
   print "Security\n";
   if ($prefs[0] || $prefs[1])
   {
      print "  Passwd:     '$prefs[0]', '$prefs[1]'\n";
   }
   else
   {
      print "  Passwd:     none\n";
   }
   print '  Print:      '.($prefs[2]?'yes':'no')."\n";
   print '  Modify:     '.($prefs[3]?'yes':'no')."\n";
   print '  Copy:       '.($prefs[4]?'yes':'no')."\n";
   print '  Add:        '.($prefs[5]?'yes':'no')."\n";
   if (@ARGV > 0)
   {
      print "---------------------------------\n";
   }
}


__END__

=for stopwords pdfinfo.pl

=head1 NAME

pdfinfo.pl - Print information about PDF file(s)

=head1 SYNOPSIS

 pdfinfo.pl [options] file.pdf [file.pdf ...]

 Options:
   -v --verbose        print diagnostic messages
   -h --help           verbose help message
   -V --version        print CAM::PDF version

=head1 DESCRIPTION

Prints to STDOUT various basic details about the specified PDF
file(s).

=head1 SEE ALSO

CAM::PDF

=head1 AUTHOR

See L<CAM::PDF>

=cut
