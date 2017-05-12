#!perl -w

use strict;
no strict "vars";

use Data::Locations;

# ======================================================================
#   $location->println(@items);
#   println $location @items;
# ======================================================================

print "1..32\n";

$n = 1;

$loc1 = Data::Locations->new();
$loc2 = Data::Locations->new();
$loc3 = Data::Locations->new();

$loc1->println("Monty Python's ", $loc2, " presents: ", $loc3);
$loc2->println("Flying Circus");
$loc3->println("A Complete Waste of Time(TM)");

if (@{*{$loc1}} == 5)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$loc1}}[0] eq "Monty Python's ")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref(${*{$loc1}}[1]))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref(${*{$loc1}}[1]) eq 'Data::Locations')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{${*{$loc1}}[1]}} eq $loc2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$loc1}}[2] eq " presents: ")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref(${*{$loc1}}[3]))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref(${*{$loc1}}[3]) eq 'Data::Locations')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{${*{$loc1}}[3]}} eq $loc3)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$loc1}}[4] eq "\n")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{*{$loc2}} == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$loc2}}[0] eq "Flying Circus")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$loc2}}[1] eq "\n")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{*{$loc3}} == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$loc3}}[0] eq "A Complete Waste of Time(TM)")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$loc3}}[1] eq "\n")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$loc4 = Data::Locations->new();
$loc5 = Data::Locations->new();
$loc6 = Data::Locations->new();

println $loc4 "Let's see wether ", $loc5, " also works: ", $loc6;
println $loc5 "this";
println $loc6 "Done.";

if (@{*{$loc4}} == 5)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$loc4}}[0] eq "Let's see wether ")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref(${*{$loc4}}[1]))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref(${*{$loc4}}[1]) eq 'Data::Locations')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{${*{$loc4}}[1]}} eq $loc5)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$loc4}}[2] eq " also works: ")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref(${*{$loc4}}[3]))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref(${*{$loc4}}[3]) eq 'Data::Locations')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{${*{$loc4}}[3]}} eq $loc6)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$loc4}}[4] eq "\n")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{*{$loc5}} == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$loc5}}[0] eq "this")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$loc5}}[1] eq "\n")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{*{$loc6}} == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$loc6}}[0] eq "Done.")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$loc6}}[1] eq "\n")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

