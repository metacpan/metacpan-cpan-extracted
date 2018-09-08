
############################################################
### dies ist eine generierte Datei - nicht editieren!!!  ###
############################################################

use 5.006000;
use ExtUtils::MakeMaker;
use File::Find;

# Configuration part

$use_german   = 1;   # Test für deutsche Bankkonten einbauen
$use_austrian = 0;   # Test für österreichische Bankkonten einbauen
$use_lx2l     = 0;   # lx2l benutzen (nur für die Entwicklung)

# In der folgenden Variablen kann der komplette Pfad von zlib.a eingetragen
# werden. Falls die Variable leer ist, wird die Datei gesucht; das kann
# bei größeren Installationen allerdings eine Weile dauern. Um die Zeit
# abzukürzen, wird zunächst in einigen bekannten Verzeichnissen gesucht,
# bevor die Suche auf die gesamte Partition ausgedehnt wird.
$zlib_static  = "";

$define=" -DDEFAULT_ENCODING=2 ";

if($use_austrian){
   $define.=" -DINCLUDE_KONTO_CHECK_AT=1 ";
}
else{
   $define.=" -DINCLUDE_KONTO_CHECK_AT=0";
}

if($use_german){
   $define.=" -DINCLUDE_KONTO_CHECK_DE=1";
}
else{
   $define.=" -DINCLUDE_KONTO_CHECK_DE=0";
}

print "Preparing Check for zlib development package...\n";
my $start=time();

# zunächst eine initiale Version des Makefiles schreiben; aus der läßt sich dann der Compiler-Aufruf
# und einige Tools sowie das Betriebssystem ermitteln. Danach wird der Test für die zlib gemacht.
#
# Für Windows muß zlib.a mit vollem Pfad in die Makros LDLOADLIBS sowie EXTRALIBS eingetragen
# werden. Falls keine zlib installiert ist, wird die lokale Kopie kompiliert und in einem zweiten
# Aufruf von write_makefile() eingetragen.

write_makefile();

# nun können aus dem generierten Makefile die Kommandos für den C Compiler, ar, ranlib
# sowie die Betriebsystemfamilie extrahiert werden. Mit den Infos kann dann eine Testdatei
# kompiliert werden und bei Bedarf eine lokale libz.a generiert werden.

$have_zlib=0;
$zlib_dir="";
$own_zlib=0;

open(IN, "<Makefile");
while(<IN>){
   $ar=$1 if(/^AR = (.+)/);
   $cc=$1 if(/^CC = (.+)/);
   $install_bin=$1 if(/^INSTALLBIN = (.+)/);
   $osname=$1 if(/^OSNAME = (.+)/);
   $ranlib=$1 if(/^RANLIB = (.+)/);
}
if($osname=~/MSWin/i){
   $os_windows=1;
	$os_darwin=0;
}
else{
	if($osname=~/darwin/i){
		$os_windows=0;
		$os_darwin=1;
	}
	else{
		$os_darwin=$os_windows=0;
	}
}
close(IN);

# zweiter Teil: testen ob die zlib verfügbar ist

if($os_windows){
   test_zlib() if($zlib_static);

   if(!$zlib_static){
# Laufwerk auf dem Perl installiert ist (da findet sich vielleicht auch die zlib)
      $drive=substr($install_bin,0,3).".";
      print "... searching for zlib.a on windows (drive $drive), may need some time ...\n";
      search_zlib("$drive/strawberry/c/lib") if(!$zlib_static);
      search_zlib("$drive/MinGW/lib") if(!$zlib_static);
      search_zlib("$drive/cygwin/lib") if(!$zlib_static);
      search_zlib("$drive/strawberry") if(!$zlib_static);
      search_zlib("$drive/MinGW") if(!$zlib_static);
      search_zlib("$drive/cygwin") if(!$zlib_static);
      search_zlib("$drive/msys") if(!$zlib_static);
      search_zlib("$drive/") if(!$zlib_static);
   }
}
else{
   if($os_darwin){
# Mac-System; nur -lz, selbst kompilieren macht bislang Probleme
      $zlib_static=" -lz";
      $have_zlib=1;
   }
   else{
# Nicht-Windows System; testen mit -lz
      $zlib_static=" -lz";  # Krücke für test_zlib()
      test_zlib();
      $zlib_static="";
   }
}

if(!$have_zlib){
# keine zlib gefunden; selbst kompilieren und makefile anpassen
   $have_zlib=0;
	compile_zlib();
   test_zlib();
   if($zlib_static){
# das makefile muß mit geändertem Includepfad noch einmal geschrieben werden
      $own_zlib=1;
      $zlib_dir=" -Izlib";
      write_makefile();
   }
}

# hier sollte die zlib eigentlich verfügbar sein; Notausstieg, falls etwas mit dem
# Compilieren nicht geklappt hat (da muß der Benutzer selbst Hand anlegen; evl. wurden
# irgendwelche Includedateien nicht gefunden, und ein configure-Aufruf ist notwendig.)
# Die zlib selbst läßt sich auf praktisch jeder Plattform kompilieren.

if(!$have_zlib){
   print <<QUARK
I could not find the required file zlib.a and was unable to compile this
library. You should download zlib from http://zlib.org, compile it and add
the complete path to the top of this file (variable \$zlib_static). Then try
again to run Makefile.PL. Good luck :-)

QUARK
;
   return;
}

# dritter Teil: Windows oder keine zlib gefunden. In dem Fall muß das Makefile noch leicht
# angepaßt werden (Bibliotheken in LDLOADLIBS und EXTRALIBS eintragen) 

if($own_zlib || $os_windows){
   open(IN, "<Makefile");
   open(OUT,">Makefile.neu");

   if($os_windows){
      while(<IN>){   
         s/^LDLOADLIBS = /LDLOADLIBS = $zlib_static /;
         s/^EXTRALIBS = /EXTRALIBS = $zlib_static /;
         print OUT;
      }
   }
   else{
      while(<IN>){   
         s/^LDLOADLIBS = -lz/LDLOADLIBS = $zlib_static /;
         s/^EXTRALIBS = -lz/EXTRALIBS = $zlib_static /;
         print OUT;
      }
   }
   close(IN);
   close(OUT);
   rename("Makefile.neu","Makefile");
}


# einige Hilfsfunktionen

# die zlib selbst kompilieren
sub compile_zlib{
   print "Compile zlib:\n";
   chdir("zlib");
   system("$cc -c -O2 *.c");
   unlink("minigzip.o");
   unlink("example.o");
   system("$ar rsc libz.a *.o");
   system("$ranlib libz.a");
   chdir("..");
   my $retval=rename("zlib/libz.a","libz.a");
   if($retval==1){   # Datei vorhanden und umbenannt
      $zlib_static="libz.a";
      $have_zlib=1;
      $own_zlib=1;
   }
}

sub search_zlib
{
   my $dir=$_[0];
   print "looking for zlib.a in $dir...\n";
   find({"wanted"=>\&wanted,"preprocess"=>\&preprocess},$dir);
}

# Funktion die testet, ob die zlib gefunden wurde
sub wanted{
  if(/^libz.a$/){
     print "found $File::Find::name\n";
     $zlib_static=$File::Find::name;
     $zlib_static=~s+/+\\+g;
     $zlib_static=~s+:\\\.\\+:\\+g;
     test_zlib();
  }
}

# Suche abbrechen, falls die zlib schon gefunden wurde
sub preprocess {
   return @_ if(!$have_zlib);
}

# gefundene zlib.a testen durch probeweises Compilieren
sub test_zlib
{
   print "Compile test programm with $zlib_static: ";
   write_testfile();
   my $retval=system("$cc test_zlib.c $zlib_static -otest_zlib ");
   if($retval){ # Fehler beim Compilieren
      print "fail\n";
      $zlib_static="";
   }
   else{
      print "ok\n";
      $have_zlib=1;
   }

# nun wieder aufräumen, damit die Testdateien nicht ins Makefile eingebaut werden
   unlink("test_zlib.c");
   unlink("test_zlib");
   unlink("test_zlib.exe");
}

# C Testdatei schreiben
sub write_testfile
{
   open(TF,"> test_zlib.c") or die "can't open test_zlib.c";
   print TF <<EOD
#include <stdio.h>
#include <string.h>
#include <zlib.h>

#define CP  (char *)
#define UCP (unsigned char *)

int main(int argc,char **argv)
{
   unsigned char buffer1[1024],buffer2[1024];
   unsigned char *ptr=UCP "hello world, hello world, hello world, hello world, hello world, hello world, "
      "hello world, hello world, hello world, hello world, hello world, hello world, "
      "hello world, hello world, hello world, hello world, hello world, hello world, "
      "hello world, hello world, hello world, hello world, hello world, hello world";
   unsigned long len,len1,len2,retval;

   len=strlen(CP ptr);
   len1=len2=1024;
   retval=compress2(buffer2,&len2,ptr,len,9);
   printf("compressed: %lu -> %lu byte\\n",len,len2);
   retval=uncompress(buffer1,&len1,buffer2,len2);
   printf("uncompressed: %lu -> %lu byte; check: %d\\n",len2,len1,strcmp(CP buffer1,CP ptr));
   return strcmp(CP ptr,CP buffer1);
}
EOD
;
   close(TF);
}

# Makefile schreiben; wird durch diverse Variablen modifiziert
sub write_makefile
{
   WriteMakefile(
      NAME          => 'Business::KontoCheck',
      VERSION_FROM  => 'lib/Business/KontoCheck.pm', # finds $VERSION
      PREREQ_PM         => {
                           'Test::Pod' => '0', # or a minimum working version
                           },
      ABSTRACT_FROM => 'lib/Business/KontoCheck.pm', # retrieve abstract from module
      AUTHOR        => 'Michael Plugge <m.plugge@hs-mannheim.de>',
      LIBS          => ['-L.','-lz'],
      LDFLAGS       => '-L.',
      DEFINE        => $define,
      INC           => "-I.$zlib_dir", # e.g., '-I. -I/usr/include/other'
      OBJECT        => '$(O_FILES)',   # link all the C files too
      NO_META       => 1,              # META.yml is manually generated
      dist          => { 
                              TARFLAGS => 'cf',
                              COMPRESS => 'gzip --best --force',
                              SUFFIX => '.gz',
                              SHAR => 'shar -m',
                              DIST_CP => 'ln',
                              ZIP => '/bin/zip',
                              ZIPFLAGS => '-rl',
                              DIST_DEFAULT => 'private tardist'
                           },

# the following dependencies are for my private build tool lx2l (a little esoteric ;-) )
      ($use_lx2l==1 ?
      (depend        => {
                           'konto_check-cfg.lx' => "konto_check-cfg.lxx\n\tlx2l -x \$<",
                         'lib/Business/KontoCheck.pm' => "pm.lxx konto_check-cfg.lx\n\tlx2l -x \$<",
                         'META.yml'            => "META.lx konto_check-cfg.lx\n\tlx2l \$<",
                         'konto_check.h'      => "konto_check_h.lx konto_check-cfg.lx META.yml lib/Business/KontoCheck.pm\n\tlx2l \$<",
                         'retvals.h'          => "retvals.lx konto_check-cfg.lx \n\tlx2l \$< -ua1",
                         'konto_check.c'      => "konto_check.lxx lib/Business/KontoCheck.pm META.yml retvals.h konto_check-cfg.lx \n\tlx2l -x \$< -ua1",
                         'konto_check-at.c'   => "konto_check-at.lxx konto_check-cfg.lx\n\tlx2l -x \$<",
                         'konto_check-at.h'   => "konto_check-at.lxx konto_check-cfg.lx\n\tlx2l -x \$< -uh",
                         'KontoCheck.xs'      => "KontoCheck.lx lib/Business/KontoCheck.pm konto_check-cfg.lx\n\tlx2l \$<",
                         'Makefile.PL'        => "makefile.lx konto_check-cfg.lx\n\tlx2l \$< -um",
                       }) :())
  );
}

