#!perl -w

# Testfaelle fuer das Modul Config::Manager::Conf

# Es fehlen noch folgende Testfaelle:
#  - Weitere Testfaelle zum Erkennen von Syntaxfehlern (jede Fehlermeldung des
#    Parsers sollte mindestens einmal provoziert werden)
#  - Syntaxfehler beim set() erkennen (nicht nur beim Einlesen aus Datei)
#  - Fehlermeldung, wenn das get() bei einer Substitution fehlschlaegt (d.h.
#    jene Fehlermeldungen, die erst beim Auswerten ausgespuckt werden)

use strict;
#use diagnostics;
use Config::Manager::Conf;

my $n = 0;
my $conf;
my $result;

sub ok {
    $n++;
    print "ok $n\n";
}

sub nok {
    $n++;
    print "not ok $n\n";
#   die "That's all, folks!\n";
}

sub conf {
    my $c = Config::Manager::Conf->new();
    # Dateien einlesen
    $c->add('t/conf_private.ini', 't/conf_public.ini') || die 'Unable to read files';
    # Kommandozeilenargumente setzen
    $c->set('INSTDIR', 'inst') || die 'Unable to set command line options';
    return $c;
}

print "1..445\n";

################################################################################
# Werden fatale Fehler als solche erkannt und gemeldet?                        #
################################################################################

############################################################
# Datei nicht vorhanden
############################################################

# Datei nicht vorhanden
$conf = Config::Manager::Conf->new();
defined $conf->add('t/bullshit.ini') ? nok() : ok();
# Fehlermeldung?
$conf->error() =~ m!^Unable to open file 't/bullshit\.ini':! ? ok() : nok();

# Datei nicht vorhanden, aber nachher korrekte Daten
$conf = Config::Manager::Conf->new();
defined $conf->add('t/bullshit.ini', 't/conf_public.ini') ? nok() : ok();
# Fehlermeldung?
$conf->error() =~ m!^Unable to open file 't/bullshit\.ini':! ? ok() : nok();

# Datei nicht vorhanden, aber vorher korrekte Dateien
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_private.ini', 't/bullshit.ini') ? nok() : ok();
# Fehlermeldung?
$conf->error() =~ m!^Unable to open file 't/bullshit\.ini':! ? ok() : nok();

# Datei nicht vorhanden, aber vorher und nachher korrekte Dateien
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_private.ini', 't/bullshit.ini', 't/conf_public.ini') ? nok() : ok();
# Fehlermeldung?
$conf->error() =~ m!^Unable to open file 't/bullshit\.ini':! ? ok() : nok();

############################################################
# Fehlerhafte Abschnittsueberschriften
############################################################

# Schliessende Klammer fehlt
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_section01.ini') ? nok() : ok();
# Fehlermeldung?
$conf->error() eq "Syntax error in file 't/conf_err_section01.ini' line #7 [DEFAULT]: [TWO" ? ok() : nok();
# Voriger Wert trotzdem eingelesen?
$conf->get('HELLO') eq 'hello' ? ok() : nok();

# Oeffnende Klammer fehlt
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_section02.ini') ? nok() : ok();
# Fehlermeldung?
$conf->error() eq "Syntax error in file 't/conf_err_section02.ini' line #7 [DEFAULT]: TWO]" ? ok() : nok();
# Voriger Wert trotzdem eingelesen?
$conf->get('HELLO') eq 'hello' ? ok() : nok();

# Text nach der Abschnittueberschrift
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_section03.ini') ? nok() : ok();
# Fehlermeldung?
$conf->error() eq "Syntax error in file 't/conf_err_section03.ini' line #7 [DEFAULT]: [TWO] # geht nicht" ? ok() : nok();
# Voriger Wert trotzdem eingelesen?
$conf->get('HELLO') eq 'hello' ? ok() : nok();

# Beginnt mit Bindestrich
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_section04.ini') ? nok() : ok();
# Fehlermeldung?
$conf->error() eq "Syntax error in file 't/conf_err_section04.ini' line #7 [DEFAULT]: [-TWO]" ? ok() : nok();
# Voriger Wert trotzdem eingelesen?
$conf->get('HELLO') eq 'hello' ? ok() : nok();

# Endet mit Bindestrich
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_section05.ini') ? nok() : ok();
# Fehlermeldung?
$conf->error() eq "Syntax error in file 't/conf_err_section05.ini' line #7 [DEFAULT]: [TWO-]" ? ok() : nok();
# Voriger Wert trotzdem eingelesen?
$conf->get('HELLO') eq 'hello' ? ok() : nok();

# Nur Bindestrich
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_section06.ini') ? nok() : ok();
# Fehlermeldung?
$conf->error() eq "Syntax error in file 't/conf_err_section06.ini' line #7 [DEFAULT]: [-]" ? ok() : nok();
# Voriger Wert trotzdem eingelesen?
$conf->get('HELLO') eq 'hello' ? ok() : nok();

# Beginnt mit Ziffer
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_section07.ini') ? nok() : ok();
# Fehlermeldung?
$conf->error() eq "Syntax error in file 't/conf_err_section07.ini' line #7 [DEFAULT]: [7Zwerge]" ? ok() : nok();
# Voriger Wert trotzdem eingelesen?
$conf->get('HELLO') eq 'hello' ? ok() : nok();

# Besteht nur aus Ziffer
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_section08.ini') ? nok() : ok();
# Fehlermeldung?
$conf->error() eq "Syntax error in file 't/conf_err_section08.ini' line #7 [DEFAULT]: [8]" ? ok() : nok();
# Voriger Wert trotzdem eingelesen?
$conf->get('HELLO') eq 'hello' ? ok() : nok();

# Beginnt mit Unterstrich
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_section09.ini') ? nok() : ok();
# Fehlermeldung?
$conf->error() eq "Syntax error in file 't/conf_err_section09.ini' line #7 [DEFAULT]: [_score]" ? ok() : nok();
# Voriger Wert trotzdem eingelesen?
$conf->get('HELLO') eq 'hello' ? ok() : nok();

# Nur Unterstrich
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_section10.ini') ? nok() : ok();
# Fehlermeldung?
$conf->error() eq "Syntax error in file 't/conf_err_section10.ini' line #7 [DEFAULT]: [_]" ? ok() : nok();
# Voriger Wert trotzdem eingelesen?
$conf->get('HELLO') eq 'hello' ? ok() : nok();

############################################################
# Fehlerhafte Schluessel
############################################################

# Keine Zuweisung
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_key01.ini') ? nok() : ok();
# Fehlermeldung?
$conf->error() eq "Syntax error in file 't/conf_err_key01.ini' line #8 [TWO]: THIS" ? ok() : nok();
# Voriger Wert trotzdem eingelesen?
$conf->get('HELLO') eq 'hello' ? ok() : nok();

# Zweiteilig
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_key02.ini') ? nok() : ok();
# Fehlermeldung?
$conf->error() eq "Syntax error in file 't/conf_err_key02.ini' line #8 [TWO]: THIS IS = wrong" ? ok() : nok();
# Voriger Wert trotzdem eingelesen?
$conf->get('HELLO') eq 'hello' ? ok() : nok();

# Numerisch
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_key03.ini') ? nok() : ok();
# Fehlermeldung?
$conf->error() eq "Syntax error in file 't/conf_err_key03.ini' line #8 [TWO]: 7 = wrong" ? ok() : nok();
# Voriger Wert trotzdem eingelesen?
$conf->get('HELLO') eq 'hello' ? ok() : nok();

# Numerischer Anfang
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_key04.ini') ? nok() : ok();
# Fehlermeldung?
$conf->error() eq "Syntax error in file 't/conf_err_key04.ini' line #8 [TWO]: 4U = wrong" ? ok() : nok();
# Voriger Wert trotzdem eingelesen?
$conf->get('HELLO') eq 'hello' ? ok() : nok();

# Anfang mit Unterstrich
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_key05.ini') ? nok() : ok();
# Fehlermeldung?
$conf->error() eq "Syntax error in file 't/conf_err_key05.ini' line #8 [TWO]: _X = wrong" ? ok() : nok();
# Voriger Wert trotzdem eingelesen?
$conf->get('HELLO') eq 'hello' ? ok() : nok();

# Substitutionsversuch
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_key06.ini') ? nok() : ok();
# Fehlermeldung?
$conf->error() eq "Syntax error in file 't/conf_err_key06.ini' line #8 [TWO]: X\$HELLO = wrong" ? ok() : nok();
# Voriger Wert trotzdem eingelesen?
$conf->get('HELLO') eq 'hello' ? ok() : nok();

# Nicht angegeben (Zeile beginnt mit "=")
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_key07.ini') ? nok() : ok();
# Fehlermeldung?
$conf->error() eq "Syntax error in file 't/conf_err_key07.ini' line #8 [TWO]:  = wrong" ? ok() : nok();
# Voriger Wert trotzdem eingelesen?
$conf->get('HELLO') eq 'hello' ? ok() : nok();

# Anfang mit Bindestrich
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_key08.ini') ? nok() : ok();
# Fehlermeldung?
$conf->error() eq "Syntax error in file 't/conf_err_key08.ini' line #8 [TWO]: -HELLO = wrong" ? ok() : nok();
# Voriger Wert trotzdem eingelesen?
$conf->get('HELLO') eq 'hello' ? ok() : nok();

# Ende mit Bindestrich
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_key09.ini') ? nok() : ok();
# Fehlermeldung?
$conf->error() eq "Syntax error in file 't/conf_err_key09.ini' line #8 [TWO]: HELLO- = wrong" ? ok() : nok();
# Voriger Wert trotzdem eingelesen?
$conf->get('HELLO') eq 'hello' ? ok() : nok();

# Nur Bindestrich
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_key10.ini') ? nok() : ok();
# Fehlermeldung?
$conf->error() eq "Syntax error in file 't/conf_err_key10.ini' line #8 [TWO]: - = wrong" ? ok() : nok();
# Voriger Wert trotzdem eingelesen?
$conf->get('HELLO') eq 'hello' ? ok() : nok();

############################################################
# Doppelte Schluessel
############################################################

# Doppelter Schluessel in Default-Section
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_dk01.ini') ? nok() : ok();
# Fehlermeldung?
$conf->error() eq "Double entry in file 't/conf_err_dk01.ini' for configuration constant \$[DEFAULT]{A} in line #6 and #8" ? ok() : nok();
# Voriger Wert trotzdem eingelesen?
$conf->get('HELLO') eq 'hello' ? ok() : nok();

# Doppelter Schluessel in einer Section
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_dk02.ini') ? nok() : ok();
# Fehlermeldung?
$conf->error() eq "Double entry in file 't/conf_err_dk02.ini' for configuration constant \$[ONE]{A} in line #8 and #10" ? ok() : nok();
# Voriger Wert trotzdem eingelesen?
$conf->get('HELLO') eq 'hello' ? ok() : nok();

# Doppelter Schluessel in einer zweigeteilten Section
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_dk03.ini') ? nok() : ok();
# Fehlermeldung?
$conf->error() eq "Double entry in file 't/conf_err_dk03.ini' for configuration constant \$[ONE]{A} in line #8 and #14" ? ok() : nok();
# Voriger Wert trotzdem eingelesen?
$conf->get('HELLO') eq 'hello' ? ok() : nok();

# Doppelter nextconf-Eintrag
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_dk04.ini') ? nok() : ok();
# Fehlermeldung?
$conf->error() eq "Double entry in file 't/conf_err_dk04.ini' for configuration constant \$[NONE]{NEXTCONF} in line #8 and #9" ? ok() : nok();
# Voriger Wert trotzdem eingelesen?
$conf->get('HELLO') eq 'hello' ? ok() : nok();

############################################################
# Fehlerhafte Werte
############################################################

# Kein Wert angegeben
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_val01.ini') ? nok() : ok();
# Fehlermeldung?
$conf->error() eq "Syntax error in file 't/conf_err_val01.ini' line #5 [DEFAULT]: EMPTY =" ? ok() : nok();

# Als Wert nur Leerzeichen angegeben
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_val02.ini') ? nok() : ok();
# Fehlermeldung?
$conf->error() eq "Syntax error in file 't/conf_err_val02.ini' line #5 [DEFAULT]: EMPTY =" ? ok() : nok();

# Verunglueckte Sustitution: Blank zwischen $ und Key
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_val03.ini') ? nok() : ok();
$conf->error() eq "Syntax error in file 't/conf_err_val03.ini' line #6 [DEFAULT]: found '\$' followed by ' ', expecting '{' or [A-Za-z]" ? ok() : nok();

# Verunglueckte Substitution: Nur oeffnende Klammer
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_val04.ini') ? nok() : ok();
$conf->error() eq "Syntax error in file 't/conf_err_val04.ini' line #6 [DEFAULT]: missing '}' after variable name 'SYS', unexpected end of string" ? ok() : nok();

# Verunglueckte qualifizierte Substitution: Nur oeffnende Klammer
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_val05.ini') ? nok() : ok();
$conf->error() eq "Syntax error in file 't/conf_err_val05.ini' line #6 [DEFAULT]: missing ']' after section name 'A', found '{' instead" ? ok() : nok();

# Verunglueckte qualifizierte Substition: Nur Section
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_val06.ini') ? nok() : ok();
$conf->error() eq "Syntax error in file 't/conf_err_val06.ini' line #6 [DEFAULT]: missing key name after section name 'A', unexpected end of string" ? ok() : nok();

# Verunglueckte qualifizierte Substition: Nur oeffnende Klammer und Section
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_val07.ini') ? nok() : ok();
$conf->error() eq "Syntax error in file 't/conf_err_val07.ini' line #6 [DEFAULT]: expecting identifier or variable, unexpected end of string" ? ok() : nok();

# Verunglueckte qualifizierte Substition: Nur Section und schliessende Klammer
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_val08.ini') ? nok() : ok();
$conf->error() eq "Syntax error in file 't/conf_err_val08.ini' line #6 [DEFAULT]: found '\$[A]' followed by '}', expecting '{' or [A-Za-z]" ? ok() : nok();

# Verunglueckte Substition: Dollar am Zeilenende
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_val09.ini') ? nok() : ok();
$conf->error() eq "Syntax error in file 't/conf_err_val09.ini' line #6 [DEFAULT]: illegal '\$' at end of string" ? ok() : nok();

# Verunglueckte Substition: Variable beginnt mit Bindestrich
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_val10.ini') ? nok() : ok();
$conf->error() eq "Syntax error in file 't/conf_err_val10.ini' line #6 [DEFAULT]: found '\$' followed by '-', expecting '{' or [A-Za-z]" ? ok() : nok();

# Verunglueckte Substition: Variable endet mit Bindestrich
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_val11.ini') ? nok() : ok();
$conf->error() eq "Syntax error in file 't/conf_err_val11.ini' line #6 [DEFAULT]: illegal terminating '-' in identifier 'NO-NO-'" ? ok() : nok();

############################################################
# Schreibzugriffe auf reservierte Sections
############################################################

# Versuch, eine Umgebungsvariable aus einer Datei einzulesen
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_wp01.ini') ? nok() : ok();
$conf->error() eq 'Configuration constant $[ENV]{TMP} is read-only' ? ok() : nok();
# Versuch, eine Umgebungsvariable zu setzen
$conf = Config::Manager::Conf->new();
defined $conf->set('ENV', 'DINGS', 'tralala') ? nok() : ok();
$conf->error() eq 'Configuration constant $[ENV]{DINGS} is read-only' ? ok() : nok();

# Versuch, eine SPECIAL-Variable aus einer Datei einzulesen
$conf = Config::Manager::Conf->new();
defined $conf->add('t/conf_err_wp02.ini') ? nok() : ok();
$conf->error() eq 'Configuration constant $[SPECIAL]{DINGS} is read-only' ? ok() : nok();
# SPECIAL-Variable mit set() setzen (das ist erlaubt!)
$conf = Config::Manager::Conf->new();
defined $conf->set('SPECIAL', 'DAY', '32') ? ok() : nok();
$conf->get('SPECIAL', 'DAY') eq '32' ? ok() : nok();
# SPECIAL::OS mit set() setzen (das ist wiederum nicht erlaubt)
$conf = Config::Manager::Conf->new();
defined $conf->set('SPECIAL', 'OS', 'CP/M') ? nok() : ok();
$conf->error() eq 'Configuration constant $[SPECIAL]{OS} is read-only' ? ok() : nok();
# SPECIAL::SCOPE mit set() setzen (das ist wiederum nicht erlaubt)
$conf = Config::Manager::Conf->new();
defined $conf->set('SPECIAL', 'SCOPE', 'UNIVERSE') ? nok() : ok();
$conf->error() eq 'Configuration constant $[SPECIAL]{SCOPE} is read-only' ? ok() : nok();

################################################################################
# Werte setzen und auswerten                                                   #
################################################################################

$conf = Config::Manager::Conf->new();
# Wert setzen und wieder auslesen
$conf->set('SPU', 'TMP1', 'C:\tmp') ? ok(): nok();
$conf->get('SPU', 'TMP1') eq 'C:\tmp' ? ok(): nok();
$conf->set('SPU', 'TMP2', 'D:\tmp') ? ok() : nok();
$conf->get('SPU', 'TMP2') eq 'D:\tmp' ? ok() : nok();
# Wert in anderen Abschnitt setzen und wieder auslesen
$conf->set('KM', 'TMP1', 'C:\temp') ? ok() : nok();
$conf->get('KM', 'TMP1') eq 'C:\temp' ? ok() : nok();
$conf->set('KM', 'TMP2', 'D:\temp') ? ok() : nok();
$conf->get('KM', 'TMP2') eq 'D:\temp' ? ok() : nok();
$conf->set('KM', 'TMP3', 'X:\temp') ? ok() : nok();
$conf->get('KM', 'TMP3') eq 'X:\temp' ? ok() : nok();
# Die Werte in SPU muessen nach wie vor stimmen
$conf->get('SPU', 'TMP1') eq 'C:\tmp' ? ok() : nok();
$conf->get('SPU', 'TMP2') eq 'D:\tmp' ? ok() : nok();
$conf->get('SPU', 'TMP1') eq 'C:\tmp' ? ok() : nok();
$conf->get('SPU', 'TMP2') eq 'D:\tmp' ? ok() : nok();
$conf->get('KM', 'TMP1') eq 'C:\temp' ? ok() : nok();
$conf->get('KM', 'TMP2') eq 'D:\temp' ? ok() : nok();
# Zugriff auf undefinierten Wert
$conf->get('SPU', 'TRALALA') ? nok() : ok();
$conf->error() eq "Configuration constant \$[SPU]{TRALALA} not found" ? ok() : nok();
$conf->get('SPX', 'TMP1') ? nok() : ok();
$conf->error() eq "Configuration constant \$[SPX]{TMP1} not found" ? ok() : nok();
$conf->get('SPX', 'TRALALA') ? nok() : ok();
$conf->error() eq "Configuration constant \$[SPX]{TRALALA} not found" ? ok() : nok();
$conf->get('TRALALA') ? nok() : ok();
$conf->error() eq "Configuration constant \$[DEFAULT]{TRALALA} not found" ? ok() : nok();

################################################################################
# Konstruktor auf Instanz anwenden statt auf Klasse                            #
################################################################################

$conf = $conf->new();
$conf->get('SPU', 'TMP1') ? nok() : ok();
$conf->error() eq "Configuration constant \$[SPU]{TMP1} not found" ? ok() : nok();

################################################################################
# Einlesen und Auswerten einer korrekten Datei sowie Kommandozeilenoptionen    #
################################################################################

# Ich mache alle Tests sowohl auf einem frischen Objekt ($conf) als auch auf
# der Klasse, d.h. auf der Default-Instanz.

############################################################
# Daten einlesen, Kommandozeilenoptionen setzen
############################################################

# Fuer die Default-Instanz dasselbe wie in conf(), aber mit Pruefungen.
# Dateien einlesen
Config::Manager::Conf->add('t/conf_private.ini', 't/conf_public.ini') ? ok() : nok();
# Kommandozeilenargumente setzen
Config::Manager::Conf->set('INSTDIR', 'inst') ? ok() : nok();

############################################################
# Einfache Werte in Default-Section abfragen
############################################################

# Unbekannter Wert
defined conf()->get('TRALALA') ? nok() : ok();
defined Config::Manager::Conf->get('TRALALA') ? nok() : ok();

# Einfacher Wert
conf()->get('SYSDIR') eq 'sys' ? ok() : nok();
Config::Manager::Conf->get('SYSDIR') eq 'sys' ? ok() : nok();
# Einfacher Wert aus conf_private.ini
conf()->get('DRIVE') eq 'C:' ? ok() : nok();
Config::Manager::Conf->get('DRIVE') eq 'C:' ? ok() : nok();
# Einfacher Wert aus Kommandozeile
conf()->get('INSTDIR') eq 'inst' ? ok() : nok();
Config::Manager::Conf->get('INSTDIR') eq 'inst' ? ok() : nok();

# Einfacher Wert, Leerzeichen am Zeilenende ignoriert
conf()->get('WRKDIR') eq 'wrk' ? ok() : nok();
Config::Manager::Conf->get('WRKDIR') eq 'wrk' ? ok() : nok();
# Einfacher Wert, Leerzeichen am Zeilenanfang ignoriert
conf()->get('TMPDIR') eq 'tmp' ? ok() : nok();
Config::Manager::Conf->get('TMPDIR') eq 'tmp' ? ok() : nok();

# Leerer Wert
conf()->get('EMPTY') eq '' ? ok() : nok();
Config::Manager::Conf->get('EMPTY') eq '' ? ok() : nok();

# Leerzeichen
conf()->get('SPACES1') eq '   ' ? ok() : nok();
Config::Manager::Conf->get('SPACES1') eq '   ' ? ok() : nok();
conf()->get('SPACES2') eq '   ' ? ok() : nok();
Config::Manager::Conf->get('SPACES2') eq '   ' ? ok() : nok();

# Wert mit Gleichheitszeichen
conf()->get('ORWELL') eq '2+2=5' ? ok() : nok();
Config::Manager::Conf->get('ORWELL') eq '2+2=5' ? ok() : nok();

# Einfache Anfuehrungszeichen: Keine Sonderbedeutung
conf()->get('SINGLE_QUOTES') eq "'tralala'" ? ok() : nok();
Config::Manager::Conf->get('SINGLE_QUOTES') eq "'tralala'" ? ok() : nok();
# Doppelte Anfuehrungszeichen sind Begrenzer
conf()->get('QUOTES') eq 'tralala' ? ok() : nok();
Config::Manager::Conf->get('QUOTES') eq 'tralala' ? ok() : nok();
# Anfuehrungszeichen am Anfang: Keine Sonderbedeutung
conf()->get('FIRST_QUOTE') eq '"tralala' ? ok() : nok();
Config::Manager::Conf->get('FIRST_QUOTE') eq '"tralala' ? ok() : nok();
# Anfuehrungszeichen am Ende: Keine Sonderbedeutung
conf()->get('LAST_QUOTE') eq 'tralala"' ? ok() : nok();
Config::Manager::Conf->get('LAST_QUOTE') eq 'tralala"' ? ok() : nok();
# Anfuehrungszeichen in der Mitte: Keine Sonderbedeutung
conf()->get('MID_QUOTE1') eq 'tra"lala' ? ok() : nok();
Config::Manager::Conf->get('MID_QUOTE1') eq 'tra"lala' ? ok() : nok();
conf()->get('MID_QUOTE2') eq 'tra"lala' ? ok() : nok();
Config::Manager::Conf->get('MID_QUOTE2') eq 'tra"lala' ? ok() : nok();
conf()->get('MID_QUOTE3') eq ' " ' ? ok() : nok();
Config::Manager::Conf->get('MID_QUOTE3') eq ' " ' ? ok() : nok();

# Escape-Sequenzen: Dollar
conf()->get('ESC_D') eq '$SYS' ? ok() : nok();
Config::Manager::Conf->get('ESC_D') eq '$SYS' ? ok() : nok();
# Escape-Sequenzen: Backslash und Substitution
conf()->get('ESC_BS') eq '\C:/sys' ? ok() : nok();
Config::Manager::Conf->get('ESC_BS') eq '\C:/sys' ? ok() : nok();
# Escape-Sequenzen: Backslash und Dollar
conf()->get('ESC_BD') eq '\$SYS' ? ok() : nok();
Config::Manager::Conf->get('ESC_BD') eq '\$SYS' ? ok() : nok();
# Escape-Sequenzen: Backslash, Backslash, Substitution
conf()->get('ESC_BBS') eq '\\\\C:/sys' ? ok() : nok();
Config::Manager::Conf->get('ESC_BBS') eq '\\\\C:/sys' ? ok() : nok();
# Escape-Sequenzen: Backslash, Backslash, Dollar
conf()->get('ESC_BBD') eq '\\\\$SYS' ? ok() : nok();
Config::Manager::Conf->get('ESC_BBD') eq '\\\\$SYS' ? ok() : nok();

# Substitution: Nur schliessende Klammer
conf()->get('S_C') eq 'C:/sys}' ? ok() : nok();
Config::Manager::Conf->get('S_C') eq 'C:/sys}' ? ok() : nok();
# Qualifizierte Substitution: Nur schliessende Klammer
conf()->get('SQ_C') eq 'a_hello}' ? ok() : nok();
Config::Manager::Conf->get('SQ_C') eq 'a_hello}' ? ok() : nok();

# Gross- und Kleinschreibung fuer Schluessel
conf()->get('A') eq 'a' ? ok() : nok();
Config::Manager::Conf->get('A') eq 'a' ? ok() : nok();
conf()->get('a') eq 'ach ja' ? ok() : nok();
Config::Manager::Conf->get('a') eq 'ach ja' ? ok() : nok();

# Schluessel darf auch mit $ beginnen
conf()->get('SONDERLOCKE') eq 'Key faengt mit $ an' ? ok() : nok();
Config::Manager::Conf->get('SONDERLOCKE') eq 'Key faengt mit $ an' ? ok() : nok();

############################################################
# Substitutionen in Default-Section abfragen
############################################################

# Einfache Substitution von zwei Werten
conf()->get('SYS') eq 'C:/sys' ? ok() : nok();
Config::Manager::Conf->get('SYS') eq 'C:/sys' ? ok() : nok();
conf()->get('TMP') eq 'C:/tmp' ? ok() : nok();
Config::Manager::Conf->get('TMP') eq 'C:/tmp' ? ok() : nok();

# Rekursive Substitution
conf()->get('WRK') eq 'C:/sys/wrk' ? ok() : nok();
Config::Manager::Conf->get('WRK') eq 'C:/sys/wrk' ? ok() : nok();
conf()->get('INST') eq 'C:/sys/inst' ? ok() : nok();
Config::Manager::Conf->get('INST') eq 'C:/sys/inst' ? ok() : nok();
conf()->get('PATH') eq 'C:/sys/wrk;C:/sys/inst' ? ok() : nok();
Config::Manager::Conf->get('PATH') eq 'C:/sys/wrk;C:/sys/inst' ? ok() : nok();

############################################################
# Zyklen erkennen und abbrechen
############################################################

# Die duemmste Art, einen Zyklus zu produzieren
$conf = conf();
defined $conf->get('SIMPLE_LOOP') ? nok() : ok();
$conf->error() eq "Infinite recursion in file 't/conf_public.ini' line #84 [DEFAULT]: \$[DEFAULT]{SIMPLE_LOOP} = \"This is a \$SIMPLE_LOOP\"" ? ok() : nok();
defined Config::Manager::Conf->get('SIMPLE_LOOP') ? nok() : ok();
Config::Manager::Conf->error() eq "Infinite recursion in file 't/conf_public.ini' line #84 [DEFAULT]: \$[DEFAULT]{SIMPLE_LOOP} = \"This is a \$SIMPLE_LOOP\"" ? ok() : nok();

# Etwas weniger auffaellig
$conf = conf();
defined $conf->get('LOOP') ? nok() : ok();
$conf->error() eq "Infinite recursion in file 't/conf_public.ini' line #87 [DEFAULT]: \$[DEFAULT]{LOOP} = \"\$THIS will loop\"" ? ok() : nok();
defined Config::Manager::Conf->get('LOOP') ? nok() : ok();
Config::Manager::Conf->error() eq "Infinite recursion in file 't/conf_public.ini' line #87 [DEFAULT]: \$[DEFAULT]{LOOP} = \"\$THIS will loop\"" ? ok() : nok();

# Unauffaellig
$conf = conf();
defined $conf->get('THAT') ? nok() : ok();
$conf->error() eq "Infinite recursion in file 't/conf_public.ini' line #85 [DEFAULT]: \$[DEFAULT]{THIS} = \"This \$WILL loop\"" ? ok() : nok();
defined Config::Manager::Conf->get('THAT') ? nok() : ok();
Config::Manager::Conf->error() eq "Infinite recursion in file 't/conf_public.ini' line #85 [DEFAULT]: \$[DEFAULT]{THIS} = \"This \$WILL loop\"" ? ok() : nok();

############################################################
# Qualifizierter Zugriff
############################################################

# Wert ist in der Default-Section und zwei weiteren Sections definiert
conf()->get('EVERYWHERE') eq 'default' ? ok() : nok();
Config::Manager::Conf->get('EVERYWHERE') eq 'default' ? ok() : nok();
conf()->get('A', 'EVERYWHERE') eq 'at a' ? ok() : nok();
Config::Manager::Conf->get('A', 'EVERYWHERE') eq 'at a' ? ok() : nok();
conf()->get('B', 'EVERYWHERE') eq 'at b' ? ok() : nok();
Config::Manager::Conf->get('B', 'EVERYWHERE') eq 'at b' ? ok() : nok();

# Wert ist in zwei Sections, aber nicht in der Default-Section definiert
$conf = conf();
defined $conf->get('HELLO') ? nok() : ok();
$conf->error() eq "Configuration constant \$[DEFAULT]{HELLO} not found" ? ok() : nok();
defined Config::Manager::Conf->get('HELLO') ? nok() : ok();
Config::Manager::Conf->error() eq "Configuration constant \$[DEFAULT]{HELLO} not found" ? ok() : nok();
conf()->get('A', 'HELLO') eq 'a_hello' ? ok() : nok();
Config::Manager::Conf->get('A', 'HELLO') eq 'a_hello' ? ok() : nok();
conf()->get('B', 'HELLO') eq 'b_hello' ? ok() : nok();
Config::Manager::Conf->get('B', 'HELLO') eq 'b_hello' ? ok() : nok();

# Wert ist in der Default-Section und einer weiteren Section definiert
conf()->get('A') eq 'a' ? ok() : nok();
Config::Manager::Conf->get('A') eq 'a' ? ok() : nok();
conf()->get('A', 'A') eq 'a, too' ? ok() : nok();
Config::Manager::Conf->get('A', 'A') eq 'a, too' ? ok() : nok();
$conf = conf();
defined $conf->get('B', 'A') ? nok() : ok();
$conf->error() eq "Configuration constant \$[B]{A} not found" ? ok() : nok();
defined Config::Manager::Conf->get('B', 'A') ? nok() : ok();
Config::Manager::Conf->error() eq "Configuration constant \$[B]{A} not found" ? ok() : nok();

# Wert ist nicht in der Default-Section, aber in einer weiteren Section definiert
defined conf()->get('EXCLUSIVE') ? nok() : ok();
defined Config::Manager::Conf->get('EXCLUSIVE') ? nok() : ok();
conf()->get('A', 'EXCLUSIVE') eq 'XA' ? ok() : nok();
Config::Manager::Conf->get('A', 'EXCLUSIVE') eq 'XA' ? ok() : nok();
$conf = conf();
defined $conf->get('B', 'EXCLUSIVE') ? nok() : ok();
$conf->error() eq "Configuration constant \$[B]{EXCLUSIVE} not found" ? ok() : nok();
defined Config::Manager::Conf->get('B', 'EXCLUSIVE') ? nok() : ok();
Config::Manager::Conf->error() eq "Configuration constant \$[B]{EXCLUSIVE} not found" ? ok() : nok();

# Wert ist nirgendwo definiert
$conf = conf();
defined $conf->get('HURZ') ? nok() : ok();
$conf->error() eq "Configuration constant \$[DEFAULT]{HURZ} not found" ? ok() : nok();
defined Config::Manager::Conf->get('HURZ') ? nok() : ok();
Config::Manager::Conf->error() eq "Configuration constant \$[DEFAULT]{HURZ} not found" ? ok() : nok();
$conf = conf();
defined $conf->get('A', 'HURZ') ? nok() : ok();
$conf->error() eq "Configuration constant \$[A]{HURZ} not found" ? ok() : nok();
defined Config::Manager::Conf->get('A', 'HURZ') ? nok() : ok();
Config::Manager::Conf->error() eq "Configuration constant \$[A]{HURZ} not found" ? ok() : nok();

############################################################
# Qualifizierte Substitutionen
############################################################

# Wert ist in der Default-Section und zwei weiteren Sections definiert
conf()->get('ANYTHING', 'EVERYWHERE1') eq '%default%' ? ok() : nok();
Config::Manager::Conf->get('ANYTHING', 'EVERYWHERE1') eq '%default%' ? ok() : nok();
conf()->get('ANYTHING', 'EVERYWHERE2') eq '%default%' ? ok() : nok();
Config::Manager::Conf->get('ANYTHING', 'EVERYWHERE2') eq '%default%' ? ok() : nok();
conf()->get('ANYTHING', 'EVERYWHERE3') eq '%at a%' ? ok() : nok();
Config::Manager::Conf->get('ANYTHING', 'EVERYWHERE3') eq '%at a%' ? ok() : nok();
conf()->get('ANYTHING', 'EVERYWHERE4') eq '%at a%' ? ok() : nok();
Config::Manager::Conf->get('ANYTHING', 'EVERYWHERE4') eq '%at a%' ? ok() : nok();
conf()->get('ANYTHING', 'EVERYWHERE5') eq '%at b%' ? ok() : nok();
Config::Manager::Conf->get('ANYTHING', 'EVERYWHERE5') eq '%at b%' ? ok() : nok();
conf()->get('ANYTHING', 'EVERYWHERE6') eq '%at b%' ? ok() : nok();
Config::Manager::Conf->get('ANYTHING', 'EVERYWHERE6') eq '%at b%' ? ok() : nok();

# Wert ist in zwei Sections, aber nicht in der Default-Section definiert
$conf = conf();
defined $conf->get('ANYTHING', 'HELLO1') ? nok() : ok();
$conf->error() eq "Configuration constant \$[DEFAULT]{HELLO} not found" ? ok() : nok();
defined Config::Manager::Conf->get('ANYTHING', 'HELLO1') ? nok() : ok();
Config::Manager::Conf->error() eq "Configuration constant \$[DEFAULT]{HELLO} not found" ? ok() : nok();
$conf = conf();
defined $conf->get('ANYTHING', 'HELLO2') ? nok() : ok();
$conf->error() eq "Configuration constant \$[DEFAULT]{HELLO} not found" ? ok() : nok();
defined Config::Manager::Conf->get('ANYTHING', 'HELLO2') ? nok() : ok();
Config::Manager::Conf->error() eq "Configuration constant \$[DEFAULT]{HELLO} not found" ? ok() : nok();
conf()->get('ANYTHING', 'HELLO3') eq '%a_hello%' ? ok() : nok();
Config::Manager::Conf->get('ANYTHING', 'HELLO3') eq '%a_hello%' ? ok() : nok();
conf()->get('ANYTHING', 'HELLO4') eq '%a_hello%' ? ok() : nok();
Config::Manager::Conf->get('ANYTHING', 'HELLO4') eq '%a_hello%' ? ok() : nok();
conf()->get('ANYTHING', 'HELLO5') eq '%b_hello%' ? ok() : nok();
Config::Manager::Conf->get('ANYTHING', 'HELLO5') eq '%b_hello%' ? ok() : nok();
conf()->get('ANYTHING', 'HELLO6') eq '%b_hello%' ? ok() : nok();
Config::Manager::Conf->get('ANYTHING', 'HELLO6') eq '%b_hello%' ? ok() : nok();

# Wert ist in der Default-Section und einer weiteren Section definiert
conf()->get('ANYTHING', 'A1') eq '%a%' ? ok() : nok();
Config::Manager::Conf->get('ANYTHING', 'A1') eq '%a%' ? ok() : nok();
conf()->get('ANYTHING', 'A2') eq '%a%' ? ok() : nok();
Config::Manager::Conf->get('ANYTHING', 'A2') eq '%a%' ? ok() : nok();
conf()->get('ANYTHING', 'A3') eq '%a, too%' ? ok() : nok();
Config::Manager::Conf->get('ANYTHING', 'A3') eq '%a, too%' ? ok() : nok();
conf()->get('ANYTHING', 'A4') eq '%a, too%' ? ok() : nok();
Config::Manager::Conf->get('ANYTHING', 'A4') eq '%a, too%' ? ok() : nok();
$conf = conf();
defined $conf->get('ANYTHING', 'A5') ? nok() : ok();
$conf->error() eq "Configuration constant \$[B]{A} not found" ? ok() : nok();
defined Config::Manager::Conf->get('ANYTHING', 'A5') ? nok() : ok();
Config::Manager::Conf->error() eq "Configuration constant \$[B]{A} not found" ? ok() : nok();
$conf = conf();
defined $conf->get('ANYTHING', 'A6') ? nok() : ok();
$conf->error() eq "Configuration constant \$[B]{A} not found" ? ok() : nok();
defined Config::Manager::Conf->get('ANYTHING', 'A6') ? nok() : ok();
Config::Manager::Conf->error() eq "Configuration constant \$[B]{A} not found" ? ok() : nok();

# Wert ist nicht in der Default-Section, aber in einer weiteren Section definiert
$conf = conf();
defined $conf->get('ANYTHING', 'EXCLUSIVE1') ? nok() : ok();
$conf->error() eq "Configuration constant \$[DEFAULT]{EXCLUSIVE} not found" ? ok() : nok();
defined Config::Manager::Conf->get('ANYTHING', 'EXCLUSIVE1') ? nok() : ok();
Config::Manager::Conf->error() eq "Configuration constant \$[DEFAULT]{EXCLUSIVE} not found" ? ok() : nok();
$conf = conf();
defined $conf->get('ANYTHING', 'EXCLUSIVE2') ? nok() : ok();
$conf->error() eq "Configuration constant \$[DEFAULT]{EXCLUSIVE} not found" ? ok() : nok();
defined Config::Manager::Conf->get('ANYTHING', 'EXCLUSIVE2') ? nok() : ok();
Config::Manager::Conf->error() eq "Configuration constant \$[DEFAULT]{EXCLUSIVE} not found" ? ok() : nok();
conf()->get('ANYTHING', 'EXCLUSIVE3') eq '%XA%' ? ok() : nok();
Config::Manager::Conf->get('ANYTHING', 'EXCLUSIVE3') eq '%XA%' ? ok() : nok();
conf()->get('ANYTHING', 'EXCLUSIVE4') eq '%XA%' ? ok() : nok();
Config::Manager::Conf->get('ANYTHING', 'EXCLUSIVE4') eq '%XA%' ? ok() : nok();
$conf = conf();
defined $conf->get('ANYTHING', 'EXCLUSIVE5') ? nok() : ok();
$conf->error() eq "Configuration constant \$[B]{EXCLUSIVE} not found" ? ok() : nok();
defined Config::Manager::Conf->get('ANYTHING', 'EXCLUSIVE5') ? nok() : ok();
Config::Manager::Conf->error() eq "Configuration constant \$[B]{EXCLUSIVE} not found" ? ok() : nok();
$conf = conf();
defined $conf->get('ANYTHING', 'EXCLUSIVE6') ? nok() : ok();
$conf->error() eq "Configuration constant \$[B]{EXCLUSIVE} not found" ? ok() : nok();
defined Config::Manager::Conf->get('ANYTHING', 'EXCLUSIVE6') ? nok() : ok();
Config::Manager::Conf->error() eq "Configuration constant \$[B]{EXCLUSIVE} not found" ? ok() : nok();

# Wert ist nirgendwo definiert
$conf = conf();
defined $conf->get('ANYTHING', 'HURZ1') ? nok() : ok();
$conf->error() eq "Configuration constant \$[DEFAULT]{HURZ} not found" ? ok() : nok();
defined Config::Manager::Conf->get('ANYTHING', 'HURZ1') ? nok() : ok();
Config::Manager::Conf->error() eq "Configuration constant \$[DEFAULT]{HURZ} not found" ? ok() : nok();
$conf = conf();
defined $conf->get('ANYTHING', 'HURZ2') ? nok() : ok();
$conf->error() eq "Configuration constant \$[DEFAULT]{HURZ} not found" ? ok() : nok();
defined Config::Manager::Conf->get('ANYTHING', 'HURZ2') ? nok() : ok();
Config::Manager::Conf->error() eq "Configuration constant \$[DEFAULT]{HURZ} not found" ? ok() : nok();
$conf = conf();
defined $conf->get('ANYTHING', 'HURZ3') ? nok() : ok();
$conf->error() eq "Configuration constant \$[A]{HURZ} not found" ? ok() : nok();
defined Config::Manager::Conf->get('ANYTHING', 'HURZ3') ? nok() : ok();
Config::Manager::Conf->error() eq "Configuration constant \$[A]{HURZ} not found" ? ok() : nok();
$conf = conf();
defined $conf->get('ANYTHING', 'HURZ4') ? nok() : ok();
$conf->error() eq "Configuration constant \$[A]{HURZ} not found" ? ok() : nok();
defined Config::Manager::Conf->get('ANYTHING', 'HURZ4') ? nok() : ok();
Config::Manager::Conf->error() eq "Configuration constant \$[A]{HURZ} not found" ? ok() : nok();

############################################################
# Funktioniert der Zugriff ueber die Default-Instanz?
############################################################

# default() als Klassenmethode aufgefasst
Config::Manager::Conf->default()->get('SYSDIR') eq 'sys' ? ok() : nok();
# default() als Funktion aufgefasst
Config::Manager::Conf::default()->get('SYSDIR') eq 'sys' ? ok() : nok();
# default() als Instanzmethode aufgefasst
conf()->default()->get('SYSDIR') eq 'sys' ? ok() : nok();

############################################################
# Namen, die Bindestriche enthalten
############################################################

conf()->get('WITH-SLASH', 'FOR-EXAMPLE') eq '-' ? ok() : nok();
conf()->get('WITH-SLASH', 'T-1') eq 'A-Z' ? ok() : nok();
conf()->get('WITH-SLASH', 'T-2') eq 'A-O' ? ok() : nok();
conf()->get('WITH-SLASH', 'T-3') eq '+-' ? ok() : nok();
conf()->get('WITH-SLASH', 'T-4') eq '4-' ? ok() : nok();
conf()->get('WITH-SLASH', 'T-5') eq '5-;' ? ok() : nok();
conf()->get('WITH-SLASH', 'T-6') eq '6-;' ? ok() : nok();
Config::Manager::Conf->get('WITH-SLASH', 'FOR-EXAMPLE') eq '-' ? ok() : nok();
Config::Manager::Conf->get('WITH-SLASH', 'T-1') eq 'A-Z' ? ok() : nok();
Config::Manager::Conf->get('WITH-SLASH', 'T-2') eq 'A-O' ? ok() : nok();
Config::Manager::Conf->get('WITH-SLASH', 'T-3') eq '+-' ? ok() : nok();
Config::Manager::Conf->get('WITH-SLASH', 'T-4') eq '4-' ? ok() : nok();
Config::Manager::Conf->get('WITH-SLASH', 'T-5') eq '5-;' ? ok() : nok();
Config::Manager::Conf->get('WITH-SLASH', 'T-6') eq '6-;' ? ok() : nok();

############################################################
# Zugriff auf die eigene Section
############################################################

conf()->get('A3', 'D') eq 'd3>a3' ? ok() : nok();
conf()->get('A2', 'C') eq 'c2>d3>a3' ? ok() : nok();
conf()->get('A2', 'B') eq 'b2>c2>d3>a3' ? ok() : nok();
conf()->get('A1', 'A') eq 'a1>b2>c2>d3>a3' ? ok() : nok();
Config::Manager::Conf->get('A3', 'D') eq 'd3>a3' ? ok() : nok();
Config::Manager::Conf->get('A2', 'C') eq 'c2>d3>a3' ? ok() : nok();
Config::Manager::Conf->get('A2', 'B') eq 'b2>c2>d3>a3' ? ok() : nok();
Config::Manager::Conf->get('A1', 'A') eq 'a1>b2>c2>d3>a3' ? ok() : nok();

############################################################
# Indirekte Substitution
############################################################

conf()->get('WHO', 'NAME') eq 'Fritz Fischer' ? ok() : nok();
conf()->get('WHO', 'name') eq 'Fritz Fischer' ? ok() : nok();
conf()->get('WHO', 'IQ') eq '0' ? ok() : nok();
conf()->get('WHO', 'XYZ') eq 'fritz' ? ok() : nok();
conf()->get('WHO', 'xyz') eq 'fritz' ? ok() : nok();
conf()->get('WHO', 'XXX') eq 'fritz' ? ok() : nok();
conf()->get('WHO', 'xxx') eq 'fritz' ? ok() : nok();
conf()->get('WHO', 'UVW') eq 'fritzfritz' ? ok() : nok();
conf()->get('WHO', 'uvw') eq 'fritzfritz' ? ok() : nok();
Config::Manager::Conf->get('WHO', 'NAME') eq 'Fritz Fischer' ? ok() : nok();
Config::Manager::Conf->get('WHO', 'name') eq 'Fritz Fischer' ? ok() : nok();
Config::Manager::Conf->get('WHO', 'IQ') eq '0' ? ok() : nok();
Config::Manager::Conf->get('WHO', 'XYZ') eq 'fritz' ? ok() : nok();
Config::Manager::Conf->get('WHO', 'xyz') eq 'fritz' ? ok() : nok();
Config::Manager::Conf->get('WHO', 'XXX') eq 'fritz' ? ok() : nok();
Config::Manager::Conf->get('WHO', 'xxx') eq 'fritz' ? ok() : nok();
Config::Manager::Conf->get('WHO', 'UVW') eq 'fritzfritz' ? ok() : nok();
Config::Manager::Conf->get('WHO', 'uvw') eq 'fritzfritz' ? ok() : nok();

################################################################################
# Zugriff auf Umgebungsvariablen                                               #
################################################################################

$ENV{DONALD} = 'Duck';
# Zugriff auf Umgebungsvariable
conf()->get('ENV', 'DONALD') eq 'Duck' ? ok() : nok();
Config::Manager::Conf->get('ENV', 'DONALD') eq 'Duck' ? ok() : nok();
# Qualifizierter Name erforderlich
$conf = conf();
defined $conf->get('DONALD') ? nok() : ok();
$conf->error() eq "Configuration constant \$[DEFAULT]{DONALD} not found" ? ok() : nok();
defined Config::Manager::Conf->get('DONALD') ? nok() : ok();
Config::Manager::Conf->error() eq "Configuration constant \$[DEFAULT]{DONALD} not found" ? ok() : nok();
# Umgebungsvariable nicht gefunden
$conf = conf();
defined $conf->get('ENV', 'DAGOBERT') ? nok() : ok();
$conf->error() eq "Configuration constant \$[ENV]{DAGOBERT} not found" ? ok() : nok();
defined Config::Manager::Conf->get('ENV', 'DAGOBERT') ? nok() : ok();
Config::Manager::Conf->error() eq "Configuration constant \$[ENV]{DAGOBERT} not found" ? ok() : nok();
# Substitution unter Verwendung einer Umgebungsvariablen
$conf = conf();
$conf->set('SUBST_ENV1', 'Dagobert $[ENV]DONALD') ? ok() : nok();
$conf->get('SUBST_ENV1') eq 'Dagobert Duck' ? ok() : nok();
Config::Manager::Conf->set('SUBST_ENV1', 'Dagobert $[ENV]DONALD') ? ok() : nok();
Config::Manager::Conf->get('SUBST_ENV1') eq 'Dagobert Duck' ? ok() : nok();
# Nochmal Substitution, aber {}-Syntax verwenden
$conf = conf();
$conf->set('SUBST_ENV2', 'Dagobert $[ENV]{DONALD}') ? ok() : nok();
$conf->get('SUBST_ENV2') eq 'Dagobert Duck' ? ok() : nok();
Config::Manager::Conf->set('SUBST_ENV2', 'Dagobert $[ENV]{DONALD}') ? ok() : nok();
Config::Manager::Conf->get('SUBST_ENV2') eq 'Dagobert Duck' ? ok() : nok();
# Substitution unter Verwendung einer fehlenden Umgebungsvariablen
$conf = conf();
$conf->set('SUBST_NOENV', 'Donald $[ENV]DAGOBERT') ? ok() : nok();
defined $conf->get('SUBST_NOENV') ? nok() : ok();
$conf->error() eq "Configuration constant \$[ENV]{DAGOBERT} not found" ? ok() : nok();
Config::Manager::Conf->set('SUBST_NOENV', 'Donald $[ENV]DAGOBERT') ? ok() : nok();
defined Config::Manager::Conf->get('SUBST_NOENV') ? nok() : ok();
Config::Manager::Conf->error() eq "Configuration constant \$[ENV]{DAGOBERT} not found" ? ok() : nok();

################################################################################
# Zugriff auf SPECIAL-Werte                                                    #
################################################################################

############################################################
# Jahr, Monat, Tag
############################################################

# Ich kann hier aus naheliegenden Gruenden nicht auf konkrete Werte abfragen,
# daher pruefe ich nur, ob die Werte ueberhaupt vorhanden sind und ob ihr Format
# dem entspricht, was ich erwarte.

# Zugriff auf YEAR
$result = conf()->get('SPECIAL', 'YEAR');
length($result) == 4 ? ok() : nok();
$result >= 2000 ? ok() : nok();
$result = Config::Manager::Conf->get('SPECIAL', 'YEAR');
length($result) == 4 ? ok() : nok();
$result >= 2000 ? ok() : nok();
# Zugriff auf YY
$result = conf()->get('SPECIAL', 'YY');
length($result) == 2 ? ok() : nok();
$result = Config::Manager::Conf->get('SPECIAL', 'YY');
length($result) == 2 ? ok() : nok();
# Zugriff auf CC (sollte noch einige Zeit das 20. Jahrhundert liefern :-)
conf()->get('SPECIAL', 'CC') == 20 ? ok() : nok();
Config::Manager::Conf->get('SPECIAL', 'CC') == 20 ? ok() : nok();

# Zugriff auf MONTH
$result = conf()->get('SPECIAL', 'MONTH');
length($result) == 2 ? ok() : nok();
$result >= 1 ? ok() : nok();
$result <= 12 ? ok() : nok();
$result = Config::Manager::Conf->get('SPECIAL', 'MONTH');
length($result) == 2 ? ok() : nok();
$result >= 1 ? ok() : nok();
$result <= 12 ? ok() : nok();
# Zugriff auf DAY
$result = conf()->get('SPECIAL', 'DAY');
length($result) == 2 ? ok() : nok();
$result >= 1 ? ok() : nok();
$result <= 31 ? ok() : nok();
$result = Config::Manager::Conf->get('SPECIAL', 'DAY');
length($result) == 2 ? ok() : nok();
$result >= 1 ? ok() : nok();
$result <= 31 ? ok() : nok();
# Zugriff auf YDAY
$result = conf()->get('SPECIAL', 'YDAY');
length($result) == 3 ? ok() : nok();
$result >= 1 ? ok() : nok();
$result <= 366 ? ok() : nok();
$result = Config::Manager::Conf->get('SPECIAL', 'YDAY');
length($result) == 3 ? ok() : nok();
$result >= 1 ? ok() : nok();
$result <= 366 ? ok() : nok();

############################################################
# Name des Betriebssystems
############################################################

conf()->get('SPECIAL', 'OS') eq $^O ? ok() : nok();
Config::Manager::Conf->get('SPECIAL', 'OS') eq $^O ? ok() : nok();

############################################################
# Scope
############################################################

conf()->get('SPECIAL', 'SCOPE') eq 'NONE' ? ok() : nok();
conf()->scope() eq 'NONE' ? ok() : nok();
Config::Manager::Conf->get('SPECIAL', 'SCOPE') eq 'NONE' ? ok() : nok();
Config::Manager::Conf->scope() eq 'NONE' ? ok() : nok();

################################################################################
# Auswerten der globalen Conf.ini                                              #
################################################################################

# Eine frische Instanz
$conf = Config::Manager::Conf->new();
defined $conf->init('TEST') ? ok() : nok();
$conf->scope() eq 'TEST' ? ok() : nok();
$conf->get('SPECIAL', 'SCOPE') eq 'TEST' ? ok() : nok();
$conf->get('NEFFEN', 'KWIK') eq 'kwik' ? ok() : nok();
$conf->get('DRIVE') eq 'X:' ? ok() : nok();

# Die Default-Instanz ; init() sollte den alten Schrott weggeraeumt haben
defined Config::Manager::Conf->init('TEST') ? ok() : nok();
Config::Manager::Conf->scope() eq 'TEST' ? ok() : nok();
Config::Manager::Conf->get('SPECIAL', 'SCOPE') eq 'TEST' ? ok() : nok();
Config::Manager::Conf->get('NEFFEN', 'KWIK') eq 'kwik' ? ok() : nok();
Config::Manager::Conf->get('DRIVE') eq 'X:' ? ok() : nok();

__END__

