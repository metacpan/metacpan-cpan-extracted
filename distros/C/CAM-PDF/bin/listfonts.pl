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

my %fonts;
for my $p (1 .. $doc->numPages())
{
   if (!$opts{sort})
   {
      print "Page $p:\n";
   }

   # Retrieve an examine all page properties to find the fonts
   foreach my $fontname (sort $doc->getFontNames($p))
   {
      my $font = $doc->getFont($p, $fontname);

      # Collect a list of all fields, so we can list the unhandled ones at the end
      my %fields = map {$_ => 1} keys %{$font};
      delete $fields{Type}; # delete the fields as we handle them

      # Font name, if present
      my $name = $fontname;
      if ($font->{Name})
      {
         delete $fields{Name};
         my $othername = $doc->getValue($font->{Name});
         if ($othername ne $name)
         {
            $name .= "(aka $othername)";
         }
      }
      my $desc = "  Name: $name\n";

      # Font subtype (required)
      delete $fields{Subtype};
      $desc .= '    Type: '.$doc->getValue($font->{Subtype})."\n";

      # Base font
      if ($font->{BaseFont})
      {
         delete $fields{BaseFont};
         $desc .= '    BaseFont: '.$doc->getValue($font->{BaseFont})."\n";
      }

      # Font encoding
      delete $fields{Encoding};
      if ($font->{Encoding})
      {
         # complex or simple encoding?
         if ($font->{Encoding}->{type} eq 'reference')  # Complex
         {
            # Handle encoding here.  If it's not an encoding, no big deal
            $desc .= "    Encoding:\n";
            my $ref = $doc->getValue($font->{Encoding});
            my %efields = map {$_ => 1} keys %{$ref};
            delete $efields{Type};
            if ($ref->{BaseEncoding})
            {
               delete $efields{BaseEncoding};
               $desc .= '      BaseEncoding: '.$doc->getValue($ref->{BaseEncoding})."\n";
            }
            if ($ref->{Differences})
            {
               delete $efields{Differences};
               my @diffs = @{$doc->getValue($ref->{Differences})};
               my @chars = grep {$_->{type} eq 'label'} @diffs;
               $desc .= '      Differences: ' . @chars . "\n";
            }
            my @others = sort keys %efields;
            if (@others > 0)
            {
               my $other = join ', ', @others;
               $desc .= "      Other fields: $other\n";
            }
         }
         else   # Simple encoding
         {
            $desc .= '    Encoding: '.$doc->getValue($font->{Encoding})."\n";
         }
      }

      # Font widths
      delete $fields{Widths};
      $desc .= '    Widths: '. ($font->{Widths} ? 'yes' : 'no') . "\n";
      if ($font->{Widths})
      {
         delete $fields{FirstChar};
         delete $fields{LastChar};
         $desc .= '      Characters: '.$doc->getValue($font->{FirstChar}) . q{-} . $doc->getValue($font->{LastChar}) . "\n";
      }

      # Embedding info
      delete $fields{FontDescriptor};
      $desc .= '    Embedded: '. ($font->{FontDescriptor} ? 'yes' : 'no') . "\n";

      # Remaining fields
      my @others = sort keys %fields;
      if (@others > 0)
      {
         my $other = join ', ', @others;
         $desc .= "    Other fields: $other\n";
      }

      # Output, or defer until the end of all PDF pages
      if ($opts{sort})
      {
         $fonts{$fontname} = $desc;
      }
      else
      {
         print $desc;
      }
   }
}

# No-op unless $opts{sort} is set
foreach my $fontname (sort keys %fonts)
{
   $fonts{$fontname} =~ s/ ^[ ][ ] //gxms;
   print $fonts{$fontname};
}

__END__

=for stopwords listfonts.pl

=head1 NAME

listfonts.pl - Print details of the fonts used in the PDF

=head1 SYNOPSIS

 listfonts.pl [options] infile.pdf

 Options:
   -s --sort           sort the fonts by name, not by page
   -v --verbose        print diagnostic messages
   -h --help           verbose help message
   -V --version        print CAM::PDF version

=head1 DESCRIPTION

Outputs to STDOUT all of the fonts in the PDF document.

=head1 SEE ALSO

CAM::PDF

=head1 AUTHOR

See L<CAM::PDF>

=cut
