@echo off
rem ===========================================================================
rem AmberDB Standalone Executable Builder (Windows Win64)
rem Requires: Strawberry Perl with PAR::Packer (cpanm PAR::Packer)
rem ===========================================================================

setlocal enabledelayedexpansion

echo [1/4] Checking environment...
where pp >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [ERROR] 'pp' command (PAR::Packer) was not found in PATH!
    echo Please install Strawberry Perl and run: cpanm PAR::Packer
    exit /b 1
)

if not exist "dist" mkdir dist

echo [2/4] Packing bin\amberdb_cli.pl into dist\amberdb.exe...
pp -o dist\amberdb.exe -I lib -M DB_File -M JSON::PP -M Archive::Tar -M Digest::SHA -M Unicode::Collate -M AmberDB -M AmberDB::Tools bin\amberdb_cli.pl

if %ERRORLEVEL% neq 0 (
    echo [ERROR] Compilation failed!
    exit /b %ERRORLEVEL%
)

echo [3/4] Copying CLI Guides and License...
if exist "wiki\TR-Guide-CLI.md" copy /Y "wiki\TR-Guide-CLI.md" "dist\KULLANIM_KILAVUZU_TR.md" >nul
if exist "wiki\Guide-CLI.md" copy /Y "wiki\Guide-CLI.md" "dist\CLI_GUIDE_EN.md" >nul
if exist "LICENSE" copy /Y "LICENSE" "dist\LICENSE.txt" >nul

echo [4/4] Creating zip bundle (amberdb-win64.zip)...
cd dist
tar -a -c -f ..\amberdb-win64.zip *
cd ..

echo.
echo ===========================================================================
echo [SUCCESS] Built dist\amberdb.exe and amberdb-win64.zip successfully!
echo ===========================================================================
dir dist\amberdb.exe
dir amberdb-win64.zip
