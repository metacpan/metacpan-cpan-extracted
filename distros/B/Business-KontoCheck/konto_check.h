/* vim: ft=c:set si:set fileencoding=iso-8859-1
 */
#line 9 "konto_check_h.lx"

/*
 * ##########################################################################
 * #  Dies ist konto_check, ein Programm zum Testen der Prüfziffern         #
 * #  von deutschen Bankkonten. Es kann als eigenständiges Programm         #
 * #  (z.B. mit der beigelegten main() Routine) oder als Library zur        #
 * #  Verwendung in anderen Programmen bzw. Programmiersprachen benutzt     #
 * #  werden.                                                               #
 * #                                                                        #
 * #  Copyright (C) 2002-2017 Michael Plugge <m.plugge@hs-mannheim.de>      #
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

#ifndef KONTO_CHECK_H_INCLUDED
#define KONTO_CHECK_H_INCLUDED

   /* Falls EXTRA_BLZ_REGEL auf 1 gesetzt wird, wird beim IBAN-Test
    * unterschieden ob eine Regel ignoriert wurde, die nur eine BLZ ersetzt,
    * oder eine andere Regel. Die Variante wenn nur eine BLZ ersetzt wird, wird
    * von cKonto als richtig angesehen.
    *
    * Bei einer Nachfrage bei den 17 in Frage kommenden Banken bekam ich von
    * zehn Banken Antworten. Von diesen sagte nur eine, daß (aktuell) die
    * "alten" IBANs noch akzeptiert würden, die neun anderen sehen eine solche
    * IBAN jedoch als fehlerhaft an. In konto_check wird daher das alte
    * Verhalten beibehalten, solche IBANs als Fehler zu deklarieren. Wenn das
    * folgende Makro auf 1 gesetzt wird, gibt es verschiedene Rückgabewerte für
    * Regelverstöße mit nur BLZ-Ersetzung und andere Regeln. Auf diese Weise
    * kann das Verhalten von cKonto in Benutzerprogrammen nachgebildet werden.
    */

#define EXTRA_BLZ_REGEL 1

/* Das Makro DEFAULT_ENCODING legt die Ausgabe-Kodierung für die Funktion
 * kto_check_retval2txt() und die Blocks Name, Kurzname und Ort aus der
 * LUT-Datei fest. Die folgenden Werte sind möglich:
 *
 *    1: ISO-8859-1
 *    2: UTF-8
 *    3: HTML Entities
 *    4: DOS CP-850
 *
 * Werte außerhalb dieses Bereichs dürften schnell zum Absturz führen, da
 * einige Arrays damit initialisiert werden.
 */

#ifndef DEFAULT_ENCODING
#  define DEFAULT_ENCODING 1
#endif

#define KEEP_RAW_DATA    1

/* 
 * ##########################################################################
 * # Fallls das folgende Makro auf 1 gesetzt wird, werden unterschiedliche  #
 * # Interpretationen der Prüfziffermethoden interpretiert wie in BAV       #
 * # (Bank Account Validator, http://sourceforge.net/projects/bav)          #
 * # Dieses Makro dient zum Test der beiden Pakete, damit bei den Tests     # 
 * # nicht immer Unterschiede ausgegeben werden, wo nur (bekannte)          #
 * # unterschiedliche Interpretationen der Berechnungsmethoden existieren.  #
 * ##########################################################################
 */
#define BAV_ENABLE 0

#if BAV_ENABLE==1
#ifndef BAV_KOMPATIBEL
#define BAV_KOMPATIBEL 0
#endif
#else
#undef BAV_KOMPATIBEL
#define BAV_KOMPATIBEL 0
#endif

/*
 * ##########################################################################
 * # Fallls das Makro DEBUG auf 1 gesetzt wird, werden zwei- und drei-      #
 * # stellige Methoden (Methode + evl. Untermethode) akzeptiert, sowie noch #
 * # diverser Debug-Code mit eingebaut.                                     #
 * #                                                                        #
 * # Das Makro VERBOSE_DEBUG wird für einige spezielle Problemfälle benutzt;#
 * # falls es gesetzt ist, wird im Fehlerfall mittels perror() eine etwas   #
 * # detailliertere Fehlermeldung ausgegeben (im Moment nur bei fopen()).   #
 * # Es wird ebenfalls für zum Debuggen von RückgabewerteN (Makro RETURN(r) #
 * # bei Problemen benutzt.                                                 #
 * ##########################################################################
 */
#ifndef DEBUG
#define DEBUG 1
#endif

#ifndef VERBOSE_DEBUG
#define VERBOSE_DEBUG 1
#endif

/*
 * ##########################################################################
 * # falls das folgende Makro auf 1 gesetzt wird, werden für das PHP-Modul  #
 * # symbolische Konstanten definiert (analog zu den #define's aus der      #
 * # C Bibliothek. Der Wert false ist in PHP allerdings schon belegt und    #
 * # kann nicht verwendet werden; stattdessen wird NOT_OK definiert.        #
 * ##########################################################################
 */
#define SYMBOLIC_RETVALS 1

/*
 * ##########################################################################
 * # falls das folgende Makro auf 1 gesetzt wird, werden Dummys für die     #
 * # alten globalen Variablen eingebunden; die alte Funktionalität wird     #
 * # jedoch aufgrund der Threadfestigkeit nicht implementiert.              #
 * ##########################################################################
 */
#define INCLUDE_DUMMY_GLOBALS 0

/*
 * ##########################################################################
 * # falls das folgende Makro auf 1 gesetzt wird, werden die Zweigstellen   #
 * # in der LUT-Datei nach Postleitzahlen sortiert; andernfalls wird die    #
 * # Reihenfolge aus der Datei der Deutschen Bundesbank übernommen (mit der #
 * # Ausnahme, daß Hauptstellen vor die Zweigstellen gesetzt werden und die #
 * # gesamte Datei nach BLZs sortiert wird).                                #
 * ##########################################################################
 */
#define SORT_PLZ 0

/*
 * ######################################################################
 * # DLL-Optionen für Windows                                           #
 * # Der DLL-Code wurde aus der Datei dllhelpers (beim MinGW-Compiler   #
 * # enthalten, http://www.mingw.org/) entnommen                        #
 * #                                                                    #
 * # Falls das Makro USE_CDECL gesetzt ist, wird als Aufrufmethode      #
 * # CDECL genommen, ansonsten STDCALL (Default).                       #
 * ######################################################################
 */

#if _WIN32>0 || _WIN64>0
#  if USE_CDECL
#    if BUILD_DLL /* DLL kompilieren */
#      define DLL_EXPORT __declspec (dllexport)
#      define DLL_EXPORT_V __declspec (dllexport)
#    elif USE_DLL /* DLL in einem anderen Programm benutzen */
#      define DLL_EXPORT __declspec (dllimport)
#      define DLL_EXPORT_V __declspec (dllimport)
#    else /* kein DLL-Krempel erforderlich */
#      define DLL_EXPORT
#      define DLL_EXPORT_V
#    endif
#  else
#     if BUILD_DLL /* DLL kompilieren */
#      define DLL_EXPORT __declspec (dllexport) __stdcall 
#      define DLL_EXPORT_V __declspec (dllexport)
#    elif USE_DLL /* DLL in einem anderen Programm benutzen */
#      define DLL_EXPORT __declspec (dllimport) __stdcall 
#      define DLL_EXPORT_V __declspec (dllimport)
#    else /* kein DLL-Krempel erforderlich */
#      define DLL_EXPORT
#      define DLL_EXPORT_V
#    endif
#  endif
#  define localtime_r(timep,result) localtime(timep)
#else
#  define DLL_EXPORT
#  define DLL_EXPORT_V
#endif

/*
 * ######################################################################
 * # AWK_ADD_MICROTIME: AWK-Funktionalität mit Mikrosekunden-Auflösung  #
 * # Falls das folgende Makro auf 1 gesetzt wird, wird im awk-Port die  #
 * # Funktion microtime() definiert, die - anders als systime() - mit   #
 * # hoher Auflösung (Mikrosekunden) arbeitet. Parameter etc. finden    #
 * # sich in konto_check_awk.c. Standardmäßig ist die Funktion nicht    #
 * # aktiviert.                                                         #
 * ######################################################################
 */
#define AWK_ADD_MICROTIME 1


/*
 * ######################################################################
 * #          Defaultnamen und Suchpfad für die LUT-Datei               #
 * ######################################################################
 */

#define DEFAULT_LUT_NAME "blz.lut","blz.lut2f","blz.lut2"

#if _WIN32>0 || _WIN64>0
#define DEFAULT_LUT_PATH ".","C:","C:\\Programme\\konto_check"
#else
#define DEFAULT_LUT_PATH ".","/usr/local/etc","/etc","/usr/local/bin","/opt/konto_check"
#endif

   /* maximale Länge für Default-Suchpfad und Dateiname der LUT-Datei */
#define LUT_PATH_LEN 512

/*
 * ######################################################################
 * #               Felder für die LUT-Datei (ab LUT-Version 2.0)        #
 * ######################################################################
 */

#define DEFAULT_LUT_FIELDS_NUM   9
#define DEFAULT_LUT_FIELDS       lut_set_9
#define DEFAULT_LUT_VERSION      3
#define DEFAULT_SLOTS            60
#define DEFAULT_INIT_LEVEL       5
#define LAST_LUT_BLOCK           100

   /* falls das nächste Makro auf 0 gesetzt wird, werden von generate_lut2() immer
    * LUT-Dateien im neuen Format generieret; falls für lut_version ein Wert <3 angegeben
    * wurde, wird er auf 3 gesetzt.
    */
#define GENERATE_OLD_LUTFILE     0

   /* Das folgende Makro bestimmt das Verhalten, wenn zu einer LUT-Datei Blocks
    * hinzugefügt werden sollen und bereits (mindestens) ein Block mit
    * demselben Typ in der Datei enthalten ist. Falls das Makro 1 ist, wird für
    * den neuen Block der alte Slots der LUT-Datei benutzt; bei 0 wird ein
    * neuer Slot allokiert.
    *
    * Falls das Makro 0 ist, kann man auch später noch auf alte Blocks
    * zugreifen (falls das einmal notwendig sein sollte); allerdings läßt sich
    * das LUT-Verzeichnis nicht vergrößern, so daß u.U. nach mehreren Updates
    * alle Slots belegt sind und daher keine neuen Blocks mehr geschrieben
    * werden können.
    */

#define REPLACE_LUT_DIR_ENTRIES 1

#define LUT2_BLZ                      1
#define LUT2_FILIALEN                 2
#define LUT2_NAME                     3
#define LUT2_PLZ                      4
#define LUT2_ORT                      5
#define LUT2_NAME_KURZ                6
#define LUT2_PAN                      7
#define LUT2_BIC                      8
#define LUT2_PZ                       9
#define LUT2_NR                      10
#define LUT2_AENDERUNG               11
#define LUT2_LOESCHUNG               12
#define LUT2_NACHFOLGE_BLZ           13
#define LUT2_NAME_NAME_KURZ          14
#define LUT2_INFO                    15
#define LUT2_BIC_SORT                16
#define LUT2_NAME_SORT               17
#define LUT2_NAME_KURZ_SORT          18
#define LUT2_ORT_SORT                19
#define LUT2_PLZ_SORT                20
#define LUT2_PZ_SORT                 21
#define LUT2_OWN_IBAN                22
#define LUT2_VOLLTEXT_TXT            23
#define LUT2_VOLLTEXT_IDX            24
#define LUT2_IBAN_REGEL              25
#define LUT2_IBAN_REGEL_SORT         26
#define LUT2_BIC_H_SORT              27

#define LUT2_2_BLZ                  101
#define LUT2_2_FILIALEN             102
#define LUT2_2_NAME                 103
#define LUT2_2_PLZ                  104
#define LUT2_2_ORT                  105
#define LUT2_2_NAME_KURZ            106
#define LUT2_2_PAN                  107
#define LUT2_2_BIC                  108
#define LUT2_2_PZ                   109
#define LUT2_2_NR                   110
#define LUT2_2_AENDERUNG            111
#define LUT2_2_LOESCHUNG            112
#define LUT2_2_NACHFOLGE_BLZ        113
#define LUT2_2_NAME_NAME_KURZ       114
#define LUT2_2_INFO                 115
#define LUT2_2_BIC_SORT             116
#define LUT2_2_NAME_SORT            117
#define LUT2_2_NAME_KURZ_SORT       118
#define LUT2_2_ORT_SORT             119
#define LUT2_2_PLZ_SORT             120
#define LUT2_2_PZ_SORT              121
#define LUT2_2_OWN_IBAN             122
#define LUT2_2_VOLLTEXT_TXT         123
#define LUT2_2_VOLLTEXT_IDX         124
#define LUT2_2_IBAN_REGEL           125
#define LUT2_2_IBAN_REGEL_SORT      126
#define LUT2_2_BIC_H_SORT           127

#define LUT2_DEFAULT                501

#ifdef KONTO_CHECK_VARS
const char *lut2_feld_namen[256];
#else
extern const char *lut2_feld_namen[256];
#endif

/*
 * ######################################################################
 * #               mögliche Rückgabewerte von kto_check() & Co          #
 * ######################################################################
 */

#undef FALSE
#define INVALID_REGULAR_EXPRESSION_CNT        -152
#define INVALID_REGULAR_EXPRESSION            -151
#define INVALID_HANDLE                        -150
#define INVALID_BIQ_INDEX                     -149
#define ARRAY_INDEX_OUT_OF_RANGE              -148
#define IBAN_ONLY_GERMAN                      -147
#define INVALID_PARAMETER_TYPE                -146
#define BIC_ONLY_GERMAN                       -145
#define INVALID_BIC_LENGTH                    -144
#define IBAN_CHKSUM_OK_RULE_IGNORED_BLZ       -143
#define IBAN_CHKSUM_OK_KC_NOT_INITIALIZED     -142
#define IBAN_CHKSUM_OK_BLZ_INVALID            -141
#define IBAN_CHKSUM_OK_NACHFOLGE_BLZ_DEFINED  -140
#define LUT2_NOT_ALL_IBAN_BLOCKS_LOADED       -139
#define LUT2_NOT_YET_VALID_PARTIAL_OK         -138
#define LUT2_NO_LONGER_VALID_PARTIAL_OK       -137
#define LUT2_BLOCKS_MISSING                   -136
#define FALSE_UNTERKONTO_ATTACHED             -135
#define BLZ_BLACKLISTED                       -134
#define BLZ_MARKED_AS_DELETED                 -133
#define IBAN_CHKSUM_OK_SOMETHING_WRONG        -132
#define IBAN_CHKSUM_OK_NO_IBAN_CALCULATION    -131
#define IBAN_CHKSUM_OK_RULE_IGNORED           -130
#define IBAN_CHKSUM_OK_UNTERKTO_MISSING       -129
#define IBAN_INVALID_RULE                     -128
#define IBAN_AMBIGUOUS_KTO                    -127
#define IBAN_RULE_NOT_IMPLEMENTED             -126
#define IBAN_RULE_UNKNOWN                     -125
#define NO_IBAN_CALCULATION                   -124
#define OLD_BLZ_OK_NEW_NOT                    -123
#define LUT2_IBAN_REGEL_NOT_INITIALIZED       -122
#define INVALID_IBAN_LENGTH                   -121
#define LUT2_NO_ACCOUNT_GIVEN                 -120
#define LUT2_VOLLTEXT_INVALID_CHAR            -119
#define LUT2_VOLLTEXT_SINGLE_WORD_ONLY        -118
#define LUT_SUCHE_INVALID_RSC                 -117
#define LUT_SUCHE_INVALID_CMD                 -116
#define LUT_SUCHE_INVALID_CNT                 -115
#define LUT2_VOLLTEXT_NOT_INITIALIZED         -114
#define NO_OWN_IBAN_CALCULATION               -113
#define KTO_CHECK_UNSUPPORTED_COMPRESSION     -112
#define KTO_CHECK_INVALID_COMPRESSION_LIB     -111
#define OK_UNTERKONTO_ATTACHED_OLD            -110
#define KTO_CHECK_DEFAULT_BLOCK_INVALID       -109
#define KTO_CHECK_DEFAULT_BLOCK_FULL          -108
#define KTO_CHECK_NO_DEFAULT_BLOCK            -107
#define KTO_CHECK_KEY_NOT_FOUND               -106
#define LUT2_NO_LONGER_VALID_BETTER           -105
#define INVALID_SEARCH_RANGE                   -79
#define KEY_NOT_FOUND                          -78
#define BAV_FALSE                              -77
#define LUT2_NO_USER_BLOCK                     -76
#define INVALID_SET                            -75
#define NO_GERMAN_BIC                          -74
#define IPI_CHECK_INVALID_LENGTH               -73
#define IPI_INVALID_CHARACTER                  -72
#define IPI_INVALID_LENGTH                     -71
#define LUT1_FILE_USED                         -70
#define MISSING_PARAMETER                      -69
#define IBAN2BIC_ONLY_GERMAN                   -68
#define IBAN_OK_KTO_NOT                        -67
#define KTO_OK_IBAN_NOT                        -66
#define TOO_MANY_SLOTS                         -65
#define INIT_FATAL_ERROR                       -64
#define INCREMENTAL_INIT_NEEDS_INFO            -63
#define INCREMENTAL_INIT_FROM_DIFFERENT_FILE   -62
#define DEBUG_ONLY_FUNCTION                    -61
#define LUT2_INVALID                           -60
#define LUT2_NOT_YET_VALID                     -59
#define LUT2_NO_LONGER_VALID                   -58
#define LUT2_GUELTIGKEIT_SWAPPED               -57
#define LUT2_INVALID_GUELTIGKEIT               -56
#define LUT2_INDEX_OUT_OF_RANGE                -55
#define LUT2_INIT_IN_PROGRESS                  -54
#define LUT2_BLZ_NOT_INITIALIZED               -53
#define LUT2_FILIALEN_NOT_INITIALIZED          -52
#define LUT2_NAME_NOT_INITIALIZED              -51
#define LUT2_PLZ_NOT_INITIALIZED               -50
#define LUT2_ORT_NOT_INITIALIZED               -49
#define LUT2_NAME_KURZ_NOT_INITIALIZED         -48
#define LUT2_PAN_NOT_INITIALIZED               -47
#define LUT2_BIC_NOT_INITIALIZED               -46
#define LUT2_PZ_NOT_INITIALIZED                -45
#define LUT2_NR_NOT_INITIALIZED                -44
#define LUT2_AENDERUNG_NOT_INITIALIZED         -43
#define LUT2_LOESCHUNG_NOT_INITIALIZED         -42
#define LUT2_NACHFOLGE_BLZ_NOT_INITIALIZED     -41
#define LUT2_NOT_INITIALIZED                   -40
#define LUT2_FILIALEN_MISSING                  -39
#define LUT2_PARTIAL_OK                        -38
#define LUT2_Z_BUF_ERROR                       -37
#define LUT2_Z_MEM_ERROR                       -36
#define LUT2_Z_DATA_ERROR                      -35
#define LUT2_BLOCK_NOT_IN_FILE                 -34
#define LUT2_DECOMPRESS_ERROR                  -33
#define LUT2_COMPRESS_ERROR                    -32
#define LUT2_FILE_CORRUPTED                    -31
#define LUT2_NO_SLOT_FREE                      -30
#define UNDEFINED_SUBMETHOD                    -29
#define EXCLUDED_AT_COMPILETIME                -28
#define INVALID_LUT_VERSION                    -27
#define INVALID_PARAMETER_STELLE1              -26
#define INVALID_PARAMETER_COUNT                -25
#define INVALID_PARAMETER_PRUEFZIFFER          -24
#define INVALID_PARAMETER_WICHTUNG             -23
#define INVALID_PARAMETER_METHODE              -22
#define LIBRARY_INIT_ERROR                     -21
#define LUT_CRC_ERROR                          -20
#define FALSE_GELOESCHT                        -19
#define OK_NO_CHK_GELOESCHT                    -18
#define OK_GELOESCHT                           -17
#define BLZ_GELOESCHT                          -16
#define INVALID_BLZ_FILE                       -15
#define LIBRARY_IS_NOT_THREAD_SAFE             -14
#define FATAL_ERROR                            -13
#define INVALID_KTO_LENGTH                     -12
#define FILE_WRITE_ERROR                       -11
#define FILE_READ_ERROR                        -10
#define ERROR_MALLOC                            -9
#define NO_BLZ_FILE                             -8
#define INVALID_LUT_FILE                        -7
#define NO_LUT_FILE                             -6
#define INVALID_BLZ_LENGTH                      -5
#define INVALID_BLZ                             -4
#define INVALID_KTO                             -3
#define NOT_IMPLEMENTED                         -2
#define NOT_DEFINED                             -1
#define FALSE                                    0
#define OK                                       1
#define OK_NO_CHK                                2
#define OK_TEST_BLZ_USED                         3
#define LUT2_VALID                               4
#define LUT2_NO_VALID_DATE                       5
#define LUT1_SET_LOADED                          6
#define LUT1_FILE_GENERATED                      7
#define LUT_V2_FILE_GENERATED                    9
#define KTO_CHECK_VALUE_REPLACED                10
#define OK_UNTERKONTO_POSSIBLE                  11
#define OK_UNTERKONTO_GIVEN                     12
#define OK_SLOT_CNT_MIN_USED                    13
#define SOME_KEYS_NOT_FOUND                     14
#define LUT2_KTO_NOT_CHECKED                    15
#define LUT2_OK_WITHOUT_IBAN_RULES              16
#define OK_NACHFOLGE_BLZ_USED                   17
#define OK_KTO_REPLACED                         18
#define OK_BLZ_REPLACED                         19
#define OK_BLZ_KTO_REPLACED                     20
#define OK_IBAN_WITHOUT_KC_TEST                 21
#define OK_INVALID_FOR_IBAN                     22
#define OK_HYPO_REQUIRES_KTO                    23
#define OK_KTO_REPLACED_NO_PZ                   24
#define OK_UNTERKONTO_ATTACHED                  25
#define OK_SHORT_BIC_USED                       26
#line 279 "konto_check_h.lx"

#define MAX_BLZ_CNT 30000  /* maximale Anzahl BLZ's in generate_lut() */

#ifndef INT4_DEFINED
#define INT4_DEFINED
#include <limits.h>
#if INT_MAX==2147483647
typedef int INT4;
typedef unsigned int UINT4;
#elif LONG_MAX==2147483647
typedef long INT4;
typedef unsigned long UINT4;
#else  /* Notausstieg, kann 4 Byte Integer nicht bestimmen */
#error "Typedef für 4 Byte Integer nicht definiert"
#endif
#endif

   /* in den alten Versionen war reserved als 'void *reserved[5]' definiert;
    * es ist allerdings geschickter, einen Teil davon als char-Array zu
    * definieren.  Dieses kann dann flexibler verwendet werden (auch
    * byteweise). Die Größe der Struktur wird auf diese Weise nicht verändert.
    *
    * Als erstes neues Element wird pz_pos (Position der Prüfziffer) eingeführt.
    */
typedef struct{
   const char *methode;
   INT4 pz_methode;
   INT4 pz;
   signed char pz_pos;
   char reserved_chr[3*sizeof(void*)-1];
   void *reserved_ptr[2];
} RETVAL;


/* ######################################################################
 * # Dies ist der alte Kommentar zu KTO_CHK_CTX; die Struktur ist ab    #
 * # Version 3.0 obsolet und wird nicht mehr verwendet. Die Deklaration #
 * # ist allerdings noch in der Headerdatei enthalten, um Abwärtskompa- #
 * # tibilität mit dem alten Interface zu wahren; Funktionen, die die   #
 * # Struktur benutzen, rufen einfach die neuen (threadfesten)          #
 * # Funktionen auf; die ctx-Variable wird dabei einfach ignoriert.     #
 * #                                                                    #
 * # Definition der Struktur KTO_CHK_CTX. Diese Struktur enthält alle   #
 * # globalen bzw. static Variablen der alten Library und wird bei den  #
 * # threadfesten Varianten als Parameter übergeben. Damit treten keine #
 * # Interferenzen zwischen verschiedenen Instanzen bei einem gleich-   #
 * # zeitigen Aufruf der library mehr auf, wie es bei den nicht thread- #
 * # festen Varianten der Fall ist (beispielsweise werden kto_check_msg,#
 * # pz_str, pz_methode und pz von jeder Instanz überschrieben; dadurch #
 * # sind diese Variablen in einem Thread-Kontext unbrauchbar.          #
 * # Die alten (nicht threadfesten) Varianten sind so realisiert, daß   #
 * # eine (static) globale Struktur global_ctx definiert wird, die von  #
 * # den diesen Funktionen benutzt wird. Diese Vorgehensweise ist       #
 * # wesentlich schneller als die Alternative, lokale Variablen für die #
 * # Problemfälle zu benutzen; die Umsetzung zwischen nicht threadfesten#
 * # und threadfesten Variablen geschieht über Präprozessor #defines    #
 * # in konto_check.c.                                                  #
 * ######################################################################
 */
typedef struct{
   char *kto_check_msg,pz_str[4];
   int pz_methode;
   int pz;
   UINT4 cnt_blz,*blz_array,*pz_array,*blz_hash_low,*blz_hash_high,*invalid;
   char lut_info[1024];
   UINT4 b1[256],b2[256],b3[256],b4[256],b5[256],b6[256],b7[256],b8[256];
   int c2,d2,a5,p,konto[11];
} KTO_CHK_CTX;

/*
 * ##########################################################################
 * # SLOT_CNT_MIN: Minimale Anzahl Slots für eine LUT-Daei.                 #
 * # Dieser Parameter gibt an, wieviele Slots das Inhaltsverzeichnis einer  #
 * # LUT-Datei mindestens haben soll. Für jeden Block in der LUT-Datei wird #
 * # ein Slot im Inhaltsverzeichnis benötigt; bei einer LUT-Datei mit allen #
 * # Einträgen (Level 9) sind das 23 Slots, falls zwei Datensätze in der    #
 * # Datei gehalten werden sollen, 46 (inklusive Indexblocks).              #
 * #                                                                        #
 * # Das Slotverzeichnis ist eine relativ einfache Datenstruktur; es        #
 * # enthält für jeden Slot nur drei 4 Byte-Integers (Typ, Offset und       #
 * # Länge); daher ist es auch kein Problem, für das Slotverzeichnis einen  #
 * # etwas größeren Wert zu wählen. Die Datei wird dadurch nur minimal      #
 * # größer. Die angegebene Anzahl Slots kann nachträglich nicht mehr       #
 * # geändert werden, da das Slotverzeichnis am Beginn des Datenblocks      #
 * # steht und sich bei einer Vergrößerung alle Offsets in der Datei ändern #
 * # würden; außerdem müßten alle Blocks verschoben werden. Es gibt die     #
 * # Möglichkeit, eine LUT-Datei zu kopieren (mittels copy_lutfile()); bei  #
 * # dieser Funktion kann eine neue Anzahl Slots angegeben werden.          #
 * #                                                                        #
 * ##########################################################################
 */
#define SLOT_CNT_MIN 60

/*
 * ##########################################################################
 * # Benutzte Kompressionsbibliothek für die LUT-Datei. Mögliche Werte:     #
 * #    COMPRESSION_NONE     keine Kompression                              #
 * #    COMPRESSION_ZLIB     zlib                                           #
 * #    COMPRESSION_BZIP2    bzip2                                          #
 * #    COMPRESSION_LZO      lzo                                            #
 * #                                                                        #
 * # Beim Lesen wird die benutzte Kompressionsmethode aus dem Klartext-     #
 * # Header gelesen; beim Schreiben wird normalerweise die zlib benutzt.    #
 * # Falls eine LUT-Datei mit einem anderen Kompressionsverfahren oder ohne #
 * # Kompression geschrieben werden soll, kann die Umstellung durch einen   #
 * # Aufruf der Funktion set_default_compression() erfolgen.                #
 * #                                                                        #
 * # Die Unterschiede der verschiedenen Kompressionsbibliotheken können im  #
 * # Detail der Datei 0test_compression.txt entnommen werden.               #
 * ##########################################################################
 */

#define COMPRESSION_NONE   1
#define COMPRESSION_ZLIB   2
#define COMPRESSION_BZIP2  3
#define COMPRESSION_LZO    4
#define COMPRESSION_LZMA   5

DLL_EXPORT int set_default_compression(int mode);

/*
 * ######################################################################
 * # kto_check(): Test eines Kontos                                     #
 * #              Diese Funktion stammt aus der alten Programmier-      #
 * #              schnittstelle und ist aus Kompatibilitätsgründen noch #
 * #              in der Library enthalten. Da alle möglichen Fälle     #
 * #              behandelt werden und Initialisierung und Test nicht   #
 * #              getrennt sind, hat diese Funktion im Vergleich zu dem #
 * #              neuen Interface einen relativ hohen Overhead, und     #
 * #              sollte durch die neuen Funktionen (s.u.) ersetzt      #
 * #              werden.                                               #
 * #                                                                    #
 * # Parameter: x_blz:      falls 2-stellig: Prüfziffer                 #
 * #                        falls 8-stellig: Bankleitzahl               #
 * #                                                                    #
 * #            kto:        Kontonummer (wird vor der Berechnung        #
 * #                        linksbündig mit Nullen auf 10 Stellen       #
 * #                        aufgefüllt)                                 #
 * #                                                                    #
 * #            lut_name:   Dateiname der Lookup-Tabelle.               #
 * #                        Falls NULL oder ein leerer String übergeben #
 * #                        wird, wird DEFAULT_LUT_NAME benutzt.        #
 * #                                                                    #
 * # Rückgabewerte: s.o.                                                #
 * ######################################################################
 */
DLL_EXPORT int kto_check(char *x_blz,char *kto,char *lut_name);
DLL_EXPORT int kto_check_t(char *x_blz,char *kto,char *lut_name,KTO_CHK_CTX *ctx);
DLL_EXPORT const char *kto_check_str(char *x_blz,char *kto,char *lut_name);

/* ###########################################################################
 * # Die Funktion kto_check_blz() ist die neue externe Schnittstelle zur     #
 * # Überprüfung einer BLZ/Kontonummer Kombination. Es wird grundsätzlich    #
 * # nur mit Bankleitzahlen gearbeitet; falls eine Prüfziffermethode direkt  #
 * # aufgerufen werden soll, ist stattdessen die Funktion kto_check_pz()     #
 * # zu benutzen.                                                            #
 * #                                                                         #
 * # Bei dem neuen Interface sind außerdem Initialisierung und Test          #
 * # getrennt. Vor einem Test ist (einmal) die Funktion kto_check_init()     #
 * # aufzurufen; diese Funktion liest die LUT-Datei und initialisiert einige #
 * # interne Variablen. Wenn diese Funktion nicht aufgerufen wurde, wird die #
 * # Fehlermeldung LUT2_NOT_INITIALIZED zurückgegeben.                       #
 * #                                                                         #
 * # Parameter:                                                              #
 * #    blz:        Bankleitzahl (immer 8-stellig)                           #
 * #    kto:        Kontonummer                                              #
 * #                                                                         #
 * # Copyright (C) 2007 Michael Plugge <m.plugge@hs-mannheim.de>             #
 * ###########################################################################
 */

DLL_EXPORT int kto_check_blz(char *blz,char *kto);
#if DEBUG>0
DLL_EXPORT int kto_check_blz_dbg(char *blz,char *kto,RETVAL *retvals);
#endif

/* ###########################################################################
 * # Die Funktion kto_check_pz() ist die neue externe Schnittstelle zur      #
 * # Überprüfung einer Prüfziffer/Kontonummer Kombination. Diese Funktion    #
 * # dient zum Test mit direktem Aufruf einer Prüfziffermethode. Bei dieser  #
 * # Funktion kann der Aufruf von kto_check_init() entfallen. Die BLZ wird   #
 * # bei einigen Methoden, die auf das ESER-Altsystem zurückgehen, benötigt  #
 * # (52, 53, B6, C0); ansonsten wird sie ignoriert.                         #
 * #                                                                         #
 * # Parameter:                                                              #
 * #    pz:         Prüfziffer (2- oder 3-stellig)                           #
 * #    blz:        Bankleitzahl (immer 8-stellig)                           #
 * #    kto:        Kontonummer                                              #
 * #                                                                         #
 * # Copyright (C) 2007 Michael Plugge <m.plugge@hs-mannheim.de>             #
 * ###########################################################################
 */

DLL_EXPORT int kto_check_pz(char *pz,char *kto,char *blz);
#if DEBUG>0
DLL_EXPORT int kto_check_pz_dbg(char *pz,char *kto,char *blz,RETVAL *retvals);
#endif

/* ###########################################################################
 * # Die Funktion kto_check_regel() entspricht der Funktion                  #
 * # kto_check_blz(). Der einzige Unterschied ist, daß vor dem Test geprüft  #
 * # wird, ob für die  BLZ/Konto-Kombination eine IBAN-Regel angewendet      #
 * # werden muß (z.B. bei Spendenkonten etc.). U.U. wird die BLZ und/oder    #
 * # Kontonummer ersetzt  und die Berechnung mit den modifizierten Werten    #
 * # gemacht. Die Werte für BLZ und Kontonummer werden nicht zurückgegeben;  #
 * # das kann mittels der Funktion kto_check_blz2() erfolgen.                #
 * #                                                                         #
 * # Die Funktion kto_check_regel_dbg() ist das Gegenstück zu                #
 * # kto_check_blz_dbg(); bei dieser Funktion werden zusätzlich noch einige  #
 * # interne Werte zurückgegeben. Die beiden Variablen blz2 und kto2         #
 * # müssen auf einen Speicherbereich von mindestens 9 bzw. 11 Byte zeigen;  #
 * # in diese Speicherbereiche werden die neue BLZ bzw. Kontonummer          #
 * # geschrieben. Praktischerweise sollten dies lokale Variablen der         #
 * # aufrufenden Funktion sein.                                              #
 * #                                                                         #
 * # Parameter:                                                              #
 * #    blz:        Bankleitzahl (immer 8-stellig)                           #
 * #    kto:        Kontonummer                                              #
 * #    blz2:       benutzte BLZ (evl. durch die Regeln modifiziert)         #
 * #    kto2:       benutzte Kontonummer (evl. modifiziert)                  #
 * #    bic:        BIC der benutzten Bank                                   #
 * #    Regel:      benutzte IBAN-Regel                                      #
 * #    retvals:    Struktur, in der die benutzte Prüfziffermethode und die  #
 * #                berechnete Prüfziffer zurückgegeben werden               #
 * #                                                                         #
 * # Copyright (C) 2013 Michael Plugge <m.plugge@hs-mannheim.de>             #
 * ###########################################################################
 */
DLL_EXPORT int kto_check_regel(char *blz,char *kto);
DLL_EXPORT int kto_check_regel_dbg(char *blz,char *kto,char *blz2,char *kto2,const char **bic,int *regel,RETVAL *retvals);

/*
 * ######################################################################
 * # cleanup_kto(): Aufräumarbeiten                                     #
 * #                                                                    #
 * # Die Funktion gibt allokierten Speicher frei und setzt die Variable #
 * # cnt_blz auf 0, um anzuzeigen, daß die Library bei Bedarf neu       #
 * # initialisiert werden muß.                                          #
 * #                                                                    #
 * # Rückgabewerte: 0: es war nichts zu tun (library wurde nicht init.) #
 * #                1: Aufräumen fertig                                 #
 * ######################################################################
 */
DLL_EXPORT int cleanup_kto(void);
DLL_EXPORT int cleanup_kto_t(KTO_CHK_CTX *ctx);

/*
 * ######################################################################
 * # generate_lut(): Lookup-Table generieren                            #
 * #                                                                    #
 * # Die Funktion generiert die Datei blz.lut, die alle Bankleitzahlen  #
 * # und die zugehörigen Prüfziffermethoden in komprimierter Form       #
 * # enthält.                                                           #
 * #                                                                    #
 * # Parameter: inputname:  Name der Bankleitzahlendatei der Deutschen  #
 * #                        Bundesbank (z.B. blz0303pc.txt)             #
 * #                                                                    #
 * #            outputname: Name der Zieldatei (z.B. blz.lut)           #
 * #                                                                    #
 * #            user_info:  Info-Zeile, die zusätzlich in die LUT-Datei #
 * #                        geschrieben wird. Diese Zeile wird von der  #
 * #                        Funktion get_lut_info() in zurückgegeben,   #
 * #                        aber ansonsten nicht ausgewertet.           #
 * #                                                                    #
 * #                                                                    #
 * #                                                                    #
 * #           lut_version: Format der LUT-Datei. Mögliche Werte:       #
 * #                        1: altes Format (1.0)                       #
 * #                        2: altes Format (1.1) mit Infozeile         #
 * #                        3: neues Format (2.0) mit Blocks            #
 * #                                                                    #
 * # Rückgabewerte:                                                     #
 * #    NO_BLZ_FILE          Bankleitzahlendatei nicht gefunden         #
 * #    FILE_WRITE_ERROR     kann Datei nicht schreiben (Schreibschutz?)#
 * #    OK                   Erfolg                                     #
 * ######################################################################
 */
DLL_EXPORT int generate_lut(char *inputname,char *outputname,char *user_info,int lut_version);

/*
 * ######################################################################
 * # get_lut_info(): Infozeile der LUT-Datei holen                      #
 * #                                                                    #
 * # Die Funktion holt die Infozeile(n) der LUT-Datei in einen          #
 * # statischen Speicherbereich und setzt die Variable info auf diesen  #
 * # Speicher. Diese Funktion wird erst ab Version 1.1 der LUT-Datei    #
 * # unterstützt.                                                       #
 * #                                                                    #
 * # Parameter:                                                         #
 * #    info:     Die Variable wird auf die Infozeile gesetzt           #
 * #    lut_name: Name der LUT-Datei                                    #
 * #                                                                    #
 * # Rückgabewerte: wie in read_lut():                                  #
 * #    ERROR_MALLOC       kann keinen Speicher allokieren              #
 * #    NO_LUT_FILE        LUT-Datei nicht gefunden (Pfad falsch?)      #
 * #    FATAL_ERROR        kann die LUT-Datei nicht lesen               #
 * #    INVALID_LUT_FILE   Fehler in der LUT-Datei (Format, CRC...)     #
 * #    OK                 Erfolg                                       #
 * ######################################################################
 */
DLL_EXPORT int get_lut_info(char **info,char *lut_name);
DLL_EXPORT int get_lut_info_t(char **info,char *lut_name,KTO_CHK_CTX *ctx);

/*
 * ######################################################################
 * # get_kto_check_version(): Version und Releasedate der library holen #
 * # Diese Funktion wird erst ab Version 1.1 der library unterstützt.   #
 * ######################################################################
 */
DLL_EXPORT const char *get_kto_check_version(void);
DLL_EXPORT const char *get_kto_check_version_x(int mode);

/*
 * ######################################################################
 * # kc_free(): Speicher freigeben (für das Perl-Modul)                 #
 * ######################################################################
 */
DLL_EXPORT void kc_free(char *ptr);

#if DEBUG>0
/* ###########################################################################
 * # Die Funktion kto_check_test_vars() macht nichts anderes, als die beiden #
 * # übergebenen Variablen txt und i auszugeben und als String zurückzugeben.#
 * # Sie kann für Debugzwecke benutzt werden, wenn Probleme mit Variablen in #
 * # der DLL auftreten; ansonsten ist sie nicht allzu nützlich.              #
 * #                                                                         #
 * # Parameter:                                                              #
 * #    txt:        Textvariable                                             #
 * #    i:          Integervariable (4 Byte)                                 #
 * #    ip:         Pointer auf Integerarray (4 Byte Integer-Werte)          #
 * ###########################################################################
 */
DLL_EXPORT char *kto_check_test_vars(char *txt,UINT4 i);
#endif

/*
 * ############################################################################
 * # set_verbose_debug(): zusätzliche Debugmeldungen einschalten (bei Bedarf) #
 * ############################################################################
 */
DLL_EXPORT int set_verbose_debug(int mode);

/*
 * ######################################################################
 * # public interface der lut2-Routinen                                 #
 * # Eine nähere Beschreibung findet sich momentan nur im C-Code, sie   #
 * # wird aber später nachgeliefert.                                    #
 * ######################################################################
 */
   /* public interface von lut2 */
DLL_EXPORT int create_lutfile(char *name, char *prolog, int slots);
DLL_EXPORT int write_lut_block(char *lutname,UINT4 typ,UINT4 len,char *data);
DLL_EXPORT int read_lut_block(char *lutname, UINT4 typ,UINT4 *blocklen,char **data);
DLL_EXPORT int read_lut_slot(char *lutname,int slot,UINT4 *blocklen,char **data);
DLL_EXPORT int lut_dir_dump(char *lutname,char *outputname);
DLL_EXPORT int lut_dir_dump_str(char *lutname,char **dptr);
DLL_EXPORT int lut_dir_dump_id(char *lutname,int *rv);
DLL_EXPORT int generate_lut2_p(char *inputname,char *outputname,char *user_info,char *gueltigkeit,
      UINT4 felder,UINT4 filialen,int slots,int lut_version,int set);
DLL_EXPORT int generate_lut2(char *inputname,char *outputname,const char *user_info,
      char *gueltigkeit,UINT4 *felder,UINT4 slots,UINT4 lut_version,UINT4 set);
DLL_EXPORT int copy_lutfile(char *old_name,char *new_name,int new_slots);
DLL_EXPORT int lut_init(char *lut_name,int required,int set);
DLL_EXPORT int kto_check_init(char *lut_name,int *required,int **status,int set,int incremental);
DLL_EXPORT int kto_check_init2(char *lut_name);
DLL_EXPORT int *lut2_status(void);
DLL_EXPORT int kto_check_init_p(char *lut_name,int required,int set,int incremental);
DLL_EXPORT int lut_info(char *lut_name,char **info1,char **info2,int *valid1,int *valid2);
DLL_EXPORT int lut_info_b(char *lut_name,char **info1,char **info2,int *valid1,int *valid2);
DLL_EXPORT int lut_info_id(char *lut_name,int *info1,int *info2,int *valid1,int *valid2);
DLL_EXPORT const char *current_lutfile_name(int *set,int *level,int *retval);
DLL_EXPORT int current_lutfile_name_id(int *set,int *level,int *retval);
DLL_EXPORT int lut_valid(void);
DLL_EXPORT int get_lut_info2(char *lut_name,int *version_p,char **prolog_p,char **info_p,char **user_info_p);
DLL_EXPORT int get_lut_info_b(char **info,char *lutname);
DLL_EXPORT int get_lut_info2_b(char *lutname,int *version,char **prolog_p,char **info_p,char **user_info_p);
DLL_EXPORT int get_lut_id(char *lut_name,int set,char *id);
DLL_EXPORT int rebuild_blzfile(char *inputname,char *outputname,UINT4 set);
DLL_EXPORT int dump_lutfile(char *outputname,UINT4 *required);
DLL_EXPORT int dump_lutfile_p(char *outputname,UINT4 felder);

   /* Universalfunktion, die Pointer auf die internen Variablen zurückliefert (von Haupt- und Nebenstellen) */
DLL_EXPORT int lut_multiple(char *b,int *cnt,int **p_blz,char ***p_name,char ***p_name_kurz,int **p_plz,char ***p_ort,
      int **p_pan,char ***p_bic,int *p_pz,int **p_nr,char **p_aenderung,char **p_loeschung,int **p_nachfolge_blz,
      int *id,int *cnt_all,int **start_idx);
DLL_EXPORT int lut_multiple_i(int b,int *cnt,int **p_blz,char ***p_name,char ***p_name_kurz,
      int **p_plz,char ***p_ort,int **p_pan,char ***p_bic,int *p_pz,int **p_nr,
      char **p_aenderung,char **p_loeschung,int **p_nachfolge_blz,int *id,
      int *cnt_all,int **start_idx);

   /* Funktionen, um einzelne Felder zu bestimmen (Rückgabe direkt) */
DLL_EXPORT int lut_blz(char *b,int zweigstelle);
DLL_EXPORT int lut_blz_i(int b,int zweigstelle);
DLL_EXPORT int lut_filialen(char *b,int *retval);
DLL_EXPORT int lut_filialen_i(int b,int *retval);
DLL_EXPORT const char *lut_name(char *b,int zweigstelle,int *retval);
DLL_EXPORT const char *lut_name_i(int b,int zweigstelle,int *retval);
DLL_EXPORT const char *lut_name_kurz(char *b,int zweigstelle,int *retval);
DLL_EXPORT const char *lut_name_kurz_i(int b,int zweigstelle,int *retval);
DLL_EXPORT int lut_plz(char *b,int zweigstelle,int *retval);
DLL_EXPORT int lut_plz_i(int b,int zweigstelle,int *retval);
DLL_EXPORT const char *lut_ort(char *b,int zweigstelle,int *retval);
DLL_EXPORT const char *lut_ort_i(int b,int zweigstelle,int *retval);
DLL_EXPORT int lut_pan(char *b,int zweigstelle,int *retval);
DLL_EXPORT int lut_pan_i(int b,int zweigstelle,int *retval);
DLL_EXPORT const char *lut_bic(char *b,int zweigstelle,int *retval);
DLL_EXPORT const char *lut_bic_i(int b,int zweigstelle,int *retval);
DLL_EXPORT const char *lut_bic_h(char *b,int zweigstelle,int *retval);
DLL_EXPORT const char *lut_bic_hi(int b,int zweigstelle,int *retval);
DLL_EXPORT int lut_nr(char *b,int zweigstelle,int *retval);
DLL_EXPORT int lut_nr_i(int b,int zweigstelle,int *retval);
DLL_EXPORT int lut_pz(char *b,int zweigstelle,int *retval);
DLL_EXPORT int lut_pz_i(int b,int zweigstelle,int *retval);
DLL_EXPORT int lut_aenderung(char *b,int zweigstelle,int *retval);
DLL_EXPORT int lut_aenderung_i(int b,int zweigstelle,int *retval);
DLL_EXPORT int lut_loeschung(char *b,int zweigstelle,int *retval);
DLL_EXPORT int lut_loeschung_i(int b,int zweigstelle,int *retval);
DLL_EXPORT int lut_nachfolge_blz(char *b,int zweigstelle,int *retval);
DLL_EXPORT int lut_nachfolge_blz_i(int b,int zweigstelle,int *retval);
DLL_EXPORT int lut_keine_iban_berechnung(char *iban_blacklist,char *lutfile,int set);
DLL_EXPORT int lut_iban_regel(char *b,int zweigstelle,int *retval);
DLL_EXPORT int lut_iban_regel_i(int b,int zweigstelle,int *retval);

DLL_EXPORT int bic_aenderung(char *bic_name,int mode,int filiale,int*retval);
DLL_EXPORT int bic_loeschung(char *bic_name,int mode,int filiale,int*retval);
DLL_EXPORT int bic_iban_regel(char *bic_name,int mode,int filiale,int*retval);
DLL_EXPORT int bic_nachfolge_blz(char *bic_name,int mode,int filiale,int*retval);
DLL_EXPORT int bic_nr(char *bic_name,int mode,int filiale,int*retval);
DLL_EXPORT int bic_pan(char *bic_name,int mode,int filiale,int*retval);
DLL_EXPORT int bic_plz(char *bic_name,int mode,int filiale,int*retval);
DLL_EXPORT int bic_pz(char *bic_name,int mode,int filiale,int*retval);
DLL_EXPORT const char *bic_bic(char *bic_name,int mode,int filiale,int*retval);
DLL_EXPORT const char *bic_bic_h(char *bic_name,int mode,int filiale,int*retval);
DLL_EXPORT const char *bic_name(char *bic_name,int mode,int filiale,int*retval);
DLL_EXPORT const char *bic_name_kurz(char *bic_name,int mode,int filiale,int*retval);
DLL_EXPORT const char *bic_ort(char *bic_name,int mode,int filiale,int*retval);

DLL_EXPORT int biq_aenderung(int idx,int*retval);
DLL_EXPORT int biq_loeschung(int idx,int*retval);
DLL_EXPORT int biq_iban_regel(int idx,int*retval);
DLL_EXPORT int biq_nachfolge_blz(int idx,int*retval);
DLL_EXPORT int biq_nr(int idx,int*retval);
DLL_EXPORT int biq_pan(int idx,int*retval);
DLL_EXPORT int biq_plz(int idx,int*retval);
DLL_EXPORT int biq_pz(int idx,int*retval);
DLL_EXPORT const char *biq_bic(int idx,int*retval);
DLL_EXPORT const char *biq_bic_h(int idx,int*retval);
DLL_EXPORT const char *biq_name(int idx,int*retval);
DLL_EXPORT const char *biq_name_kurz(int idx,int*retval);
DLL_EXPORT const char *biq_ort(int idx,int*retval);

DLL_EXPORT int iban_aenderung(char *iban,int filiale,int*retval);
DLL_EXPORT int iban_loeschung(char *iban,int filiale,int*retval);
DLL_EXPORT int iban_iban_regel(char *iban,int filiale,int*retval);
DLL_EXPORT int iban_nachfolge_blz(char *iban,int filiale,int*retval);
DLL_EXPORT int iban_nr(char *iban,int filiale,int*retval);
DLL_EXPORT int iban_pan(char *iban,int filiale,int*retval);
DLL_EXPORT int iban_plz(char *iban,int filiale,int*retval);
DLL_EXPORT int iban_pz(char *iban,int filiale,int*retval);
DLL_EXPORT const char *iban_bic(char *iban,int filiale,int*retval);
DLL_EXPORT const char *iban_bic_h(char *iban,int filiale,int*retval);
DLL_EXPORT const char *iban_name(char *iban,int filiale,int*retval);
DLL_EXPORT const char *iban_name_kurz(char *iban,int filiale,int*retval);
DLL_EXPORT const char *iban_ort(char *iban,int filiale,int*retval);

/*
 * ######################################################################
 * # Suche von Banken nach verschiedenen Kriterien                      #
 * ######################################################################
 */

#define LUT_SUCHE_VOLLTEXT    1
#define LUT_SUCHE_BIC         2
#define LUT_SUCHE_NAMEN       3
#define LUT_SUCHE_NAMEN_KURZ  4
#define LUT_SUCHE_ORT         5
#define LUT_SUCHE_BLZ         6
#define LUT_SUCHE_PLZ         7
#define LUT_SUCHE_PZ          8
#define LUT_SUCHE_REGEL       9
#define LUT_SUCHE_BIC_H      10

   /* Defaultwert für sort/uniq bei Suchfunktionen (=> nur eine Zweigstelle
    * zurückgeben) (betrifft nur PHP, Perl und Ruby, bei denen der Parameter
    * weggelassen werden kann).
    *
    * Für Perl gibt es eine eigene Definition, da sort und uniq bis einschließlich
    * Version 4.1 nicht unterstützt wurden. Mit der Standarddefinition von
    * UNIQ_DEFAULT (2) würde sich eine Änderung im Verhalten ergeben,
    * die so nicht erwünscht ist.
    */
#define UNIQ_DEFAULT 2
#define UNIQ_DEFAULT_PERL 0

DLL_EXPORT int kto_check_idx2blz(int idx,int *zweigstelle,int *retval);
DLL_EXPORT int konto_check_idx2blz(int idx,int *zweigstelle,int *retval);
DLL_EXPORT int lut_suche_bic(char *such_name,int *anzahl,int **start_idx,int **zweigstellen_base,char ***base_name,int **blz_base);
DLL_EXPORT int lut_suche_bic_h(char *such_name,int *anzahl,int **start_idx,int **zweigstellen_base,char ***base_name,int **blz_base);
DLL_EXPORT int lut_suche_namen(char *such_name,int *anzahl,int **start_idx,int **zweigstellen_base,char ***base_name,int **blz_base);
DLL_EXPORT int lut_suche_namen_kurz(char *such_name,int *anzahl,int **start_idx,int **zweigstellen_base,char ***base_name,int **blz_base);
DLL_EXPORT int lut_suche_ort(char *such_name,int *anzahl,int **start_idx,int **zweigstellen_base,char ***base_name,int **blz_base);
DLL_EXPORT int lut_suche_blz(int such1,int such2,int *anzahl,int **start_idx,int **zweigstellen_base,int **base_name,int **blz_base);
DLL_EXPORT int lut_suche_pz(int such1,int such2,int *anzahl,int **start_idx,int **zweigstellen_base,int **base_name,int **blz_base);
DLL_EXPORT int lut_suche_plz(int such1,int such2,int *anzahl,int **start_idx,int **zweigstellen_base,int **base_name,int **blz_base);
DLL_EXPORT int lut_suche_regel(int such1,int such2,int *anzahl,int **start_idx,int **zweigstellen_base,int **base_name,int **blz_base);
DLL_EXPORT int lut_suche_volltext(char *such_wort,int *anzahl,int *base_name_idx,char ***base_name,int *zweigstellen_anzahl,int **start_idx,int **zweigstellen_base,int **blz_base);
DLL_EXPORT int lut_suche_multiple(char *such_worte,int uniq,char *such_cmd,UINT4 *anzahl,UINT4 **zweigstellen,UINT4 **blz);
DLL_EXPORT int lut_suche_sort1(int anzahl,int *blz_base,int *zweigstellen_base,int *idx,int *anzahl_o,int **idx_op,int **cnt_o,int uniq);
DLL_EXPORT int lut_suche_sort2(int anzahl,int *blz,int *zweigstellen,int *anzahl_o,int **blz_op,int **zweigstellen_op,int **cnt_o,int uniq);
DLL_EXPORT int lut_suche_init(int uniq);
DLL_EXPORT int lut_suche_free(int id);
DLL_EXPORT int lut_suche_set(int such_id,int idx,int typ,int i1,int i2,char *txt);
DLL_EXPORT int lut_suche(int such_id,char *such_cmd,UINT4 *such_cnt,UINT4 **filiale,UINT4 **blz);
DLL_EXPORT int lut_blocks(int mode,char **lut_filename,char **lut_blocks_ok,char **lut_blocks_fehler);
DLL_EXPORT int lut_blocks_id(int mode,int *lut_filename,int *lut_blocks_ok,int *lut_blocks_fehler);

   /* (Benutzerdefinierte) Default-Werte in der LUT-Datei lesen und schreiben */
#define DEFAULT_CNT 50                 /* Anzahl Einträge (fest) */

DLL_EXPORT int kto_check_init_default(char *lut_name,int block_id);
DLL_EXPORT int kto_check_default_keys(char ***keys,int *cnt);
DLL_EXPORT int kto_check_set_default(char *key,char *val);
DLL_EXPORT int kto_check_set_default_bin(char *key,char *val,int size);
DLL_EXPORT int kto_check_get_default(char *key,char **val,int *size);
DLL_EXPORT int kto_check_write_default(char *lutfile,int block_id);

   /* Aufräumarbeiten */
DLL_EXPORT int lut_cleanup(void);

   /* IBAN-Sachen */
DLL_EXPORT int ci_check(char *ci);
DLL_EXPORT int bic_check(char *search_bic,int *cnt);
DLL_EXPORT int iban_check(char *iban,int *retval);
DLL_EXPORT const char *iban2bic(char *iban,int *retval,char *blz,char *kto);
DLL_EXPORT const char *iban2bic_id(char *iban,int *retval,int *blz,int *kto);
DLL_EXPORT char *iban_gen(char *kto,char *blz,int *retval);
DLL_EXPORT char *iban_bic_gen(char *blz,char *kto,const char **bicp,char *blz2,char *kto2,int *retval);
DLL_EXPORT char *iban_bic_gen1(char *blz,char *kto,const char **bicp,int *retval);
DLL_EXPORT int ipi_gen(char *zweck,char *dst,char *papier);
DLL_EXPORT int iban_gen_id(char *blz,char *kto,int *retval);
DLL_EXPORT int ipi_gen_id(char *zweck,int *dst,int *papier);
DLL_EXPORT int iban_bic_gen_id(char *blz,char *kto,int *bic2,int *blz2,int *kto2,int *retval);
DLL_EXPORT int ipi_check(char *zweck);

   /* BIC-Funktionen */
DLL_EXPORT int bic_info(char *bic_name,int mode,int *anzahl,int *start_idx);

   /* Rückgabewerte in Klartext umwandeln */
DLL_EXPORT int kto_check_encoding(int mode);
DLL_EXPORT int keep_raw_data(int mode);
DLL_EXPORT const char *kto_check_encoding_str(int mode);
DLL_EXPORT const char *kto_check_retval2txt(int retval);
DLL_EXPORT const char *kto_check_retval2iso(int retval);
DLL_EXPORT const char *kto_check_retval2txt_short(int retval);
DLL_EXPORT const char *kto_check_retval2html(int retval);
DLL_EXPORT const char *kto_check_retval2utf8(int retval);
DLL_EXPORT const char *kto_check_retval2dos(int retval);

   /* Prüfziffer (numerisch) in String umwandeln */
const DLL_EXPORT char *pz2str(int pz,int *ret);

   /* Flag für neue Prüfziffermethoden setzen bzw. abfragen */
DLL_EXPORT int pz_aenderungen_enable(int set);


   /* Funktionen für Strings mit Rückgabe per handle */
DLL_EXPORT char *kc_id2ptr(int handle,int *retval);
DLL_EXPORT int kc_id_free(int handle);

   /* Handle-Varianten für Funktionen mit Stringkonstanten als Rückgabewert */
DLL_EXPORT int kto_check_encoding_str_id(int mode);
DLL_EXPORT int kto_check_retval2txt_id(int retval);
DLL_EXPORT int kto_check_retval2txt_short_id(int retval);
DLL_EXPORT int kto_check_retval2html_id(int retval);
DLL_EXPORT int kto_check_retval2dos_id(int retval);
DLL_EXPORT int kto_check_retval2utf8_id(int retval);
DLL_EXPORT int get_kto_check_version_id(int mode);

DLL_EXPORT int lut_name_id(char *b,int zweigstelle,int *retval);
DLL_EXPORT int lut_name_i_id(int b,int zweigstelle,int *retval);
DLL_EXPORT int lut_name_kurz_id(char *b,int zweigstelle,int *retval);
DLL_EXPORT int lut_name_kurz_i_id(int b,int zweigstelle,int *retval);
DLL_EXPORT int lut_ort_id(char *b,int zweigstelle,int *retval);
DLL_EXPORT int lut_ort_i_id(int b,int zweigstelle,int *retval);
DLL_EXPORT int lut_bic_id(char *b,int zweigstelle,int *retval);
DLL_EXPORT int lut_bic_i_id(int b,int zweigstelle,int *retval);
DLL_EXPORT int lut_bic_h_id(char *b,int zweigstelle,int *retval);
DLL_EXPORT int lut_bic_hi_id(int b,int zweigstelle,int *retval);

DLL_EXPORT int bic_bic_id(char *bic_name,int mode,int filiale,int*retval);
DLL_EXPORT int bic_bic_h_id(char *bic_name,int mode,int filiale,int*retval);
DLL_EXPORT int bic_name_id(char *bic_name,int mode,int filiale,int*retval);
DLL_EXPORT int bic_name_kurz_id(char *bic_name,int mode,int filiale,int*retval);
DLL_EXPORT int bic_ort_id(char *bic_name,int mode,int filiale,int*retval);

DLL_EXPORT int biq_bic_id(int idx,int*retval);
DLL_EXPORT int biq_bic_h_id(int idx,int*retval);
DLL_EXPORT int biq_name_id(int idx,int*retval);
DLL_EXPORT int biq_name_kurz_id(int idx,int*retval);
DLL_EXPORT int biq_ort_id(int idx,int*retval);

DLL_EXPORT int iban_bic_id(char *iban,int filiale,int*retval);
DLL_EXPORT int iban_bic_h_id(char *iban,int filiale,int*retval);
DLL_EXPORT int iban_name_id(char *iban,int filiale,int*retval);
DLL_EXPORT int iban_name_kurz_id(char *iban,int filiale,int*retval);
DLL_EXPORT int iban_ort_id(char *iban,int filiale,int*retval);

/*
 * ######################################################################
 * #               globale Variablen                                    #
 * ######################################################################
 */

#ifndef KONTO_CHECK_VARS
#if DEBUG>0
   /* "aktuelles" Datum für die Testumgebung (um einen Datumswechsel zu simulieren) */
DLL_EXPORT_V extern UINT4 current_date;
#endif

   /* String mit den LUT-Blocks, die nicht geladen werden konnten */
DLL_EXPORT_V extern char *lut_blocks_missing;

/*
 * ######################################################################
 * # die folgenden globalen Variablen waren in Version 1 und 2 von      #
 * # konto_check definiert; ab Version 3 werden sie nicht mehr unter-   #
 * # stützt. Zur Vermeidung von Linker-Fehlermeldungen können jedoch    #
 * # Dummyversionen eingebunden werden (ohne Funktionalität).           #
 * ######################################################################
 */

#if INCLUDE_DUMMY_GLOBALS>0
DLL_EXPORT_V extern const char *kto_check_msg;  /* globaler char-ptr mit Klartext-Ergebnis des Tests */
DLL_EXPORT_V extern const char pz_str[];        /* benutzte Prüfziffer-Methode und -Untermethode (als String) */
DLL_EXPORT_V extern int pz_methode;             /* pz_methode: benutzte Prüfziffer-Methode (numerisch) */
#if DEBUG>0
DLL_EXPORT_V extern int pz;                     /* Prüfziffer (bei DEBUG als globale Variable für Testzwecke) */
#endif   /* DEBUG */
#endif   /* INCLUDE_DUMMY_GLOBALS */
#endif   /* KONTO_CHECK_VARS */
#endif   /* KONTO_CHECK_H_INCLUDED */
