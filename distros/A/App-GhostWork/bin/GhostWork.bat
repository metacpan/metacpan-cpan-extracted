@echo off
:#####################################################################
:.
: GhostWork - Barcode Logger (When,Where,Who,What,toWhich,Why,Howmanysec)
:.
: https://metacpan.org/dist/App-GhostWork
:.
: Copyright (c) 2021 INABA Hitoshi "ina@cpan.org" in a CPAN
:#####################################################################
setlocal
set VERSION=0.06

rem default message by English
if "%Q_WHO%"==""                set Q_WHO=Your name?
if "%Q_TOWHICH%"==""            set Q_TOWHICH=Which work you do?
if "%Q_WHAT%"==""               set Q_WHAT=What number?
if "%Q_WHY%"==""                set Q_WHY=....Why?
if "%INFO_LOGFILE_IS%"==""      set INFO_LOGFILE_IS=Logfile is:
if "%INFO_DOUBLE_SCANNED%"==""  set INFO_DOUBLE_SCANNED=ERROR: Double Scanned.
if "%INFO_ANY_KEY_TO_EXIT%"=="" set INFO_ANY_KEY_TO_EXIT=Press any key to exit.

:BEGIN
    color 0F
    pushd %~dp0
    set COUNT=1
    set FS=	

:SET_YYYYMMDD
    color 0F
    rem 0123456789
    rem 2021/09/18
    set YYYYMMDD=%DATE:~0,4%%DATE:~5,2%%DATE:~8,2%

:SET_WHERE
    color 0F
    set WHERE=%COMPUTERNAME%

:INPUT_WHO
    color 0F
    set INPUT=
    set /p INPUT=%Q_WHO%[Q]^>
    if    {%INPUT%}=={}  goto :INPUT_WHO
    if /i {%INPUT%}=={Q} goto :DO_QUIT
    set WHO=%INPUT%

:INPUT_TOWHICH
    color 0F
    set INPUT=
    set /p INPUT=%Q_TOWHICH%[Q][R]^>
    if    {%INPUT%}=={}  goto :INPUT_TOWHICH
    if /i {%INPUT%}=={Q} goto :DO_QUIT
    if /i {%INPUT%}=={R} goto :INPUT_WHO
    set TOWHICH=%INPUT%

:SET_OUTPUT
    color 0F
    mkdir LOG\%YYYYMMDD%\%TOWHICH% 2>nul
    set OUTPUT=LOG\%YYYYMMDD%\%TOWHICH%\%YYYYMMDD%-%TOWHICH%-%WHO%
    echo %INFO_LOGFILE_IS%%OUTPUT%.ltsv
    title %INFO_LOGFILE_IS%%OUTPUT%.ltsv

:SET_LAST_SERIAL_TIME
    rem convert octal to decimal
    set OCT_ZH_ZM_ZS=%TIME: =0%
    set OCT_HOUR=%OCT_ZH_ZM_ZS:~0,2%
    set OCT__MIN=%OCT_ZH_ZM_ZS:~3,2%
    set OCT__SEC=%OCT_ZH_ZM_ZS:~6,2%
    set /a DEC_HOUR=8%OCT_HOUR%-800
    set /a DEC__MIN=8%OCT__MIN%-800
    set /a DEC__SEC=8%OCT__SEC%-800
    set /a LAST_SERIAL_TIME=(%DEC_HOUR%*60*60)+(%DEC__MIN%*60)+(%DEC__SEC%)

:SET_LAST_WHAT
    set LAST_WHAT=

:DO_WHILE
    color 1F

:INPUT_WHAT
    set INPUT=
    set /p INPUT=No.%COUNT% %Q_WHAT%[Q]^>
    if    {%INPUT%}=={}  goto :INPUT_WHAT
    if /i {%INPUT%}=={Q} goto :DO_QUIT

:AVOID_DOUBLE_SCANNING
    if not {%INPUT%}=={%LAST_WHAT%} goto :SET_WHAT
    color CF
    echo %INFO_DOUBLE_SCANNED%
    goto :INPUT_WHAT

:SET_WHAT
    set WHAT=%INPUT%

:INPUT_WHY
    set WHY=%1
    if not {%1}=={} goto :SET_WHEN
    color E0
    set INPUT=
    set /p INPUT=%Q_WHY%[Q][R]^>
    if    {%INPUT%}=={}  goto :INPUT_WHY
    if /i {%INPUT%}=={Q} goto :DO_QUIT
    if /i {%INPUT%}=={R} goto :INPUT_WHAT
    set WHY=%INPUT%

:SET_WHEN
    color 1F
    rem 0123456789
    rem 2021/09/18
    set YYYYMMDD=%DATE:~0,4%%DATE:~5,2%%DATE:~8,2%
    rem 01234567890
    rem 23:34:59.77
    set ZEROTIME=%TIME: =0%
    set WHEN=%YYYYMMDD%%ZEROTIME:~0,2%%TIME:~3,2%%TIME:~6,2%

:SET_LOOSEID
    color 1F
    set LOOSEID=%RANDOM%%RANDOM%

:SET_SERIAL_TIME
    color 1F
    rem convert octal to decimal
    set OCT_ZH_ZM_ZS=%TIME: =0%
    set OCT_HOUR=%OCT_ZH_ZM_ZS:~0,2%
    set OCT__MIN=%OCT_ZH_ZM_ZS:~3,2%
    set OCT__SEC=%OCT_ZH_ZM_ZS:~6,2%
    set /a DEC_HOUR=8%OCT_HOUR%-800
    set /a DEC__MIN=8%OCT__MIN%-800
    set /a DEC__SEC=8%OCT__SEC%-800
    set /a SERIAL_TIME=(%DEC_HOUR%*60*60)+(%DEC__MIN%*60)+(%DEC__SEC%)

:SET_HOWMANYSEC
    color 1F
    rem calculation when start time and end time cross 00:00 at midnight
    set /a HOWMANYSEC=%SERIAL_TIME%
    if "%SERIAL_TIME%" lss "%LAST_SERIAL_TIME%" set /a HOWMANYSEC+=24*60*60
    set /a HOWMANYSEC-=%LAST_SERIAL_TIME%

:DO_OUTPUT
    color 1F
    set CSV=%WHEN%,%WHERE%,%WHO%,%WHAT%,%TOWHICH%,%WHY%,%HOWMANYSEC%,%LOOSEID%
    echo %CSV%>>%OUTPUT%.csv
    echo csv:%CSV%%FS%when_:%WHEN%%FS%where_:%WHERE%%FS%who:%WHO%%FS%what:%WHAT%%FS%towitch:%TOWHICH%%FS%why:%WHY%%FS%howmanysec:%HOWMANYSEC%%FS%looseid:%LOOSEID%>>%OUTPUT%.ltsv
    echo {"csv":"%CSV%","when_":"%WHEN%","where_":"%WHERE%","who":"%WHO%","what":"%WHAT%","towitch":"%TOWHICH%","why":"%WHY%","howmanysec":"%HOWMANYSEC%","looseid":"%LOOSEID%"},>>%OUTPUT%.json5
    set /a COUNT=%COUNT%+1

:END_WHILE
    color 1F
    set LAST_SERIAL_TIME=%SERIAL_TIME%
    set LAST_WHAT=%WHAT%
    goto :DO_WHILE

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
: LICENSE AND COPYRIGHT
:.
: This software is free software; you can redistribute it and/or
: modify it under the same terms as Perl itself. See perlartistic.
:.
: This software is distributed in the hope that it will be useful,
: but WITHOUT ANY WARRANTY; without even the implied warranty of
: MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:DO_QUIT
    color 0F
    popd
    echo %INFO_ANY_KEY_TO_EXIT%
    endlocal
    pause >nul
