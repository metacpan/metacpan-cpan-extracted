/* 
 vim:cindent:ft=c:foldmethod=marker:fmr=+§§§,-§§§
*/

/* C prolog +§§§1
   Copyright-Notitz +§§§2 */

/*
 * ##########################################################################
 * #  Dies ist konto_check-at, ein Programm zum Testen der Prüfziffern von  #
 * #  österreichischen Bankkonten. Es kann jedoch auch als eigenständiges   #
 * #  Programm oder als Library zur Verwendung in anderen Programmen        #
 * #  benutzt werden.                                                       #
 * #                                                                        #
 * #  Copyright (C) 2006 Michael Plugge <m.plugge@hs-mannheim.de>           #
 * #                                                                        #
 * #  Dieses Programm ist freie Software; Sie dürfen es unter den           #
 * #  Bedingungen der GNU Lesser General Public License, wie von der Free   #
 * #  Software Foundation veröffentlicht, weiterverteilen und/oder          #
 * #  modifizieren; entweder gemäß Version 2.1 der Lizenz oder (nach Ihrer  #
 * #  Option) jeder späteren Version.                                       #
 * #                                                                        #
 * #  Die GNU LGPL ist weniger infektiös als die normale GPL; Code, der von #
 * #  Ihnen hinzugefügt wird, unterliegt nicht der Offenlegungspflicht      #
 * #  (wie bei der normalen GPL); außerdem müssen Programme, die diese      #
 * #  Bibliothek benutzen, nicht (L)GPL lizensiert sein, sondern können     #
 * #  beliebig kommerziell verwertet werden. Die Offenlegung des Sourcecodes#
 * #  bezieht sich bei der LGPL *nur* auf geänderten Bibliothekscode.       #
 * #                                                                        #
 * #  Dieses Programm wird in der Hoffnung weiterverbreitet, daß es         #
 * #  nützlich sein wird, jedoch OHNE IRGENDEINE GARANTIE, auch ohne die    #
 * #  implizierte Garantie der MARKTREIFE oder der VERWENDBARKEIT FÜR       #
 * #  EINEN BESTIMMTEN ZWECK. Mehr Details finden Sie in der GNU Lesser     #
 * #  General Public License.                                               #
 * #                                                                        #
 * #  Sie sollten eine Kopie der GNU Lesser General Public License          #
 * #  zusammen mit diesem Programm erhalten haben; falls nicht,             #
 * #  schreiben Sie an die Free Software Foundation, Inc., 59 Temple        #
 * #  Place, Suite 330, Boston, MA 02111-1307, USA. Sie können sie auch     #
 * #  von                                                                   #
 * #                                                                        #
 * #       http://www.gnu.org/licenses/lgpl.html                            #
 * #                                                                        #
 * # im Internet herunterladen.                                             #
 * #                                                                        #
 * ##########################################################################
 */

/* Include-Dateien +§§§2 */
#ifndef INCLUDE_KONTO_CHECK_AT
#define INCLUDE_KONTO_CHECK_AT 1
#endif
#if INCLUDE_KONTO_CHECK_AT
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>
#include "konto_check-at.h"


/* Präprozessor-Makros +§§§2 */
/* Makros UC, UCP, C2UM, UM2C, C2UL, UL2C: Umwandlung Binärdaten -> Integerzahl +§§§3 */
/* ######################################################################
 * # einige häufig benutzte Makros zur Umwandlung zwischen signed und   #
 * # unsigned char-Pointern sowie zur Umwandlung von Bytestreams in INT #
 * # Werte. Die Anordnung in der Ausgabedatei ist big endian, damit die #
 * # erzeugten Binärdateien sich (bei Bedarf ;-) ) besser lesen lassen. #
 * # Dies ist anders als bei der deutschen Version (!). Dort war im     #
 * # Anfang keine Notwendigkeit, die Binärdatei anzusehen, und später   #
 * # (als es interessant gewesen wäre) war es dann zu spät zum Wechsel. #
 * # Die LUT2-Routinen arbeiten allerdings komplett mit little endian,  #
 * # da sie auf dem alten deutschen Format aufbauen.                    #
 * ######################################################################
 */

#define UC  (unsigned char)
#define UCP  (unsigned char *)

   /* C2UM: 3 Byte binär umwandeln in eine 4 Byte Integer-Zahl */
#define C2UM         (*(uptr  )) * 0x10000UL \
                    +(*(uptr+1)) * 0x100UL \
                    +(*(uptr+2)); \
                    uptr+=3

   /* UM2C: eine 4 Byte Integer-Zahl umwandeln in 3 Byte (begrenzten
    * Zahlenraum beachten, die Zahl darf nur 24 signifikante Bit haben!!)
    */
#define UM2C(x) *uptr++=UC ((x)/0x10000L  ) & 0xff; \
                *uptr++=UC ((x)/0x100L    ) & 0xff; \
                *uptr++=UC ((x)           ) & 0xff

   /* C2UL: 4 Byte umwandeln in eine 4 Byte Integer-Zahl */
#define C2UL       (UC *(uptr)  ) * 0x1000000UL \
                  +(UC *(uptr+1)) * 0x10000UL \
                  +(UC *(uptr+2)) * 0x100UL \
                  +(UC *(uptr+3)); \
                  uptr+=4

   /* UL2C: eine 4 Byte Integer-Zahl umwandeln in 4 Byte */
#define UL2C(x) *uptr++=UC ((x)/0x1000000L) & 0xff; \
                *uptr++=UC ((x)/0x10000L  ) & 0xff; \
                *uptr++=UC ((x)/0x100L    ) & 0xff; \
                *uptr++=UC ((x)           ) & 0xff

   /* E_L: als Markierungsflag benutzt */
#ifndef E_L
#define E_L 2718281828ul
#endif

/* Makros EXTRACT, EXTRACT_1, EXTRACT_NUM +§§§3 */
/* EXTRACT, EXTRACT_NUM: Makros, um Text bzw. Zahlen aus einer Zeile der
 * INPAR-Datei zu extrahieren.
 */

#define EXTRACT(var,pos,cnt) for(i=0,ptr=buffer+pos-1,dptr=var;i<cnt;i++)switch(UC *ptr){ \
         case 132: *dptr++='ä'; ptr++; break; \
         case 148: *dptr++='ö'; ptr++; break; \
         case 129: *dptr++='ü'; ptr++; break; \
         case 142: *dptr++='Ä'; ptr++; break; \
         case 153: *dptr++='Ö'; ptr++; break; \
         case 154: *dptr++='Ü'; ptr++; break; \
         case 225: *dptr++='ß'; ptr++; break; \
         default:  *dptr++=*ptr++;     break; \
      } \
      *dptr=0

#define EXTRACT_1(var,pos) ptr=buffer+pos-1; switch(UC *ptr){ \
         case 132: var='ä';  break; \
         case 148: var='ö';  break; \
         case 129: var='ü';  break; \
         case 142: var='Ä';  break; \
         case 153: var='Ö';  break; \
         case 154: var='Ü';  break; \
         case 225: var='ß';  break; \
         default:  var=*ptr; break; \
      }

#define EXTRACT_NUM(var,pos,cnt) for(i=0,ptr=buffer+pos-1,dptr=buffer2;i<cnt;i++)*dptr++=*ptr++; \
       *dptr=0; var=atoi(buffer2)

/* Makros bedingung, bedingung2 (für kto_check_at()) +§§§3 */
#define BEDINGUNG2(chr1,chr2,ziffer) case chr1: BEDINGUNG(chr2,ziffer)
#define BEDINGUNG(chr,ziffer) case chr: \
            switch(*ptr){ \
               case '0': \
               case '1': \
               case '2': \
               case '3': \
               case '4': \
               case '5': \
               case '6': \
               case '7': \
               case '8': \
               case '9': \
                  if(kto[11- 0x ## ziffer]!=*ptr){ \
                     ptr+=6; \
                     continue; \
                  } \
                  break; \
               case 'a': \
               case 'A': \
                  if(kto[11- 0x ## ziffer]!='0' || kto[12- 0x ## ziffer]!='0'){ \
                     ptr+=6; \
                     continue; \
                  } \
                  break; \
               case 'b': \
               case 'B': \
                  if(kto[11- 0x ## ziffer]!='0' || kto[12- 0x ## ziffer]!='0' || kto[13- 0x ## ziffer]!='0'){ \
                     ptr+=6; \
                     continue; \
                  } \
                  break; \
               case 'c': \
               case 'C': \
                  if(kto[11- 0x ## ziffer]!='5' || kto[12- 0x ## ziffer]!='9' || kto[13- 0x ## ziffer]!='9'){ \
                     ptr+=6; \
                     continue; \
                  } \
                  break; \
               case 'd': \
               case 'D': \
                  if(kto[11- 0x ## ziffer]!='8' || kto[12- 0x ## ziffer]!='8' || kto[13- 0x ## ziffer]!='8'){ \
                     ptr+=6; \
                     continue; \
                  } \
                  break; \
               case 'e': \
               case 'E': \
                  if(kto[11- 0x ## ziffer]!='9' || kto[12- 0x ## ziffer]!='9' || kto[13- 0x ## ziffer]!='9'){ \
                     ptr+=6; \
                     continue; \
                  } \
                  break; \
            } \
            break
/* lokale (nicht exportierte) Prototypen und static Variablen +§§§2 */
static int init_globals(char *lut_name);
static int read_lut(char *lut_name);
static int cmp_blz(const void *ap,const void *bp);
static int search_blz(int such_blz);
static UINT4 adler32(UINT4 adler,const signed char *buf,unsigned int len);

static signed char tabelle[MAX_TABLE_CNT_AT][80],loesch_datum[MAX_BLZ_CNT_AT][12],hauptstelle[MAX_BLZ_CNT_AT],
            blz_tabelle[100000],geloeschte_blz[100000];
static int blz[MAX_BLZ_CNT_AT],blz2[MAX_BLZ_CNT_AT],blz_idx[MAX_BLZ_CNT_AT],pruef_tabelle[MAX_BLZ_CNT_AT],
           ident[MAX_BLZ_CNT_AT],tabelle_name[MAX_BLZ_CNT_AT],blz_anzahl,loesch_datum_num[MAX_BLZ_CNT_AT];

static unsigned long global_vars_initialized,init_in_progress;

const static int w[18][11]={
      {0,0,0,0,0,0,0,0,0,0,0},  /* 0 */
      {1,2,1,2,1,2,1,2,1,2,1},  /* 1 */
      {1,2,3,4,5,6,7,2,3,4,5},  /* 2 */
      {1,2,3,4,5,6,7,8,9,1,2},  /* 3 */
      {0,0,1,9,3,7,5,4,8,2,6},  /* 4 */
      {0,1,7,5,3,1,7,5,3,1,7},  /* 5 */
      {1,3,7,1,3,7,1,3,7,1,3},  /* 6 */
      {1,2,4,8,7,5,1,0,0,0,0},  /* 7 */
      {1,2,4,8,5,10,9,7,3,0,0},  /* 8 */
      {1,2,3,4,5,0,0,2,3,4,5},  /* 9 */
      {0,1,2,1,3,4,5,6,7,8,9},  /* A */
      {0,7,9,8,1,3,0,0,0,0,0},  /* B */
      {1,0,2,1,2,1,2,1,2,1,2},  /* C */
      {0,0,0,1,2,3,4,5,6,0,0},  /* D */
      {1,9,3,7,5,4,8,2,6,0,0},  /* E */
      {0,0,0,1,2,1,2,1,2,1,2},  /* F */
      {0,0,0,1,2,3,4,5,6,7,2},  /* G */
      {0,1,2,6,5,7,4,8,3,9,2}   /* H */
   };

   /* die beiden Arrays char2num und char2numi dienen zur einfachen Umwandlung
    * einer (erweiterten) ASCII-Zahl in einen numerischen Wert. Der
    * Wertebereich von char2num[] liegt bei '0' bis '9' und 'a bis 'z' sowie
    * 'A' bis 'Z'; die Buchstaben (sowohl Klein- als auch Großbuchstaben)
    * bekommen die Werte 10, 11, ... zugewiesen.
    * Das Array char2numi enthält die Umsetzung 11-c, wobei c einen ASCII-Wert
    * aus [0-9aA] enthalten kann.
    * Das Parameter parameter_valid enthält ein Binärmuster für den Test der
    * Prüfparameter. Benutzte Werte:
    *
    * Feldname                    Wertebereich     Flag
    * 1. Stelle                    1...9, A, B       1  
    * Anzahl Stellen               1...9, A, B       2  
    * Position der Prüfziffer      1...9, A, B       4  
    * Gewichtung                   0...9, A...H      8  
    * Rechenvorgang                0...8            16  
    */

const static int char2num[]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,
   10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,
   0,0,0,0,0,0,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,
   32,33,34,35,0,0,0,0,0,}, 
char2numi[]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,11,10,9,8,7,6,5,4,3,2,0,0,0,0,0,0,0,1,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
parameter_valid[]={20,22,22,22,22,22,22,22,22,6,6,2,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,9,9,9,9,9,9,9,
   9,9,0,0,0,0,0,0,0,9,9,8,8,8,8,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,0,9,9,8,8,8,8,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,};


/* Funktion adler32()+§§§1 */
/* ##########################################################################
 * # Die Funktion adler32.c wurde aus der zlib entnommen                    #
 * #                                                                        #
 * # adler32.c -- compute the Adler-32 checksum of a data stream            #
 * # Copyright (C) 1995-1998 Mark Adler                                     #
 * # For conditions of distribution and use, see copyright notice in zlib.h #
 * ##########################################################################
 */

#define BASE 65521L /* largest prime smaller than 65536 */
#define NMAX 5552
   /* NMAX is the largest n such that 255n(n+1)/2 + (n+1)(BASE-1) <= 2^32-1 */

#define DO1(buf,i)  {s1+=buf[i]; s2+=s1;}
#define DO2(buf,i)  DO1(buf,i); DO1(buf,i+1);
#define DO4(buf,i)  DO2(buf,i); DO2(buf,i+2);
#define DO8(buf,i)  DO4(buf,i); DO4(buf,i+4);
#define DO16(buf)   DO8(buf,0); DO8(buf,8);

/*
 *  Update a running Adler-32 checksum with the bytes buf[0..len-1] and
 *  return the updated checksum. If buf is NULL, this function returns
 *  the required initial value for the checksum.
 *  An Adler-32 checksum is almost as reliable as a CRC32 but can be computed
 *  much faster. Usage example:
 *
 *    uLong adler = adler32(0L, Z_NULL, 0);
 *
 *    while (read_buffer(buffer, length) != EOF) {
 *      adler = adler32(adler, buffer, length);
 *    }
 *    if (adler != original_adler) error();
 *
 * das "signed char *buf" ist eigentlich falsch; in der alten Version stand nur
 * "const char *buf", aber das gibt dann bei Plattformen, die defaultmäßig
 * "unsigned char" für den Datentyp char haben, einen Fehler. Daher wird hier
 * eine inkorrekte Implementierung des adler32 Algorithmus benutzt; diese hat
 * jedoch den Vorteil, kompatibel zur alten konto_check-at Version zu sein.
 */
static UINT4 adler32(UINT4 adler,const signed char *buf,unsigned int len)
{
   UINT4 s1=adler&0xffff;
   UINT4 s2=(adler>>16)&0xffff;
   int k;

   if(buf==NULL)return 1L;

   while(len>0){
      k=len<NMAX ? len:NMAX;
      len-=k;
      while(k>=16){
         DO16(buf);
	      buf+=16;
         k-=16;
      }
      if(k!=0)do{
         s1+=*buf++;
         s2+=s1;
      } while(--k);
      s1%=BASE;
      s2%=BASE;
   }
   return (s2<<16)|s1;
}

/* Funktion cmp_blz()  +§§§1 */
/* ##############################################################################
 * # cmp_blz: Vergleichsfunktion für Quicksort. Die erste Sortiervariable ist   #
 * # die Bankleitzahl, die zweite die Prüftabelle, danach Löschdatum und        #
 * # Hauptstelle/Zweigstelle und am Schluß die Identnummer.                     #
 * #                                                                            #
 * # Ziel ist, eine Hauptstelle an erste Position zu schieben, sowie nicht      #
 * # gelöschte Einträge nach vorne zu schieben und die gelöschten Einträge in   #
 * # der Reihenfolge der Löschung zu sortieren. Das Kennzeichen für die         #
 * # Hauptstelle scheint allerdings nicht ganz konsistent zu sein; manchmal     #
 * # erscheinen nur Zweigstellen, oder eine Hauptstelle wurde gelöscht. Falls   #
 * # allerdings eine gültige Hauptstelle existiert, wird sie für den Eintrag    #
 * # benutzt.                                                                   #
 * #                                                                            #
 * # Das Löschdatum erhält eine besondere Behandlung: Falls eines der beiden    #
 * # Daten 0 ist (Eintrag nicht gelöscht), wird der entsprechende Eintrag nach  #
 * # oben geschoben (mittels return 1/return -1); andernfalls werden die Werte  #
 * # absteigend sortiert (=> neueste Löschungen zuerst). So werden gültige      #
 * # Bankleitzahlen nach vorn geschoben, so daß sie auf jeden Fall aufgenommen  #
 * # werden, auch falls für eine oder mehrere Filialen (mit derselben BLZ!!)    #
 * # eine Löschung beantragt wurde. Die Hauptstelle muß zweimal getestet werden,#
 * # einmal, falls beide Löschdaten nicht gesetzt sind, und dann nochmal nach   #
 * # dem Test auf je ein Löschdatum (bei Löschung von einzelnen Filialen).      #
 * #                                                                            #
 * # Falls eine BLZ gelöscht wurde, und mehrere Einträge (mit unterschiedlichen #
 * # Daten) in der Liste sind, wird durch die absteiegende Sortierung das Datum #
 * # der letzten Löschung in die blz-at.lut Datei aufgenommen (es gibt zu jeder #
 * # BLZ nur einen Eintrag).                                                    #
 * #                                                                            #
 * # Die Funktion ist *nicht* threadfest, da globale Variablen benutzt werden   #
 * # (müssen).                                                                  #
 * #                                                                            #
 * # Copyright (C) 2006 Michael Plugge <m.plugge@hs-mannheim.de>                #
 * ##############################################################################
 */

static int cmp_blz(const void *ap,const void *bp)
{
   int retval,ld1,ld2,a,b;

   a=*((int *)ap);
   b=*((int *)bp);
   if((retval=blz[a]-blz[b]))
      return retval;
   else if((retval=pruef_tabelle[a]-pruef_tabelle[b]))
      return retval;
   ld1=loesch_datum_num[a];
   ld2=loesch_datum_num[b] ;  
   if(!ld1 && !ld2 && hauptstelle[a]!=hauptstelle[b]){
      if(hauptstelle[a]=='H')return -1;
      if(hauptstelle[b]=='H')return 1;
   }
   if(!ld1)return -1;
   if(!ld2)return 1;
   if(hauptstelle[a]=='H' && hauptstelle[b]!='H')return -1;
   if(hauptstelle[a]!='H' && hauptstelle[b]=='H')return 1;
   if(ld1==ld2)
      return ident[a]-ident[b];
   else
      return ld2-ld1;
}

/* Funktion search_blz_idx()  +§§§1 */
/* ###############################################################################
 * # search_blz_idx: Index einer bestimmten Bankleitzahl suchen (nur für         #
 * # generate_lut()!!!).                                                         #
 * #                                                                             #
 * # Die Funktion wird von generate_lut benutzt, um die Prüftabelle von          #
 * # zugeordneten Bankleitzahlen zu bestimmen. Die Implementierung setzt voraus, #
 * # daß das Array durch den Index blz_idx[] bereits sortiert wurde, also nicht  #
 * # direkt wie bei search_blz(). Dies ist bei der Funktion generate_lut() der   #
 * # Fall; dort wird der Index generiert.                                        #
 * #                                                                             #
 * # Rückgabe: Index der BLZ oder -1, falls nicht gefunden.                      #
 * #                                                                             #
 * # Copyright (C) 2006 Michael Plugge <m.plugge@hs-mannheim.de>                 #
 * ###############################################################################
 */

static int search_blz_idx(int such_blz)
{
   int unten,oben,chk,b1=0,diff;

   oben=blz_anzahl;
   for(unten=0,chk=oben/2;oben!=unten;){
      if((b1=blz[blz_idx[chk]])<such_blz){
         unten=chk;
         if((diff=oben-chk)==1){
            b1=blz[blz_idx[oben]];
            break;
         }
         else
            chk+=diff/2;
      }
      else if(b1==such_blz)
         break;
      else{
         oben=chk;
         if((diff=chk-unten)==1){
            b1=blz[blz_idx[unten]];
            break;
         }
         else
            chk-=diff/2;
      }
   }
   if(b1==such_blz)
      return blz_idx[chk];
   else
      return -1;
}

/* Funktion generate_lut_at()  +§§§1 */
/* Beschreibung, Parameter  +§§§3 */
/* ###########################################################################
 * # Die Funktion generate_lut_at() generiert aus der Institutsparameter-    #
 * # Datenbankdatei (5,3 MB) eine kleine Datei (8,3 KB), in der nur die      #
 * # Bankleitzahlen und Prüfziffermethoden gespeichert sind. Um die Datei    #
 * # klein zu halten, wird der größte Teil der Datei binär gespeichert.      #
 * #                                                                         #
 * # Am Anfang ist ein Kopfteil mit diversen Infoeinträgen, danach kommen    #
 * # die Tabellen der Kontoprüfparameter (als Klartext). Darauf folgt der    #
 * # Hauptteil der Datei mit Bankleitzahlen (jeweils in 3 Byte kodiert) und  #
 * # zugehöriger Kontoprüfparameter-Tabelle (1 Byte Index).                  #
 * #                                                                         #
 * # Falls eine Bankleitzahl gelöscht wurde, wird als Index 0xff eingetragen #
 * # und danach das Löschdatum (ebenfalls mit 3 Byte); danach wird noch im   #
 * # folgenden Byte der Index der Prüftabelle angegeben, damit die BLZ bei   #
 * # Bedarf geprüft werden kann.                                             #
 * #                                                                         #
 * # Bei fiktiven Bankleitzahlen wird als Prüfparameter-Index 0xfe benutzt,  #
 * # und die zugeordnete BLZ (und Prüftabelle) wie bei gelöschten BLZs       #
 * # im nächsten Langwort eingetragen.                                       #
 * #                                                                         #
 * # Falls der Parameter plain_name angegeben wird, wird zu jeder INPAR-     #
 * # Eintrag außerdem (in einem frei wählbaren Format) noch in eine Klartext-#
 * # datei geschrieben. Das Format der Datei wird durch den 4. Parameter     #
 * # (plain_format) bestimmt. Es sind die folgenden Felder und Escape-       #
 * # Sequenzen definiert (der Sortierparameter muß als erstes Zeichen        #
 * # kommen!):                                                               #
 * #                                                                         #
 * #    @i   Sortierung nach Identnummern                                    #
 * #    @b   Sortierung nach Bankleitzahlen (default)                        #
 * #    %b   Bankleitzahl                                                    #
 * #    %B   Bankleitzahl (5-stellig, links mit Nullen aufgefüllt)           #
 * #    %f   Kennzeichen fiktive Bankleitzahl                                #
 * #    %h   Kennzeichen Hauptstelle/Zweigstelle                             #
 * #    %i   Identnummer der Österreichischen Nationalbank                   #
 * #    %I   Identnummer der Österreichischen Nationalbank (7-stellig)       #
 * #    %l   Löschdatum (DD.MM.YYYY falls vorhanden, sonst nichts)           #
 * #    %L   Löschdatum (DD.MM.YYYY falls vorhanden, sonst 10 Blanks)        #
 * #    %n1  Erster Teil des Banknamens                                      #
 * #    %n2  Zweiter Teil des Banknamens                                     #
 * #    %n3  Dritter Teil des Banknamens                                     #
 * #    %N   kompletter Bankname (alle drei Teile zusammengesetzt)           #
 * #    %p   Kontoprüfparameter                                              #
 * #    %t   Name der Prüftabelle                                            #
 * #    %z   zugeordnete BLZ (nur bei fiktiver BLZ, sonst nichts)            #
 * #    %Z   zugeordnete BLZ (5-stellig bei fiktiver BLZ, sonst 5 Blanks)    #
 * #    %%   das % Zeichen selbst                                            #
 * #                                                                         #
 * #    \n   Zeilenvorschub                                                  #
 * #    \r   CR (für M$DOS)                                                  #
 * #    \t   Tabulatorzeichen                                                #
 * #    \\   ein \                                                           #
 * #                                                                         #
 * # @i (bzw. @b) muß am Anfang des Formatstrings stehen; falls keine        #
 * # Sortierung angegeben wird, wird @b benutzt.                             #
 * #                                                                         #
 * # Nicht definierte Felder und Escape-Sequenzen werden (zumindest momentan #
 * # noch) direkt in die Ausgabedatei übernommen. D.h., wenn man %x schreibt,#
 * # erscheint in der Ausgabedatei auch ein %x, ohne daß ein Fehler gemeldet #
 * # wird. Ob dies ein Bug oder Feature ist, sei dahingestellt; momentan     #
 * # scheint es eher ein Feature zu sein ;-))).                              #
 * #                                                                         #
 * # Falls kein plain_format angegeben wird, wird DEFAULT_PLAIN_FORMAT       #
 * # benutzt (aus konto_check_at.h, mit "@B%I %B %t %N"). Die Datei ist      #
 * # (anders als die INPAR-Datei) nach Bankleitzahlen sortiert.              #
 * #                                                                         #
 * # Copyright (C) 2006-2008 Michael Plugge <m.plugge@hs-mannheim.de>        #
 * ###########################################################################
 */

/* Vorspann  +§§§2 */
DLL_EXPORT int generate_lut_at(char *inputname,char *outputname,char *plain_name,char *plain_format)
{
   int i,j,k,idx,t_idx,ident1=0,ident2,last_blz,last_table,ld,show_all,sort_mode,file_version;
   int *table_idx;
   UINT4 adler;
   long adler_pos;
   unsigned char *uptr,*eptr;
   FILE *in,*out,*plain;

      /* (hier noch der alte Kommentar, nun allerdings obsolet)
       * die folgenden Variablen werden als static allokiert, da sie (bei
       * MAX_BLZ_CNT_AT=30000) etwa 3,5 MB benötigen; unter Windows tritt dann
       * ein Stacküberlauf, das Programm verabschiedet sich einfach mit einer
       * Schreibschutzverletzung (bei Linux gibt es kein Problem). Windog$ will
       * dann einen Problembericht nach Redmond senden, auf daß die nach dem
       * Rechten sehen; die haben sich allerdings auch früher noch nie bei mir
       * gemeldet und etwas Konstruktives beigetragen ;-))) . 
       *
       * Die alte Unterscheidung zwischen den Namensbestandteilen wird
       * fallengelassen, da bei der neuen Dateiversion nur noch ein Namensteil
       * vorkommt. Die Variablen bankname1, bankname2 und bankname3 werden auf
       * Leerstrings gesetzt, der komplette Name kommt nach bankname. Da die
       * Variablen nur in dieser Funktion benutzt werden, ist das kein großer
       * Verlust; bei der Ausgabe wird nur noch der komplette Name unterstützt
       * (bei %n, %n1 oder %N). Die Allokierung erfolgt jetzt dynamisch,
       * allerdings noch mit festen Arraygrößen (kann in konto_check-at.h
       * bei Bedarf geändert werden).
       */
   char *ptr,*dptr,*pptr,*buffer,buffer2[64],kopf_parameter[64],fiktiv[MAX_BLZ_CNT_AT],
        *bankname[MAX_BLZ_CNT_AT],*namebuffer,*nameptr;

   if(!inputname || !*inputname)inputname="inporwo.txt";
   if(!outputname || !*outputname)outputname=DEFAULT_LUT_NAME_AT;
   if(!(in=fopen(inputname,"r")))return NO_BLZ_FILE;
   if(!(out=fopen(outputname,"wb")))return FILE_WRITE_ERROR;
   if(plain_name && *plain_name){
      if(!(plain=fopen(plain_name,"w")))return FILE_WRITE_ERROR;
   }
   else
      plain=NULL;
   if(!(nameptr=namebuffer=malloc(MAX_BLZ_CNT_AT*256))
         || !(table_idx=calloc(99999,sizeof(int)))
         || !(buffer=malloc(65737)))return ERROR_MALLOC;
   if(!plain_format || !strlen(plain_format))plain_format=DEFAULT_PLAIN_FORMAT;
   if(*plain_format=='@'){
      switch(*(plain_format+1)){
         case 'i':   /* Sortierung nach Identnummern; nur gültige Bankleitzahlen ausgeben */
            sort_mode='i';
            show_all=0;
            break;
         case 'I':   /* Sortierung nach Identnummern; alle Bankleitzahlen ausgeben */
            sort_mode='i';
            show_all=1;
            break;
         case 'b':   /* Sortierung nach Bankleitzahlen; nur gültige ausgeben */
            sort_mode='b';
            show_all=0;
            break;
         case 'B':   /* Sortierung nach Bankleitzahlen; alle ausgeben */
            sort_mode='b';
            show_all=1;
            break;
         default: /* Format nicht definiert, default nehmen */
            fprintf(stderr,"invalid output format @%c; ignored\n",*(plain_format+1));
            sort_mode='b';
            show_all=0;
      }
      plain_format+=2; /* Sortierformat nicht ausgeben */
   }
   else{
      sort_mode='b';
      show_all=0;
   }

      /* Eingabedatei lesen +§§§2 */
   strcpy((char *)tabelle[0],"0000000");
   for(i=0;i<MAX_TABLE_CNT_AT;i++)table_idx[i]=0;
   for(file_version=idx=t_idx=0;idx<MAX_BLZ_CNT_AT;){
      if(!fgets(buffer,4096,in) || feof(in))break;
      if(*buffer=='0')switch(*(buffer+1)){
         case '0':   /* Kopfsatz */
            if(!strncmp(buffer,"00INPAR100",10))file_version=1; /* altes Dateiformat */
            if(!strncmp(buffer,"00INPAR200",10))file_version=2; /* neues Dateiformat (ab Februar 2008) */
            if(!file_version){   /* unbekannte/ungültige INPAR-Datei */
               fprintf(stderr,"keine gültige INPAR-Datei; Abbruch\n");
               free(namebuffer);
               free(table_idx);
               free(buffer);
               return INVALID_BLZ_FILE;
            }
            if(*(buffer+18)!='G'){   /* Dateityp (Gesamt-/Änderungsbestand prüfen */
               fprintf(stderr,"es werden nur Dateien mit dem Gesamtbestand unterstützt; Abbruch\n");
               free(namebuffer);
               free(table_idx);
               free(buffer);
               return INVALID_BLZ_FILE;
            }
            for(i=0,ptr=buffer+10;i<9;i++)kopf_parameter[i]=*ptr++;
            kopf_parameter[9]=0;
            break;
         case '1':   /* Stammsatz Teil 1 */
            if(file_version==1){ /* altes Dateiformat */
               EXTRACT_NUM(ident1,3,7);  /* Identnummer merken für Konsistenztest */
               ident[idx]=ident1;
               EXTRACT_NUM(blz[idx],11,5);
               EXTRACT(bankname[idx]=nameptr,16,40);
               for(dptr--;*dptr==' ';dptr--);   /* trailing blanks entfernen */
               if(*dptr!='-')*++dptr=' ';      /* Sonderfall, kein Blank als Trenner zwischen Namensteilen */
               nameptr=++dptr;
               EXTRACT(nameptr,56,40);
               for(dptr--;*dptr==' ';dptr--);   /* nochmal dasselbe Spiel wie oben für den zweiten Teil des Namens */
               if(*dptr!='-')*++dptr=' ';
               nameptr=++dptr;
               EXTRACT_1(hauptstelle[idx],110);
            }
            else if(file_version==2){  /* neues Dateiformat; die Stammdaten sind komplett in einer Zeile mit Kennung 01 */
               EXTRACT_NUM(ident[idx],3,8);
               EXTRACT_NUM(blz[idx],11,5);
               EXTRACT(bankname[idx]=nameptr,16,255);
               for(dptr--;*dptr==' ';dptr--);   /* trailing blanks entfernen */
               *++dptr=0;
               nameptr=++dptr;
               EXTRACT_NUM(loesch_datum_num[idx],2355,8);
               EXTRACT_1(hauptstelle[idx],2377);
               EXTRACT_1(fiktiv[idx],2407);
               EXTRACT_NUM(pruef_tabelle[idx],2408,5);
               if(fiktiv[idx]=='A' || fiktiv[idx]=='F'){
                  EXTRACT_NUM(blz2[idx],2402,5);
               }
               else
                  blz2[idx]=0;
               idx++;

            }
            break;
         case '2':
            EXTRACT(nameptr,10,40);
            for(dptr--;*dptr==' ';dptr--);   /* und noch einmal für den dritten Teil */
            *++dptr=0;
            break;
         case '3':
            break;   /* Stammsatz 3: momentan nicht benutzt */
         case '4':
            break;   /* Stammsatz 4: momentan nicht benutzt */
         case '5':   /* Stammsatz Teil 5 */
            EXTRACT_NUM(ident2,3,7);  /* neue Identnummer holen und mit indent1 vergleichen */
            if(ident2!=ident1){
               fprintf(stderr,"Verschiedene Idents in Feld 1 und 5: %dd/%d\n   (BLZ %d, Bankname %s)\n",
                     ident1,ident2,blz[idx],bankname[idx]);
               continue;
            }
            EXTRACT_NUM(loesch_datum_num[idx],18,8);
            EXTRACT_NUM(pruef_tabelle[idx],106,5);
            EXTRACT_1(fiktiv[idx],34);
            if(fiktiv[idx]=='A' || fiktiv[idx]=='F'){
               EXTRACT_NUM(blz2[idx],29,5);
            }
            else
               blz2[idx]=0;
            idx++;
            break;
         default:
            break;
      }
      else if(*buffer=='1' && *(buffer+1)=='0'){   /* Prüftabelle */
         if(file_version==1){ /* altes Dateiformat */
            t_idx++;
            EXTRACT_NUM(tabelle_name[t_idx],3,5);
            table_idx[tabelle_name[t_idx]]=t_idx;
            EXTRACT((char *)tabelle[t_idx],9,64);
            for(ptr=(char *)tabelle[t_idx]+63;*ptr==' ';ptr--)*ptr=0;
         }
         else if(file_version==2){ /* neues Dateiformat */
            t_idx++;
            EXTRACT_NUM(tabelle_name[t_idx],3,5);
            table_idx[tabelle_name[t_idx]]=t_idx;
            EXTRACT((char *)tabelle[t_idx],9,70); /* es sind bis zu 10 Prüfverfahren möglich */
            for(ptr=(char *)tabelle[t_idx]+69;*ptr==' ';ptr--)*ptr=0;
         }
      }
   }
   for(i=0;i<idx;i++)blz_idx[i]=i;
   qsort(blz_idx,idx,sizeof(int),cmp_blz);
   blz_anzahl=idx;

#define ADLER_FPRINTF fprintf(out,"%s",buffer); adler=adler32(adler,(signed char *)buffer,strlen(buffer)); x_sz+=strlen(buffer)
{  int x_sz=0;

      /* Ausgabedatei schreiben: Kopfdaten (beide Dateiformate) +§§§2 */
   adler=adler32(0,NULL,0);
   for(ptr=kopf_parameter,i=0,dptr=buffer2;i<8;i++)*dptr++=*ptr++;
   *dptr++=0;
   i=atoi(buffer2);  /* Bestandsdatum aus den Kopfdaten holen */
   sprintf(buffer,"BLZ Lookup Table/Format 1.0 AT\nLUT-Datei generiert aus %sbestand vom %02d.%02d.%d\n"
         "Anzahl Kontoprüfparameter-Tabellen: %d\nCRC: 0x00000000\n\n",
      *(kopf_parameter+8)=='G'?"Gesamt":"Änderungs",i%100,(i/100)%100,i/10000,t_idx);
   ADLER_FPRINTF;
   adler_pos=ftell(out)-10;   /* Position von CRC-Feld merken für späteres Schreiben */
   for(i=1;i<=t_idx;i++){
      sprintf(buffer,"T%05d %s\n",tabelle_name[i],tabelle[i]);
      ADLER_FPRINTF;
   }
   sprintf(buffer,"-------------\n");
   ADLER_FPRINTF;

   if(plain){
      i=atoi(buffer2);  /* Bestandsdatum nochmal holen */
      fprintf(plain,"BLZ-Tabelle AT/plain\nDie Datei wurde generiert aus dem %sbestand vom %02d.%02d.%d\n"
            "Anzahl Kontoprüfparameter-Tabellen: %d (T0 wird nicht mitgezählt)\n",
            *(kopf_parameter+8)=='G'?"Gesamt":"Änderungs",i%100,(i/100)%100,i/10000,t_idx);
      ptr="+----------------------------------------------------+";
      fprintf(plain,"\n%s\n|          Liste der Prüfparameter-Tabellen          |\n%s\n\n",ptr,ptr);
      for(i=0;i<=t_idx;i++)fprintf(plain,"[%3d] T%05d %s\n",i,tabelle_name[i],tabelle[i]);
      fprintf(plain,"\n%s\n|                  Liste der Banken                  |\n",ptr);
      if(show_all)fprintf(plain,"|                                                    |\n"
            "|   Bedeutung der ersten Spalte:                     |\n"
            "| + Die Zeile wird in blz-at.lut aufgenommen         |\n"
            "| - Die Zeile wird nicht in blz-at.lut aufgenommen   |\n");
      fprintf(plain,"%s\n\n",ptr);
   }

fprintf(stderr,"x_sz0: %d\n",x_sz);
      /* Ausgabedatei schreiben: Bankdaten (Binärdatei) +§§§2 */
   eptr=UCP buffer+65536;
   uptr=UCP buffer;
   for(i=0,last_blz=last_table=-1;i<idx;i++){
if(!((i+1)%50))fprintf(stderr,"x_sz1: %d\n",(int)((uptr-(unsigned char*)buffer)+1));
      j=blz_idx[i];
      if(blz[j]!=last_blz || pruef_tabelle[j]!=last_table){
         UM2C(blz[j]);
         if((ld=loesch_datum_num[j])){
            *uptr++=0xff;

               /* das Löschdatum wird etwas reduziert, damit es in drei Byte
                * dargestellt werden kann; so belegen alle Einträge in der
                * blz-at.lut Datei genau 4 Byte, und eventuelle Fehler wirken
                * sich nur lokal aus. Falls das Löschdatum mit 4 Byte
                * geschrieben würde, hätte der entsprechende Eintrag mit der
                * Prüftabelle 5 Byte; ein Fehler in der Datei hätte dann
                * aufgrund fehlender Synchronisation u.U. verheerende Folgen
                * für den ganzen Rest der Datei.
                */

               /* Problem: fiktive BLZ + gelöscht => zugeordnete Prüftabelle suchen+eintragen?? */

            if(ld==11111111)
               ld=1; /* Dummy-Löschdatum, kommt aber einige mal vor... */
            else
               ld-=19000000;
            UM2C(ld);
            *uptr++=UC table_idx[pruef_tabelle[j]];
         }
         else if(fiktiv[j]!=' ' && !pruef_tabelle[j]){
            *uptr++=0xfe;     /* Kennbyte fiktive BLZ */
            UM2C(blz2[j]);    /* zugeordnete BLZ eintragen */
            k=search_blz_idx(blz2[j]);
            if(k>=0)
                 /* zugeordnete Prüftabelle (muß die für den Test benutzt werden???) */
               *uptr++=UC table_idx[pruef_tabelle[k]];
            else
               *uptr++=0;
         }
         else
            *uptr++=UC table_idx[pruef_tabelle[j]];   /* normale Prüftabelle eintragen */
         last_blz=blz[j];
         last_table=pruef_tabelle[j];
         if(uptr>eptr){
            fwrite(buffer,1,(uptr-(unsigned char *)buffer)+1,out);
            adler=adler32(adler,(signed char *)buffer,(uptr-(unsigned char *)buffer)+1);
fprintf(stderr,"x_sz1: %d\n",x_sz);
x_sz+=(int)(uptr-(unsigned char*)buffer)+1;
fprintf(stderr,"x_sz2: %d\n",x_sz);
            uptr=UCP buffer;
         }
      }
   }
fprintf(stderr,"x_sz2: %d\n",(int)((uptr-(unsigned char*)buffer)+1));
   fwrite(buffer,1,(uptr-(unsigned char *)buffer)+1,out);
fprintf(stderr,"x_sz3: %d\n",(int)((uptr-(unsigned char*)buffer)+1));
   adler=adler32(adler,(signed char *)buffer,(uptr-(unsigned char *)buffer)+1);
fprintf(stderr,"x_sz4: %d\n",(int)((uptr-(unsigned char*)buffer)+1));
fprintf(stderr,"x_sz3: %d / %d\n",x_sz,(int)(uptr-(unsigned char*)buffer)+1);
x_sz+=(int)(uptr-(unsigned char*)buffer)+1;
fprintf(stderr,"x_sz4: %d\n",x_sz);
   fseek(out,adler_pos,SEEK_SET);
   fprintf(out,"%08lx\n",(unsigned long)adler);
fprintf(stderr,"adler gen: %08x, sz: %d\n",adler,x_sz);
   fclose(in);
   fclose(out);
}

      /* Ausgabedatei schreiben: Bankdaten (Plaindatei) +§§§2 */
   if(plain){
      for(i=0,last_blz=last_table=-1;i<idx;i++){
         if(sort_mode=='i')
            j=i;
         else
            j=blz_idx[i];
         if(blz[j]!=last_blz || pruef_tabelle[j]!=last_table || show_all){
            if(show_all){
               if(blz[j]!=last_blz || pruef_tabelle[j]!=last_table)
                  fprintf(plain,"+ ");
               else
                  fprintf(plain,"- ");
            }
            last_blz=blz[j];
            last_table=pruef_tabelle[j];
            if(sort_mode=='i')j=i;  /* für Sortierreihenfolge nach Identnummern */
            for(pptr=plain_format;*pptr;pptr++){
               if(*pptr=='%' && *(pptr+1)){
                  switch(*++pptr){
                     case 'b':   /* BLZ */
                        fprintf(plain,"%d",blz[j]);
                        break;
                     case 'B':   /* BLZ (5-stellig) */
                        fprintf(plain,"%05d",blz[j]);
                        break;
                     case 'f':   /* fiktive Bankleitzahl */
                        fprintf(plain,"%c",fiktiv[j]);
                        break;
                     case 'h':   /* Hauptstelle/Zweigstelle */
                        fprintf(plain,"%c",hauptstelle[j]);
                        break;
                     case 'i':   /* ident */
                        fprintf(plain,"%d",ident[j]);
                        break;
                     case 'I':   /* ident (8-stellig) */
                        fprintf(plain,"%8d",ident[j]);
                        break;
                     case 'l':   /* Löschdatum */
                        ld=loesch_datum_num[j];
                        if(ld>0)fprintf(plain,"%02d.%02d.%d",ld%100,(ld/100)%100,ld/10000);
                        break;
                     case 'L':   /* Löschdatum oder 10 Blanks, falls nicht gelöscht */
                        ld=loesch_datum_num[j];
                        if(ld>0)
                           fprintf(plain,"%02d.%02d.%d",ld%100,(ld/100)%100,ld/10000);
                        else
                           fprintf(plain,"          ");
                        break;
                     case 'n':   /* Bankname Teil 1...3 (einzeln) */
                        switch(*++pptr){
                           case '1':   /* war vorher erster Teil des Banknamens, jetzt für kompletten Namen */
                              fprintf(plain,"%s",bankname[j]);
                              break;
                           case '2':
                                 /* war vorher zweiter Teil des Namens; ignorieren */
                              break;
                           case '3':
                                 /* war vorher dritter Teil des Namens; ebenfalls ignorieren */
                              break;
                           default:
                              fprintf(plain,"%s",bankname[j]); /* wurde vorher direkt übernommen; jetzt auch Bankname */
                              fputc(*pptr,plain);  /* das nächste Zeichen ausgeben */
                              break;
                        }
                        break;

                     case 'N':   /* Bankname (komplett, Teil 1-3 zusammen; jetzt äquivalent zu %n und %n1) */
                        fprintf(plain,"%s",bankname[j]);
                        break;
                     case 'p':   /* Kontoprüfparameter */
                        fprintf(plain,"%s",tabelle[table_idx[pruef_tabelle[j]]]);
                        break;
                     case 't':   /* Name der Prüftabelle */
                        fprintf(plain,"%05d",pruef_tabelle[j]);
                        break;
                     case 'z':   /* zugeordnete BLZ (nur bei fiktiver BLZ) */
                        if(fiktiv[j]!=' ')fprintf(plain,"%d",blz2[j]);
                        break;
                     case 'Z':   /* zugeordnete BLZ (5-stellig) oder Blanks */
                        if(fiktiv[j]!=' ')
                           fprintf(plain,"%5d",blz2[j]);
                        else
                           fprintf(plain,"     ");
                        break;
                     case '%':
                        fputc('%',plain);
                        break;
                     default:
                        fputc('%',plain);
                        fputc(*pptr,plain);
                        break;
                  }
               }
               else if(*pptr=='\\' && *(pptr+1)){
                  switch(*++pptr){
                     case 'n':
                        fputc('\n',plain);
                        break;
                     case '\\':
                        fputc('\\',plain);
                        break;
                     case 'r':
                        fputc('\r',plain);
                        break;
                     case 't':
                        fputc('\t',plain);
                        break;
                     default:
                        fputc('\\',plain);
                        fputc(*pptr,plain);
                        break;
                  }
               }
               else
                  fputc(*pptr,plain);
            }
            fputc('\n',plain);
         }
      }
      fclose(plain);
   }
   free(namebuffer);
   free(table_idx);
   free(buffer);
   return OK;
}

/* Funktion read_lut()  +§§§1 */

/* #################################################################
 * # read_lut: die lut-Datei einlesen und in die Arrays eintragen. #
 * #################################################################
 */

static int read_lut(char *lut_name)
{
   char *ptr,*dptr,*buffer;
   unsigned char *uptr,*eptr;
   int i,j,idx,size,cnt,ld,bankleitzahl;
   UINT4 adler,adler_file;
   struct stat sbuf;
   FILE *in;

      /* nachsehen, ob es die angegebene Datei gibt; falls ja, Buffer allokieren
       * und die Datei komplett einlesen.
       */
   if(stat(lut_name,&sbuf))return NO_LUT_FILE;
   size=sbuf.st_size;
   buffer=malloc(size+1024);
   if(!(in=fopen(lut_name,"rb")))return FILE_READ_ERROR;
   cnt=fread(buffer,1,size,in);  /* Datei in einem Rutsch einlesen (ist nicht sehr groß) */
   eptr=UCP (buffer+cnt);
   fclose(in);

      /* die Prüftabellen mit Leerzeichen auffüllen und terminieren */
   for(i=0;i<MAX_TABLE_CNT_AT;i++){
      for(j=0;j<64;j++)tabelle[i][j]=' ';
      tabelle[i][64]=0;
   }

      /* Signatur testen */
   if(strncmp(buffer,"BLZ Lookup Table/Format 1.0 AT",30))return INVALID_LUT_FILE;

      /* Felder im Klartextteil auswerten */
   for(ptr=buffer,i=0;i<3;)if(*ptr++=='\n')i++; /* Zeilen überspringen bis CRC */
   if(strncmp(ptr,"CRC: ",4))while(*ptr++!='\n'); /* evl. noch eine Zeilen überspringen */
   if(strncmp(ptr,"CRC: ",4))
      return INVALID_LUT_FILE;
   else{
      sscanf(ptr+4,"%x",&adler_file);  /* Prüfsumme aus der Datei lesen */
      if(adler_file){

            /* für die Berechnung muß die Prüfsumme in buffer auf 0 gesetzt werden */
         for(dptr=ptr+7,i=0;i<8;i++)*dptr++='0';
         adler=adler32(0,NULL,0);
         adler=adler32(adler,(signed char *)buffer,size);
fprintf(stderr,"size: %d, buflen: %d,adler: %08x, adler-file: %08x\n",size,strlen(buffer),adler,adler_file);
         if(adler!=adler_file)return LUT_CRC_ERROR;
      }
   }

      /* noch zwei Zeilen überspringen bis zum Anfang Prüfparameter-Tabellen */
   for(i=0;i<2;)if(*ptr++=='\n')i++;
   for(idx=1;;){
      if(*ptr=='T'){ /* eine Tabelle einlesen */
         for(dptr=(char *)tabelle[idx];(*dptr= *++ptr)!='\n';dptr++)
            if(*dptr==' ')*dptr=0;  /* Tabellennamen nullterminieren */
         *dptr=0;
         idx++;
      }
      else if(!strncmp(ptr,"-------------",13)){
         while(*ptr++!='\n'); /* Zeile überspringen */
         break;   /* nun beginnt die Tabelle mit den Bankleitzahlen und Prüfmethoden */
      }
      else  /* sollte eigentlich nicht vorkommen */
         ptr++;
   }
   adler=adler32(0,NULL,0);
   adler=adler32(adler,(signed char *)buffer,(ptr-buffer));

      /* Arrays mit den Prüfmethoden und Löschflags initialisieren */
   memset(blz_tabelle,-1,100000);
   memset(geloeschte_blz,0,100000);

      /* nun die Tabellen lesen und eintragen */
   for(idx=0,uptr=UCP ptr;uptr<eptr;idx++){
      bankleitzahl=blz[idx]=C2UM;
      if(bankleitzahl>=100000){
           /* bei der Testdatei trat ein an dieser Stelle ein Fehler auf (mit
            * anschließendem core dump); Bankleitzahlen>100000 sind in jedem
            * Fall falsch.
            */
         idx--;
         continue;
      }
      switch(j= *uptr++){
         case 0xff:  /* gelöschte BLZ */
            j=C2UM;
            geloeschte_blz[bankleitzahl]=1;
            if(!j)
               loesch_datum[idx][0]=0;
            else if(j==1)
               strcpy((char *)loesch_datum[idx],"11.11.1111");
            else{
               ld=j+19000000;
               sprintf((char *)loesch_datum[idx],"%02d.%02d.%04d",ld%100,(ld/100)%100,ld/10000);
            }
            blz_tabelle[bankleitzahl]=pruef_tabelle[idx]= *uptr++;
            break;

         case 0xfe:  /* fiktive BLZ */
            uptr+=3; /* zugeordnete BLZ (momentan) überspringen */
            blz_tabelle[bankleitzahl]=pruef_tabelle[idx]= *uptr++;
            break;

         default:
            blz_tabelle[bankleitzahl]=pruef_tabelle[idx]=j;
            break;
      }
   }
   if(!blz[idx-1])idx--;   /* Anzahl korrigieren */
   for(i=0,dptr=(char *)tabelle[0];i<13;i++)*dptr++='0';
   for(i=0;i<MAX_TABLE_CNT_AT;i++){
      tabelle[i][5]=0;
      for(ptr=(char *)&tabelle[i][63];*ptr==' ';)*ptr=0;
   }
   blz_anzahl=idx;
   free(buffer);
   return OK;
}

/* Funktion dump_lutfile_at()  +§§§1 */
/* ###############################################################################
 * # dump_lutfile_at: Inhalt einer .lut-Datei als Klartextdatei ausgeben         #
 * ###############################################################################
 */

DLL_EXPORT int dump_lutfile_at(char *inputname, char *outputname)
{
   int i,retval;
   FILE *out;

   if(global_vars_initialized!=E_L && (retval=read_lut(inputname))!=OK)return retval;
   if(!(out=fopen(outputname,"w")))return FILE_WRITE_ERROR;
   fprintf(out," BLZ  Löschdatum Prüftabelle/-parameter\n---------------------------------------\n\n");
   for(i=0;i<blz_anzahl;i++){
      fprintf(out,"%5d %10s T%s %s\n",
            blz[i],loesch_datum[i][0]?(char *)loesch_datum[i]:"",tabelle[pruef_tabelle[i]],
            tabelle[pruef_tabelle[i]]+6);
   }
   fclose(out);
   return OK;
}

/* Funktion search_blz()  +§§§1 */
/* ###############################################################################
 * # search_blz: Index einer bestimmten Bankleitzahl suchen.                     #
 * #                                                                             #
 * # Die Funktion wird benutzt, um den Index einer Bankleitzahl zu finden. Die   #
 * # Implementierung setzt voraus, daß das Array bereits sortiert wurde (binäre  #
 * # Suche; dies wird beim Schreiben der LUT-Datei erledigt). Die Funktion wird  #
 * # für den normalen Test aus Geschwindigkeitsgründen nicht benutzt, sondern    #
 * # nur, um das Löschdatum zu bestimmen. Für den Test eines Kontos wird         #
 * # stattdessen das Array blz_tabelle genommen.                                 #
 * #                                                                             #
 * # Rückgabe: Index der BLZ oder -1, falls nicht gefunden.                      #
 * ###############################################################################
 */

static int search_blz(int such_blz)
{
   int unten,oben,chk,b1=0,diff;

   for(unten=0,oben=blz_anzahl,chk=oben/2;oben!=unten;){
      if((b1=blz[chk])<such_blz){
         unten=chk;
         if((diff=oben-chk)==1){
            b1=blz[oben];
            break;
         }
         else
            chk+=diff/2;
      }
      else if(b1==such_blz)
         break;
      else{
         oben=chk;
         if((diff=chk-unten)==1){
            b1=blz[unten];
            break;
         }
         else
            chk-=diff/2;
      }
   }
   if(b1==such_blz)
      return chk;
   else
      return -1;
}

/* Funktion init_globals()  +§§§1 */
/* #################################################################
 * # init_globals(): Initialisierung von globalen Variablen,       #
 * # Einlesen der LUT-Datei.                                       #
 * #################################################################
 */                  

static int init_globals(char *lut_name)
{
   int i,retval;
   FILE *tmp;


      /* Die Variable init_in_progress dient als Quasi-Semaphore für die
       * threadfeste Version (ohne den Overhead einer richtigen Semaphoren, da
       * das hier wohl ein Overkill wäre ;-)
       */
   if(lut_name){
      if(init_in_progress){

            /* ein anderer thread initialisiert gerade; Warteschleife einlegen,
             * bis die Initialisierung fertig ist...
             */
         for(i=0;init_in_progress && i++<10000;){
            tmp=tmpfile();
            fprintf(tmp,"%s","noch etwas warten...");
            fclose(tmp);
         }
      }
         /* nochmal nachsehen; falls etwas schiefgelaufen ist, Initialisierung
          * selbst versuchen.
          */
      if(global_vars_initialized!=E_L && !init_in_progress){
         init_in_progress++;
         if((retval=read_lut(lut_name))!=OK)return retval;

            /* Flag setzen, daß die globalen Variablen initialisiert sind */
         global_vars_initialized=E_L;

            /* Falls ein zweiter thread gleichzeitig die Initialisierung startete
             * (race condition, sollte normal nicht vorkommen), hier eine kleine
             * Warteschleife einlegen...
             * Für Windows ist usleep nicht definiert; es gibt zwar Sleep()
             * (warten im Millisekunden-Berich), aber der Mingw Crosscompiler
             * (Linker) findet die Funktion nicht. Daher wird hier für die
             * Warteschleife die Funktion tmpfile() und fprintf benutzt.
             */
         if(--init_in_progress>0)for(i=0;init_in_progress && i++<1000;){
            tmp=tmpfile();
            fprintf(tmp,"%s","noch etwas warten...");
            fclose(tmp);
         }
      }
      else{
            /* ein anderer thread initialisiert gerade; Warteschleife einlegen,
             * bis die Initialisierung fertig ist...
             */
         for(i=0;init_in_progress && i++<10000;){
            tmp=tmpfile();
            fprintf(tmp,"%s","noch etwas warten...");
            fclose(tmp);
         }
      }
   }
   else
         /* kein lut-Name, mit eigenen Prüfparametern arbeiten;
          * global_vars_initialized ist hier nicht gesetzt, damit bei einem
          * Test mit Bankleitzahlen die Library neu initialisiert wird
          * (**mit** der lut-Datei).
          */
      return OK;
   if(global_vars_initialized==E_L)
      return OK;
   else
      return LIBRARY_INIT_ERROR;
}

/* Funktion get_loesch_datum()  +§§§2 */
DLL_EXPORT const char *get_loesch_datum(char *blz1)
{
   return (char *)loesch_datum[search_blz(atoi(blz1))];
}

#ifndef INCLUDE_KONTO_CHECK_DE
/* Funktion kto_check_retval2txt() +§§§1 */
/* ###########################################################################
 * # Die Funktion gibt eine Klartext-Fehlermeldung zur Variablen retval      #
 * # zurück. Es werden alle Rückgabewerte von konto_check-at und konto_check #
 * # berücksichtigt, nicht nur die in konto_check-at benutzten.              #
 * #                                                                         #
 * # Copyright (C) 2006 Michael Plugge <m.plugge@hs-mannheim.de>             #
 * ###########################################################################
 */

DLL_EXPORT const char *kto_check_retval2txt(int retval)
{
   switch(retval){
      case UNDEFINED_SUBMETHOD:
         return "Die Untermethode ist nicht definiert";

      case EXCLUDED_AT_COMPILETIME:
         return "Die Funktion wurde beim Kompilieren ausgeschlossen";

      case INVALID_LUT_VERSION:
         return "Die Versionsnummer für die LUT-Datei ist ungültig";

      case INVALID_PARAMETER_STELLE1:
         return "ungültiger Prüfparameter (erste zu prüfende Stelle)";

      case INVALID_PARAMETER_COUNT:
         return "ungültiger Prüfparameter (Anzahl zu prüfender Stellen)";

      case INVALID_PARAMETER_PRUEFZIFFER:
         return "ungültiger Prüfparameter (Position der Prüfziffer)";

      case INVALID_PARAMETER_WICHTUNG:
         return "ungültiger Prüfparameter (Wichtung)";

      case INVALID_PARAMETER_METHODE:
         return "ungültiger Prüfparameter (Rechenmethode)";

      case LIBRARY_INIT_ERROR:
         return "Problem beim Initialisieren der globalen Variablen";

      case LUT_CRC_ERROR:
         return "Prüfsummenfehler in der blz.lut Datei";

      case FALSE_GELOESCHT:
         return "falsch (die BLZ wurde außerdem gelöscht)";

      case OK_NO_CHK_GELOESCHT:
         return "ok, ohne Prüfung (die BLZ wurde allerdings gelöscht)";

      case OK_GELOESCHT:
         return "ok (die BLZ wurde allerdings gelöscht)";

      case BLZ_GELOESCHT:
         return "die Bankleitzahl wurde gelöscht";

      case INVALID_BLZ_FILE:
         return "Fehler in der blz.txt Datei (falsche Zeilenlänge)";

      case LIBRARY_IS_NOT_THREAD_SAFE:
         return "undefinierte Funktion; die library wurde mit THREAD_SAFE=0 kompiliert";

      case FATAL_ERROR:
         return "schwerer Fehler im Konto-Modul";

      case INVALID_KTO_LENGTH:
         return "ein Konto muß zwischen 1 und 10 Stellen haben";

      case FILE_WRITE_ERROR:
         return "kann Datei nicht schreiben";

      case FILE_READ_ERROR:
         return "kann Datei nicht lesen";

      case ERROR_MALLOC:
         return "kann keinen Speicher allokieren";

      case NO_BLZ_FILE:
         return "die Datei mit den Bankleitzahlen wurde nicht gefunden";

      case INVALID_LUT_FILE:
         return "die blz.lut Datei ist inkosistent/ungültig";

      case NO_LUT_FILE:
         return "die blz.lut Datei wurde nicht gefunden";

      case INVALID_BLZ_LENGTH:
         return "die Bankleitzahl ist nicht achtstellig";

      case INVALID_BLZ:
         return "die Bankleitzahl ist ungültig";

      case INVALID_KTO:
         return "das Konto ist ungültig";

      case NOT_IMPLEMENTED:
         return "die Methode wurde noch nicht implementiert";

      case NOT_DEFINED:
         return "die Methode ist nicht definiert";

      case FALSE:
         return "falsch";

      case OK:
         return "ok";

      case OK_NO_CHK:
         return "ok, ohne Prüfung";

      default: 
         return "ungültiger Rückgabewert";

   }
}

/* Funktion kto_check_retval2html() +§§§1 */
/* ###########################################################################
 * # Die Funktion gibt eine Klartext-Fehlermeldung zur Variablen retval      #
 * # zurück. Es werden alle Rückgabewerte von konto_check-at und konto_check #
 * # berücksichtigt, nicht nur die in konto_check-at benutzten. Für Umlaute  #
 * # werden HTML-Tags benutzt.                                               #
 * #                                                                         #
 * # Copyright (C) 2006 Michael Plugge <m.plugge@hs-mannheim.de>             #
 * ###########################################################################
 */

DLL_EXPORT const char *kto_check_retval2html(int retval)
{
   switch(retval){
      case UNDEFINED_SUBMETHOD:
         return "Die Untermethode ist nicht definiert";

      case EXCLUDED_AT_COMPILETIME:
         return "Die Funktion wurde beim Kompilieren ausgeschlossen";

      case INVALID_LUT_VERSION:
         return "Die Versionsnummer f&uuml;r die LUT-Datei ist ung&uuml;ltig";

      case INVALID_PARAMETER_STELLE1:
         return "ung&uuml;ltiger Pr&uuml;fparameter (erste zu pr&uuml;fende Stelle)";

      case INVALID_PARAMETER_COUNT:
         return "ung&uuml;ltiger Pr&uuml;fparameter (Anzahl zu pr&uuml;fender Stellen)";

      case INVALID_PARAMETER_PRUEFZIFFER:
         return "ung&uuml;ltiger Pr&uuml;fparameter (Position der Pr&uuml;fziffer)";

      case INVALID_PARAMETER_WICHTUNG:
         return "ung&uuml;ltiger Pr&uuml;fparameter (Wichtung)";

      case INVALID_PARAMETER_METHODE:
         return "ung&uuml;ltiger Pr&uuml;fparameter (Rechenmethode)";

      case LIBRARY_INIT_ERROR:
         return "Problem beim Initialisieren der globalen Variablen";

      case LUT_CRC_ERROR:
         return "Pr&uuml;fsummenfehler in der blz.lut Datei";

      case FALSE_GELOESCHT:
         return "falsch (die BLZ wurde au&szlig;erdem gel&ouml;scht)";

      case OK_NO_CHK_GELOESCHT:
         return "ok, ohne Pr&uuml;fung (die BLZ wurde allerdings gel&ouml;scht)";

      case OK_GELOESCHT:
         return "ok (die BLZ wurde allerdings gel&ouml;scht)";

      case BLZ_GELOESCHT:
         return "die Bankleitzahl wurde gel&ouml;scht";

      case INVALID_BLZ_FILE:
         return "Fehler in der blz.txt Datei (falsche Zeilenl&auml;nge)";

      case LIBRARY_IS_NOT_THREAD_SAFE:
         return "undefinierte Funktion; die library wurde mit THREAD_SAFE=0 kompiliert";

      case FATAL_ERROR:
         return "schwerer Fehler im Konto-Modul";

      case INVALID_KTO_LENGTH:
         return "ein Konto mu&szlig; zwischen 1 und 10 Stellen haben";

      case FILE_WRITE_ERROR:
         return "kann Datei nicht schreiben";

      case FILE_READ_ERROR:
         return "kann Datei nicht lesen";

      case ERROR_MALLOC:
         return "kann keinen Speicher allokieren";

      case NO_BLZ_FILE:
         return "die Datei mit den Bankleitzahlen wurde nicht gefunden";

      case INVALID_LUT_FILE:
         return "die blz.lut Datei ist inkosistent/ung&uuml;ltig";

      case NO_LUT_FILE:
         return "die blz.lut Datei wurde nicht gefunden";

      case INVALID_BLZ_LENGTH:
         return "die Bankleitzahl ist nicht achtstellig";

      case INVALID_BLZ:
         return "die Bankleitzahl ist ung&uuml;ltig";

      case INVALID_KTO:
         return "das Konto ist ung&uuml;ltig";

      case NOT_IMPLEMENTED:
         return "die Methode wurde noch nicht implementiert";

      case NOT_DEFINED:
         return "die Methode ist nicht definiert";

      case FALSE:
         return "falsch";

      case OK:
         return "ok";

      case OK_NO_CHK:
         return "ok, ohne Pr&uuml;fung";

      default: 
         return "ung&uuml;ltiger R&uuml;ckgabewert";

   }
}

   /* dummy function for perl */
int lut_cleanup(void)
{
   return OK;
}

#endif /* INCLUDE_KONTO_CHECK_DE */

/* Funktion kto_check_at() +§§§1 */
/* Funktion kto_check_at()  +§§§2 */
/* Beschreibung, Vorspann +§§§3 */
/* ###########################################################################
 * # Die Funktion kto_check_at() ist die externe Schnittstelle zur Über-     #
 * # prüfung einer Kontonummer. Die Rückgabewerte sind in der Datei          #
 * # konto_check-at.h definiert; eine Klartextmeldung kann über die Funktion #
 * # kto_check_retval2txt geholt werden.                                     #
 * #                                                                         #
 * # Parameter:                                                              #
 * #    blz1:     BLZ (5-stellig) oder Prüfparameter (mit vorangestelltem p) #
 * #              Falls der BLZ ein - vorausgestellt wird, werden gelöschte  #
 * #              Bankleitzahlen geprüft.                                    #
 * #              Falls der BLZ ein p vorausgestellt wird, wird der folgende #
 * #              Teil (bis zum Blank/Tab) als Prüfparameter angesehen.      #
 * #                                                                         #
 * #    kto1:     Kontonummer                                                #
 * #                                                                         #
 * #    lut_name: Name der Lookup-Datei, NULL oder Leerstring                #
 * #              Falls für lut_name NULL angegeben wird, wird keine         #
 * #              lut-Datei gelesen; die Variable global_vars_initialized    #
 * #              wird in diesem Fall *nicht* gesetzt.                       #
 * #              Falls für lut_name ein Leerstring angegeben wird, versucht #
 * #              die Funktion, die Datei DEFAULT_LUT_NAME_AT zu lesen.      #
 * #                                                                         #
 * # Copyright (C) 2006 Michael Plugge <m.plugge@hs-mannheim.de>             #
 * ###########################################################################
 */

DLL_EXPORT int kto_check_at(char *blz1,char *kto1,char *lut_name)
{
   char *ptr,*ptr1,*kptr,*liste,kto[16];
   int count,pruefziffer,wichtung,methode,stelle_1,pz,pz1,i,blz_num,retval,
       ignore_loeschdatum,ok,ok_no_chk,false_retval;

      /* Initialisierung etc. +§§§3
       */
      ok=OK;
      ok_no_chk=OK_NO_CHK;
      false_retval=FALSE;

      /* globale Variablen initialisieren, falls noch nicht geschehen */
   if(global_vars_initialized!=E_L){
      if(!lut_name)   /* NULL für die LUT-Datei angegeben; lut-Datei nicht lesen */
         retval=init_globals(NULL);
      else if(!*lut_name)   /* Leerstring angegeben; Default benutzen */
         retval=init_globals(DEFAULT_LUT_NAME_AT);
      else
         retval=init_globals(lut_name);
      if(retval!=OK)return retval;
   }

      /* Bankleitzahl und Prüfparameter holen */
   if(*blz1=='-'){
      blz1++;
      ignore_loeschdatum=1;
   }
   else
      ignore_loeschdatum=0;
   if(*blz1=='p'){
      liste=blz1+1;
   }
   else{
      for(ptr=blz1;*ptr<'0' || *ptr>'9';ptr++); /* Blanks etc. am Anfang überspringen */
      for(ptr1=ptr;*ptr1>='0' && *ptr1<='9';ptr1++); /* Ende der BLZ suchen */
      i=(ptr1-ptr);
      switch(i){  /* je nach Stringlänge der BLZ umwandeln: */
         case 1: blz_num=*ptr-'0'; break;
         case 2: blz_num=(*ptr-'0')*10+ *(ptr+1)-'0'; break;
         case 3: blz_num=(*ptr-'0')*100+(*(ptr+1)-'0')*10+ *(ptr+2)-'0'; break;
         case 4: blz_num=(*ptr-'0')*1000+(*(ptr+1)-'0')*100+(*(ptr+2)-'0')*10+ *(ptr+3)-'0'; break;
         case 5: blz_num=(*ptr-'0')*10000+(*(ptr+1)-'0')*1000+(*(ptr+2)-'0')*100+(*(ptr+3)-'0')*10+ *(ptr+4)-'0'; break;
         default: blz_num=0; break;
      }
      i=blz_tabelle[blz_num];
      if(i==-1)return INVALID_BLZ;
      if(ignore_loeschdatum){
         if(geloeschte_blz[blz_num]){
            ok=OK_GELOESCHT;
            ok_no_chk=OK_NO_CHK_GELOESCHT;
            false_retval=FALSE_GELOESCHT;
         }
         else{
            ok=OK;
            ok_no_chk=OK_NO_CHK;
            false_retval=FALSE;
         }
      }
      else{
         if(geloeschte_blz[blz_num])return BLZ_GELOESCHT;
         ok=OK;
         ok_no_chk=OK_NO_CHK;
         false_retval=FALSE;
      }
         /* die ersten fünf Stellen enthalten den Namen der Tabelle */
      liste=(char *)tabelle[i]+6;
      if(i==0)return ok_no_chk;
   }

      /* Kontonummer mit führenden Nullen auf 11 Stellen ergänzen */
   for(ptr=kto1;*ptr;ptr++);  /* Stringende suchen */
   for(kptr=kto+11;ptr>=kto1;*kptr--= *ptr--);  /* Kontonummer (von rechts) kopieren */
   while(kptr>=kto)*kptr--='0';  /* führende Nullen ergänzen */

      /* nun die Bedingungen prüfen und u.U. den entsprechenden Test durchführen +§§§3 */
   for(ptr=liste;*ptr!=' ' && *ptr;){
      switch(*ptr++){   /* Sonderfall Bedingung 00: immer testen */
         case '0':
            if(*ptr!='0'){    /* sollte nicht vorkommen (nicht definiert); nächste Bedingung testen */
               fprintf(stderr,"Bedingung 0%c ist nicht definiert; gehe zum nächsten Test\n",*ptr);
               ptr+=6;
               continue;
            }
            if(*(ptr+1)=='0' && *(ptr+2)=='0' && *(ptr+3)=='0' && *(ptr+4)=='0' && *(ptr+5)=='0'){
               return ok_no_chk; /* Sonderfall, keine Prüfung vorzunehmen */
            }
            break;
            /* weitere Bedingungen prüfen */
         BEDINGUNG('1',1);
         BEDINGUNG('2',2);
         BEDINGUNG('3',3);
         BEDINGUNG('4',4);
         BEDINGUNG('5',5);
         BEDINGUNG('6',6);
         BEDINGUNG('7',7);
         BEDINGUNG('8',8);
         BEDINGUNG('9',9);
         BEDINGUNG2('a','A',A);
         BEDINGUNG2('b','B',B);
      }
      ptr++;

         /* Position der ersten zu prüfenden Stelle der Kontonummer (als Pointer) */
      kptr=kto+char2numi[stelle_1=*ptr++];

         /* Anzahl der zu prüfenden Stellen */
      count=char2num[(int)*ptr++];

         /* Position der Prüfziffer (hier von **links**, wegen Arrayindizierung) */
      pruefziffer=char2numi[(int)*ptr++];

         /* Gewichtung der zu prüfenden Stellen */
      wichtung=*ptr++;

         /* Rechenvorgang der Prüfziffer */
      methode=char2num[(int)*ptr++];      

      if(!(parameter_valid[stelle_1]&1))return INVALID_PARAMETER_STELLE1;
      if(!(parameter_valid[count]&2))return INVALID_PARAMETER_COUNT;
      if(!(parameter_valid[pruefziffer]&4))return INVALID_PARAMETER_PRUEFZIFFER;
      if(!(parameter_valid[wichtung]&8))return INVALID_PARAMETER_WICHTUNG;
      if(!(parameter_valid[methode]&16))return INVALID_PARAMETER_METHODE;

      pz=pz1=0;
      wichtung=char2num[wichtung];
      stelle_1=char2num[stelle_1]-1;   

          /* Methode 0 +§§§3 */
      if(methode==0){
         for(;count>0;count--){
            pz1=w[wichtung][stelle_1++]*(*kptr-- -'0');
            if(pz1>9)pz1=pz1/10 + pz1%10;
            if(pz1>9)pz1-=9;
            pz+=pz1;
         }
         if(!(pz%10))return ok;
      }  /* Ende von Methode 0 */
         /* Methode 1 ... 8 +§§§3 */
      else{
         for(;count>0;count--)pz+=w[wichtung][stelle_1++]*(*kptr-- -'0');

            /* Test der Prüfziffer, je nach Methode: +§§§3
             * Die Tests für Methode 0 (mit Quersumme) wurde oben im eigenen
             * Zweig durchgeführt. Falls ein Test nicht erfolgreich ist, wird 
             * mit dem nächsten möglichen Verfahren getestet; falls kein
             * Verfahren mehr angegeben ist, wird die Schleife verlassen
             * und FALSE zurückgegeben.
             */
         switch(methode){
            case 1:
               if(!(pz%11))return ok;
               break;

            case 2:
               if(pz%10==kto[pruefziffer]-'0')return ok;
               break;

            case 3:
               if(!(pz1=pz%11))
                  return ok;
               else if(pz1==1 && kto[pruefziffer]=='0')
                  return ok;
               break;

            case 4:
               if(!(pz%10))return ok;
               break;

            case 5:
               if(!(pz1=pz%11))
                  return ok;
               else if(pz1==2 && kto[pruefziffer]=='1')
                  return ok;
               break;

            case 6:
               if(!(pz1=pz%10) || pz1==1)return ok;
               break;

            case 7:
               if(!(pz1=pz%11) || pz1==1)return ok;
               break;

            case 8:
               if(!(pz%11))
                  return ok;
               else if(!(pz%14))
                  return ok;
               break;
         }
      }
   }
   return false_retval;
}


/* Funktion kto_check_at_str() (Trace-Version) +§§§1 */
DLL_EXPORT char *kto_check_at_str(char *blz1,char *kto1,char *lut_name)
{
   switch(kto_check_at(blz1,kto1,lut_name)){
      case UNDEFINED_SUBMETHOD: return "UNDEFINED_SUBMETHOD";
      case EXCLUDED_AT_COMPILETIME: return "EXCLUDED_AT_COMPILETIME";
      case INVALID_LUT_VERSION: return "INVALID_LUT_VERSION";
      case INVALID_PARAMETER_STELLE1: return "INVALID_PARAMETER_STELLE1";
      case INVALID_PARAMETER_COUNT: return "INVALID_PARAMETER_COUNT";
      case INVALID_PARAMETER_PRUEFZIFFER: return "INVALID_PARAMETER_PRUEFZIFFER";
      case INVALID_PARAMETER_WICHTUNG: return "INVALID_PARAMETER_WICHTUNG";
      case INVALID_PARAMETER_METHODE: return "INVALID_PARAMETER_METHODE";
      case LIBRARY_INIT_ERROR: return "LIBRARY_INIT_ERROR";
      case LUT_CRC_ERROR: return "LUT_CRC_ERROR";
      case FALSE_GELOESCHT: return "FALSE_GELOESCHT";
      case OK_NO_CHK_GELOESCHT: return "OK_NO_CHK_GELOESCHT";
      case OK_GELOESCHT: return "OK_GELOESCHT";
      case BLZ_GELOESCHT: return "BLZ_GELOESCHT";
      case INVALID_BLZ_FILE: return "INVALID_BLZ_FILE";
      case LIBRARY_IS_NOT_THREAD_SAFE: return "LIBRARY_IS_NOT_THREAD_SAFE";
      case FATAL_ERROR: return "FATAL_ERROR";
      case INVALID_KTO_LENGTH: return "INVALID_KTO_LENGTH";
      case FILE_WRITE_ERROR: return "FILE_WRITE_ERROR";
      case FILE_READ_ERROR: return "FILE_READ_ERROR";
      case ERROR_MALLOC: return "ERROR_MALLOC";
      case NO_BLZ_FILE: return "NO_BLZ_FILE";
      case INVALID_LUT_FILE: return "INVALID_LUT_FILE";
      case NO_LUT_FILE: return "NO_LUT_FILE";
      case INVALID_BLZ_LENGTH: return "INVALID_BLZ_LENGTH";
      case INVALID_BLZ: return "INVALID_BLZ";
      case INVALID_KTO: return "INVALID_KTO";
      case NOT_IMPLEMENTED: return "NOT_IMPLEMENTED";
      case NOT_DEFINED: return "NOT_DEFINED";
      case FALSE: return "FALSE";
      case OK: return "OK";
      case OK_NO_CHK: return "OK_NO_CHK";
      default: return "???";
   }
}

/* Funktion konto_check_at_version_major() +§§§1 */
DLL_EXPORT int konto_check_at_version_major(void)
{
   return VERSION_AT_MAJOR;
}

/* Funktion konto_check_at_version_minor() +§§§1 */
DLL_EXPORT int konto_check_at_version_minor(void)
{
   return VERSION_AT_MINOR;
}

/* Funktion konto_check_at_version_release() +§§§1 */
DLL_EXPORT int konto_check_at_version_release(void)
{
   return VERSION_AT_RELEASE;
}

/* Funktion main() (normale Version) +§§§1 */
#ifdef USE_MAIN
int main(int argc,char **argv)
{
   char *blz1,*kto1,*extra,*ptr,buffer[1024],*plain_name,*plain_format,*lut_name;
   int retval;
   FILE *in,*out;

   if(argc<3 || !strcmp(argv[1],"-h") || !strcmp(argv[1],"-help") || !strcmp(argv[1],"--help")){
      fprintf(stderr,"konto_check-at Version " VERSION_AT " vom " VERSION_DATE_AT ")\n"
            "Mögliche Aufrufoptionen:\n\n"
            "   die Konten aus infile testen, nach outfile schreiben:\n"
            "         konto_check-at infile outfile [lutfile]\n\n"
            "   Inhalt der lut-Datei lutfile als Klartextdatei plainfile schreiben:\n"
            "         konto_check-at -dump lutfile plainfile\n\n"
            "   lut-Datei aus inparfile generieren, sowie optional noch eine Klartextdatei\n"
            "   plainfile schreiben (in freiem Format; die möglichen Escape-Sequenzen\n"
            "   von plain-format sind in konto_check-at.h beschrieben):\n"
            "         konto_check-at -lut inparfile lutfile [plainfile] [plain-format]\n");
      return 0;
   }

   if(!strcmp(argv[1],"-dump")){
      if(argc<4){
         fprintf(stderr,"konto_check_at: die Option -dump benötigt einen Eingabe- und einen Ausgabenamen; Abbruch\n");
         exit(1);
      }
      fprintf(stderr,"dump %s -> %s: ",argv[2],argv[3]);
      retval=dump_lutfile_at(argv[2],argv[3]);
      fprintf(stderr,"%d (%s)\n",retval,kto_check_retval2txt(retval));
      return 0;
   }

   if(!strcmp(argv[1],"-lut")){
      if(argc<4){
         fprintf(stderr,"konto_check_at: die Option -lut benötigt mindestens einen Eingabe- und einen Ausgabenamen; Abbruch\n");
         exit(1);
      }
      if(argc<5)
         plain_name=NULL;
      else
         plain_name=argv[4];
      if(argc<6)
         plain_format=DEFAULT_PLAIN_FORMAT;
      else
         plain_format=argv[5];
      retval=generate_lut_at(argv[2],argv[3],plain_name,plain_format);
      fprintf(stderr,"generate_lut: %d (%s)\n",retval,kto_check_retval2txt(retval));
      return 0;
   }

   if(!(in=fopen(argv[1],"r"))){
      fprintf(stderr,"Kann die Datei %s nicht zum Lesen öffnen; Abbruch\n",argv[1]);
      exit(1);
   }
   if(!(out=fopen(argv[2],"w"))){
      fprintf(stderr,"Kann die Datei %s nicht zum Schreiben öffnen; Abbruch\n",argv[2]);
      exit(1);
   }
   if(argc>3)
      lut_name=argv[3];
   else
      lut_name=DEFAULT_LUT_NAME_AT;


      /* erst mal nachsehen, ob die lut-Datei auch da und in Ordnung ist */
   retval=kto_check_at("1","10000",lut_name);
   switch(retval){
      case FALSE_GELOESCHT:
      case OK_NO_CHK_GELOESCHT:
      case OK_GELOESCHT:
      case BLZ_GELOESCHT:
      case INVALID_KTO_LENGTH:
      case INVALID_BLZ:
      case INVALID_KTO:
      case NOT_IMPLEMENTED:
      case NOT_DEFINED:
      case FALSE:
      case OK:
      case OK_NO_CHK:
         break;   /* unkritischer Fehler, Datei testen */

      default:    /* Initialisierung nicht ok => Fehlermeldung und Abbruch*/
         fprintf(stderr,"konto_check-at: Fehler %s; Abbruch\n",kto_check_retval2txt(retval));
         exit(1);
   }

   while(1){
      fgets(ptr=buffer,1024,in);
      if(feof(in))break;
      while(*ptr==' '||*ptr=='\t')ptr++;
      for(blz1=ptr;*ptr!=' ';ptr++);
      *ptr++=0;
      while(*ptr==' '||*ptr=='\t')ptr++;
      for(kto1=ptr;*ptr!='\n' && *ptr!=' ';ptr++);
      if(*ptr==' '){
         *ptr++=0;
         extra=ptr;
         while(*ptr && *ptr!='\n')ptr++;
      }
      else
         extra="";
      *ptr=0;
      retval=kto_check_at(blz1,kto1,lut_name);
      fprintf(out,"%s # %5s # %-11s # %s -> %s",retval>0?"+":"-",
            blz1,kto1,extra,kto_check_retval2txt(retval));
      if(retval==BLZ_GELOESCHT)
         fprintf(out," (Löschdatum: %s)\n",get_loesch_datum(blz1));
      else
         fputc('\n',out);

      fflush(out);
   }
   fclose(in);
   fclose(out);
   return 0;
}

/* Funktion xmain() (Benchmark-Version) +§§§1 */
/* #####################################################################################
 * # Diese Funktion dient nur zur Geschwindigkeitsmessung; sie erwartet eine           #
 * # Liste von Kontonummern und Bankleitzahlen, die durch jeweils ein Blank            #
 * # getrennt sind. Kontonummern und Bankleitzahlen werden in je ein Array             #
 * # geschrieben, und dann zur Geschwindigkeitsmessung in einer eigenen Schleife       #
 * # getestet. Die Ausgabe ist normalerweise durch die continue-Anweisung deaktiviert. #
 * #####################################################################################
 */
int xmain(int argc,char **argv)
{
   char *blz1[1000000],*kto1[1000000],*extra[1000000],*buffer,*ptr,*eptr,*retval_txt,
        *plain_name,*plain_format;
   int retval,size,i,j;
   struct stat sbuf;
   FILE *in,*out;

   if(argc<3 || !strcmp(argv[1],"-h") || !strcmp(argv[1],"-help") || !strcmp(argv[1],"--help")){
      fprintf(stderr,"konto_check-at Version " VERSION_AT " vom " VERSION_DATE_AT ")\n"
            "Mögliche Aufrufoptionen:\n\n"
            "   Inhalt der lut-Datei lutfile als Klartextdatei plainfile schreiben:\n"
            "         konto_check-at -dump lutfile plainfile\n\n"
            "   lut-Datei aus inparfile generieren, sowie optional noch eine Klartextdatei\n"
            "   plainfile schreiben (in freiem Format; die möglichen Escape-Sequenzen\n"
            "   von plain-format sind in konto_check-at.h beschrieben):\n"
            "         konto_check-at -lut inparfile lutfile [plainfile] [plain-format]\n\n"
            "   die Konten aus infile testen, nach outfile schreiben:\n"
            "         konto_check-at infile outfile\n");
      return 0;
   }

   if(!strcmp(argv[1],"-dump")){
      if(argc<3){
         fprintf(stderr,"konto_check_at: die Option -dump benötigt einen Eingabe- und einen Ausgabenamen; Abbruch\n");
         exit(1);
      }
      fprintf(stderr,"dump %s -> %s: ",argv[2],argv[3]);
      retval=dump_lutfile_at(argv[2],argv[3]);
      fprintf(stderr,"%d (%s)\n",retval,kto_check_retval2txt(retval));
      return 0;
   }
   if(!strcmp(argv[1],"-lut")){
      if(argc<3){
         fprintf(stderr,"konto_check_at: die Option -lut benötigt mindestens einen Eingabe- und einen Ausgabenamen; Abbruch\n");
         exit(1);
      }
      if(argc<4)
         plain_name=NULL;
      else
         plain_name=argv[4];
      if(argc<5)
         plain_format=DEFAULT_PLAIN_FORMAT;
      else
         plain_format=argv[5];
      retval=generate_lut_at(argv[2],argv[3],plain_name,plain_format);
      fprintf(stderr,"generate_lut: %d (%s)\n",retval,kto_check_retval2txt(retval));
      return 0;
   }
   if(stat(argv[1],&sbuf)){
      perror("Filesize input");
      exit(1);
   }
   size=sbuf.st_size;
   if(!(buffer=malloc(size+1024))){
      fprintf(stderr,"Kann keinen Speicher allokieren (%d Byte); Abbruch\n",size+1024);
      exit(1);
   }

   if(!(in=fopen(argv[1],"r"))){
      fprintf(stderr,"Kann die Datei %s nicht zum Lesen öffnen; Abbruch\n",argv[1]);
      exit(1);
   }
   if(!(out=fopen(argv[2],"w"))){
      fprintf(stderr,"Kann die Datei %s nicht zum Schreiben öffnen; Abbruch\n",argv[2]);
      exit(1);
   }

      /* nun die gesamte Datei in einem Rutsch einlesen */
   eptr=buffer+fread(buffer,1,size,in);
   for(ptr=buffer,i=0;i<1000000 && ptr<eptr;i++){
      while(*ptr==' ' || *ptr=='\t')ptr++;
      for(blz1[i]=ptr;*ptr!=' ';ptr++);
      *ptr++=0;
      while(*ptr==' ' || *ptr=='\t')ptr++;
      for(kto1[i]=ptr;*ptr!='\n' && *ptr!=' ';ptr++);
      if(*ptr==' '){
         *ptr++=0;
         extra[i]=ptr;
         while(*ptr!='\n')ptr++;
      }
      else
         extra[i]="";
      *ptr++=0;
   }
   if((retval=kto_check_at(blz1[0],kto1[0],DEFAULT_LUT_NAME_AT))==LUT_CRC_ERROR){
         fprintf(stderr,"CRC Fehler in der LUT-Datei; Abbruch\n");
         return 2;
   }
   for(j=0;j<i;j++){
      retval=kto_check_at(blz1[j],kto1[j],DEFAULT_LUT_NAME_AT);
      continue;

         /***********************************************************************************
          * Der folgende Teil wird normalerweise aufgrund des continue nicht ausgeführt!!!! *
          * Falls eine Ausgabe gemacht werden soll, die vorige Zeile auskommentieren.       *
          ***********************************************************************************/
      switch(retval){
         case UNDEFINED_SUBMETHOD        : retval_txt="UNDEFINED_SUBMETHOD        "; break;
         case EXCLUDED_AT_COMPILETIME    : retval_txt="EXCLUDED_AT_COMPILETIME    "; break;
         case INVALID_LUT_VERSION        : retval_txt="INVALID_LUT_VERSION        "; break;
         case INVALID_PARAMETER_STELLE1  : retval_txt="INVALID_PARAMETER_STELLE1  "; break;
         case INVALID_PARAMETER_COUNT    : retval_txt="INVALID_PARAMETER_COUNT    "; break;
         case INVALID_PARAMETER_PRUEFZIFFER: retval_txt="INVALID_PARAMETER_PRUEFZIFFER"; break;
         case INVALID_PARAMETER_WICHTUNG : retval_txt="INVALID_PARAMETER_WICHTUNG "; break;
         case INVALID_PARAMETER_METHODE  : retval_txt="INVALID_PARAMETER_METHODE  "; break;
         case LIBRARY_INIT_ERROR         : retval_txt="LIBRARY_INIT_ERROR         "; break;
         case LUT_CRC_ERROR              : retval_txt="LUT_CRC_ERROR              "; break;
         case FALSE_GELOESCHT            : retval_txt="FALSE_GELOESCHT            "; break;
         case OK_NO_CHK_GELOESCHT        : retval_txt="OK_NO_CHK_GELOESCHT        "; break;
         case OK_GELOESCHT               : retval_txt="OK_GELOESCHT               "; break;
         case BLZ_GELOESCHT              : retval_txt="BLZ_GELOESCHT              "; break;
         case INVALID_BLZ_FILE           : retval_txt="INVALID_BLZ_FILE           "; break;
         case LIBRARY_IS_NOT_THREAD_SAFE : retval_txt="LIBRARY_IS_NOT_THREAD_SAFE "; break;
         case FATAL_ERROR                : retval_txt="FATAL_ERROR                "; break;
         case INVALID_KTO_LENGTH         : retval_txt="INVALID_KTO_LENGTH         "; break;
         case FILE_WRITE_ERROR           : retval_txt="FILE_WRITE_ERROR           "; break;
         case FILE_READ_ERROR            : retval_txt="FILE_READ_ERROR            "; break;
         case ERROR_MALLOC               : retval_txt="ERROR_MALLOC               "; break;
         case NO_BLZ_FILE                : retval_txt="NO_BLZ_FILE                "; break;
         case INVALID_LUT_FILE           : retval_txt="INVALID_LUT_FILE           "; break;
         case NO_LUT_FILE                : retval_txt="NO_LUT_FILE                "; break;
         case INVALID_BLZ_LENGTH         : retval_txt="INVALID_BLZ_LENGTH         "; break;
         case INVALID_BLZ                : retval_txt="INVALID_BLZ                "; break;
         case INVALID_KTO                : retval_txt="INVALID_KTO                "; break;
         case NOT_IMPLEMENTED            : retval_txt="NOT_IMPLEMENTED            "; break;
         case NOT_DEFINED                : retval_txt="NOT_DEFINED                "; break;
         case FALSE                      : retval_txt="FALSE                      "; break;
         case OK                         : retval_txt="OK                         "; break;
         case OK_NO_CHK                  : retval_txt="OK_NO_CHK                  "; break;
      }
      fprintf(out,"%s %s %5s %11s %s\n",retval>0?"+":"-",
            retval_txt,blz1[j],kto1[j],extra[j]);
      fflush(out);
   }
   fclose(in);
   free(buffer);
   return 0;
}
#endif
#else /* !INCLUDE_KONTO_CHECK_AT */
#include "konto_check-at.h"
char *kto_check_at_str(char *blz,char *kto,char *lut_name){return "EXCLUDED_AT_COMPILETIME";};
int kto_check_at(char *blz,char *kto,char *lut_name){return EXCLUDED_AT_COMPILETIME;};
#ifndef INCLUDE_KONTO_CHECK_DE
char *kto_check_retval2txt(int retval){return "EXCLUDED_AT_COMPILETIME";};
char *kto_check_retval2html(int retval){return "EXCLUDED_AT_COMPILETIME";};
#endif
const char *get_loesch_datum(char *blz){return "EXCLUDED_AT_COMPILETIME";};
int generate_lut_at(char *inputname,char *outputname,char *plainname,char *plain_format){return EXCLUDED_AT_COMPILETIME;};
int konto_check_at_version_major(void){return EXCLUDED_AT_COMPILETIME;};
int konto_check_at_version_minor(void){return EXCLUDED_AT_COMPILETIME;};
int konto_check_at_version_release(void){return EXCLUDED_AT_COMPILETIME;};
int dump_lutfile_at(char *inputname, char *outputname){return EXCLUDED_AT_COMPILETIME;};
#endif
