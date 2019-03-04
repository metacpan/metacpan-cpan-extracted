use strict;
use warnings;

if($^O eq 'MSWin32')
{
  print "Sorry, this plugin does not work on Windows.\n";
  exit;
}

unless(-e '/dev/tty')
{
  print "Sorry, your Operating System does not provide a /dev/tty this plugin\n";
  print "won't work here.\n";
  exit;
}

