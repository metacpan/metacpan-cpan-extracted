# bin/setup_windows.ps1 - Windows Setup, Infrastructure & RAM-Disk Engine for AmberDB
# Handles Windows ImDisk RAM-disk, Task Scheduler watchdog, and NTFS directory provisioning.
# Run with Administrator privileges (or via amberdb_setup.pl)

param(
    [string]$Action = "status",
    [string]$Drive = "R:",
    [string]$Size = "512M",
    [string]$ProjectName = "",
    [string]$ProjectDir = "",
    [string]$User = ""
)

# 1. Resolve Project Paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ProjectDir) {
    $ProjectDir = Split-Path -Parent $scriptDir
}
$ProjectDir = (Resolve-Path $ProjectDir).Path

if (Test-Path (Join-Path $ProjectDir "tables")) {
    $dbDir  = $ProjectDir
    $appDir = Split-Path -Parent $ProjectDir
}
elseif (Test-Path (Join-Path $ProjectDir "dbstore")) {
    $dbDir  = Join-Path $ProjectDir "dbstore"
    $appDir = $ProjectDir
}
elseif (Test-Path (Join-Path $ProjectDir "dbase")) {
    $dbDir  = Join-Path $ProjectDir "dbase"
    $appDir = $ProjectDir
}
else {
    $dbDir  = $ProjectDir
    $appDir = $ProjectDir
}

if (-not $ProjectName -or $ProjectName -eq "dbstore" -or $ProjectName -eq "dbase") {
    $ProjectName = Split-Path -Leaf $appDir
    if ($ProjectName -eq "dbstore" -or $ProjectName -eq "dbase") {
        $ProjectName = Split-Path -Leaf (Split-Path -Parent $appDir)
    }
}

$ramdiskDir   = Join-Path $dbDir "ramdisk"
$driveRoot = "$Drive\"
if ($User -and $ProjectName -and $ProjectName -ne $User -and $ProjectName -ne "amberdb") {
    $projectRam = Join-Path (Join-Path $driveRoot $User) $ProjectName
}
elseif ($User) {
    $projectRam = Join-Path $driveRoot $User
}
else {
    $projectRam = Join-Path $driveRoot $ProjectName
}
$lockDir      = Join-Path $dbDir "lock"
$taskName     = "AmberDB-Watchdog-$ProjectName"
$daemonScript = Join-Path $scriptDir "amberdb_daemon.pl"
$libDir       = Join-Path $appDir "lib"

# Subfolders required by AmberDB
$subdirs = @("tables", "config", "schema", "lock", "pids")

function Check-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Error "[ERROR] Administrator privileges required! Please right-click PowerShell and select 'Run as Administrator'."
        exit 1
    }
}

function Install-ImDisk {
    Write-Host "[SETUP] Checking ImDisk installation..." -ForegroundColor Cyan

    $imdiskCmd = Get-Command imdisk -ErrorAction SilentlyContinue
    if ($imdiskCmd) {
        Write-Host "[OK] ImDisk is already installed on your system ($($imdiskCmd.Source))." -ForegroundColor Green
        return
    }

    Check-Admin

    Write-Host "[SETUP] ImDisk not detected. Attempting automated installation..." -ForegroundColor Cyan

    # 1. Try winget (Windows Package Manager)
    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetCmd) {
        Write-Host "[SETUP] Installing ImDisk via Windows Package Manager (winget)..." -ForegroundColor Cyan
        & winget install --id LTR.ImDisk -e --silent --accept-package-agreements --accept-source-agreements
        $imdiskCmd = Get-Command imdisk -ErrorAction SilentlyContinue
        if ($imdiskCmd) {
            Write-Host "[SUCCESS] ImDisk installed successfully via winget!" -ForegroundColor Green
            return
        }
    }

    # 2. Try Chocolatey
    $chocoCmd = Get-Command choco -ErrorAction SilentlyContinue
    if ($chocoCmd) {
        Write-Host "[SETUP] Installing ImDisk via Chocolatey..." -ForegroundColor Cyan
        & choco install imdisk-toolkit -y
        $imdiskCmd = Get-Command imdisk -ErrorAction SilentlyContinue
        if ($imdiskCmd) {
            Write-Host "[SUCCESS] ImDisk installed successfully via Chocolatey!" -ForegroundColor Green
            return
        }
    }

    # 3. Direct download from SourceForge
    Write-Host "[SETUP] Downloading ImDisk Toolkit from SourceForge..." -ForegroundColor Cyan
    $downloadUrl = "https://sourceforge.net/projects/imdisk-toolkit/files/latest/download"
    $installerPath = Join-Path $env:TEMP "ImDiskTk-setup.exe"

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UserAgent "Mozilla/5.0"
        if (Test-Path $installerPath) {
            Write-Host "[SETUP] Running ImDisk installer silently..." -ForegroundColor Cyan
            Start-Process -FilePath $installerPath -ArgumentList "/SILENT", "/NORESTART" -Wait
            Write-Host "[SUCCESS] ImDisk Toolkit installation completed!" -ForegroundColor Green
            return
        }
    }
    catch {
        Write-Warning "[WARN] Automatic download failed: $_"
    }

    Write-Error "[ERROR] Could not automatically install ImDisk.`nPlease manually download and install from: https://sourceforge.net/projects/imdisk-toolkit/"
    exit 1
}

# Normalize Action
$act = $Action.ToLower()

# --- Action: INSTALL-IMDISK / IMDISK ---
if ($act -eq "install-imdisk" -or $act -eq "imdisk" -or $act -eq "imdisk-install") {
    Install-ImDisk
    return
}

# --- Action: STATUS / RAMDISK-STATUS ---
if ($act -eq "status" -or $act -eq "ramdisk-status") {
    Write-Host "=================================================================" -ForegroundColor Cyan
    Write-Host " AmberDB Windows Infrastructure & RAM-Disk Status Monitor" -ForegroundColor Cyan
    Write-Host "=================================================================" -ForegroundColor Cyan
    Write-Host "Platform:       Windows ($([Environment]::OSVersion.VersionString))"
    Write-Host "Project Name:   $ProjectName"
    Write-Host "Project Root:   $ProjectDir"
    Write-Host "Local RAM Path: $ramdiskDir"
    Write-Host "RAM Drive:      $Drive ($projectRam)"

    $driveExists = Test-Path $driveRoot
    $projectRamExists = Test-Path $projectRam

    if ($driveExists -and $projectRamExists) {
        Write-Host "RAM-Disk:       ACTIVE (Mounted on $projectRam)" -ForegroundColor Green
    }
    elseif ($driveExists) {
        Write-Host "RAM-Disk:       DRIVE ACTIVE ($Drive mounted, but project folder $ProjectName not initialized)" -ForegroundColor Yellow
    }
    else {
        Write-Host "RAM-Disk:       INACTIVE (Running on local storage)" -ForegroundColor Gray
    }

    # Check Task Scheduler Watchdog
    $taskCheck = & schtasks.exe /query /tn $taskName 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Watchdog Task:  REGISTERED ($taskName)" -ForegroundColor Green
    }
    else {
        Write-Host "Watchdog Task:  NOT REGISTERED" -ForegroundColor Gray
    }

    Write-Host "=================================================================" -ForegroundColor Cyan
    return
}

# --- Action: CRON-INSTALL / TASK-INSTALL ---
if ($act -eq "cron-install" -or $act -eq "task-install" -or $act -eq "cron") {
    Check-Admin
    Write-Host "[SETUP] Registering Windows Scheduled Task for AmberDB Watchdog..." -ForegroundColor Cyan

    $perlPath = (Get-Command perl -ErrorAction SilentlyContinue).Source
    if (-not $perlPath) { $perlPath = "perl.exe" }

    $taskCmd = "`"$perlPath`" -I`"$libDir`" `"$daemonScript`" watchdog --dbase_dir `"$ProjectDir`""

    # Register task running every 5 minutes
    & schtasks.exe /create /tn $taskName /tr "powershell.exe -NoProfile -WindowStyle Hidden -Command `"$taskCmd`"" /sc minute /mo 5 /f /ru "SYSTEM" | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] Watchdog Scheduled Task registered successfully: $taskName (every 5 minutes)" -ForegroundColor Green
    }
    else {
        # Fallback to current user if SYSTEM fails
        & schtasks.exe /create /tn $taskName /tr "powershell.exe -NoProfile -WindowStyle Hidden -Command `"$taskCmd`"" /sc minute /mo 5 /f | Out-Null
        Write-Host "[SUCCESS] Watchdog Scheduled Task registered for current user: $taskName" -ForegroundColor Green
    }
    return
}

# --- Action: CRON-REMOVE / TASK-REMOVE ---
if ($act -eq "cron-remove" -or $act -eq "task-remove") {
    Check-Admin
    Write-Host "[SETUP] Removing Windows Scheduled Task '$taskName'..." -ForegroundColor Yellow
    & schtasks.exe /delete /tn $taskName /f 2>$null
    Write-Host "[SUCCESS] Watchdog Scheduled Task removed." -ForegroundColor Green
    return
}

# --- Action: SERVICE-INSTALL ---
if ($act -eq "service-install" -or $act -eq "service") {
    Write-Host "=================================================================" -ForegroundColor Cyan
    Write-Host " AmberDB Windows Service Installation Guidance                  " -ForegroundColor Cyan
    Write-Host "=================================================================" -ForegroundColor Cyan
    Write-Host "To install AmberDB background sync engine as an official Windows Service:"
    Write-Host "1. Download NSSM (Non-Sucking Service Manager): https://nssm.cc/"
    Write-Host "2. Execute from an elevated Command Prompt:"
    Write-Host "   nssm install AmberDB-Sync `"$((Get-Command perl).Source)`" -I`"$libDir`" `"$daemonScript`" run --dbase_dir `"$ProjectDir`""
    Write-Host "   nssm set AmberDB-Sync AppDirectory `"$ProjectDir`""
    Write-Host "   nssm start AmberDB-Sync"
    Write-Host "=================================================================" -ForegroundColor Cyan
    return
}

# Require admin for ramdisk start / stop
Check-Admin

# --- Action: STOP / RAMDISK-STOP / UNMOUNT ---
if ($act -eq "stop" -or $act -eq "ramdisk-stop" -or $act -eq "unmount") {
    Write-Host "[RAM-DISK] Stopping AmberDB RAM-Disk for project '$ProjectName'..." -ForegroundColor Yellow

    # Remove junction link
    if (Test-Path $ramdiskDir) {
        cmd /c "rmdir `"$ramdiskDir`"" 2>$null
        New-Item -ItemType Directory -Path $ramdiskDir -Force | Out-Null
        foreach ($sub in $subdirs) {
            New-Item -ItemType Directory -Path (Join-Path $ramdiskDir $sub) -Force | Out-Null
        }
    }

    if (Test-Path $lockDir) {
        cmd /c "rmdir /s /q `"$lockDir`"" 2>$null
    }

    # If project RAM folder exists, clean it
    if (Test-Path $projectRam) {
        cmd /c "rmdir /s /q `"$projectRam`"" 2>$null
    }

    # If drive has no remaining project folders, unmount it
    if (Test-Path $driveRoot) {
        $remaining = Get-ChildItem $driveRoot -Directory -ErrorAction SilentlyContinue
        if (-not $remaining -or $remaining.Count -eq 0) {
            Write-Host "[RAM-DISK] No other projects active. Unmounting drive $Drive..." -ForegroundColor Yellow
            & imdisk -D -m $Drive 2>$null
        }
    }

    Write-Host "[SUCCESS] RAM-Disk unmounted and restored to local storage for '$ProjectName'." -ForegroundColor Green
    return
}

# --- Action: START / RAMDISK-START / MOUNT ---
if ($act -eq "start" -or $act -eq "ramdisk-start" -or $act -eq "mount") {
    Write-Host "[RAM-DISK] Initializing Windows ImDisk RAM-Disk for '$ProjectName' ($Size)..." -ForegroundColor Cyan

    $imdiskCmd = Get-Command imdisk -ErrorAction SilentlyContinue
    if (-not $imdiskCmd) {
        Write-Host "[WARN] 'imdisk' CLI tool was not found on your system. Attempting automated installation..." -ForegroundColor Yellow
        Install-ImDisk
        $imdiskCmd = Get-Command imdisk -ErrorAction SilentlyContinue
        if (-not $imdiskCmd) {
            Write-Error "[ERROR] ImDisk is required to mount RAM-disk on Windows."
            exit 1
        }
    }

    # 1. Mount RAM drive if not mounted
    if (-not (Test-Path $driveRoot)) {
        Write-Host "[RAM-DISK] Mounting $Size RAM drive on $Drive..."
        & imdisk -a -s $Size -m $Drive -p "/fs:ntfs /q /y"
        if ($LASTEXITCODE -ne 0) {
            Write-Error "[ERROR] Failed to mount ImDisk drive $Drive"
            exit 1
        }
    }

    # 2. Create isolated project folder on RAM drive
    if (-not (Test-Path $projectRam)) {
        New-Item -ItemType Directory -Path $projectRam -Force | Out-Null
    }
    foreach ($sub in $subdirs) {
        $subPath = Join-Path $projectRam $sub
        if (-not (Test-Path $subPath)) {
            New-Item -ItemType Directory -Path $subPath -Force | Out-Null
        }
    }

    # 2b. Configure NTFS permissions and ownership on RAM folder
    if ($User) {
        Write-Host "[RAM-DISK] Setting ownership and permissions for user '$User' on $projectRam..." -ForegroundColor Cyan
        & icacls.exe "$projectRam" /setowner "$User" /T /C /Q 2>$null
        & icacls.exe "$projectRam" /grant "${User}:(OI)(CI)F" /T /C /Q
    }
    # Always grant Users modify/full control so web processes (Apache, PHP, Perl) can write without permission denial
    & icacls.exe "$projectRam" /grant "Users:(OI)(CI)F" /T /C /Q 2>$null

    # 3. Clean legacy lock dir
    if (Test-Path $lockDir) {
        cmd /c "rmdir /s /q `"$lockDir`"" 2>$null
    }

    # 4. Link dbstore\ramdisk to R:\<ProjectName>
    if (Test-Path $ramdiskDir) {
        cmd /c "rmdir /s /q `"$ramdiskDir`"" 2>$null
    }
    cmd /c "mklink /J `"$ramdiskDir`" `"$projectRam`"" 2>$null | Out-Null

    Write-Host "`n[SUCCESS] Windows ImDisk RAM-Disk is ready and configured for AmberDB!" -ForegroundColor Green
    Write-Host "  Project:      $ProjectName"
    Write-Host "  RAM Storage:  $projectRam"
    Write-Host "  Local Link:   $ramdiskDir -> $projectRam"
    Write-Host '  |-- table/    (DB and Index acceleration files)'
    Write-Host '  |-- config/   (Compiled config files)'
    Write-Host '  |-- schema/   (Table and DBase schema files)'
    Write-Host '  |-- lock/     (Flock lock files)'
    Write-Host "  \-- pids/     (Process and mutex files)`n"
}
