#!/usr/bin/perl

# bin/amberdb_setup.pl - Consolidated Setup, Provisioning, Maintenance & Infrastructure Utility
# Combines installation, permissions, RAM-disk management, table migrations, backup/restore, re-indexing, and cron/systemd service configuration.

use 5.016;
use strict;
use warnings;
use Getopt::Long qw(:config pass_through);
use File::Spec;
use File::Path qw(make_path);
use File::Basename qw(dirname);
use File::Copy qw(move);
use Cwd qw(abs_path getcwd);
use version;
use HTTP::Tiny;
use JSON::PP qw(decode_json encode_json);

BEGIN {
    use File::Basename qw(dirname);
    use Cwd qw(abs_path);
    my $bin_dir = dirname(abs_path(__FILE__));
    my $lib_dir = abs_path("$bin_dir/../lib");
    unshift @INC, $lib_dir if -d $lib_dir;
}

use AmberDB;
use AmberDB::Tools;

# Resolve project paths
my $script_dir  = dirname(abs_path(__FILE__));
my $project_dir = abs_path( File::Spec->catdir( $script_dir, ".." ) );
my $lib_dir     = File::Spec->catdir( $project_dir, "lib" );

# Common options
my $opt_action    = '';
my $opt_user      = '';
my $opt_group     = '';
my $opt_size      = '512M';
my $opt_dbase     = '';
my $opt_ramdisk   = '';
my $opt_drive     = 'R:';
my $opt_name      = '';
my $opt_cron      = undef;
my $opt_service   = 0;

# RAM-disk sub-options
my $opt_start     = 0;
my $opt_stop      = 0;
my $opt_status    = 0;

# Update & reindex sub-options
my $opt_all       = 0;
my $opt_tables    = '';
my $opt_force     = 0;
my $opt_check     = 0;
my $opt_no_backup = 0;
my $opt_manifest  = '';
my $opt_cpanm     = '';

# Backup sub-options
my $opt_dump      = 0;
my $opt_restore   = 0;
my $opt_file      = '';
my $opt_reindex   = 1;

my $opt_help      = 0;

GetOptions(
    'action=s'      => \$opt_action,
    'user=s'        => \$opt_user,
    'group=s'       => \$opt_group,
    'size=s'        => \$opt_size,
    'dbase_dir=s'   => \$opt_dbase,
    'dbase=s'       => \$opt_dbase,
    'ramdisk_dir=s' => \$opt_ramdisk,
    'drive=s'       => \$opt_drive,
    'name=s'        => \$opt_name,
    'cron!'         => \$opt_cron,
    'service'       => \$opt_service,

    # Ramdisk actions
    'start|mount'   => \$opt_start,
    'stop|unmount'  => \$opt_stop,
    'status'        => \$opt_status,

    # Update & reindex
    'all|a'         => \$opt_all,
    'tables|t=s'    => \$opt_tables,
    'table=s'       => \$opt_tables,
    'force'         => \$opt_force,
    'check'         => \$opt_check,
    'no-backup'     => \$opt_no_backup,
    'manifest=s'    => \$opt_manifest,
    'cpanm=s'       => \$opt_cpanm,

    # Backup
    'dump|d'        => \$opt_dump,
    'restore|r'     => \$opt_restore,
    'file|f=s'      => \$opt_file,
    'reindex!'      => \$opt_reindex,

    'help|h'        => \$opt_help,
);

# Determine project directory & project name
my $target_dir = $opt_dbase;
if ( !defined $target_dir || $target_dir eq '' ) {
    my $cwd = abs_path(getcwd());
    if ( -d File::Spec->catdir( $cwd, "dbstore" ) ) {
        $target_dir = File::Spec->catdir( $cwd, "dbstore" );
    }
    elsif ( -d File::Spec->catdir( $cwd, "dbase" ) ) {
        $target_dir = File::Spec->catdir( $cwd, "dbase" );
    }
    elsif ( -d File::Spec->catdir( $cwd, "tables" ) ) {
        $target_dir = $cwd;
    }
    elsif ( -d File::Spec->catdir( $project_dir, "dbstore" ) ) {
        $target_dir = File::Spec->catdir( $project_dir, "dbstore" );
    }
    elsif ( -d File::Spec->catdir( $project_dir, "dbase" ) ) {
        $target_dir = File::Spec->catdir( $project_dir, "dbase" );
    }
    else {
        $target_dir = $project_dir;
    }
}
$target_dir = abs_path($target_dir);

my $project_name = $opt_name;
if ( !defined $project_name || $project_name eq '' ) {
    my @dirs = File::Spec->splitdir($target_dir);
    $project_name = pop @dirs;
    $project_name = pop @dirs while ( defined $project_name && $project_name eq '' && @dirs );
    if ( defined $project_name && ( $project_name eq 'dbstore' || $project_name eq 'dbase' ) && @dirs ) {
        $project_name = pop @dirs;
        $project_name = pop @dirs while ( defined $project_name && $project_name eq '' && @dirs );
    }
    $project_name ||= "amberdb";
}

# Infer action if not specified
if ( !$opt_action ) {
    if ($opt_dump || $opt_restore) {
        $opt_action = 'backup';
    }
    elsif ($opt_start || $opt_stop || $opt_status) {
        $opt_action = 'ramdisk';
    }
    elsif ($opt_user) {
        $opt_action = 'install';
    }
    elsif ($opt_cron) {
        $opt_action = 'cron';
    }
    elsif ($opt_service) {
        $opt_action = 'service';
    }
}

# Show usage if no action or help requested
if ( $opt_help || !$opt_action || $opt_action eq 'usage' || $opt_action eq 'help' ) {
    show_usage();
    exit 0;
}

# Dispatch actions
if ( $opt_action eq 'install' || $opt_action eq 'setup' ) {
    action_install();
}
elsif ( $opt_action eq 'ramdisk' ) {
    action_ramdisk();
}
elsif ( $opt_action eq 'update-amberdb' ) {
    action_update_amberdb();
}
elsif ( $opt_action eq 'update-storage' || $opt_action eq 'updatedb' ) {
    action_update_storage();
}
elsif ( $opt_action eq 'update' ) {
    action_update();
}
elsif ( $opt_action eq 'backup' ) {
    action_backup();
}
elsif ( $opt_action eq 'reindex' ) {
    action_reindex();
}
elsif ( $opt_action eq 'cron' ) {
    action_cron();
}
elsif ( $opt_action eq 'service' ) {
    action_service();
}
else {
    print STDERR "[ERROR] Unknown action '$opt_action'. Use 'perl $0 usage' for help.\n";
    exit 1;
}

# ============================================================================
# ACTIONS
# ============================================================================

sub action_install {
    print "=================================================================\n";
    print " AmberDB Infrastructure Installation & Provisioning            \n";
    print "=================================================================\n";
    print "Target Directory : $target_dir\n";
    print "Project Name     : $project_name\n";
    print "Configured User  : " . ( $opt_user || '(Current User)' ) . "\n";
    print "RAM-Disk Size    : $opt_size\n";
    print "-----------------------------------------------------------------\n";

    # 1. Create directory structure
    my @dirs = (
        "$target_dir/table",
        "$target_dir/schema",
        "$target_dir/journal",
        "$target_dir/lock",
        "$target_dir/session",
        "$target_dir/config",
        "$target_dir/ramdisk",
    );

    print "Creating database directory structure...\n";
    for my $d (@dirs) {
        if ( !-d $d ) {
            make_path($d);
            print "  [+] Created $d\n";
        }
        else {
            print "  [.] Exists  $d\n";
        }
    }

    # 2. Optional: Configure ownership on Unix if user exists in system accounts
    if ( $opt_user && ( $^O ne 'MSWin32' && $^O ne 'msys' && $^O ne 'cygwin' ) ) {
        my $uid = eval { getpwnam($opt_user) };
        if ( defined $uid ) {
            my $gid = $opt_group ? eval { getgrnam($opt_group) } : ( getpwnam($opt_user) )[3];
            print "Applying ownership ($opt_user:" . ( $opt_group || $opt_user ) . ") to $target_dir...\n";
            system( "chown", "-R", "$uid:$gid", $target_dir );
            system( "chmod", "-R", "0775", $target_dir );
            print "  [OK] Permissions configured.\n";
        }
    }

    # 3. Ensure Windows prerequisites (ImDisk) if running on Windows
    if ( $^O eq 'MSWin32' || $^O eq 'msys' || $^O eq 'cygwin' ) {
        my $has_imdisk = `where imdisk 2>nul` || `which imdisk 2>/dev/null`;
        unless ($has_imdisk) {
            print "\n[SETUP] ImDisk is not detected. Launching automated installer via setup_windows.ps1...\n";
            my $ps1_path = File::Spec->catfile( $script_dir, "setup_windows.ps1" );
            system(qq{powershell -NoProfile -ExecutionPolicy Bypass -File "$ps1_path" -Action install-imdisk});
        }
    }

    # 4. Mount RAM-disk
    print "\nConfiguring RAM-disk ($opt_size)...\n";
    $opt_start = 1;
    action_ramdisk();

    # 5. Configure Cron Watchdog (installed automatically unless --no-cron)
    if ( !defined $opt_cron || $opt_cron ) {
        print "\nConfiguring Cron Watchdog...\n";
        action_cron();
    }

    # 5. Configure systemd if requested
    if ($opt_service) {
        print "\nConfiguring Systemd Service...\n";
        action_service();
    }

    print "\n=================================================================\n";
    print " AmberDB setup completed successfully!                          \n";
    print "=================================================================\n";
}

sub action_ramdisk {
    my $platform;
    if ( $^O eq 'MSWin32' || $^O eq 'msys' || $^O eq 'cygwin' ) {
        $platform = 'windows';
    }
    elsif ( $^O eq 'darwin' ) {
        $platform = 'macos';
    }
    else {
        $platform = 'linux';
    }

    my $sub_action = $opt_start ? "start" : $opt_stop ? "stop" : "status";

    if ( $platform eq 'windows' ) {
        my $ps1_path = File::Spec->catfile( $script_dir, "setup_windows.ps1" );
        die "[ERROR] Missing Windows helper script: $ps1_path\n" unless -e $ps1_path;

        my $user_flag = ( defined $opt_user && length $opt_user ) ? qq{ -User "$opt_user"} : "";
        my $ps_cmd = qq{powershell -NoProfile -ExecutionPolicy Bypass -File "$ps1_path"}
          . qq{ -Action "$sub_action"}
          . qq{ -Drive "$opt_drive"}
          . qq{ -Size "$opt_size"}
          . qq{ -ProjectName "$project_name"}
          . qq{ -ProjectDir "$target_dir"}
          . $user_flag;

        system($ps_cmd);
    }
    elsif ( $platform eq 'macos' ) {
        my $sh_path = File::Spec->catfile( $script_dir, "setup_macos.sh" );
        die "[ERROR] Missing macOS helper script: $sh_path\n" unless -e $sh_path;

        system( qq{bash "$sh_path" "$sub_action" "$opt_size" "$project_name" "$opt_user"} );
    }
    else {
        my $sh_path = File::Spec->catfile( $script_dir, "setup_linux.sh" );
        die "[ERROR] Missing Linux helper script: $sh_path\n" unless -e $sh_path;

        if ( ( $sub_action eq 'start' || $sub_action eq 'stop' ) && $> != 0 ) {
            print "[INFO] Linux tmpfs requires root privileges. Invoking sudo...\n";
            system( "sudo", "bash", $sh_path, $sub_action, $opt_size, $project_name, $opt_user || '' );
        }
        else {
            system( "bash", $sh_path, $sub_action, $opt_size, $project_name, $opt_user || '' );
        }
    }
}

sub action_update {
    print "=================================================================\n";
    print " AmberDB Comprehensive System Update Engine (Engine + Storage)  \n";
    print "=================================================================\n";
    print "Target Database Directory : $target_dir\n";
    print "Current AmberDB Engine    : $AmberDB::VERSION\n";
    print "-----------------------------------------------------------------\n";

    print "\n>>> [Stage 1/2] Checking AmberDB Engine (CPAN)...\n\n";
    action_update_amberdb();

    print "\n>>> [Stage 2/2] Updating Database Storage & Migrations...\n\n";
    action_update_storage();

    print "\n=================================================================\n";
    print " AmberDB comprehensive update finished successfully!             \n";
    print "=================================================================\n";
}

sub action_update_amberdb {
    print "=================================================================\n";
    print " AmberDB Core Engine Update Utility (CPAN Distribution)          \n";
    print "=================================================================\n";
    print "Current Engine Version : $AmberDB::VERSION\n";
    print "Checking MetaCPAN for latest release...\n";

    my $api_url = "https://fastapi.metacpan.org/v1/release/AmberDB";
    my $json_text;

    my $http = HTTP::Tiny->new( timeout => 8, verify_SSL => 1 );
    my $res  = $http->get($api_url);
    if ( $res && $res->{success} ) {
        $json_text = $res->{content};
    }
    else {
        if ( $^O eq 'MSWin32' || $^O eq 'msys' || $^O eq 'cygwin' ) {
            $json_text = `powershell -NoProfile -Command "try { (Invoke-WebRequest -Uri '$api_url' -UseBasicParsing).Content } catch {}"`;
        }
        else {
            $json_text = `curl -s -L "$api_url" 2>/dev/null`;
        }
    }

    my $latest_version;
    if ( $json_text ) {
        my $data = eval { decode_json($json_text) };
        $latest_version = $data->{version} if $data && ref($data) eq 'HASH';
    }

    if ( !defined $latest_version || $latest_version eq '' ) {
        print "[WARNING] Could not retrieve release information from MetaCPAN (offline or API unavailable).\n";
        print "You can manually verify or install via: cpanm AmberDB\n";
        print "=================================================================\n";
        return;
    }

    print "Latest MetaCPAN Version: $latest_version\n";
    print "-----------------------------------------------------------------\n";

    my $v_curr = eval { version->parse($AmberDB::VERSION) };
    my $v_late = eval { version->parse($latest_version) };

    if ( $v_curr && $v_late && $v_curr >= $v_late ) {
        print "[OK] AmberDB engine is up to date (v$AmberDB::VERSION).\n";
        print "=================================================================\n";
        return;
    }

    print "[UPDATE AVAILABLE] AmberDB can be updated from v$AmberDB::VERSION to v$latest_version.\n";

    if ( $opt_check ) {
        print "[CHECK MODE] Skipping package installation.\n";
        print "=================================================================\n";
        return;
    }

    my $cpanm_cmd = $opt_cpanm;
    if ( !$cpanm_cmd ) {
        my $has_cpanm = `where cpanm 2>nul` || `which cpanm 2>/dev/null`;
        if ( $has_cpanm ) {
            $cpanm_cmd = 'cpanm';
        }
        else {
            my $has_cpan = `where cpan 2>nul` || `which cpan 2>/dev/null`;
            $cpanm_cmd = 'cpan' if $has_cpan;
        }
    }

    if ( $cpanm_cmd ) {
        print "Launching installer via '$cpanm_cmd AmberDB'...\n";
        my $exit_code = system( $cpanm_cmd, "AmberDB" );
        if ( $exit_code == 0 ) {
            print "[SUCCESS] AmberDB engine updated successfully to latest CPAN release.\n";
        }
        else {
            print "[WARNING] Installer exited with status $exit_code. You can run '$cpanm_cmd AmberDB' manually.\n";
        }
    }
    else {
        print "[INFO] Neither 'cpanm' nor 'cpan' executable was detected in PATH.\n";
        print "Please run the following command to update AmberDB:\n";
        print "  cpanm AmberDB\n";
    }
    print "=================================================================\n";
}

sub action_update_storage {
    print "=================================================================\n";
    print " AmberDB Storage, Directory & Compatibility Migration Engine     \n";
    print "=================================================================\n";
    print "Database Directory : $target_dir\n";

    my $config_dir = File::Spec->catdir( $target_dir, "config" );
    my $ver_file   = File::Spec->catfile( $config_dir, "storage_version.json" );

    # 1. Inspect existing storage version
    my $current_storage_ver;
    if ( -e $ver_file ) {
        if ( open my $fh, '<', $ver_file ) {
            local $/;
            my $content = <$fh>;
            close $fh;
            my $data = eval { decode_json($content) };
            if ( $data && $data->{storage_version} ) {
                $current_storage_ver = $data->{storage_version};
            }
        }
    }

    if ( !defined $current_storage_ver || $current_storage_ver eq '' ) {
        # Check presence of legacy scheme or tables directory
        if ( -d File::Spec->catdir( $target_dir, "scheme" ) ) {
            $current_storage_ver = "5.20.0";
        }
        elsif ( -d File::Spec->catdir( $target_dir, "tables" ) && !-d File::Spec->catdir( $target_dir, "table" ) ) {
            $current_storage_ver = "5.21.0";
        }
        else {
            $current_storage_ver = "5.21.0";
        }
    }

    print "Current Storage Version   : v$current_storage_ver\n";

    # 2. Load Roadmap / Manifest (Online or Local Fallback)
    my $target_storage_ver = "5.25.0";
    my $manifest;

    my $manifest_url = $opt_manifest || "https://raw.githubusercontent.com/marufcetin/amberdb/main/migrations/manifest.json";
    my $json_manifest;

    my $http = HTTP::Tiny->new( timeout => 5, verify_SSL => 1 );
    my $m_res = $http->get($manifest_url);
    if ( $m_res && $m_res->{success} ) {
        $json_manifest = $m_res->{content};
    }
    elsif ( $^O eq 'MSWin32' || $^O eq 'msys' || $^O eq 'cygwin' ) {
        $json_manifest = `powershell -NoProfile -Command "try { (Invoke-WebRequest -Uri '$manifest_url' -UseBasicParsing).Content } catch {}"`;
    }
    else {
        $json_manifest = `curl -s -L "$manifest_url" 2>/dev/null`;
    }

    if ( $json_manifest ) {
        $manifest = eval { decode_json($json_manifest) };
    }

    if ( !$manifest || ref($manifest) ne 'HASH' || !$manifest->{current_storage_version} ) {
        my $local_manifest_file = File::Spec->catfile( $project_dir, "migrations", "manifest.json" );
        if ( -e $local_manifest_file && open my $lfh, '<', $local_manifest_file ) {
            local $/;
            my $lcont = <$lfh>;
            close $lfh;
            $manifest = eval { decode_json($lcont) };
        }
    }

    if ( $manifest && $manifest->{current_storage_version} ) {
        $target_storage_ver = $manifest->{current_storage_version};
    }

    print "Target Storage Version    : v$target_storage_ver\n";
    print "-----------------------------------------------------------------\n";

    my $v_curr = eval { version->parse($current_storage_ver) };
    my $v_targ = eval { version->parse($target_storage_ver) };

    if ( $v_curr && $v_targ && $v_curr >= $v_targ && !$opt_force ) {
        print "[OK] Storage format is already at latest version ($current_storage_ver).\n";
        print "     Use --force to rewrite and re-index existing tables.\n";
        print "=================================================================\n";
        return;
    }

    if ( $opt_check ) {
        print "[CHECK MODE] Storage migration from v$current_storage_ver to v$target_storage_ver is pending.\n";
        if ( $v_curr < version->parse('5.21.0') ) {
            print "  - [v5.21.0] Directory migration: Rename scheme/ -> schema/\n";
        }
        if ( $v_curr < version->parse('5.25.0') || $opt_force ) {
            print "  - [v5.25.0] Directory migration: Rename tables/ -> table/\n";
            print "  - [v5.25.0] Format migration: Convert legacy records to ABR v5 binary pack\n";
            print "  - [v5.25.0] Index migration: Rebuild all secondary indexes (.inx, .fld, .unq, .fac, .slg, .srt)\n";
        }
        print "=================================================================\n";
        return;
    }

    my $adb = AmberDB->new( path => { dbase_dir => $target_dir } );
    my $tools = AmberDB::Tools->new($adb);

    # 3. Pre-migration Safety Snapshot (unless --no-backup)
    if ( !$opt_no_backup ) {
        print "Taking pre-migration safety snapshot...\n";
        my $backup_file = File::Spec->catfile( $target_dir, "backup_pre_storage_update_" . time() . ".amberdb" );
        eval {
            $tools->dump( file => $backup_file );
        };
        if ( -e $backup_file && -s $backup_file ) {
            print "  [+] Safety snapshot created: $backup_file\n";
        }
        else {
            print "  [INFO] Snapshot skipped or empty database.\n";
        }
    }

    # 4. Stage v5.21.0 Migration: Rename scheme -> schema
    if ( $v_curr < version->parse('5.21.0') ) {
        print "\n>>> [Stage v5.21.0 Migration] Scheme to Schema Directory Renaming...\n";
        my $m521 = File::Spec->catfile( $project_dir, "migrations", "versions", "5.21.0", "migrate.pl" );
        if ( -f $m521 ) {
            eval {
                do $m521;
                migrate_5_21_0( target_dir => $target_dir );
            };
            if ($@) {
                print "  [!] External script warning: $@\n";
                _inline_migrate_5_21_0($target_dir);
            }
        }
        else {
            _inline_migrate_5_21_0($target_dir);
        }
    }

    # 5. Stage v5.25.0 Migration: tables -> table, ABR v5 format & complete re-indexing
    if ( $v_curr < version->parse('5.25.0') || $opt_force ) {
        print "\n>>> [Stage v5.25.0 Migration] Tables to Table, ABR v5 Binary Pack & Index Rebuild...\n";
        my $m525 = File::Spec->catfile( $project_dir, "migrations", "versions", "5.25.0", "migrate.pl" );
        if ( -f $m525 ) {
            eval {
                do $m525;
                migrate_5_25_0(
                    target_dir => $target_dir,
                    force      => $opt_force,
                    tables     => $opt_tables,
                );
            };
            if ($@) {
                print "  [!] External script warning: $@\n";
                _inline_migrate_5_25_0($target_dir);
            }
        }
        else {
            _inline_migrate_5_25_0($target_dir);
        }
    }

    # 6. Synchronize standard directory layout
    print "\nSynchronizing standard directory layout...\n";
    my @dirs = (
        File::Spec->catdir( $target_dir, "table" ),
        File::Spec->catdir( $target_dir, "schema" ),
        File::Spec->catdir( $target_dir, "journal" ),
        File::Spec->catdir( $target_dir, "lock" ),
        File::Spec->catdir( $target_dir, "session" ),
        File::Spec->catdir( $target_dir, "config" ),
        File::Spec->catdir( $target_dir, "ramdisk" ),
    );
    for my $d (@dirs) {
        if ( !-d $d ) {
            make_path($d);
            print "  [+] Created $d\n";
        }
    }

    # 7. Stamp storage version
    make_path($config_dir) unless -d $config_dir;
    if ( open my $fh, '>', $ver_file ) {
        my $stamp = {
            storage_version => $target_storage_ver,
            amberdb_engine  => $AmberDB::VERSION,
            record_format   => "abr_v5",
            encoding        => "utf-8",
            last_updated    => scalar localtime,
        };
        print $fh encode_json($stamp);
        close $fh;
        print "\n[OK] Storage version stamped as v$target_storage_ver in $ver_file\n";
    }

    print "=================================================================\n";
    print " Storage migration completed successfully!                      \n";
    print "=================================================================\n";
}

sub _inline_migrate_5_21_0 {
    my ($tdir) = @_;
    my $scheme_dir = File::Spec->catdir($tdir, 'scheme');
    my $schema_dir = File::Spec->catdir($tdir, 'schema');

    if (-d $scheme_dir) {
        if (!-d $schema_dir) {
            if (rename($scheme_dir, $schema_dir)) {
                print "  [v5.21.0] Renamed '$scheme_dir' -> '$schema_dir'\n";
            }
            else {
                make_path($schema_dir);
                opendir(my $dh, $scheme_dir) or die "Cannot open $scheme_dir: $!";
                my $moved = 0;
                while (my $f = readdir($dh)) {
                    next if $f eq '.' || $f eq '..';
                    move(File::Spec->catfile($scheme_dir, $f), File::Spec->catfile($schema_dir, $f));
                    $moved++;
                }
                closedir($dh);
                rmdir($scheme_dir);
                print "  [v5.21.0] Moved $moved file(s) from '$scheme_dir' -> '$schema_dir'\n";
            }
        }
        else {
            opendir(my $dh, $scheme_dir) or die "Cannot open $scheme_dir: $!";
            my $moved = 0;
            while (my $f = readdir($dh)) {
                next if $f eq '.' || $f eq '..';
                my $src = File::Spec->catfile($scheme_dir, $f);
                my $dst = File::Spec->catfile($schema_dir, $f);
                if (!-e $dst) {
                    move($src, $dst);
                    $moved++;
                }
            }
            closedir($dh);
            rmdir($scheme_dir);
            print "  [v5.21.0] Merged $moved file(s) from '$scheme_dir' into '$schema_dir'\n";
        }
    }
    else {
        make_path($schema_dir) unless -d $schema_dir;
        print "  [v5.21.0] Verified schema directory '$schema_dir'\n";
    }
}

sub _inline_migrate_5_25_0 {
    my ($tdir, %opts) = @_;
    my $tables_dir = File::Spec->catdir($tdir, 'tables');
    my $table_dir  = File::Spec->catdir($tdir, 'table');

    # 1. Rename tables to table
    if (-d $tables_dir) {
        if (!-d $table_dir) {
            if (rename($tables_dir, $table_dir)) {
                print "  [v5.25.0] Renamed directory: '$tables_dir' -> '$table_dir'\n";
            }
            else {
                make_path($table_dir);
                opendir(my $dh, $tables_dir) or die "Cannot open $tables_dir: $!";
                my $moved = 0;
                while (my $f = readdir($dh)) {
                    next if $f eq '.' || $f eq '..';
                    move(File::Spec->catfile($tables_dir, $f), File::Spec->catfile($table_dir, $f));
                    $moved++;
                }
                closedir($dh);
                rmdir($tables_dir);
                print "  [v5.25.0] Moved $moved file(s) from '$tables_dir' -> '$table_dir'\n";
            }
        }
        else {
            opendir(my $dh, $tables_dir) or die "Cannot open $tables_dir: $!";
            my $moved = 0;
            my $date_stamp = $opts{date_stamp};
            if (!$date_stamp) {
                my ($sec, $min, $hour, $mday, $mon, $year) = localtime();
                $date_stamp = sprintf("%04d-%02d-%02d", $year + 1900, $mon + 1, $mday);
            }

            while (my $f = readdir($dh)) {
                next if $f eq '.' || $f eq '..';
                my $src = File::Spec->catfile($tables_dir, $f);
                my $dst = File::Spec->catfile($table_dir, $f);
                if (!-e $dst) {
                    if (move($src, $dst)) {
                        $moved++;
                    }
                    else {
                        warn "  [!] Failed to move '$src' -> '$dst': $!\n";
                    }
                }
                else {
                    # Conflict: file already exists in table/. Append date stamp.
                    # e.g., catalog_product_2026-08-25.db, catalog_product_2026-08-25.inx
                    my ($base, $ext) = ( $f =~ /^(.*?)(\.[^.]+)$/ );
                    my $stamped_name = (defined $base && length $base)
                        ? "${base}_${date_stamp}${ext}"
                        : "${f}_${date_stamp}";

                    my $stamped_dst = File::Spec->catfile($table_dir, $stamped_name);
                    if (-e $stamped_dst) {
                        my $counter = 1;
                        while (-e $stamped_dst) {
                            my $suffixed = (defined $base && length $base)
                                ? "${base}_${date_stamp}_${counter}${ext}"
                                : "${f}_${date_stamp}_${counter}";
                            $stamped_dst = File::Spec->catfile($table_dir, $suffixed);
                            $counter++;
                        }
                    }

                    if (move($src, $stamped_dst)) {
                        $moved++;
                    }
                    else {
                        warn "  [!] Failed to move '$src' -> '$stamped_dst': $!\n";
                    }
                }
            }
            closedir($dh);
            rmdir($tables_dir);
            print "  [v5.25.0] Merged $moved file(s) from '$tables_dir' into '$table_dir'\n";
        }
    }
    else {
        make_path($table_dir) unless -d $table_dir;
        print "  [v5.25.0] Verified table directory '$table_dir'\n";
    }

    # 2. Convert legacy table records to ABR v5
    # Always create fresh AmberDB instance after renaming directories
    my $adb = AmberDB->new( path => { dbase_dir => $tdir } );
    my $tools = AmberDB::Tools->new($adb);
    my @target_tables;
    if ($opt_tables) {
        @target_tables = split /,/, $opt_tables;
    }
    elsif (@ARGV) {
        @target_tables = @ARGV;
    }
    else {
        @target_tables = $tools->all_tables();
    }

    if (@target_tables) {
        print "  [v5.25.0] Upgrading legacy table formats to native ABR v5...\n";
        for my $tbl (@target_tables) {
            $tbl =~ s/^\s+|\s+$//g;
            next unless $tbl;

            print "    - Migrating table '$tbl' ... ";
            my $res = $tools->update_table( $tbl, force => $opt_force );
            if (!$res || $res->{status} eq 'error') {
                my $err = $res->{error} // 'Unknown error';
                print "FAILED! ($err)\n";
            }
            elsif ($res->{status} eq 'already_current') {
                print "ALREADY CURRENT ABR v5 (" . ($res->{already_current} // 0) . " records)\n";
            }
            elsif ($res->{status} eq 'updated') {
                print "MIGRATED! ($res->{total} records, format: $res->{dominant_format})\n";
            }
            else {
                print "OK\n";
            }
        }

        # 3. Rebuild all secondary binary indexes
        print "  [v5.25.0] Rebuilding all derived secondary binary indexes...\n";
        action_reindex();
    }
    else {
        print "  [v5.25.0] No tables found to migrate in '$tdir'.\n";
    }
}

sub action_backup {
    my $adb = AmberDB->new( path => { dbase_dir => $target_dir } );
    my $tools = AmberDB::Tools->new($adb);

    print "=================================================================\n";
    print " AmberDB Native Backup & Disaster Recovery Engine               \n";
    print "=================================================================\n";
    print "Database Directory : $target_dir\n";

    if ($opt_dump) {
        my %opts;
        $opts{file} = $opt_file if $opt_file;
        if ($opt_tables) {
            my @tbls = split /,/, $opt_tables;
            $opts{tables} = \@tbls;
            print "Target Tables      : " . join(", ", @tbls) . "\n";
        }
        else {
            print "Target Tables      : [All Database Tables]\n";
        }
        print "Starting database dump...\n";

        my ($outfile, $manifest) = $tools->dump(%opts);
        if ($outfile && -e $outfile) {
            my $size = -s $outfile;
            my $table_count = scalar(keys %{ $manifest->{tables} || {} });
            print "\n[SUCCESS] Dump completed successfully!\n";
            print "Archive File       : $outfile\n";
            print "Archive Size       : $size bytes\n";
            print "Archived Tables    : $table_count tables\n";
            print "AmberDB Version    : $manifest->{amberdb_version}\n";
        }
        else {
            die "\n[ERROR] Database dump failed.\n";
        }
    }
    elsif ($opt_restore) {
        unless ($opt_file) {
            die "Error: --restore requires --file=<archive.amberdb>\n";
        }
        unless (-e $opt_file) {
            die "Error: Archive file '$opt_file' not found.\n";
        }

        my %opts = (
            file    => $opt_file,
            force   => $opt_force ? 1 : 0,
            reindex => $opt_reindex ? 1 : 0,
        );
        if ($opt_tables) {
            my @tbls = split /,/, $opt_tables;
            $opts{tables} = \@tbls;
            print "Restoring Tables   : " . join(", ", @tbls) . "\n";
        }
        else {
            print "Restoring Tables   : [All Tables in Archive]\n";
        }
        print "Archive File       : $opt_file\n";
        print "Force Overwrite    : " . ($opt_force ? "Yes" : "No") . "\n";
        print "Rebuild Indexes    : " . ($opt_reindex ? "Yes" : "No") . "\n";
        print "Starting database restore...\n";

        my $res = $tools->restore(%opts);
        if ($res && $res->{ok}) {
            my $table_count = scalar(@{ $res->{tables} || [] });
            print "\n[SUCCESS] Database restore completed successfully!\n";
            print "Restored Tables    : $table_count (" . join(", ", @{ $res->{tables} }) . ")\n";
            print "Indexes Rebuilt    : " . ($res->{reindexed} ? "Yes (Fresh secondary indexes)" : "Skipped") . "\n";
        }
        else {
            die "\n[ERROR] Database restore failed. Target directory may not be empty (use --force).\n";
        }
    }
    else {
        die "Error: --action=backup requires either --dump or --restore.\n";
    }
    print "=================================================================\n";
}

sub action_reindex {
    print "=================================================================\n";
    print " AmberDB Binary Index Re-Indexer                                \n";
    print "=================================================================\n";
    print "Database Directory : $target_dir\n";

    my $table_dir = File::Spec->catdir($target_dir, "table");
    die "Error: Table directory '$table_dir' does not exist.\n" unless -d $table_dir;

    my $adb = AmberDB->new( path => { dbase_dir => $target_dir } );
    my $tools = AmberDB::Tools->new($adb);

    my @table_list;
    if ($opt_tables) {
        @table_list = split /,/, $opt_tables;
    }
    else {
        @table_list = $tools->all_tables();
    }

    print "Found " . scalar(@table_list) . " table(s) to re-index.\n";
    print "-----------------------------------------------------------------\n";

    require Time::HiRes;
    my $total_t0 = Time::HiRes::time();
    my $reindex_count = 0;

    for my $tableid (@table_list) {
        $tableid =~ s/^\s+|\s+$//g;
        next unless $tableid;

        print "Re-indexing table: $tableid ... ";
        my $t0 = Time::HiRes::time();
        eval {
            $tools->set_index($tableid);
            my $elapsed = sprintf( "%.2f", Time::HiRes::time() - $t0 );
            my $rec_count = eval { $adb->table_count($tableid) } // eval { scalar($adb->table_keys($tableid)) } // 0;
            print "OK (${elapsed}s, $rec_count records)\n";
            $reindex_count++;
        };
        if ($@) {
            my $elapsed = sprintf( "%.2f", Time::HiRes::time() - $t0 );
            print "FAILED! (${elapsed}s) ($@)\n";
        }
    }
    my $total_elapsed = sprintf( "%.2f", Time::HiRes::time() - $total_t0 );
    print "-----------------------------------------------------------------\n";
    print "Completed re-indexing $reindex_count table(s) in ${total_elapsed}s.\n";
    print "=================================================================\n";
}

sub action_cron {
    my $platform = ( $^O eq 'MSWin32' || $^O eq 'msys' || $^O eq 'cygwin' ) ? 'windows'
                 : ( $^O eq 'darwin' ) ? 'macos' : 'linux';

    if ( $platform eq 'windows' ) {
        my $ps1_path = File::Spec->catfile( $script_dir, "setup_windows.ps1" );
        die "[ERROR] Missing Windows setup script: $ps1_path\n" unless -e $ps1_path;
        system(qq{powershell -NoProfile -ExecutionPolicy Bypass -File "$ps1_path" -Action cron-install -ProjectName "$project_name" -ProjectDir "$target_dir"});
    }
    elsif ( $platform eq 'macos' ) {
        my $sh_path = File::Spec->catfile( $script_dir, "setup_macos.sh" );
        die "[ERROR] Missing macOS setup script: $sh_path\n" unless -e $sh_path;
        system(qq{bash "$sh_path" cron-install "$opt_user" "$project_name"});
    }
    else {
        my $sh_path = File::Spec->catfile( $script_dir, "setup_linux.sh" );
        die "[ERROR] Missing Linux setup script: $sh_path\n" unless -e $sh_path;
        if ( $> != 0 ) {
            print "[INFO] Setting up system cron watchdog may require root. Invoking sudo if needed...\n";
            system("sudo", "bash", $sh_path, "cron-install", $opt_user || '', $project_name);
        }
        else {
            system("bash", $sh_path, "cron-install", $opt_user || '', $project_name);
        }
    }
}

sub action_service {
    my $platform = ( $^O eq 'MSWin32' || $^O eq 'msys' || $^O eq 'cygwin' ) ? 'windows'
                 : ( $^O eq 'darwin' ) ? 'macos' : 'linux';

    if ( $platform eq 'windows' ) {
        my $ps1_path = File::Spec->catfile( $script_dir, "setup_windows.ps1" );
        die "[ERROR] Missing Windows setup script: $ps1_path\n" unless -e $ps1_path;
        system(qq{powershell -NoProfile -ExecutionPolicy Bypass -File "$ps1_path" -Action service-install -ProjectName "$project_name" -ProjectDir "$target_dir"});
    }
    elsif ( $platform eq 'macos' ) {
        my $sh_path = File::Spec->catfile( $script_dir, "setup_macos.sh" );
        die "[ERROR] Missing macOS setup script: $sh_path\n" unless -e $sh_path;
        system(qq{bash "$sh_path" service-install "$opt_user" "$project_name"});
    }
    else {
        my $sh_path = File::Spec->catfile( $script_dir, "setup_linux.sh" );
        die "[ERROR] Missing Linux setup script: $sh_path\n" unless -e $sh_path;
        if ( $> != 0 ) {
            print "[INFO] Installing systemd service requires root privileges. Invoking sudo...\n";
            system("sudo", "bash", $sh_path, "service-install", $opt_user || '', $project_name);
        }
        else {
            system("bash", $sh_path, "service-install", $opt_user || '', $project_name);
        }
    }
}

sub show_usage {
    print <<"USAGE";
=================================================================
 AmberDB Consolidated Setup, Provisioning & Maintenance Engine
=================================================================

Usage:
  perl bin/amberdb_setup.pl --action=<action> [options]

Actions:
  update            Run comprehensive update (AmberDB engine via CPAN + storage migrations)
  update-amberdb    Check and update AmberDB core engine distribution via CPAN
  update-storage    Migrate database directory layout, ABR format, UTF-8 and indexes
  updatedb          Alias for update-storage
  install, setup    Full infrastructure setup (dirs, user permissions, RAM-disk, cron)
  ramdisk           RAM-disk mount/unmount and status management
  backup            Dump (.amberdb) or restore database archives
  reindex           Rebuild and pack all derived secondary binary indexes
  cron              Install / inspect self-healing watchdog in crontab
  service           Generate systemd service unit for background sync daemon
  usage, help       Show this help message

Options:
  --user NAME         System user for file ownership (e.g. eticaretim, www-data)
  --group NAME        System group for file ownership (default: user primary group)
  --size SIZE         RAM-disk size (e.g. 256M, 512M, 1G - default: 512M)
  --dbase_dir PATH    Target AmberDB database root directory (default: ./dbase)
  --no-cron           Skip configuring cron watchdog entry during install
  --service           Automatically configure systemd service unit during install

Update Options (--action=update, update-amberdb, update-storage):
  --check             Check for pending engine or storage updates without applying
  --no-backup         Skip pre-migration safety snapshot (.amberdb)
  --manifest URL      Custom URL or path for storage migration roadmap manifest
  --cpanm PATH        Custom path or executable name for CPAN installer (default: cpanm)
  --force             Force table migration and index rewrite even if up-to-date
  --all               Process all detected database tables
  --tables T1,T2      Target specific comma-separated tables

RAM-Disk Options (--action=ramdisk):
  --start             Mount and initialize RAM-disk storage
  --stop              Unmount and clean RAM-disk storage
  --status            Inspect RAM-disk mount status and capacity
  --size SIZE         RAM-disk size (default: 512M)
  --user NAME         System user for NTFS ACLs and folder ownership
  --drive DRIVE       Drive letter on Windows (default: R:)

Backup Options (--action=backup):
  --dump              Export database archive (.amberdb)
  --restore           Import database archive (.amberdb)
  --file PATH         Archive file path for dump or restore
  --force             Allow restore into non-empty directory

Examples:
  perl bin/amberdb_setup.pl --action=update
  perl bin/amberdb_setup.pl --action=update-amberdb --check
  perl bin/amberdb_setup.pl --action=update-storage --dbase_dir=./dbstore
  perl bin/amberdb_setup.pl --action=install --user=eticaretim --size=256M --cron
  perl bin/amberdb_setup.pl --action=ramdisk --start --size=512M
  perl bin/amberdb_setup.pl --action=backup --dump --file=backup/full.amberdb
  perl bin/amberdb_setup.pl --action=reindex
=================================================================
USAGE
}

1;
