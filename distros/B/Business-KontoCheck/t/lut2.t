# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl lut2.t'

use Test::More tests => 18;

BEGIN { use_ok('Business::KontoCheck') };

sub chk_biq
{
   my($start_idx,$i,$r);

   $start_idx=$_[0];
   $i=$_[1];


# printf() benutzt einen Array-Kontext, wenn es den bekommt; daher werden die
# Funktionen biq_*1 benutzt, die grundsätzlich in skalarem Kontext arbeiten.
# Ansonsten würde ein Array zurückgeliefert werden und die Ausgabe sähe nicht so
# aus wie erwartet...
   $r=sprintf("%s # %s # %d # %s # %d # %d # %c # %c # %d\n",
         Business::KontoCheck::biq_name1($start_idx+$i),
         Business::KontoCheck::biq_name_kurz1($start_idx+$i),
         Business::KontoCheck::biq_plz1($start_idx+$i),
         Business::KontoCheck::biq_ort1($start_idx+$i),
         Business::KontoCheck::biq_pz1($start_idx+$i),
         Business::KontoCheck::biq_iban_regel1($start_idx+$i),
         Business::KontoCheck::biq_aenderung1($start_idx+$i),
         Business::KontoCheck::biq_loeschung1($start_idx+$i),
         Business::KontoCheck::biq_nachfolge_blz1($start_idx+$i)
         );
   return $r;
}

sub chk_bic
{
   my($start_idx,$i,$r);

# hier werden wieder die Funktionen bic_*1() benutzt, siehe Anmerkung oben
   $r=sprintf("%s # %s # %d # %s # %d # %d # %c # %c # %d\n",
         Business::KontoCheck::bic_name1(@_),
         Business::KontoCheck::bic_name_kurz1(@_),
         Business::KontoCheck::bic_plz1(@_),
         Business::KontoCheck::bic_ort1(@_),
         Business::KontoCheck::bic_pz1(@_),
         Business::KontoCheck::bic_iban_regel1(@_),
         Business::KontoCheck::bic_aenderung1(@_),
         Business::KontoCheck::bic_loeschung1(@_),
         Business::KontoCheck::bic_nachfolge_blz1(@_)
         );
   return $r;
}

sub chk_iban
{
   my($start_idx,$i,$r);

# und noch einmal die Funktionen iban_*1(), siehe Anmerkung oben
   $r=sprintf("%s # %s # %d # %s # %d # %d # %c # %c # %d\n",
         Business::KontoCheck::iban_name1(@_),
         Business::KontoCheck::iban_name_kurz1(@_),
         Business::KontoCheck::iban_plz1(@_),
         Business::KontoCheck::iban_ort1(@_),
         Business::KontoCheck::iban_pz1(@_),
         Business::KontoCheck::iban_iban_regel1(@_),
         Business::KontoCheck::iban_aenderung1(@_),
         Business::KontoCheck::iban_loeschung1(@_),
         Business::KontoCheck::iban_nachfolge_blz1(@_)
         );
   return $r;
}

$ok_cnt=1;
$nok_cnt=0;
$retval=lut_init("blz.lut",9);
$ret_txt=$kto_retval{$retval};
if($retval>0){$ok_cnt++;}else{$nok_cnt++;}
ok($retval gt 0,"init: $retval => $ret_txt (ok: $ok_cnt, nok: $nok_cnt)");


#$cnt=$start_idx=0;
$cnt=0;

### $r=chk_biq($start_idx,0);
### $r2=chk_bic("genodef1s01",0,0);
### $r3=chk_iban("DE87550905000001156132",0);
### $r1="Sparda-Bank Südwest # Sparda-Bank Südwest # 55118 # Mainz a Rhein # 90 # 0 # U # 0 # 0\n";
### if($r eq $r1){$ok_cnt++;}else{$nok_cnt++;}
### ok($r eq $r1,"biq_*() von genodef1s01[0] (ok: $ok_cnt, nok: $nok_cnt)");
### if($r1 eq $r2){$ok_cnt++;}else{$nok_cnt++;}
### ok($r1 eq $r2,"bic_*() von genodef1s01[0] (ok: $ok_cnt, nok: $nok_cnt)");
### if($r eq $r3){$ok_cnt++;}else{$nok_cnt++;}
### ok($r eq $r3,"iban_*() von genodef1s01[0] (ok: $ok_cnt, nok: $nok_cnt)");
### 
### $r=chk_biq($start_idx,13);
### $r2=chk_bic("genodef1s01",0,13);
### $r3=chk_iban("DE87550905000001156132",13);
### $r1="Sparda-Bank Südwest # Sparda-Bank Südwest # 66482 # Zweibrücken, Pfalz # 90 # 0 # U # 0 # 0\n";
### if($r eq $r1){$ok_cnt++;}else{$nok_cnt++;}
### ok($r eq $r1,"biq_*() von genodef1s01[13] (ok: $ok_cnt, nok: $nok_cnt)");
### if($r eq $r2){$ok_cnt++;}else{$nok_cnt++;}
### ok($r eq $r2,"bic_*() von genodef1s01[13] (ok: $ok_cnt, nok: $nok_cnt)");
### if($r eq $r3){$ok_cnt++;}else{$nok_cnt++;}
### ok($r eq $r3,"iban_*() von genodef1s01[13] (ok: $ok_cnt, nok: $nok_cnt)");
### 
### $r=chk_biq($start_idx,37);
### $r2=chk_bic("genodef1s01",0,37);
### $r3=chk_iban("DE87550905000001156132",37);
### $r1="Sparda-Bank Südwest # Sparda-Bank Südwest # 55469 # Simmern, Hunsrück # 90 # 0 # U # 0 # 0\n";
### if($r eq $r1){$ok_cnt++;}else{$nok_cnt++;}
### ok($r eq $r1,"biq_*() von genodef1s01[37] (ok: $ok_cnt, nok: $nok_cnt)");
### if($r eq $r2){$ok_cnt++;}else{$nok_cnt++;}
### ok($r eq $r2,"bic_*() von genodef1s01[37] (ok: $ok_cnt, nok: $nok_cnt)");
### if($r eq $r3){$ok_cnt++;}else{$nok_cnt++;}
### ok($r eq $r3,"iban_*() von genodef1s01[37] (ok: $ok_cnt, nok: $nok_cnt)");
### 
### $r1="Commerzbank vormals Dresdner Bank, PCC DCC-ITGK 2 # Commerzbank ITGK2 Mainz # 55002 # Mainz a Rhein # 9 # 503 # U # 0 # 0\n";
### $r2=chk_bic("dresdeffj21",0,0);
### $r3=chk_iban("DE36550800860012345678",0);
### if($r eq $r1){$ok_cnt++;}else{$nok_cnt++;}
### ok($r eq $r1,"biq_*() von dresdeffj21 (ok: $ok_cnt, nok: $nok_cnt)");
### if($r eq $r2){$ok_cnt++;}else{$nok_cnt++;}
### ok($r eq $r2,"bic_*() von genodef1s01 (ok: $ok_cnt, nok: $nok_cnt)");
### if($r eq $r3){$ok_cnt++;}else{$nok_cnt++;}
### ok($r eq $r3,"iban_*() von dresdeffj21[0] (ok: $ok_cnt, nok: $nok_cnt)");

if($retval>0){
   while(<DATA>){
      chomp;
      ($blz,$soll)=split(/:/);
      ($retval,$cnt,$name,$name_kurz,$plz,$ort)=Business::KontoCheck::lut_multiple($blz);
      $ergebnis="$name_kurz, $plz $ort";
      $cnt=$name=0; # nur wegen Warnung wegen dummy-Variablen
      if($ergebnis eq $soll){$ok_cnt++;}else{$nok_cnt++;}
      ok($ergebnis eq $soll,"LUT2: $retval (cnt: $cnt) / $ergebnis (Soll: $soll) (ok: $ok_cnt, nok: $nok_cnt)");
   }
}

__DATA__
10010010:POSTBANK NDL DB PFK, 10916 Berlin
15051732:Spk Mecklenburg-Strelitz, 17235 Neustrelitz
16050000:Mittelbrandenbg Sparkasse, 14459 Potsdam
18062678:VR Bank Lausitz, 3044 Cottbus
20040000:Commerzbank Hamburg, 20454 Hamburg
20050550:Haspa Hamburg, 20454 Hamburg
20080000:Commerzbank Hamburg, 20349 Hamburg
21050170:Förde Sparkasse, 24103 Kiel
25010030:POSTBANK NDL DB PFK, 30139 Hannover
25020600:Santander Consumer Bank, 30179 Hannover
25050180:Sparkasse Hannover, 30001 Hannover
30050000:Ld Bk Hess-Thür, Gz, Dus, 40019 Düsseldorf
30070010:Deutsche Bank Düsseldorf, 40189 Düsseldorf
50951469:Sparkasse Starkenburg, 64646 Heppenheim (Bergstraße)
54510067:POSTBANK NDL DB PFK, 67057 Ludwigshafen am Rhein
54651240:Spk Rhein-Haardt, 67087 Bad Dürkheim
