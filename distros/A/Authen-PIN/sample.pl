#!/usr/bin/perl

use Authen::PIN;

my $p = new Authen::PIN('4545PPCCCCCCHHHHHHHHHHV');

for my $word ( qw (
		   perro gato0 1casa cosat iteme punto comas spice peter
		   blitz krieg 2tank plane thing think tanks tommy sleep
		   ))
{
    print "$word == ", $p->pin(123456, $word), "\n";
}
