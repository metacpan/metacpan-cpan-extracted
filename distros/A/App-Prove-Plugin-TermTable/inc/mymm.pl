use strict;
use warnings;

unless(-e '/dev/tty')
{
  print "OS unsupported\n";
  exit;
}
