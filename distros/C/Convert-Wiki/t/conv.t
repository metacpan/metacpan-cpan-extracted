use Test::More;

BEGIN
   {
   plan tests => 7;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Convert::Wiki") or die($@);
   };

use File::Spec;
use Test::Differences;
use strict;

sub DEBUG () { 0; }

#############################################################################
# for all in txt/, read in, convert and compare to out/

opendir DIR, "txt/" or die ("Cannot open dir txt: $!");
my @files = readdir DIR;
closedir DIR;

foreach my $file (@files)
  {
  next if $file =~ /^i/;		# skip link list

  my $f = File::Spec->catfile('txt', $file);
  next unless -f $f;

  print "# At $f\n";

  my $links = File::Spec->catfile('txt', 'i' . $file);
  my $interlink = [];
  if (-f $links)
    {
    print "# Reading $links for interlinking\n";
    $interlink = [ split /\n/, read_file ($links) ];
    print "# Links: \n# " . join ("\n# ", @$interlink) . "\n";
    }

  my $wiki = Convert::Wiki->new( debug => DEBUG, interlink => $interlink );

  $wiki->from_txt ( read_file ($f) );

  my $w = File::Spec->catfile('out', $file);
  eq_or_diff ($wiki->as_wiki(), read_file ($w));
 
#  print $wiki->as_wiki() if DEBUG; 
  }

1;

#############################################################################

sub read_file
  {
  my $f = shift;

  local $/ = undef;		# slurp mode  
  open FILE, $f or die ("Cannot open file: $f");
  my $doc = <FILE>;
  close FILE;

  $doc;
  }

