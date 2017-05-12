
###############################################################################
##                                                                           ##
##    Copyright (c) 2003 by Steffen Beyer & Gerhard Albers.                  ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

package Config::Manager::Report;

use strict;
use vars qw( @ISA @EXPORT @ALL @AUX @EXPORT_OK %EXPORT_TAGS $VERSION %SIG
             $SHOW_ALL $USE_LEADIN $STACKTRACE
             $LEVEL_TRACE $LEVEL_INFO $LEVEL_WARN $LEVEL_ERROR $LEVEL_FATAL
             $FROM_HOLD $TO_HLD $TO_OUT $TO_ERR $TO_LOG
             @TRACE @INFO @WARN @ERROR @FATAL );

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw();

@ALL = qw( $SHOW_ALL $USE_LEADIN $STACKTRACE
           $LEVEL_TRACE $LEVEL_INFO $LEVEL_WARN $LEVEL_ERROR $LEVEL_FATAL
           $FROM_HOLD $TO_HLD $TO_OUT $TO_ERR $TO_LOG
           @TRACE @INFO @WARN @ERROR @FATAL
           end abort );

@AUX = qw( Normalize MakeDir );

@EXPORT_OK = (@ALL,@AUX);

%EXPORT_TAGS =
(
    all => [@ALL],
    aux => [@AUX],
    ALL => [@EXPORT_OK]
);

$VERSION = '1.7';

use Config::Manager::Conf qw( whoami );
use Symbol;

#######################
## Public constants: ##
#######################

$TO_HLD      = 0x01;
$TO_OUT      = 0x02;
$TO_ERR      = 0x04;
$TO_LOG      = 0x08;
$FROM_HOLD   = 0x10;

$USE_LEADIN  = 0x01;
$STACKTRACE  = 0x02;

$LEVEL_TRACE = 0x00;
$LEVEL_INFO  = 0x04;
$LEVEL_WARN  = 0x08;
$LEVEL_ERROR = 0x0C;
$LEVEL_FATAL = 0x10;

$SHOW_ALL    = 0x00;

@TRACE = ( $TO_LOG          , $LEVEL_TRACE + $USE_LEADIN );
@INFO  = ( $TO_LOG + $TO_OUT, $LEVEL_INFO  + $USE_LEADIN );
@WARN  = ( $TO_LOG + $TO_ERR, $LEVEL_WARN  + $USE_LEADIN );
@ERROR = ( $TO_LOG + $TO_HLD, $LEVEL_ERROR + $USE_LEADIN );
@FATAL = ( $TO_LOG + $TO_HLD, $LEVEL_FATAL + $USE_LEADIN );

#######################################
## Internal configuration constants: ##
#######################################

my $LOGSUFFIX = 'log';

my @LOGFILEPATH  = ('DEFAULT', 'LOGFILEPATH');
my @FULLNAME     = ('Person',  'Name');

my $RULER   = '_' x 78 . "\n";
my $HEADER  = 'STARTED';
my $CMDLINE = 'COMMAND';
my $LOGFILE = 'LOGFILE';
my $FOOTER  = 'ENDED';

my @LEADIN =
(
    [ 'TRACE',  'HINT',  'WARNING',  'ERROR',  'EXCEPTION'  ], # Singular
    [ 'TRACES', 'HINTS', 'WARNINGS', 'ERRORS', 'EXCEPTIONS' ]  # Plural
);

my $LINE0 = 'line on hold';
my $LINE1 = 'lines on hold';

my $STAT_MIN = 1;
my $STAT_MAX = 4;

my $STARTDEPTH = 0;
my $MAXEVALLEN = 0; # 0 = no limit

#######################
## Global variables: ##
#######################

my $Singleton = 0;

my @Inventory = ();

my $User = (&whoami())[0] || '';

my $Count = 0;

########################
## Private functions: ##
########################

sub _warn_
{
    my($text) = @_;
    $text =~ s!\s+$!!;
    Config::Manager::Report->report
    (
        $TO_LOG+$TO_ERR, $LEVEL_WARN+$USE_LEADIN, $text
    )
}

sub _die_
{
    my($text) = @_;
    $text =~ s!\s+$!!;
    Config::Manager::Report->report
    (
        $TO_LOG+$TO_ERR, $LEVEL_FATAL+$USE_LEADIN, $text
    )
    if (defined $^S); # no logging during startup
}

sub _adjust # code "stolen" from Carp.pm:
{
    my($pack,$file,$line,$sub,$hargs,$warray,$eval,$require) = @_;

    if (defined $eval)
    {
        if ($require)
        {
            $sub = "require $eval";
        }
        else
        {
            if ($MAXEVALLEN && length($eval) > $MAXEVALLEN)
            {
                substr($eval,$MAXEVALLEN) = '...';
            }
            $eval =~ s!([\\\'])!\\$1!g;
            $sub = "eval '$eval'";
        }
    }
    elsif ($sub eq '(eval)')
    {
        $sub = 'eval {...}';
    }
    return $sub;
}

sub _ShortTime
{
    my($s,$m,$h,$dd,$mm,$yy) = localtime(time);
    $yy %= 100;
    $mm++;
    return sprintf("%02d%02d%02d-%02d%02d%02d", $yy,$mm,$dd,$h,$m,$s);
}

sub _LongTime
{
    my($s,$m,$h,$dd,$mm,$yy) = localtime(time);
    $yy += 1900;
    $mm = (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec))[$mm];
    return sprintf("%02d-%s-%d %02d:%02d:%02d", $dd,$mm,$yy,$h,$m,$s);
}

sub _which
{
    my($self) = shift;

    if (ref $self) { return $self; }
    else
    {
        unless (ref $Singleton)
        {
            if (ref ($Singleton = Config::Manager::Report->new(@_)))
            {
                ${$Singleton}{'singleton'} = 1;
                $SIG{'__WARN__'} = \&_warn_;
                $SIG{'__DIE__'}  = \&_die_;
            }
        }
        return $Singleton;
    }
}

sub DESTROY
{
    my($self,$close) = @_;
    my($text,$item,$count,$file,$handle);

    return unless (ref $self and keys %{$self});
    $text = "\n" . $RULER . "\n $FOOTER: " . _LongTime();
    for ( $item = $STAT_MIN; $item <= $STAT_MAX; $item++ )
    {
        if ((defined ($count = ${${$self}{'stat'}}[$item])) && ($count > 0))
        {
            $text .= " - $count ";
            if ($count == 1) { $text .= ucfirst(lc($LEADIN[0][$item])); }
            else             { $text .= ucfirst(lc($LEADIN[1][$item])); }
        }
    }
    if (($count = scalar(@{${$self}{'hold'}})) > 0)
    {
        $text .= " - $count ";
        if ($count == 1) { $text .= $LINE0; }
        else             { $text .= $LINE1; }
    }
    $text .= "\n" . $RULER;
    $file   = ${$self}{'file'};
    $handle = ${$self}{'hand'};
    ${$self}{'level'} = $SHOW_ALL;
    if (${$self}{'flag'})
    {
        $self->report($TO_LOG+$TO_OUT,$LEVEL_INFO,"$LOGFILE = '$file'");
    }
    $self->report($TO_LOG,$LEVEL_INFO,$text);
    # Enable creation of new singleton object if necessary:
    $Singleton = 0 if (${$self}{'singleton'});
    # Prevent closing it again at global destruction time:
    %{$self} = ();
    $text = '';
    unless (close($handle))
    {
        if ($close)
        {
            $text = __PACKAGE__ . "::close(): Can't close logfile '$file': $!";
        }
        else
        {
            $text = __PACKAGE__ . "::DESTROY(): Can't close logfile '$file': $!";
            print STDERR "$text\n";
        }
    }
    return $text;
}

END { &end(); }

#######################
## Public functions: ##
#######################

sub end
{
    $SIG{'__WARN__'} = 'DEFAULT';
    $SIG{'__DIE__'}  = 'DEFAULT';
    while (@Inventory)
    {
        pop(@Inventory)->DESTROY();
    }
}

sub abort
{
    &end();
    print STDERR @_ if @_;
    print STDERR "<Program aborted>\n";
    exit 1;
}

sub Normalize
{
    my $dir = defined $_[0] ? $_[0] : '';
    my $drv = '';

    if    ($dir =~ s!^([a-zA-Z]:)!!) { $drv = $1;  }
    elsif ($dir !~ m!^[/\\]!)        { $drv = '.'; }
    $dir = "/$dir/";
    $dir =~ s!\\!/!g;
    $dir =~ s!//+!/!g;
    while ($dir =~ s!/(?:\./)+!/!g) {};
    while ($dir =~ s,/(?!\.\./)[^/]+/\.\./,/,g) {};
    $dir =~ s!^/(?:\.\./)+!/!g;
    $dir =~ s!^/!!;
    $dir =~ s!/$!!;

    return wantarray ? ($drv,$dir) : "$drv/$dir";
}

sub MakeDir
{
    my($drv,$dir) = Normalize($_[0]);
    my(@dir);
    local($!);

    return '' if (-d "$drv/$dir");
    @dir = split(/\//, $dir);
    $dir = $drv;
    while (@dir)
    {
        $dir .= '/' . shift(@dir);
        unless (-d $dir)
        {
            unless (mkdir($dir,0777))
            {
                return "Can't mkdir '$dir': $!";
            }
        }
    }
    return '';
}

#####################
## Public methods: ##
#####################

sub singleton
{
    shift;                        # discard class name
    return _which($Singleton,@_); # trigger creation if necessary
}

sub new
{
    my($class) = shift || __PACKAGE__;
    my($tool)  = shift || '';
    my($path)  = shift || '';
    my($file)  = shift || '';
    my($err,$name,$user,$handle,$self,$time,$text);
    local($_); # because of map()

    $class = ref($class) || $class;
    $name = Config::Manager::Conf->get(@FULLNAME) || '';
    if ($tool =~ /^\s*$/)
    {
        $tool = $0;
        $tool =~ s!^.*[/\\]!!;
        $tool =~ s!\.+[^\.]*$!!;
    }
    if ($path =~ /^\s*$/)
    {
        unless (defined ($path = Config::Manager::Conf->get(@LOGFILEPATH)))
        {
            $err = Config::Manager::Conf->error();
            $err =~ s!\s+$!!;
            return(__PACKAGE__ .
                "::new(): Can't find log directory in configuration data: $err");
        }
    }
    $file =~ s!^.*[/\\]!!;
    if ($file =~ /^\s*$/)
    {
        $user = $User || $name || 'unknown';
        $user =~ s!\s+!!g;
        $path .= "/$tool/$user";
        $file = join('-', $tool, $user, _ShortTime(), $$, ++$Count) . '.' . $LOGSUFFIX;
    }
    if ($err = MakeDir($path))
    {
        return(__PACKAGE__ .
            "::new(): Can't create log directory '$path': $err");
    }
    $file = Normalize("$path/$file");
    $handle = gensym();
    unless (open($handle, ">$file"))
    {
        return(__PACKAGE__ .
            "::new(): Can't open logfile '$file': $!");
    }
    select( ( select($handle), $| = 1 )[0] );
    $self = { };
    bless($self, $class);
#   ${$self}{'user'} = $User;
#   ${$self}{'name'} = $name;
#   ${$self}{'tool'} = $tool;
#   ${$self}{'path'} = $path;
    ${$self}{'file'} = $file;   # logfile name
    ${$self}{'hand'} = $handle; # logfile handle
    ${$self}{'hold'} = [ ];     # for putting lines on hold
    ${$self}{'stat'} = [ ];     # for statistics
    ${$self}{'flag'} = 0;       # for automatic dump of logfile name
    ${$self}{'level'} = $SHOW_ALL;
    # (for suppressing messages below the indicated level)
    $user = $User;
    if (($user !~ /^\s*$/) && ($name !~ /^\s*$/))
    {
        $user = "$name ($user)";
    }
    else
    {
        if ($user =~ /^\s*$/)
        {
            if ($name =~ /^\s*$/) { $user = "<Unknown User>"; }
            else                  { $user = $name; }
        }
    }
    $time = _LongTime();
    $text =
        $RULER .
        "\n $HEADER: $tool - $time - $user\n" .
        $RULER .
        "\n $CMDLINE: " .
        join(' ', map("'$_'", $^X, $0, @ARGV)) .
        "\n";
    $self->report($TO_LOG,$LEVEL_INFO,$text); # increments stat counters
    ${$self}{'stat'} = [ ];                   # reset stat counters to zero
    push( @Inventory, $self );
    return $self;
}

sub close
{
    my($self) = _which(shift);

    return __PACKAGE__ . "::close(): invalid logfile object!"
        unless (ref $self and keys %{$self});
    return $self->DESTROY(1);
}

sub report
{
    my($self)    = _which(shift);
    my($command) = shift || 0;
    my($level)   = shift || 0;
    my($text,$leadin,$indent,$item,$depth,$sub,$file,$handle);
    my(@stack,@trace);

    return unless (ref $self and keys %{$self});
    if ($command & $FROM_HOLD)
    {
        return if ($command == $FROM_HOLD + $TO_HLD);
        return unless (@{${$self}{'hold'}} > 0);
        $text = ${$self}{'hold'};
    }
    else
    {
        return if ($level < ${$self}{'level'});
        $leadin = '';
        $indent = '';
        if ($level & $USE_LEADIN)
        {
            $leadin = $LEADIN[0][$level >> 2] . ': ';
            $indent = ' ' x length($leadin);
        }
        $text = [ ];
        foreach $item (@_)
        {
            push( @{$text}, split(/\n/, $item, -1) );
        }
        foreach $item (@{$text})
        {
            $item = $leadin . $item;
            $item =~ s!\s+$!!;
            $item .= "\n";
            $leadin = $indent;
        }
        @trace = ();
        if ($level & $STACKTRACE)
        {
            $depth = $STARTDEPTH;
            while (@stack = caller($depth++))
            {
                $sub = _adjust(@stack);
                push
                (
                    @trace,
                    $indent . "in $sub\n",
                    $indent . "called at $stack[1] line $stack[2]\n"
                );
            }
            # Comment out next line if stack traces in logfile ONLY:
####        push( @{$text}, @trace );
        }
    }
    if ($command & $TO_LOG)
    {
        $file   = ${$self}{'file'};
        $handle = ${$self}{'hand'};
####    unless (print $handle join('', @{$text}))         # use this if push above is enabled
        unless (print $handle join('', @{$text}, @trace)) # use this if push above is disabled
        {
            unshift( @{$text}, __PACKAGE__ . "::report(): Can't print logfile '$file': $!\n" );
            $command |= $TO_HLD;
            $command |= $TO_ERR;
        }
    }
    if ($command & $TO_ERR)
    {
        unless (print STDERR join('', @{$text}))
        {
            $command |= $TO_OUT;
        }
    }
    if ($command & $TO_OUT)
    {
        unless (print STDOUT join('', @{$text}))
        {
            $command |= $TO_HLD;
        }
    }
    if ($command & $TO_HLD)
    {
        unless ($command & $FROM_HOLD)
        {
####        push( @{${$self}{'hold'}}, @{$text} );         # use this if push above is enabled
            push( @{${$self}{'hold'}}, @{$text}, @trace ); # use this if push above is disabled
        }
    }
    if ($command & $FROM_HOLD)
    {
        ${$self}{'hold'} = [ ] unless ($command & $TO_HLD);
    }
    else
    {
        ${${$self}{'stat'}}[$level >> 2]++;
    }
}

sub trace
{
    my($self) = _which(shift);
    my($first,$depth,$sub,$item);
    my(@stack,@trace,@args);

    return unless (ref $self and keys %{$self});
    # Do nothing if trace unwanted:
    return if ($LEVEL_TRACE < ${$self}{'level'});
    $first = 1;
    $depth = 1;
    @trace = (); # code "borrowed" from Carp.pm:
    while ( do {{ package DB; @stack = caller($depth++) }} )
    {
        $sub = _adjust(@stack);
        if ($first)
        {
            if ($stack[4]) # $hargs
            {
                @args = @DB::args;
                foreach $item (@args)
                {
                    if (defined $item)
                    {
                        $item = "$item";
                        $item =~ s!([\\\'])!\\$1!g;
                        $item = "'$item'"
                            unless ($item =~ /^-?(?:[1-9]\d*|0)(?:\.\d+)?$/);
#                       $item =~ s!([\x80-\xFF])!'M-'.chr(ord($1)&0x7F)!eg;
                        $item =~ s!([\x00-\x1F\x7F])!'^'.chr(ord($1)^0x40)!eg;
                    }
                    else { $item = "undef"; }
                }
                $sub .= '(' . join(',', @args) . ')';
            }
            else { $sub .= '()'; }
        }
        else { $sub = "in $sub"; }
        push
        (
            @trace,
            $sub,
            "called at $stack[1] line $stack[2]"
        );
        $first = 0;
    }
    $self->report(@TRACE,@trace);
}

sub level
{
    my($self) = _which(shift);
    my($level);

    return undef unless (ref $self and keys %{$self});
    $level = ${$self}{'level'};
    if (@_ > 0)
    {
        ${$self}{'level'} = $_[0] + 0;
    }
    return $level;
}

sub logfile
{
    my($self) = _which(shift);

    return undef unless (ref $self and keys %{$self});
    return ${$self}{'file'};
}

sub notify # set flag for notifying user at exit about where logfile lies
{
    my($self) = _which(shift);
    my($flag);

    return undef unless (ref $self and keys %{$self});
    $flag = ${$self}{'flag'};
    if (@_ > 0)
    {
        ${$self}{'flag'} = ($_[0] ? 1 : 0);
    }
    return $flag;
}

sub ret_hold
{
    my($self) = _which(shift);

    if (defined wantarray && wantarray)
    {
        return () unless (ref $self and keys %{$self});
        return (@{${$self}{'hold'}});
    }
    else
    {
        return undef unless (ref $self and keys %{$self});
        return scalar(@{${$self}{'hold'}});
    }
}

sub clr_hold
{
    my($self) = _which(shift);

    return unless (ref $self and keys %{$self});
    ${$self}{'hold'} = [ ];
}

1;

__END__

=head1 NAME

Config::Manager::Report - Error Reporting and Logging Module

=head1 SYNOPSIS

  use Config::Manager::Report qw(:all);

  $logobject = Config::Manager::Report->new([TOOL[,PATH[,FILE]]]);
  $newlogobject = $logobject->new([TOOL[,PATH[,FILE]]]);

  $default_logobject = Config::Manager::Report->singleton();

  $logobject->report($CMD,$LEVEL,@text);
  Config::Manager::Report->report($CMD,$LEVEL,@text);

    Fuer ($CMD,$LEVEL) sollte stets eine der folgenden
    (oeffentlichen) Konstanten verwendet werden:

        @TRACE
        @INFO
        @WARN
        @ERROR
        @FATAL

    Beispiel:
        Config::Manager::Report->report(@ERROR,@text);

  $logobject->trace();
  Config::Manager::Report->trace();

  $logfile = $logobject->logfile();
  $logfile = Config::Manager::Report->logfile();

  [ $oldlevel = ] $logobject->level([NEWLEVEL]);
  [ $oldlevel = ] Config::Manager::Report->level([NEWLEVEL]);

  [ $oldflag = ] $logobject->notify([NEWFLAG]);
  [ $oldflag = ] Config::Manager::Report->notify([NEWFLAG]);

  $lines = $logobject->ret_hold();
  @text  = $logobject->ret_hold();
  $lines = Config::Manager::Report->ret_hold();
  @text  = Config::Manager::Report->ret_hold();

  $logobject->clr_hold();
  Config::Manager::Report->clr_hold();

=head1 DESCRIPTION

Das Logging ist so realisiert, dass die Ausgabe der Meldungen auf den
verschiedenen Ausgabekanaelen einzeln (unabhaengig voneinander) gesteuert
werden kann. Es gibt die Ausgabekanaele STDOUT, STDERR, Logdatei und Halde.

STDOUT und STDERR sind die ueblichen Standard-Ausgabekanaele. Auf Wunsch
koennen Meldungen aber auch in das Logfile geschrieben werden. Auf der
Halde koennen Meldungen gekellert werden. Die Meldungen werden dann erst
auf Anforderung auf dem Bildschirm ausgegeben.

Bei Verwendung der Funktion "ReportErrorAndExit()" aus dem Modul
"Config::Manager::Base.pm" wird vor Beendigung des Programms die Halde
auf STDERR ausgegeben, falls sie nicht leer ist.

Bei Verwendung der Standard-Konstanten @TRACE @INFO @WARN @ERROR @FATAL
werden alle Meldungen immer auch in die Logdatei geschrieben, damit keine
(moeglicherweise wichtige!) Information verlorengehen kann.

Das sollte man auch dann immer tun, wenn man diese Standard-Konstanten nicht
verwendet.

=over 4

=item *

C<private &_warn_($text,...)>

Dieser Signal-Handler gibt alle Warnungen weiter an das Modul
"Config::Manager::Report.pm", indem er die Methode "report()" aufruft. Trailing
Whitespace im Parameter wird eliminiert - es geht hier vor allem um moegliche
Newlines am Zeilenende, die entfernt werden muessen.

 Parameter: $text - Text der Warnungsmeldung
            ...   - weitere Parameter, die Perl liefert

 Rueckgabe: -

Durch diesen Handler wird sichergestellt, dass auch Warnungen in die Logdatei
geschrieben werden, wo sie zur Aufklaerung von Fehlern nuetzlich sein koennen.

Dies ist in erster Linie fuer externe Module gedacht, die Warnungsmeldungen
absetzen, und nicht fuer Tools der vorliegenden SPU. Letztere sollten statt
"warn" immer die Methode "report()" mit dem Parameter "C<@WARN>" verwenden.

Dieser Signal-Handler wird jedoch nur dann aktiviert, wenn das
Singleton-Log-Objekt angelegt wird (dies geschieht durch alle Aufrufe von
Objekt-Methoden, die statt C<$objekt-E<gt>methode();> die Form
C<Config::Manager::Report-E<gt>methode();> verwenden).

=item *

C<private &_die_($text,...)>

Dieser Signal-Handler gibt alle Ausnahmen weiter an das Modul
"Config::Manager::Report.pm", indem er die Methode "report()" aufruft,
vorausgesetzt das "die" trat nicht waehrend der Compilierung (beim
Programmstart) auf. Trailing Whitespace im Parameter wird eliminiert -
es geht hier vor allem um moegliche Newlines am Zeilenende, die entfernt
werden muessen.

 Parameter: $text - Text der Fehlermeldung
            ...   - weitere Parameter, die Perl liefert

 Rueckgabe: -

Durch diesen Handler wird ermoeglicht, dass man statt "ReportErrorAndExit()"
theoretisch auch einfach nur "die" verwenden kann. Im Unterschied zu ersterem
wird mit "die" aber die Halde nicht mit ausgegeben. Man sollte daher "die"
lieber nicht benutzen. Dieses Feature ist vielmehr dafuer gedacht, dass auf
diese Art und Weise auch "die"s in Modulen abgefangen werden, die nicht zur
SPU gehoeren aber von dieser verwendet werden (Perl Standard-Module, externe
Module wie Net::FTP, usw.), damit auch deren Fehlermeldungen in der Logdatei
landen, wo sie bei der Fehlersuche hilfreich sein koennen.

Dieser Signal-Handler wird jedoch nur dann aktiviert, wenn das
Singleton-Log-Objekt angelegt wird (dies geschieht durch alle Aufrufe von
Objekt-Methoden, die statt C<$objekt-E<gt>methode();> die Form
C<Config::Manager::Report-E<gt>methode();> verwenden).

=item *

C<private &_adjust($pack,$file,$line,$sub,$hargs,$warray,$eval,$require)>

Diese Routine bereitet die Parameter auf, die von der System-Funktion
"caller()" zurueckgeliefert werden.

Die Routine ist aus dem Standard-Modul "Carp.pm" "geklaut"; sie sorgt dafuer,
dass im Stacktrace hinterher die "richtigen" Subroutine-Namen und -Parameter
ausgegeben werden.

 Parameter: $pack    - Package-Name des Aufrufers
            $file    - Dateiname des Aufrufers
            $line    - Zeilennummer des Aufrufers
            $sub     - Name der aufgerufenen Routine
            $hargs   - wahr falls Aufrufparameter vorhanden
            $warray  - wahr falls in List-Kontext aufgerufen
            $eval    - wahr falls eval-Aufruf
            $require - wahr falls require-Aufruf

 Rueckgabe:
            $sub     - aufbereiteter Name der aufgerufenen Routine

=item *

C<private &_ShortTime()>

 Rueckgabe: Die aktuelle Zeit im Format MMTT-HHMMSS

=item *

C<private &_LongTime()>

 Rueckgabe: Die aktuelle Zeit im Format TT.MM. HH:MM:SS

=item *

C<private &_which($self[,...])>

 Parameter: $self - Referenz auf Log-Objekt oder Klassenname
            ...   - weitere (optionale) Parameter, die ggfs. an
                    "new()" weitergereicht werden (siehe dort)

 Rueckgabe: $self, falls $self eine Objekt-Referenz ist,
            oder eine Referenz auf das Singleton-Objekt sonst

Falls der Aufrufparameter eine Referenz ist, wird diese unveraendert
zurueckgegeben.

Falls der Aufrufparameter ein Skalar ist (z.B. durch den Aufruf als
Klassenmethode), wird eine Referenz auf das Default-Log-Objekt (das
sogenannte "Singleton"-Objekt) dieser Klasse zurueckgeliefert.

Falls das Singleton-Objekt noch nicht existiert, wird es durch den Aufruf
dieser Routine erzeugt. In diesem Falle werden alle weiteren Aufrufparameter
an den Konstruktor ("new()") durchgereicht (siehe dort).

Man kann diese Routine uebrigens sowohl als Funktion als auch als Methode
verwenden; der Aufruf als Funktion ist jedoch etwas schneller.

=item *

C<private $self-E<gt>DESTROY([$close])>

In dieser Methode werden Aktionen definiert, die beim "Tod" eines Log-Objekts
(typischerweise bei Beendigung des Programms, im Rahmen der Global
Destruction) noch durchgefuehrt werden muessen. Dazu gehoeren:

  - Auf (vorherige) Anforderung Ausgabe des Logfilenamens auf dem Bildschirm
  - Den Footer der Logdatei schreiben
  - Logdatei schliessen

 Parameter: $self  - Referenz auf das zu zerstoerende Objekt
            $close - Optional; ein "true"-Wert, falls von
                     "close()" aufgerufen

 Rueckgabe: Text der Fehlermeldung falls close(FILEHANDLE)
            nicht erfolgreich, Leerstring falls alles OK

Diese Methode wird implizit von Perl aufgerufen und sollte nicht
explizit aufgerufen werden.

Statt dessen sollte bei Bedarf die Methode "close()" verwendet
werden (die ihrerseits "DESTROY()" aufruft).

=item *

C<reserved &end()>

Diese Routine setzt die Signal-Handler fuer "warn" und "die" wieder auf
"DEFAULT" zurueck, die moeglicherweise (falls das Singleton-Log-Objekt
benutzt wurde) auf die Routinen "&_warn_()" und "&_die_()" eingestellt
waren.

Dies ist notwendig, um Endlos-Rekursionen im Zusammenhang mit "DESTROY()"
zu vermeiden.

Ausserdem wird hier die Aufloesung aller Log-Objekte (d.h. der Aufruf
von "DESTROY()" fuer alle diese Objekte) getriggert, d.h. die Log-
Objekte werden geschlossen (zuvor wird noch ein Footer in die Datei
geschrieben).

Ohne diese explizite Triggerung der Zerstoerung der Log-Objekte wuerde
es zu Fehlern (Footer nicht geschrieben, Datei nicht ordnungsgemaess
geschlossen) bei der Global Destruction kommen.

Die Zerstoerung aller Log-Objekte erfolgt in umgekehrter Reihenfolge
ihrer Erzeugung.

 Parameter: -

 Rueckgabe: -

Diese Funktion wird implizit von Perl aufgerufen (durch die Funktion
"END") und sollte im Normalfall nicht explizit verwendet werden.

=item *

C<reserved &abort()>

Diese Funktion bricht die Programmausfuehrung ab.

Zuvor wird die Funktion "&end()" aufgerufen, um die Signal-Handler fuer
"die" und "warn" zurueckzusetzen und ggfs. alle Log-Dateien zu schliessen.

Anschliessend werden die als Parameter mitgegebenen Zeilen Text auf STDERR
ausgegeben, gefolgt von der Zeile "<Program aborted>"; zuletzt wird dann
die Ausfuehrung des Programms beendet.

 Parameter: Beliebig viele Zeilen Fehlermeldung (oder keine)
            (MIT Newlines ("\n") wo gewuenscht!)

 Rueckgabe: -

Der Exit-Code des Programms wird auf 1 gesetzt.

Diese Funktion sollte im Normalfall B<NICHT> verwendet werden (statt dessen
sollte die Funktion "ReportErrorAndExit()" aus dem Modul "Config::Manager::Base.pm"
gerufen werden, die ihrerseits auf der "abort()"-Funktion beruht).

=item *

C<public Config::Manager::Report-E<gt>singleton([...])>

Diese Methode gibt eine Referenz auf das Singleton-Objekt zurueck.

Das Singleton-Objekt ist die Default-Logdatei. Man ist als Benutzer des
Report-Moduls jedoch nicht gezwungen, dieses Singleton-Objekt zu verwenden (es
wird nur dann automatisch erzeugt, wenn man sich implizit darauf bezieht).
Vielmehr kann man mit diesem Modul beliebig viele Log-Objekte (denen jeweils
eine separate Logdatei und eine eigene Halde zugeordnet sind) erzeugen und
benutzen.

Alle Methodenaufrufe der Form "C<Config::Manager::Report-E<gt>methode();>" beziehen
sich auf das Singleton-Objekt und legen es automatisch an, falls es noch nicht
existiert (genauer gesagt alle Objekt-Methoden, in denen auf den Parameter
"C<$self>" nur ueber die Funktion "C<&_which()>" zugegriffen wird).

 Parameter: ...   - optionale Parameter, die ggfs. an "new()"
                    weitergereicht werden (siehe dort)

 Rueckgabe: Gibt eine Referenz auf das Singleton-Objekt zurueck
            oder einen String mit einer Fehlermeldung, falls das
            Singleton-Objekt nicht erzeugt werden konnte

Wenn das Singleton-Objekt noch nicht existiert, wird es durch diesen Aufruf
erzeugt. In diesem Falle werden alle optionalen Aufrufparameter an den
Konstruktor ("new()") durchgereicht, d.h. man kann ggfs. den Pfad und
den Namen der Log-Datei beeinflussen.

"C<Config::Manager::Report-E<gt>methode();>" ist dabei dasselbe wie
"C<Config::Manager::Report-E<gt>singleton()-E<gt>methode();>" oder wie
"C<$Singleton = Config::Manager::Report-E<gt>singleton();>" und
"C<$Singleton-E<gt>methode();>".

Es sollte jedoch immer die erste dieser Formen
("C<Config::Manager::Report-E<gt>methode();>") verwendet werden. Ausserdem darf der
Rueckgabewert dieser Methode nicht dauerhaft im Programm gespeichert werden,
da es sonst zu Fehlern kommen kann, wenn die Log-Datei inzwischen woanders
geschlossen wurde.

Es gibt im Grunde nur eine einzige sinnvolle Verwendung fuer diese Methode,
naemlich, um die Erzeugung des Singleton-Objekts auszuloesen (wie das
beispielsweise in "Config::Manager::Base.pm" geschieht), und um ggfs.
den Namen und Pfad dieser Logdatei festzulegen.

=item *

C<public $class-E<gt>new([$tool[,$path[,$file]]])>

Bei Aufruf - in der Regel bei Toolstart - wird das Logfile angelegt.

Falls der Name des aufrufenden Tools (= wird Teil des ggfs. automatisch
bestimmten Pfades und Dateinamens) nicht angegeben ist, wird er automatisch
bestimmt.

Falls das Logverzeichnis nicht angegeben ist, wird der Pfad automatisch
aus der Konfiguration geholt (Section [DEFAULT], Konstante 'LOGFILEPATH').

Falls der Pfad noch nicht vorhanden ist, wird er automatisch angelegt.

Falls der Name der Logdatei nicht angegeben ist, wird hierfuer automatisch
ein (moeglichst sinnvoller) Default-Wert bestimmt.

Danach wird der Header des Logfiles geschrieben. Dieser enthaelt z.B. Uhrzeit,
Namen des Aufrufers und Kommandoaufruf samt Optionen.

 Parameter: $class - Name der Klasse oder ein Objekt derselben Klasse
            $tool  - Optional; wird kein Toolname uebergeben, so wird er
                     in der Funktion ermittelt
            $path  - Optional; wird kein Logpfad angegeben, so wird er aus
                     der Konfiguration ausgelesen
            $file  - Optional; wird kein Dateiname angegeben, wird
                     automatisch einer vergeben

 Rueckgabe: Eine Referenz auf das neue erzeugte Objekt, falls das
            Oeffnen der Log-Datei und das Schreiben des Headers
            in diese Log-Datei geklappt hat, ansonsten (bei einem
            Fehler) ein String mit der entsprechenden Fehlermeldung

Diese Methode muss (d.h. darf) nicht explizit aufgerufen werden, falls man nur
die Default-Logdatei ("Singleton-Log-Objekt") verwenden will (in diesem Fall
ist statt dessen die Methode "singleton()" zu verwenden).

=item *

C<public $self-E<gt>close()>

Diese Methode schliesst die Log-Datei, die zu dem angegebenen Objekt
gehoert, und schreibt zuvor noch einen Footer (mit Datum, Uhrzeit
sowie einer kleinen Ausgabestatistik) in die Datei.

Bei einem Fehler wird ein String mit der entsprechenden Fehlermeldung
zurueckgeliefert, ansonsten der leere String.

 Parameter: -

 Rueckgabe: Ein Leerstring bei Erfolg, ein String mit der
            entsprechenden Fehlermeldung bei einem Fehler

Diese Methode kann auch fuer das Singleton-Objekt als Klassenmethode
aufgerufen werden:

    Config::Manager::Report->close();

In diesem Fall wird das Singleton-Objekt geloescht, so dass
ein erneuter Aufruf von Klassenmethoden aus dieser Klasse
automatisch ein neues Singleton-Objekt erzeugt (und eine
neue Log-Datei mit neuem Namen).

=item *

C<public $self-E<gt>report($command[,$level[,@zeilen]])>

Die Funktion realisiert das bereits im allgemeinen Teil beschriebene
Loggingkonzept. Meldungen werden auf Anforderung entsprechend eingerueckt.

 Besonderheit: Der Stacktrace wird nie auf dem Bildschirm ausgegeben,
               sondern nur in das Logfile. Damit sind fuer den Benutzer
               die Fehlermeldungen uebersichtlicher.

 Parameter: $self     - Referenz auf Log-Objekt oder Klassenname
            (Es wird das Singleton-Objekt verwendet, falls die Methode
            als Klassen- und nicht als Objekt-Methode aufgerufen wurde)
            $command  - Angabe darueber, wohin die Meldung geleitet
                        werden soll. Moegliche Werte:
                            $TO_HLD $TO_OUT $TO_ERR $TO_LOG
                            $FROM_HOLD $USE_LEADIN $STACKTRACE
                        Diese Werte koennen beliebig durch Addition
                        oder Bit-Or ("|") kombiniert werden.
            $level    - Auf welcher Stufe ist die Meldung einzuordnen:
                            $LEVEL_TRACE $LEVEL_INFO $LEVEL_WARN
                            $LEVEL_ERROR $LEVEL_FATAL
            @zeilen   - Beliebig viele weitere Parameter. Jeder wird als
                        Textzeile fuer das Log interpretiert. Die Zeilen
                        sollten nicht mit Newlines abgeschlossen werden,
                        ausser man will (entsprechend viele) Leerzeilen
                        nach der betreffenden Meldungszeile erzwingen.

 Rueckgabe: -

Es ist moeglich, Newlines im Inneren der Meldungszeilen zu verwenden; dies
sollte jedoch vermieden werden (Einrueckungen erfolgen dennoch auch bei
Verwendung von eingebetteten Newlines "richtig").

Generell sollte jedes Element der Parameterliste eine Zeile der Meldung
darstellen, und es sollten keinerlei Newlines verwendet werden, auch und
insbesondere nicht am Zeilenende.

Mit Hilfe des Kommando-Bestandteils "$FROM_HOLD" lassen sich die Inhalte der
Halde wiederum auf STDOUT, STDERR und/oder in die Logdatei ausgeben, z.B. wie
folgt:

    Config::Manager::Report->report($FROM_HOLD+$TO_ERR);

Durch die Verwendung von "$FROM_HOLD" wird die Halde automatisch (nach ihrer
Ausgabe) geloescht, ausser bei einem Kommando wie

    Config::Manager::Report->report($FROM_HOLD+$TO_HLD);

welches (da sinnlos) vollstaendig ignoriert wird.

Es ist auch moeglich, ein Kommando wie z.B.

    Config::Manager::Report->report($FROM_HOLD+$TO_HLD+$TO_ERR);

anzugeben, hier wird die Halde auf STDERR ausgegeben aber NICHT
geloescht.

Die Methode zaehlt automatisch die Anzahl der Meldungen, die auf jedem Level
ausgegeben wurden, mit - unabhaengig davon, auf welchem Kanal (STDOUT, STDERR,
Halde oder Logdatei) diese Meldungen ausgegeben wurden.

Meldungen, die zuerst auf die Halde gelegt wurden und spaeter von dort aus
(mit Hilfe des Kommando-Bestandteils "$FROM_HOLD") auf einem der anderen
Kanaele ausgegeben werden, werden nicht noch einmal gezaehlt (das ginge auch
schon allein deshalb nicht, weil der Level der Meldung zu diesem Zeitpunkt
nicht mehr bekannt ist).

Diese kleine "Statistik" wird von der Methode "DESTROY()" mit in den Footer
der Logdatei geschrieben.

=item *

C<public $self-E<gt>trace()>

Diese Methode erlaubt es, Funktions- und Methodenaufrufe zu "tracen".

 Parameter: $self     - Referenz auf Log-Objekt oder Klassenname
            (Es wird das Singleton-Objekt verwendet, falls die Methode
            als Klassen- und nicht als Objekt-Methode aufgerufen wurde)

 Rueckgabe: -

Indem man die Zeile

     Config::Manager::Report->trace();

 (unter Verwendung der Default-Logdatei) oder

     $objekt->trace();

 (unter Verwendung der dem "$objekt" zugeordneten Logdatei)

ganz an den Anfang einer Funktion (insbesondere VOR irgendwelche
"shift"-Anweisungen, die sich auf die Aufrufparameter beziehen!) oder Methode
setzt, wird automatisch ein Stacktrace, zusammen mit allen Aufrufparametern
der aktuellen Funktion oder Methode, in die betreffende Logdatei geschrieben.

Setzt man den Ausgabe-"Level" (siehe dazu auch die Methode "C<level()>" direkt
hierunter) vom Default-Wert ("C<$LEVEL_TRACE>") auf den Wert "C<$LEVEL_INFO>",
werden alle Trace-Ausgaben effizient unterdrueckt, d.h. Trace-Informationen
werden dann gar nicht erst erzeugt, sondern die Methode "C<trace()>" kehrt
sofort (nach einem "C<if>") mit "C<return>" zur aufrufenden Routine zurueck.

=item *

C<public $self-E<gt>level([$value])>

Gibt den bisherigen Level des Loggings zurueck. Kann auch dazu verwendet
werden, diesen Level zu setzen, falls im Aufruf ein Wert angegeben wurde.

Moegliche Werte in diesem Zusammenhang sind:

    $SHOW_ALL $LEVEL_TRACE $LEVEL_INFO
    $LEVEL_WARN $LEVEL_ERROR $LEVEL_FATAL

Es sollten stets nur diese vordefinierten Konstanten zum Setzen des Levels
verwendet werden.

Das Setzen eines Levels groesser als Null (= Konstante "C<$SHOW_ALL>", bzw.
"C<$LEVEL_TRACE>", die Default-Einstellung) bewirkt, dass alle Meldungen
mit einem Level kleiner als diesem Wert unterdrueckt werden (und insbesondere
auch nicht in der Logdatei erscheinen).

 Parameter: $self     - Referenz auf Log-Objekt oder Klassenname
            (Es wird das Singleton-Objekt verwendet, falls die Methode
            als Klassen- und nicht als Objekt-Methode aufgerufen wurde)
            $value    - Optional der neue Wert

 Rueckgabe: Es wird immer der bisherige Wert zurueckgeliefert.

=item *

C<public $self-E<gt>logfile()>

Gibt den Namen und Pfad der Logdatei des betreffenden Log-Objekts zurueck.

 Parameter: $self     - Referenz auf Log-Objekt oder Klassenname
            (Es wird das Singleton-Objekt verwendet, falls die Methode
            als Klassen- und nicht als Objekt-Methode aufgerufen wurde)

 Rueckgabe: Gibt den Namen und Pfad der Logdatei zurueck.

=item *

C<public $self-E<gt>notify([$value])>

Gibt den bisherigen Wert des Flags zurueck, das angibt, ob bei Programmende
der Name und Pfad der Logdatei auf dem Bildschirm ausgegeben werden soll. Kann
auch dazu verwendet werden, dieses Flag zu setzen oder zu loeschen, falls im
Aufruf ein Wert angegeben wurde.

 Parameter: $self     - Referenz auf Log-Objekt oder Klassenname
            (Es wird das Singleton-Objekt verwendet, falls die Methode
            als Klassen- und nicht als Objekt-Methode aufgerufen wurde)
            $value    - Optional der neue Wert

 Rueckgabe: Es wird immer der bisherige Wert zurueckgeliefert.

=item *

C<public $self-E<gt>ret_hold()>

In List-Kontext:

Gibt die Halde des betreffenden Objekts (als Liste von Zeilen) zurueck (ohne
sie zu veraendern).

In Scalar-Kontext:

Gibt die Anzahl der Zeilen zurueck, die sich auf Halde befinden.

 Parameter: $self     - Referenz auf Log-Objekt oder Klassenname
            (Es wird das Singleton-Objekt verwendet, falls die Methode
            als Klassen- und nicht als Objekt-Methode aufgerufen wurde)

 Rueckgabe: Liste der Zeilen der Halde
            (jedes Element der Liste ist eine Zeile der Halde)
            - oder -
            Anzahl der Zeilen auf der Halde

=item *

C<public $self-E<gt>clr_hold()>

Loescht die Halde des betreffeden Objekts.

 Parameter: $self     - Referenz auf Log-Objekt oder Klassenname
            (Es wird das Singleton-Objekt verwendet, falls die Methode
            als Klassen- und nicht als Objekt-Methode aufgerufen wurde)

 Rueckgabe: -

=back

=head1 SEE ALSO

Config::Manager(3),
Config::Manager::Base(3),
Config::Manager::Conf(3),
Config::Manager::File(3),
Config::Manager::PUser(3),
Config::Manager::SendMail(3),
Config::Manager::User(3).

=head1 VERSION

This man page documents "Config::Manager::Report" version 1.7.

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

