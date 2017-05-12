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

use Business::KontoCheck qw(kto_check_init kto_check_blz lut_valid lut_name
     lut_plz lut_ort kto_check_pz lut_cleanup %kto_retval);

($ret=kto_check_init("../blz.lut"))>0 or die "Fehler bei der Initialisierung: $kto_retval{$ret}\n";
$ret=lut_valid();
print  "lut_valid: $ret => $kto_retval{$ret}\n";

open(IN,@ARGV[0]) or die "Kann ".@ARGV[0]." nicht öffenen: $!\n";
open(OUT,"> testkonten.out") or die "Kann testkonten.out nicht öffenen: $!\n";

while(<IN>){
   chomp;
      # eine Zeile aufdröseln und den Variablen zuweisen
   ($valid,$blz,$separator,$kto,$rest)=/(([0-9a-zA-Z\-]+)([^0-9a-zA-Z]+)([0-9]+))?(.*)/;
   if($valid){
      if(length($blz)==8){ # BLZ angegeben
         $retval=kto_check_blz($blz,$kto);
         if($retval>0){   # OK -> Banknamen und Adresse ausgeben
            $name=": ".lut_name($blz).", ".lut_plz($blz)." ".lut_ort($blz);
         }
         else{ # Fehler, leer lassen
            $name="";
         }
      }
      else{    # Prüfziffermethode angegeben
         $retval=kto_check_pz($blz,$kto);
         $name="";
      }
      print OUT "$blz$separator$kto$rest: $kto_retval{$retval}$name\n";
   }
   else{
      print OUT "$rest\n";
   }
}
lut_cleanup(); # Speicher freigeben

