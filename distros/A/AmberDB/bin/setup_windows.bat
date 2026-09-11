@echo off
rem bin/setup_windows.bat - Windows Setup & RAM-Disk Forwarder for AmberDB
rem Run with Administrator privileges (or via amberdb_setup.pl)

set ACTION=%1
if "%ACTION%"=="" set ACTION=status
if "%ACTION%"=="--start" set ACTION=start
if "%ACTION%"=="--stop" set ACTION=stop
if "%ACTION%"=="--status" set ACTION=status
if "%ACTION%"=="mount" set ACTION=start
if "%ACTION%"=="unmount" set ACTION=stop

set SIZE=512M
if not "%2"=="" set SIZE=%2

set PROJECT_NAME=
if not "%3"=="" set PROJECT_NAME=%3

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1" -Action %ACTION% -Size %SIZE% -ProjectName "%PROJECT_NAME%"
