#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

use Date::Pcalc::Object qw(:all);

# ======================================================================
#   $lang = Date::Pcalc->language([LANG]);
#   $lang = $date->language([LANG]);
# ======================================================================

print "1..9\n";

$n = 1;

$date = Date::Pcalc->new();

$lang = Date::Pcalc->language();
if ($lang eq 'English')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$lang = Date::Pcalc->language("fr");
if ($lang eq 'English')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$lang = Date::Pcalc->language();
if ($lang eq 'Français')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$lang = $date->language();
unless (defined $lang)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$lang = $date->language("SV");
unless (defined $lang)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$lang = $date->language();
if ($lang eq 'Svenska')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$lang = $date->language(3);
if ($lang eq 'Svenska')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$lang = $date->language();
if ($lang eq 'Deutsch')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$date->[0][3] = 0;

eval { $lang = $date->language(); };
if ($@ =~ /\bDate::Pcalc::language\(\): language not available\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

