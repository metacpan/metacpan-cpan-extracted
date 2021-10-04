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
print STDERR <<END;
#####################################################################

 GhostWork - Barcode Logger

#####################################################################

** USAGE **
   Press [Q] to Quit this software
   Press [R] to Retry last operation

END

$Q_WHO='Your name?';
$Q_TOWHICH='Which work you do?';
$Q_WHAT='What number?';
$Q_WHY='....Why?';
$INFO_LOGFILE_IS='Logfile is: ';
$INFO_DOUBLE_SCANNED='ERROR: Double Scanned.';
$INFO_ANY_KEY_TO_EXIT='Press any key to exit.';

($FindBin = __FILE__) =~ s{[^/\\]+$}{};
do "$FindBin/GhostWork.pl4.bat";

__END__
:endofperl
