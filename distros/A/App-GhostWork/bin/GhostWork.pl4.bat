@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
jperl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
jperl -x -S "%0" %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
goto endofperl
@rem ';
#!jperl
#line 14
undef @rem;
######################################################################
#
# GhostWork - Barcode Logger (When,Where,Who,What,toWhich,Why,Howmanysec)
#
# https://metacpan.org/dist/App-GhostWork
#
# Copyright (c) 2021 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

sub BEGIN {
    eval q{
        use strict;
        use vars qw(
            $COUNT
            $CSV
            $FS
            $FindBin
            $HOWMANYSEC
            $INFO_ANY_KEY_TO_EXIT
            $INFO_DOUBLE_SCANNED
            $INFO_LOGFILE_IS
            $INPUT
            $LAST_SERIAL_TIME
            $LAST_WHAT
            $LOOSEID
            $OUTPUT
            $Q_TOWHICH
            $Q_WHAT
            $Q_WHO
            $Q_WHY
            $SERIAL_TIME
            $TOWHICH
            $VERSION
            $WHAT
            $WHEN
            $WHERE
            $WHO
            $WHY
            $YYYYMMDD
            $day
            $hour
            $min
            $month
            $sec
            $year
            @rem
        );
    };
}

$VERSION='0.06';
$VERSION=$VERSION;

# default message by English
if ($Q_WHO                eq "") { $Q_WHO='Your name?';                            }
if ($Q_TOWHICH            eq "") { $Q_TOWHICH='Which work you do?';                }
if ($Q_WHAT               eq "") { $Q_WHAT='What number?';                         }
if ($Q_WHY                eq "") { $Q_WHY='....Why?';                              }
if ($INFO_LOGFILE_IS      eq "") { $INFO_LOGFILE_IS='Logfile is:';                 }
if ($INFO_DOUBLE_SCANNED  eq "") { $INFO_DOUBLE_SCANNED='ERROR: Double Scanned.';  }
if ($INFO_ANY_KEY_TO_EXIT eq "") { $INFO_ANY_KEY_TO_EXIT='Press any key to exit.'; }

BEGIN:
    system('color 0F');
    ($FindBin=__FILE__) =~ s{[/\\][^/\\]*$}{};
    chdir($FindBin);
    $COUNT=1;
    $FS="\t";
    $LAST_SERIAL_TIME='';
    $LAST_WHAT='';

SET_YYYYMMDD:
    system('color 0F');
    ($year, $month, $day) = (localtime)[5,4,3];
    $YYYYMMDD=sprintf('%04d%02d%02d', 1900+$year, $month+1, $day);

SET_WHERE:
    system('color 0F');
    $WHERE=$ENV{'COMPUTERNAME'};

INPUT_WHO:
    system('color 0F');
    $INPUT='';
    print STDERR "$Q_WHO\[Q\]>";
    chop($INPUT=<STDIN>);
    if ($INPUT =~ /^$/)   { goto INPUT_WHO; }
    if ($INPUT =~ /^Q$/i) { goto DO_QUIT;   }
    $WHO=$INPUT;

INPUT_TOWHICH:
    system('color 0F');
    $INPUT='';
    print STDERR "$Q_TOWHICH\[Q\]\[R\]>";
    chop($INPUT=<STDIN>);

    if ($INPUT =~ /^$/)   { goto INPUT_TOWHICH; }
    if ($INPUT =~ /^Q$/i) { goto DO_QUIT;       }
    if ($INPUT =~ /^R$/i) { goto INPUT_WHO;     }
    $TOWHICH=$INPUT;

SET_OUTPUT:
    system('color 0F');
    mkdir("LOG", 0777);
    mkdir("LOG\\$YYYYMMDD", 0777);
    mkdir("LOG\\$YYYYMMDD\\$TOWHICH", 0777);
    $OUTPUT="LOG\\$YYYYMMDD\\$TOWHICH\\$YYYYMMDD-$TOWHICH-$WHO";
    print STDERR "$INFO_LOGFILE_IS$OUTPUT.ltsv\n";
    system("title $INFO_LOGFILE_IS$OUTPUT.ltsv");

SET_LAST_SERIAL_TIME:
    ($hour, $min, $sec) = (localtime)[3,2,1];
    $LAST_SERIAL_TIME=($hour*60*60)+($min*60)+($sec);

SET_LAST_WHAT:
    $LAST_WHAT='';

DO_WHILE:
    system('color 1F');

INPUT_WHAT:
    $INPUT='';
    print STDERR "No.$COUNT $Q_WHAT\[Q\]>";
    chop($INPUT=<STDIN>);
    if ($INPUT =~ /^$/)   { goto INPUT_WHAT; }
    if ($INPUT =~ /^Q$/i) { goto DO_QUIT;    }

AVOID_DOUBLE_SCANNING:
    if ($INPUT ne $LAST_WHAT) { goto SET_WHAT; }
    system('color CF');
    print STDERR $INFO_DOUBLE_SCANNED, "\n";
    goto INPUT_WHAT;

SET_WHAT:
    $WHAT=$INPUT;

INPUT_WHY:
    $WHY=$ARGV[0];
    if ($ARGV[0] ne '') { goto SET_WHEN; }
    system('color E0');
    $INPUT='';
    print STDERR "No.$COUNT $Q_WHY\[Q\]\[R\]>";
    chop($INPUT=<STDIN>);
    if ($INPUT =~ /^$/)   { goto INPUT_WHY;  }
    if ($INPUT =~ /^Q$/i) { goto DO_QUIT;    }
    if ($INPUT =~ /^R$/i) { goto INPUT_WHAT; }
    $WHY=$INPUT;

SET_WHEN:
    system('color 1F');
    ($year, $month, $day, $hour, $min, $sec) = (localtime)[5,4,3,2,1,0];
    $WHEN=sprintf('%04d%02d%02d%02d%02d%02d', 1900+$year, $month+1, $day, $hour, $min, $sec);

SET_LOOSEID:
    system('color 1F');
    $LOOSEID=rand(2**15).rand(2**15);

SET_SERIAL_TIME:
    system('color 1F');
    # convert octal to decimal
    ($hour, $min, $sec) = (localtime)[2,1,0];
    $SERIAL_TIME=($hour*60*60)+($min*60)+($sec);

SET_HOWMANYSEC:
    system('color 1F');
    # calculation when start time and end time cross 00:00 at midnight
    $HOWMANYSEC=$SERIAL_TIME;
    if ($SERIAL_TIME < $LAST_SERIAL_TIME) { $HOWMANYSEC+=24*60*60; }
    $HOWMANYSEC-=$LAST_SERIAL_TIME;

DO_OUTPUT:
    system('color 1F');
    $CSV="$WHEN,$WHERE,$WHO,$WHAT,$TOWHICH,$WHY,$HOWMANYSEC,$LOOSEID";
    open( CSV,  ">>$OUTPUT.csv");
    print CSV $CSV, "\n";
    open( LTSV, ">>$OUTPUT.ltsv");
    print LTSV "csv:$CSV${FS}when_:$WHEN${FS}where_:$WHERE${FS}who:$WHO${FS}what:$WHAT${FS}towitch:$TOWHICH${FS}why:$WHY${FS}howmanysec:$HOWMANYSEC${FS}looseid:$LOOSEID", "\n";
    open( JSON5,">>$OUTPUT.json5");
    print JSON5 qq<{"csv":"$CSV","when_":"$WHEN","where_":"$WHERE","who":"$WHO","what":"$WHAT","towitch":"$TOWHICH","why":"$WHY","howmanysec":"$HOWMANYSEC","looseid":"$LOOSEID"},>,"\n";
    $COUNT=$COUNT+1;

END_WHILE:
    system('color 1F');
    $LAST_SERIAL_TIME=$SERIAL_TIME;
    $LAST_WHAT=$WHAT;
    goto DO_WHILE;

######################################################################
# LICENSE AND COPYRIGHT
#
# This software is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself. See perlartistic.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
######################################################################

DO_QUIT:
    system('color 0F');
    print STDERR $INFO_ANY_KEY_TO_EXIT, "\n";
    system('pause >nul');

__END__
:endofperl
