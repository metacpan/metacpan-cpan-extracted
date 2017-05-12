#!perl -w

use strict;
no strict "vars";

use Data::Locations;

# ======================================================================
#   $toplocation = Data::Locations->new();
#   $sublocation = $location->new();
#   $location->print($sublocation);
# ======================================================================

print "1..3\n";

$n = 1;

$A1 = Data::Locations->new("A1");
$A2 = Data::Locations->new("A2");
$A3 = Data::Locations->new("A3");
$A4 = Data::Locations->new("A4");
$A5 = Data::Locations->new("A5");

$B1 = $A1->new();
$A2->print($B1);
$A3->print($B1);

$B2 = $A4->new();
$A5->print($B2);

$C1 = $B1->new();
$B2->print($C1);

$D1 = Data::Locations->new("D1");

$E1 = $D1->new();
$E2 = $D1->new();

$F1 = $E1->new();
$F2 = $E1->new();

$F3 = $E2->new();
$F4 = $E2->new();

$A2->print($F1,$F2,$F3,$F4);

$F4->print($A5);

eval { $C1->print($D1); };

if ($@ =~ /Data::Locations::print\(\): infinite recursion loop attempted/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$B1->print($D1);

eval { $B2->print($A3); };

if ($@ =~ /Data::Locations::print\(\): infinite recursion loop attempted/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$B1->delete();

$B2->print($A3);

eval { $B1->print($D1); };

if ($@ =~ /Data::Locations::print\(\): infinite recursion loop attempted/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$A1->filename("");
$A2->filename("");
$A3->filename("");
$A4->filename("");
$A5->filename("");
$D1->filename("");

__END__

