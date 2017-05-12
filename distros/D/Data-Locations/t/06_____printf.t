#!perl -w

use strict;
no strict "vars";

use Data::Locations;

# ======================================================================
#   $location->printf($format, @items);
#   printf $location $format, @items;
# ======================================================================

print "1..5\n";

$n = 1;

$loc = Data::Locations->new();

$loc->printf("%04X '%-6s' %08.3f\n", 40334, "nUlL", 3.14159265358979);

if (@{*{$loc}} == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$loc}}[0] eq "9D8E 'nUlL  ' 0003.142\n")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

printf $loc "%08d '%6.6s' '%10.4f'\n", 0xA0D9, "NoNsEnSe", 2.71828182845905;

if (@{*{$loc}} == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$loc}}[0] eq "9D8E 'nUlL  ' 0003.142\n")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$loc}}[1] eq "00041177 'NoNsEn' '    2.7183'\n")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

