# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl base.t'

use Test::More tests => 17;

BEGIN { use_ok('Business::KontoCheck') };

$ok_cnt=1;
$nok_cnt=0;

# generate a basic lutfile with only a few blocks
$retval=Business::KontoCheck::generate_lut2("blz.txt","blz_pl.lut","User-Info Zeile","20130101-20130102",3,0);
$ret_txt=$kto_retval{$retval};
if($retval gt 0){$ok_cnt++;} else{$nok_cnt++;}
ok($retval gt 0,"generate_lut(): $retval => $ret_txt (ok: $ok_cnt, nok: $nok_cnt)");

# rebuild_blzfile() nur für privaten Test, müllt sonst die Platte der Tester zu :-)
# $retval=Business::KontoCheck::rebuild_blzfile("blz.lut","blz_pl.txt",1);
# $ret_txt=$kto_retval{$retval};
# ok($retval gt 0,"=== >>  rebuild_blzfile(): $retval => $ret_txt (ok: $ok_cnt, nok: $nok_cnt)");

($ret,$info1,$valid1)=Business::KontoCheck::lut_info('blz_pl.lut');
($i1,$i2,$i3,$i4,$i5,$i6,$i7)=split /\n/,$info1;
print "ret: $ret, valid1: $valid1\ni1: >>$i1<<\ni2: >>$i2<<\ni3: >>$i3<<\ni4: >>$i4<<\ni5: >>$i5<<\ni6: >>$i6<<\ni7: >>$i7<<\n";

$i1_soll="Gueltigkeit der Daten: 20130101-20130102 (Erster Datensatz)";
$i2_soll="Enthaltene Felder: BLZ, PZ+, AENDERUNG, NAME+, PLZ+, ORT+";
$i3_soll="";
$i4_soll="BLZ Lookup Table/Format 2.0";
$i5_soll="LUT-Datei generiert am 27.7.2012, 12:11 aus blz.txt\\";
$i6_soll="User-Info Zeile";
$i7_soll="Anzahl Banken: 104, davon Hauptstellen: 62 (inkl. 4 Testbanken)";

if($i1 eq $i1_soll){$i1_ok=1; $ok_cnt++;} else{$i1_ok=0; $nok_cnt++;}
ok($i1_ok eq 1,"lut_info() Zeile 1/Satz 1 (ok: $ok_cnt, nok: $nok_cnt)");
if($i2 eq $i2_soll){$i2_ok=1; $ok_cnt++;} else{$i2_ok=0; $nok_cnt++;}
ok($i2_ok eq 1,"lut_info() Zeile 2/Satz 1 (ok: $ok_cnt, nok: $nok_cnt)");
if($i3 eq $i3_soll){$i3_ok=1; $ok_cnt++;} else{$i3_ok=0; $nok_cnt++;}
ok($i3_ok eq 1,"lut_info() Zeile 3/Satz 1 (ok: $ok_cnt, nok: $nok_cnt)");
if($i4 eq $i4_soll){$i4_ok=1; $ok_cnt++;} else{$i4_ok=0; $nok_cnt++;}
ok($i4_ok eq 1,"lut_info() Zeile 4/Satz 1 (ok: $ok_cnt, nok: $nok_cnt)");
# line 5 changes at each invocation; don't test
if($i6 eq $i6_soll){$i6_ok=1; $ok_cnt++;} else{$i6_ok=0; $nok_cnt++;}
ok($i6_ok eq 1,"lut_info() Zeile 6/Satz 1 (ok: $ok_cnt, nok: $nok_cnt)");
if($i7 eq $i7_soll){$i7_ok=1; $ok_cnt++;} else{$i7_ok=0; $nok_cnt++;}
ok($i7_ok eq 1,"lut_info() Zeile 7/Satz 1 (ok: $ok_cnt, nok: $nok_cnt)");

# append the IBAN blacklist to the lutfile
$retval=Business::KontoCheck::lut_keine_iban_berechnung("CONFIG.INI","blz_pl.lut");
$ret_txt=$kto_retval{$retval};
if($retval gt 0){$ok_cnt++;} else{$nok_cnt++;}
ok($retval gt 0,"lut_keine_iban_berechnung: $retval => $ret_txt (ok: $ok_cnt, nok: $nok_cnt)");

$retval=Business::KontoCheck::generate_lut2("blz.txt","blz_pl.lut","User-Info Zeile","20130104-20130105",9,1,0,0,2);
$ret_txt=$kto_retval{$retval};
if($retval gt 0){$ok_cnt++;} else{$nok_cnt++;}
ok($retval gt 0,"generate_lut(): $retval => $ret_txt (ok: $ok_cnt, nok: $nok_cnt)");

# append the IBAN blacklist to the lutfile
$retval=Business::KontoCheck::lut_keine_iban_berechnung("iban.blacklist","blz_pl.lut",2);
$ret_txt=$kto_retval{$retval};
if($retval gt 0){$ok_cnt++;} else{$nok_cnt++;}
ok($retval gt 0,"lut_keine_iban_berechnung: $retval => $ret_txt (ok: $ok_cnt, nok: $nok_cnt)");

($ret,$info1,$valid1,$info2,$valid2)=Business::KontoCheck::lut_info('blz_pl.lut');
($i1,$i2,$i3,$i4,$i5,$i6,$i7)=split /\n/,$info2;
print "ret: $ret, retval: $retval, valid2: $valid2\ni1: >>$i1<<\ni2: >>$i2<<\ni3: >>$i3<<\ni4: >>$i4<<\ni5: >>$i5<<\ni6: >>$i6<<\ni7: >>$i7<<\n";

$i1_soll="Gueltigkeit der Daten: 20130104-20130105 (Zweiter Datensatz)";
$i2_soll="Enthaltene Felder: BLZ, PZ+, FILIALEN, VOLLTEXT_TXT, AENDERUNG, NAME_NAME_KURZ+, PLZ+, ORT+, BIC+, NACHFOLGE_BLZ, LOESCHUNG, PAN, NR, OWN_IBAN";
$i3_soll="";
$i4_soll="BLZ Lookup Table/Format 2.0";
$i5_soll="LUT-Datei generiert am 27.7.2012, 12:11 aus blz.txt\\";
$i6_soll="User-Info Zeile";
$i7_soll="Anzahl Banken: 104, davon Hauptstellen: 62 (inkl. 4 Testbanken)";

if($i1 eq $i1_soll){$i1_ok=1; $ok_cnt++;} else{$i1_ok=0; $nok_cnt++;}
ok($i1_ok eq 1,"lut_info() Zeile 1/Satz 2 (ok: $ok_cnt, nok: $nok_cnt)");
if($i2 eq $i2_soll){$i2_ok=1; $ok_cnt++;} else{$i2_ok=0; $nok_cnt++;}
ok($i2_ok eq 1,"lut_info() Zeile 2/Satz 2 (ok: $ok_cnt, nok: $nok_cnt)");
if($i3 eq $i3_soll){$i3_ok=1; $ok_cnt++;} else{$i3_ok=0; $nok_cnt++;}
ok($i3_ok eq 1,"lut_info() Zeile 3/Satz 2 (ok: $ok_cnt, nok: $nok_cnt)");
if($i4 eq $i4_soll){$i4_ok=1; $ok_cnt++;} else{$i4_ok=0; $nok_cnt++;}
ok($i4_ok eq 1,"lut_info() Zeile 4/Satz 2 (ok: $ok_cnt, nok: $nok_cnt)");
# line 5 changes at each invocation; don't test
if($i6 eq $i6_soll){$i6_ok=1; $ok_cnt++;} else{$i6_ok=0; $nok_cnt++;}
ok($i6_ok eq 1,"lut_info() Zeile 6/Satz 2 (ok: $ok_cnt, nok: $nok_cnt)");
if($i7 eq $i7_soll){$i7_ok=1; $ok_cnt++;} else{$i7_ok=0; $nok_cnt++;}
ok($i7_ok eq 1,"lut_info() Zeile 7/Satz 2 (ok: $ok_cnt, nok: $nok_cnt)");

