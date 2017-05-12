package Hello::CLI;
use strict;
use warnings;
use Hello;

sub new { bless {}, shift }
sub run { print "Hello world.\n" }

1;
