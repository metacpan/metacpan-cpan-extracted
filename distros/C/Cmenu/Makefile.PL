
# $Id: Makefile.PL,v 1.1.1.1 2001/04/07 18:43:45 devel Exp $

use ExtUtils::MakeMaker;
use strict;

print "\nBefore continuing - please check the README file\n";
print "This is especially important for determining Terminal settings\n\n";

my %opts = (
    NAME         => 'Cmenu',
    VERSION_FROM => 'Cmenu.pm',
);

# Make sure Curses is a sound version courtesy of Gavin
use Curses;
if($Curses::VERSION<1.04) {
  print "your Curses Version $Curses::VERSION is too old - get a new one\n";
  exit();
}

WriteMakefile(%opts);

exit(0);

# end of Makefile.PL
