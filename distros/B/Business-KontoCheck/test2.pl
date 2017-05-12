# This is a small example for Business::KontoCheck. The program reads
# bank code numbers and account numbers from a file (delimited by at least one
# non-alphanumeric character), optionally followed by user comment. Then the
# account number is tested for validity and the line is written to the output.
# The test result is appended to the line. Empty lines or lines without bank
# code numbers or account number are copied to the output whithout
# modificaation.

# Dies ist eine kleine Beispielsanwendung für Business::KontoCheck. Das
# Programm list eine Reihe Bankleitzahlen und Kontonummern (durch mindestens
# ein nicht-alphanumerisches Zeichen getrennt) sowie noch evl. nachfolgenden
# Kommentar ein, testet das Konto auf Gültigkeit und gibt die Zeile (ergänzt
# durch den Rückgabewert) wieder aus. Leerzeilen sowie Zeilen ohne Bankleitzahl
# oder Kontonummer werden unverändert ausgegeben.
#
# Geschrieben 9.6.07, Michael Plugge
# 8.2.08 erweitert für konto_check 3.0

use Business::KontoCheck qw(kto_check kto_check_init kto_check_blz kto_check_at lut_info dump_lutfile
    lut_valid generate_lut2 lut_name lut_plz lut_ort kto_check_pz lut_filialen %kto_retval );

open(IN,"testkonten.txt") or die "Kann testkonten.txt nicht öffenen: $!\n";
open(OUT,"> testkonten.out") or die "Kann testkonten.out nicht öffenen: $!\n";

$ret=lut_info("blz.lut");
print  "info:  $ret => $kto_retval{$ret}\n";

$ret=kto_check_init("blz.lut");
print  "init:  $ret => $kto_retval{$ret}\n";

$ret=dump_lutfile("blz.dump",9);
print  "dump:  $ret => $kto_retval{$ret}\n";

$ret=lut_valid();
print  "valid: $ret => $kto_retval{$ret}\n";

#$ret=generate_lut2("blz.txt","blz.lut-perl");  # Minimalvariante mit Defaultwerten
$ret=generate_lut2("blz.txt","blz.lut-perl","Text für das user_info","20071203-20080303",3,0,23,3,0);
print  "generate_lut: $ret => $kto_retval{$ret}\n";

($ret,$i1,$v1)=lut_info("blz.lut-perl");
print  "lut_info: $ret => $kto_retval{$ret}\n";
print "valid1: $v1 => $kto_retval{$v1}\ninfo1:\n==================\n$i1==================\n";

for($i=0;$i<10;$i++){
   ($ret,$cnt,$name,$name_kurz,$plz,$ort,$pan,$bic,$pz,$nr,$aenderung,$loeschung,$nachfolg_blz)=Business::KontoCheck::lut_multiple("55090500",$i);
   print "==> multiple: $ret#$cnt#$name#$name_kurz#$plz#$ort#$pan#$bic#$pz#$nr#$aenderung#$loeschung#$nachfolg_blz\n";
}
while(<IN>){
   chomp;
   ($valid,$blz,$separator,$kto,$rest)=/(([0-9a-zA-Z\-]+)([^0-9a-zA-Z]+)([0-9]+))?(.*)/;
   if($valid){
#      $retval=kto_check($blz,$kto,"blz.lut");  # Aufruf mit alter Funktion (auch möglich)
      if(length($blz)==8){
         $retval=kto_check_blz($blz,$kto);
         ($cnt,$ret)=lut_filialen($blz);  # Aufruf im Array-Kontext -> zusätzlich Statuswert
         if($ret==1){   # OK -> Banknamen und Adresse ausgeben
            $name=" (".lut_name($blz).", ".lut_plz($blz)." ".lut_ort($blz).", $cnt Filialen)";
         }
         else{ # Fehler, leer lassen (die Fehlermeldung kam schon beim Test)
            $name="";
         }
      }
      else{
         $retval=kto_check_pz($blz,$kto);
         $name="";
      }
      print OUT "$blz$separator$kto$rest: $kto_retval{$retval}$name\n";
   }
   else{
      print OUT "$rest\n";
   }
}

print OUT "\n===============================================\n\nÖsterreichische Testkonten:\n\n";
open(IN,"testkonten-at.txt") or die "Kann testkonten-at.txt nicht öffenen: $!\n";

while(<IN>){
   chomp;
   ($valid,$blz,$separator,$kto,$rest)=/(([0-9a-zA-Z\-]+)([^0-9a-zA-Z]+)([0-9]+))?(.*)/;
   if($valid){
      $retval=kto_check_at($blz,$kto,"");
      print OUT "$blz$separator$kto$rest: $kto_retval{$retval}\n";
   }
   else{
      print OUT "$rest\n";
   }
}
@vz=Business::KontoCheck::ipi_gen("1234as5778dfgxyy");
print "vz: $vz[0], Papierform: $vz[1], Rückgabewert: $vz[2] -> $kto_retval{$vz[2]}\n";
$test=Business::KontoCheck::ipi_check($vz[0]);
print "Test ipi: $test ($kto_retval{$test})\n";
