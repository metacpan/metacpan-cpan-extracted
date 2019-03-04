use strict;
use warnings;
use File::Which qw( which );

unless(which('stty'))
{
  print "This plugin requires a `stty` command, which I am unable to find\n";
  exit;
}
