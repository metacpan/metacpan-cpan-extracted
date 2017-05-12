#!perl -w

use strict;
no strict "vars";

use Data::Locations;

# ======================================================================
#   $flag = $location->toplevel();
# ======================================================================

print "1..9\n";

$n = 1;

$top = Data::Locations->new();

if ($top->toplevel())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$sub = $top->new();

if ($top->toplevel())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (! $sub->toplevel())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$top->delete();

if ($top->toplevel())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($sub->toplevel())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

print $sub $top;

if (! $top->toplevel())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($sub->toplevel())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$sub->delete();

if ($top->toplevel())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($sub->toplevel())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

