use strict;
use warnings;
#use lib 'lib';
use Test::More tests => 3;

use Acme::Metification;
ok(1, "Module loaded.");

sub faculty {
   my $no = shift;
   my $fac = 1;
   $fac *= ($no--);
   return $fac if $no == 0;
   recursemeta depth => 10, 5, 7
   return $fac;
}

ok(1, "Applied filter.");

ok(faculty(4) == 24, "Filter application successful.");

