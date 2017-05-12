# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl lut_info.t'

use Test::More tests => 5;

BEGIN { use_ok('Business::KontoCheck', 'lut_info', 'lut_init', '%kto_retval') };

$ok_cnt=1;
$nok_cnt=0;
$retval=lut_init("blz.lut",3,1);
if($retval>0){$ok_cnt++;}else{$nok_cnt++;}
ok($retval gt 0,"init: $retval => $kto_retval{$retval} (ok: $ok_cnt, nok: $nok_cnt)");

if($retval>0){
   @tmp= lut_info('blz.lut');
   ok($#tmp>0,"LUT_info: Es wurden " . scalar(@tmp) . " Variablen durch lut_info() geladen");
   if($#tmp>0){$ok_cnt++;}else{$nok_cnt++;}
   printf "lut_dir:\n%s\n",$tmp[5];
   ($lut_name,$set,$level,$ret)=Business::KontoCheck::current_lutfile_name();
   printf("current_lutfile_name: %s, Set: %d, Level: %d, ret: %d\n",$lut_name,$set,$level,$ret);
   if($lut_name eq "blz.lut" && $set==1 && $level==3){$ok_cnt++;}else{$nok_cnt++;}
   ok($lut_name eq "blz.lut" && $set==1 && $level==3,
           "current_lutfile_name: $lut_name, set: $set, level: $level (ok: $ok_cnt, nok: $nok_cnt)");
   $ret=Business::KontoCheck::lut_blocks(1,$lut_name,$blocks_ok,$blocks_fehler);
   printf("Retval lut_blocks: %d\nName aus lut_blocks(): %s\nBlocks ok: %s\nBlocks mit Fehlern: %s\n",
         $ret,$lut_name,$blocks_ok,$blocks_fehler);
   ok($ret==1 && $lut_name eq "blz.lut" && $blocks_ok eq "BLZ, FILIALEN, NAME, PLZ, ORT, NAME_KURZ, PZ, AENDERUNG, NAME_NAME_KURZ"
         && $blocks_fehler eq "");
}

