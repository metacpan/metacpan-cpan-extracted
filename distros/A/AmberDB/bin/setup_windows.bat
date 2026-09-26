@echo off
rem bin/setup_windows.bat - AmberDB Windows RAM-Disk Manager (ImDisk)
rem Usage:
rem   setup_windows.bat start [size] [drive]   (e.g. setup_windows.bat start 512M R:)
rem   setup_windows.bat stop [drive]          (e.g. setup_windows.bat stop R:)
rem   setup_windows.bat status [drive]

setlocal EnableDelayedExpansion

set ACTION=%1
if "%ACTION%"=="" set ACTION=status
if /i "%ACTION%"=="--start"  set ACTION=start
if /i "%ACTION%"=="mount"    set ACTION=start
if /i "%ACTION%"=="--stop"   set ACTION=stop
if /i "%ACTION%"=="unmount"  set ACTION=stop
if /i "%ACTION%"=="--status" set ACTION=status

set SIZE=512M
if not "%2"=="" set SIZE=%2

set DRIVE=R:
if not "%3"=="" set DRIVE=%3

if /i "%ACTION%"=="start"  goto do_start
if /i "%ACTION%"=="stop"   goto do_stop
if /i "%ACTION%"=="status" goto do_status

echo Unknown action: %ACTION%
echo Usage: %0 {start^|stop^|status} [size] [drive]
exit /b 1

:check_admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Administrator privileges required!
    echo Please run this Command Prompt as Administrator.
    exit /b 1
)
exit /b 0

:do_start
call :check_admin
if %errorlevel% neq 0 exit /b 1

if exist %DRIVE%\ (
    echo [INFO] RAM-Disk is already mounted on %DRIVE%
    exit /b 0
)

echo [RAM-DISK] Mounting %SIZE% NTFS RAM-Disk on %DRIVE%...
imdisk -a -s %SIZE% -m %DRIVE% -p "/fs:ntfs /q /y /v:AmberDB"
if %errorlevel% neq 0 (
    echo [ERROR] Failed to mount ImDisk drive %DRIVE%
    echo Please ensure ImDisk Toolkit is installed: https://sourceforge.net/projects/imdisk-toolkit/
    exit /b 1
)

rem Grant full permissions to local users so web and CLI processes can write
icacls %DRIVE%\ /grant "Users:(OI)(CI)F" /T /C /Q >nul 2>&1

echo [SUCCESS] RAM-Disk mounted and formatted on %DRIVE% (%SIZE%)
exit /b 0

:do_stop
call :check_admin
if %errorlevel% neq 0 exit /b 1

if not exist %DRIVE%\ (
    echo [INFO] RAM-Disk drive %DRIVE% is not mounted.
    exit /b 0
)

echo [RAM-DISK] Unmounting RAM-Disk on %DRIVE%...
imdisk -D -m %DRIVE%
if %errorlevel% neq 0 (
    echo [ERROR] Failed to unmount %DRIVE%
    exit /b 1
)

echo [SUCCESS] RAM-Disk on %DRIVE% successfully unmounted.
exit /b 0

:do_status
echo =================================================================
echo  AmberDB Windows RAM-Disk Status Monitor (%DRIVE%)
echo =================================================================
if exist %DRIVE%\ (
    echo Status: ACTIVE (Mounted on %DRIVE%)
    imdisk -l -m %DRIVE% 2>nul
) else (
    echo Status: INACTIVE (No RAM-disk on %DRIVE%)
)
echo =================================================================
exit /b 0
