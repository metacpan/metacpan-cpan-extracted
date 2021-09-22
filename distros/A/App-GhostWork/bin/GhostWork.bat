@echo off
:#####################################################################
:.
: GhostWork - Barcode Logger (When, Where, Who, What, toWhich, and Why)
:.
: https://metacpan.org/dist/App-GhostWork
:.
: Copyright (c) 2021 INABA Hitoshi "ina@cpan.org" in a CPAN
:#####################################################################
set VERSION=0.02

rem default message by English
if "%Q_WHO%"==""                set Q_WHO=Your name?
if "%Q_TOWHICH%"==""            set Q_TOWHICH=Which work you do?
if "%INFO_LOGFILE_IS%"==""      set INFO_LOGFILE_IS=Logfile is:
if "%Q_WHAT%"==""               set Q_WHAT=What number?
if "%Q_WHY%"==""                set Q_WHY=....Why?
if "%INFO_ANY_KEY_TO_EXIT%"=="" set INFO_ANY_KEY_TO_EXIT=Press any key to exit.

:BEGIN
    color 0F
    pushd %~dp0
    set COUNT=1

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
    if /i {%INPUT%}=={Q} goto :DO_EXIT
    set WHO=%INPUT%

:INPUT_TOWHICH
    color 0F
    set INPUT=
    set /p INPUT=%Q_TOWHICH%[Q][R]^>
    if    {%INPUT%}=={}  goto :INPUT_TOWHICH
    if /i {%INPUT%}=={Q} goto :DO_EXIT
    if /i {%INPUT%}=={R} goto :INPUT_WHO
    set TOWHICH=%INPUT%

:SET_OUTPUT
    color 0F
    mkdir LOG\%YYYYMMDD%\%TOWHICH% 2>nul
    set OUTPUT=LOG\%YYYYMMDD%\%TOWHICH%\%YYYYMMDD%-%TOWHICH%-%WHO%
    echo %INFO_LOGFILE_IS%%OUTPUT%.ltsv
    title %INFO_LOGFILE_IS%%OUTPUT%.ltsv

:DO_WHILE
    color 1F

:INPUT_WHAT
    color 1F
    set INPUT=
    set /p INPUT=No.%COUNT% %Q_WHAT%[Q]^>
    if    {%INPUT%}=={}  goto :INPUT_WHAT
    if /i {%INPUT%}=={Q} goto :DO_SAVEQUIT
    set WHAT=%INPUT%

:INPUT_WHY
    set WHY=%1
    if not {%1}=={} goto :SET_WHEN
    color E0
    set INPUT=
    set /p INPUT=%Q_WHY%[Q][R]^>
    if    {%INPUT%}=={}  goto :INPUT_WHY
    if /i {%INPUT%}=={Q} goto :DO_SAVEQUIT
    if /i {%INPUT%}=={R} goto :INPUT_WHAT
    set WHY=%INPUT%

:SET_WHEN
    color 1F
    rem 0123456789
    rem 2021/09/18
    set YYYYMMDD=%DATE:~0,4%%DATE:~5,2%%DATE:~8,2%
    rem 01234567890
    rem 23:34:59.77
    set HMMSS=%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%
    set HHMMSS=%HMMSS: =0%
    set WHEN=%YYYYMMDD%%HHMMSS%

:SET_LOOSEID
    color 1F
    set LOOSEID=%RANDOM%%RANDOM%

:DO_OUTPUT
    color 1F
    echo csv:%WHEN%,%WHERE%,%WHO%,%WHAT%,%TOWHICH%,%WHY%,%LOOSEID%	when:%WHEN%	where:%WHERE%	who:%WHO%	what:%WHAT%	towitch:%TOWHICH%	why:%WHY%	looseid:%LOOSEID%>>%OUTPUT%.ltsv
    echo     %WHEN%,%WHERE%,%WHO%,%WHAT%,%TOWHICH%,%WHY%
    set /a COUNT=%COUNT%+1

:END_WHILE
    color 1F
    goto :DO_WHILE

:DO_SAVEQUIT
    color CF
    set YYYYMMDD=%DATE:~0,4%%DATE:~5,2%%DATE:~8,2%
    set HMMSS=%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%
    set HHMMSS=%HMMSS: =0%
    set WHEN=%YYYYMMDD%%HHMMSS%
    set WHAT=***REMOVE_THIS_TIMESTAMP***
    set TOWHICH=
    set WHY=
    set LOOSEID=%RANDOM%%RANDOM%
    echo csv:%WHEN%,%WHERE%,%WHO%,%WHAT%,%TOWHICH%,%WHY%,%LOOSEID%	when:%WHEN%	where:%WHERE%	who:%WHO%	what:%WHAT%	towitch:%TOWHICH%	why:%WHY%	looseid:%LOOSEID%>>%OUTPUT%.ltsv
    echo     %WHEN%,%WHERE%,%WHO%,%WHAT%,%TOWHICH%,%WHY%
    timeout /nobreak 2 >nul
    goto :DO_EXIT

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

:DO_EXIT
    color 0F
    popd
    echo %INFO_ANY_KEY_TO_EXIT%
    pause >nul
