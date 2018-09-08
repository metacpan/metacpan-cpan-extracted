/* vim: ft=c:set si:set fileencoding=iso-8859-1
 */

/*
 * ##########################################################################
 * #  Diese Datei gehört zur konto_check Bibliothek. Sie enthält einige     #
 * #  Rückgabewerte in verschiedenen Kodierungen (ISO-8859-1, UTF-8,        #
 * #  DOS CP850); falls die Datei konto_check.c (bzw. konto_check.h) nach   #
 * #  UTF-8 umkodiert wird, sollten diese Werte erhalten bleiben, damit die #
 * #  Funktionen auch weiterhin so funktionieren wie sie sollen... Die      #
 * #  anderen Dateien sollten sich ohne Problem nach UTF-8 umkodieren       #
 * #  lassen.                                                               #
 * #                                                                        #
 * #  Dies ist eigentlich keine Header-Datei; aber da einige Build-Tools    #
 * #  meinen, sie müssten aus jeder .c-Datei auch eine Objekt-Datei         #
 * #  generieren, wurde sie umgetauft auf retvals.h                         #
 * #                                                                        #
 * #  Copyright (C) 2002-2014 Michael Plugge <m.plugge@hs-mannheim.de>      #
 * #                                                                        #
 * ##########################################################################
 */

/* Funktion kto_check_retval2txt() +§§§1 */
/* ###########################################################################
 * # Die Funktion kto_check_retval2txt() wandelt die numerischen Rückgabe-   #
 * # werte in Klartext um. Die Funktion kto_check_retval2txt_short macht     #
 * # dasselbe, nur mit mehr symbolischen Klartexten (kurz).                  #
 * #                                                                         #
 * # Copyright (C) 2007 Michael Plugge <m.plugge@hs-mannheim.de>             #
 * ###########################################################################
 */

DLL_EXPORT const char *kto_check_retval2txt(int retval)
{
   if(!retval_enc)kto_check_encoding(DEFAULT_ENCODING);
   return (*retval_enc)(retval);
}

/* Funktion kto_check_retval2iso() +§§§1 */
/* ###########################################################################
 * # Die Funktion kto_check_retval2iso() wandelt die numerischen Rückgabe-   #
 * # werte in Klartext mit den Umlauten in der Kodierung ISO-8859-1 um.      #
 * #                                                                         #
 * # Copyright (C) 2007 Michael Plugge <m.plugge@hs-mannheim.de>             #
 * ###########################################################################
 */

DLL_EXPORT const char *kto_check_retval2iso(int retval)
{
   switch(retval){
      case NO_SCL_BLOCKS_LOADED: return "die SCL-Blocks wurden noch nicht eingelesen";
      case NO_SCL_INFO_BLOCK: return "Der Info-Block des SCL-Verzeichnisses wurde noch nicht eingelesen";
      case SCL_BIC_NOT_FOUND: return "Der BIC wurde im SCL-Verzeichnis nicht gefunden";
      case INVALID_SCL_INFO_BLOCK: return "Ungültiger SCL-Info-Block in der LUT-Datei";
      case NO_SCL_BLOCKS: return "Keine SCL-Blocks in der LUT-Datei enthalten";
      case SCL_INPUT_FORMAT_ERROR: return "Ungültige Eingabewerte in der SCL-Datei";
      case INVALID_REGULAR_EXPRESSION_CNT: return "Ungültiger Zähler in regulärem Ausdruck (innerhalb von {})";
      case INVALID_REGULAR_EXPRESSION: return "Ungültiger regulärer Ausdruck (enthält zwei Zeichen aus [+?*] nacheinander)";
      case INVALID_HANDLE: return "Ungültiges Handle angegeben";
      case INVALID_BIQ_INDEX: return "Ungültiger Index für die biq_*() Funktionen";
      case ARRAY_INDEX_OUT_OF_RANGE: return "Der Array-Index liegt außerhalb des gültigen Bereichs";
      case IBAN_ONLY_GERMAN: return "Es werden nur deutsche IBANs unterstützt";
      case INVALID_PARAMETER_TYPE: return "Falscher Parametertyp für die Funktion";
      case BIC_ONLY_GERMAN: return "Es werden nur deutsche BICs unterstützt";
      case INVALID_BIC_LENGTH: return "Die Länge des BIC muß genau 8 oder 11 Zeichen sein";
      case IBAN_CHKSUM_OK_RULE_IGNORED_BLZ: return "Die IBAN-Prüfsumme stimmt, die BLZ sollte aber durch eine zentrale BLZ ersetzt werden. Die Richtigkeit der IBAN kann nur mit einer Anfrage bei der Bank ermittelt werden";
      case IBAN_CHKSUM_OK_KC_NOT_INITIALIZED: return "Die IBAN-Prüfsumme stimmt, konto_check wurde jedoch noch nicht initialisiert (Kontoprüfung nicht möglich)";
      case IBAN_CHKSUM_OK_BLZ_INVALID: return "Die IBAN-Prüfsumme stimmt, die BLZ ist allerdings ungültig";
      case IBAN_CHKSUM_OK_NACHFOLGE_BLZ_DEFINED: return "Die IBAN-Prüfsumme stimmt, für die Bank gibt es allerdings eine (andere) Nachfolge-BLZ";
      case LUT2_NOT_ALL_IBAN_BLOCKS_LOADED: return "es konnten nicht alle Datenblocks die für die IBAN-Berechnung notwendig sind geladen werden";
      case LUT2_NOT_YET_VALID_PARTIAL_OK: return "Der Datensatz ist noch nicht gültig, außerdem konnten nicht alle Blocks geladen werden";
      case LUT2_NO_LONGER_VALID_PARTIAL_OK: return "Der Datensatz ist nicht mehr gültig, außerdem konnten nicht alle Blocks geladen werdeng";
      case LUT2_BLOCKS_MISSING: return "ok, bei der Initialisierung konnten allerdings ein oder mehrere Blocks nicht geladen werden";
      case FALSE_UNTERKONTO_ATTACHED: return "falsch, es wurde ein Unterkonto hinzugefügt (IBAN-Regel)";
      case BLZ_BLACKLISTED: return "Die BLZ findet sich in der Ausschlussliste für IBAN-Berechnungen";
      case BLZ_MARKED_AS_DELETED: return "Die BLZ ist in der Bundesbank-Datei als gelöscht markiert und somit ungültig";
      case IBAN_CHKSUM_OK_SOMETHING_WRONG: return "Die IBAN-Prüfsumme stimmt, es gibt allerdings einen Fehler in der eigenen IBAN-Bestimmung (wahrscheinlich falsch)";
      case IBAN_CHKSUM_OK_NO_IBAN_CALCULATION: return "Die IBAN-Prüfsumme stimmt. Die Bank gibt IBANs nach nicht veröffentlichten Regeln heraus, die Richtigkeit der IBAN kann nur mit einer Anfrage bei der Bank ermittelt werden";
      case IBAN_CHKSUM_OK_RULE_IGNORED: return "Die IBAN-Prüfsumme stimmt, es wurde allerdings eine IBAN-Regel nicht beachtet (wahrscheinlich falsch)";
      case IBAN_CHKSUM_OK_UNTERKTO_MISSING: return "Die IBAN-Prüfsumme stimmt, es fehlt aber ein Unterkonto (wahrscheinlich falsch)";
      case IBAN_INVALID_RULE: return "Die BLZ passt nicht zur angegebenen IBAN-Regel";
      case IBAN_AMBIGUOUS_KTO: return "Die Kontonummer ist nicht eindeutig (es gibt mehrere Möglichkeiten)";
      case IBAN_RULE_NOT_IMPLEMENTED: return "Die IBAN-Regel ist noch nicht implementiert";
      case IBAN_RULE_UNKNOWN: return "Die IBAN-Regel ist nicht bekannt";
      case NO_IBAN_CALCULATION: return "Für die Bankverbindung ist keine IBAN-Berechnung erlaubt";
      case OLD_BLZ_OK_NEW_NOT: return "Die Bankverbindung ist mit der alten BLZ stimmig, mit der Nachfolge-BLZ nicht";
      case LUT2_IBAN_REGEL_NOT_INITIALIZED: return "Das Feld IBAN-Regel wurde nicht initialisiert";
      case INVALID_IBAN_LENGTH: return "Die Länge der IBAN für das angegebene Länderkürzel ist falsch";
      case LUT2_NO_ACCOUNT_GIVEN: return "Keine Bankverbindung/IBAN angegeben";
      case LUT2_VOLLTEXT_INVALID_CHAR: return "Ungültiges Zeichen ( ()+-/&.,\' ) für die Volltextsuche gefunden";
      case LUT2_VOLLTEXT_SINGLE_WORD_ONLY: return "Die Volltextsuche sucht jeweils nur ein einzelnes Wort, benutzen Sie lut_suche_multiple() zur Suche nach mehreren Worten";
      case LUT_SUCHE_INVALID_RSC: return "die angegebene Suchresource ist ungültig";
      case LUT_SUCHE_INVALID_CMD: return "bei der Suche sind im Verknüpfungsstring nur die Zeichen a-z sowie + und - erlaubt";
      case LUT_SUCHE_INVALID_CNT: return "bei der Suche müssen zwischen 1 und 26 Suchmuster angegeben werden";
      case LUT2_VOLLTEXT_NOT_INITIALIZED: return "Das Feld Volltext wurde nicht initialisiert";
      case NO_OWN_IBAN_CALCULATION: return "das Institut erlaubt keine eigene IBAN-Berechnung";
      case KTO_CHECK_UNSUPPORTED_COMPRESSION: return "die notwendige Kompressions-Bibliothek wurde beim Kompilieren nicht eingebunden";
      case KTO_CHECK_INVALID_COMPRESSION_LIB: return "der angegebene Wert für die Default-Kompression ist ungültig";
      case OK_UNTERKONTO_ATTACHED_OLD: return "(nicht mehr als Fehler, sondern positive Ausgabe - Dummy für den alten Wert)";
      case KTO_CHECK_DEFAULT_BLOCK_INVALID: return "Ungültige Signatur im Default-Block";
      case KTO_CHECK_DEFAULT_BLOCK_FULL: return "Die maximale Anzahl Einträge für den Default-Block wurde erreicht";
      case KTO_CHECK_NO_DEFAULT_BLOCK: return "Es wurde noch kein Default-Block angelegt";
      case KTO_CHECK_KEY_NOT_FOUND: return "Der angegebene Schlüssel wurde im Default-Block nicht gefunden";
      case LUT2_NO_LONGER_VALID_BETTER: return "Beide Datensätze sind nicht mehr gültig, dieser ist aber jünger als der andere";
      case INVALID_SEARCH_RANGE: return "ungültiger Suchbereich angegeben (unten>oben)";
      case KEY_NOT_FOUND: return "Die Suche lieferte kein Ergebnis";
      case BAV_FALSE: return "BAV denkt, das Konto ist falsch (konto_check hält es für richtig)";
      case LUT2_NO_USER_BLOCK: return "User-Blocks müssen einen Typ > 500 haben";
      case INVALID_SET: return "für ein LUT-Set sind nur die Werte 0, 1 oder 2 möglich";
      case NO_GERMAN_BIC: return "Ein Konto kann kann nur für deutsche Banken geprüft werden";
      case IPI_CHECK_INVALID_LENGTH: return "Der zu validierende strukturierete Verwendungszweck muß genau 20 Zeichen enthalten";
      case IPI_INVALID_CHARACTER: return "Im strukturierten Verwendungszweck dürfen nur alphanumerische Zeichen vorkommen";
      case IPI_INVALID_LENGTH: return "Die Länge des IPI-Verwendungszwecks darf maximal 18 Byte sein";
      case LUT1_FILE_USED: return "Es wurde eine LUT-Datei im Format 1.0/1.1 geladen";
      case MISSING_PARAMETER: return "Für die aufgerufene Funktion fehlt ein notwendiger Parameter";
      case IBAN2BIC_ONLY_GERMAN: return "Die Funktion iban2bic() arbeitet nur mit deutschen Bankleitzahlen";
      case IBAN_OK_KTO_NOT: return "Die Prüfziffer der IBAN stimmt, die der Kontonummer nicht";
      case KTO_OK_IBAN_NOT: return "Die Prüfziffer der Kontonummer stimmt, die der IBAN nicht";
      case TOO_MANY_SLOTS: return "Es sind nur maximal 500 Slots pro LUT-Datei möglich (Neukompilieren erforderlich)";
      case INIT_FATAL_ERROR: return "Initialisierung fehlgeschlagen (init_wait geblockt)";
      case INCREMENTAL_INIT_NEEDS_INFO: return "Ein inkrementelles Initialisieren benötigt einen Info-Block in der LUT-Datei";
      case INCREMENTAL_INIT_FROM_DIFFERENT_FILE: return "Ein inkrementelles Initialisieren mit einer anderen LUT-Datei ist nicht möglich";
      case DEBUG_ONLY_FUNCTION: return "Die Funktion ist nur in der Debug-Version vorhanden";
      case LUT2_INVALID: return "Kein Datensatz der LUT-Datei ist aktuell gültig";
      case LUT2_NOT_YET_VALID: return "Der Datensatz ist noch nicht gültig";
      case LUT2_NO_LONGER_VALID: return "Der Datensatz ist nicht mehr gültig";
      case LUT2_GUELTIGKEIT_SWAPPED: return "Im Gültigkeitsdatum sind Anfangs- und Enddatum vertauscht";
      case LUT2_INVALID_GUELTIGKEIT: return "Das angegebene Gültigkeitsdatum ist ungültig (Sollformat ist JJJJMMTT-JJJJMMTT)";
      case LUT2_INDEX_OUT_OF_RANGE: return "Der Index für die Filiale ist ungültig";
      case LUT2_INIT_IN_PROGRESS: return "Die Bibliothek wird gerade neu initialisiert";
      case LUT2_BLZ_NOT_INITIALIZED: return "Das Feld BLZ wurde nicht initialisiert";
      case LUT2_FILIALEN_NOT_INITIALIZED: return "Das Feld Filialen wurde nicht initialisiert";
      case LUT2_NAME_NOT_INITIALIZED: return "Das Feld Bankname wurde nicht initialisiert";
      case LUT2_PLZ_NOT_INITIALIZED: return "Das Feld PLZ wurde nicht initialisiert";
      case LUT2_ORT_NOT_INITIALIZED: return "Das Feld Ort wurde nicht initialisiert";
      case LUT2_NAME_KURZ_NOT_INITIALIZED: return "Das Feld Kurzname wurde nicht initialisiert";
      case LUT2_PAN_NOT_INITIALIZED: return "Das Feld PAN wurde nicht initialisiert";
      case LUT2_BIC_NOT_INITIALIZED: return "Das Feld BIC wurde nicht initialisiert";
      case LUT2_PZ_NOT_INITIALIZED: return "Das Feld Prüfziffer wurde nicht initialisiert";
      case LUT2_NR_NOT_INITIALIZED: return "Das Feld NR wurde nicht initialisiert";
      case LUT2_AENDERUNG_NOT_INITIALIZED: return "Das Feld Änderung wurde nicht initialisiert";
      case LUT2_LOESCHUNG_NOT_INITIALIZED: return "Das Feld Löschung wurde nicht initialisiert";
      case LUT2_NACHFOLGE_BLZ_NOT_INITIALIZED: return "Das Feld Nachfolge-BLZ wurde nicht initialisiert";
      case LUT2_NOT_INITIALIZED: return "die Programmbibliothek wurde noch nicht initialisiert";
      case LUT2_FILIALEN_MISSING: return "der Block mit der Filialenanzahl fehlt in der LUT-Datei";
      case LUT2_PARTIAL_OK: return "es wurden nicht alle Blocks geladen";
      case LUT2_Z_BUF_ERROR: return "Buffer error in den ZLIB Routinen";
      case LUT2_Z_MEM_ERROR: return "Memory error in den ZLIB-Routinen";
      case LUT2_Z_DATA_ERROR: return "Datenfehler im komprimierten LUT-Block";
      case LUT2_BLOCK_NOT_IN_FILE: return "Der Block ist nicht in der LUT-Datei enthalten";
      case LUT2_DECOMPRESS_ERROR: return "Fehler beim Dekomprimieren eines LUT-Blocks";
      case LUT2_COMPRESS_ERROR: return "Fehler beim Komprimieren eines LUT-Blocks";
      case LUT2_FILE_CORRUPTED: return "Die LUT-Datei ist korrumpiert";
      case LUT2_NO_SLOT_FREE: return "Im Inhaltsverzeichnis der LUT-Datei ist kein Slot mehr frei";
      case UNDEFINED_SUBMETHOD: return "Die (Unter)Methode ist nicht definiert";
      case EXCLUDED_AT_COMPILETIME: return "Der benötigte Programmteil wurde beim Kompilieren deaktiviert";
      case INVALID_LUT_VERSION: return "Die Versionsnummer für die LUT-Datei ist ungültig";
      case INVALID_PARAMETER_STELLE1: return "ungültiger Prüfparameter (erste zu prüfende Stelle)";
      case INVALID_PARAMETER_COUNT: return "ungültiger Prüfparameter (Anzahl zu prüfender Stellen)";
      case INVALID_PARAMETER_PRUEFZIFFER: return "ungültiger Prüfparameter (Position der Prüfziffer)";
      case INVALID_PARAMETER_WICHTUNG: return "ungültiger Prüfparameter (Wichtung)";
      case INVALID_PARAMETER_METHODE: return "ungültiger Prüfparameter (Rechenmethode)";
      case LIBRARY_INIT_ERROR: return "Problem beim Initialisieren der globalen Variablen";
      case LUT_CRC_ERROR: return "Prüfsummenfehler in der blz.lut Datei";
      case FALSE_GELOESCHT: return "falsch (die BLZ wurde außerdem gelöscht)";
      case OK_NO_CHK_GELOESCHT: return "ok, ohne Prüfung (die BLZ wurde allerdings gelöscht)";
      case OK_GELOESCHT: return "ok (die BLZ wurde allerdings gelöscht)";
      case BLZ_GELOESCHT: return "die Bankleitzahl wurde gelöscht";
      case INVALID_BLZ_FILE: return "Fehler in der blz.txt Datei (falsche Zeilenlänge)";
      case LIBRARY_IS_NOT_THREAD_SAFE: return "undefinierte Funktion, die library wurde mit THREAD_SAFE=0 kompiliert";
      case FATAL_ERROR: return "schwerer Fehler im Konto_check-Modul";
      case INVALID_KTO_LENGTH: return "ein Konto muß zwischen 1 und 10 Stellen haben";
      case FILE_WRITE_ERROR: return "kann Datei nicht schreiben";
      case FILE_READ_ERROR: return "kann Datei nicht lesen";
      case ERROR_MALLOC: return "kann keinen Speicher allokieren";
      case NO_BLZ_FILE: return "die blz.txt Datei wurde nicht gefunden";
      case INVALID_LUT_FILE: return "die blz.lut Datei ist inkosistent/ungültig";
      case NO_LUT_FILE: return "die blz.lut Datei wurde nicht gefunden";
      case INVALID_BLZ_LENGTH: return "die Bankleitzahl ist nicht achtstellig";
      case INVALID_BLZ: return "die Bankleitzahl ist ungültig";
      case INVALID_KTO: return "das Konto ist ungültig";
      case NOT_IMPLEMENTED: return "die Methode wurde noch nicht implementiert";
      case NOT_DEFINED: return "die Methode ist nicht definiert";
      case FALSE: return "falsch";
      case OK: return "ok";
      case EE: if(eep)return (char *)eep; else return "";
      case OK_NO_CHK: return "ok, ohne Prüfung";
      case OK_TEST_BLZ_USED: return "ok, für den Test wurde eine Test-BLZ verwendet";
      case LUT2_VALID: return "Der Datensatz ist aktuell gültig";
      case LUT2_NO_VALID_DATE: return "Der Datensatz enthält kein Gültigkeitsdatum";
      case LUT1_SET_LOADED: return "Die Datei ist im alten LUT-Format (1.0/1.1)";
      case LUT1_FILE_GENERATED: return "ok, es wurde allerdings eine LUT-Datei im alten Format (1.0/1.1) generiert";
      case LUT_V2_FILE_GENERATED: return "ok, es wurde allerdings eine LUT-Datei im Format 2.0 generiert (Compilerswitch)";
      case KTO_CHECK_VALUE_REPLACED: return "ok, der Wert für den Schlüssel wurde überschrieben";
      case OK_UNTERKONTO_POSSIBLE: return "wahrscheinlich ok, die Kontonummer kann allerdings (nicht angegebene) Unterkonten enthalten";
      case OK_UNTERKONTO_GIVEN: return "wahrscheinlich ok, die Kontonummer enthält eine Unterkontonummer";
      case OK_SLOT_CNT_MIN_USED: return "ok, die Anzahl Slots wurde auf SLOT_CNT_MIN (60) hochgesetzt";
      case SOME_KEYS_NOT_FOUND: return "ok, ein(ige) Schlüssel wurden nicht gefunden";
      case LUT2_KTO_NOT_CHECKED: return "Die Bankverbindung wurde nicht getestet";
      case LUT2_OK_WITHOUT_IBAN_RULES: return "Es wurden fast alle Blocks (außer den IBAN-Regeln) geladen";
      case OK_NACHFOLGE_BLZ_USED: return "ok, für die BLZ wurde allerdings die Nachfolge-BLZ eingesetzt";
      case OK_KTO_REPLACED: return "ok, die Kontonummer wurde allerdings ersetzt";
      case OK_BLZ_REPLACED: return "ok, die Bankleitzahl wurde allerdings ersetzt";
      case OK_BLZ_KTO_REPLACED: return "ok, die Bankleitzahl und Kontonummer wurden allerdings ersetzt";
      case OK_IBAN_WITHOUT_KC_TEST: return "ok, die Bankverbindung ist (ohne Test) als richtig anzusehen";
      case OK_INVALID_FOR_IBAN: return "ok, für die die IBAN ist (durch eine Regel) allerdings ein anderer BIC definiert";
      case OK_HYPO_REQUIRES_KTO: return "ok, für die BIC-Bestimmung der ehemaligen Hypo-Bank für IBAN wird i.A. zusätzlich die Kontonummer benötigt";
      case OK_KTO_REPLACED_NO_PZ: return "ok, die Kontonummer wurde ersetzt, die neue Kontonummer hat keine Prüfziffer";
      case OK_UNTERKONTO_ATTACHED: return "ok, es wurde ein (weggelassenes) Unterkonto angefügt";
      case OK_SHORT_BIC_USED: return "ok, für den BIC wurde die Zweigstellennummer allerdings durch XXX ersetzt";
      case OK_SCL_EXTENSION_BIC_USED: return "ok, für den BIC wurde die Extension XXX angehängt";
      case OK_SCL_WILDCARD_BIC_USED: return "ok, für den BIC wurde die Wildcard-Version (8stellig) benutzt";
      default: return "ungültiger Rückgabewert";
   }
}

/* Funktion kto_check_retval2dos() +§§§1 */
/* ###########################################################################
 * # Die Funktion kto_check_retval2dos() wandelt die numerischen Rückgabe-   #
 * # werte in Klartext mit den Umlauten in DOS-Kodierung (CP850) um.         #
 * #                                                                         #
 * # Copyright (C) 2007 Michael Plugge <m.plugge@hs-mannheim.de>             #
 * ###########################################################################
 */

DLL_EXPORT const char *kto_check_retval2dos(int retval)
{
   switch(retval){
      case NO_SCL_BLOCKS_LOADED: return "die SCL-Blocks wurden noch nicht eingelesen";
      case NO_SCL_INFO_BLOCK: return "Der Info-Block des SCL-Verzeichnisses wurde noch nicht eingelesen";
      case SCL_BIC_NOT_FOUND: return "Der BIC wurde im SCL-Verzeichnis nicht gefunden";
      case INVALID_SCL_INFO_BLOCK: return "Ungltiger SCL-Info-Block in der LUT-Datei";
      case NO_SCL_BLOCKS: return "Keine SCL-Blocks in der LUT-Datei enthalten";
      case SCL_INPUT_FORMAT_ERROR: return "Ungltige Eingabewerte in der SCL-Datei";
      case INVALID_REGULAR_EXPRESSION_CNT: return "Ungltiger Z„ hler in regul„ rem Ausdruck (innerhalb von {})";
      case INVALID_REGULAR_EXPRESSION: return "Ungltiger regul„ rer Ausdruck (enth„ lt zwei Zeichen aus [+?*] nacheinander)";
      case INVALID_HANDLE: return "Ungltiges Handle angegeben";
      case INVALID_BIQ_INDEX: return "Ungltiger Index fr die biq_*() Funktionen";
      case ARRAY_INDEX_OUT_OF_RANGE: return "Der Array-Index liegt auáerhalb des gltigen Bereichs";
      case IBAN_ONLY_GERMAN: return "Es werden nur deutsche IBANs untersttzt";
      case INVALID_PARAMETER_TYPE: return "Falscher Parametertyp fr die Funktion";
      case BIC_ONLY_GERMAN: return "Es werden nur deutsche BICs untersttzt";
      case INVALID_BIC_LENGTH: return "Die L„ nge des BIC muá genau 8 oder 11 Zeichen sein";
      case IBAN_CHKSUM_OK_RULE_IGNORED_BLZ: return "Die IBAN-Prfsumme stimmt, die BLZ sollte aber durch eine zentrale BLZ ersetzt werden. Die Richtigkeit der IBAN kann nur mit einer Anfrage bei der Bank ermittelt werden";
      case IBAN_CHKSUM_OK_KC_NOT_INITIALIZED: return "Die IBAN-Prfsumme stimmt, konto_check wurde jedoch noch nicht initialisiert (Kontoprfung nicht m”glich)";
      case IBAN_CHKSUM_OK_BLZ_INVALID: return "Die IBAN-Prfsumme stimmt, die BLZ ist allerdings ungltig";
      case IBAN_CHKSUM_OK_NACHFOLGE_BLZ_DEFINED: return "Die IBAN-Prfsumme stimmt, fr die Bank gibt es allerdings eine (andere) Nachfolge-BLZ";
      case LUT2_NOT_ALL_IBAN_BLOCKS_LOADED: return "es konnten nicht alle Datenblocks die fr die IBAN-Berechnung notwendig sind geladen werden";
      case LUT2_NOT_YET_VALID_PARTIAL_OK: return "Der Datensatz ist noch nicht gltig, auáerdem konnten nicht alle Blocks geladen werden";
      case LUT2_NO_LONGER_VALID_PARTIAL_OK: return "Der Datensatz ist nicht mehr gltig, auáerdem konnten nicht alle Blocks geladen werdeng";
      case LUT2_BLOCKS_MISSING: return "ok, bei der Initialisierung konnten allerdings ein oder mehrere Blocks nicht geladen werden";
      case FALSE_UNTERKONTO_ATTACHED: return "falsch, es wurde ein Unterkonto hinzugefgt (IBAN-Regel)";
      case BLZ_BLACKLISTED: return "Die BLZ findet sich in der Ausschlussliste fr IBAN-Berechnungen";
      case BLZ_MARKED_AS_DELETED: return "Die BLZ ist in der Bundesbank-Datei als gel”scht markiert und somit ungltig";
      case IBAN_CHKSUM_OK_SOMETHING_WRONG: return "Die IBAN-Prfsumme stimmt, es gibt allerdings einen Fehler in der eigenen IBAN-Bestimmung (wahrscheinlich falsch)";
      case IBAN_CHKSUM_OK_NO_IBAN_CALCULATION: return "Die IBAN-Prfsumme stimmt. Die Bank gibt IBANs nach nicht ver”ffentlichten Regeln heraus, die Richtigkeit der IBAN kann nur mit einer Anfrage bei der Bank ermittelt werden";
      case IBAN_CHKSUM_OK_RULE_IGNORED: return "Die IBAN-Prfsumme stimmt, es wurde allerdings eine IBAN-Regel nicht beachtet (wahrscheinlich falsch)";
      case IBAN_CHKSUM_OK_UNTERKTO_MISSING: return "Die IBAN-Prfsumme stimmt, es fehlt aber ein Unterkonto (wahrscheinlich falsch)";
      case IBAN_INVALID_RULE: return "Die BLZ passt nicht zur angegebenen IBAN-Regel";
      case IBAN_AMBIGUOUS_KTO: return "Die Kontonummer ist nicht eindeutig (es gibt mehrere M”glichkeiten)";
      case IBAN_RULE_NOT_IMPLEMENTED: return "Die IBAN-Regel ist noch nicht implementiert";
      case IBAN_RULE_UNKNOWN: return "Die IBAN-Regel ist nicht bekannt";
      case NO_IBAN_CALCULATION: return "Fr die Bankverbindung ist keine IBAN-Berechnung erlaubt";
      case OLD_BLZ_OK_NEW_NOT: return "Die Bankverbindung ist mit der alten BLZ stimmig, mit der Nachfolge-BLZ nicht";
      case LUT2_IBAN_REGEL_NOT_INITIALIZED: return "Das Feld IBAN-Regel wurde nicht initialisiert";
      case INVALID_IBAN_LENGTH: return "Die L„ nge der IBAN fr das angegebene L„ nderkrzel ist falsch";
      case LUT2_NO_ACCOUNT_GIVEN: return "Keine Bankverbindung/IBAN angegeben";
      case LUT2_VOLLTEXT_INVALID_CHAR: return "Ungltiges Zeichen ( ()+-/&.,\' ) fr die Volltextsuche gefunden";
      case LUT2_VOLLTEXT_SINGLE_WORD_ONLY: return "Die Volltextsuche sucht jeweils nur ein einzelnes Wort, benutzen Sie lut_suche_multiple() zur Suche nach mehreren Worten";
      case LUT_SUCHE_INVALID_RSC: return "die angegebene Suchresource ist ungltig";
      case LUT_SUCHE_INVALID_CMD: return "bei der Suche sind im Verknpfungsstring nur die Zeichen a-z sowie + und - erlaubt";
      case LUT_SUCHE_INVALID_CNT: return "bei der Suche mssen zwischen 1 und 26 Suchmuster angegeben werden";
      case LUT2_VOLLTEXT_NOT_INITIALIZED: return "Das Feld Volltext wurde nicht initialisiert";
      case NO_OWN_IBAN_CALCULATION: return "das Institut erlaubt keine eigene IBAN-Berechnung";
      case KTO_CHECK_UNSUPPORTED_COMPRESSION: return "die notwendige Kompressions-Bibliothek wurde beim Kompilieren nicht eingebunden";
      case KTO_CHECK_INVALID_COMPRESSION_LIB: return "der angegebene Wert fr die Default-Kompression ist ungltig";
      case OK_UNTERKONTO_ATTACHED_OLD: return "(nicht mehr als Fehler, sondern positive Ausgabe - Dummy fr den alten Wert)";
      case KTO_CHECK_DEFAULT_BLOCK_INVALID: return "Ungltige Signatur im Default-Block";
      case KTO_CHECK_DEFAULT_BLOCK_FULL: return "Die maximale Anzahl Eintr„ ge fr den Default-Block wurde erreicht";
      case KTO_CHECK_NO_DEFAULT_BLOCK: return "Es wurde noch kein Default-Block angelegt";
      case KTO_CHECK_KEY_NOT_FOUND: return "Der angegebene Schlssel wurde im Default-Block nicht gefunden";
      case LUT2_NO_LONGER_VALID_BETTER: return "Beide Datens„ tze sind nicht mehr gltig, dieser ist aber jnger als der andere";
      case INVALID_SEARCH_RANGE: return "ungltiger Suchbereich angegeben (unten>oben)";
      case KEY_NOT_FOUND: return "Die Suche lieferte kein Ergebnis";
      case BAV_FALSE: return "BAV denkt, das Konto ist falsch (konto_check h„ lt es fr richtig)";
      case LUT2_NO_USER_BLOCK: return "User-Blocks mssen einen Typ > 500 haben";
      case INVALID_SET: return "fr ein LUT-Set sind nur die Werte 0, 1 oder 2 m”glich";
      case NO_GERMAN_BIC: return "Ein Konto kann kann nur fr deutsche Banken geprft werden";
      case IPI_CHECK_INVALID_LENGTH: return "Der zu validierende strukturierete Verwendungszweck muá genau 20 Zeichen enthalten";
      case IPI_INVALID_CHARACTER: return "Im strukturierten Verwendungszweck drfen nur alphanumerische Zeichen vorkommen";
      case IPI_INVALID_LENGTH: return "Die L„ nge des IPI-Verwendungszwecks darf maximal 18 Byte sein";
      case LUT1_FILE_USED: return "Es wurde eine LUT-Datei im Format 1.0/1.1 geladen";
      case MISSING_PARAMETER: return "Fr die aufgerufene Funktion fehlt ein notwendiger Parameter";
      case IBAN2BIC_ONLY_GERMAN: return "Die Funktion iban2bic() arbeitet nur mit deutschen Bankleitzahlen";
      case IBAN_OK_KTO_NOT: return "Die Prfziffer der IBAN stimmt, die der Kontonummer nicht";
      case KTO_OK_IBAN_NOT: return "Die Prfziffer der Kontonummer stimmt, die der IBAN nicht";
      case TOO_MANY_SLOTS: return "Es sind nur maximal 500 Slots pro LUT-Datei m”glich (Neukompilieren erforderlich)";
      case INIT_FATAL_ERROR: return "Initialisierung fehlgeschlagen (init_wait geblockt)";
      case INCREMENTAL_INIT_NEEDS_INFO: return "Ein inkrementelles Initialisieren ben”tigt einen Info-Block in der LUT-Datei";
      case INCREMENTAL_INIT_FROM_DIFFERENT_FILE: return "Ein inkrementelles Initialisieren mit einer anderen LUT-Datei ist nicht m”glich";
      case DEBUG_ONLY_FUNCTION: return "Die Funktion ist nur in der Debug-Version vorhanden";
      case LUT2_INVALID: return "Kein Datensatz der LUT-Datei ist aktuell gltig";
      case LUT2_NOT_YET_VALID: return "Der Datensatz ist noch nicht gltig";
      case LUT2_NO_LONGER_VALID: return "Der Datensatz ist nicht mehr gltig";
      case LUT2_GUELTIGKEIT_SWAPPED: return "Im Gltigkeitsdatum sind Anfangs- und Enddatum vertauscht";
      case LUT2_INVALID_GUELTIGKEIT: return "Das angegebene Gltigkeitsdatum ist ungltig (Sollformat ist JJJJMMTT-JJJJMMTT)";
      case LUT2_INDEX_OUT_OF_RANGE: return "Der Index fr die Filiale ist ungltig";
      case LUT2_INIT_IN_PROGRESS: return "Die Bibliothek wird gerade neu initialisiert";
      case LUT2_BLZ_NOT_INITIALIZED: return "Das Feld BLZ wurde nicht initialisiert";
      case LUT2_FILIALEN_NOT_INITIALIZED: return "Das Feld Filialen wurde nicht initialisiert";
      case LUT2_NAME_NOT_INITIALIZED: return "Das Feld Bankname wurde nicht initialisiert";
      case LUT2_PLZ_NOT_INITIALIZED: return "Das Feld PLZ wurde nicht initialisiert";
      case LUT2_ORT_NOT_INITIALIZED: return "Das Feld Ort wurde nicht initialisiert";
      case LUT2_NAME_KURZ_NOT_INITIALIZED: return "Das Feld Kurzname wurde nicht initialisiert";
      case LUT2_PAN_NOT_INITIALIZED: return "Das Feld PAN wurde nicht initialisiert";
      case LUT2_BIC_NOT_INITIALIZED: return "Das Feld BIC wurde nicht initialisiert";
      case LUT2_PZ_NOT_INITIALIZED: return "Das Feld Prfziffer wurde nicht initialisiert";
      case LUT2_NR_NOT_INITIALIZED: return "Das Feld NR wurde nicht initialisiert";
      case LUT2_AENDERUNG_NOT_INITIALIZED: return "Das Feld Žnderung wurde nicht initialisiert";
      case LUT2_LOESCHUNG_NOT_INITIALIZED: return "Das Feld L”schung wurde nicht initialisiert";
      case LUT2_NACHFOLGE_BLZ_NOT_INITIALIZED: return "Das Feld Nachfolge-BLZ wurde nicht initialisiert";
      case LUT2_NOT_INITIALIZED: return "die Programmbibliothek wurde noch nicht initialisiert";
      case LUT2_FILIALEN_MISSING: return "der Block mit der Filialenanzahl fehlt in der LUT-Datei";
      case LUT2_PARTIAL_OK: return "es wurden nicht alle Blocks geladen";
      case LUT2_Z_BUF_ERROR: return "Buffer error in den ZLIB Routinen";
      case LUT2_Z_MEM_ERROR: return "Memory error in den ZLIB-Routinen";
      case LUT2_Z_DATA_ERROR: return "Datenfehler im komprimierten LUT-Block";
      case LUT2_BLOCK_NOT_IN_FILE: return "Der Block ist nicht in der LUT-Datei enthalten";
      case LUT2_DECOMPRESS_ERROR: return "Fehler beim Dekomprimieren eines LUT-Blocks";
      case LUT2_COMPRESS_ERROR: return "Fehler beim Komprimieren eines LUT-Blocks";
      case LUT2_FILE_CORRUPTED: return "Die LUT-Datei ist korrumpiert";
      case LUT2_NO_SLOT_FREE: return "Im Inhaltsverzeichnis der LUT-Datei ist kein Slot mehr frei";
      case UNDEFINED_SUBMETHOD: return "Die (Unter)Methode ist nicht definiert";
      case EXCLUDED_AT_COMPILETIME: return "Der ben”tigte Programmteil wurde beim Kompilieren deaktiviert";
      case INVALID_LUT_VERSION: return "Die Versionsnummer fr die LUT-Datei ist ungltig";
      case INVALID_PARAMETER_STELLE1: return "ungltiger Prfparameter (erste zu prfende Stelle)";
      case INVALID_PARAMETER_COUNT: return "ungltiger Prfparameter (Anzahl zu prfender Stellen)";
      case INVALID_PARAMETER_PRUEFZIFFER: return "ungltiger Prfparameter (Position der Prfziffer)";
      case INVALID_PARAMETER_WICHTUNG: return "ungltiger Prfparameter (Wichtung)";
      case INVALID_PARAMETER_METHODE: return "ungltiger Prfparameter (Rechenmethode)";
      case LIBRARY_INIT_ERROR: return "Problem beim Initialisieren der globalen Variablen";
      case LUT_CRC_ERROR: return "Prfsummenfehler in der blz.lut Datei";
      case FALSE_GELOESCHT: return "falsch (die BLZ wurde auáerdem gel”scht)";
      case OK_NO_CHK_GELOESCHT: return "ok, ohne Prfung (die BLZ wurde allerdings gel”scht)";
      case OK_GELOESCHT: return "ok (die BLZ wurde allerdings gel”scht)";
      case BLZ_GELOESCHT: return "die Bankleitzahl wurde gel”scht";
      case INVALID_BLZ_FILE: return "Fehler in der blz.txt Datei (falsche Zeilenl„ nge)";
      case LIBRARY_IS_NOT_THREAD_SAFE: return "undefinierte Funktion, die library wurde mit THREAD_SAFE=0 kompiliert";
      case FATAL_ERROR: return "schwerer Fehler im Konto_check-Modul";
      case INVALID_KTO_LENGTH: return "ein Konto muá zwischen 1 und 10 Stellen haben";
      case FILE_WRITE_ERROR: return "kann Datei nicht schreiben";
      case FILE_READ_ERROR: return "kann Datei nicht lesen";
      case ERROR_MALLOC: return "kann keinen Speicher allokieren";
      case NO_BLZ_FILE: return "die blz.txt Datei wurde nicht gefunden";
      case INVALID_LUT_FILE: return "die blz.lut Datei ist inkosistent/ungltig";
      case NO_LUT_FILE: return "die blz.lut Datei wurde nicht gefunden";
      case INVALID_BLZ_LENGTH: return "die Bankleitzahl ist nicht achtstellig";
      case INVALID_BLZ: return "die Bankleitzahl ist ungltig";
      case INVALID_KTO: return "das Konto ist ungltig";
      case NOT_IMPLEMENTED: return "die Methode wurde noch nicht implementiert";
      case NOT_DEFINED: return "die Methode ist nicht definiert";
      case FALSE: return "falsch";
      case OK: return "ok";
      case EE: if(eep)return (char *)eep; else return "";
      case OK_NO_CHK: return "ok, ohne Prfung";
      case OK_TEST_BLZ_USED: return "ok, fr den Test wurde eine Test-BLZ verwendet";
      case LUT2_VALID: return "Der Datensatz ist aktuell gltig";
      case LUT2_NO_VALID_DATE: return "Der Datensatz enth„ lt kein Gltigkeitsdatum";
      case LUT1_SET_LOADED: return "Die Datei ist im alten LUT-Format (1.0/1.1)";
      case LUT1_FILE_GENERATED: return "ok, es wurde allerdings eine LUT-Datei im alten Format (1.0/1.1) generiert";
      case LUT_V2_FILE_GENERATED: return "ok, es wurde allerdings eine LUT-Datei im Format 2.0 generiert (Compilerswitch)";
      case KTO_CHECK_VALUE_REPLACED: return "ok, der Wert fr den Schlssel wurde berschrieben";
      case OK_UNTERKONTO_POSSIBLE: return "wahrscheinlich ok, die Kontonummer kann allerdings (nicht angegebene) Unterkonten enthalten";
      case OK_UNTERKONTO_GIVEN: return "wahrscheinlich ok, die Kontonummer enth„ lt eine Unterkontonummer";
      case OK_SLOT_CNT_MIN_USED: return "ok, die Anzahl Slots wurde auf SLOT_CNT_MIN (60) hochgesetzt";
      case SOME_KEYS_NOT_FOUND: return "ok, ein(ige) Schlssel wurden nicht gefunden";
      case LUT2_KTO_NOT_CHECKED: return "Die Bankverbindung wurde nicht getestet";
      case LUT2_OK_WITHOUT_IBAN_RULES: return "Es wurden fast alle Blocks (auáer den IBAN-Regeln) geladen";
      case OK_NACHFOLGE_BLZ_USED: return "ok, fr die BLZ wurde allerdings die Nachfolge-BLZ eingesetzt";
      case OK_KTO_REPLACED: return "ok, die Kontonummer wurde allerdings ersetzt";
      case OK_BLZ_REPLACED: return "ok, die Bankleitzahl wurde allerdings ersetzt";
      case OK_BLZ_KTO_REPLACED: return "ok, die Bankleitzahl und Kontonummer wurden allerdings ersetzt";
      case OK_IBAN_WITHOUT_KC_TEST: return "ok, die Bankverbindung ist (ohne Test) als richtig anzusehen";
      case OK_INVALID_FOR_IBAN: return "ok, fr die die IBAN ist (durch eine Regel) allerdings ein anderer BIC definiert";
      case OK_HYPO_REQUIRES_KTO: return "ok, fr die BIC-Bestimmung der ehemaligen Hypo-Bank fr IBAN wird i.A. zus„ tzlich die Kontonummer ben”tigt";
      case OK_KTO_REPLACED_NO_PZ: return "ok, die Kontonummer wurde ersetzt, die neue Kontonummer hat keine Prfziffer";
      case OK_UNTERKONTO_ATTACHED: return "ok, es wurde ein (weggelassenes) Unterkonto angefgt";
      case OK_SHORT_BIC_USED: return "ok, fr den BIC wurde die Zweigstellennummer allerdings durch XXX ersetzt";
      case OK_SCL_EXTENSION_BIC_USED: return "ok, fr den BIC wurde die Extension XXX angeh„ ngt";
      case OK_SCL_WILDCARD_BIC_USED: return "ok, fr den BIC wurde die Wildcard-Version (8stellig) benutzt";
      default: return "ungltiger Rckgabewert";
   }
}

/* Funktion kto_check_retval2html() +§§§1 */
/* ###########################################################################
 * # Die Funktion kto_check_retval2html() wandelt die numerischen Rückgabe-  #
 * # werte in Klartext mit den Umlauten in HTML-Kodierung um.                #
 * #                                                                         #
 * # Copyright (C) 2007 Michael Plugge <m.plugge@hs-mannheim.de>             #
 * ###########################################################################
 */

DLL_EXPORT const char *kto_check_retval2html(int retval)
{
   switch(retval){
      case NO_SCL_BLOCKS_LOADED: return "die SCL-Blocks wurden noch nicht eingelesen";
      case NO_SCL_INFO_BLOCK: return "Der Info-Block des SCL-Verzeichnisses wurde noch nicht eingelesen";
      case SCL_BIC_NOT_FOUND: return "Der BIC wurde im SCL-Verzeichnis nicht gefunden";
      case INVALID_SCL_INFO_BLOCK: return "Ung&uuml;ltiger SCL-Info-Block in der LUT-Datei";
      case NO_SCL_BLOCKS: return "Keine SCL-Blocks in der LUT-Datei enthalten";
      case SCL_INPUT_FORMAT_ERROR: return "Ung&uuml;ltige Eingabewerte in der SCL-Datei";
      case INVALID_REGULAR_EXPRESSION_CNT: return "Ung&uuml;ltiger Z&auml;hler in regul&auml;rem Ausdruck (innerhalb von {})";
      case INVALID_REGULAR_EXPRESSION: return "Ung&uuml;ltiger regul&auml;rer Ausdruck (enth&auml;lt zwei Zeichen aus [+?*] nacheinander)";
      case INVALID_HANDLE: return "Ung&uuml;ltiges Handle angegeben";
      case INVALID_BIQ_INDEX: return "Ung&uuml;ltiger Index f&uuml;r die biq_*() Funktionen";
      case ARRAY_INDEX_OUT_OF_RANGE: return "Der Array-Index liegt au&szlig;erhalb des g&uuml;ltigen Bereichs";
      case IBAN_ONLY_GERMAN: return "Es werden nur deutsche IBANs unterst&uuml;tzt";
      case INVALID_PARAMETER_TYPE: return "Falscher Parametertyp f&uuml;r die Funktion";
      case BIC_ONLY_GERMAN: return "Es werden nur deutsche BICs unterst&uuml;tzt";
      case INVALID_BIC_LENGTH: return "Die L&auml;nge des BIC mu&szlig; genau 8 oder 11 Zeichen sein";
      case IBAN_CHKSUM_OK_RULE_IGNORED_BLZ: return "Die IBAN-Pr&uuml;fsumme stimmt, die BLZ sollte aber durch eine zentrale BLZ ersetzt werden. Die Richtigkeit der IBAN kann nur mit einer Anfrage bei der Bank ermittelt werden";
      case IBAN_CHKSUM_OK_KC_NOT_INITIALIZED: return "Die IBAN-Pr&uuml;fsumme stimmt, konto_check wurde jedoch noch nicht initialisiert (Kontopr&uuml;fung nicht m&ouml;glich)";
      case IBAN_CHKSUM_OK_BLZ_INVALID: return "Die IBAN-Pr&uuml;fsumme stimmt, die BLZ ist allerdings ung&uuml;ltig";
      case IBAN_CHKSUM_OK_NACHFOLGE_BLZ_DEFINED: return "Die IBAN-Pr&uuml;fsumme stimmt, f&uuml;r die Bank gibt es allerdings eine (andere) Nachfolge-BLZ";
      case LUT2_NOT_ALL_IBAN_BLOCKS_LOADED: return "es konnten nicht alle Datenblocks die f&uuml;r die IBAN-Berechnung notwendig sind geladen werden";
      case LUT2_NOT_YET_VALID_PARTIAL_OK: return "Der Datensatz ist noch nicht g&uuml;ltig, au&szlig;erdem konnten nicht alle Blocks geladen werden";
      case LUT2_NO_LONGER_VALID_PARTIAL_OK: return "Der Datensatz ist nicht mehr g&uuml;ltig, au&szlig;erdem konnten nicht alle Blocks geladen werdeng";
      case LUT2_BLOCKS_MISSING: return "ok, bei der Initialisierung konnten allerdings ein oder mehrere Blocks nicht geladen werden";
      case FALSE_UNTERKONTO_ATTACHED: return "falsch, es wurde ein Unterkonto hinzugef&uuml;gt (IBAN-Regel)";
      case BLZ_BLACKLISTED: return "Die BLZ findet sich in der Ausschlussliste f&uuml;r IBAN-Berechnungen";
      case BLZ_MARKED_AS_DELETED: return "Die BLZ ist in der Bundesbank-Datei als gel&ouml;scht markiert und somit ung&uuml;ltig";
      case IBAN_CHKSUM_OK_SOMETHING_WRONG: return "Die IBAN-Pr&uuml;fsumme stimmt, es gibt allerdings einen Fehler in der eigenen IBAN-Bestimmung (wahrscheinlich falsch)";
      case IBAN_CHKSUM_OK_NO_IBAN_CALCULATION: return "Die IBAN-Pr&uuml;fsumme stimmt. Die Bank gibt IBANs nach nicht ver&ouml;ffentlichten Regeln heraus, die Richtigkeit der IBAN kann nur mit einer Anfrage bei der Bank ermittelt werden";
      case IBAN_CHKSUM_OK_RULE_IGNORED: return "Die IBAN-Pr&uuml;fsumme stimmt, es wurde allerdings eine IBAN-Regel nicht beachtet (wahrscheinlich falsch)";
      case IBAN_CHKSUM_OK_UNTERKTO_MISSING: return "Die IBAN-Pr&uuml;fsumme stimmt, es fehlt aber ein Unterkonto (wahrscheinlich falsch)";
      case IBAN_INVALID_RULE: return "Die BLZ passt nicht zur angegebenen IBAN-Regel";
      case IBAN_AMBIGUOUS_KTO: return "Die Kontonummer ist nicht eindeutig (es gibt mehrere M&ouml;glichkeiten)";
      case IBAN_RULE_NOT_IMPLEMENTED: return "Die IBAN-Regel ist noch nicht implementiert";
      case IBAN_RULE_UNKNOWN: return "Die IBAN-Regel ist nicht bekannt";
      case NO_IBAN_CALCULATION: return "F&uuml;r die Bankverbindung ist keine IBAN-Berechnung erlaubt";
      case OLD_BLZ_OK_NEW_NOT: return "Die Bankverbindung ist mit der alten BLZ stimmig, mit der Nachfolge-BLZ nicht";
      case LUT2_IBAN_REGEL_NOT_INITIALIZED: return "Das Feld IBAN-Regel wurde nicht initialisiert";
      case INVALID_IBAN_LENGTH: return "Die L&auml;nge der IBAN f&uuml;r das angegebene L&auml;nderk&uuml;rzel ist falsch";
      case LUT2_NO_ACCOUNT_GIVEN: return "Keine Bankverbindung/IBAN angegeben";
      case LUT2_VOLLTEXT_INVALID_CHAR: return "Ung&uuml;ltiges Zeichen ( ()+-/&amp;.,\' ) f&uuml;r die Volltextsuche gefunden";
      case LUT2_VOLLTEXT_SINGLE_WORD_ONLY: return "Die Volltextsuche sucht jeweils nur ein einzelnes Wort, benutzen Sie lut_suche_multiple() zur Suche nach mehreren Worten";
      case LUT_SUCHE_INVALID_RSC: return "die angegebene Suchresource ist ung&uuml;ltig";
      case LUT_SUCHE_INVALID_CMD: return "bei der Suche sind im Verkn&uuml;pfungsstring nur die Zeichen a-z sowie + und - erlaubt";
      case LUT_SUCHE_INVALID_CNT: return "bei der Suche m&uuml;ssen zwischen 1 und 26 Suchmuster angegeben werden";
      case LUT2_VOLLTEXT_NOT_INITIALIZED: return "Das Feld Volltext wurde nicht initialisiert";
      case NO_OWN_IBAN_CALCULATION: return "das Institut erlaubt keine eigene IBAN-Berechnung";
      case KTO_CHECK_UNSUPPORTED_COMPRESSION: return "die notwendige Kompressions-Bibliothek wurde beim Kompilieren nicht eingebunden";
      case KTO_CHECK_INVALID_COMPRESSION_LIB: return "der angegebene Wert f&uuml;r die Default-Kompression ist ung&uuml;ltig";
      case OK_UNTERKONTO_ATTACHED_OLD: return "(nicht mehr als Fehler, sondern positive Ausgabe - Dummy f&uuml;r den alten Wert)";
      case KTO_CHECK_DEFAULT_BLOCK_INVALID: return "Ung&uuml;ltige Signatur im Default-Block";
      case KTO_CHECK_DEFAULT_BLOCK_FULL: return "Die maximale Anzahl Eintr&auml;ge f&uuml;r den Default-Block wurde erreicht";
      case KTO_CHECK_NO_DEFAULT_BLOCK: return "Es wurde noch kein Default-Block angelegt";
      case KTO_CHECK_KEY_NOT_FOUND: return "Der angegebene Schl&uuml;ssel wurde im Default-Block nicht gefunden";
      case LUT2_NO_LONGER_VALID_BETTER: return "Beide Datens&auml;tze sind nicht mehr g&uuml;ltig, dieser ist aber j&uuml;nger als der andere";
      case INVALID_SEARCH_RANGE: return "ung&uuml;ltiger Suchbereich angegeben (unten&gt;oben)";
      case KEY_NOT_FOUND: return "Die Suche lieferte kein Ergebnis";
      case BAV_FALSE: return "BAV denkt, das Konto ist falsch (konto_check h&auml;lt es f&uuml;r richtig)";
      case LUT2_NO_USER_BLOCK: return "User-Blocks m&uuml;ssen einen Typ &gt; 500 haben";
      case INVALID_SET: return "f&uuml;r ein LUT-Set sind nur die Werte 0, 1 oder 2 m&ouml;glich";
      case NO_GERMAN_BIC: return "Ein Konto kann kann nur f&uuml;r deutsche Banken gepr&uuml;ft werden";
      case IPI_CHECK_INVALID_LENGTH: return "Der zu validierende strukturierete Verwendungszweck mu&szlig; genau 20 Zeichen enthalten";
      case IPI_INVALID_CHARACTER: return "Im strukturierten Verwendungszweck d&uuml;rfen nur alphanumerische Zeichen vorkommen";
      case IPI_INVALID_LENGTH: return "Die L&auml;nge des IPI-Verwendungszwecks darf maximal 18 Byte sein";
      case LUT1_FILE_USED: return "Es wurde eine LUT-Datei im Format 1.0/1.1 geladen";
      case MISSING_PARAMETER: return "F&uuml;r die aufgerufene Funktion fehlt ein notwendiger Parameter";
      case IBAN2BIC_ONLY_GERMAN: return "Die Funktion iban2bic() arbeitet nur mit deutschen Bankleitzahlen";
      case IBAN_OK_KTO_NOT: return "Die Pr&uuml;fziffer der IBAN stimmt, die der Kontonummer nicht";
      case KTO_OK_IBAN_NOT: return "Die Pr&uuml;fziffer der Kontonummer stimmt, die der IBAN nicht";
      case TOO_MANY_SLOTS: return "Es sind nur maximal 500 Slots pro LUT-Datei m&ouml;glich (Neukompilieren erforderlich)";
      case INIT_FATAL_ERROR: return "Initialisierung fehlgeschlagen (init_wait geblockt)";
      case INCREMENTAL_INIT_NEEDS_INFO: return "Ein inkrementelles Initialisieren ben&ouml;tigt einen Info-Block in der LUT-Datei";
      case INCREMENTAL_INIT_FROM_DIFFERENT_FILE: return "Ein inkrementelles Initialisieren mit einer anderen LUT-Datei ist nicht m&ouml;glich";
      case DEBUG_ONLY_FUNCTION: return "Die Funktion ist nur in der Debug-Version vorhanden";
      case LUT2_INVALID: return "Kein Datensatz der LUT-Datei ist aktuell g&uuml;ltig";
      case LUT2_NOT_YET_VALID: return "Der Datensatz ist noch nicht g&uuml;ltig";
      case LUT2_NO_LONGER_VALID: return "Der Datensatz ist nicht mehr g&uuml;ltig";
      case LUT2_GUELTIGKEIT_SWAPPED: return "Im G&uuml;ltigkeitsdatum sind Anfangs- und Enddatum vertauscht";
      case LUT2_INVALID_GUELTIGKEIT: return "Das angegebene G&uuml;ltigkeitsdatum ist ung&uuml;ltig (Sollformat ist JJJJMMTT-JJJJMMTT)";
      case LUT2_INDEX_OUT_OF_RANGE: return "Der Index f&uuml;r die Filiale ist ung&uuml;ltig";
      case LUT2_INIT_IN_PROGRESS: return "Die Bibliothek wird gerade neu initialisiert";
      case LUT2_BLZ_NOT_INITIALIZED: return "Das Feld BLZ wurde nicht initialisiert";
      case LUT2_FILIALEN_NOT_INITIALIZED: return "Das Feld Filialen wurde nicht initialisiert";
      case LUT2_NAME_NOT_INITIALIZED: return "Das Feld Bankname wurde nicht initialisiert";
      case LUT2_PLZ_NOT_INITIALIZED: return "Das Feld PLZ wurde nicht initialisiert";
      case LUT2_ORT_NOT_INITIALIZED: return "Das Feld Ort wurde nicht initialisiert";
      case LUT2_NAME_KURZ_NOT_INITIALIZED: return "Das Feld Kurzname wurde nicht initialisiert";
      case LUT2_PAN_NOT_INITIALIZED: return "Das Feld PAN wurde nicht initialisiert";
      case LUT2_BIC_NOT_INITIALIZED: return "Das Feld BIC wurde nicht initialisiert";
      case LUT2_PZ_NOT_INITIALIZED: return "Das Feld Pr&uuml;fziffer wurde nicht initialisiert";
      case LUT2_NR_NOT_INITIALIZED: return "Das Feld NR wurde nicht initialisiert";
      case LUT2_AENDERUNG_NOT_INITIALIZED: return "Das Feld &Auml;nderung wurde nicht initialisiert";
      case LUT2_LOESCHUNG_NOT_INITIALIZED: return "Das Feld L&ouml;schung wurde nicht initialisiert";
      case LUT2_NACHFOLGE_BLZ_NOT_INITIALIZED: return "Das Feld Nachfolge-BLZ wurde nicht initialisiert";
      case LUT2_NOT_INITIALIZED: return "die Programmbibliothek wurde noch nicht initialisiert";
      case LUT2_FILIALEN_MISSING: return "der Block mit der Filialenanzahl fehlt in der LUT-Datei";
      case LUT2_PARTIAL_OK: return "es wurden nicht alle Blocks geladen";
      case LUT2_Z_BUF_ERROR: return "Buffer error in den ZLIB Routinen";
      case LUT2_Z_MEM_ERROR: return "Memory error in den ZLIB-Routinen";
      case LUT2_Z_DATA_ERROR: return "Datenfehler im komprimierten LUT-Block";
      case LUT2_BLOCK_NOT_IN_FILE: return "Der Block ist nicht in der LUT-Datei enthalten";
      case LUT2_DECOMPRESS_ERROR: return "Fehler beim Dekomprimieren eines LUT-Blocks";
      case LUT2_COMPRESS_ERROR: return "Fehler beim Komprimieren eines LUT-Blocks";
      case LUT2_FILE_CORRUPTED: return "Die LUT-Datei ist korrumpiert";
      case LUT2_NO_SLOT_FREE: return "Im Inhaltsverzeichnis der LUT-Datei ist kein Slot mehr frei";
      case UNDEFINED_SUBMETHOD: return "Die (Unter)Methode ist nicht definiert";
      case EXCLUDED_AT_COMPILETIME: return "Der ben&ouml;tigte Programmteil wurde beim Kompilieren deaktiviert";
      case INVALID_LUT_VERSION: return "Die Versionsnummer f&uuml;r die LUT-Datei ist ung&uuml;ltig";
      case INVALID_PARAMETER_STELLE1: return "ung&uuml;ltiger Pr&uuml;fparameter (erste zu pr&uuml;fende Stelle)";
      case INVALID_PARAMETER_COUNT: return "ung&uuml;ltiger Pr&uuml;fparameter (Anzahl zu pr&uuml;fender Stellen)";
      case INVALID_PARAMETER_PRUEFZIFFER: return "ung&uuml;ltiger Pr&uuml;fparameter (Position der Pr&uuml;fziffer)";
      case INVALID_PARAMETER_WICHTUNG: return "ung&uuml;ltiger Pr&uuml;fparameter (Wichtung)";
      case INVALID_PARAMETER_METHODE: return "ung&uuml;ltiger Pr&uuml;fparameter (Rechenmethode)";
      case LIBRARY_INIT_ERROR: return "Problem beim Initialisieren der globalen Variablen";
      case LUT_CRC_ERROR: return "Pr&uuml;fsummenfehler in der blz.lut Datei";
      case FALSE_GELOESCHT: return "falsch (die BLZ wurde au&szlig;erdem gel&ouml;scht)";
      case OK_NO_CHK_GELOESCHT: return "ok, ohne Pr&uuml;fung (die BLZ wurde allerdings gel&ouml;scht)";
      case OK_GELOESCHT: return "ok (die BLZ wurde allerdings gel&ouml;scht)";
      case BLZ_GELOESCHT: return "die Bankleitzahl wurde gel&ouml;scht";
      case INVALID_BLZ_FILE: return "Fehler in der blz.txt Datei (falsche Zeilenl&auml;nge)";
      case LIBRARY_IS_NOT_THREAD_SAFE: return "undefinierte Funktion, die library wurde mit THREAD_SAFE=0 kompiliert";
      case FATAL_ERROR: return "schwerer Fehler im Konto_check-Modul";
      case INVALID_KTO_LENGTH: return "ein Konto mu&szlig; zwischen 1 und 10 Stellen haben";
      case FILE_WRITE_ERROR: return "kann Datei nicht schreiben";
      case FILE_READ_ERROR: return "kann Datei nicht lesen";
      case ERROR_MALLOC: return "kann keinen Speicher allokieren";
      case NO_BLZ_FILE: return "die blz.txt Datei wurde nicht gefunden";
      case INVALID_LUT_FILE: return "die blz.lut Datei ist inkosistent/ung&uuml;ltig";
      case NO_LUT_FILE: return "die blz.lut Datei wurde nicht gefunden";
      case INVALID_BLZ_LENGTH: return "die Bankleitzahl ist nicht achtstellig";
      case INVALID_BLZ: return "die Bankleitzahl ist ung&uuml;ltig";
      case INVALID_KTO: return "das Konto ist ung&uuml;ltig";
      case NOT_IMPLEMENTED: return "die Methode wurde noch nicht implementiert";
      case NOT_DEFINED: return "die Methode ist nicht definiert";
      case FALSE: return "falsch";
      case OK: return "ok";
      case EE: if(eeh)return (char *)eeh; else return "";
      case OK_NO_CHK: return "ok, ohne Pr&uuml;fung";
      case OK_TEST_BLZ_USED: return "ok, f&uuml;r den Test wurde eine Test-BLZ verwendet";
      case LUT2_VALID: return "Der Datensatz ist aktuell g&uuml;ltig";
      case LUT2_NO_VALID_DATE: return "Der Datensatz enth&auml;lt kein G&uuml;ltigkeitsdatum";
      case LUT1_SET_LOADED: return "Die Datei ist im alten LUT-Format (1.0/1.1)";
      case LUT1_FILE_GENERATED: return "ok, es wurde allerdings eine LUT-Datei im alten Format (1.0/1.1) generiert";
      case LUT_V2_FILE_GENERATED: return "ok, es wurde allerdings eine LUT-Datei im Format 2.0 generiert (Compilerswitch)";
      case KTO_CHECK_VALUE_REPLACED: return "ok, der Wert f&uuml;r den Schl&uuml;ssel wurde &uuml;berschrieben";
      case OK_UNTERKONTO_POSSIBLE: return "wahrscheinlich ok, die Kontonummer kann allerdings (nicht angegebene) Unterkonten enthalten";
      case OK_UNTERKONTO_GIVEN: return "wahrscheinlich ok, die Kontonummer enth&auml;lt eine Unterkontonummer";
      case OK_SLOT_CNT_MIN_USED: return "ok, die Anzahl Slots wurde auf SLOT_CNT_MIN (60) hochgesetzt";
      case SOME_KEYS_NOT_FOUND: return "ok, ein(ige) Schl&uuml;ssel wurden nicht gefunden";
      case LUT2_KTO_NOT_CHECKED: return "Die Bankverbindung wurde nicht getestet";
      case LUT2_OK_WITHOUT_IBAN_RULES: return "Es wurden fast alle Blocks (au&szlig;er den IBAN-Regeln) geladen";
      case OK_NACHFOLGE_BLZ_USED: return "ok, f&uuml;r die BLZ wurde allerdings die Nachfolge-BLZ eingesetzt";
      case OK_KTO_REPLACED: return "ok, die Kontonummer wurde allerdings ersetzt";
      case OK_BLZ_REPLACED: return "ok, die Bankleitzahl wurde allerdings ersetzt";
      case OK_BLZ_KTO_REPLACED: return "ok, die Bankleitzahl und Kontonummer wurden allerdings ersetzt";
      case OK_IBAN_WITHOUT_KC_TEST: return "ok, die Bankverbindung ist (ohne Test) als richtig anzusehen";
      case OK_INVALID_FOR_IBAN: return "ok, f&uuml;r die die IBAN ist (durch eine Regel) allerdings ein anderer BIC definiert";
      case OK_HYPO_REQUIRES_KTO: return "ok, f&uuml;r die BIC-Bestimmung der ehemaligen Hypo-Bank f&uuml;r IBAN wird i.A. zus&auml;tzlich die Kontonummer ben&ouml;tigt";
      case OK_KTO_REPLACED_NO_PZ: return "ok, die Kontonummer wurde ersetzt, die neue Kontonummer hat keine Pr&uuml;fziffer";
      case OK_UNTERKONTO_ATTACHED: return "ok, es wurde ein (weggelassenes) Unterkonto angef&uuml;gt";
      case OK_SHORT_BIC_USED: return "ok, f&uuml;r den BIC wurde die Zweigstellennummer allerdings durch XXX ersetzt";
      case OK_SCL_EXTENSION_BIC_USED: return "ok, f&uuml;r den BIC wurde die Extension XXX angeh&auml;ngt";
      case OK_SCL_WILDCARD_BIC_USED: return "ok, f&uuml;r den BIC wurde die Wildcard-Version (8stellig) benutzt";
      default: return "ung&uuml;ltiger R&uuml;ckgabewert";
   }
}

/* Funktion kto_check_retval2utf8() +§§§1 */
/* ###########################################################################
 * # Die Funktion kto_check_retval2utf8() wandelt die numerischen Rückgabe-  #
 * # werte in Klartext mit den Umlauten in UTF-8-Kodierung um.               #
 * #                                                                         #
 * # Copyright (C) 2007 Michael Plugge <m.plugge@hs-mannheim.de>             #
 * ###########################################################################
 */

DLL_EXPORT const char *kto_check_retval2utf8(int retval)
{
   switch(retval){
      case NO_SCL_BLOCKS_LOADED: return "die SCL-Blocks wurden noch nicht eingelesen";
      case NO_SCL_INFO_BLOCK: return "Der Info-Block des SCL-Verzeichnisses wurde noch nicht eingelesen";
      case SCL_BIC_NOT_FOUND: return "Der BIC wurde im SCL-Verzeichnis nicht gefunden";
      case INVALID_SCL_INFO_BLOCK: return "UngÃ¼ltiger SCL-Info-Block in der LUT-Datei";
      case NO_SCL_BLOCKS: return "Keine SCL-Blocks in der LUT-Datei enthalten";
      case SCL_INPUT_FORMAT_ERROR: return "UngÃ¼ltige Eingabewerte in der SCL-Datei";
      case INVALID_REGULAR_EXPRESSION_CNT: return "UngÃ¼ltiger ZÃ¤hler in regulÃ¤rem Ausdruck (innerhalb von {})";
      case INVALID_REGULAR_EXPRESSION: return "UngÃ¼ltiger regulÃ¤rer Ausdruck (enthÃ¤lt zwei Zeichen aus [+?*] nacheinander)";
      case INVALID_HANDLE: return "UngÃ¼ltiges Handle angegeben";
      case INVALID_BIQ_INDEX: return "UngÃ¼ltiger Index fÃ¼r die biq_*() Funktionen";
      case ARRAY_INDEX_OUT_OF_RANGE: return "Der Array-Index liegt auÃŸerhalb des gÃ¼ltigen Bereichs";
      case IBAN_ONLY_GERMAN: return "Es werden nur deutsche IBANs unterstÃ¼tzt";
      case INVALID_PARAMETER_TYPE: return "Falscher Parametertyp fÃ¼r die Funktion";
      case BIC_ONLY_GERMAN: return "Es werden nur deutsche BICs unterstÃ¼tzt";
      case INVALID_BIC_LENGTH: return "Die LÃ¤nge des BIC muÃŸ genau 8 oder 11 Zeichen sein";
      case IBAN_CHKSUM_OK_RULE_IGNORED_BLZ: return "Die IBAN-PrÃ¼fsumme stimmt, die BLZ sollte aber durch eine zentrale BLZ ersetzt werden. Die Richtigkeit der IBAN kann nur mit einer Anfrage bei der Bank ermittelt werden";
      case IBAN_CHKSUM_OK_KC_NOT_INITIALIZED: return "Die IBAN-PrÃ¼fsumme stimmt, konto_check wurde jedoch noch nicht initialisiert (KontoprÃ¼fung nicht mÃ¶glich)";
      case IBAN_CHKSUM_OK_BLZ_INVALID: return "Die IBAN-PrÃ¼fsumme stimmt, die BLZ ist allerdings ungÃ¼ltig";
      case IBAN_CHKSUM_OK_NACHFOLGE_BLZ_DEFINED: return "Die IBAN-PrÃ¼fsumme stimmt, fÃ¼r die Bank gibt es allerdings eine (andere) Nachfolge-BLZ";
      case LUT2_NOT_ALL_IBAN_BLOCKS_LOADED: return "es konnten nicht alle Datenblocks die fÃ¼r die IBAN-Berechnung notwendig sind geladen werden";
      case LUT2_NOT_YET_VALID_PARTIAL_OK: return "Der Datensatz ist noch nicht gÃ¼ltig, auÃŸerdem konnten nicht alle Blocks geladen werden";
      case LUT2_NO_LONGER_VALID_PARTIAL_OK: return "Der Datensatz ist nicht mehr gÃ¼ltig, auÃŸerdem konnten nicht alle Blocks geladen werdeng";
      case LUT2_BLOCKS_MISSING: return "ok, bei der Initialisierung konnten allerdings ein oder mehrere Blocks nicht geladen werden";
      case FALSE_UNTERKONTO_ATTACHED: return "falsch, es wurde ein Unterkonto hinzugefÃ¼gt (IBAN-Regel)";
      case BLZ_BLACKLISTED: return "Die BLZ findet sich in der Ausschlussliste fÃ¼r IBAN-Berechnungen";
      case BLZ_MARKED_AS_DELETED: return "Die BLZ ist in der Bundesbank-Datei als gelÃ¶scht markiert und somit ungÃ¼ltig";
      case IBAN_CHKSUM_OK_SOMETHING_WRONG: return "Die IBAN-PrÃ¼fsumme stimmt, es gibt allerdings einen Fehler in der eigenen IBAN-Bestimmung (wahrscheinlich falsch)";
      case IBAN_CHKSUM_OK_NO_IBAN_CALCULATION: return "Die IBAN-PrÃ¼fsumme stimmt. Die Bank gibt IBANs nach nicht verÃ¶ffentlichten Regeln heraus, die Richtigkeit der IBAN kann nur mit einer Anfrage bei der Bank ermittelt werden";
      case IBAN_CHKSUM_OK_RULE_IGNORED: return "Die IBAN-PrÃ¼fsumme stimmt, es wurde allerdings eine IBAN-Regel nicht beachtet (wahrscheinlich falsch)";
      case IBAN_CHKSUM_OK_UNTERKTO_MISSING: return "Die IBAN-PrÃ¼fsumme stimmt, es fehlt aber ein Unterkonto (wahrscheinlich falsch)";
      case IBAN_INVALID_RULE: return "Die BLZ passt nicht zur angegebenen IBAN-Regel";
      case IBAN_AMBIGUOUS_KTO: return "Die Kontonummer ist nicht eindeutig (es gibt mehrere MÃ¶glichkeiten)";
      case IBAN_RULE_NOT_IMPLEMENTED: return "Die IBAN-Regel ist noch nicht implementiert";
      case IBAN_RULE_UNKNOWN: return "Die IBAN-Regel ist nicht bekannt";
      case NO_IBAN_CALCULATION: return "FÃ¼r die Bankverbindung ist keine IBAN-Berechnung erlaubt";
      case OLD_BLZ_OK_NEW_NOT: return "Die Bankverbindung ist mit der alten BLZ stimmig, mit der Nachfolge-BLZ nicht";
      case LUT2_IBAN_REGEL_NOT_INITIALIZED: return "Das Feld IBAN-Regel wurde nicht initialisiert";
      case INVALID_IBAN_LENGTH: return "Die LÃ¤nge der IBAN fÃ¼r das angegebene LÃ¤nderkÃ¼rzel ist falsch";
      case LUT2_NO_ACCOUNT_GIVEN: return "Keine Bankverbindung/IBAN angegeben";
      case LUT2_VOLLTEXT_INVALID_CHAR: return "UngÃ¼ltiges Zeichen ( ()+-/&.,\' ) fÃ¼r die Volltextsuche gefunden";
      case LUT2_VOLLTEXT_SINGLE_WORD_ONLY: return "Die Volltextsuche sucht jeweils nur ein einzelnes Wort, benutzen Sie lut_suche_multiple() zur Suche nach mehreren Worten";
      case LUT_SUCHE_INVALID_RSC: return "die angegebene Suchresource ist ungÃ¼ltig";
      case LUT_SUCHE_INVALID_CMD: return "bei der Suche sind im VerknÃ¼pfungsstring nur die Zeichen a-z sowie + und - erlaubt";
      case LUT_SUCHE_INVALID_CNT: return "bei der Suche mÃ¼ssen zwischen 1 und 26 Suchmuster angegeben werden";
      case LUT2_VOLLTEXT_NOT_INITIALIZED: return "Das Feld Volltext wurde nicht initialisiert";
      case NO_OWN_IBAN_CALCULATION: return "das Institut erlaubt keine eigene IBAN-Berechnung";
      case KTO_CHECK_UNSUPPORTED_COMPRESSION: return "die notwendige Kompressions-Bibliothek wurde beim Kompilieren nicht eingebunden";
      case KTO_CHECK_INVALID_COMPRESSION_LIB: return "der angegebene Wert fÃ¼r die Default-Kompression ist ungÃ¼ltig";
      case OK_UNTERKONTO_ATTACHED_OLD: return "(nicht mehr als Fehler, sondern positive Ausgabe - Dummy fÃ¼r den alten Wert)";
      case KTO_CHECK_DEFAULT_BLOCK_INVALID: return "UngÃ¼ltige Signatur im Default-Block";
      case KTO_CHECK_DEFAULT_BLOCK_FULL: return "Die maximale Anzahl EintrÃ¤ge fÃ¼r den Default-Block wurde erreicht";
      case KTO_CHECK_NO_DEFAULT_BLOCK: return "Es wurde noch kein Default-Block angelegt";
      case KTO_CHECK_KEY_NOT_FOUND: return "Der angegebene SchlÃ¼ssel wurde im Default-Block nicht gefunden";
      case LUT2_NO_LONGER_VALID_BETTER: return "Beide DatensÃ¤tze sind nicht mehr gÃ¼ltig, dieser ist aber jÃ¼nger als der andere";
      case INVALID_SEARCH_RANGE: return "ungÃ¼ltiger Suchbereich angegeben (unten>oben)";
      case KEY_NOT_FOUND: return "Die Suche lieferte kein Ergebnis";
      case BAV_FALSE: return "BAV denkt, das Konto ist falsch (konto_check hÃ¤lt es fÃ¼r richtig)";
      case LUT2_NO_USER_BLOCK: return "User-Blocks mÃ¼ssen einen Typ > 500 haben";
      case INVALID_SET: return "fÃ¼r ein LUT-Set sind nur die Werte 0, 1 oder 2 mÃ¶glich";
      case NO_GERMAN_BIC: return "Ein Konto kann kann nur fÃ¼r deutsche Banken geprÃ¼ft werden";
      case IPI_CHECK_INVALID_LENGTH: return "Der zu validierende strukturierete Verwendungszweck muÃŸ genau 20 Zeichen enthalten";
      case IPI_INVALID_CHARACTER: return "Im strukturierten Verwendungszweck dÃ¼rfen nur alphanumerische Zeichen vorkommen";
      case IPI_INVALID_LENGTH: return "Die LÃ¤nge des IPI-Verwendungszwecks darf maximal 18 Byte sein";
      case LUT1_FILE_USED: return "Es wurde eine LUT-Datei im Format 1.0/1.1 geladen";
      case MISSING_PARAMETER: return "FÃ¼r die aufgerufene Funktion fehlt ein notwendiger Parameter";
      case IBAN2BIC_ONLY_GERMAN: return "Die Funktion iban2bic() arbeitet nur mit deutschen Bankleitzahlen";
      case IBAN_OK_KTO_NOT: return "Die PrÃ¼fziffer der IBAN stimmt, die der Kontonummer nicht";
      case KTO_OK_IBAN_NOT: return "Die PrÃ¼fziffer der Kontonummer stimmt, die der IBAN nicht";
      case TOO_MANY_SLOTS: return "Es sind nur maximal 500 Slots pro LUT-Datei mÃ¶glich (Neukompilieren erforderlich)";
      case INIT_FATAL_ERROR: return "Initialisierung fehlgeschlagen (init_wait geblockt)";
      case INCREMENTAL_INIT_NEEDS_INFO: return "Ein inkrementelles Initialisieren benÃ¶tigt einen Info-Block in der LUT-Datei";
      case INCREMENTAL_INIT_FROM_DIFFERENT_FILE: return "Ein inkrementelles Initialisieren mit einer anderen LUT-Datei ist nicht mÃ¶glich";
      case DEBUG_ONLY_FUNCTION: return "Die Funktion ist nur in der Debug-Version vorhanden";
      case LUT2_INVALID: return "Kein Datensatz der LUT-Datei ist aktuell gÃ¼ltig";
      case LUT2_NOT_YET_VALID: return "Der Datensatz ist noch nicht gÃ¼ltig";
      case LUT2_NO_LONGER_VALID: return "Der Datensatz ist nicht mehr gÃ¼ltig";
      case LUT2_GUELTIGKEIT_SWAPPED: return "Im GÃ¼ltigkeitsdatum sind Anfangs- und Enddatum vertauscht";
      case LUT2_INVALID_GUELTIGKEIT: return "Das angegebene GÃ¼ltigkeitsdatum ist ungÃ¼ltig (Sollformat ist JJJJMMTT-JJJJMMTT)";
      case LUT2_INDEX_OUT_OF_RANGE: return "Der Index fÃ¼r die Filiale ist ungÃ¼ltig";
      case LUT2_INIT_IN_PROGRESS: return "Die Bibliothek wird gerade neu initialisiert";
      case LUT2_BLZ_NOT_INITIALIZED: return "Das Feld BLZ wurde nicht initialisiert";
      case LUT2_FILIALEN_NOT_INITIALIZED: return "Das Feld Filialen wurde nicht initialisiert";
      case LUT2_NAME_NOT_INITIALIZED: return "Das Feld Bankname wurde nicht initialisiert";
      case LUT2_PLZ_NOT_INITIALIZED: return "Das Feld PLZ wurde nicht initialisiert";
      case LUT2_ORT_NOT_INITIALIZED: return "Das Feld Ort wurde nicht initialisiert";
      case LUT2_NAME_KURZ_NOT_INITIALIZED: return "Das Feld Kurzname wurde nicht initialisiert";
      case LUT2_PAN_NOT_INITIALIZED: return "Das Feld PAN wurde nicht initialisiert";
      case LUT2_BIC_NOT_INITIALIZED: return "Das Feld BIC wurde nicht initialisiert";
      case LUT2_PZ_NOT_INITIALIZED: return "Das Feld PrÃ¼fziffer wurde nicht initialisiert";
      case LUT2_NR_NOT_INITIALIZED: return "Das Feld NR wurde nicht initialisiert";
      case LUT2_AENDERUNG_NOT_INITIALIZED: return "Das Feld Ã„nderung wurde nicht initialisiert";
      case LUT2_LOESCHUNG_NOT_INITIALIZED: return "Das Feld LÃ¶schung wurde nicht initialisiert";
      case LUT2_NACHFOLGE_BLZ_NOT_INITIALIZED: return "Das Feld Nachfolge-BLZ wurde nicht initialisiert";
      case LUT2_NOT_INITIALIZED: return "die Programmbibliothek wurde noch nicht initialisiert";
      case LUT2_FILIALEN_MISSING: return "der Block mit der Filialenanzahl fehlt in der LUT-Datei";
      case LUT2_PARTIAL_OK: return "es wurden nicht alle Blocks geladen";
      case LUT2_Z_BUF_ERROR: return "Buffer error in den ZLIB Routinen";
      case LUT2_Z_MEM_ERROR: return "Memory error in den ZLIB-Routinen";
      case LUT2_Z_DATA_ERROR: return "Datenfehler im komprimierten LUT-Block";
      case LUT2_BLOCK_NOT_IN_FILE: return "Der Block ist nicht in der LUT-Datei enthalten";
      case LUT2_DECOMPRESS_ERROR: return "Fehler beim Dekomprimieren eines LUT-Blocks";
      case LUT2_COMPRESS_ERROR: return "Fehler beim Komprimieren eines LUT-Blocks";
      case LUT2_FILE_CORRUPTED: return "Die LUT-Datei ist korrumpiert";
      case LUT2_NO_SLOT_FREE: return "Im Inhaltsverzeichnis der LUT-Datei ist kein Slot mehr frei";
      case UNDEFINED_SUBMETHOD: return "Die (Unter)Methode ist nicht definiert";
      case EXCLUDED_AT_COMPILETIME: return "Der benÃ¶tigte Programmteil wurde beim Kompilieren deaktiviert";
      case INVALID_LUT_VERSION: return "Die Versionsnummer fÃ¼r die LUT-Datei ist ungÃ¼ltig";
      case INVALID_PARAMETER_STELLE1: return "ungÃ¼ltiger PrÃ¼fparameter (erste zu prÃ¼fende Stelle)";
      case INVALID_PARAMETER_COUNT: return "ungÃ¼ltiger PrÃ¼fparameter (Anzahl zu prÃ¼fender Stellen)";
      case INVALID_PARAMETER_PRUEFZIFFER: return "ungÃ¼ltiger PrÃ¼fparameter (Position der PrÃ¼fziffer)";
      case INVALID_PARAMETER_WICHTUNG: return "ungÃ¼ltiger PrÃ¼fparameter (Wichtung)";
      case INVALID_PARAMETER_METHODE: return "ungÃ¼ltiger PrÃ¼fparameter (Rechenmethode)";
      case LIBRARY_INIT_ERROR: return "Problem beim Initialisieren der globalen Variablen";
      case LUT_CRC_ERROR: return "PrÃ¼fsummenfehler in der blz.lut Datei";
      case FALSE_GELOESCHT: return "falsch (die BLZ wurde auÃŸerdem gelÃ¶scht)";
      case OK_NO_CHK_GELOESCHT: return "ok, ohne PrÃ¼fung (die BLZ wurde allerdings gelÃ¶scht)";
      case OK_GELOESCHT: return "ok (die BLZ wurde allerdings gelÃ¶scht)";
      case BLZ_GELOESCHT: return "die Bankleitzahl wurde gelÃ¶scht";
      case INVALID_BLZ_FILE: return "Fehler in der blz.txt Datei (falsche ZeilenlÃ¤nge)";
      case LIBRARY_IS_NOT_THREAD_SAFE: return "undefinierte Funktion, die library wurde mit THREAD_SAFE=0 kompiliert";
      case FATAL_ERROR: return "schwerer Fehler im Konto_check-Modul";
      case INVALID_KTO_LENGTH: return "ein Konto muÃŸ zwischen 1 und 10 Stellen haben";
      case FILE_WRITE_ERROR: return "kann Datei nicht schreiben";
      case FILE_READ_ERROR: return "kann Datei nicht lesen";
      case ERROR_MALLOC: return "kann keinen Speicher allokieren";
      case NO_BLZ_FILE: return "die blz.txt Datei wurde nicht gefunden";
      case INVALID_LUT_FILE: return "die blz.lut Datei ist inkosistent/ungÃ¼ltig";
      case NO_LUT_FILE: return "die blz.lut Datei wurde nicht gefunden";
      case INVALID_BLZ_LENGTH: return "die Bankleitzahl ist nicht achtstellig";
      case INVALID_BLZ: return "die Bankleitzahl ist ungÃ¼ltig";
      case INVALID_KTO: return "das Konto ist ungÃ¼ltig";
      case NOT_IMPLEMENTED: return "die Methode wurde noch nicht implementiert";
      case NOT_DEFINED: return "die Methode ist nicht definiert";
      case FALSE: return "falsch";
      case OK: return "ok";
      case EE: if(eep)return (char *)eep; else return "";
      case OK_NO_CHK: return "ok, ohne PrÃ¼fung";
      case OK_TEST_BLZ_USED: return "ok, fÃ¼r den Test wurde eine Test-BLZ verwendet";
      case LUT2_VALID: return "Der Datensatz ist aktuell gÃ¼ltig";
      case LUT2_NO_VALID_DATE: return "Der Datensatz enthÃ¤lt kein GÃ¼ltigkeitsdatum";
      case LUT1_SET_LOADED: return "Die Datei ist im alten LUT-Format (1.0/1.1)";
      case LUT1_FILE_GENERATED: return "ok, es wurde allerdings eine LUT-Datei im alten Format (1.0/1.1) generiert";
      case LUT_V2_FILE_GENERATED: return "ok, es wurde allerdings eine LUT-Datei im Format 2.0 generiert (Compilerswitch)";
      case KTO_CHECK_VALUE_REPLACED: return "ok, der Wert fÃ¼r den SchlÃ¼ssel wurde Ã¼berschrieben";
      case OK_UNTERKONTO_POSSIBLE: return "wahrscheinlich ok, die Kontonummer kann allerdings (nicht angegebene) Unterkonten enthalten";
      case OK_UNTERKONTO_GIVEN: return "wahrscheinlich ok, die Kontonummer enthÃ¤lt eine Unterkontonummer";
      case OK_SLOT_CNT_MIN_USED: return "ok, die Anzahl Slots wurde auf SLOT_CNT_MIN (60) hochgesetzt";
      case SOME_KEYS_NOT_FOUND: return "ok, ein(ige) SchlÃ¼ssel wurden nicht gefunden";
      case LUT2_KTO_NOT_CHECKED: return "Die Bankverbindung wurde nicht getestet";
      case LUT2_OK_WITHOUT_IBAN_RULES: return "Es wurden fast alle Blocks (auÃŸer den IBAN-Regeln) geladen";
      case OK_NACHFOLGE_BLZ_USED: return "ok, fÃ¼r die BLZ wurde allerdings die Nachfolge-BLZ eingesetzt";
      case OK_KTO_REPLACED: return "ok, die Kontonummer wurde allerdings ersetzt";
      case OK_BLZ_REPLACED: return "ok, die Bankleitzahl wurde allerdings ersetzt";
      case OK_BLZ_KTO_REPLACED: return "ok, die Bankleitzahl und Kontonummer wurden allerdings ersetzt";
      case OK_IBAN_WITHOUT_KC_TEST: return "ok, die Bankverbindung ist (ohne Test) als richtig anzusehen";
      case OK_INVALID_FOR_IBAN: return "ok, fÃ¼r die die IBAN ist (durch eine Regel) allerdings ein anderer BIC definiert";
      case OK_HYPO_REQUIRES_KTO: return "ok, fÃ¼r die BIC-Bestimmung der ehemaligen Hypo-Bank fÃ¼r IBAN wird i.A. zusÃ¤tzlich die Kontonummer benÃ¶tigt";
      case OK_KTO_REPLACED_NO_PZ: return "ok, die Kontonummer wurde ersetzt, die neue Kontonummer hat keine PrÃ¼fziffer";
      case OK_UNTERKONTO_ATTACHED: return "ok, es wurde ein (weggelassenes) Unterkonto angefÃ¼gt";
      case OK_SHORT_BIC_USED: return "ok, fÃ¼r den BIC wurde die Zweigstellennummer allerdings durch XXX ersetzt";
      case OK_SCL_EXTENSION_BIC_USED: return "ok, fÃ¼r den BIC wurde die Extension XXX angehÃ¤ngt";
      case OK_SCL_WILDCARD_BIC_USED: return "ok, fÃ¼r den BIC wurde die Wildcard-Version (8stellig) benutzt";
      default: return "ungÃ¼ltiger RÃ¼ckgabewert";
   }
}

/* Funktion kto_check_retval2txt_short() +§§§1 */
/* ###########################################################################
 * # Die Funktion kto_check_retval2txt_short() wandelt die numerischen       #
 * # Rückgabwerte in kurze Klartexte (symbolische Konstanten) um.            #
 * #                                                                         #
 * # Copyright (C) 2007 Michael Plugge <m.plugge@hs-mannheim.de>             #
 * ###########################################################################
 */

DLL_EXPORT const char *kto_check_retval2txt_short(int retval)
{
   switch(retval){
      case NO_SCL_BLOCKS_LOADED: return "NO_SCL_BLOCKS_LOADED";
      case NO_SCL_INFO_BLOCK: return "NO_SCL_INFO_BLOCK";
      case SCL_BIC_NOT_FOUND: return "SCL_BIC_NOT_FOUND";
      case INVALID_SCL_INFO_BLOCK: return "INVALID_SCL_INFO_BLOCK";
      case NO_SCL_BLOCKS: return "NO_SCL_BLOCKS";
      case SCL_INPUT_FORMAT_ERROR: return "SCL_INPUT_FORMAT_ERROR";
      case INVALID_REGULAR_EXPRESSION_CNT: return "INVALID_REGULAR_EXPRESSION_CNT";
      case INVALID_REGULAR_EXPRESSION: return "INVALID_REGULAR_EXPRESSION";
      case INVALID_HANDLE: return "INVALID_HANDLE";
      case INVALID_BIQ_INDEX: return "INVALID_BIQ_INDEX";
      case ARRAY_INDEX_OUT_OF_RANGE: return "ARRAY_INDEX_OUT_OF_RANGE";
      case IBAN_ONLY_GERMAN: return "IBAN_ONLY_GERMAN";
      case INVALID_PARAMETER_TYPE: return "INVALID_PARAMETER_TYPE";
      case BIC_ONLY_GERMAN: return "BIC_ONLY_GERMAN";
      case INVALID_BIC_LENGTH: return "INVALID_BIC_LENGTH";
      case IBAN_CHKSUM_OK_RULE_IGNORED_BLZ: return "IBAN_CHKSUM_OK_RULE_IGNORED_BLZ";
      case IBAN_CHKSUM_OK_KC_NOT_INITIALIZED: return "IBAN_CHKSUM_OK_KC_NOT_INITIALIZED";
      case IBAN_CHKSUM_OK_BLZ_INVALID: return "IBAN_CHKSUM_OK_BLZ_INVALID";
      case IBAN_CHKSUM_OK_NACHFOLGE_BLZ_DEFINED: return "IBAN_CHKSUM_OK_NACHFOLGE_BLZ_DEFINED";
      case LUT2_NOT_ALL_IBAN_BLOCKS_LOADED: return "LUT2_NOT_ALL_IBAN_BLOCKS_LOADED";
      case LUT2_NOT_YET_VALID_PARTIAL_OK: return "LUT2_NOT_YET_VALID_PARTIAL_OK";
      case LUT2_NO_LONGER_VALID_PARTIAL_OK: return "LUT2_NO_LONGER_VALID_PARTIAL_OK";
      case LUT2_BLOCKS_MISSING: return "LUT2_BLOCKS_MISSING";
      case FALSE_UNTERKONTO_ATTACHED: return "FALSE_UNTERKONTO_ATTACHED";
      case BLZ_BLACKLISTED: return "BLZ_BLACKLISTED";
      case BLZ_MARKED_AS_DELETED: return "BLZ_MARKED_AS_DELETED";
      case IBAN_CHKSUM_OK_SOMETHING_WRONG: return "IBAN_CHKSUM_OK_SOMETHING_WRONG";
      case IBAN_CHKSUM_OK_NO_IBAN_CALCULATION: return "IBAN_CHKSUM_OK_NO_IBAN_CALCULATION";
      case IBAN_CHKSUM_OK_RULE_IGNORED: return "IBAN_CHKSUM_OK_RULE_IGNORED";
      case IBAN_CHKSUM_OK_UNTERKTO_MISSING: return "IBAN_CHKSUM_OK_UNTERKTO_MISSING";
      case IBAN_INVALID_RULE: return "IBAN_INVALID_RULE";
      case IBAN_AMBIGUOUS_KTO: return "IBAN_AMBIGUOUS_KTO";
      case IBAN_RULE_NOT_IMPLEMENTED: return "IBAN_RULE_NOT_IMPLEMENTED";
      case IBAN_RULE_UNKNOWN: return "IBAN_RULE_UNKNOWN";
      case NO_IBAN_CALCULATION: return "NO_IBAN_CALCULATION";
      case OLD_BLZ_OK_NEW_NOT: return "OLD_BLZ_OK_NEW_NOT";
      case LUT2_IBAN_REGEL_NOT_INITIALIZED: return "LUT2_IBAN_REGEL_NOT_INITIALIZED";
      case INVALID_IBAN_LENGTH: return "INVALID_IBAN_LENGTH";
      case LUT2_NO_ACCOUNT_GIVEN: return "LUT2_NO_ACCOUNT_GIVEN";
      case LUT2_VOLLTEXT_INVALID_CHAR: return "LUT2_VOLLTEXT_INVALID_CHAR";
      case LUT2_VOLLTEXT_SINGLE_WORD_ONLY: return "LUT2_VOLLTEXT_SINGLE_WORD_ONLY";
      case LUT_SUCHE_INVALID_RSC: return "LUT_SUCHE_INVALID_RSC";
      case LUT_SUCHE_INVALID_CMD: return "LUT_SUCHE_INVALID_CMD";
      case LUT_SUCHE_INVALID_CNT: return "LUT_SUCHE_INVALID_CNT";
      case LUT2_VOLLTEXT_NOT_INITIALIZED: return "LUT2_VOLLTEXT_NOT_INITIALIZED";
      case NO_OWN_IBAN_CALCULATION: return "NO_OWN_IBAN_CALCULATION";
      case KTO_CHECK_UNSUPPORTED_COMPRESSION: return "KTO_CHECK_UNSUPPORTED_COMPRESSION";
      case KTO_CHECK_INVALID_COMPRESSION_LIB: return "KTO_CHECK_INVALID_COMPRESSION_LIB";
      case OK_UNTERKONTO_ATTACHED_OLD: return "OK_UNTERKONTO_ATTACHED_OLD";
      case KTO_CHECK_DEFAULT_BLOCK_INVALID: return "KTO_CHECK_DEFAULT_BLOCK_INVALID";
      case KTO_CHECK_DEFAULT_BLOCK_FULL: return "KTO_CHECK_DEFAULT_BLOCK_FULL";
      case KTO_CHECK_NO_DEFAULT_BLOCK: return "KTO_CHECK_NO_DEFAULT_BLOCK";
      case KTO_CHECK_KEY_NOT_FOUND: return "KTO_CHECK_KEY_NOT_FOUND";
      case LUT2_NO_LONGER_VALID_BETTER: return "LUT2_NO_LONGER_VALID_BETTER";
      case INVALID_SEARCH_RANGE: return "INVALID_SEARCH_RANGE";
      case KEY_NOT_FOUND: return "KEY_NOT_FOUND";
      case BAV_FALSE: return "BAV_FALSE";
      case LUT2_NO_USER_BLOCK: return "LUT2_NO_USER_BLOCK";
      case INVALID_SET: return "INVALID_SET";
      case NO_GERMAN_BIC: return "NO_GERMAN_BIC";
      case IPI_CHECK_INVALID_LENGTH: return "IPI_CHECK_INVALID_LENGTH";
      case IPI_INVALID_CHARACTER: return "IPI_INVALID_CHARACTER";
      case IPI_INVALID_LENGTH: return "IPI_INVALID_LENGTH";
      case LUT1_FILE_USED: return "LUT1_FILE_USED";
      case MISSING_PARAMETER: return "MISSING_PARAMETER";
      case IBAN2BIC_ONLY_GERMAN: return "IBAN2BIC_ONLY_GERMAN";
      case IBAN_OK_KTO_NOT: return "IBAN_OK_KTO_NOT";
      case KTO_OK_IBAN_NOT: return "KTO_OK_IBAN_NOT";
      case TOO_MANY_SLOTS: return "TOO_MANY_SLOTS";
      case INIT_FATAL_ERROR: return "INIT_FATAL_ERROR";
      case INCREMENTAL_INIT_NEEDS_INFO: return "INCREMENTAL_INIT_NEEDS_INFO";
      case INCREMENTAL_INIT_FROM_DIFFERENT_FILE: return "INCREMENTAL_INIT_FROM_DIFFERENT_FILE";
      case DEBUG_ONLY_FUNCTION: return "DEBUG_ONLY_FUNCTION";
      case LUT2_INVALID: return "LUT2_INVALID";
      case LUT2_NOT_YET_VALID: return "LUT2_NOT_YET_VALID";
      case LUT2_NO_LONGER_VALID: return "LUT2_NO_LONGER_VALID";
      case LUT2_GUELTIGKEIT_SWAPPED: return "LUT2_GUELTIGKEIT_SWAPPED";
      case LUT2_INVALID_GUELTIGKEIT: return "LUT2_INVALID_GUELTIGKEIT";
      case LUT2_INDEX_OUT_OF_RANGE: return "LUT2_INDEX_OUT_OF_RANGE";
      case LUT2_INIT_IN_PROGRESS: return "LUT2_INIT_IN_PROGRESS";
      case LUT2_BLZ_NOT_INITIALIZED: return "LUT2_BLZ_NOT_INITIALIZED";
      case LUT2_FILIALEN_NOT_INITIALIZED: return "LUT2_FILIALEN_NOT_INITIALIZED";
      case LUT2_NAME_NOT_INITIALIZED: return "LUT2_NAME_NOT_INITIALIZED";
      case LUT2_PLZ_NOT_INITIALIZED: return "LUT2_PLZ_NOT_INITIALIZED";
      case LUT2_ORT_NOT_INITIALIZED: return "LUT2_ORT_NOT_INITIALIZED";
      case LUT2_NAME_KURZ_NOT_INITIALIZED: return "LUT2_NAME_KURZ_NOT_INITIALIZED";
      case LUT2_PAN_NOT_INITIALIZED: return "LUT2_PAN_NOT_INITIALIZED";
      case LUT2_BIC_NOT_INITIALIZED: return "LUT2_BIC_NOT_INITIALIZED";
      case LUT2_PZ_NOT_INITIALIZED: return "LUT2_PZ_NOT_INITIALIZED";
      case LUT2_NR_NOT_INITIALIZED: return "LUT2_NR_NOT_INITIALIZED";
      case LUT2_AENDERUNG_NOT_INITIALIZED: return "LUT2_AENDERUNG_NOT_INITIALIZED";
      case LUT2_LOESCHUNG_NOT_INITIALIZED: return "LUT2_LOESCHUNG_NOT_INITIALIZED";
      case LUT2_NACHFOLGE_BLZ_NOT_INITIALIZED: return "LUT2_NACHFOLGE_BLZ_NOT_INITIALIZED";
      case LUT2_NOT_INITIALIZED: return "LUT2_NOT_INITIALIZED";
      case LUT2_FILIALEN_MISSING: return "LUT2_FILIALEN_MISSING";
      case LUT2_PARTIAL_OK: return "LUT2_PARTIAL_OK";
      case LUT2_Z_BUF_ERROR: return "LUT2_Z_BUF_ERROR";
      case LUT2_Z_MEM_ERROR: return "LUT2_Z_MEM_ERROR";
      case LUT2_Z_DATA_ERROR: return "LUT2_Z_DATA_ERROR";
      case LUT2_BLOCK_NOT_IN_FILE: return "LUT2_BLOCK_NOT_IN_FILE";
      case LUT2_DECOMPRESS_ERROR: return "LUT2_DECOMPRESS_ERROR";
      case LUT2_COMPRESS_ERROR: return "LUT2_COMPRESS_ERROR";
      case LUT2_FILE_CORRUPTED: return "LUT2_FILE_CORRUPTED";
      case LUT2_NO_SLOT_FREE: return "LUT2_NO_SLOT_FREE";
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
      case EE: return "EE";
      case OK_NO_CHK: return "OK_NO_CHK";
      case OK_TEST_BLZ_USED: return "OK_TEST_BLZ_USED";
      case LUT2_VALID: return "LUT2_VALID";
      case LUT2_NO_VALID_DATE: return "LUT2_NO_VALID_DATE";
      case LUT1_SET_LOADED: return "LUT1_SET_LOADED";
      case LUT1_FILE_GENERATED: return "LUT1_FILE_GENERATED";
      case LUT_V2_FILE_GENERATED: return "LUT_V2_FILE_GENERATED";
      case KTO_CHECK_VALUE_REPLACED: return "KTO_CHECK_VALUE_REPLACED";
      case OK_UNTERKONTO_POSSIBLE: return "OK_UNTERKONTO_POSSIBLE";
      case OK_UNTERKONTO_GIVEN: return "OK_UNTERKONTO_GIVEN";
      case OK_SLOT_CNT_MIN_USED: return "OK_SLOT_CNT_MIN_USED";
      case SOME_KEYS_NOT_FOUND: return "SOME_KEYS_NOT_FOUND";
      case LUT2_KTO_NOT_CHECKED: return "LUT2_KTO_NOT_CHECKED";
      case LUT2_OK_WITHOUT_IBAN_RULES: return "LUT2_OK_WITHOUT_IBAN_RULES";
      case OK_NACHFOLGE_BLZ_USED: return "OK_NACHFOLGE_BLZ_USED";
      case OK_KTO_REPLACED: return "OK_KTO_REPLACED";
      case OK_BLZ_REPLACED: return "OK_BLZ_REPLACED";
      case OK_BLZ_KTO_REPLACED: return "OK_BLZ_KTO_REPLACED";
      case OK_IBAN_WITHOUT_KC_TEST: return "OK_IBAN_WITHOUT_KC_TEST";
      case OK_INVALID_FOR_IBAN: return "OK_INVALID_FOR_IBAN";
      case OK_HYPO_REQUIRES_KTO: return "OK_HYPO_REQUIRES_KTO";
      case OK_KTO_REPLACED_NO_PZ: return "OK_KTO_REPLACED_NO_PZ";
      case OK_UNTERKONTO_ATTACHED: return "OK_UNTERKONTO_ATTACHED";
      case OK_SHORT_BIC_USED: return "OK_SHORT_BIC_USED";
      case OK_SCL_EXTENSION_BIC_USED: return "OK_SCL_EXTENSION_BIC_USED";
      case OK_SCL_WILDCARD_BIC_USED: return "OK_SCL_WILDCARD_BIC_USED";
      default: return "UNDEFINED_RETVAL";
   }
}

