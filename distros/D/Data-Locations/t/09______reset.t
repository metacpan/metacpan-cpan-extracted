#!perl -w

use strict;
no strict "vars";

use Data::Locations;

# ======================================================================
#   $location->reset();
# ======================================================================

print "1..12\n";

$n = 1;

$loc = Data::Locations->new();

$loc->print("[1]");

if (! exists ${*{$loc}}{'stack'})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str = $loc->read();

if ($str eq '[1]')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (exists ${*{$loc}}{'stack'})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{${*{$loc}}{'stack'}} == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$loc->reset();

if (! exists ${*{$loc}}{'stack'})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str = <$loc>;

if ($str eq '[1]')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (exists ${*{$loc}}{'stack'})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{${*{$loc}}{'stack'}} == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str = $loc->read();

if (! defined $str)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (exists ${*{$loc}}{'stack'})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{${*{$loc}}{'stack'}} == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$loc->reset();

if (! exists ${*{$loc}}{'stack'})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

