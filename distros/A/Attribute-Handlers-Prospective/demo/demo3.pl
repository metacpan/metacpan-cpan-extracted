package main;
use MyClass;

my MyClass $x :Good :Bad(1**1-1) :Omni('vorous');

package SomeOtherClass;
use base MyClass;

BEGIN { $_ = "recieve" }

sub tent { 'acle' }

sub w :Ugly(-duckling) :Omni('po',tent()) {}

my @y :Good :Omni(s/cie/nt/);

my %y :Good(q/bye/) :Omni(q/bus/);

print;
