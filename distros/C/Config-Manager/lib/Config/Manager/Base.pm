
###############################################################################
##                                                                           ##
##    Copyright (c) 2003 by Steffen Beyer & Gerhard Albers.                  ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

package Config::Manager::Base;

use strict;
use vars qw( @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION $SCOPE $NONE %SIG @ARGV );

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw();

@EXPORT_OK = qw(
                   $SCOPE
                   GetList
                   GetOrDie
                   ReportErrorAndExit
               );

%EXPORT_TAGS = (all => [@EXPORT_OK]);

$VERSION = '1.7';

use Config::Manager::Conf;
use Config::Manager::Report qw(:all);

################################################
## Private function, name prescribed by Perl! ##
################################################

BEGIN # Global initialization
{
    my($self) = __PACKAGE__;
    my($depth,$caller,$index,$param,$match,$sec,$var,$val,$err);
    my             (  $HOST_LIST, $LANG_LIST, $SRC_LIST, $OBJ_LIST, $EXE_LIST );
    my(@Refs)  =   ( \$HOST_LIST,\$LANG_LIST,\$SRC_LIST,\$OBJ_LIST,\$EXE_LIST );
    my(@Names) = qw(   HOST_LIST   LANG_LIST   SRC_LIST   OBJ_LIST   EXE_LIST );
    my($Section) = "Commandline";
    my($EnvHost) = 1;
    my($EnvLang) = 1;

    ###########################################################################
    # Ensure writability of log dirs etc. for all users:
    umask(002);
    ###########################################################################
    # Determine current "scope":
    $SCOPE = $NONE = 'NONE';
    $self =~ s!::.*$!!;
    $depth = 0;
    while (defined ($caller = (caller($depth++))[0]))
    {
        if ($caller =~ /^         ${self}
                              :: ([a-zA-Z0-9_]+)
                          (?: ::  [a-zA-Z0-9_]+ )* $/ox)
        {
            $SCOPE = $1;
        }
    }
    if ($SCOPE eq $NONE)
    {
        warn "WARNING: Couldn't determine the caller's \"scope\" (assuming '$NONE')!\n";
    }
    unless (defined (Config::Manager::Conf->init( $SCOPE )))
    {
        $err = Config::Manager::Conf->error();
        $err =~ s!\s+$!!;
        &abort( __PACKAGE__ .
            "::BEGIN(): Global initialization failed:\n$err\n" );
    }
    ###########################################################################
    # Install signal handlers for common signals:
    $SIG{'INT'} = 'IGNORE'; # Ignore Ctrl-C (important for closing log file!)
    ###########################################################################
    # Initialize logging module and log file (trigger creation of singleton object):
    unless (ref ($err = Config::Manager::Report->singleton()))
    {
        $err =~ s!\s+$!!;
        &abort( __PACKAGE__ .
            "::BEGIN(): Global initialization failed:\n$err\n" );
    }
    $err = '';
    Config::Manager::Report->notify(1); # in case this should be the default
    ###########################################################################
#   # Read configuration constants for command line option processing:
#   for ( $index = 0; $index < @Refs; $index++ )
#   {
#       $var = $Refs[$index];
#       $val = $Names[$index];
#       unless (defined (${$var} = Config::Manager::Conf->get( $Section, $val )))
#       {
#           $err = Config::Manager::Conf->error();
#           $err =~ s!\s+$!!;
#           Config::Manager::Report->report
#           (
#               $TO_LOG+$TO_ERR,$LEVEL_FATAL+$USE_LEADIN,
#               __PACKAGE__ . "::BEGIN():",
#               "Couldn't get the value of configuration constant " .
#               Config::Manager::Conf::_name_($Section,$val) . ":",
#               $err
#           );
#           &abort();
#       }
#       # Sanity check (*MUST* be uppercase in order to avoid
#       # clashes with lowercase tool-specific parameters!):
#       unless (${$var} =~ m!^[A-Z][A-Z0-9]*(?:\|[A-Z][A-Z0-9]*)*$!)
#       {
#           Config::Manager::Report->report
#           (
#               $TO_LOG+$TO_ERR,$LEVEL_FATAL+$USE_LEADIN,
#               __PACKAGE__ . "::BEGIN():",
#               "Syntax error in configuration constant " .
#               Config::Manager::Conf::_name_($Section,$val) .
#               " (must be UPPERCASE and '|'-separated)!"
#           );
#           &abort();
#       }
#   }
#   $match = "HOST=(?:$HOST_LIST)|LANG=(?:$LANG_LIST)|SRC=(?:$SRC_LIST)|OBJ=(?:$OBJ_LIST)|EXE=(?:$EXE_LIST)";
#   ###########################################################################
#   # The shortcuts below implement the following precedence rules:           #
#   # (low) Config File << Environment Variable << Command Line Option (high) #
#   ###########################################################################
#   # Configuration Shortcuts Part 1:
#   $index = 0;
#   LOOP1:
#   while ($index < @ARGV)
#   {
#       $param = \$ARGV[$index];
#       if ($$param =~ m!^-(?:$match)(?:,(?:$match))*$!o)
#       {
#           splice(@ARGV,$index,1);
#           while ($$param =~ m!($match)!go)
#           {
#               $sec = $1;
#               ($var,$val) = split(/=/, $sec);
#               $EnvHost = 0 if ($var eq 'HOST');
#               $EnvLang = 0 if ($var eq 'LANG');
#               splice(@ARGV,$index,0,"-D${Section}::$var=$val");
#               $index++;
#           }
#           next LOOP1;
#       }
#       elsif ($$param =~ m!^-($HOST_LIST),($LANG_LIST),($SRC_LIST),($OBJ_LIST),($EXE_LIST)$!o)
#       {
#           $EnvHost = 0;
#           $EnvLang = 0;
#           splice(@ARGV,$index,1,
#               "-D${Section}::HOST=$1",
#               "-D${Section}::LANG=$2",
#               "-D${Section}::SRC=$3",
#               "-D${Section}::OBJ=$4",
#               "-D${Section}::EXE=$5" );
#           $index += 5;
#           next LOOP1;
#       }
#       elsif ($$param =~ m!^-($LANG_LIST),($SRC_LIST),($OBJ_LIST),($EXE_LIST)$!o)
#       {
#           $EnvLang = 0;
#           splice(@ARGV,$index,1,
#               "-D${Section}::LANG=$1",
#               "-D${Section}::SRC=$2",
#               "-D${Section}::OBJ=$3",
#               "-D${Section}::EXE=$4" );
#           $index += 4;
#           next LOOP1;
#       }
#       elsif ($$param =~ m!^-($SRC_LIST),($OBJ_LIST),($EXE_LIST)$!o)
#       {
#           splice(@ARGV,$index,1,
#               "-D${Section}::SRC=$1",
#               "-D${Section}::OBJ=$2",
#               "-D${Section}::EXE=$3" );
#           $index += 3;
#           next LOOP1;
#       }
#       elsif ($$param =~ m!^-($HOST_LIST),($LANG_LIST)$!o)
#       {
#           $EnvHost = 0;
#           $EnvLang = 0;
#           splice(@ARGV,$index,1,
#               "-D${Section}::HOST=$1",
#               "-D${Section}::LANG=$2" );
#           $index += 2;
#           next LOOP1;
#       }
#       elsif ($$param =~ s!^-($LANG_LIST)$!-D${Section}::LANG=$1!o) { $EnvLang = 0; }
#       elsif ($$param =~ m!^-D${Section}::LANG=(?:$LANG_LIST)$!o)   { $EnvLang = 0; }
#       elsif ($$param =~ s!^-($HOST_LIST)$!-D${Section}::HOST=$1!o) { $EnvHost = 0; }
#       elsif ($$param =~ m!^-D${Section}::HOST=(?:$HOST_LIST)$!o)   { $EnvHost = 0; }
#       $index++;
#   }
#   ###########################################################################
#   # Configuration Shortcuts Part 2:
#   unshift( @ARGV, "-D${Section}::LANG=$1" )
#       if ($EnvLang and
#           (exists  $ENV{'COMPLANG'}) and
#           (defined $ENV{'COMPLANG'}) and
#           (        $ENV{'COMPLANG'}  =~  m!^($LANG_LIST)$!o));
#   ###########################################################################
#   # Configuration Shortcuts Part 3:
#   unshift( @ARGV, "-D${Section}::HOST=$1" )
#       if ($EnvHost and
#           (exists  $ENV{'PLATFORM'}) and
#           (defined $ENV{'PLATFORM'}) and
#           (        $ENV{'PLATFORM'}  =~  m!^($HOST_LIST)$!o));
    ###########################################################################
    # Process "Define"s for configuration constants:
    $index = 0;
    LOOP2:
    while ($index < @ARGV)
    {
        $param = $ARGV[$index];
        if ($param =~ /^-D   ( [a-zA-Z][a-zA-Z0-9_-]* )
                      ( (?: :: [a-zA-Z][a-zA-Z0-9_-]* )? )
                      = ( .* ) $/x)
        {
            $sec = $1;
            $var = $2;
            $val = $3;
            if ($var eq '')
            {
                $var = $sec;
                $sec = 'DEFAULT';
            }
            else { $var = substr($var,2); }
            if ((substr($sec,-1) ne '-') && (substr($var,-1) ne '-'))
            {
                unless (defined (Config::Manager::Conf->set( $sec,$var,$val )))
                {
                    $err = Config::Manager::Conf->error();
                    $err =~ s!\s+$!!;
                    Config::Manager::Report->report
                    (
                        $TO_LOG+$TO_ERR,$LEVEL_FATAL+$USE_LEADIN,
                        __PACKAGE__ . "::BEGIN():",
                        "Couldn't set the value of configuration constant " .
                        Config::Manager::Conf::_name_($sec,$var) . ":",
                        $err
                    );
                    &abort();
                }
                Config::Manager::Report->report
                (
                    $TO_LOG,$LEVEL_INFO,
                    "OVERRIDE: " . Config::Manager::Conf::_name_($sec,$var) . " = \"${val}\""
                );
                splice(@ARGV,$index,1); # remove option from command line
                next LOOP2;
            }
        }
        $index++;
    }
}

#######################
## Public functions: ##
#######################

sub ReportErrorAndExit
{
    my($fishy) = 1;

    if (Config::Manager::Report->ret_hold() > 0)
    {
        Config::Manager::Report->report($FROM_HOLD+$TO_ERR);
        $fishy = 0;
    }
    if (@_ > 0)
    {
        Config::Manager::Report->report($TO_LOG+$TO_ERR,$LEVEL_ERROR+$USE_LEADIN,@_);
        $fishy = 0;
    }
    if ($fishy)
    {
        Config::Manager::Report->report(
            $TO_LOG+$TO_ERR,$LEVEL_ERROR+$USE_LEADIN,
            "Program abortion without error message -",
            "see log file for possible causes!" );
        Config::Manager::Report->notify(1); # print location of log file if possible
    }
    &abort();
}

sub GetList
{
    my($conf,$item,$value,$error);
    my(@list);

    if ((@_ > 0) && (ref($_[0]) eq 'Config::Manager::Conf'))
        { $conf = shift; }
    else
        { $conf = Config::Manager::Conf->default(); }
    @list = ();
    foreach $item (@_)
    {
        if (ref($item) && (ref($item) eq 'ARRAY') && (@{$item} > 0))
        {
            if (defined ($value = $conf->get( @{$item} )))
            {
                push(@list, $value);
            }
            else
            {
                $error = $conf->error();
                $error =~ s!\s+$!!;
                Config::Manager::Report->report
                (
                    @ERROR,
                    "Couldn't get the value of configuration constant " .
                    Config::Manager::Conf::_name_(@{$item}) . ":",
                    $error
                );
                return ();
            }
        }
        else
        {
            Config::Manager::Report->report
            (
                @FATAL,
        "Parameter '$item' is not a valid ARRAY reference (internal program error)"
            );
            return ();
        }
    }
    return (@list);
}

sub GetOrDie
{
    my(@list);

    if (@list = &GetList(@_)) { return (@list); }
    &ReportErrorAndExit();
}

1;

__END__

=head1 NAME

Config::Manager::Base - Basis-Funktionalitaet fuer alle Tools

=head1 SYNOPSIS

  use Config::Manager::Base
  qw(
      $SCOPE
      GetList
      GetOrDie
      ReportErrorAndExit
  );

  use Config::Manager::Base qw(:all);

  if (($host,$hostid,$hostpw) = &GetList([$ConfObj,]\@HOSTNAME,\@HOSTID,\@HOSTPW))

  ($host,$hostid,$hostpw) = &GetOrDie([$ConfObj,]\@HOSTNAME,\@HOSTID,\@HOSTPW);

  &ReportErrorAndExit("Error Message");

  &ReportErrorAndExit() unless (...);

=head1 DESCRIPTION

Dieses Modul uebernimmt die globale Initialisierung fuer ein Skript. Dies
geschieht vollautomatisch durch Perl, zur Compile-Zeit, beim Laden des Moduls
(durch die speziellen Funktionen "use" und "BEGIN()").

Das vorliegende Modul initialisiert die Module "Config::Manager::Conf" und
"Config::Manager::Report" und setzt ausserdem den Signal-Handler fuer "Ctrl-C"
auf "ignorieren". Dies ist unerlaesslich, damit das Schliessen der Log-Datei
und das Loeschen aller temporaeren Dateien bei Programmende korrekt
funktioniert.

Wichtig: Beim Aufruf aller Skripte kann zusaetzlich eine Option "C<-D>"
(fuer "Define") angegeben werden. Die genaue Syntax lautet:

  -DSECTION::VARIABLE=WERT oder
  -DVARIABLE=WERT

Falls keine Section angegeben ist, wird "DEFAULT" angenommen.

Im Unterschied zu den Konfigurationsdateien kann ein Leerstring hier
ohne Anfuehrungszeichen angegeben werden:

  -DSECTION::VARIABLE=

Optionen dieser Art werden noch vor dem eigentlichen Programmstart
ausgewertet und anschliessend aus der Kommandozeile entfernt, so dass
das ablaufende Skript sie gar nicht erst zu sehen bekommt und also im
Skript keine entsprechenden Ausnahmefaelle beruecksichtigt zu werden
brauchen.

Mit Hilfe dieses Mechanismus koennen bei einem Toolaufruf beliebige
Konfigurationsparameter gesetzt oder ueberschrieben werden. Die Option
"C<-D>" kann bei einem Toolaufruf auch mehrmals angegeben werden, um
mehr als eine Konstante zu setzen.

Zusaetzlich koennen auch noch die folgenden Abkuerzungen verwendet werden:

  Option           Abkuerzung fuer                Kommentar
 ---------    --------------------------    ----------------------

  -OS390       -DHost::Platform=OS390        Zielplattform
  -BS2000      -DHost::Platform=BS2000       Zielplattform

  -DEVL        -DHost::Environment=DEVL      Entwicklungsumgebung
  -TEST        -DHost::Environment=TEST      Testumgebung
  -INTG        -DHost::Environment=INTG      Integrationsumgebung
  -PROD        -DHost::Environment=PROD      Produktionsumgebung

Diese Optionen ueberschreiben waehrend der Programmausfuehrung die
angegebenen Konfigurationskonstanten und heben die Wirkung der
Umgebungsvariablen "PLATFORM" bzw. "HOSTENV", respektive, auf.

Die Praeferenzregeln sind dabei wie folgt:

Die niedrigste Praeferenz haben die in den Konfigurationsdateien
hinterlegten Werte der beiden Konfigurationskonstanten "Host::Platform"
und "Host::Environment".

Falls die Umgebungsvariablen "PLATFORM" oder "HOSTENV" definiert sind
und einen der gueltigen Werte "OS390" oder "BS2000" bzw. "DEVL", "TEST",
"INTG" oder "PROD" enthalten, so haben diese eine hoehere Praeferenz.

Die hoechste Praeferenz haben die auf der Kommandozeile angegebenen
Optionen, wobei es gleichgueltig ist, ob jeweils die lange Form mit
"C<-D>" oder die entsprechende Abkuerzung verwendet wird.

=head1 REQUIREMENTS

Alle Skripte muessen wie folgt aufgebaut sein:

  #!perl -w
  $running_under_some_shell = $running_under_some_shell = 0; # silence warning
  package Config::<scope>::<toolname>;
  use strict;
  use vars qw( $var1 $var2 @var3 %var4 ... ); # optional
  use Config::Manager::Base qw( ... );
  <weitere "use"-Statements>
  <eigentlicher Programmkode>

Zu Beginn des Skripts muss die folgende Zeile stehen:

  #!perl -w

Diese Zeile wird von Perl bei der Installation der vorliegenden Module und
Skripten automatisch angepasst (d.h. der Pfad des bei der Installation
verwendeten Perls wird hier automatisch eingetragen).

Die Zeile

  $running_under_some_shell = $running_under_some_shell = 0; # silence warning

direkt darunter, ganz zu Beginn des Skriptes sorgt dafuer, dass
Warnungsmeldungen (die auf unterschiedlichen Plattformen wegen der
obigen automatischen Anpassung des Pfades von Perl in der Zeile
"C<#!perl -w>" unter unterschiedlichen Umstaenden auftreten koennen)
unterdrueckt werden (deswegen auch der seltsam tautologische Aufbau
dieser Zeile).

Das Tool-Skript muss danach eine Package-Deklaration enthalten:

  package Config::<scope>::<toolname>;

Als Toolname ist der Skript-Filename ohne Extension zu verwenden (also z.B.
"putmember" fuer das Skript "putmember.pl"). Derzeit sind die vorgesehenen
Scopes beispielsweise "SPU", "Manager" oder "KM".

Der Scope "TEST" ist fuer die Regressionstests des Moduls "Config::Manager::Conf"
reserviert, der Scope "Manager" fuer alle Basis-Module (zu denen es im Normalfall
keine Skripte gibt).

Anhand der obigen Package-Deklaration wird bei Programmstart der jeweils
richtige Scope automatisch erkannt. Der Scope gibt die Gruppe von
Konfigurationsdateien an, die eingelesen werden sollen. So lassen sich
unterschiedliche Saetze von Werkzeugen bauen, die alle dieselbe
Basisfunktionalitaet benutzen, aber dennoch jeweils eigene (und von allen
anderen Saetzen von Werkzeugen vollkommen unabhaengige) Konfigurationsdateien
besitzen.

Fuer jeden Scope findet sich in der Datei "Conf.ini" eine entsprechende
Section, die den weiteren Einleseweg von Konfigurationsdateien vorgibt.
(Der "E<lt>scopeE<gt>" in der "package"-Deklaration bestimmt direkt den
Scope fuer den Aufruf der Methode "Config::Manager::Conf::init()".)

Die Package-Deklaration wird gefolgt von der Zeile

  use strict;

und ggfs. (Beispiel!) von der Zeile

  use vars qw( $var1 $var2 @var3 %var4 );

fuer globale Variablen, die nicht mit Hilfe von "my" als statisch
deklariert werden koennen (z.B. weil sie exportiert werden sollen).

Diese beiden (und andere) Compiler-Pragmas muessen immer B<NACH> einer
eventuellen "package"-Deklaration stehen, da sie sonst unwirksam sind.

Anschliessend folgt die Zeile

  use Config::Manager::Base qw(...);

die unbedingt die erste "use"-Anweisung (nach allen Compiler-Pragmas
wie "use strict" usw.) sein B<MUSS>.

Es folgen alle weiteren "use"-Statements (in beliebiger Reihenfolge)
sowie der eigentliche Programmtext.

=head1 UTILITIES

=over 4

=item *

C<($host,$hostid,$hostpw) = &GetList([$ConfObj,]\@...)>

Diese Subroutine gibt eine Liste von Konfigurationswerten zurueck, entweder
vom Default-Konfigurationsobjekt oder dem angegenen Konfigurationsobjekt.

 Parameter: $ConfObj   - Optional; Konfigurationsobjekt, so wie es
                         von dem Modul Config::Manager::Conf zurueckgegeben
                         wird. Wenn keins angegeben wird, wird das
                         Objekt von Config::Manager::Conf::default()
                         verwendet
            \@...      - Eine Liste beliebiger Laenge, die Array-Referenzen
                         enthaelt. Jedes Array besteht aus einem
                         Section/Schluessel-Paar

 Rueckgabe: Die Rueckgabe der entsprechenden Werte der Section/Schluessel-Paare
            (evaluiert in dem Modul Config::Manager::Conf) wird in derselben
            Reihenfolge wie die uebergebenen Parameter zurueckgegeben
            Es wird eine leere Liste zurueckgegeben, sofern auch nur ein
            einziger Wert nicht gefunden werden kann. Eine entsprechende
            Fehlermeldung findet sich dann im Logfile und auf Halde.

 Beispiel:

    my($a, $b) = &GetList( [qw(SPECIAL WHOAMI)],
                           [qw(Host HOST-ID)]);

=item *

C<($host,$hostid,$hostpw) = &GetOrDie([$ConfObj,]\@...)>

Gleiche Syntax und Semantik wie GetList(), jedoch mit dem Unterschied, dass
wenn auch nur ein Wert nicht gefunden werden kann, der Programmlauf mit einer
entsprechenden Fehlermeldung beendet wird.

=item *

C<&ReportErrorAndExit("Error Message");>

Wenn Meldungen zuvor auf Halde gelegt worden sind, so schreibt diese Funktion
die Meldung vor Abbruch auf den Bildschirm (STDERR).

Danach schreibt die Funktion eine Fehlermeldung (sofern uebergeben) in das
Log-File und auf den Bildschirm (STDERR) und beendet danach die
Programmausfuehrung.

Als Parameter erwartet die Funktion optional eine Liste von Strings. Diese
werden Zeilenweise zuerst in das Log-File und dann auf STDERR geschrieben.
Wird kein Parameter uebergeben, so werden keine zusaetzlichen Fehlermeldungen
(zusaetzlich zu den Meldungen von der Halde) auf dem Bildschirm ausgegeben.

Wenn keine Fehlermeldungen verfuegbar sind (weder auf Halde noch als Parameter
uebergebene), so wird eine generische Fehlermeldung auf dem Bildschirm (STDERR)
ausgegeben. Dem Modul "Config::Manager::Report" wird in diesem Fall mitgeteilt,
dass es den Ort des Logfiles ausgeben soll (STDOUT), da das Logfile ggfs.
noch Zusatzinformation enthaelt, die den aufgetretenen Fehler erkennen lassen.

Der Exit-Code des Programms wird auf 1 gesetzt.

=back

=head1 SEE ALSO

Config::Manager(3),
Config::Manager::Conf(3),
Config::Manager::File(3),
Config::Manager::PUser(3),
Config::Manager::Report(3),
Config::Manager::SendMail(3),
Config::Manager::User(3).

=head1 VERSION

This man page documents "Config::Manager::Base" version 1.7.

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

