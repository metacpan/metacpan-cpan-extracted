# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl base.t'

use Test::More tests => 61;

BEGIN { use_ok('Business::KontoCheck') };

$ok_cnt=$nok_cnt=0;

# check initialization with base init level
$retval=lut_init("blz.lut",0);
$ret_txt=$kto_retval{$retval};
if($retval gt 0){$ok_cnt++;}else{$nok_cnt++;}
ok($retval gt 0,"1. lut_init(): $retval => $ret_txt (ok: $ok_cnt, nok: $nok_cnt)");

# check initialization with init level set to 5
Business::KontoCheck::lut_cleanup();
$retval=lut_init("blz.lut",5);
$ret_txt=$kto_retval{$retval};
if($retval gt 0){$ok_cnt++;}else{$nok_cnt++;}
ok($retval gt 0,"2. lut_init(): $retval => $ret_txt (ok: $ok_cnt, nok: $nok_cnt)");

#$retval=Business::KontoCheck::set_verbose_debug(20);
$ret_txt=$kto_retval{$retval};
if($retval gt 0){$ok_cnt++;}else{$nok_cnt++;}
ok($retval gt 0,"set_verbose_retval(): $retval => $ret_txt (ok: $ok_cnt, nok: $nok_cnt)");

#check one kto/blz as test
$ret=1;
$blz="10010010";
$kto="73245108";
$retval=kto_check_blz($blz,$kto);
$ret_txt=$kto_retval{$retval};
if($retval==$ret){$ok_cnt++;}else{$nok_cnt++;}
ok($retval eq $ret,"BLZ/KTO (neu) $blz $kto: $retval (Soll: $ret) => $ret_txt (ok: $ok_cnt, nok: $nok_cnt)");


# check initialization with init level set to 5
Business::KontoCheck::lut_cleanup();
$retval=lut_init("blz.lut",5);
$ret_txt=$kto_retval{$retval};
if($retval gt 0){$ok_cnt++;}else{$nok_cnt++;}
ok($retval gt 0,"2. lut_init(): $retval => $ret_txt (ok: $ok_cnt, nok: $nok_cnt)");

# some additional tests (with data)
if($retval gt 0){
   while(<DATA>){
      chomp;
      ($ret,$iban)=split(/ /);
      $retval=Business::KontoCheck::iban_check($iban,$r1);
      $ret_txt=$kto_retval{$retval};
      $kc_retval=$kto_retval{$r1};
      if($ret eq $retval){$ok_cnt++;}else{$nok_cnt++;}
      ok($ret eq $retval,"check_iban von $iban: $retval/$r1 (Soll: $ret) (ok: $ok_cnt, nok: $nok_cnt)\n        IBAN-Retval: $ret_txt\n        KC-Retval:   $kc_retval");
   }
}

# Der erste Teil der Daten stammt aus http://www.vr-bank-fn.de/etc/medialib/i500m0192/downloads.Par.0005.File.tmp/IBANLIST.pdf
# Einige sind allerdings falsch; sie wurden mit einem unabhängigen Programm überprüft.
# Die zweite Gruppe stammt von http://www.iban-rechner.eu/ibancalculator/iban.de.html; sie sind alle korrekt.
# Eine dritte Gruppe findet sich unter http://www.toms-cafe.de/iban/iban.de.html (ebenfalls komplett ok).
# Die Dubletten (etwa die Hälfte) wurden entfernt.

__DATA__
0 MT87MALT011000012345MTLCAST001S
0 SE1212312345678901234561
0 TN5912345678901234567890
1 AD1200012030200359100100
1 AT611904300234573201
1 BA391290079401028494
1 BE68539007547034
1 BG80BNBG96611020345678
1 CH9300762011623852957
1 CY17002001280000001200527600
1 CZ6508000000192000145399
1 DE89370400440532013000
1 DE92600501017486501274
1 DK5000400440116243
1 EE382200221020145685
1 ES9121000418450200051332
1 FI2112345600000785
1 FO2000400440116243
1 FR1420041010050500013M02606
1 GB29NWBK60161331926819
1 GI75NWBK000000007099453
1 GI75NWBK000000007099453	
1 GL2000400440116243
1 GR1601101250000000012300695
1 GR4101402940294002320000587
1 GR7303801150000000001208017
1 HR1210010051863000160
1 HU42117730161111101800000000
1 IE29AIBK93115212345678
1 IS140159260076545510730339
1 IT60X0542811101000000123456
1 LI0900762011623852957
1 LI21088100002324013AA
1 LT121000011101001000
-121 LU2800194000644750000
1 LU280019400644750000
1 LV80BANK0000435195001
1 MC9320041010050500013M02606
1 ME25505000012345678951
1 MK07300000000042425
1 MT84MALT011000012345MTLCAST001S
1 MU17BOMM0101101030300200000MUR
1 NL91ABNA0417164300
1 NO9386011117947
1 PL27114020040000300201355387
1 PL61109010140000071219812874
1 PT50000201231234567890154
1 RO49AAAA1B31007593840000
1 RS35260005601001611379
1 SE3550000000054910000003
1 SI56191000000123438
1 SK3112000000198742637541
1 SM88X0542811101000000123456
1 TN5914207207100707129648
1 TR330006100519786457841326
