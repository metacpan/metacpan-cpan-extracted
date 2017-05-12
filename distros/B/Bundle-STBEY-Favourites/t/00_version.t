#!perl -w

use strict;
no strict "vars";

$Bundle::STBEY::Favourites::VERSION = $Bundle::STBEY::Favourites::VERSION = 0;

# ======================================================================
#   $ver = $Bundle::STBEY::Favourites::VERSION;
#   $ver = Bundle::STBEY::Favourites::Version();
#   $ver = Bundle::STBEY::Favourites->Version();
# ======================================================================

print "1..5\n";

$n = 1;

if ($Bundle::STBEY::Favourites::VERSION eq "0")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { require Bundle::STBEY::Favourites; 1; };

unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($Bundle::STBEY::Favourites::VERSION eq "1.2")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (Bundle::STBEY::Favourites::Version() eq "1.2")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (Bundle::STBEY::Favourites->Version() eq "1.2")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

