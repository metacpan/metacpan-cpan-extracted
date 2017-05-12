#!/usr/bin/perl -w

package main;

use warnings;
use strict;
use CAM::PDF;
use Getopt::Long;
use Pod::Usage;

our $VERSION = '1.60';

my %opts = (
            triggerclear => 0,
            background   => '1',
            verbose      => 0,
            order        => 0,
            help         => 0,
            version      => 0,
            );

Getopt::Long::Configure('bundling');
GetOptions('t|triggerclear'  => \$opts{triggerclear},
           'b|background=s'  => \$opts{background},
           'v|verbose'       => \$opts{verbose},
           'o|order'         => \$opts{order},
           'h|help'          => \$opts{help},
           'V|version'       => \$opts{version},
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

my $infile = shift;
my $outfile = shift;

if ($opts{background} =~ m/\s/xms)
{
   # Separate r,g,b
   $opts{background} = [split m/\s+/xms, $opts{background}];
}

my $doc = CAM::PDF->new($infile) || die "$CAM::PDF::errstr\n";

my @list = (@ARGV);
$doc->fillFormFields({background_color => $opts{background}}, @list);
if ($opts{triggerclear})
{
   # get even-numbered-index elemented (i.e. fieldnames)
   my @names = map {$_ % 2 ? $list[$_] : ()} 0 .. $#list;
   for my $name (@names)
   {
      my $objnode = $doc->getFormField($name);
      if ($objnode)
      {
         delete $objnode->{value}->{value}->{AA};
      }
   }
}

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

=for stopwords fillpdffields.pl

=head1 NAME

fillpdffields.pl - Replace PDF form fields with specified values

=head1 SYNOPSIS

 fillpdffields.pl [options] infile.pdf outfile.pdf field value [field value ...]

 Options:
   -b --background=val  specify a background color behind the filled text field
                        Options are: 'none', gray or 'r g b'.  Default: '1'
   -t --triggerclear    remove all of the form triggers after replacing values
   -o --order           preserve the internal PDF ordering for output
   -v --verbose         print diagnostic messages
   -h --help            verbose help message
   -V --version         print CAM::PDF version

Examples of C<--background> values are:

  --background=none
  --background=1        # white
  --background=0.5      # gray
  --background=0        # black
  --background="1 0 0"  # red

=head1 DESCRIPTION

Fill in the forms in the PDF with the specified values, identified by
their field names.  See F<listpdffields.pl> for a the names of the form
fields.

=head1 SEE ALSO

CAM::PDF

F<listpdffields.pl>

=head1 AUTHOR

See L<CAM::PDF>

=cut
