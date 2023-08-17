# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 00-compile.t".
#
# Without "Build" file it could be called with "perl -I../lib 00-compile.t"
# or "perl -Ilib t/00-compile.t".  This is also the command needed to find
# out what specific tests failed in a "./Build test" as the later only gives
# you a number and not the description of the test.
#
# For successful run with test coverage use "./Build testcover".

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;

use Test::More tests => 1;

BEGIN {  use_ok 'App::LXC::Container'  ||  print "Bail out!\n";  }

diag("Testing App::LXC::Container $App::LXC::Container::VERSION, Perl $^V, $^X");
