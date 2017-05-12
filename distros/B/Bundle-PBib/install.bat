@echo off
echo Install PBib modules for use with perl
rem arguments:
rem %1 = path to perl root

set perl=perl

if "%1" == "" goto install
set perl="%1\bin\perl.exe"
if not exist "%perl%" goto notfound
goto install

:notfound
echo "Cannot find specified perl executable "%perl%", I try using "perl"
set perl=perl

:install
rem ToDo use CPAN module to get + install Module::Build
@echo on
%perl% Build.PL
%perl% Build
rem %perl% Build test
%perl% Build install
rem %perl% Build clean
@echo off
pause
