#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc qw( Decode_Date_EU2 Language Decode_Language );

# ======================================================================
#   ($year,$mm,$dd) = Decode_Date_EU2($date);
# ======================================================================

print "1..46\n";

$n = 1;
unless (($year,$mm,$dd) = Decode_Date_EU2(""))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

unless (($year,$mm,$dd) = Decode_Date_EU2("__"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

unless (($year,$mm,$dd) = Decode_Date_EU2("_31_"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_314_")) &&
($year==2004) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_0314_")) &&
($year==2004) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_00314_")) &&
($year==2004) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_3164_")) &&
(int($year/100)>19) && ($year%100==64) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_03164_")) &&
(int($year/100)>19) && ($year%100==64) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_003164_")) &&
(int($year/100)>19) && ($year%100==64) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_30164_")) &&
(int($year/100)>19) && ($year%100==64) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_030164_")) &&
(int($year/100)>19) && ($year%100==64) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_0030164_")) &&
(int($year/100)>19) && ($year%100==64) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_110364_")) &&
(int($year/100)>19) && ($year%100==64) && ($mm==3) && ($dd==11))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_0110364_")) &&
(int($year/100)>19) && ($year%100==64) && ($mm==3) && ($dd==11))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_00110364_")) &&
(int($year/100)>19) && ($year%100==64) && ($mm==3) && ($dd==11))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_3011964_")) &&
($year==1964) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_03011964_")) &&
($year==1964) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_003011964_")) &&
($year==1964) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_11031964_")) &&
($year==1964) && ($mm==3) && ($dd==11))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_011031964_")) &&
($year==1964) && ($mm==3) && ($dd==11))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_0011031964_")) &&
($year==1964) && ($mm==3) && ($dd==11))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_3_1_64_")) &&
(int($year/100)>19) && ($year%100==64) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_3_1_1964_")) &&
($year==1964) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_3_jan_64_")) &&
(int($year/100)>19) && ($year%100==64) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_3_Jan_64_",0)) &&
(int($year/100)>19) && ($year%100==64) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_3_jAN_64_",1)) &&
(int($year/100)>19) && ($year%100==64) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_3-JAN-64_",2)) &&
(int($year/100)>19) && ($year%100==64) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_3-Jan-1964_",3)) &&
($year==1964) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_3-January-1964_",'')) &&
($year==1964) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_000003-Jan-000064_",undef)) &&
(int($year/100)>19) && ($year%100==64) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_000003-Jan-001964_")) &&
($year==1964) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_3_ja_64_")) &&
(int($year/100)>19) && ($year%100==64) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

unless (($year,$mm,$dd) = Decode_Date_EU2("_3_j_64_"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_3ja64_")) &&
(int($year/100)>19) && ($year%100==64) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_03ja64_")) &&
(int($year/100)>19) && ($year%100==64) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_003ja64_")) &&
(int($year/100)>19) && ($year%100==64) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_000003ja000064_")) &&
(int($year/100)>19) && ($year%100==64) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_3ja1964_")) &&
($year==1964) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_03ja1964_")) &&
($year==1964) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_003ja1964_")) &&
($year==1964) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_000003ja001964_")) &&
($year==1964) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

unless (($year,$mm,$dd) = Decode_Date_EU2("_33ja64_"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

unless (($year,$mm,$dd) = Decode_Date_EU2("_33ja1964_"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("x000003x000001x000064x")) &&
(int($year/100)>19) && ($year%100==64) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("x000003_ja_000064x")) &&
(int($year/100)>19) && ($year%100==64) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU2("_dia_tres_3_janeiro_1964_mil_novecentos_sessenta_e_seis_",Decode_Language("Portug"))) &&
($year==1964) && ($mm==1) && ($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

