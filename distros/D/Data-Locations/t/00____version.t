#!perl -w

use strict;
no strict "vars";

$Data::Locations::VERSION = $Data::Locations::VERSION = 0;

# ======================================================================
#   $ver = $Data::Locations::VERSION;
#   $ver = Data::Locations::Version();
#   $ver = Data::Locations->Version();
# ======================================================================

print "1..5\n";

$n = 1;

if ($Data::Locations::VERSION eq "0")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { require Data::Locations; 1; };

unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($Data::Locations::VERSION eq "5.5")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (Data::Locations::Version() eq "5.5")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (Data::Locations->Version() eq "5.5")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

