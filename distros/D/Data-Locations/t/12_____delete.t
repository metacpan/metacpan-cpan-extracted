#!perl -w

use strict;
no strict "vars";

use Data::Locations;

# ======================================================================
#   $location->delete();
# ======================================================================

print "1..32\n";

$n = 1;

$top = Data::Locations->new();
$sub = $top->new();

&check($top,$sub);

$top->delete();

if (keys(%{${*{$top}}{'inner'}}) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (keys(%{${*{$sub}}{'outer'}}) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

print $sub $top;

&check($sub,$top);

$sub->delete();

if (keys(%{${*{$top}}{'inner'}}) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (keys(%{${*{$sub}}{'outer'}}) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

exit;

sub check
{
    my($top,$sub) = @_;
    my($topname,$subname);

    if (@{*{$top}} == 1)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (@{*{$sub}} == 0)
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
}

__END__

