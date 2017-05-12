#!perl -w

use strict;
no strict "vars";

use Data::Locations;

# ======================================================================
#   $toplocation = Data::Locations->new();
#   $sublocation = $location->new();
# ======================================================================

print "1..59\n";

$n = 1;

$top = Data::Locations->new();

&check($top);

$sub = $top->new();

&check($sub);

if (@{*{$top}} == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (defined ${*{$top}}[0])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref(${*{$top}}[0]))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref(${*{$top}}[0]) eq 'Data::Locations')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$top}}[0] eq $sub)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$topname = ${*{$top}}{'name'};
$subname = ${*{$sub}}{'name'};

if (keys(%{${*{$top}}{'inner'}}) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (exists ${${*{$top}}{'inner'}}{$subname})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined ${${*{$top}}{'inner'}}{$subname})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${${*{$top}}{'inner'}}{$subname} == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (keys(%{${*{$sub}}{'outer'}}) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (exists ${${*{$sub}}{'outer'}}{$topname})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined ${${*{$sub}}{'outer'}}{$topname})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${${*{$sub}}{'outer'}}{$topname} == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

exit;

sub check
{
    my($loc) = @_;
    my($name);

    if (defined $loc)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (ref($loc))
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (ref($loc) eq 'Data::Locations')
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (defined %{*{$loc}})
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (exists ${*{$loc}}{'name'})
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (defined ${*{$loc}}{'name'})
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    $name = ${*{$loc}}{'name'};
    if ($name =~ /^LOCATION\d+$/)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (${*{$loc}} eq $loc)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (${*{$Data::Locations::{$name}}} eq $loc)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (${*{$Data::Locations::{$name}}}{'name'} eq $name)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (tied(*{$loc}) eq $loc)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (exists ${*{$loc}}{'file'})
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (defined ${*{$loc}}{'file'})
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (${*{$loc}}{'file'} eq '')
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    if (exists ${*{$loc}}{'inner'})
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (defined ${*{$loc}}{'inner'})
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (ref(${*{$loc}}{'inner'}))
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (ref(${*{$loc}}{'inner'}) eq 'HASH')
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    if (exists ${*{$loc}}{'outer'})
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (defined ${*{$loc}}{'outer'})
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (ref(${*{$loc}}{'outer'}))
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (ref(${*{$loc}}{'outer'}) eq 'HASH')
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    if (@{*{$loc}} == 0)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

__END__

