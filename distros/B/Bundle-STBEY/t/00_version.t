#!perl -w

use strict;
no strict "vars";

$Bundle::STBEY::VERSION = $Bundle::STBEY::VERSION = 0;

# ======================================================================
#   $ver = $Bundle::STBEY::VERSION;
#   $ver = Bundle::STBEY::Version();
#   $ver = Bundle::STBEY->Version();
# ======================================================================

print "1..5\n";

$n = 1;

if ($Bundle::STBEY::VERSION eq "0")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { require Bundle::STBEY; 1; };

unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($Bundle::STBEY::VERSION eq "1.1")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (Bundle::STBEY::Version() eq "1.1")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (Bundle::STBEY->Version() eq "1.1")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

