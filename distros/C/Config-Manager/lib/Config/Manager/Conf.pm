
###############################################################################
##                                                                           ##
##    Copyright (c) 2003 by Steffen Beyer & Gerhard Albers.                  ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

package Config::Manager::Conf;

################################################################################
# Im- und Exporte
################################################################################

use strict;
use vars qw( @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION %INC %SIG );

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw();

@EXPORT_OK = qw( whoami );

%EXPORT_TAGS = (all => [@EXPORT_OK]);

$VERSION = '1.7';

################################################################################
# Datenstrukturen
################################################################################

# Programminterne Konstanten

# Pattern zur Beschreibung von "privaten" Dateien (Sonderbehandlung)
my $PRIVATE  = "\\bPRIVATE?\\.ini\$";

# Besondere Datenquellen
my @WHOAMI   = qw( USERNAME LOGNAME USER LOGIN );
my $USR      = '<USR>';
my $SYS      = '<SYS>';
my $EXT      = '<ENV>';
# Sections
my $ENV      = 'ENV';
my $SPECIAL  = 'SPECIAL';
my $DEFAULT  = 'DEFAULT';
# Keys
my $SCOPE    = 'SCOPE';
my $NEXTCONF = 'NEXTCONF';
my $YEAR     = 'YEAR';
my $MONTH    = 'MONTH';
my $DAY      = 'DAY';
my $HOUR     = 'HOUR';
my $MIN      = 'MIN';
my $SEC      = 'SEC';
my $YDAY     = 'YDAY';
my $WDAY     = 'WDAY';
my $YY       = 'YY';
my $CC       = 'CC';
my $OS       = 'OS';
my $PERL     = 'PERL';
my $HOME     = 'HOME';
my $WHOAMI   = 'WHOAMI';
# Verarbeitungszustaende
my $RAW      = 1;
my $PENDING  = 2;
my $CACHED   = 3;
# Sonstige Konstanten
my $NONE     = 'NONE';

my $SYNTAX   = 'Syntax error';
my $INFINITE = 'Infinite recursion';

my $anchor;

my $default = Config::Manager::Conf->new();

################################################################################
# Oeffentliche Funktionen
################################################################################

sub whoami
{
    my($key,$value);

    foreach $key (@WHOAMI)
    {
        if (defined ($value = $ENV{$key})) { return ($value,$key); }
    }
    return ();
}

################################################################################
# Oeffentliche Methoden
################################################################################

sub add {
    my $self = shift;
    ref($self) || ($self = $default);
    local($_); # because of foreach
    foreach (@_) {
        next if (!(-r $_) && /$PRIVATE/io);
        open(FILE, $_) || return $self->_error("Unable to open file '$_':\n$!");
        my @lines = <FILE>;
        close(FILE) || return $self->_error("Unable to close file '$_':\n$!");
        $self->_add($_, \@lines) || return undef;
    }
    return 1;
}

sub default {
    return $default;
}

sub error {
    my $self = shift;
    ref($self) || ($self = $default);
    return $$self{'<error>'};
}

sub get {
    my $self = shift;
    ref($self) || ($self = $default);
    my $key = pop;
    my $section = pop || $DEFAULT;
    my $state = $$self{$section}{$key}{'state'};
    my $value;
    local($@); # because of eval{}; and parse()
    unless ($state) {
        return $ENV{$key} if $section eq $ENV && defined $ENV{$key};
        if ($section eq $SPECIAL &&
            ($key eq $WHOAMI || $key eq $HOME)) {
            $$self{$section}{$key}{'source'} = $SYS;
            $$self{$section}{$key}{'line'} = 0;
            unless (($value) = &whoami()) {
                return $self->_error( _not_found_($SPECIAL,$WHOAMI) );
            }
            return $value if $key eq $WHOAMI;
            {
                local($SIG{'__DIE__'}) = 'DEFAULT';
                eval {
                    ($value) = (getpwnam($value))[7];
                };
            }
            if ($@) {
                $value = $@;
                $value =~ s!\s+$!!;
                $value .= " on this platform" if ($value =~ s!\s+at\s+\S.+$!!);
                return $self->_error($value);
            }
            return $value if defined $value;
        }
        return $self->_error( _not_found_($section,$key) );
    }
    $value = $$self{$section}{$key}{'value'};
    return $value if $state == $CACHED;
    if ($state == $PENDING) {
        my $text   = _name_($section,$key) . " = \"$value\"";
        my $source = $$self{$section}{$key}{'source'};
        my $line   = $$self{$section}{$key}{'line'};
        return $self->_error($INFINITE, $text, $section, $source, $line);
    }
    $$self{$section}{$key}{'state'} = $PENDING;
    if (defined ($value = $self->parse($value, $section))) {
        $$self{$section}{$key}{'value'} = $value;
        $$self{$section}{$key}{'state'} = $CACHED;
        return $value;
    }
    else {
        $$self{'<error>'} = $@;
        $$self{$section}{$key}{'state'} = $RAW;
        return undef;
    }
}

sub init {
    my $self = shift;
    my $scope = shift || $DEFAULT;
    my $base = __PACKAGE__;
    ref($self) || ($self = $default);
    $self->_init();
    # Wenn Ankerdatei unbekannt bzw. nicht vorhanden bzw. leer: Neu ermitteln
    unless ($anchor && (-f $anchor) && (-r $anchor) && (-s $anchor)) {
        # Anker ist die Datei "Conf.ini", die im selben Verzeichnis wie die
        # Moduldatei "Conf.pm" selbst liegt; dazu wird %INC herangezogen.
        $base =~ s!::!/!g;
        $anchor = $INC{"$base.pm"};
        $anchor =~ s!\.pm$!.ini!;
        unless ($anchor && (-f $anchor) && (-r $anchor) && (-s $anchor)) {
            $anchor = undef;
            return $self->_error("Can't locate '$base.ini' in %INC");
        }
    }
    return $self->set($SYS, $SPECIAL, $SCOPE, $scope) && $self->add($anchor);
}

sub new {
    my $this = shift;
    my $class = ref($this) || $this || __PACKAGE__;
    my $self = {};
    bless $self, $class;
    return $self->_init();
}

sub parse {
    my($self,$text,$eval) = @_;
    my($left,$right,$first,$var);
    $@ = '';
    return $text unless $text =~ /\$/;
    $left = $`;
    $right = $';
    if (length($right) == 0) {
        $@ = "illegal '\$' at end of string";
        return undef;
    }
    $first = substr($right,0,1);
    if ($first eq '$') {
        $left .= '$' unless $eval;
        return undef unless defined($right = $self->parse(substr($right,1),$eval));
        return $left . '$' . $right;
    }
    else {
        return undef unless (($var,$right) = $self->_parse_var($first,$right,$eval));
        return undef unless defined($right = $self->parse($right,$eval));
        return $left . $var . $right;
    }
}

sub scope {
    my $self = shift;
    ref($self) || ($self = $default);
    return $self->get($SPECIAL, $SCOPE);
}

sub set {
    my $self = shift;
    ref($self) || ($self = $default);
    my $value   = pop;
    my $key     = pop;
    my $section = pop || $DEFAULT;
    my $source  = pop || $USR;
    return $self->_error( _read_only_($SPECIAL,$key) )
        if ($section eq $SPECIAL && $source ne $SYS &&
        ($key eq $OS || $key eq $PERL || $key eq $SCOPE));
    return $self->_set($source, 0, $section, $key, $value, 1);
}

sub get_all {
    my $self = shift;
    my $list = [];
    ref($self) || ($self = $default);
    foreach my $sec (sort keys(%{$self})) {
        next unless
            (($sec =~ /^[a-zA-Z][a-zA-Z0-9_-]*$/) &&
            (substr($sec,-1) ne '-'));
        foreach my $key (sort keys(%{${$self}{$sec}})) {
            my $val = $self->get($sec,$key);
            my $ok = 1;
            unless (defined $val) {
                $val = $self->error();
                $val =~ s!\s+$!!;
                $ok = 0;
            }
            push(
                @{$list},
                [
                    $ok,
                    _name_($sec,$key),
                    $val,
                    $$self{$sec}{$key}{'source'},
                    $$self{$sec}{$key}{'line'}
                ]
            );
        }
    }
    foreach my $key (sort keys(%ENV)) {
        push(
            @{$list},
            [
                1,
                _name_($ENV,$key),
                $ENV{$key},
                $EXT,
                0
            ]
        );
    }
    return $list;
}

sub get_section {
    my $self = shift;
    my $sec = shift || $DEFAULT;
    my $hash = {};
    ref($self) || ($self = $default);
    foreach my $key (keys %{${$self}{$sec}}) {
        my $val = $self->get($sec,$key);
        if (defined $val)
        {
            ${$hash}{$key} = $val;
        }
#       else
#       {
#           $val = $self->error();
#           $val =~ s!\s+$!!;
#           ${$hash}{$key} = $val;
#       }
    }
    return $hash;
}

sub get_files {
    return [ @{shift->{'<files>'}} ];
}

################################################################################
# Private Methoden
################################################################################

sub _init {
    my $self = shift;
    # Alle frueheren Eintraege loeschen:
    %{$self} = ();
    # Liste der eingelesenen Dateien anlegen:
    $$self{'<files>'} = [];
    # Datumsangaben fuer SPECIAL-Section aus localtime() holen:
    my @localtime = localtime();
    # Jahresangabe bezieht sich auf das Basisjahr 1900:
    $localtime[5] += 1900;
    # Monat ist im Bereich 0-11, daher eins addieren:
    $localtime[4]++;
    # Der erste Januar ist in localtime() der nullte Tag, daher eins addieren:
    $localtime[7]++;
    # Der Wochentag Sonntag ist in localtime() mit Null kodiert:
    $localtime[6] = 7 unless ($localtime[6]);
    # Tag und Monat zweistellig fuer eindeutige Zeitstempel (2000123 kann der
    # 3. Dezember oder der 23. Januar sein); Tag des Jahres dreistellig:
    $self->set($SYS, $SPECIAL, $YEAR,  $localtime[5]);
    $self->set($SYS, $SPECIAL, $MONTH, sprintf('%02d',$localtime[4]));
    $self->set($SYS, $SPECIAL, $DAY,   sprintf('%02d',$localtime[3]));
    $self->set($SYS, $SPECIAL, $HOUR,  sprintf('%02d',$localtime[2]));
    $self->set($SYS, $SPECIAL, $MIN,   sprintf('%02d',$localtime[1]));
    $self->set($SYS, $SPECIAL, $SEC,   sprintf('%02d',$localtime[0]));
    $self->set($SYS, $SPECIAL, $YDAY,  sprintf('%03d',$localtime[7]));
    $self->set($SYS, $SPECIAL, $WDAY,                 $localtime[6] );
    $self->set($SYS, $SPECIAL, $YY,    sprintf('%02d',$localtime[5]%100));
    $self->set($SYS, $SPECIAL, $CC,    int($localtime[5]/100));
    $self->set($SYS, $SPECIAL, $OS,    $^O);
    $self->set($SYS, $SPECIAL, $PERL,  $^X);
    $self->set($SYS, $SPECIAL, $SCOPE, $NONE);
    return $self;
}

sub _add {
    my($self,$file,$list) = @_;
    my $line = 0;
    my $section = $DEFAULT;
    my $scope = $self->scope();
    my $next = '';
    my @next = ();
    local($_); # because of foreach
    local($@); # because of parse()
    push( @{$$self{'<files>'}}, $file );
    foreach (@$list) {
        $line++;
        # Leerzeilen und Kommentarzeilen ignorieren
        /^\s*(\S)/ && $1 ne '#' || next;
        # Leerzeichen und Zeilenumbruch vom Zeilenende entfernen
        s/\s+$//;
        # Neuer Abschnitt?
        if (/^\s*\[\s*([a-zA-Z][a-zA-Z0-9_-]*)\s*\]$/ && substr($1,-1) ne '-') {
            $section = $1;
            next;
        }
        # Text in Schluessel und Wert zerlegen
        unless (/^\s*\$?([a-zA-Z][a-zA-Z0-9_-]*)\s*=\s*(.*?\S.*?)\s*$/ && substr($1,-1) ne '-') {
            return $self->_error($SYNTAX, $_, $section, $file, $line);
        }
        my $key = $1;
        my $value = $2; # ist ggf. in doppelte Anfuehrungszeichen verpackt
        $value =~ s/^\s*"(.*)"\s*$/$1/;
        return $self->_error( _read_only_($SPECIAL,$key) )
            if $section eq $SPECIAL;
        if (($key eq $NEXTCONF) && ($section eq $scope)) {
            $next = $value;
        }
        $self->_set($file, $line, $section, $key, $value) || return undef;
    }
    return 1 if $next eq '';
    return $self->add($next)
        if (defined ($next = $self->parse($next, $scope)));
    $$self{'<error>'} = $@;
    return undef;
}

sub _error {
    my($self, $text, $description, $section, $source, $line) = @_;
    my $location = '';
    if (defined $section || defined $source || defined $line) {
        $location = ' in';
        $location .= " file '$source'" if $source;
        $location .= " line #$line"    if $line;
        $location .= " [$section]"     if $section;
    }
    $description = $description ? ": $description" : '';
    $$self{'<error>'} = $text . $location . $description;
    return undef;
}

sub _set {
    my($self, $source, $line, $section, $key, $value, $override) = @_;
    local($@); # because of parse()
    return $self->_error( _read_only_($section,$key) )
        if ($section eq $ENV || ($section eq $SPECIAL &&
        ($key eq $HOME || $key eq $WHOAMI)));
    my $src = $$self{$section}{$key}{'source'};
    if (defined $src && $src eq $source && $src ne $SYS && $src ne $USR) {
        my $error = "Double entry in file '$src' for configuration constant " . _name_($section,$key);
        if ($line && $$self{$section}{$key}{'line'}) {
            $error .= " in line #$$self{$section}{$key}{'line'} and #$line";
        }
        return $self->_error($error);
    }
    unless (defined $self->parse($value)) {
        return $self->_error($SYNTAX, $@, $section, $source, $line);
    }
    if ($override || not $src) {
        $$self{$section}{$key}{'source'} = $source;
        $$self{$section}{$key}{'line'}   = $line;
        $$self{$section}{$key}{'value'}  = $value;
        $$self{$section}{$key}{'state'}  = $RAW;
    }
    return 1;
}

################################################################################
# Private Funktionen
################################################################################

sub _name_ {
    my $key = pop;
    my $sec = pop || $DEFAULT;
    return "\$[$sec]{$key}";
}

sub _not_found_ {
    return "Configuration constant " . _name_(@_) . " not found";
}

sub _read_only_ {
    return "Configuration constant " . _name_(@_) . " is read-only";
}

############################################################
# Private Hilfsmethoden fuer parse()
############################################################

sub _parse_id {
    # Aufrufer muss sicherstellen, dass $text mit einem Buchstaben [A-Za-z] beginnt!
    my($self,$text) = @_;
    $text =~ /^([a-zA-Z][a-zA-Z0-9_-]*)/;
    return ($1,$') unless substr($1,-1) eq '-';
    $@ = "illegal terminating '-' in identifier '$1'";
    return ();
}

sub _parse_sub {
    # Aufrufer muss sicherstellen, dass $rest auf dem Anfang eines moeglichen '$' oder [A-Za-z] steht
    my($self,$rest,$eval) = @_;
    my($first,$variable);
    if (length($rest) == 0) {
        $@ = "expecting identifier or variable, unexpected end of string";
        return ();
    }
    $first = substr($rest,0,1);
    if ($first eq '$') {
        $rest = substr($rest,1);
        if (length($rest) == 0) {
            $@ = "found '$', expecting variable, unexpected end of string";
            return ();
        }
        $first = substr($rest,0,1);
        return (($variable,$rest) = $self->_parse_var($first,$rest,$eval));
    }
    elsif ($first =~ /^[A-Za-z]$/) {
        return (($variable,$rest) = $self->_parse_id($rest,$eval));
    }
    else {
        $@ = "expecting identifier or variable, found '$first', expected '$' or [A-Za-z]";
        return ();
    }
}

sub _parse_var {
    # Aufrufer muss sicherstellen, dass vor $first ein '$' war und dass $first erster Char von $rest ist
    my($self,$first,$rest,$eval) = @_;
    my($section,$variable,$value);
    $section = '';
    if ($first eq '[') {
        return () unless (($section,$rest) = $self->_parse_sub(substr($rest,1),$eval));
        if (length($rest) == 0) {
            $@ = "missing ']' after section name '$section', unexpected end of string";
            return ();
        }
        $first = substr($rest,0,1);
        if ($first ne ']') {
            $@ = "missing ']' after section name '$section', found '$first' instead";
            return ();
        }
        $rest = substr($rest,1);
        if (length($rest) == 0) {
            $@ = "missing key name after section name '$section', unexpected end of string";
            return ();
        }
        $first = substr($rest,0,1);
    }
    if ($first eq '{') {
        return () unless (($variable,$rest) = $self->_parse_sub(substr($rest,1),$eval));
        if (length($rest) == 0) {
            $@ = "missing '}' after variable name '$variable', unexpected end of string";
            return ();
        }
        $first = substr($rest,0,1);
        if ($first ne '}') {
            $@ = "missing '}' after variable name '$variable', found '$first' instead";
            return ();
        }
        $rest = substr($rest,1);
        if ($eval) {
            return ($value,$rest) if defined ($value = $self->get($section || $eval, $variable));
            $@ = $self->error();
            return () if $section || $@ ne _not_found_($eval, $variable);
            $@ = '';
            return ($value,$rest) if defined ($value = $self->get($variable));
            $@ = $self->error();
            return ();
        }
        else {
            if ($section eq '') { return( "[$section]{$variable}", $rest ); }
            else                { return( "{$variable}",           $rest ); }
        }
    }
    elsif ($first =~ /^[A-Za-z]$/) {
        return () unless (($variable,$rest) = $self->_parse_id($rest,$eval));
        if ($eval) {
            return ($value,$rest) if defined ($value = $self->get($section || $eval, $variable));
            $@ = $self->error();
            return () if $section || $@ ne _not_found_($eval, $variable);
            $@ = '';
            return ($value,$rest) if defined ($value = $self->get($variable));
            $@ = $self->error();
            return ();
        }
        else {
            if ($section eq '') { return( "[$section]$variable", $rest ); }
            else                { return( $variable,             $rest ); }
        }
    }
    else {
        if ($section eq '') { $@ = "found '\$' followed by '$first', expecting '{' or [A-Za-z]"; }
        else                { $@ = "found '\$[$section]' followed by '$first', expecting '{' or [A-Za-z]"; }
        return ();
    }
}

1;

__END__

=head1 NAME

Config::Manager::Conf - Ich verwalte den Inhalt von Konfigurationsdateien

=head1 SYNOPSIS

Konfigurationsdaten sind Schluessel-Wert-Paare, die in Abschnitte gegliedert
sind. Sie koennen entweder mit

   Config::Manager::Conf->set(section, key, value);

programmatisch gesetzt werden oder mit

   Config::Manager::Conf->add(file1, file2, ...);

aus Konfigurationsdateien eingelesen werden. Sofern die Standarddatei Conf.ini
und die dort angegebene Folgedatei(en) eines Bereichs eingelesen werden sollen,
reicht statt dessen auch ein

   Config::Manager::Conf->init(scope);

Mit

   Config::Manager::Conf->get(section, key)

werden die gesetzten und/oder eingelesenen Daten ausgelesen.

Alle genannten Operationen funktionieren nicht nur als Klassenmethoden (wie
oben angegeben), sondern auch als Instanzmethoden. Das heisst, auch folgende
Aufrufe sind moeglich:

   my $conf = Config::Manager::Conf->new();
   $conf->init(scope);
   $conf->set(section, key, value);
   $conf->get(section, key);

Dies ist nuetzlich, wenn man mehrere Konfigurationen innerhalb eines Programms
braucht, z.B. um voruebergehend mit einer manipulierten Kopie der Konfiguration
zu arbeiten, ohne die Originalkonfiguration zu zerstoeren.

Beispiel fuer eine Konfigurationsdatei:

   # Was mit # beginnt, ist Kommentar. Kommentarzeilen werden genau so
   # ignoriert wie Leerzeilen, daher ...

   # ... beginnt hier der erste Abschnitt:
   [DIRECTORIES]
   # Innerhalb des Abschnitts folgen Schluessel-Wert-Paare:
   ROOT = D:\work
   # Die Variable $ROOT wird durch den oben definierten Wert substituiert:
   TMP = $ROOT\tmp

   # Ein neuer Abschnitt:
   [FILES]
   # Auch Variablen eines anderen Abschnitts sind verfuegbar:
   TMPFILE1 = $[DIRECTORIES]{TMP}\tempfile1.txt
   # Wer unbedingt Anfuehrungszeichen verwenden moechte, bitteschoen:
   TMPFILE2 = "$[DIRECTORIES]{TMP}\tempfile2.txt"

   # Noch ein Abschnitt
   [DIVERSES]
   # Wenn ich ein Dollarzeichen '$' brauche:
   MS = "Micro$$oft"
   # Backslash '\' hat keine Sonderbedeutung:
   SW = Sun\$MS\IBM
   # Wenn ich ein '$' vor einem '$' von einer Substitution brauche:
   BD = $$$[SO]{WHAT}

   # Variablennamen koennen in geschweifte Klammern gesetzt werden,
   # muessen aber (ausser bei Indirektion) nicht:
   MESSAGE1 = Schreibe alles nach $[FILES]TMPFILE1
   MESSAGE2 = Schreibe alles nach $[FILES]{TMPFILE2}

   # Ein Schluessel-Wert-Paar kann durch einen Dollar eingeleitet werden, um
   # sowohl Shell- als auch Perl-Programmierer zufriedenzustellen :-). Der
   # Dollar ist aber ohne Bedeutung, d.h. folgende Zeilen sind gleichwertig:
   $KEY = Value
   KEY = Value

Tritt in mehreren Dateien ein Schluessel im gleichen Abschnitt auf, so gilt der
zuerst eingelesene Wert. Anders formuliert, man muss die massgeblichen Dateien
zuerst, Dateien mit Default-Einstellungen zuletzt einlesen. Die Methode set()
hingegen ueberschreibt auch bestehende Werte.

=head1 DESCRIPTION

Ich verwalte eine Konfiguration, d.h. den Inhalt einer oder mehrerer
Konfigurationsdateien. Eine Konfiguration besteht aus Schluessel-Wert-Paaren,
die in Abschnitte (Sections) gegliedert sind.

Ein Wert kann Verweise enthalten auf Schluessel, die anderswo definiert sind
(Variablensubstitution). Zyklen in der Definition sind nicht erlaubt; sie
werden beim Auswerten erkannt und als Fehler gemeldet.

Eine Konfiguration kann die Information mehrerer Konfigurationsdateien
zusammenfassen. Je Datei kann innerhalb eines Abschnitts jeder Schluessel nur
einmal vergeben werden, sonst wird beim Lesen der Datei ein Fehler gemeldet.
Es ist moeglich, den Schluessel im gleichen Abschnitt mehrerer Dateien zu
definieren; dann gilt der Wert aus der zuerst eingelesenen Datei. Die
Substitution erfolgt beim ersten Zugriff auf den Wert ("Lazy Evaluation"),
daher kann ein Wert abhaengige Werte sowohl in vorangehenden als auch in
nachfolgenden Dateien beeinflussen.

Fuer den Aufbau von Konfigurationsdateien gelten folgende Regeln:

=over 4

=item *

Kommentare:

Eine Kommentarzeile beginnt mit "#"; fuehrende Leerzeichen sind erlaubt.
Kommentarzeilen werden genau so ignoriert wie Leerzeilen oder Zeilen, die
nur Leerzeichen enthalten.

=item *

Abschnittsueberschriften:

Eine Abschnittsueberschrift steht auf einer eigenen Zeile in eckigen Klammern
("[" und "]"). Sie beginnt mit einem Buchstaben, es folgen beliebig viele
Buchstaben, Ziffern, "_" (Unterstrich) und "-" (Bindestrich); sie darf nicht
mit einem Bindestrich enden. Gross- und Kleinschreibung wird unterschieden.

Fuehrende und/oder nachfolgende Leerzeichen innerhalb und/oder ausserhalb der
eckigen Klammern werden ignoriert.

=item *

Schluessel-Wert-Paare:

In einer Zeile stehen der Name des Schluessels, ein Gleichheitszeichen, und der
Wert. Leerzeichen um Schluessel und Wert werden ignoriert.

Das erste Zeichen des Schluessels ist ein Buchstabe, es folgen beliebig viele
Buchstaben, Ziffern, "_" (Unterstrich) und "-" (Bindestrich). Der Schluessel
darf nicht mit einem Bindestrich enden. Gross- und Kleinschreibung wird
unterschieden. Man darf dem Schluessel einen "$" (Dollar) voranstellen, dies
hat aber weiter keine Bedeutung.

Man darf den Wert in doppelte Anfuehrungszeichen setzen; noetig ist das jedoch
nur, wenn der Wert mit Leerzeichen anfangen oder enden soll. Auch wenn der
Wert in Anfuehrungszeichen gesetzt ist, werden enthaltene Anfuehrungszeichen
NICHT besonders gekennzeichnet (also KEINE Verdopplung oder Voranstellen eines
Backslashes).

Schluessel-Wert-Paare vor der ersten Abschnittsueberschrift gehoeren zum
Abschnitt "DEFAULT". Dieser wird bei Bedarf automatisch angelegt, aber sonst
wie jeder andere Abschnitt behandelt.

=item *

Substitution:

Der Wert kann Verweise auf andere Schluessel-Wert-Paare enthalten; jeder
Verweis wird durch den betreffenden Wert ersetzt. Ein Verweis besteht aus
einem "$" (Dollar) und dem gewuenschten Schluessel. Es wird nur im aktuellen
und im DEFAULT-Abschnitt gesucht (in dieser Reihenfolge). Schluessel eines
anderen Abschnitts muessen durch den Abschnittsnamen qualifiziert werden;
Der Abschnitt muss in "[...]" und der Schluessel (d.h. der Variablenname)
kann in "{...}" eingefasst werden, dadurch sind beide Angaben sicher
voneinander getrennt und auch leichter lesbar.

Das Einfassen des Variablennamens in "{...}" (geschweifte Klammern) ist
notwendig, wenn es danach mit einem Buchstaben, einer Ziffer, einem
Unterstrich oder einem Bindestrich weitergeht (es waere sonst unklar,
wo der Variablenname (bzw. die Substitution) aufhoert und wo der Text
weitergeht).

Somit sind auch verschachtelte Substitutionen moeglich: Der Name des Abschnitts
und/oder der Schluessel koennen ihrerseits aus einer Substitution bestehen
(dies wird im folgenden "Indirektion" genannt, weil der jeweilige Name nicht
als literaler String angegeben, sondern aus dem Inhalt der spezifizierten
Konfigurationskonstanten ermittelt wird).

Wenn man den Dollar als Zeichen braucht, stellt man ihm einen weiteren Dollar
voran, um seine Sonderbedeutung fuer die Substitution aufzuheben.

=item *

Besondere Abschnitte:

Der Abschnitt "ENV" erlaubt lesenden Zugriff auf Umgebungsvariablen. Diese
Werte koennen nicht geaendert werden (weder mit set() noch aus einer Datei).

(Es ist jedoch technisch moeglich, wenn auch stark abzuraten, solche Werte
direkt in den Perl-Hash "%ENV" zu schreiben und damit auch in die Umgebung.)

Der Abschnitt "SPECIAL" enthaelt die Schluessel YEAR (vierstelliges Jahr),
YY (zweistelliges Jahr), CC (Jahrhundert), MONTH, DAY, YDAY (fortlaufende
Nummerierung der Tage eines Jahres); OS (Betriebssystem), SCOPE (wie in der
Methode init() angegeben), HOME (wie von "getpwnam()" fuer den Benutzer aus
WHOAMI zurueckgeliefert, falls dieser Systemaufruf implementiert ist, ansonsten
"undef" und entsprechende Fehlermeldung) sowie WHOAMI (der erste Wert, der
in der Umgebung fuer USERNAME, LOGNAME, USER oder LOGIN gefunden wurde). Die
Werte werden vom System gesetzt; der Abschnitt "SPECIAL" kann nicht aus einer
Datei eingelesen werden. Es ist aber moeglich, die Datumsangaben durch set()
zu ueberschreiben (koennte fuer den Test von Tools nuetzlich sein); OS, SCOPE,
HOME und WHOAMI sind auch mit set() nicht aenderbar.

Die Zeitangaben werden zum Zeitpunkt des Aufrufs der new()- bzw. der
init()-Methode gesetzt und aendern sich ab da nicht mehr; d.h. sie
werden bei aufeinanderfolgenden Abfragen NICHT mehr auf den jeweils
aktuellen Wert gesetzt. (Der Benutzer kann dies aber wie gesagt
ggfs. selbst, mit Hilfe der set()-Methode, tun.)

=back

=head1 ANMERKUNG

Diese Klasse ist als geschachtelter Hash implementiert, und zwar hat man je
Abschnitt-Schluessel-Paar folgende Eintraege:

   $$self{$section}{$key}{'source'};
   $$self{$section}{$key}{'line'};
   $$self{$section}{$key}{'value'};
   $$self{$section}{$key}{'state'};

Hierbei bedeutet:

   source - Datenquelle (z.B. Dateiname)
   line   - Zeilennummer in der Datei (optional)
   value  - Wert des Schluessels
   state  - Verarbeitungszustand des Wertes:
            'raw'     = Substitution noch nicht durchgefuehrt
            'pending' = Substitution wird gerade durchgefuehrt
            'cached'  = Subsitution wurde erfolgreich durchgefuehrt

Weiterhin enthaelt

   $$self{'<error>'}

die aktuellste Fehlermeldung. Die spitzen Klammern verhindern Konflikte mit
Abschnittsnamen (Abschnitte beginnen grundsaetzlich mit einem Buchstaben).

Alle oeffentlichen Methoden sind so ausgelegt, dass sie nicht nur auf einer
Instanz, sondern auch auf der Klasse aufgerufen werden koennen; in letzterem
Fall wird die Methode auf der Default-Instanz ausgefuehrt.

=head1 BEKANNTE FEHLER

Diese Klasse ist nicht thread-sicher: Bei der Variablensubstitution muessen
Zyklen erkannt werden, und dies funktioniert nicht zuverlaessig, wenn mehrere
Threads gleichzeitig eine Variable auswerten.

Es wird immer nur der letzte aufgetretene Fehler gespeichert. Treten mehrere
Fehler nacheinander auf, ist nur die jeweils letzte Fehlermeldung abrufbar.

Man erhaelt eine Endlosschleife, wenn in einer Datei eine NEXTCONF-Anweisung
direkt oder indirekt auf die Datei selbst verweist.

Doppelte Eintraege innerhalb eines Abschnitts werden nur erkannt, wenn der
erste dieser Eintraege tatsaechlich wirksam ist (d.h. nicht durch einen Eintrag
in einer frueher eingelesenen Datei verdeckt wird).

=head1 DATENSTRUKTUREN

=over 4

=item *

C<$anchor>

Name (inkl. Pfad) der ersten Konfigurationsdatei; hier beginnt die Kette der
Konfigurationsdateien. Wird von der Methode init() gesetzt.

=item *

C<$default>

Die Default-Instanz dieser Klasse; siehe Methode default().

=back

=head1 OEFFENTLICHE FUNKTIONEN

=over 4

=item *

C<whoami()>

This function returns the login of the current user and
the name of the environment variable in which it was found.

 Parameter: -
 Rueckgabe: Liste (UserID,VarName) aus der Umgebung
            (d.h. es wird (value,key) zurueckgegeben)

It polls "C<$ENV{'USERNAME'}>", "C<$ENV{'LOGNAME'}>",
"C<$ENV{'USER'}>" and "C<$ENV{'LOGIN'}>" (in this order)
and returns the first key-value-pair it finds whose value
is not "C<undef>" (note though that key and value are reversed
in the returned list!).

Returns the empty list if none of these values is defined.

=back

=head1 OEFFENTLICHE METHODEN

=over 4

=item *

C<add(file1, file2, ...)>

Ich lese Konfigurationsdaten aus den angegebenen Dateien

 Parameter: Dateiname1
            Dateiname2
            ...
 Rueckgabe: <OK> | undef

Ich lese Konfigurationsdaten aus den angegebenen Dateien. Wenn ein Fehler
auftritt, setze ich einen Fehler und gebe undef zurueck.

Eine Ausnahmebehandlung gibt es fuer Dateien mit Passwoertern und aehnlich
sensiblen Daten darin: Falls der Name einer Datei dem Regulaeren Ausdruck
"C</\bPRIVATE?\.ini$/i>" genuegt und die Datei fuer den Aufrufer nicht
lesbar ist (z.B. weil sie einem anderen Benutzer gehoert und die
Zugriffsrechte entsprechend gesperrt sind), wird diese Datei
ignoriert (uebersprungen) und keine Fehlermeldung ausgegeben.

Damit bricht die Kette der einzulesenden Konfigurationsdateien unter
Umstaenden ab. Aus diesem Grund muessen derartige private Dateien immer
am Ende der Kette der einzulesenden Konfigurationsdateien stehen.

=item *

C<default()>

Ich gebe eine Referenz auf die Default-Konfiguration zurueck.

 Parameter: -
 Rueckgabe: Referenz auf Default-Konfiguration

Ich gebe jene Konfiguration zurueck, die von den Klassenmethoden, d.h.
Config::Manager::Conf->method(), verwendet wird.

=item *

C<error()>

Ich gebe eine Beschreibung des letzten aufgetretenen Fehlers zurueck

 Parameter: -
 Rueckgabe: Fehlertext || undef

=item *

C<get(section, key)>

Ich ermittle den Wert zu einem Schluessel

 Parameter: Section (optional)
            Schluessel
 Rueckgabe: Wert || undef

Ich ermittle den Wert zu einem Schluessel. Ist die Section gleich ENV, dann
gebe ich die entsprechende Umgebungsvariable zurueck. Ist keine Section
angegeben, suche ich in der DEFAULT-Section.

=item *

C<init(scope)>

Ich initialisiere mich fuer den angegebenen Gueltigkeitsbereich

 Parameter: Name der Anwendung (optional)
 Rueckgabe: <OK> || undef

Ich initialisiere mich fuer den angegebenen Gueltigkeitsbereich, d.h. ich lese
die Datei "Conf.ini" ein und alle Dateien, die direkt oder indirekt durch die
Anweisungen E<lt>scopeE<gt>::NEXTCONF angegeben sind.

Wird diese Methode als Klassenmethode aufgerufen, dann setze ich ausserdem die
Default-Instanz zurueck.

=item *

C<new()>

 Konstruktor
 Parameter: -
 Rueckgabe: Neues Conf-Objekt

=item *

C<parse(string, eval)>

Ich parse den gegebenen String und substituiere ggfs. die Variablen.

 Parameter: Der zu bearbeitende String
            Section, in der der String ausgewertet wird (optional)
 Rueckgabe: Der bearbeitete String || undef (bei Fehler)
            In $@ steht ggfs. die Fehlermeldung

Ich parse die rechten Seiten der Zuweisungen aus den Konfigurationsdateien. Ist
in eval eine Section angegeben, fuehre ich die Substitution durch, wobei ich
nicht-qualifizierte Schluessel zunaechst in dieser Section, dann in der
DEFAULT-Section suche. Ist "eval" nicht angegeben oder leer, fuehre ich die
Substitution nicht durch, sondern pruefe nur die Syntax.

Der String muss von fuehrenden und nachfolgenden Leerzeichen sowie den
optionalen umschliessenden Anfuehrungszeichen befreit sein. Der Leerstring
ist als Eingabe erlaubt.

FEATURES:

 1) Variablensubstitution mit Abschnitts- und Variablennamen.
 2) Abschnitts- und Variablennamen koennen ebenfalls Variablen sein
    (rekursive Substitution, d.h. ermoeglicht Indirektion).

REGELN:

 1) Soll der String einen literalen Dollar "$" enthalten, muss er
    doppelt geschrieben werden: "$$".

 2) Variablen werden durch einen vorangestellten einfachen Dollar "$"
    gekennzeichnet. Der Variablenname ist der Name des Schluessels, dem
    der Abschnittsname vorangestellt werden kann. Der Abschnittsname
    wird dabei in eckige Klammern ("[]") eingefasst. Der Variablen-
    name kann zur Vermeidung von Mehrdeutigkeiten in geschweifte
    Klammern ("{}") eingefasst werden. Zwischen Abschnittsnamen und
    Variablennamen darf kein Leerraum stehen. Beispiele:

        $Var, $[Sec]Var, ${Var}, $[Sec]{Var}, Text${Var}Text

    Der Name eines Abschnitts oder einer Variablen muss mit einem
    Buchstaben beginnen, gefolgt von beliebig vielen Zeichen (auch
    null) aus a-z, A-Z, 0-9, Unterstrich "_" und Bindestrich "-". Der
    Name darf nicht mit einem Bindestrich enden.

    Gross- und Kleinschreibung wird unterschieden. (!)

 3) Die Indirektion ist grundsaetzlich nur zwischen Klammern
    moeglich, da zwei aufeinanderfolgende Dollarzeichen ("$")
    fuer ein literales Dollarzeichen stehen ("$$var" steht
    fuer den literalen String "$var"). Beispiele:

    $VAR, ${VAR}, ${$var}, $[SEC]VAR, $[SEC]{VAR},
    $[SEC]{$var}, $[$sec]VAR, $[$sec]{VAR}, $[$sec]{$var}

 4) Bei einer Indirektion kann eine Variable den Namen eines Abschnitts
    ODER den Namen einer Variablen enthalten, aber nicht beides; z.B.:

        $Section  = Person
        $Variable = Name
        $Fullname = $[$Section]{$Variable}

    Dagegen geht folgendes NICHT:

        $Variable = Person::Name
        $Fullname = ${$Variable}

    Mit anderen Worten: Eine Variable, deren Wert zur Indirektion
    eingesetzt wird, darf nur einen String enthalten, der dem
    regulaeren Ausdruck ^[a-zA-Z][a-zA-Z0-9_-]*$ genuegt und
    nicht mit einem Bindestrich endet.

VORSICHT:

 1) "$Var}" ist eine legale Konstruktion (mit einem literalen "}"
    am Schluss), ebenso wie "{$Var}".
 2) [, ], { und } sind ausserhalb von Variablensubstitutionen
    ganz normale Literale.

GRAMMATIK:

  S = @       |
      A S     |
      V S

  V = $X      |
      ${X}    |
      $[X]X   |  (Interpolation)
      $[X]{X} |
  ---------------------------------
      ${V}    |
      $[V]X   |   (Indirektion)
      $[V]{X} |
      $[X]{V} |
      $[V]{V}

  X = (A-Za-z)(A-Za-z0-9_-)*

  Erlaeuterungen:

  "@" steht hier fuer den leeren String.

  "A" steht fuer beliebige ASCII-Zeichen;
  allerdings muss fuer jedes Dollarzeichen
  ("$") ein doppeltes Dollarzeichen ("$$")
  geschrieben werden.

  "V" ist die Spezifikation einer
  Konfigurationskonstanten ("Variable").

  "X" ist ein literaler Identifier (d.h.
  Variablen- oder Abschnittsname).

=item *

C<scope()>

Ich gebe meinen Gueltigkeitsbereich zurueck

 Parameter: -
 Rueckgabe: Gueltigkeitsbereich

Ich gebe meinen Gueltigkeitsbereich zurueck, d.h. der Name, der in der Methode
init() angegeben wurde. Wurde die Methode init() nicht durchlaufen, dann gebe
ich 'NONE' zurueck.

=item *

C<set(source, section, key, value)>

Ich setze den Wert zu einem Schluessel

 Parameter: Datenquelle (optional)
            Section (optional)
            Schluessel
            Wert
 Rueckgabe: <OK> || undef

Ich setze den Wert des Schluessels in der angegebenen Section; ist keine
Section angegeben, wird "DEFAULT" verwendet. Weiterhin kann angegeben werden,
um welche Datenquelle es sich handelt; ohne diese Angabe wird die Kommandozeile
angenommen.

Mit dieser Methode werden die Einstellungen aus den Konfigurationsdateien
nachtraeglich ueberschrieben. Es ist nicht zulaessig, mit dieser Methode fuer
die gleiche Datenquelle und die gleiche Section einen Schluessel zweimal zu
definieren. In diesem Fall wird ein Fehler gesetzt und undef zurueckgegeben.
Diese Pruefung wird allerdings abgeschaltet, wenn als Datenquelle "<sys>"
angegeben wird - wovon wir hiermit heftigst abraten :-).

=item *

C<get_all()>

Ich gebe saemtliche Konfigurationswerte eines Konfigurationsobjekts aus.

 Parameter: -
 Rueckgabe: Referenz auf Liste von Quintupeln von Werten

Jedes Element der zurueckgelieferten Liste besteht aus einem anonymen
Array mit fuenf Werten.

Der erste Wert gibt an, ob es sich bei dem dritten Wert um den Inhalt
der betreffenden Konfigurationskonstanten handelt, oder um eine Fehlermeldung
(weil der Wert nicht erfolgreich bestimmt werden konnte, z.B. aufgrund
nicht aufloesbarer eingebetteter Konfigurationskonstanten).

Der Wert "1" bedeutet "alles in Ordnung", der Wert "0" bedeutet, dass
es sich um eine Fehlermeldung handelt.

Der zweite Wert gibt den Namen der Konfigurationskonstanten in der Form
"C<$[SECTION]{VARIABLE}>" an.

Der dritte Wert enthaelt entweder den Wert der Konfigurationskonstanten
oder eine Fehlermeldung.

Der vierte Wert des Tupels gibt die Quelle an, aus dem die betreffende
Konfigurationskonstante stammt.

Der fuenfte Wert gibt die Zeilennummer in der Quelle an. Dieser kann
den Wert Null haben, falls es sich bei der Quelle nicht um eine Datei
gehandelt hat (sondern zum Beispiel um einen expliziten Aufruf der
Methode "set()").

Die Liste ist alphabetisch (ASCII) nach den Namen der Sections und
darin nach den Namen der Konfigurationskonstanten sortiert.

=item *

C<get_section(section)>

Ich gebe saemtliche Konfigurationswerte einer Section des gegebenen
Konfigurationsobjekts zurueck.

 Parameter: Name der Section (optional)
 Rueckgabe: Referenz auf Hash von Schluessel/Wert-Paaren

Falls keine Section angegeben ist, wird der Inhalt der
"DEFAULT"-Section zurueckgegeben.

Falls ein Wert in der Section nicht ermittelt werden kann
(z.B. weil er von anderen Werten abhaengt, deren Ermittlung
nicht moeglich ist), wird er nicht in den Ausgabe-Hash
kopiert.

=item *

C<get_files()>

Ich gebe die Liste der eingelesenen Konfigurationsdateien fuer
ein Konfigurationsobjekt zurueck, in der Reihenfolge in der sie
eingelesen wurden.

 Parameter: -
 Rueckgabe: Referenz auf Array von Dateinamen

=back

=head1 PRIVATE METHODEN

=over 4

=item *

C<_init()>

Ich initialisiere jedes neue Konfigurations-Objekt.

 Parameter: -
            (wie bei allen Objektmethoden;
             eine Objekt-Referenz "$self")
 Rueckgabe: Die Objekt-Referenz "$self"

Ich erledige die grundlegende Initialisierung eines jeden
Konfigurations-Objekts ("SPECIAL"-Variablen).

=item *

C<_add(file, [ line1, line2, ... ])>

Ich merke mir die angegebenen Zeilen

 Parameter: Dateiname
            Referenz auf Array mit Zeileninhalten
            ...
 Rueckgabe: <OK> || undef

Ich speichere die Konfigurationsdaten aus den angegebenen Zeilen; diese stammen
aus der angegebenen Datei.

=item *

C<_error(text, description, section, source, line)>

Ich setze meinen Fehlertext

 Parameter: Fehlertext
            Ergaenzender Fehlertext (optional)
            Section, in der der Fehler auftritt (optional)
            Datenquelle, in der der Fehler auftritt (optional)
            Zeilennummer, in der der Fehler auftritt (optional)
 Rueckgabe: undef

=item *

C<_set(source, line, section, key, value, override)>

Ich setze den Wert zu einem Schluessel

 Parameter: Datenquelle
            Zeilennummer in der Datenquelle
            Section
            Schluessel
            Wert
            Bestehenden Wert ueberschreiben?
 Rueckgabe: <OK> || undef

Ich setze den Wert zu einem Schluessel in einer Section.

Es ist nicht zulaessig, in der gleichen Datei in der gleichen Section einen
Schluessel zweimal zu definieren. In diesem Fall setze ich einen Fehler und
gebe undef zurueck.

Es ist unzulaessig, einen Wert in die Section ENV zu schreiben (diese ist fuer
Werte, die aus Umgebungsvariablen stammen). Weiterhin ist unzulaessig, die
Werte SCOPE, OS, HOME und WHOAMI aus der Section SPECIAL zu schreiben. In
diesen Faellen setze ich einen Fehler und gebe undef zurueck.

=back

=head1 PRIVATE FUNKTIONEN

=over 4

=item *

C<_name_([section,] key)>

Ich gebe den Namen in der Form C<$[section]{key}> zurueck. Ist
keine Section oder die DEFAULT-Section angegeben, dann wird als
Section C<[DEFAULT]> geschrieben.

=item *

C<_not_found_([section,] key)>

Ich gebe den String "C<Configuration constant $[section]{key} not found>"
zurueck. Ist keine Section oder die DEFAULT-Section angegeben,
dann wird als Section C<[DEFAULT]> geschrieben.

=item *

C<_read_only_([section,] key)>

Ich gebe den String "C<Configuration constant $[section]{key} is read-only>"
zurueck. Ist keine Section oder die DEFAULT-Section angegeben,
dann wird als Section C<[DEFAULT]> geschrieben.

=back

=head1 SEE ALSO

Config::Manager(3),
Config::Manager::Base(3),
Config::Manager::File(3),
Config::Manager::PUser(3),
Config::Manager::Report(3),
Config::Manager::SendMail(3),
Config::Manager::User(3).

=head1 VERSION

This man page documents "Config::Manager::Conf" version 1.7.

=head1 AUTHORS

 Steffen Beyer <sb@engelschall.com>
 http://www.engelschall.com/u/sb/download/
 Gerhard Albers

=head1 COPYRIGHT

 Copyright (c) 2003 by Steffen Beyer & Gerhard Albers.
 All rights reserved.

=head1 LICENSE

This package is free software; you can use, modify and redistribute
it under the same terms as Perl itself, i.e., under the terms of
the "Artistic License" or the "GNU General Public License".

Please refer to the files "Artistic.txt" and "GNU_GPL.txt"
in this distribution, respectively, for more details!

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

