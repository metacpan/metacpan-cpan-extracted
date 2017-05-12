#!perl -w

use strict;
no strict "vars";

use Data::Locations;

# ======================================================================
#   $location->filename($filename);
#   $filename = $location->filename();
#   $filename = $location->filename($filename);
# ======================================================================

print "1..20\n";

$n = 1;

$top = Data::Locations->new("");

if ($top->filename() eq '')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($top->filename("toplevel") eq '')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($top->filename() eq 'toplevel')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$sub = $top->new("sublocation");

if ($top->filename() eq 'toplevel')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($sub->filename() eq 'sublocation')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($top->filename("+>nonesuch") eq 'toplevel')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($top->filename() eq '+>nonesuch')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($sub->filename() eq 'sublocation')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($sub->filename("| more") eq 'sublocation')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($top->filename() eq '+>nonesuch')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($sub->filename() eq '| more')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($top->filename("") eq '+>nonesuch')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($top->filename() eq '')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($sub->filename() eq '| more')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($sub->filename(">>tempfile") eq '| more')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($top->filename() eq '')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($sub->filename() eq '>>tempfile')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($sub->filename("") eq '>>tempfile')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($top->filename() eq '')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($sub->filename() eq '')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

