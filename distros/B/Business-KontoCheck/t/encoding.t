#
#===============================================================================
#
#         FILE:  encoding.t
#
#  DESCRIPTION:  test the encoding function for return values and lut file blocks
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Michael Plugge
#      VERSION:  1.0
#      CREATED:  06.05.2011 23:57:00
#     REVISION:  ---
#===============================================================================

use Test::More tests => 19;                      # last test to print

BEGIN { use_ok('Business::KontoCheck') };

$ok_cnt=1;
$nok_cnt=0;

$retval=lut_init("blz.lut");
$ret_txt=$kto_retval{$retval};
if($retval>0){$ok_cnt++;}else{$nok_cnt++;}
ok($retval gt 0,"init: $retval => $ret_txt (ok: $ok_cnt, nok: $nok_cnt)");

while(<DATA>){
   chomp;
   ($blz,$soll1,$soll2,$soll3,$soll4)=split(/:/);

   $enc=Business::KontoCheck::kto_check_encoding(1);
   $name=Business::KontoCheck::lut_name($blz,0,$ret);
   if($soll1 eq $name){$ok_cnt++;}else{$nok_cnt++;}
   ok($soll1 eq $name,"Name von $blz: $name (Soll: $soll1, rv: $ret, enc: $enc) (ok: $ok_cnt, nok: $nok_cnt)");
 
   $enc=Business::KontoCheck::kto_check_encoding(2);
   $name=Business::KontoCheck::lut_name($blz,0,$ret);
   if($soll2 eq $name){$ok_cnt++;}else{$nok_cnt++;}
   ok($soll2 eq $name,"Name von $blz: $name (Soll: $soll2, rv: $ret, enc: $enc) (ok: $ok_cnt, nok: $nok_cnt)");

   $enc=Business::KontoCheck::kto_check_encoding(3);
   $name=Business::KontoCheck::lut_name($blz,0,$ret);
   if($soll3 eq $name){$ok_cnt++;}else{$nok_cnt++;}
   ok($soll3 eq $name,"Name von $blz: $name (Soll: $soll3, rv: $ret, enc: $enc) (ok: $ok_cnt, nok: $nok_cnt)");

   $enc=Business::KontoCheck::kto_check_encoding(4);
   $name=Business::KontoCheck::lut_name($blz,0,$ret);
   if($soll4 eq $name){$ok_cnt++;}else{$nok_cnt++;}
   ok($soll4 eq $name,"Name von $blz: $name (Soll: $soll4, rv: $ret, enc: $enc) (ok: $ok_cnt, nok: $nok_cnt)");
}

$ret=Business::KontoCheck::kto_check_encoding(1);
$rv=Business::KontoCheck::kto_check_retval2txt(-4);
$soll="die Bankleitzahl ist ung¸ltig";
if($rv eq $soll){$ok_cnt++;} else {$nok_cnt++};
ok($rv eq $soll,"Kodierung 1: $rv (ok: $ok_cnt, nok: $nok_cnt)");

$ret=Business::KontoCheck::kto_check_encoding(2);
$rv=Business::KontoCheck::kto_check_retval2txt(-4);
$soll="die Bankleitzahl ist ung√ºltig";
if($rv eq $soll){$ok_cnt++;} else {$nok_cnt++};
ok($rv eq $soll,"Kodierung 2: $rv (ok: $ok_cnt, nok: $nok_cnt)");

$ret=Business::KontoCheck::kto_check_encoding(3);
$rv=Business::KontoCheck::kto_check_retval2txt(-4);
$soll="die Bankleitzahl ist ung&uuml;ltig";
if($rv eq $soll){$ok_cnt++;} else {$nok_cnt++};
ok($rv eq $soll,"Kodierung 3: $rv (ok: $ok_cnt, nok: $nok_cnt)");

$ret=Business::KontoCheck::kto_check_encoding(4);
$rv=Business::KontoCheck::kto_check_retval2txt(-4);
$soll="die Bankleitzahl ist ungÅltig";
if($rv eq $soll){$ok_cnt++;} else {$nok_cnt++};
ok($rv eq $soll,"Kodierung 4: $rv (ok: $ok_cnt, nok: $nok_cnt)");

$ret=Business::KontoCheck::kto_check_encoding(51);
$rv=Business::KontoCheck::kto_check_retval2txt(-4);
$soll="INVALID_BLZ";
if($rv eq $soll){$ok_cnt++;} else {$nok_cnt++};
ok($rv eq $soll,"Kodierung 5: $rv (ok: $ok_cnt, nok: $nok_cnt)");

__DATA__
12070024:Deutsche Bank Privat und Gesch‰ftskunden:Deutsche Bank Privat und Gesch√§ftskunden:Deutsche Bank Privat und Gesch&auml;ftskunden:Deutsche Bank Privat und GeschÑftskunden
17092404:VR Bank F¸rstenwalde Seelow Wriezen:VR Bank F√ºrstenwalde Seelow Wriezen:VR Bank F&uuml;rstenwalde Seelow Wriezen:VR Bank FÅrstenwalde Seelow Wriezen
50069976:Volksbank Wiﬂmar:Volksbank Wi√ümar:Volksbank Wi&szlig;mar:Volksbank Wi·mar
