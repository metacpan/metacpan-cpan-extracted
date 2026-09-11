package AmberDB::Base::Ramdisk;

use 5.016;
use warnings;
use Carp qw(croak cluck);
use Cwd qw(abs_path);
use Digest::MD5 qw(md5_hex);

our $VERSION = '5.25.1';

my $CREATED = '2026-08-11';

our %RAMDISK_TIERS = (
    '0'            => 0,
    'none'         => 0,
    'off'          => 0,
    'disk'         => 0,
    'disabled'     => 0,

    '1'            => 1,
    'index'        => 1,
    'indexes'      => 1,
    'indices'      => 1,
    'hybrid'       => 1,

    '2'            => 2,
    'dual'         => 2,
    'full'         => 2,
    'all'          => 2,
    'mirror'       => 2,
    'mirrored'     => 2,

    '3'            => 3,
    'temp'         => 3,
    'temporary'    => 3,
    'volatile'     => 3,
    'ephemeral'    => 3,
    'ram_only'     => 3,
    'memory_only'  => 3,

    '4'            => 4,
    'async'        => 4,
    'sync'         => 4,
    'delay'        => 4,
    'delayed'      => 4,
    'write_behind' => 4,
    'writeback'    => 4,
);

sub _normalize_ramdisk_tier {
    my ( $self, $val ) = @_;
    return 0 unless defined $val && length $val;
    my $key = lc("$val");
    $key =~ s/^\s+|\s+$//g;
    return exists $RAMDISK_TIERS{$key} ? $RAMDISK_TIERS{$key} : ( $key =~ /^\d+$/ ? int($key) : 0 );
}

# ============================================================================
# AmberDB Native .db and .inx RAM-Disk (Linux tmpfs / macOS APFS / Windows ImDisk) Engine
# Purely dedicated to physical RAM-Disk file-based acceleration
# ============================================================================

# Resolves root directory for ramdisk storage (typically mounted as tmpfs / APFS / ImDisk)
sub ramdisk_dir {
    my ($self) = @_;
    if ( length( $self->path('ramdisk_dir') // '' ) ) {
        return $self->path('ramdisk_dir');
    }
    my $ramdisk_dir = ( ( $self->path('dbase_dir') || "." ) . "/ramdisk" );
    $self->path( ramdisk_dir => $ramdisk_dir );
    return $ramdisk_dir;
}

# Backwards compatibility path accessors
sub ramdisk_tbl_dir {
    my ($self) = @_;
    return $self->{_path}->{table_rdir} // $self->path('table_rdir');
}

sub ramdisk_lock_dir {
    my ($self) = @_;
    return $self->{_path}->{lock_dir} || $self->path('lock_dir') || ( ( $self->path('dbase_dir') || "." ) . "/lock" );
}

sub ramdisk_schema_dir {
    my ($self) = @_;
    return $self->{_path}->{schema_rdir} // $self->path('schema_rdir');
}

sub ramdisk_session_dir {
    my ($self) = @_;
    return $self->{_path}->{session_dir} || $self->path('session_dir') || ( ( $self->path('dbase_dir') || "." ) . "/session" );
}

# $bool = $adb->ramdisk_is_mounted();
# Returns 1 if RAM-disk is mounted and ready, 0 otherwise.
# ------------------------------------------------
sub ramdisk_is_mounted {
    my ($self) = @_;
    return 1 if $ENV{AMBERDB_TEST_RAMDISK};
    if ( !defined $self->{_cfg}->{ramdisk_mounted} ) {
        my $info = $self->ramdisk_setup();
        $self->{_cfg}->{ramdisk_mounted} = $info->{is_mounted} ? 1 : 0;
    }
    return $self->{_cfg}->{ramdisk_mounted} ? 1 : 0;
}

# my $info = $adb->ramdisk_setup([$tableid]);
# Returns diagnostics, script paths, configured size, and RAM-disk mount status for Linux (tmpfs), macOS (APFS), and Windows (ImDisk).
# If optional $tableid is provided, verifies mount and preloads/ensures the table on RAM-disk.
# ------------------------------------------------
sub ramdisk_setup {
    my ( $self, $tableid ) = @_;

    my $ramdisk_dir = ( length( $self->path('ramdisk_dir') // '' ) )
      ? $self->path('ramdisk_dir')
      : ( ( $self->path('dbase_dir') || "." ) . "/ramdisk" );
    $ramdisk_dir =~ s{[\\/]+$}{};

    my $disk_size   = $self->config('ramdisk_size') // '512M';

    my $is_win      = ( $^O eq 'MSWin32' || $^O eq 'msys' || $^O eq 'cygwin' );
    my $is_mac      = ( $^O eq 'darwin' );

    my $bin_dir     = ( $self->path('dbase_dir') || "." ) . "/../bin";
    my $helper_pl   = "$bin_dir/amberdb_setup.pl";
    my $helper_bat  = "$bin_dir/setup_windows.bat";
    my $helper_ps1  = "$bin_dir/setup_windows.ps1";
    my $helper_sh   = $is_mac ? "$bin_dir/setup_macos.sh" : "$bin_dir/setup_linux.sh";

    my $is_mounted  = 0;
    my $mount_desc  = "Local Storage (No RAM-disk active)";

    # Pure-Perl Linux kernel mount table verification (zero subprocess overhead)
    my $_is_linux_tmpfs = sub {
        my ($path) = @_;
        return 0 unless defined $path && -d $path;

        # Standard in-memory tmpfs spaces on Linux
        return 1 if $path =~ m{^/(?:dev/shm|run/user/\d+)(?:/|$)};

        my $real_target = eval { abs_path($path) } // $path;

        if ( open my $fh, '<', '/proc/mounts' ) {
            while ( my $line = <$fh> ) {
                my ( $dev, $mountpoint, $fstype ) = split( ' ', $line );
                next unless $fstype && ( $fstype eq 'tmpfs' || $fstype eq 'ramfs' );

                if ( $real_target eq $mountpoint || index( $real_target, "$mountpoint/" ) == 0 ) {
                    close $fh;
                    return 1;
                }
            }
            close $fh;
        }
        return 0;
    };

    # 1. Test environment simulation override
    if ( $ENV{AMBERDB_TEST_RAMDISK} ) {
        $is_mounted = 1;
        $mount_desc = "Test RAM-Disk Emulation ($ramdisk_dir)";
    }
    # 2. Symbolic Link or NTFS Junction Check (-l)
    elsif ( -l $ramdisk_dir && -d $ramdisk_dir ) {
        my $target = eval { readlink($ramdisk_dir) } // '';
        $target =~ s{[\\/]+$}{};

        if ( $is_win && ( $target =~ /^[a-zA-Z]:/ || $target =~ m{^/[a-zA-Z]/} ) ) {
            $is_mounted = 1;
            $mount_desc = "Linked RAM-Disk ($ramdisk_dir -> $target)";
        }
        elsif ( $is_mac && $target =~ m{^/Volumes/AmberDB_RAM} ) {
            $is_mounted = 1;
            $mount_desc = "Linked APFS RAM-Disk ($ramdisk_dir -> $target)";
        }
        elsif ( !$is_win && !$is_mac ) {
            if ( $_is_linux_tmpfs->( $target || $ramdisk_dir ) ) {
                $is_mounted = 1;
                $mount_desc = "Linked tmpfs ($ramdisk_dir -> $target)";
            }
        }
        else {
            $is_mounted = 1;
            $mount_desc = $target ? "Linked RAM-Disk ($ramdisk_dir -> $target)" : "Linked RAM-Disk ($ramdisk_dir)";
        }
    }
    # 3. Windows: Direct R: Drive Path
    elsif ( $is_win && ( $ramdisk_dir =~ /^[rR]:/i || $ramdisk_dir =~ m{^/[rR]/}i ) && -d $ramdisk_dir ) {
        $is_mounted = 1;
        $mount_desc = "ImDisk RAM-Disk on R: (Windows)";
    }
    # 4. macOS: Direct /Volumes/AmberDB_RAM Path
    elsif ( $is_mac && $ramdisk_dir =~ m{^/Volumes/AmberDB_RAM} && -d $ramdisk_dir ) {
        $is_mounted = 1;
        $mount_desc = "APFS RAM-Disk on /Volumes/AmberDB_RAM (macOS)";
    }
    # 5. Linux: Direct tmpfs/ramfs Mount or /dev/shm Path
    elsif ( !$is_win && !$is_mac && -d $ramdisk_dir ) {
        if ( $_is_linux_tmpfs->($ramdisk_dir) ) {
            $is_mounted = 1;
            $mount_desc = "tmpfs mountpoint on $ramdisk_dir (Linux)";
        }
    }

    my ( $tbl_dir, $schema_dir, $conf_dir ) = ( '', '', '' );

    # Populate and create RAM-disk paths ONLY if RAM-disk is confirmed mounted
    if ($is_mounted) {
        $tbl_dir    = ( length( $self->path('table_rdir') // '' ) )  ? $self->path('table_rdir')  : "$ramdisk_dir/table";
        $schema_dir = ( length( $self->path('schema_rdir') // '' ) ) ? $self->path('schema_rdir') : "$ramdisk_dir/schema";
        $conf_dir   = ( length( $self->path('conf_rdir') // '' ) )   ? $self->path('conf_rdir')   : "$ramdisk_dir/config";

        $self->{_path}->{ramdisk_dir} = $ramdisk_dir;
        $self->{_path}->{table_rdir}  = $tbl_dir;
        $self->{_path}->{schema_rdir} = $schema_dir;
        $self->{_path}->{conf_rdir}   = $conf_dir;

        # Repoint lock_dir and session_dir to RAM-disk
        $self->{_path}->{lock_dir}    = "$ramdisk_dir/lock";
        $self->{_path}->{session_dir} = "$ramdisk_dir/session";

        for my $dir ( $tbl_dir, $schema_dir, $conf_dir, $self->{_path}->{lock_dir}, $self->{_path}->{session_dir} ) {
            $self->make_path($dir);
        }
    }

    my $tbl_res = '';
    if ( defined $tableid && length $tableid && $is_mounted ) {
        $tbl_res = $self->ramdisk_ensure($tableid) // '';
    }

    return {
        os           => $^O,
        table        => $tbl_res,
        ramdisk_dir  => $ramdisk_dir,
        table_dir    => $tbl_dir,
        lock_dir     => $self->{_path}->{lock_dir},
        session_dir  => $self->{_path}->{session_dir},
        schema_dir   => $schema_dir,
        conf_dir     => $conf_dir,
        tbl_dir      => $tbl_dir,
        table_rdir   => $tbl_dir,
        schema_rdir  => $schema_dir,
        conf_rdir    => $conf_dir,
        ramdisk_size => $disk_size,
        is_mounted   => $is_mounted,
        mount_desc   => $mount_desc,
        script_pl    => $helper_pl,
        script_bat   => $helper_bat,
        script_ps1   => $helper_ps1,
        script_sh    => $helper_sh,
        instructions => $is_win
          ? "Run as Administrator: perl $helper_pl --action=ramdisk --start --size $disk_size"
          : "Run with sudo: sudo perl $helper_pl --action=ramdisk --start --size $disk_size",
    };
}

# my $ramdisk_path = $adb->ramdisk_path($tableid, [$with_ext]);
# Symmetric counterpart to table_path($tableid, [$with_ext]).
# Resolves root directory and base path for table in ramdisk/table/$tableid.
# Supports custom table_dir (e.g. table_dir => 'siparis', table_dir => '').
# ------------------------------------------------
sub ramdisk_path {
    my ( $self, $tableid, $with_ext ) = @_;

    $tableid = $self->sanitize_table($tableid);
    return "" unless defined $tableid && length $tableid;

    my $ramdisk_dir = $self->ramdisk_dir or return "";
    my $table_info  = $self->table_info($tableid);

    my $target_dir;
    if ( $table_info && exists $table_info->{table_dir} ) {
        my $tdir = $table_info->{table_dir};
        if ( defined $tdir && length $tdir ) {
            $tdir =~ s{^[\\/]+|[\\/]+$}{}g;
            $target_dir = "$ramdisk_dir/$tdir";
        }
        else {
            $target_dir = $ramdisk_dir;
        }
        $self->make_path($target_dir);
    }
    else {
        $target_dir = $self->{_path}->{table_rdir} || $self->path('table_rdir') || "$ramdisk_dir/table";
    }

    my $target  = "$target_dir/$tableid";

    return $target . ( $with_ext ? ".$self->{db_ext}" : "" );
}

# Returns target ramdisk file path (.db for records, .inx for meta/indexes)
sub ramdisk_file_for {
    my ( $self, $tableid, $key, $type ) = @_;

    $tableid = $self->sanitize_table($tableid);
    return unless defined $tableid && length $tableid;

    my $base_path = $self->ramdisk_path($tableid) or return;

    my $ext;
    if ( defined $type && $type ne '' ) {
        $ext = $type;
    }
    else {
        my $table_info = $self->table_info($tableid);
        my $is_simple  = $self->config('simple') || ( $table_info && $table_info->{use_simple} );

        if ( $is_simple || ( defined $key && $key =~ /^\d+$/ ) ) {
            $ext = $self->{db_ext} // 'db';
        }
        else {
            $ext = 'inx';
        }
    }

    my $target = "${base_path}.${ext}";
    return $target;
}

# Checks TTL expiration on ramdisk file.
# Strictly evaluated ONLY for Tier 3 (use_ramdisk => 3). Tiers 1 and 2 never expire.
# Unlinks expired file and returns 0.
sub _check_ramdisk_ttl {
    my ( $self, $tableid, $file_path ) = @_;
    return 1 unless -e $file_path;

    my $table_info  = $self->table_info($tableid);
    my $use_ramdisk = $table_info ? ( $table_info->{use_ramdisk} // 0 ) : 0;
    return 1 unless $use_ramdisk == 3;

    my $ttl = $table_info ? ( $table_info->{ramdisk_ttl} // 300 ) : 300;
    if ( defined $ttl && $ttl > 0 ) {
        my $mtime = ( stat($file_path) )[9];
        if ( defined $mtime && ( time() - $mtime ) > $ttl ) {
            $self->table_close($file_path);
            unlink $file_path;
            return 0;
        }
    }
    return 1;
}

my %RAMDISK_ENSURING;

# my $ramdisk_path = $adb->ramdisk_ensure($tableid);
# Ensures ramdisk for use_ramdisk => 1 or 2 is populated.
# Automatically triggers ramdisk_preload if files are absent.
# For Tier 3 (use_ramdisk => 3), checks TTL on RAM-disk .db without physical preloading.
# ------------------------------------------------
sub ramdisk_ensure {
    my ( $self, $tableid ) = @_;

    $tableid or return;
    return unless $self->ramdisk_is_mounted();
    return if $RAMDISK_ENSURING{$tableid};

    my $table_info  = $self->table_info($tableid);
    my $use_ramdisk = $table_info ? ( $table_info->{use_ramdisk} // 0 ) : 0;
    return unless $use_ramdisk;

    $RAMDISK_ENSURING{$tableid} = 1;

    my $ramdisk_path = $self->ramdisk_path($tableid);
    unless ( $ramdisk_path ) {
        delete $RAMDISK_ENSURING{$tableid};
        return;
    }

    # For use_ramdisk == 3: volatile pure RAM table.
    # Zero physical disk files, no preloading from physical disk!
    if ( $use_ramdisk == 3 ) {
        my $db_ext = $self->{db_ext} // 'db';
        my $ram_db = "$ramdisk_path.$db_ext";
        $self->_check_ramdisk_ttl( $tableid, $ram_db );
        delete $RAMDISK_ENSURING{$tableid};
        return $ramdisk_path;
    }

    my $table_path   = $self->table_path($tableid);
    my $needs_preload = 0;

    # For use_ramdisk == 2 or 4: ensure .db is present in RAM-disk
    # Note: Tiers 1, 2, and 4 do not expire via TTL as they are synchronized with physical disk.
    if ( $use_ramdisk == 2 || $use_ramdisk == 4 ) {
        my $db_ext = $self->{db_ext} // 'db';
        my $src_db = "$table_path.$db_ext";
        my $ram_db = "$ramdisk_path.$db_ext";
        if ( -e $src_db && !-e $ram_db ) {
            $needs_preload = 1;
        }
    }

    # For use_ramdisk >= 1: ensure all secondary & lookup index files are present
    unless ($needs_preload) {
        for my $ext ( qw( inx fld src fac unq slg ) ) {
            my $src_file = "$table_path.$ext";
            my $ram_file = "$ramdisk_path.$ext";
            if ( -e $src_file && !-e $ram_file ) {
                $needs_preload = 1;
                last;
            }
        }
    }

    if ($needs_preload) {
        $self->ramdisk_preload($tableid);
    }

    delete $RAMDISK_ENSURING{$tableid};
    return $ramdisk_path;
}

# my @data = $adb->ramdisk_read($tableid, $key, [$type]);
# Reads entry from ramdisk/$tableid.db (for numeric/records) or ramdisk/$tableid.inx (for meta/keys).
# ------------------------------------------------
sub ramdisk_read {
    my ( $self, $tableid, $key, $type ) = @_;

    $tableid or return;
    defined $key && $key ne '' or return;

    my $table_info = $self->table_info($tableid);
    my $use_ramdisk = $table_info ? ( $table_info->{use_ramdisk} // $table_info->{use_cache} // 0 ) : 0;
    return unless $use_ramdisk;

    $self->ramdisk_ensure($tableid);

    my $ramdisk_file = $self->ramdisk_file_for( $tableid, $key, $type ) or return;
    return unless -e $ramdisk_file;

    return unless $self->_check_ramdisk_ttl( $tableid, $ramdisk_file );

    my $res = $self->recs_get( $ramdisk_file, $key );
    return unless $res && defined $res->{$key} && $res->{$key} ne '';

    # Sliding TTL refresh on successful read for Tier 3
    if ( $use_ramdisk == 3 ) {
        utime( undef, undef, $ramdisk_file );
    }

    return $self->db_decode( $res->{$key} );
}

# my $ok = $adb->ramdisk_write($tableid, $key, @records);
# Writes entry to ramdisk/$tableid.db (for numeric/records) or ramdisk/$tableid.inx (for meta/keys).
# ------------------------------------------------
sub ramdisk_write {
    my ( $self, $tableid, $key, @records ) = @_;

    $tableid or return;
    defined $key && $key ne '' or return;
    return unless @records;

    my $table_info = $self->table_info($tableid);
    my $use_ramdisk = $table_info ? ( $table_info->{use_ramdisk} // $table_info->{use_cache} // 0 ) : 0;
    return unless $use_ramdisk;

    my $ramdisk_file = $self->ramdisk_file_for( $tableid, $key );
    my $encoded_val  = $self->db_encode(@records);

    $self->recs_put( $ramdisk_file, [ $key, $encoded_val ] );
    return 1;
}

# my $ok = $adb->ramdisk_delete($tableid, [$key], [$type]);
# Invalidates entry from ramdisk/$tableid.db / .inx or removes entire table ramdisk files.
# ------------------------------------------------
sub ramdisk_delete {
    my ( $self, $tableid, $key, $type ) = @_;

    $tableid or return;

    my $table_info = $self->table_info($tableid);
    my $use_ramdisk = $table_info ? ( $table_info->{use_ramdisk} // $table_info->{use_cache} // 0 ) : 0;
    return unless $use_ramdisk;

    if ( defined $key && $key ne '' ) {
        my $ramdisk_file = $self->ramdisk_file_for( $tableid, $key, $type );
        if ( $ramdisk_file && -e $ramdisk_file ) {
            $self->recs_del( $ramdisk_file, $key );
        }
    }
    else {
        my $ramdisk_path = $self->ramdisk_path($tableid) or return;
        my $db_ext       = $self->{db_ext} // 'db';

        foreach my $ext ( $db_ext, qw( inx fld src fac unq slg ) ) {
            my $file = "$ramdisk_path.$ext";
            if ( -e $file ) {
                $self->table_close($file);
                unlink $file;
            }
        }
    }

    return 1;
}

# my $ok = $adb->ramdisk_preload($tableid);
# Preloads records and metadata from table/ into ramdisk/ based on use_ramdisk (1: indexes, 2: data+indexes).
# Uses atomic temporary writes (.tmp.$$) to prevent multi-process race conditions.
# ------------------------------------------------
sub ramdisk_preload {
    my ( $self, $tableid ) = @_;

    $tableid or return;
    $tableid = $self->sanitize_table($tableid);
    return unless defined $tableid && length $tableid;

    my $table_info  = $self->table_info($tableid);
    my $use_ramdisk = $table_info ? ( $table_info->{use_ramdisk} // $table_info->{use_cache} // 0 ) : 0;
    return unless $use_ramdisk;
    return if $use_ramdisk == 3;

    my $tbl_dir = $self->{_path}->{table_rdir} || $self->path('table_rdir') or return;
    unless ( -d $tbl_dir ) {
        warn "[AMBERDB_RAMDISK] RAM-disk tables directory does not exist: $tbl_dir\n";
        return;
    }

    my $table_path   = $self->table_path($tableid);
    my $ramdisk_path = $self->ramdisk_path($tableid);
    my $db_ext       = $self->{db_ext} // 'db';

    my $_copy_atomic = sub {
        my ( $src_file, $dst_file ) = @_;
        return unless -e $src_file;

        require File::Copy;
        my $tmp_dst = "$dst_file.tmp.$$";
        unlink $tmp_dst if -e $tmp_dst;

        $self->table_close($src_file) if $self->{_db}->{$src_file};

        if ( File::Copy::copy( $src_file, $tmp_dst ) ) {
            $self->table_close($dst_file) if -e $dst_file && $self->{_db}->{$dst_file};
            unlink $dst_file if -e $dst_file;
            rename $tmp_dst, $dst_file;
        }
    };

    # 1. Preload data file .db only for use_ramdisk == 2 or 4
    if ( $use_ramdisk == 2 || $use_ramdisk == 4 ) {
        my $src_db = "$table_path.$db_ext";
        my $dst_db = "$ramdisk_path.$db_ext";
        $_copy_atomic->( $src_db, $dst_db );
    }

    # 2. Preload index & lookup files (.inx, .fld, .src, .fac, .unq, .slg) for use_ramdisk >= 1 and != 3
    if ( $use_ramdisk >= 1 && $use_ramdisk != 3 ) {
        foreach my $ext ( qw( inx fld src fac unq slg ) ) {
            my $src_file = "$table_path.$ext";
            my $dst_file = "$ramdisk_path.$ext";
            $_copy_atomic->( $src_file, $dst_file );
        }
    }

    return 1;
}

# ============================================================================
# Tier 4 (Async Write-Behind) Sync Event Tracking & Background Daemon Engine
# ============================================================================

# Returns absolute path to the sync events journal slot.
# ------------------------------------------------
sub ramdisk_sync_db_path {
    my ($self) = @_;
    return $self->journal_slot("sync_ramdisk");
}

# Marks a record dirty in the RAM-disk sync events journal.
# Formats entry as: [ 'recs', $tableid, $file_path, $rid, $action, $pos, $raw, time() ]
# Appends to $journal_dir/sync_ramdisk
# ------------------------------------------------
sub ramdisk_mark_dirty {
    my ( $self, $file_path, $rid, $action, $raw, $pos ) = @_;

    return unless defined $file_path && length $file_path;
    return unless defined $rid && length $rid;
    $action //= 'edit';

    return unless $self->ramdisk_is_mounted();

    my $db_ext = $self->{db_ext} // 'db';
    my ($fname) = $file_path =~ m{([^/\\:]+)$};
    $fname =~ s{\.\Q$db_ext\E$}{} if defined $fname;
    my $tableid = $fname // 'default';

    my $norm_action = ( $action eq '1' || $action eq 'add' || $action eq 'insert' ) ? 'add'
                    : ( $action eq '2' || $action eq 'edit' || $action eq 'modify' || $action eq 'update' ) ? 'edit'
                    : ( $action eq '3' || $action eq 'del' || $action eq 'delete' ) ? 'del'
                    : $action;

    # If raw payload not supplied and not a delete, fetch from RAM-disk
    if ( !defined $raw && $norm_action ne 'del' ) {
        my $ram_path = $tableid ? $self->ramdisk_path($tableid) : undef;
        my $ram_file = $ram_path ? "$ram_path.$db_ext" : undef;
        if ( $ram_file && -e $ram_file ) {
            my $rec_hash = $self->recs_get( $ram_file, $rid );
            $raw = $rec_hash ? $rec_hash->{$rid} : undef;
        }
    }

    $self->journal_append( 'sync_ramdisk', [ 'recs', $tableid, $file_path, $rid, $norm_action, $pos // '', $raw, time() ] );
    return 1;
}

# Removes dirty tracking marker for given record (used on immediate dual-write / txn commit).
# In the journal write-behind architecture, transactional writes bypass ramdisk_mark_dirty
# entirely via immediate dual-write. Retained as a harmless compatibility helper.
# ------------------------------------------------
sub ramdisk_unmark_dirty {
    my ( $self, $file_path, $rid ) = @_;
    return 1;
}

# Synchronizes pending dirty events from journal (sync_ramdisk) to persistent disk.
# If $target_table is specified, syncs only events matching that table.
# Atomically rotates active journal file: sync_ramdisk -> sync_ramdisk_${epoch}
# Processes all pending rotated journals, applies coalescing, and removes processed files.
# Returns number of synced events.
# ------------------------------------------------
sub ramdisk_sync {
    my ( $self, $target_table ) = @_;

    return 0 unless $self->ramdisk_is_mounted();

    # 1. Rotate active sync_ramdisk journal under lock
    $self->journal_rotate('sync_ramdisk');

    # 2. Scan for rotated journal files
    my @journal_files = $self->journal_scan('sync_ramdisk_');
    return 0 unless @journal_files;

    my $db_ext       = $self->{db_ext} // 'db';
    my $synced_count = 0;

    foreach my $jfile (@journal_files) {
        my @entries = $self->journal_read($jfile);
        next unless @entries;

        my ( @to_process, @to_keep );
        if ( defined $target_table && length $target_table ) {
            for my $e (@entries) {
                if ( ( $e->{tableid} // '' ) eq $target_table ) {
                    push @to_process, $e;
                }
                else {
                    push @to_keep, $e;
                }
            }
        }
        else {
            @to_process = @entries;
        }

        # If partial sync with target_table, re-queue events for other tables
        if (@to_keep) {
            my @re_entries = map {
                [ $_->{type}, $_->{tableid}, $_->{file_path}, $_->{key}, $_->{action}, $_->{pos}, $_->{payload}, $_->{epoch} ]
            } @to_keep;
            $self->journal_append( 'sync_ramdisk', @re_entries );
        }

        # 3. In-batch state machine coalescing
        # (add + edit) => add
        # (add + del)  => canceled (never touches persistent disk)
        # (edit + edit)=> edit
        # (edit + del) => del
        # (del + add)  => edit
        my %coalesced;
        my @ordered_keys;

        foreach my $entry (@to_process) {
            my $file_path = $entry->{file_path};
            my $rid       = $entry->{key};
            my $composite = "$file_path\0$rid";
            my $action    = $entry->{action};

            if ( !exists $coalesced{$composite} ) {
                push @ordered_keys, $composite;
                $coalesced{$composite} = {
                    entry  => $entry,
                    action => $action,
                    raw    => $entry->{payload},
                };
            }
            else {
                my $state      = $coalesced{$composite};
                my $old_action = $state->{action};

                if ( $old_action eq 'add' || $old_action eq '1' ) {
                    if ( $action eq 'edit' || $action eq '2' ) {
                        $state->{action} = 'add';
                        $state->{raw}    = $entry->{payload} if defined $entry->{payload};
                        $state->{entry}  = $entry;
                    }
                    elsif ( $action eq 'del' || $action eq '3' ) {
                        delete $coalesced{$composite};
                        @ordered_keys = grep { $_ ne $composite } @ordered_keys;
                    }
                }
                elsif ( $old_action eq 'edit' || $old_action eq '2' ) {
                    if ( $action eq 'edit' || $action eq '2' ) {
                        $state->{action} = 'edit';
                        $state->{raw}    = $entry->{payload} if defined $entry->{payload};
                        $state->{entry}  = $entry;
                    }
                    elsif ( $action eq 'del' || $action eq '3' ) {
                        $state->{action} = 'del';
                        $state->{raw}    = undef;
                        $state->{entry}  = $entry;
                    }
                }
                elsif ( $old_action eq 'del' || $old_action eq '3' ) {
                    if ( $action eq 'add' || $action eq '1' ) {
                        $state->{action} = 'edit';
                        $state->{raw}    = $entry->{payload} if defined $entry->{payload};
                        $state->{entry}  = $entry;
                    }
                }
            }
        }

        # 4. Flush coalesced events to persistent disk
        foreach my $composite (@ordered_keys) {
            my $state = $coalesced{$composite};
            next unless $state;

            my $entry      = $state->{entry};
            my $action     = $state->{action};
            my $raw        = $state->{raw};
            my $file_path  = $entry->{file_path};
            my $rid        = $entry->{key};
            my $tableid    = $entry->{tableid};
            my $table_info = $self->table_info($tableid);
            my $table_path = $self->table_path($tableid);
            my $ramdisk_path = $self->ramdisk_path($tableid);

            # If raw not present in journal payload, fetch from RAM-disk
            if ( !defined $raw && ( $action eq 'add' || $action eq 'edit' || $action eq '1' || $action eq '2' ) ) {
                my $ram_file = "$ramdisk_path.$db_ext";
                my $rec_hash = -e $ram_file ? $self->recs_get( $ram_file, $rid ) : undef;
                $raw = $rec_hash ? $rec_hash->{$rid} : undef;
            }

            if ( $action eq 'add' || $action eq 'edit' || $action eq '1' || $action eq '2' ) {
                if ( defined $raw ) {
                    # 1. Sync to persistent disk .db
                    if ( $self->table_write($file_path) ) {
                        $self->recs_put( $file_path, [ $rid, $raw ] );
                        $self->table_close($file_path);
                    }

                    # 2. Sync secondary index files on persistent disk
                    unless ( $self->config('simple') || ( $table_info && $table_info->{use_simple} ) ) {
                        my @decoded = ( $rid, $self->db_decode($raw) );
                        my @batch   = ( \@decoded );

                        # Base stream indexes
                        $self->records_add( $table_path, $table_info, $tableid, [$rid] );
                        $self->search_add( $table_path, $table_info, $tableid, \@batch );
                        $self->match_add( $table_path, $table_info, \@batch );
                        $self->sort_add( $table_path, $table_info, \@batch );
                        $self->unique_add( $table_path, $table_info, \@batch );
                        $self->slug_add( $table_path, $table_info, $tableid, \@batch ) if $table_info->{slug_block};

                        if ( $table_info->{use_junk} ) {
                            if ( $action eq 'add' || $action eq '1' ) {
                                my $is_junk = $self->junk_rules( $table_info, @decoded );
                                my $tier    = $is_junk ? 'B' : 'A';
                                $self->records_add( $table_path, $table_info, $tableid, [$rid], $tier );
                                $self->search_add( $table_path, $table_info, $tableid, \@batch, $tier );
                                $self->match_add( $table_path, $table_info, \@batch, $tier );
                                $self->sort_add( $table_path, $table_info, \@batch, $tier ) if $table_info->{sort_block};
                                $self->facet_add( $table_path, $table_info, \@batch ) if !$is_junk && $table_info->{use_facet};
                            }
                            else {
                                my @mod_pairs = ( [ $rid, [$rid], \@decoded ] );
                                $self->junk_transition( $table_path, $table_info, $tableid, \@mod_pairs );
                            }
                        }
                        else {
                            if ( $action eq 'add' || $action eq '1' ) {
                                $self->facet_add( $table_path, $table_info, \@batch ) if $table_info->{use_facet};
                            }
                            else {
                                my @mod_pairs = ( [ $rid, [$rid], \@decoded ] );
                                $self->facet_modify( $table_path, $table_info, \@mod_pairs ) if $table_info->{use_facet};
                            }
                        }
                    }
                }
            }
            elsif ( $action eq 'del' || $action eq '3' ) {
                # 1. Delete from persistent disk .db
                if ( -e $file_path && $self->table_write($file_path) ) {
                    $self->recs_del( $file_path, $rid );
                    $self->table_close($file_path);
                }

                # 2. Delete from secondary indexes on persistent disk
                unless ( $self->config('simple') || ( $table_info && $table_info->{use_simple} ) ) {
                    $self->records_del( $table_path, $table_info, [$rid], $tableid );
                    $self->search_del( $table_path, $table_info, $tableid, [ [$rid] ] );
                    $self->match_del( $table_path, $table_info, [ [$rid] ] );
                    $self->sort_del( $table_path, $table_info, [ [$rid] ] ) if $table_info->{sort_block};
                    $self->unique_del( $table_path, $table_info, [ [$rid] ] );
                    $self->slug_del( $table_path, $table_info, $tableid, [ [$rid] ] ) if $table_info->{slug_block};

                    if ( $table_info->{use_junk} ) {
                        $self->records_del( $table_path, $table_info, [$rid], $tableid, ['A', 'B'] );
                        $self->search_del( $table_path, $table_info, $tableid, [ [$rid] ], ['A', 'B'] );
                        $self->match_del( $table_path, $table_info, [ [$rid] ], ['A', 'B'] );
                        $self->sort_del( $table_path, $table_info, [ [$rid] ], ['A', 'B'] ) if $table_info->{sort_block};
                        $self->facet_del( $table_path, $table_info, [ [$rid] ] ) if $table_info->{use_facet};
                    }
                    else {
                        $self->facet_del( $table_path, $table_info, [ [$rid] ] ) if $table_info->{use_facet};
                    }
                }
            }

            $synced_count++;
        }

        # 5. Clean up processed rotated journal file and its lock
        $self->journal_delete($jfile);
    }

    return $synced_count;
}

# Flushes all pending dirty events across all tables to persistent disk.
# ------------------------------------------------
sub ramdisk_sync_all {
    my ($self) = @_;
    return $self->ramdisk_sync();
}

1;

__END__

=head1 NAME

AmberDB::Base::Ramdisk - Transparent Physical RAM-Disk Acceleration Engine for AmberDB

=head1 SYNOPSIS

  use AmberDB;

  # 1. Global RAM-Disk Configuration (Canonical words: none, index, dual, temp, async)
  my $adb = AmberDB->new(
      cfg  => { use_ramdisk => "index" },
      path => { dbase_dir   => "/var/data/amberdb" }
  );

  # Or change dynamically at runtime:
  $adb->config(use_ramdisk => "dual");

  # 2. Per-Table Configuration & Overrides
  $adb->table_attr("catalog_category", use_ramdisk => "dual");  # Tier 2 (Full Mirror)
  $adb->table_attr("user_cart",        use_ramdisk => "async"); # Tier 4 (Write-Behind)
  $adb->table_attr("audit_archive",    use_ramdisk => "none");  # Tier 0 (Disk only)

  # 3. Synchronize Tier 4 Dirty Events to Disk (e.g. background daemon)
  my $synced = $adb->ramdisk_sync_all();

  # 4. Standard Transparent Operations (No special methods needed)
  my @item = $adb->read_id("catalog_category", 12);
  $adb->insert_id("catalog_category", 0, @category_data);
  $adb->modify_id("catalog_category", 12, @updated_data);

=head1 DESCRIPTION

C<AmberDB::Base::Ramdisk> provides transparent physical RAM-disk acceleration for AmberDB tables and indexes. It orchestrates filesystem-level memory mirroring (Linux C<tmpfs>, macOS C<APFS RAM-Disk> via C<hdiutil>, or Windows C<ImDisk>) without requiring manual cache management.

All RAM-disk operations run automatically in the background and are controlled via the C<use_ramdisk> option using integer levels or canonical names:

=over 4

=item * B<Tier 0 (none / off / 0):> Standard persistent disk access.

=item * B<Tier 1 (index / 1):> Secondary index files (C<.inx>, C<.src>, C<.fld>, C<.fac>, C<.unq>, C<.slg>) are maintained in RAM-disk while master data (C<.db>) remains on persistent disk.

=item * B<Tier 2 (dual / full / 2):> Master data (C<.db>) and all index files are mirrored on RAM-disk. Reads run directly from memory at microsecond speeds; writes synchronously dual-write to both RAM-disk and persistent disk.

=item * B<Tier 3 (temp / ram_only / 3):> Transient simple key-value store with zero persistent disk files and sliding TTL expiration (C<ramdisk_ttl>). Configured strictly per-table.

=item * B<Tier 4 (async / delay / 4):> High-throughput write-behind tier. All reads and writes occur exclusively in RAM-disk. Writes register dirty events in C<sync_ramdisk> journal with automatic event coalescing. A single-writer background daemon flushes changes to persistent disk. During active transactions (C<transact_start>), Tier 4 automatically elevates to synchronous Dual-Write to guarantee strict durability and immediate rollback.

=back

Developers interact with accelerated tables using only standard AmberDB methods (C<read_id>, C<search_table>, C<insert_id>, C<modify_id>, C<delete_id>, etc.).

=cut
