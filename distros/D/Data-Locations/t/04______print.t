#!perl -w

use strict;
no strict "vars";

use Data::Locations;

# ======================================================================
#   $location->print(@items);
#   print $location @items;
# ======================================================================

print "1..292\n";

$n = 1;

$top = Data::Locations->new();
$top->print("This is ");
$sub = $top->new();
$top->print("information.");
$sub->print("an additional piece of ");

if (@{*{$top}} == 3)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$top}}[0] eq 'This is ')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref(${*{$top}}[1]))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref(${*{$top}}[1]) eq 'Data::Locations')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{${*{$top}}[1]}} eq $sub)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$top}}[2] eq 'information.')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{*{$sub}} == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$sub}}[0] eq 'an additional piece of ')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$loc1 = Data::Locations->new();
$loc2 = Data::Locations->new();
$loc3 = Data::Locations->new();

print $loc3 "rich";
print $loc1 "If I was a ";
$loc1->print($loc2);
print $loc1 " man...";
print $loc2 $loc3;

if (@{*{$loc1}} == 3)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$loc1}}[0] eq 'If I was a ')
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
if (${*{$loc1}}[2] eq ' man...')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{*{$loc2}} == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref(${*{$loc2}}[0]))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref(${*{$loc2}}[0]) eq 'Data::Locations')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{${*{$loc2}}[0]}} eq $loc3)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{*{$loc3}} == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$loc3}}[0] eq 'rich')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$loc4 = Data::Locations->new();
$loc5 = Data::Locations->new();
$loc6 = Data::Locations->new();

print $loc4 "And ", $loc5, " on to ", "something", " completely ", $loc6;
print $loc5 "now";
print $loc6 "different";

if (@{*{$loc4}} == 6)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$loc4}}[0] eq 'And ')
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
if (${*{$loc4}}[2] eq ' on to ')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$loc4}}[3] eq 'something')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$loc4}}[4] eq ' completely ')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref(${*{$loc4}}[5]))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref(${*{$loc4}}[5]) eq 'Data::Locations')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{${*{$loc4}}[5]}} eq $loc6)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{*{$loc5}} == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$loc5}}[0] eq 'now')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{*{$loc6}} == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$loc6}}[0] eq 'different')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$bin = Data::Locations->new();

print $bin pack("C256", 0..255);

if (@{*{$bin}} == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$buf = ${*{$bin}}[0];

for ( $i = 0; $i < 256; $i++ )
{
    if (substr($buf,$i,1) eq chr($i))
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

__END__

