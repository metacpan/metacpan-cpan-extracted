package AmberDB;

use 5.016;
use warnings;
use Fcntl qw(:DEFAULT :flock);
use DB_File;
use Carp qw(croak cluck);
use Hash::Util qw(lock_keys lock_value);
use parent qw(
    AmberDB::Base
    AmberDB::Base::Schema
    AmberDB::Base::Encoder
    AmberDB::Base::Index
    AmberDB::Base::Facet
    AmberDB::Base::Junk
    AmberDB::Base::Transact
    AmberDB::Base::Cache
    AmberDB::Base::Ramdisk
    AmberDB::Array
    AmberDB::Date
    AmberDB::Locale
);

our $DB_HASH;
our $hash_info;

our $VERSION = '5.25.1';
my $CREATED = '2005-01-28';


# ------------------------------------------------
sub new {

    my $class = shift;
    my %input = ref( $_[0] ) eq "HASH" ? %{ $_[0] } : @_;

    # Load input values.
    my $self = bless {}, $class;
    foreach ( keys %input ) {
        $self->{$_} = $input{$_};
    }

    # Map public input keys to internal private keys
    $self->{_cfg}  = delete $self->{cfg}  // $self->{_cfg}  // {};
    $self->{_path} = delete $self->{path} // $self->{_path} // {};

    $self->{_dbase} ||= {};
    $self->{_table} ||= {};
    $self->{_cache} ||= {};
    $self->{_auth}  ||= {};
    $self->{_pid}   ||= {};
    $self->{_cfg}->{user}     ||= "user_system";
    $self->{_cfg}->{language} ||= "gb";
    if ( defined $self->{_cfg}->{use_ramdisk} ) {
        $self->{_cfg}->{use_ramdisk} = $self->_normalize_ramdisk_tier( $self->{_cfg}->{use_ramdisk} );
        if ( $self->{_cfg}->{use_ramdisk} == 3 ) {
            $self->{_cfg}->{use_ramdisk} = 0;
        }
    }

    # data path for database.
    $self->{_path}->{dbase_dir}  ||= ".";
    $self->{_path}->{dbase_dir}  =~ s{[/\\]+$}{};

    # file extensions
    # -----------------------------
    # inx: all records and lastid keys index file
    # src: search keys index file
    # fld: block matching index file
    # slg: url slug map
    # del: deleted records file
    # lnk: linked records file
    $self->{db_ext} ||= $self->{ext}->{db} ||= "db";

    # Transaction state (opt-in — transact_start çağrılmadıkça pasif)
    $self->{_txn} = undef;

    # MSYS2, MSWin32 (Strawberry), for msys or cygwin environments captures
    if ( $^O =~ /win|msys|cygwin/i ) {
        $hash_info = new DB_File::HASHINFO;
        $hash_info->{cachesize} =
          32 * 1024 * 1024;    # 32 MB Cache for development environment
    }
    else {
        # default performant structure for Linux (Ubuntu/CentOS) etc. systems
        $hash_info = $DB_HASH;
    }

    bless $self, $class;

    # Initialise locale engine — reads _cfg->{language} (default "gb" - Global Base).
    $self->_load_locale($self->config('language'));

    $self->init_date();
    my %custom_paths = %{ $self->{_path} || {} };
    $self->set_datadir( $self->path('dbase_dir') );
    for my $k ( keys %custom_paths ) {
        $self->{_path}->{$k} = $custom_paths{$k} if defined $custom_paths{$k} && length($custom_paths{$k}) && $k ne 'dbase_dir';
    }

    # Detect RAM-disk mount status and register in configuration
    my $rd_setup = $self->ramdisk_setup();
    $self->{_cfg}->{ramdisk_mounted} = $rd_setup->{is_mounted} ? 1 : 0;

    # Ensure internal containers exist
    $self->{_db}     ||= {};
    $self->{_dbm}    ||= {};
    $self->{_fd}     ||= {};
    $self->{_tie}    ||= {};
    $self->{_lock}   ||= {};
    $self->{_lastid} ||= {};
    $self->{_error}  ||= [];
    $self->{_no_txn} ||= 0;

    # 1. Lock allowed keys to prevent typos or unauthorized top-level attributes
    my %seen;
    my @input_keys = grep { $_ ne 'cfg' && $_ ne 'path' } keys %input;
    my @allowed = grep { !$seen{$_}++ } (
        @input_keys,
        qw(
            _dbase _table _cache _auth _pid _txn _db _dbm _fd _tie
            _lock _lastid _error _adb _rdbm_memo say
            _path _cfg db_ext ext date locale slug_max_len _no_txn
            day day_id dayname days hour hour_id minute minute_id
            month month_id monthname months only_time second second_id
            short str time year year_dir
            _lang _locale _collator _uc_re _lc_re _sort_re _accent_re
            _ascii_re _search_re _search_map _phonetic_rules _safe_re
            _letter_re _splitter_re _html_entities
        )
    );
    lock_keys( %$self, @allowed );

    # 2. Lock key values for core containers to prevent accidental reassignment
    lock_value( %$self, '_dbase' );
    lock_value( %$self, '_table' );
    lock_value( %$self, '_cache' );
    lock_value( %$self, '_auth' );
    lock_value( %$self, '_pid' );
    lock_value( %$self, '_db' );
    lock_value( %$self, '_dbm' );
    lock_value( %$self, '_fd' );
    lock_value( %$self, '_tie' );
    lock_value( %$self, '_lock' );
    lock_value( %$self, '_lastid' );
    lock_value( %$self, '_path' );
    lock_value( %$self, '_cfg' );

    return $self;
}

# When the object is destroyed, close all open DB files.
# ------------------------------------------------
sub DESTROY {

    my ($self) = @_;

    # Close transaction journal if still active (file left for orphan recovery)
    if ( $self->{_txn} && $self->{_txn}->{fh} ) {
        close $self->{_txn}->{fh};
    }

    $self->close_all();
}

# Adds a new record. Creates the table if it doesn't exist.
# my $rid = $adb->insert_id($tableid, $rid, @fields);
# ------------------------------------------------
sub insert_id {

    my ( $self, $tableid, $rid, @record ) = @_;

    # check inputs.
    $tableid or return;
    $rid //= 0;

    # Deflate if hashref is provided as single payload or as record payload
    if ( ref($rid) eq 'HASH' && !@record ) {
        my $h   = $rid;
        my $def = $self->deflate( $tableid, $h );
        if ( ref($def) eq 'ARRAY' ) {
            $rid    = $def->[0];
            @record = ( scalar(@$def) > 1 ) ? @{$def}[ 1 .. $#$def ] : (0);
        }
    }
    elsif ( @record && ref($record[0]) eq 'HASH' ) {
        my $h = $record[0];
        $h->{id} //= $rid if $rid;
        my $def = $self->deflate( $tableid, $h );
        if ( ref($def) eq 'ARRAY' ) {
            $rid //= $def->[0];
            @record = ( scalar(@$def) > 1 ) ? @{$def}[ 1 .. $#$def ] : (0);
        }
    }

    return () if ref $rid;
    scalar @record > 0 or $record[0] = 0;

    # check table path.
    my $table_path = $self->table_path($tableid);
    my $file_path  = "$table_path.$self->{db_ext}";

    # if defined NOWRITE
    $self->config('no_write')
      and do { $self->transact_error( $file_path, "No authority to write to the file" ); return; };

    # shorten the chain
    my $table_info = $self->table_info($tableid);
    (undef, @record) = $self->repeat_fields( $table_info, $rid, @record );

    # open table with exclusive lock
    my $db_handle = $self->table_write($file_path);
    unless ($db_handle) {
        return;
    }

    # check record id.
    my $has_manual_id = ( defined $rid && $rid ne '' && $rid ne '0' );
    $rid = $self->table_autoid( $tableid, ( $has_manual_id ? $rid : undef ) );
    unless ($rid) {
        $self->table_close($file_path);
        $self->transact_error( $file_path, "Invalid or missing record ID" );
        return;
    }

    if ($has_manual_id) {
        my $junk;
        my $k = $self->utf_encode("$rid");
        if ( $self->{_db}->{$file_path} && $self->{_db}->{$file_path}->get( $k, $junk ) == 0 ) {
            $self->table_close($file_path);
            $self->transact_error( $file_path, "Duplicate ID: $rid" );
            return;
        }
    }

    # Transaction journal & record locking (Lock before write - Strict 2PL)
    my $is_txn = ( $self->{_txn} && $self->{_txn}->{active} ) ? 1 : 0;
    $self->flock_open( $tableid, "write", $rid );
    if ($is_txn) {
        $self->{_txn}->{locks}->{"${tableid}_${rid}"} = 1;
    }

    # Validate and normalize field values according to schema blocks
    @record = $self->enc_validate( $tableid, \@record );

    # Validate unique constraints across blocks
    my ( $unq_ok, $unq_err ) = $self->unique_check( $table_path, $table_info, $rid, \@record );
    if ( !$unq_ok ) {
        $self->table_close($file_path);
        unless ($is_txn) { $self->flock_close( $tableid, $rid ); }
        $self->transact_error( $file_path, $unq_err // "Unique constraint violation" );
        return;
    }

    my $use_ramdisk = $table_info->{use_ramdisk} // $table_info->{use_cache} // 0;
    $use_ramdisk = $self->_normalize_ramdisk_tier($use_ramdisk);
    my $ramdisk_path;
    if ($use_ramdisk) {
        $self->ramdisk_ensure($tableid);
        $ramdisk_path = $self->ramdisk_path($tableid);
    }

    my $is_async_write = ( $use_ramdisk == 4 && !$is_txn );
    my $target_file    = ( $is_async_write && $ramdisk_path ) ? "$ramdisk_path.$self->{db_ext}" : $file_path;

    $self->recs_put( [ $target_file, $tableid ], [ $rid, @record ] );
    if ($is_async_write) {
        $self->ramdisk_mark_dirty( $file_path, $rid, 1 );
    }
    elsif ( $use_ramdisk == 4 && $is_txn ) {
        $self->ramdisk_unmark_dirty( $file_path, $rid );
    }

    $self->table_close($file_path);
    $self->table_close("$ramdisk_path.$self->{db_ext}") if $ramdisk_path;
    unless ($is_txn) { $self->flock_close( $tableid, $rid ); }

    # for index actions and backup
    @record = ( $rid, @record );

    # Invalidate cached table keys and count in memory
    $self->set_cache( $tableid, 'keys', undef );
    $self->set_cache( $tableid, 'count', undef );

    unless ($is_async_write) {
        $self->recs_back( "add", $tableid, \@record );
    }

    ( $self->config('simple') || ( $table_info && $table_info->{use_simple} ) ) and return $rid;

    # update .inx and secondary indexes
    my @batch = ( \@record );
    my $idx_path = ( $use_ramdisk && $ramdisk_path ) ? $ramdisk_path : $table_path;

    # 1. Base stream: unconditionally write all records
    $self->records_add( $idx_path, $table_info, $tableid, [$rid] );
    $self->search_add( $idx_path, $table_info, $tableid, \@batch );
    $self->match_add( $idx_path, $table_info, \@batch );
    $self->sort_add( $idx_path, $table_info, \@batch );
    $self->unique_add( $idx_path, $table_info, \@batch );
    $self->slug_add( $idx_path, $table_info, $tableid, \@batch );

    # 2. Tiered stream (A: Aktif, B: Pasif/Junk)
    if ( $table_info->{use_junk} ) {
        my $is_junk = $self->junk_rules( $table_info, @record );
        my $tier    = $is_junk ? 'B' : 'A';

        $self->records_add( $idx_path, $table_info, $tableid, [$rid], $tier );
        $self->search_add( $idx_path, $table_info, $tableid, \@batch, $tier );
        $self->match_add( $idx_path, $table_info, \@batch, $tier );
        $self->sort_add( $idx_path, $table_info, \@batch, $tier ) if $table_info->{sort_block};

        if ( !$is_junk ) {
            $self->facet_add( $idx_path, $table_info, \@batch );
        }
    }
    elsif ( $table_info->{use_facet} ) {
        $self->facet_add( $idx_path, $table_info, \@batch );
    }

    $self->auth_write( $tableid, $table_path, "add", $rid ) unless $is_async_write;

    return $rid;
}

# for bulk record inserting
# Note: Bulk operations (insert_list, modify_list, delete_list) do NOT use transactions (_txn_log).
# my $statu_hash = $adb->insert_list($tableid, @records);
# ------------------------------------------------
sub insert_list {

    my ( $self, $tableid, @records ) = @_;

    local $self->{_no_txn} = 1;

    $tableid        or return {};
    scalar @records or return {};

    # Deflate if records contain hashrefs or if single arrayref of hashes or HoH
    if ( @records == 1 && ref($records[0]) eq 'ARRAY' && @{$records[0]} && ref($records[0]->[0]) eq 'HASH' ) {
        @records = $self->deflate( $tableid, @{ $records[0] } );
    }
    elsif ( @records == 1 && ref($records[0]) eq 'HASH' ) {
        @records = $self->deflate( $tableid, $records[0] );
    }
    elsif ( grep { ref($_) eq 'HASH' } @records ) {
        @records = $self->deflate( $tableid, @records );
    }

    # Write authority cancelled.
    $self->config('no_write')
      and do { cluck "[DB_TIE] No authority to write to the file.\n"; return; };

    my $table_info = $self->table_info($tableid);
    my $is_simple  = $self->config('simple') || ( $table_info && $table_info->{use_simple} );

    my $table_path = $self->table_path($tableid);
    my $file_path  = "$table_path.$self->{db_ext}";

    # If explicit numeric IDs are passed, ensure ascending order
    my $has_numeric_ids = 0;
    for my $r (@records) {
        if ( ref($r) eq 'ARRAY' && defined $r->[0] && $r->[0] =~ /^\d+$/ && $r->[0] > 0 ) {
            $has_numeric_ids = 1;
            last;
        }
    }
    if ($has_numeric_ids) {
        @records = sort { ( $a->[0] // 0 ) <=> ( $b->[0] // 0 ) } @records;
    }

    my $use_ramdisk = $table_info ? ( $table_info->{use_ramdisk} // $table_info->{use_cache} // 0 ) : 0;
    $use_ramdisk = $self->_normalize_ramdisk_tier($use_ramdisk);
    my $ramdisk_path;
    if ($use_ramdisk) {
        $self->ramdisk_ensure($tableid);
        $ramdisk_path = $self->ramdisk_path($tableid);
    }

    my $is_async_write = ( $use_ramdisk == 4 );
    my $ram_file       = $ramdisk_path ? "$ramdisk_path.$self->{db_ext}" : undef;
    my $target_file    = ( $is_async_write && $ram_file ) ? $ram_file : $file_path;

    # Phase 1: raw writings (the file is opened once)
    $self->table_write($target_file) or return {};
    my $db = $self->{_db}->{$target_file};

    # Determine schema constraints upfront
    my $has_unique = 0;
    if ( ref($table_info->{blocks}) eq 'ARRAY' ) {
        for my $b (@{ $table_info->{blocks} }) {
            if ( ref($b) eq 'HASH' && defined $b->{valid} && $b->{valid} =~ /unique/i ) {
                $has_unique = 1;
                last;
            }
        }
    }
    my $has_repeat = ($table_info->{repeat_ids} && $table_info->{repeat_start}) ? 1 : 0;

    my $initial_lastid = $self->table_lastid($tableid) // 0;
    my $cached_auto    = $self->get_cache( $tableid, 'last_autoid' );
    $initial_lastid    = $cached_auto if ( defined $cached_auto && $cached_auto > $initial_lastid );
    my $running_autoid = $initial_lastid;

    my ( %statu, @batch, @new_rids );
    foreach my $record (@records) {
        my $aid = $record->[0];
        if ( defined $aid && $aid ne '' && $aid ne '0' ) {
            $aid = $self->id_check( $tableid, $aid );
            next unless defined $aid && $aid ne '';
            if ( !$is_simple && $aid =~ /^\d+$/ ) {
                if ( $aid <= $running_autoid ) {
                    $self->transact_error( $file_path, "ID must be greater than last ID ($running_autoid): $aid" );
                    next;
                }
                $running_autoid = $aid;
            }
            elsif ( $is_simple && $aid =~ /^\d+$/ && $aid > $running_autoid ) {
                $running_autoid = $aid;
            }
            $record->[0] = $aid;
        }
        else {
            $record->[0] = ++$running_autoid;
        }

        my ( $rid, @fields ) = @$record;
        @fields = $self->enc_validate( $tableid, \@fields );

        if ($has_unique) {
            my ( $unq_ok, $unq_err ) = $self->unique_check( $table_path, $table_info, $rid, \@fields );
            if ( !$unq_ok ) {
                cluck "[DB_UNIQUE] $unq_err\n";
                next;
            }
        }

        $record = [ $rid, @fields ];
        $record = [ $self->repeat_fields( $table_info, @$record ) ] if $has_repeat;

        # Duplicate check only needed if $rid is non-numeric or <= initial_lastid
        if ( $db && ( $rid !~ /^\d+$/ || $rid <= $initial_lastid ) ) {
            my $junk;
            my $k = $self->utf_encode("$rid");
            if ( $db->get( $k, $junk ) == 0 ) {
                cluck "[DB_TIE] Duplicate ID: $tableid-$rid\n";
                next;
            }
        }

        $statu{$rid} = 1;
        push @new_rids, $rid;
        push @batch,    $record;    # for indexing: $rid at [0]
    }

    if (@batch) {
        $self->recs_put( [ $target_file, $tableid ], @batch );
        if ($is_async_write) {
            foreach my $rec (@batch) {
                $self->ramdisk_mark_dirty( $file_path, $rec->[0], 1 );
            }
        }
        if (@new_rids) {
            $self->set_cache( $tableid, 'last_autoid', $running_autoid );
            $self->set_cache($tableid);
        }
    }
    $self->table_close($file_path);
    $self->table_close($ram_file) if $ram_file;

    return \%statu unless @batch;
    return \%statu if $is_simple;

    my $idx_path = ( $use_ramdisk && $ramdisk_path ) ? $ramdisk_path : $table_path;

    # 1. Base stream (All records)
    $self->records_add( $idx_path, $table_info, $tableid, \@new_rids );
    $self->search_add( $idx_path, $table_info, $tableid, \@batch );
    $self->match_add( $idx_path, $table_info, \@batch );
    $self->sort_add( $idx_path, $table_info, \@batch );

    # 2. Tiered stream (A: Aktif, B: Pasif/Junk)
    if ( $table_info->{use_junk} ) {
        my ( @active_batch, @junk_batch, @active_rids, @junk_rids );
        for my $rec (@batch) {
            if ( $self->junk_rules( $table_info, @$rec ) ) {
                push @junk_batch, $rec;
                push @junk_rids, $rec->[0];
            }
            else {
                push @active_batch, $rec;
                push @active_rids, $rec->[0];
            }
        }

        if (@active_batch) {
            $self->records_add( $idx_path, $table_info, $tableid, \@active_rids, 'A' );
            $self->search_add( $idx_path, $table_info, $tableid, \@active_batch, 'A' );
            $self->match_add( $idx_path, $table_info, \@active_batch, 'A' );
            $self->sort_add( $idx_path, $table_info, \@active_batch, 'A' ) if $table_info->{sort_block};
            $self->facet_add( $idx_path, $table_info, \@active_batch ) if $table_info->{use_facet};
        }

        if (@junk_batch) {
            $self->records_add( $idx_path, $table_info, $tableid, \@junk_rids, 'B' );
            $self->search_add( $idx_path, $table_info, $tableid, \@junk_batch, 'B' );
            $self->match_add( $idx_path, $table_info, \@junk_batch, 'B' );
            $self->sort_add( $idx_path, $table_info, \@junk_batch, 'B' ) if $table_info->{sort_block};
        }
    }
    elsif ( $table_info->{use_facet} ) {
        $self->facet_add( $idx_path, $table_info, \@batch );
    }

    if ($has_unique) {
        $self->unique_add( $idx_path, $table_info, \@batch );
    }

    $self->slug_add( $idx_path, $table_info, $tableid, \@batch );

    unless ($is_async_write) {
        if ( $table_info->{log_owner} ) {
            foreach my $rec (@batch) {
                $self->auth_write( $tableid, $table_path, "add", $rec->[0] );
            }
        }

        unless ( $self->config('no_backup') || $table_info->{no_backup} ) {
            $self->recs_back( "add", $tableid, @batch );
        }
    }

    return \%statu;
}

# Replace the DB record with new data.
# ------------------------------------------------
sub update_id {

    my ( $self, $tableid, $rid, @record ) = @_;

    # Perform the checks.
    $tableid or return;

    if ( ref($rid) eq 'HASH' && !@record ) {
        my $h = { %$rid };
        $rid = $h->{id} // $h->{ID};
        @record = ($h);
    }

    $rid = $self->id_check( $tableid, $rid );
    $rid or return;

    # Deflate if hashref is provided
    if ( @record && ref($record[0]) eq 'HASH' ) {
        my $h = { %{ $record[0] } };
        $h->{id} //= $rid;
        my $def = $self->deflate( $tableid, $h );
        if ( ref($def) eq 'ARRAY' ) {
            @record = ( scalar(@$def) > 1 ) ? @{$def}[ 1 .. $#$def ] : ();
        }
    }

    my $table_info = $self->table_info($tableid);
    (undef, @record) = $self->repeat_fields( $table_info, $rid, @record );

    my $table_path = $self->table_path($tableid);
    my $file_path  = "$table_path.$self->{db_ext}";

    # Write authority cancelled.
    $self->config('no_write')
      and do { $self->transact_error( $file_path, "No authority to write to the file" ); return; };

    # Transaction journal & record locking (Lock BEFORE reading/modifying - Strict 2PL)
    my $is_txn = ( $self->{_txn} && $self->{_txn}->{active} ) ? 1 : 0;
    $self->flock_open( $tableid, "write", $rid );
    if ($is_txn) {
        $self->{_txn}->{locks}->{"${tableid}_${rid}"} = 1;
    }

    my $use_ramdisk = $table_info ? ( $table_info->{use_ramdisk} // $table_info->{use_cache} // 0 ) : 0;
    $use_ramdisk = $self->_normalize_ramdisk_tier($use_ramdisk);
    my $ramdisk_path;
    if ($use_ramdisk) {
        $self->ramdisk_ensure($tableid);
        $ramdisk_path = $self->ramdisk_path($tableid);
    }

    my $is_async_write = ( $use_ramdisk == 4 && !$is_txn );
    my $is_dual_write  = ( $use_ramdisk == 2 || ( $is_txn && $use_ramdisk ) );
    my $ram_file       = $ramdisk_path ? "$ramdisk_path.$self->{db_ext}" : undef;
    my $old_record;

    # Open data file on disk unless async write
    unless ($is_async_write) {
        $self->table_write($file_path)
          or do {
              unless ($is_txn) { $self->flock_close( $tableid, $rid ); }
              $self->transact_error( $file_path, "$file_path can't open" );
              return;
          };
    }

    # Perform record check (exists or not)
    if ( $is_async_write && $ram_file && -e $ram_file ) {
        my $rh = $self->recs_get( $ram_file, $rid );
        $old_record = $rh ? $rh->{$rid} : undef;
    }
    unless ( defined $old_record ) {
        my $rh = $self->recs_get( $file_path, $rid );
        $old_record = $rh ? $rh->{$rid} : undef;
    }

    if ( !$table_info->{force} ) {
        if ( !defined $old_record ) {
            $self->table_close($file_path) unless $is_async_write;
            unless ($is_txn) { $self->flock_close( $tableid, $rid ); }
            $self->transact_error( $file_path, "Record not exist: $rid" );
            return;
        }
    }

    # Validate and normalize field values according to schema blocks
    @record = $self->enc_validate( $tableid, \@record );

    # Validate unique constraints across blocks
    my ( $unq_ok, $unq_err ) = $self->unique_check( $table_path, $table_info, $rid, \@record );
    if ( !$unq_ok ) {
        $self->table_close($file_path) unless $is_async_write;
        unless ($is_txn) { $self->flock_close( $tableid, $rid ); }
        $self->transact_error( $file_path, $unq_err // "Unique constraint violation" );
        return;
    }

    # Perform the record operation
    my $target_file = ( $is_async_write && $ram_file ) ? $ram_file : $file_path;
    $self->recs_put( [ $target_file, $tableid ], [ $rid, @record ] );
    if ($is_async_write) {
        $self->ramdisk_mark_dirty( $file_path, $rid, 2 );
    }
    elsif ( $use_ramdisk == 4 && $is_txn ) {
        $self->ramdisk_unmark_dirty( $file_path, $rid );
    }

    $self->table_close($file_path) unless $is_async_write;
    $self->table_close($ram_file) if $ram_file;
    unless ($is_txn) { $self->flock_close( $tableid, $rid ); }

    # Cache invalidate
    $self->clear_cache($tableid, $rid);

    my @new_rec = ( $rid, @record );

    # text backup record.
    unless ($is_async_write) {
        $self->recs_back( "edit", $tableid, \@new_rec )
          or cluck "[DB_TIE] Backup error (edit). $tableid\n";
    }

    ( $self->config('simple') || ( $table_info && $table_info->{use_simple} ) ) and return $rid;

    my @old_rec = $old_record ? ( $rid, $self->db_decode($old_record) ) : ($rid);

    # Index update (search, match, facet, sort)
    my @pairs = ( [ $rid, \@old_rec, \@new_rec ] );
    my $idx_path = ( $use_ramdisk && $ramdisk_path ) ? $ramdisk_path : $table_path;

    # 1. Base stream unconditional index updates
    $self->search_modify( $idx_path, $table_info, $tableid, \@pairs );
    $self->match_modify( $idx_path, $table_info, \@pairs );

    # 2. Tiered stream updates
    if ( $table_info->{use_junk} ) {
        $self->junk_transition( $idx_path, $table_info, $tableid, \@pairs );
    }
    elsif ( $table_info->{use_facet} ) {
        $self->facet_modify( $idx_path, $table_info, \@pairs );
    }
    $self->sort_modify( $idx_path, $table_info, \@pairs );
    $self->unique_modify( $idx_path, $table_info, \@pairs );

    $self->slug_modify( $idx_path, $table_info, $tableid, \@pairs );

    # Authorization
    $self->auth_write( $tableid, $table_path, "edit", $rid ) unless $is_async_write;

    return 1;
}

# List record modify.
# Note: Bulk operations (insert_list, modify_list, delete_list) do NOT use transactions (_txn_log).
# ------------------------------------------------
sub update_list {

    my ( $self, $tableid, @records ) = @_;

    local $self->{_no_txn} = 1;

    $tableid        or return {};
    scalar @records or return {};

    # Deflate if records contain hashrefs or if single arrayref of hashes or HoH
    if ( @records == 1 && ref($records[0]) eq 'ARRAY' && @{$records[0]} && ref($records[0]->[0]) eq 'HASH' ) {
        @records = $self->deflate( $tableid, @{ $records[0] } );
    }
    elsif ( @records == 1 && ref($records[0]) eq 'HASH' ) {
        @records = $self->deflate( $tableid, $records[0] );
    }
    elsif ( grep { ref($_) eq 'HASH' } @records ) {
        @records = $self->deflate( $tableid, @records );
    }

    # Write authority cancelled.
    $self->config('no_write')
      and do { cluck "[DB_TIE] No authority to write to the file.\n"; return; };

    my $table_info = $self->table_info($tableid);
    my $is_simple  = $self->config('simple') || ( $table_info && $table_info->{use_simple} );

    my $table_path = $self->table_path($tableid);
    my $file_path  = "$table_path.$self->{db_ext}";

    my $use_ramdisk = $table_info ? ( $table_info->{use_ramdisk} // $table_info->{use_cache} // 0 ) : 0;
    $use_ramdisk = $self->_normalize_ramdisk_tier($use_ramdisk);
    my $ramdisk_path;
    if ($use_ramdisk) {
        $self->ramdisk_ensure($tableid);
        $ramdisk_path = $self->ramdisk_path($tableid);
    }

    my $is_txn         = ( $self->{_txn} && $self->{_txn}->{active} ) ? 1 : 0;
    my $is_async_write = ( $use_ramdisk == 4 && !$is_txn );
    my $ram_file       = $ramdisk_path ? "$ramdisk_path.$self->{db_ext}" : undef;
    my $target_file    = ( $is_async_write && $ram_file ) ? $ram_file : $file_path;

    my $has_unique = ( $table_info->{valid} && grep { /unique/i } values %{ $table_info->{valid} } ) ? 1 : 0;
    my $has_repeat = ( $table_info->{repeat} && %{ $table_info->{repeat} } ) ? 1 : 0;

    my ( @valid_inputs, @input_rids );
    foreach my $record (@records) {
        my ( $rid, @data ) = @$record;
        next unless $rid;
        push @valid_inputs, [ $rid, @data ];
        push @input_rids, $rid;
    }
    return {} unless @valid_inputs;

    # Phase 1: raw writings
    $self->table_write($target_file) or return {};

    my $existing = $self->recs_get( $target_file, @input_rids );
    if ( $is_async_write && ( !$existing || !%$existing ) ) {
        $existing = $self->recs_get( $file_path, @input_rids ) if -e $file_path;
    }

    my ( %statu, @pairs, @records_to_put );
    foreach my $item (@valid_inputs) {
        my ( $rid, @data ) = @$item;

        my $old_raw = $existing->{$rid};
        if ( !defined $old_raw ) {
            my $rid_escape = $self->key_encode($rid);
            if ( defined $rid_escape && $rid_escape ne $rid ) {
                $old_raw = $existing->{$rid_escape};
            }
            if ( !defined $old_raw ) {
                cluck "[DB_TIE] Not exist: $rid\n";
                next;
            }
        }

        @data = $self->enc_validate( $tableid, \@data );

        if ($has_unique) {
            my ( $unq_ok, $unq_err ) = $self->unique_check( $table_path, $table_info, $rid, \@data );
            if ( !$unq_ok ) {
                cluck "[DB_UNIQUE] $unq_err\n";
                next;
            }
        }

        my $new_record = [ $rid, @data ];
        if ($has_repeat) {
            $new_record = [ $self->repeat_fields( $table_info, @$new_record ) ];
        }

        push @records_to_put, $new_record;
        $self->clear_cache( $tableid, $rid );
        $statu{$rid} = 1;

        my @old_rec = $old_raw ? ( $rid, $self->db_decode($old_raw) ) : ($rid);
        my @new_rec = @$new_record;
        push @pairs, [ $rid, \@old_rec, \@new_rec ];
    }

    if (@records_to_put) {
        $self->recs_put( [ $target_file, $tableid ], @records_to_put );
        if ($is_async_write) {
            foreach my $rec (@records_to_put) {
                $self->ramdisk_mark_dirty( $file_path, $rec->[0], 2 );
            }
        }
        elsif ( $use_ramdisk == 4 && $is_txn ) {
            foreach my $rec (@records_to_put) {
                $self->ramdisk_unmark_dirty( $file_path, $rec->[0] );
            }
        }
    }
    $self->table_close($file_path);
    $self->table_close($ram_file) if $ram_file;

    return \%statu unless @pairs;
    return \%statu if $is_simple;

    my $idx_path = ( $use_ramdisk && $ramdisk_path ) ? $ramdisk_path : $table_path;

    # Phase 2: bulk index updates
    # 1. Base stream unconditional index updates
    $self->search_modify( $idx_path, $table_info, $tableid, \@pairs );
    $self->match_modify( $idx_path, $table_info, \@pairs );

    # 2. Tiered stream updates
    if ( $table_info->{use_junk} ) {
        $self->junk_transition( $idx_path, $table_info, $tableid, \@pairs );
    }
    elsif ( $table_info->{use_facet} ) {
        $self->facet_modify( $idx_path, $table_info, \@pairs );
    }
    $self->sort_modify( $idx_path, $table_info, \@pairs );
    $self->unique_modify( $idx_path, $table_info, \@pairs );

    $self->slug_modify( $idx_path, $table_info, $tableid, \@pairs );

    if ( $table_info->{log_owner} && !$is_async_write ) {
        foreach my $pair (@pairs) {
            $self->auth_write( $tableid, $table_path, "edit", $pair->[0] );
        }
    }

    unless ( $is_async_write || $self->config('no_backup') || $table_info->{no_backup} ) {
        $self->recs_back( "edit", $tableid, map { $_->[2] } @pairs );
    }

    return \%statu;
}

# Standard SQL/CRUD aliases
sub modify_id   { shift->update_id(@_) }
sub modify_list { shift->update_list(@_) }

# Updates a field value in an existing record.
# Supports updating fixed schema blocks:
#   $adb->update_field($table, $rid, "price", 1750)
#   $adb->update_field($table, $rid, block => "price", 1750)
# Supports updating repeating child items by 'id' or 'pos':
#   $adb->update_field($table, $rid, id => 202, $new_item)
#   $adb->update_field($table, $rid, pos => 0, $new_item)
# ------------------------------------------------
sub update_field {
    my $self    = shift;
    my $tableid = shift;
    my $rid     = shift;

    $tableid or return;
    $rid = $self->id_check( $tableid, $rid );
    $rid or return;

    my ( $target_spec, $new_val );
    if ( @_ == 3 && !ref($_[0]) ) {
        my ( $k, $v, $val ) = @_;
        $target_spec = { $k => $v };
        $new_val     = $val;
    }
    elsif ( @_ == 2 ) {
        ( $target_spec, $new_val ) = @_;
        if ( !ref($target_spec) ) {
            $target_spec = { block => $target_spec };
        }
    }
    else {
        return;
    }

    my $table_info = $self->table_info($tableid);
    my $rep_start  = $table_info->{repeat_start};
    if ( !defined $rep_start && $table_info->{blocks} ) {
        for my $i ( 0 .. $#{ $table_info->{blocks} } ) {
            my $b = $table_info->{blocks}->[$i];
            if ( ref($b) eq 'HASH' && defined $b->{type} && lc( $b->{type} ) eq 'repeat' ) {
                $rep_start = $i;
                last;
            }
        }
    }

    my $table_path = $self->table_path($tableid);
    my $file_path  = "$table_path.$self->{db_ext}";

    $self->config('no_write')
      and do { $self->transact_error( $file_path, "No authority to write to the file" ); return; };

    my $is_txn = ( $self->{_txn} && $self->{_txn}->{active} ) ? 1 : 0;
    $self->flock_open( $tableid, "write", $rid );
    if ($is_txn) {
        $self->{_txn}->{locks}->{"${tableid}_${rid}"} = 1;
    }

    $self->table_write($file_path)
      or do {
          unless ($is_txn) { $self->flock_close( $tableid, $rid ); }
          $self->transact_error( $file_path, "$file_path can't open" );
          return;
      };

    my $old_record = $self->recs_get( $file_path, $rid )->{$rid};
    if ( !$table_info->{force} && !$old_record ) {
        $self->table_close($file_path);
        unless ($is_txn) { $self->flock_close( $tableid, $rid ); }
        $self->transact_error( $file_path, "Record not exist: $rid" );
        return;
    }

    my @old_fields = $self->db_decode($old_record);
    my @old_rec    = ( $rid, @old_fields );

    my $blk_idx;
    if ( exists $target_spec->{id} ) {
        my $target_id = $target_spec->{id};
        unless ( defined $rep_start ) {
            $self->table_close($file_path);
            unless ($is_txn) { $self->flock_close( $tableid, $rid ); }
            $self->transact_error( $file_path, "update_field by 'id' is only allowed on tables with repeat blocks" );
            return;
        }
        for my $i ( $rep_start .. $#old_rec ) {
            my $item = $old_rec[$i];
            my $item_id = ref($item) eq 'ARRAY' ? $item->[0]
                        : ref($item) eq 'HASH'  ? ( $item->{id} // $item->{ID} )
                        : $item;
            if ( defined $item_id && "$item_id" eq "$target_id" ) {
                $blk_idx = $i;
                last;
            }
        }
        unless ( defined $blk_idx ) {
            $self->table_close($file_path);
            unless ($is_txn) { $self->flock_close( $tableid, $rid ); }
            $self->transact_error( $file_path, "Child item with ID '$target_id' not found in record $rid" );
            return;
        }
    }
    elsif ( exists $target_spec->{pos} ) {
        my $pos = $target_spec->{pos};
        unless ( defined $rep_start ) {
            $self->table_close($file_path);
            unless ($is_txn) { $self->flock_close( $tableid, $rid ); }
            $self->transact_error( $file_path, "update_field by 'pos' is only allowed on tables with repeat blocks" );
            return;
        }
        my $calc_idx = $rep_start + ( 0 + $pos );
        if ( $calc_idx <= $#old_rec ) {
            $blk_idx = $calc_idx;
        }
        else {
            $self->table_close($file_path);
            unless ($is_txn) { $self->flock_close( $tableid, $rid ); }
            $self->transact_error( $file_path, "Repeat position '$pos' out of range in record $rid" );
            return;
        }
    }
    else {
        my $block = $target_spec->{block} // $target_spec->{index};
        unless ( defined $block && $block ne '' ) {
            $self->table_close($file_path);
            unless ($is_txn) { $self->flock_close( $tableid, $rid ); }
            return;
        }
        $blk_idx = $block;
        if ( $blk_idx !~ /^\d+$/ ) {
            if ( $table_info && ref( $table_info->{blocks} ) eq 'ARRAY' ) {
                my $blocks = $table_info->{blocks};
                my $found_idx;
                for my $i ( 0 .. $#$blocks ) {
                    my $b = $blocks->[$i];
                    if ( ref($b) eq 'HASH' ) {
                        if ( ( defined $b->{id} && lc( $b->{id} ) eq lc($blk_idx) )
                          || ( defined $b->{name} && lc( $b->{name} ) eq lc($blk_idx) ) ) {
                            $found_idx = $i;
                            last;
                        }
                    }
                    elsif ( defined $b && lc($b) eq lc($blk_idx) ) {
                        $found_idx = $i;
                        last;
                    }
                }
                unless ( defined $found_idx ) {
                    $self->table_close($file_path);
                    unless ($is_txn) { $self->flock_close( $tableid, $rid ); }
                    return;
                }
                $blk_idx = $found_idx;
            }
            else {
                $self->table_close($file_path);
                unless ($is_txn) { $self->flock_close( $tableid, $rid ); }
                return;
            }
        }
        else {
            $blk_idx = 0 + $blk_idx;
        }

        # Normalize input value according to the schema block definition via enc_field
        my $target_blk;
        if ( $table_info && ref( $table_info->{blocks} ) eq 'ARRAY' ) {
            $target_blk = $table_info->{blocks}->[$blk_idx];
            if ( !$target_blk && $rep_start && $blk_idx >= $rep_start ) {
                $target_blk = $table_info->{blocks}->[$rep_start] // $table_info->{blocks}->[-1];
            }
        }
        $new_val = $self->enc_field( $target_blk, $new_val );
    }

    # Primary key ID (block 0) cannot be modified via update_field
    if ( $blk_idx == 0 ) {
        $self->table_close($file_path);
        unless ($is_txn) { $self->flock_close( $tableid, $rid ); }
        $self->transact_error( $file_path, "Cannot update primary key ID via update_field" );
        return;
    }

    my $cur_val = ( $blk_idx < @old_rec ) ? $old_rec[$blk_idx] : undef;

    # Diff check: return early if scalar value is unchanged
    if ( !ref($cur_val) && !ref($new_val) ) {
        if ( ( !defined $cur_val && !defined $new_val )
          || ( defined $cur_val && defined $new_val && "$cur_val" eq "$new_val" ) ) {
            $self->table_close($file_path);
            unless ($is_txn) { $self->flock_close( $tableid, $rid ); }
            return 1;
        }
    }

    my @new_rec = @old_rec;
    while ( @new_rec <= $blk_idx ) {
        push @new_rec, undef;
    }
    $new_rec[$blk_idx] = $new_val;

    # If repeating records exist, synchronize repeat_ids
    if ( $table_info && $table_info->{repeat_ids} && $table_info->{repeat_start} ) {
        @new_rec = $self->repeat_fields( $table_info, @new_rec );
    }

    my ( $rid_norm, @fields_norm ) = @new_rec;
    @fields_norm = $self->enc_validate( $tableid, \@fields_norm );
    @new_rec = ( $rid, @fields_norm );

    my ( $unq_ok, $unq_err ) = $self->unique_check( $table_path, $table_info, $rid, \@fields_norm );
    if ( !$unq_ok ) {
        $self->table_close($file_path);
        unless ($is_txn) { $self->flock_close( $tableid, $rid ); }
        $self->transact_error( $file_path, $unq_err // "Unique constraint violation" );
        return;
    }

    $self->recs_put( [ $file_path, $tableid ], [ $rid, @fields_norm ] );

    $self->table_close($file_path);
    unless ($is_txn) { $self->flock_close( $tableid, $rid ); }

    $self->clear_cache( $tableid, $rid );
    $self->ramdisk_delete( $tableid, $rid );
    $self->recs_back( "edit", $tableid, \@new_rec );

    ( $self->config('simple') || ( $table_info && $table_info->{use_simple} ) ) and return 1;

    my @pairs = ( [ $rid, \@old_rec, \@new_rec ] );
    if ( $table_info->{use_junk} ) {
        $self->junk_transition( $table_path, $table_info, $tableid, \@pairs );
    }
    else {
        $self->search_modify( $table_path, $table_info, $tableid, \@pairs );
        $self->match_modify( $table_path, $table_info, \@pairs );
        $self->facet_modify( $table_path, $table_info, \@pairs );
    }
    $self->sort_modify( $table_path, $table_info, \@pairs );
    $self->unique_modify( $table_path, $table_info, \@pairs );

    $self->slug_modify( $table_path, $table_info, $tableid, \@pairs );

    $self->auth_write( $tableid, $table_path, "edit", $rid );
    return 1;
}

# Appends or inserts a new child item to repeating blocks (repeat_start).
# Supports position control: pos => 0 (prepend) or pos => $idx.
# Guards against duplicate child item IDs if the item carries an identifiable ID.
# ------------------------------------------------
sub insert_field {
    my $self    = shift;
    my $tableid = shift;
    my $rid     = shift;
    my $item    = shift;

    $tableid or return;
    return unless defined $item;

    $rid = $self->id_check( $tableid, $rid );
    $rid or return;

    my %opts;
    if ( @_ == 1 && ref($_[0]) eq 'HASH' ) {
        %opts = %{ $_[0] };
    }
    elsif ( @_ % 2 == 0 && @_ >= 2 ) {
        %opts = @_;
    }

    my $table_info = $self->table_info($tableid);
    my $rep_start  = $table_info->{repeat_start};
    if ( !defined $rep_start && $table_info->{blocks} ) {
        for my $i ( 0 .. $#{ $table_info->{blocks} } ) {
            my $b = $table_info->{blocks}->[$i];
            if ( ref($b) eq 'HASH' && defined $b->{type} && lc( $b->{type} ) eq 'repeat' ) {
                $rep_start = $i;
                last;
            }
        }
    }

    my $table_path = $self->table_path($tableid);
    my $file_path  = "$table_path.$self->{db_ext}";

    unless ( defined $rep_start ) {
        $self->transact_error( $file_path, "insert_field is only allowed on tables with repeat blocks" );
        return;
    }

    $self->config('no_write')
      and do { $self->transact_error( $file_path, "No authority to write to the file" ); return; };

    my $is_txn = ( $self->{_txn} && $self->{_txn}->{active} ) ? 1 : 0;
    $self->flock_open( $tableid, "write", $rid );
    if ($is_txn) {
        $self->{_txn}->{locks}->{"${tableid}_${rid}"} = 1;
    }

    $self->table_write($file_path)
      or do {
          unless ($is_txn) { $self->flock_close( $tableid, $rid ); }
          $self->transact_error( $file_path, "$file_path can't open" );
          return;
      };

    my $old_record = $self->recs_get( $file_path, $rid )->{$rid};
    if ( !$table_info->{force} && !$old_record ) {
        $self->table_close($file_path);
        unless ($is_txn) { $self->flock_close( $tableid, $rid ); }
        $self->transact_error( $file_path, "Record not exist: $rid" );
        return;
    }

    my @old_fields = $self->db_decode($old_record);
    my @old_rec    = ( $rid, @old_fields );

    # Duplicate child item ID check
    my $item_id = $opts{id};
    $item_id //= ref($item) eq 'ARRAY' ? $item->[0]
               : ref($item) eq 'HASH'  ? ( $item->{id} // $item->{ID} )
               : undef;

    if ( defined $item_id && $item_id ne '' ) {
        for my $i ( $rep_start .. $#old_rec ) {
            my $existing = $old_rec[$i];
            my $eid = ref($existing) eq 'ARRAY' ? $existing->[0]
                    : ref($existing) eq 'HASH'  ? ( $existing->{id} // $existing->{ID} )
                    : $existing;
            if ( defined $eid && "$eid" eq "$item_id" ) {
                $self->table_close($file_path);
                unless ($is_txn) { $self->flock_close( $tableid, $rid ); }
                $self->transact_error( $file_path, "Duplicate child item ID '$item_id' in record $rid" );
                return;
            }
        }
    }

    my @new_rec = @old_rec;
    while ( @new_rec < $rep_start ) {
        push @new_rec, undef;
    }

    if ( exists $opts{pos} && defined $opts{pos} ) {
        my $pos = 0 + $opts{pos};
        my $insert_at = $rep_start + $pos;
        $insert_at = scalar(@new_rec) if $insert_at > scalar(@new_rec);
        splice( @new_rec, $insert_at, 0, $item );
    }
    else {
        push @new_rec, $item;
    }

    if ( $table_info->{repeat_ids} ) {
        @new_rec = $self->repeat_fields( $table_info, @new_rec );
    }

    my ( $rid_norm, @fields_norm ) = @new_rec;
    @fields_norm = $self->enc_validate( $tableid, \@fields_norm );
    @new_rec = ( $rid, @fields_norm );

    $self->recs_put( [ $file_path, $tableid ], [ $rid, @fields_norm ] );

    $self->table_close($file_path);
    unless ($is_txn) { $self->flock_close( $tableid, $rid ); }

    $self->clear_cache( $tableid, $rid );
    $self->ramdisk_delete( $tableid, $rid );
    $self->recs_back( "edit", $tableid, \@new_rec );

    ( $self->config('simple') || ( $table_info && $table_info->{use_simple} ) ) and return 1;

    my @pairs = ( [ $rid, \@old_rec, \@new_rec ] );
    if ( $table_info->{use_junk} ) {
        $self->junk_transition( $table_path, $table_info, $tableid, \@pairs );
    }
    else {
        $self->search_modify( $table_path, $table_info, $tableid, \@pairs );
        $self->match_modify( $table_path, $table_info, \@pairs );
        $self->facet_modify( $table_path, $table_info, \@pairs );
    }
    $self->sort_modify( $table_path, $table_info, \@pairs );
    $self->unique_modify( $table_path, $table_info, \@pairs );

    $self->auth_write( $tableid, $table_path, "edit", $rid );
    return 1;
}

# Removes a repeating child item from a record.
# Target MUST be explicitly specified using 'id => $val' or 'pos => $idx':
#   $adb->delete_field($table, $rid, id => 202)
#   $adb->delete_field($table, $rid, pos => 0)
# ------------------------------------------------
sub delete_field {
    my $self    = shift;
    my $tableid = shift;
    my $rid     = shift;

    $tableid or return;
    $rid = $self->id_check( $tableid, $rid );
    $rid or return;

    my $table_path = $self->table_path($tableid);
    my $file_path  = "$table_path.$self->{db_ext}";

    my %opts;
    if ( @_ == 1 && ref($_[0]) eq 'HASH' ) {
        %opts = %{ $_[0] };
    }
    elsif ( @_ % 2 == 0 && @_ >= 2 ) {
        %opts = @_;
    }
    else {
        $self->transact_error( $file_path, "delete_field requires explicit target using 'id => \$val' or 'pos => \$idx'" );
        return;
    }

    unless ( exists $opts{id} || exists $opts{pos} ) {
        $self->transact_error( $file_path, "delete_field requires explicit target using 'id => \$val' or 'pos => \$idx'" );
        return;
    }

    my $table_info = $self->table_info($tableid);
    my $rep_start  = $table_info->{repeat_start};
    if ( !defined $rep_start && $table_info->{blocks} ) {
        for my $i ( 0 .. $#{ $table_info->{blocks} } ) {
            my $b = $table_info->{blocks}->[$i];
            if ( ref($b) eq 'HASH' && defined $b->{type} && lc( $b->{type} ) eq 'repeat' ) {
                $rep_start = $i;
                last;
            }
        }
    }

    unless ( defined $rep_start ) {
        $self->transact_error( $file_path, "delete_field is only allowed on tables with repeat blocks; use update_field to clear fixed blocks" );
        return;
    }

    $self->config('no_write')
      and do { $self->transact_error( $file_path, "No authority to write to the file" ); return; };

    my $is_txn = ( $self->{_txn} && $self->{_txn}->{active} ) ? 1 : 0;
    $self->flock_open( $tableid, "write", $rid );
    if ($is_txn) {
        $self->{_txn}->{locks}->{"${tableid}_${rid}"} = 1;
    }

    $self->table_write($file_path)
      or do {
          unless ($is_txn) { $self->flock_close( $tableid, $rid ); }
          $self->transact_error( $file_path, "$file_path can't open" );
          return;
      };

    my $old_record = $self->recs_get( $file_path, $rid )->{$rid};
    if ( !$table_info->{force} && !$old_record ) {
        $self->table_close($file_path);
        unless ($is_txn) { $self->flock_close( $tableid, $rid ); }
        $self->transact_error( $file_path, "Record not exist: $rid" );
        return;
    }

    my @old_fields = $self->db_decode($old_record);
    my @old_rec    = ( $rid, @old_fields );

    my $del_idx;
    if ( exists $opts{id} ) {
        my $target_id = $opts{id};
        for my $i ( $rep_start .. $#old_rec ) {
            my $item = $old_rec[$i];
            my $item_id = ref($item) eq 'ARRAY' ? $item->[0]
                        : ref($item) eq 'HASH'  ? ( $item->{id} // $item->{ID} )
                        : $item;
            if ( defined $item_id && "$item_id" eq "$target_id" ) {
                $del_idx = $i;
                last;
            }
        }
    }
    elsif ( exists $opts{pos} ) {
        my $pos = 0 + $opts{pos};
        my $calc_idx = $rep_start + $pos;
        if ( $calc_idx <= $#old_rec ) {
            $del_idx = $calc_idx;
        }
    }

    unless ( defined $del_idx ) {
        $self->table_close($file_path);
        unless ($is_txn) { $self->flock_close( $tableid, $rid ); }
        return 0; # Target repeat item not found
    }

    my @new_rec = @old_rec;
    splice( @new_rec, $del_idx, 1 );

    if ( $table_info->{repeat_ids} ) {
        @new_rec = $self->repeat_fields( $table_info, @new_rec );
    }

    my ( $rid_norm, @fields_norm ) = @new_rec;
    @fields_norm = $self->enc_validate( $tableid, \@fields_norm );
    @new_rec = ( $rid, @fields_norm );

    my $use_ramdisk = $table_info ? ( $table_info->{use_ramdisk} // $table_info->{use_cache} // 0 ) : 0;
    $use_ramdisk = $self->_normalize_ramdisk_tier($use_ramdisk);
    my $ramdisk_path;
    if ($use_ramdisk) {
        $self->ramdisk_ensure($tableid);
        $ramdisk_path = $self->ramdisk_path($tableid);
    }

    my $is_async_write = ( $use_ramdisk == 4 && !$is_txn );
    my $target_file    = ( $is_async_write && $ramdisk_path ) ? "$ramdisk_path.$self->{db_ext}" : $file_path;

    $self->recs_put( [ $target_file, $tableid ], [ $rid, @fields_norm ] );
    if ($is_async_write) {
        $self->ramdisk_mark_dirty( $file_path, $rid, 2 );
    }
    elsif ( $use_ramdisk == 4 && $is_txn ) {
        $self->ramdisk_unmark_dirty( $file_path, $rid );
    }

    $self->table_close($file_path);
    $self->table_close("$ramdisk_path.$self->{db_ext}") if $ramdisk_path;
    unless ($is_txn) { $self->flock_close( $tableid, $rid ); }

    $self->clear_cache( $tableid, $rid );
    unless ($is_async_write) {
        $self->recs_back( "edit", $tableid, \@new_rec );
    }

    ( $self->config('simple') || ( $table_info && $table_info->{use_simple} ) ) and return 1;

    my $idx_path = ( $use_ramdisk && $ramdisk_path ) ? $ramdisk_path : $table_path;
    my @pairs = ( [ $rid, \@old_rec, \@new_rec ] );
    if ( $table_info->{use_junk} ) {
        $self->junk_transition( $idx_path, $table_info, $tableid, \@pairs );
    }
    else {
        $self->search_modify( $idx_path, $table_info, $tableid, \@pairs );
        $self->match_modify( $idx_path, $table_info, \@pairs );
        $self->facet_modify( $idx_path, $table_info, \@pairs );
    }
    $self->sort_modify( $idx_path, $table_info, \@pairs );
    $self->unique_modify( $idx_path, $table_info, \@pairs );

    $self->auth_write( $tableid, $table_path, "edit", $rid ) unless $is_async_write;
    return 1;
}

# Delete a record in the DB.
# ------------------------------------------------
sub delete_id {

    my ( $self, $tableid, $rid ) = @_;

    # If no ID, return error.
    $tableid or return;
    $rid = $self->id_check( $tableid, $rid );
    $rid or return;

    my $table_info = $self->table_info($tableid);

    my $table_path = $self->table_path($tableid);
    my $file_path  = "$table_path.$self->{db_ext}";
    my $del_path   = "$table_path.del";

    # Write authority cancelled.
    $self->config('no_write')
      and do { $self->transact_error( $file_path, "No authority to write to the file" ); return; };

    # Transaction journal & record locking (Lock BEFORE reading/deleting - Strict 2PL)
    my $is_txn = ( $self->{_txn} && $self->{_txn}->{active} ) ? 1 : 0;
    $self->flock_open( $tableid, "write", $rid );
    if ($is_txn) {
        $self->{_txn}->{locks}->{"${tableid}_${rid}"} = 1;
    }

    my $use_ramdisk = $table_info ? ( $table_info->{use_ramdisk} // $table_info->{use_cache} // 0 ) : 0;
    $use_ramdisk = $self->_normalize_ramdisk_tier($use_ramdisk);
    my $ramdisk_path;
    if ($use_ramdisk) {
        $self->ramdisk_ensure($tableid);
        $ramdisk_path = $self->ramdisk_path($tableid);
    }

    my $is_async_write = ( $use_ramdisk == 4 && !$is_txn );
    my $is_dual_write  = ( $use_ramdisk == 2 || ( $is_txn && $use_ramdisk ) );

    my $ram_file = $ramdisk_path ? "$ramdisk_path.$self->{db_ext}" : undef;

    # Open table to write unless async write
    unless ($is_async_write) {
        $self->table_write($file_path)
          or do {
              unless ($is_txn) { $self->flock_close( $tableid, $rid ); }
              $self->transact_error( $file_path, "Could not open $file_path to write" );
              return;
          };
    }

    # If no record, return
    my $record;
    if ( $is_async_write && $ram_file && -e $ram_file ) {
        my $rec_h = $self->recs_get( $ram_file, $rid );
        $record   = $rec_h ? $rec_h->{$rid} : undef;
    }
    unless ( defined $record ) {
        my $rec_h = $self->recs_get( $file_path, $rid );
        $record   = $rec_h ? $rec_h->{$rid} : undef;
    }

    if ( !$record ) {
        $self->table_close($file_path) unless $is_async_write;
        unless ($is_txn) { $self->flock_close( $tableid, $rid ); }
        return;
    }

    # Delete the record
    my $target_file = ( $is_async_write && $ram_file ) ? $ram_file : $file_path;
    $self->recs_del( [ $target_file, $tableid ], $rid );
    if ($is_async_write) {
        $self->ramdisk_mark_dirty( $file_path, $rid, 3 );
    }
    elsif ( $use_ramdisk == 4 && $is_txn ) {
        $self->ramdisk_unmark_dirty( $file_path, $rid );
    }

    $self->table_close($file_path) unless $is_async_write;
    $self->table_close($ram_file) if $ram_file;
    unless ($is_txn) { $self->flock_close( $tableid, $rid ); }

    # Cache invalidate
    $self->clear_cache($tableid, $rid);

    # Text backup record
    unless ($is_async_write) {
        $self->recs_back( "del", $tableid, [ $rid, "" ] )
          or cluck "[DB_TIE] Backup error (del). $tableid\n";
    }

    # Move to archive if keep_deleted enabled
    if ( $table_info->{keep_deleted} && !$is_async_write ) {
        (         $self->table_write($del_path)
              and $self->recs_put( [ $del_path, $tableid ], [ $rid, $record ] )
              and $self->table_close($del_path) )
          or cluck "[DB_TIE] $del_path can't open.\n";
    }

    # Invalidate cached table keys and count in memory
    $self->set_cache( $tableid, 'keys', undef );
    $self->set_cache( $tableid, 'count', undef );

    ( $self->config('simple') || ( $table_info && $table_info->{use_simple} ) ) and return $rid;

    my @record = ( $rid, $self->db_decode($record) );

    # Clear Index (search, match, facet, sort)
    my @batch = ( \@record );
    my $idx_path = ( $use_ramdisk && $ramdisk_path ) ? $ramdisk_path : $table_path;

    # 1. Base stream: unconditionally delete from all records
    $self->records_del( $idx_path, $table_info, [$rid], $tableid );
    $self->search_del( $idx_path, $table_info, $tableid, \@batch );
    $self->match_del( $idx_path, $table_info, \@batch );
    $self->sort_del( $idx_path, $table_info, \@batch );
    $self->unique_del( $idx_path, $table_info, \@batch );

    # 2. Tiered stream (clean from both A and B tiers)
    if ( $table_info->{use_junk} ) {
        $self->records_del( $idx_path, $table_info, [$rid], $tableid, ['A', 'B'] );
        $self->search_del( $idx_path, $table_info, $tableid, \@batch, ['A', 'B'] );
        $self->match_del( $idx_path, $table_info, \@batch, ['A', 'B'] );
        $self->sort_del( $idx_path, $table_info, \@batch, ['A', 'B'] ) if $table_info->{sort_block};
        $self->facet_del( $idx_path, $table_info, \@batch ) if $table_info->{use_facet};
    }
    elsif ( $table_info->{use_facet} ) {
        $self->facet_del( $idx_path, $table_info, \@batch );
    }

    $self->slug_del( $idx_path, $table_info, $tableid, [$rid] );

    # Authorization
    $self->auth_write( $tableid, $table_path, "del", $rid ) unless $is_async_write;

    return 1;
}

# Deletes list of records from table...
# Note: Bulk operations (insert_list, modify_list, delete_list) do NOT use transactions (_txn_log).
# ------------------------------------------------
sub delete_list {

    my ( $self, $tableid, @records ) = @_;

    local $self->{_no_txn} = 1;

    $tableid        or return {};
    scalar @records or return {};

    # Write authority cancelled
    $self->config('no_write')
      and do { cluck "[DB_TIE] No authority to write to the file. $tableid\n"; return; };

    my $table_info = $self->table_info($tableid);
    my $is_simple  = $self->config('simple') || ( $table_info && $table_info->{use_simple} );

    my $table_path = $self->table_path($tableid);
    my $file_path  = "$table_path.$self->{db_ext}";
    my $del_path   = "$table_path.del";

    my @input_rids;
    foreach my $record (@records) {
        my $rid = ref($record) ? $record->[0] : $record;
        push @input_rids, $rid if $rid;
    }
    return {} unless @input_rids;

    my $use_ramdisk = $table_info ? ( $table_info->{use_ramdisk} // $table_info->{use_cache} // 0 ) : 0;
    $use_ramdisk = $self->_normalize_ramdisk_tier($use_ramdisk);
    my $ramdisk_path;
    if ($use_ramdisk) {
        $self->ramdisk_ensure($tableid);
        $ramdisk_path = $self->ramdisk_path($tableid);
    }

    my $is_async_write = ( $use_ramdisk == 4 );
    my $ram_file       = $ramdisk_path ? "$ramdisk_path.$self->{db_ext}" : undef;
    my $target_file    = ( $is_async_write && $ram_file ) ? $ram_file : $file_path;

    # Phase 1: raw deletes
    $self->table_write($target_file) or return {};
    my $raw_map = $self->recs_get( $target_file, @input_rids ) || {};
    if ( $is_async_write && ( !$raw_map || !%$raw_map ) ) {
        $raw_map = $self->recs_get( $file_path, @input_rids ) if -e $file_path;
        $raw_map ||= {};
    }

    my ( %statu, @batch, @del_rids );
    foreach my $rid (@input_rids) {
        my $raw = $raw_map->{$rid};
        next unless defined $raw;

        $statu{$rid} = 1;
        push @del_rids, $rid;
        push @batch,    [ $rid, $self->db_decode($raw) ];
        $self->clear_cache( $tableid, $rid );
    }

    if (@del_rids) {
        $self->recs_del( [ $target_file, $tableid ], @del_rids );
        if ($is_async_write) {
            foreach my $rid (@del_rids) {
                $self->ramdisk_mark_dirty( $file_path, $rid, 3 );
            }
        }
    }
    $self->table_close($file_path);
    $self->table_close($ram_file) if $ram_file;

    return \%statu unless @batch;
    $self->set_cache($tableid);
    return \%statu if $is_simple;

    # Archive
    if ( $table_info->{keep_deleted} && !$is_async_write ) {
        if ( $self->table_write($del_path) ) {
            my @archive_records = map {
                [ $_->[0], $self->db_encode( @{$_}[ 1 .. $#$_ ] ) ]
            } @batch;
            $self->recs_put( [ $del_path, $tableid ], @archive_records );
            $self->table_close($del_path);
        }
    }

    my $idx_path = ( $use_ramdisk && $ramdisk_path ) ? $ramdisk_path : $table_path;

    # Phase 2: bulk index clearing
    # 1. Base stream unconditional delete
    $self->records_del( $idx_path, $table_info, \@del_rids, $tableid );
    $self->search_del( $idx_path, $table_info, $tableid, \@batch );
    $self->match_del( $idx_path, $table_info, \@batch );
    $self->sort_del( $idx_path, $table_info, \@batch );

    # 2. Tiered stream cleanups
    if ( $table_info->{use_junk} ) {
        $self->records_del( $idx_path, $table_info, \@del_rids, $tableid, ['A', 'B'] );
        $self->search_del( $idx_path, $table_info, $tableid, \@batch, ['A', 'B'] );
        $self->match_del( $idx_path, $table_info, \@batch, ['A', 'B'] );
        $self->sort_del( $idx_path, $table_info, \@batch, ['A', 'B'] ) if $table_info->{sort_block};
        $self->facet_del( $idx_path, $table_info, \@batch ) if $table_info->{use_facet};
    }
    elsif ( $table_info->{use_facet} ) {
        $self->facet_del( $idx_path, $table_info, \@batch );
    }

    $self->unique_del( $idx_path, $table_info, \@batch );

    $self->slug_del( $idx_path, $table_info, $tableid, \@batch );

    unless ($is_async_write) {
        # Operations: auth, backup
        if ( $table_info->{log_owner} ) {
            foreach my $rec (@batch) {
                $self->auth_write( $tableid, $table_path, "del", $rec->[0] );
            }
        }

        unless ( $self->config('no_backup') || $table_info->{no_backup} ) {
            $self->recs_back( "del", $tableid, map { [ $_->[0], "" ] } @batch );
        }
    }

    return \%statu;
}

# my $ok = $adb->insert_links($tableid, [rid1, lnk1], [rid2, lnk2]);
# Writes alias link bindings into .lnk file.
# ------------------------------------------------
sub insert_links {

    my ( $self, $tableid, @records ) = @_;

    $tableid or return;
    @records or return;
    my $table_info = $self->table_info($tableid);
    $table_info->{use_alias} or return;

    # Yazma yetkisi iptal edildi.
    $self->config('no_write')
      and do { cluck "[DB_TIE] No authority to write to the file.\n"; return; };

    my $table_path = $self->table_path($tableid);
    my $link_path  = "$table_path.lnk";

    $self->table_write($link_path)
      or do { cluck "[DB_TIE] $link_path can't open. insert_links. $tableid\n"; return; };

    foreach my $rec (@records) {
        ( $rec->[0] and $rec->[1] ) or next;
        $self->recs_put( $link_path, [ $rec->[0], $rec->[1] ] );
    }
    $self->table_close($link_path);

    return 1;
}

# my $ok = $adb->insert_strs($tableid, $blk, [str1a, str1b], [str2a, str2b]);
# Updates synonym mapping tables (.unq); appends new values to existing list.
# ------------------------------------------------
sub insert_strs {

    my ( $self, $tableid, $blk, @records ) = @_;

    $tableid or return;
    @records or return;
    my $table_info = $self->table_info($tableid);

    # Write authority cancelled
    $self->config('no_write')
      and do { cluck "[DB_TIE] No authority to write to the file.\n"; return; };

    my $table_path = $self->table_path($tableid);
    my $unq_path   = "${table_path}.unq";

    $self->table_write($unq_path)
      or do { cluck "[DB_TIE] $unq_path can't open. insert_links.\n"; return; };

    foreach my $rec (@records) {
        ( $rec->[0] and $rec->[1] ) or next;
        my $value  = $self->recs_get( $unq_path, "$blk:$rec->[0]" );
        my %values = map { $_ => 1 } $self->db_decode( $value->{ "$blk:$rec->[0]" } );
        $values{ $rec->[1] } = 1;
        $self->recs_put( $unq_path, [ "$blk:$rec->[0]", keys %values ] );
    }

    $self->table_close($unq_path);

    return 1;
}

# Checks if a record exists. Opens table by $rid, returns 1 if present.
# my $ok = $adb->exist_id("tableid", $id);
# ------------------------------------------------
sub exist_id {

    my ( $self, $tableid, $rid ) = @_;

    ( $tableid and $rid ) or return;

    my $table_info = $self->table_info($tableid);
    my $table_path = $self->table_path($tableid);
    $rid = $self->id_check( $tableid, $rid );
    return 0 unless defined $rid && $rid ne '';
    my $file_path  = "$table_path.$self->{db_ext}";
    if ( ( $table_info->{use_ramdisk} // 0 ) == 3 ) {
        return 0 unless $self->_check_ramdisk_ttl( $tableid, $file_path );
    }
    return 0 unless -e $file_path;

    $self->table_read($file_path) or return 0;
    my $statu = $self->recs_exist( $file_path, $rid );
    $self->table_close($file_path);

    return $statu ? 1 : 0;
}

# Queries presence of multiple keys in raw file. Returns { key => 1/0 }.
# ------------------------------------------------
sub exist_list {

    my ( $self, $tableid, @records ) = @_;

    my $statu = {};
    scalar @records or return $statu;

    my $table_info = $self->table_info($tableid);
    my $table_path = $self->table_path($tableid);
    my $file_path  = "$table_path.$self->{db_ext}";
    if ( ( $table_info->{use_ramdisk} // 0 ) == 3 ) {
        return $statu unless $self->_check_ramdisk_ttl( $tableid, $file_path );
    }
    return $statu unless -e $file_path;

    $self->table_read($file_path) or return $statu;
    my $res = $self->recs_exist( $file_path, @records );
    $self->table_close($file_path);

    return ( ref($res) eq 'HASH' ) ? $res : { $records[0] => ( $res || 0 ) };
}

# Checks whether physical database file exists on disk.
# my $ok = $adb->exist_table("tableid", "slg");
# ------------------------------------------------
sub exist_table {

    my ( $self, $tableid, $_ext ) = @_;

    $tableid or return 0;
    $_ext ||= $self->{db_ext};
    my $table_path = $self->table_path($tableid);
    return ( -e "$table_path.$_ext" ) ? 1 : 0;
}

# ------------------------------------------------
# Transforms raw array records into schema-mapped hash structures.
# Supports single record, list/array of records, and dynamic RDBM relation resolution.
# ------------------------------------------------
sub inflate {
    my ( $self, $tableid, $data, $opts ) = @_;
    return unless defined $data;
    return $data unless defined $tableid && $tableid ne '';

    # 1. Inlined option normalization
    my ( $res_type, $block_opts, $default_rdbm, $depth );
    if ( !defined $opts ) {
        $res_type     = 'list';
        $block_opts   = {};
        $default_rdbm = 'display';
        $depth        = 0;
    }
    elsif ( !ref($opts) ) {
        $res_type     = ( $opts eq 'hash' ) ? 'hash' : 'list';
        $block_opts   = {};
        $default_rdbm = 'display';
        $depth        = 0;
    }
    elsif ( ref($opts) eq 'HASH' ) {
        $res_type     = $opts->{result} // $opts->{list} // 'list';
        $block_opts   = $opts->{block}  // $opts->{blocks} // {};
        $default_rdbm = $opts->{default} // 'display';
        $depth        = $opts->{_depth}  // 0;
    }
    else {
        $res_type     = 'list';
        $block_opts   = {};
        $default_rdbm = 'display';
        $depth        = 0;
    }

    # Recursion cycle safety guard
    return $data if $depth > 4;

    # 2. Schema check
    my $table_info = $self->table_info($tableid);
    my $blocks = ( $table_info && ref( $table_info->{blocks} ) eq 'ARRAY' ) ? $table_info->{blocks} : undef;

    # Return data as a reference to preserve caller's return signature contract consistency!
    if ( !$blocks || !@$blocks ) {
        return ( ref($data) eq 'ARRAY' ) ? $data : [$data];
    }

    # 3. Detect single vs batch records
    my $is_batch = 0;
    my @input_records;
    if ( ref($data) eq 'ARRAY' ) {
        if ( @$data && ref( $data->[0] ) eq 'ARRAY' ) {
            $is_batch = 1;
            @input_records = @$data;
        }
        else {
            @input_records = ($data);
        }
    }
    else {
        return $data;
    }

    # 4. Precompute field keys and RDBM resolution rules
    my @block_defs = @$blocks;
    my @field_keys;
    my %rdbm_lookup;
    my $primary_id_key = ( ref( $block_defs[0] ) eq 'HASH' )
      ? ( $block_defs[0]->{id} // $block_defs[0]->{name} // 'id' )
      : 'id';

    for my $i ( 0 .. $#block_defs ) {
        my $b = $block_defs[$i];
        my $k = ( ref($b) eq 'HASH' ) ? ( $b->{id} // $b->{name} // $i ) : $i;
        push @field_keys, $k;

        # Check RDBM
        my ( $tgt_t, $disp_b ) = $self->rdbm_target( $table_info, $i );
        if ($tgt_t) {
            my $mode = exists $block_opts->{$i} ? $block_opts->{$i}
                     : exists $block_opts->{$k} ? $block_opts->{$k}
                     : $default_rdbm;
            $mode = 'display' if defined $mode && "$mode" eq '1';

            if ( defined $mode && $mode ne '0' && lc($mode) ne 'none' ) {
                $rdbm_lookup{$i} = {
                    target  => $tgt_t,
                    display => $disp_b,
                    mode    => lc($mode),
                };
            }
        }
    }

    # Determine repeating block index (repeat_start) if defined in table_info or blocks
    my $rep_start = $table_info->{repeat_start};
    if ( !defined $rep_start ) {
        for my $idx ( 0 .. $#block_defs ) {
            my $b = $block_defs[$idx];
            if ( ref($b) eq 'HASH' && defined $b->{type} && lc($b->{type}) eq 'repeat' ) {
                $rep_start = $idx;
                last;
            }
        }
    }

    my $rep_key;
    if ( defined $rep_start ) {
        if ( $rep_start < @field_keys ) {
            $rep_key = $field_keys[$rep_start];
        }
        elsif ( @field_keys ) {
            my $last_b = $block_defs[-1];
            $rep_key = ( ref($last_b) eq 'HASH' )
              ? ( $last_b->{id} // $last_b->{name} // $rep_start )
              : $rep_start;
        }
        else {
            $rep_key = $rep_start;
        }
    }

    # 5. Inner record transformation
    my $inflate_record = sub {
        my ($rec) = @_;
        return unless defined $rec && ref($rec) eq 'ARRAY';

        my %hash;
        my $max_i = ( scalar(@field_keys) > scalar(@$rec) ) ? $#field_keys : $#$rec;
        for my $i ( 0 .. $max_i ) {
            my $key = ( $i < @field_keys ) ? $field_keys[$i] : $i;
            my $val = ( $i < @$rec ) ? $rec->[$i] : undef;

            # Handle repeating block from repeat_start to end of record
            if ( defined $rep_start && $i == $rep_start ) {
                my @repeat_items = ( $i <= $#$rec ) ? @{$rec}[ $i .. $#$rec ] : ();
                $hash{$key} = \@repeat_items;
                last;
            }

            if ( exists $rdbm_lookup{$i} && defined $val && $val ne '' ) {
                my $cfg = $rdbm_lookup{$i};
                my @foreign_ids = $self->get_fieldlist($val);

                if (@foreign_ids) {
                    my %resolved;
                    for my $fid (@foreign_ids) {
                        next unless defined $fid && $fid ne '';
                        my @tgt_rec = $self->get_cache( $cfg->{target}, $fid );
                        if ( !@tgt_rec ) {
                            my $tgt_path = $self->table_path( $cfg->{target} ) . "." . ( $self->{db_ext} || 'db' );
                            @tgt_rec = $self->table_readid( $tgt_path, $fid );
                            $self->set_cache( $cfg->{target}, $fid, \@tgt_rec ) if @tgt_rec;
                        }
                        if (@tgt_rec) {
                        if ( $cfg->{mode} eq 'full' ) {
                                my $full = $self->inflate(
                                    $cfg->{target}, \@tgt_rec,
                                    { default => 'display', _depth => $depth + 1 }
                            );
                            $resolved{$fid} = $full if $full;
                        }
                        else {
                            # display mode
                                my $disp_idx = $cfg->{display} // 1;
                                my $disp_val = ( $disp_idx < @tgt_rec ) ? $tgt_rec[$disp_idx] : $tgt_rec[1];
                                $resolved{$fid} = $disp_val;
                            }
                        }
                    }
                    $hash{$key} = \%resolved;
                }
                else {
                    $hash{$key} = $val;
                }
            }
            else {
                $hash{$key} = $val;
            }
        }

        # Ensure repeating block key is initialized if record had fewer fields than repeat_start
        if ( defined $rep_start && defined $rep_key && !exists $hash{$rep_key} ) {
            my @repeat_items = ( $rep_start <= $#$rec ) ? @{$rec}[ $rep_start .. $#$rec ] : ();
            $hash{$rep_key} = \@repeat_items;
        }

        return \%hash;
    };

    # 6. Format and return
    if (!$is_batch) {
        return $inflate_record->($input_records[0]);
    }

    my @inflated = map { $inflate_record->($_) } @input_records;
    if ( $res_type eq 'hash' ) {
        my %res_hash;
        for my $item (@inflated) {
            next unless ref($item) eq 'HASH';
            my $rid = $item->{$primary_id_key} // $item->{id} // $item->{ID};
            if ( defined $rid && $rid ne '' ) {
                $res_hash{$rid} = $item;
            }
        }
        return \%res_hash;
    }
    else {
        return \@inflated;
    }
}

# ------------------------------------------------
# Transforms hash structures back into schema-ordered array records for database storage.
# Accepts single hashref, arrayref of hashrefs, list of hashrefs, or hash of hashrefs.
# ------------------------------------------------
sub deflate {
    my ( $self, $tableid, @records ) = @_;
    return unless defined $tableid && $tableid ne '';
    return unless @records;

    my $table_info = $self->table_info($tableid);
    my $blocks = ( $table_info && ref( $table_info->{blocks} ) eq 'ARRAY' ) ? $table_info->{blocks} : undef;

    # Normalize incoming data container
    my @raw_inputs;
    my $single_input = 0;
    if ( @records == 1 ) {
        if ( ref( $records[0] ) eq 'ARRAY' ) {
            @raw_inputs = @{ $records[0] };
        }
        elsif ( ref( $records[0] ) eq 'HASH' ) {
            # Check if this hash is a Hash of Hashes: { 101 => { ... }, 102 => { ... } }
            my @vals = values %{ $records[0] };
            if ( @vals && !grep { ref($_) ne 'HASH' } @vals ) {
                for my $rid ( sort { ( $a =~ /^\d+$/ && $b =~ /^\d+$/ ) ? $a <=> $b : $a cmp $b } keys %{ $records[0] } ) {
                    my $sub_h = { %{ $records[0]->{$rid} } };
                    $sub_h->{id} //= $rid;
                    push @raw_inputs, $sub_h;
                }
            }
            else {
                $single_input = 1;
                @raw_inputs   = ( $records[0] );
            }
        }
        else {
            @raw_inputs = @records;
        }
    }
    else {
        @raw_inputs = @records;
    }

    # If no schema blocks defined, pass through
    if ( !$blocks || !@$blocks ) {
        return wantarray ? @raw_inputs : ( $single_input ? $raw_inputs[0] : \@raw_inputs );
    }

    # Determine repeating block index (repeat_start) if defined in table_info or blocks
    my $rep_start = $table_info->{repeat_start};
    if ( !defined $rep_start && $blocks ) {
        for my $idx ( 0 .. $#$blocks ) {
            my $b = $blocks->[$idx];
            if ( ref($b) eq 'HASH' && defined $b->{type} && lc($b->{type}) eq 'repeat' ) {
                $rep_start = $idx;
                last;
            }
        }
    }

    my @deflated;
    for my $rec (@raw_inputs) {
        if ( ref($rec) ne 'HASH' ) {
            push @deflated, $rec;
            next;
        }

        my @arr;
        for my $i ( 0 .. $#$blocks ) {
            my $blk_def = $blocks->[$i];
            my $id_k    = ref($blk_def) eq 'HASH' ? $blk_def->{id}   : undef;
            my $name_k  = ref($blk_def) eq 'HASH' ? $blk_def->{name} : undef;

            # Handle repeating block from repeat_start onwards
            if ( defined $rep_start && $i == $rep_start ) {
                my $val;
                my $plural_k = defined $id_k ? "${id_k}s" : undef;
                my $single_k = ( defined $id_k && $id_k =~ /^(.+)s$/i ) ? $1 : undef;

                if ( defined $id_k && exists $rec->{$id_k} ) {
                    $val = $rec->{$id_k};
                }
                elsif ( defined $name_k && exists $rec->{$name_k} ) {
                    $val = $rec->{$name_k};
                }
                elsif ( defined $plural_k && exists $rec->{$plural_k} ) {
                    $val = $rec->{$plural_k};
                }
                elsif ( defined $single_k && exists $rec->{$single_k} ) {
                    $val = $rec->{$single_k};
                }
                elsif ( exists $rec->{repeat} ) {
                    $val = $rec->{repeat};
                }
                elsif ( exists $rec->{repeats} ) {
                    $val = $rec->{repeats};
                }
                elsif ( exists $rec->{$i} ) {
                    $val = $rec->{$i};
                }

                if ( defined $val ) {
                    if ( ref($val) eq 'ARRAY' ) {
                        push @arr, @$val;
                    }
                    else {
                        push @arr, $val;
                    }
                }
                last;
            }

            my $val;
            if ( defined $id_k && exists $rec->{$id_k} ) {
                $val = $rec->{$id_k};
            }
            elsif ( defined $name_k && exists $rec->{$name_k} ) {
                $val = $rec->{$name_k};
            }
            elsif ( exists $rec->{$i} ) {
                $val = $rec->{$i};
            }
            elsif ( $i == 0 && exists $rec->{id} ) {
                $val = $rec->{id};
            }
            elsif ( $i == 0 && exists $rec->{ID} ) {
                $val = $rec->{ID};
            }

            # If $val is a resolved RDBM hash: { 532 => "Ahmet", 564 => "Maruf" }
            # convert back to foreign ID(s)
            if ( ref($val) eq 'HASH' ) {
                my @sub_keys = sort { ( $a =~ /^\d+$/ && $b =~ /^\d+$/ ) ? $a <=> $b : $a cmp $b } keys %$val;
                $val = join( ",", @sub_keys );
            }
            elsif ( ref($val) eq 'ARRAY' ) {
                $val = join( ",", @$val );
            }

            push @arr, $val;
        }

        # If repeat_start is beyond blocks length, check if repeat items need to be appended
        if ( defined $rep_start && $rep_start >= @arr ) {
            my $val;
            my $rep_b = ( $rep_start < @$blocks ) ? $blocks->[$rep_start] : $blocks->[-1];
            my $r_id  = ref($rep_b) eq 'HASH' ? $rep_b->{id}   : undef;
            my $r_nm  = ref($rep_b) eq 'HASH' ? $rep_b->{name} : undef;
            if ( defined $r_id && exists $rec->{$r_id} ) {
                $val = $rec->{$r_id};
            }
            elsif ( defined $r_nm && exists $rec->{$r_nm} ) {
                $val = $rec->{$r_nm};
            }
            elsif ( exists $rec->{repeat} ) {
                $val = $rec->{repeat};
            }
            elsif ( exists $rec->{repeats} ) {
                $val = $rec->{repeats};
            }

            if ( defined $val ) {
                while ( @arr < $rep_start ) {
                    push @arr, undef;
                }
                if ( ref($val) eq 'ARRAY' ) {
                    push @arr, @$val;
                }
                else {
                    push @arr, $val;
                }
            }
        }

        # Auto-populate repeat_ids summary field if repeat_ids and repeat_start are configured
        if ( $table_info && $table_info->{repeat_ids} && $table_info->{repeat_start} ) {
            @arr = $self->repeat_fields( $table_info, @arr );
        }

        push @deflated, \@arr;
    }

    if (wantarray) {
        return @deflated;
    }
    return $single_input ? $deflated[0] : \@deflated;
}

# Reads single record. Checks memory cache first, then DB; checks .lnk on force+alias, .del on force+keep_deleted.
# ------------------------------------------------
sub read_id {

    my ( $self, $tableid, $rid, $opts ) = @_;

    $tableid or return;

    # Handle 2-argument invocation where 2nd argument is options hashref:
    # e.g. $adb->read_id($table, { type => "last", inflate => 1 })
    if ( ref($rid) eq 'HASH' && !defined $opts ) {
        $opts = $rid;
        $rid  = undef;
    }
    # Shorthand 2-argument invocation: $adb->read_id($table, "last|first|rand")
    elsif ( defined $rid && !ref($rid) && ( $rid eq 'last' || $rid eq 'first' || $rid eq 'rand' || $rid eq 'random' ) && !defined $opts ) {
        $opts = { type => $rid };
        $rid  = undef;
    }

    my $table_info  = $self->table_info($tableid);
    my $use_ramdisk = $table_info ? ( $table_info->{use_ramdisk} // $table_info->{use_cache} // 0 ) : 0;

    # Options resolution
    my $opt_force       = 0;
    my $opt_get_links   = 0;
    my $opt_get_deleted = 0;
    my $opt_counter;
    my $is_inflate      = 0;
    my $inf_opts        = {};
    my $type;
    my $opt_sort;
    my $opt_range;

    if ( defined $opts ) {
        if ( ref($opts) eq 'HASH' ) {
            $type            = $opts->{type} // $opts->{pos};
            $opt_sort        = $opts->{sort} // $opts->{order} // $opts->{order_by};
            $opt_range       = $opts->{range};
            $opt_force       = $opts->{force}       // 0;
            $opt_get_deleted = $opts->{deleted}     // $opts->{get_deleted} // $opt_force // 0;
            $opt_get_links   = $opts->{links}       // $opts->{alias}       // $opts->{get_links} // $opts->{use_alias} // 0;
            if ( defined $opts->{counter} ) {
                $opt_counter = $opts->{counter};
            }
            elsif ( defined $opts->{use_counter} ) {
                $opt_counter = $opts->{use_counter};
            }
            elsif ( $opts->{no_counter} ) {
                $opt_counter = 0;
            }
            if ( $opts->{inflate} ) {
                $is_inflate = 1;
                $inf_opts   = ref($opts->{inflate}) eq 'HASH' ? $opts->{inflate} : {};
            }
        }
        elsif ( !ref($opts) ) {
            my $opt_str = lc($opts);
            if ( $opt_str eq 'inflate' ) {
                $is_inflate = 1;
            }
            elsif ( $opt_str eq 'counter' || $opt_str eq 'use_counter' ) {
                $opt_counter = 1;
            }
            elsif ( $opt_str eq 'no_counter' ) {
                $opt_counter = 0;
            }
            elsif ( $opt_str eq 'force' ) {
                $opt_force       = 1;
                $opt_get_deleted = 1;
            }
            elsif ( $opt_str eq 'deleted' || $opt_str eq 'get_deleted' ) {
                $opt_get_deleted = 1;
            }
            elsif ( $opt_str eq 'links' || $opt_str eq 'alias' || $opt_str eq 'get_links' || $opt_str eq 'use_alias' ) {
                $opt_get_links = 1;
            }
            elsif ( $opt_str eq 'last' || $opt_str eq 'first' || $opt_str eq 'rand' || $opt_str eq 'random' ) {
                $type = $opt_str;
            }
        }
    }

    # Resolve table path
    my $table_path = $self->table_path($tableid);
    return unless $table_path;

    $use_ramdisk = $table_info ? ( $table_info->{use_ramdisk} // $table_info->{use_cache} // 0 ) : 0;
    if ($use_ramdisk) {
        $self->ramdisk_ensure($tableid);
    }
    my $idx_path = $use_ramdisk ? $self->ramdisk_path($tableid) : $table_path;

    # Dynamic positional ID resolution (type => last|first|rand, with optional sort)
    if ( defined $type ) {
        $rid  = undef;
        $type = lc($type);

        my $s_norm           = defined $opt_sort ? $self->normalize_sort_opt($opt_sort) : undef;
        my $s_blk_raw        = $s_norm ? $s_norm->{blk} : undef;
        my $s_blk            = defined $s_blk_raw ? $self->resolve_block_idx( $tableid, $s_blk_raw ) : undef;
        my $is_custom_sort   = ( defined $s_blk && $s_blk ne '' && $s_blk ne '0' && $s_blk ne 'id' ) ? 1 : 0;

        my $has_explicit_dir = 0;
        if ( defined $opt_sort ) {
            if ( ref($opt_sort) eq 'HASH' ) {
                $has_explicit_dir = 1 if exists $opt_sort->{dir} || exists $opt_sort->{order} || exists $opt_sort->{reverse};
            }
            elsif ( $opt_sort =~ /^(?:-|\+)|(?:\s+(?:desc|asc|reverse))$/i ) {
                $has_explicit_dir = 1;
            }
        }

        my $want_smallest;
        if ($is_custom_sort) {
            if ($has_explicit_dir) {
                if ( $s_norm->{dir} eq 'desc' ) {
                    $want_smallest = ( $type eq 'last' ) ? 1 : 0;
                }
                else {
                    $want_smallest = ( $type eq 'first' ) ? 1 : 0;
                }
            }
            else {
                # Natural block order: 'first' wants smallest, 'last' wants largest
                $want_smallest = ( $type eq 'first' ) ? 1 : 0;
            }
        }
        else {
            # ID-based default sort: 'first' wants lowest ID, 'last' wants highest ID
            $want_smallest = ( $type eq 'first' ) ? 1 : 0;
        }

        my $index_path = "$idx_path.inx";
        if ( -e $index_path && !$opt_range ) {
            my $db_inx = $self->{_db}->{$index_path} || $self->table_read($index_path);
            if ($db_inx) {
                my $key_name = $is_custom_sort ? "$s_blk:keys" : "keys";
                my $raw_buf;
                if ( $db_inx->get( $key_name, $raw_buf ) == 0 && defined $raw_buf && length($raw_buf) >= 8 ) {
                    if ( $type eq 'rand' || $type eq 'random' ) {
                        my $total = int( length($raw_buf) / 8 );
                        if ( $total > 0 ) {
                            my $rand_pos = int( rand($total) );
                            ( undef, my @ids ) = $self->bin_decode( $raw_buf, $rand_pos, 1 );
                            $rid = $ids[0] if @ids;
                        }
                    }
                    elsif ($want_smallest) {
                        ( undef, my @ids ) = $self->bin_decode( $raw_buf, 0, 1, 'asc' );
                        $rid = $ids[0] if @ids;
                    }
                    else {
                        ( undef, my @ids ) = $self->bin_decode( $raw_buf, 0, 1, 'desc' );
                        $rid = $ids[0] if @ids;
                    }
                }
            }
        }

        # Fallback if not resolved from .inx or if range / unindexed
        if ( !defined $rid || $rid eq '' ) {
            my @all_keys = $self->table_keys($tableid);
            if (@all_keys) {
                if ( $is_custom_sort || $opt_range ) {
                    my @records = $self->read_list( $tableid, \@all_keys );
                    if ( $opt_range && @records ) {
                        @records = $self->filter_ids_by_range( $tableid, \@records, $opt_range );
                    }
                    if (@records) {
                        if ($is_custom_sort) {
                            my $table_info = $self->table_info($tableid);
                            my $sort_type  = 'auto';
                            if ( $table_info && exists $table_info->{sort_block} ) {
                                foreach my $cfg ( @{ $table_info->{sort_block} } ) {
                                    if ( ref($cfg) eq 'HASH' && ( ( defined $cfg->{blk} && $cfg->{blk} == $s_blk ) || ( defined $cfg->{name} && lc($cfg->{name}) eq lc($s_blk_raw) ) ) ) {
                                        $sort_type = $cfg->{type} // 'auto';
                                        last;
                                    }
                                }
                            }
                            @records = $self->array_sort( $sort_type, 'asc', $s_blk, @records );
                            if (@records) {
                                if ( $type eq 'rand' || $type eq 'random' ) {
                                    $rid = $records[ int( rand(@records) ) ][0];
                                }
                                elsif ($want_smallest) {
                                    $rid = $records[0][0];
                                }
                                else {
                                    $rid = $records[-1][0];
                                }
                            }
                        }
                        else {
                            if ( $type eq 'rand' || $type eq 'random' ) {
                                $rid = $records[ int( rand(@records) ) ][0];
                            }
                            elsif ($want_smallest) {
                                my @sorted = ( $records[0][0] =~ /^\d+$/ )
                                  ? sort { $a->[0] <=> $b->[0] } @records
                                  : sort { $a->[0] cmp $b->[0] } @records;
                                $rid = $sorted[0][0];
                            }
                            else {
                                my @sorted = ( $records[0][0] =~ /^\d+$/ )
                                  ? sort { $b->[0] <=> $a->[0] } @records
                                  : sort { $b->[0] cmp $a->[0] } @records;
                                $rid = $sorted[0][0];
                            }
                        }
                    }
                }
                else {
                    # Standard primary key ID fallback
                    if ( $type eq 'rand' || $type eq 'random' ) {
                        $rid = $all_keys[ int( rand(@all_keys) ) ];
                    }
                    elsif ($want_smallest) {
                        my @sorted = ( $all_keys[0] =~ /^\d+$/ )
                          ? sort { $a <=> $b } @all_keys
                          : sort { $a cmp $b } @all_keys;
                        $rid = $sorted[0];
                    }
                    else {
                        my @sorted = ( $all_keys[0] =~ /^\d+$/ )
                          ? sort { $b <=> $a } @all_keys
                          : sort { $b cmp $a } @all_keys;
                        $rid = $sorted[0];
                    }
                }
            }
        }
    }

    return unless defined $rid && $rid ne '';

    my $can_alias = ( $table_info && $table_info->{use_alias} )
      || ( $table_info && $table_info->{force} )
      || $opt_force
      || $opt_get_links;

    my $raw_rid   = $rid;
    my $clean_rid = $self->id_check( $tableid, $rid );
    if ( defined $clean_rid && $clean_rid ne '' ) {
        $rid = $clean_rid;
    }
    elsif ( !$can_alias ) {
        return;
    }

    my $data_path  = ( $use_ramdisk == 2 || $use_ramdisk == 4 ) ? $self->ramdisk_path($tableid) : $table_path;
    my $file_path  = "$data_path.$self->{db_ext}";
    if ( ( $use_ramdisk == 2 || $use_ramdisk == 4 ) && !-e $file_path ) {
        $file_path = "$table_path.$self->{db_ext}";
    }
    if ( $use_ramdisk == 3 ) {
        return unless $self->_check_ramdisk_ttl( $tableid, $file_path );
        return unless -e $file_path;
    }
    -e $file_path
      or do { cluck "[DB_TIE] $tableid id and $file_path file path not exist\n"; return; };

    my @fields;
    if ( defined $clean_rid ) {
        my $db = $self->{_db}->{$file_path} || $self->table_read($file_path);
        if ($db) {
            my $raw;
            my $k   = $self->utf_encode("$rid");
            my $ret = $db->get( $k, $raw );
            if ( $ret != 0 ) {
                my $rid_escape = $self->key_encode($rid);
                if ( defined $rid_escape && $rid_escape ne $rid ) {
                    my $k_esc = $self->utf_encode("$rid_escape");
                    $ret = $db->get( $k_esc, $raw );
                }
            }
            if ( $ret == 0 && defined $raw ) {
                @fields = ( $rid, $self->db_decode($raw) );
            }
        }
    }

    if ( $use_ramdisk == 3 && scalar @fields ) {
        utime( undef, undef, $file_path );
    }

    # Read from alias file if use_alias is configured, links/alias is requested, or .lnk file exists
    if ( !scalar @fields && ( $can_alias || -e "$table_path.lnk" ) ) {
        my $link_path = "$table_path.lnk";
        my @link      = $self->table_readid( $link_path, defined $clean_rid ? $clean_rid : $raw_rid );
        if ( $link[1] ) {
            $rid    = $self->id_check( $tableid, $link[1] ) // $link[1];
            my $db  = $self->{_db}->{$file_path} || $self->table_read($file_path);
            if ($db) {
                my $raw;
                my $k   = $self->utf_encode("$rid");
                my $ret = $db->get( $k, $raw );
                if ( $ret == 0 && defined $raw ) {
                    @fields = ( $rid, $self->db_decode($raw) );
                }
            }
        }
    }

    # Read from nodelete archive if FORCE or deleted is enabled
    if ( !scalar @fields ) {
        my $can_del = ( $table_info && $table_info->{force} && $table_info->{keep_deleted} )
          || ( $opt_force && ( !$table_info || $table_info->{keep_deleted} ) )
          || $opt_get_deleted;

        if ($can_del) {
            my $del_path = "$table_path.del";
            @fields = $self->table_readid( $del_path, $rid );
        }
    }

    # Increment read counter if enabled
    my $should_count = defined $opt_counter
      ? $opt_counter
      : ( $table_info && $table_info->{use_counter} ? 1 : 0 );

    if ( ( scalar @fields ) && $should_count ) {
        my $cnt_path = "$table_path.cnt";
        $self->table_write($cnt_path);
        my $value = $self->recs_get( $cnt_path, $rid );
        $self->recs_put( $cnt_path, [ $rid, ++$value->{$rid} ] );
        $self->table_close($cnt_path);
    }

    # Load access logs only if table tracks log_owner
    if ( $table_info && $table_info->{log_owner} ) {
        $self->auth_read( $tableid, $table_path, $rid );
    }

    if ( @fields > 1 ) {
        my $id_val     = $fields[0];
        my @val_fields = $self->dec_validate( $tableid, [ @fields[ 1 .. $#fields ] ] );
        @fields        = ( $id_val, @val_fields );
    }

    # Inflate integration
    if ($is_inflate) {
        return $self->inflate( $tableid, \@fields, $inf_opts );
    }

    return @fields;
}

# Resolves block index from either numeric integer or schema block name/id.
# ------------------------------------------------
sub resolve_block_idx {
    my ( $self, $tableid, $block ) = @_;
    return unless defined $block && $block ne '';
    return 0 + $block if $block =~ /^\d+$/;
    my $info = $self->table_info($tableid);
    if ( $info && $info->{blocks} ) {
        if ( ref( $info->{blocks} ) eq 'ARRAY' ) {
            for my $i ( 0 .. $#{ $info->{blocks} } ) {
                my $b = $info->{blocks}->[$i];
                if ( ref($b) eq 'HASH' ) {
                    return $i if ( defined $b->{id}   && lc( $b->{id} )   eq lc($block) );
                    return $i if ( defined $b->{name} && lc( $b->{name} ) eq lc($block) );
                }
                elsif ( defined $b && lc($b) eq lc($block) ) {
                    return $i;
                }
            }
        }
        elsif ( ref( $info->{blocks} ) eq 'HASH' ) {
            for my $k ( keys %{ $info->{blocks} } ) {
                my $b = $info->{blocks}->{$k};
                if ( ref($b) eq 'HASH' ) {
                    return $k if ( defined $b->{id}   && lc( $b->{id} )   eq lc($block) );
                    return $k if ( defined $b->{name} && lc( $b->{name} ) eq lc($block) );
                }
                elsif ( defined $b && lc($b) eq lc($block) ) {
                    return $k;
                }
            }
        }
    }
    return $block;
}

# Normalizes range => { block => ..., min => ..., max => ... } specifications.
# Default min = 0 if omitted; max = undef (unbounded) if omitted.
# ------------------------------------------------
sub normalize_range_opts {
    my ( $self, $tableid, $opts ) = @_;
    return unless $opts && ref($opts) eq 'HASH';
    my $range_spec = $opts->{range};
    return unless $range_spec;

    my @items;
    if ( ref($range_spec) eq 'ARRAY' ) {
        @items = @$range_spec;
    }
    elsif ( ref($range_spec) eq 'HASH' ) {
        if ( exists $range_spec->{block} || exists $range_spec->{blk} || exists $range_spec->{field} ) {
            @items = ($range_spec);
        }
        else {
            for my $k ( keys %$range_spec ) {
                my $v = $range_spec->{$k};
                if ( ref($v) eq 'HASH' ) {
                    push @items, { block => $k, %$v };
                }
                elsif ( ref($v) eq 'ARRAY' ) {
                    push @items, { block => $k, min => $v->[0], max => $v->[1] };
                }
            }
        }
    }
    return unless @items;

    my @normalized;
    for my $item (@items) {
        next unless ref($item) eq 'HASH';
        my $blk = $item->{block} // $item->{blk} // $item->{field};
        next unless defined $blk && $blk ne '';
        my $blk_idx = $self->resolve_block_idx( $tableid, $blk );
        next unless defined $blk_idx && $blk_idx =~ /^\d+$/;

        my $min = $item->{min};
        my $max = $item->{max};
        push @normalized, {
            blk => 0 + $blk_idx,
            min => ( defined $min && $min ne '' ) ? 0 + $min : 0,
            max => ( defined $max && $max ne '' ) ? 0 + $max : undef,
        };
    }

    return @normalized ? \@normalized : undef;
}

# Filters a list of record IDs or records [ $id, @fields ] by numerical/chronological ranges.
# ------------------------------------------------
sub filter_ids_by_range {
    my ( $self, $tableid, $ids_ref, $range_spec ) = @_;
    return () unless $ids_ref && ref($ids_ref) eq 'ARRAY' && @$ids_ref;
    my $ranges = ref($range_spec) eq 'ARRAY' ? $range_spec : $self->normalize_range_opts( $tableid, { range => $range_spec } );
    return @$ids_ref unless $ranges && @$ranges;

    my $table_path  = $self->table_path($tableid);
    my $table_info  = $self->table_info($tableid);
    my $use_ramdisk = $table_info ? ( $table_info->{use_ramdisk} // $table_info->{use_cache} // 0 ) : 0;
    if ($use_ramdisk) {
        $self->ramdisk_ensure($tableid);
    }
    my $idx_path    = $use_ramdisk ? $self->ramdisk_path($tableid) : $table_path;
    my $index_path  = ( -e "${idx_path}.inx" ) ? "${idx_path}.inx" : "${table_path}.inx";
    my $fac_path    = ( -e "${idx_path}.fac" ) ? "${idx_path}.fac" : "${table_path}.fac";

    my @survivors = @$ids_ref;

    for my $rng (@$ranges) {
        my $blk = $rng->{blk};
        my $min = $rng->{min};
        my $max = $rng->{max};
        last unless @survivors;

        if ( ref( $survivors[0] ) eq 'ARRAY' ) {
            my @filtered;
            for my $r (@survivors) {
                next unless ref($r) eq 'ARRAY' && @$r > $blk && defined $r->[$blk];
                my $raw_v = $r->[$blk];
                my $num_v;
                if ( $raw_v =~ /^\s*(-?\d+(?:\.\d+)?)\s*$/ ) {
                    $num_v = 0 + $1;
                }
                elsif ( $raw_v =~ /(-?\d+(?:\.\d+)?)/ ) {
                    $num_v = 0 + $1;
                }
                next unless defined $num_v;
                next if defined $min && $num_v < $min;
                next if defined $max && $num_v > $max;
                push @filtered, $r;
            }
            @survivors = @filtered;
            next;
        }

        my %val_map;

        # 1. Try fetching from .fac ($blk:$rid)
        if ( -e $fac_path ) {
            my @req = map { "$blk:$_" } @survivors;
            my $raw_hash = $self->index_get( $fac_path, \@req, 'raw' );
            if ( $raw_hash && ref($raw_hash) eq 'HASH' ) {
                for my $rid (@survivors) {
                    my $v = $raw_hash->{"$blk:$rid"};
                    $val_map{$rid} = $v if defined $v && $v ne '';
                }
            }
        }

        # 2. Try fetching from .inx ($blk:$rid) if in sort_block
        my @missing = grep { !exists $val_map{$_} } @survivors;
        if ( @missing && -e $index_path ) {
            my @req = map { "$blk:$_" } @missing;
            my $raw_hash = $self->index_get( $index_path, \@req, 'raw' );
            if ( $raw_hash && ref($raw_hash) eq 'HASH' ) {
                for my $rid (@missing) {
                    my $v = $raw_hash->{"$blk:$rid"};
                    $val_map{$rid} = $v if defined $v && $v ne '';
                }
            }
        }

        # 3. Fallback: read records for any remaining missing IDs
        @missing = grep { !exists $val_map{$_} } @survivors;
        if (@missing) {
            my @recs = $self->read_list( $tableid, \@missing );
            for my $r (@recs) {
                if ( ref($r) eq 'ARRAY' && @$r > $blk ) {
                    $val_map{ $r->[0] } = $r->[$blk];
                }
            }
        }

        my @filtered;
        for my $rid (@survivors) {
            next unless exists $val_map{$rid} && defined $val_map{$rid};
            my $raw_v = $val_map{$rid};
            my $num_v;
            if ( $raw_v =~ /^\s*(-?\d+(?:\.\d+)?)\s*$/ ) {
                $num_v = 0 + $1;
            }
            elsif ( $raw_v =~ /(-?\d+(?:\.\d+)?)/ ) {
                $num_v = 0 + $1;
            }
            next unless defined $num_v;
            next if defined $min && $num_v < $min;
            next if defined $max && $num_v > $max;
            push @filtered, $rid;
        }
        @survivors = @filtered;
    }

    return @survivors;
}

# Reads all records or range of records.
# my @records = $adb->read_all("tableID");
# my ($count, @records) = $adb->read_all("tableID", 0, 20);
# ------------------------------------------------
sub read_all {

    my ( $self, $tableid, @args ) = @_;

    $tableid or return;

    my ( $offset, $limit, %opts );
    if ( @args == 1 && ref( $args[0] ) eq 'HASH' ) {
        %opts   = %{ $args[0] };
        $offset = $opts{offset} // $opts{start} // 0;
        $limit  = $opts{limit}  // 0;
    }
    else {
        if ( @args && ( !defined $args[0] || $args[0] =~ /^\d+$/ ) ) {
            $offset = shift @args;
        }
        if ( @args && ( !defined $args[0] || $args[0] =~ /^\d+$/ ) ) {
            $limit = shift @args;
        }
        if ( @args && @args % 2 == 0 ) {
            %opts = @args;
        }
    }
    $offset //= $opts{offset} // $opts{start} // 0;
    $limit  //= $opts{limit}  // 0;

    my @records;

    my $format_return = sub {
        my ( $cnt, @recs ) = @_;
        if ( my $inf = $opts{inflate} ) {
            my $res = $self->inflate( $tableid, \@recs, $inf );
            return $limit ? ( $cnt, $res ) : $res;
        }
        return $limit ? ( $cnt, @recs ) : @recs;
    };

    my $table_info  = $self->table_info($tableid);
    my $use_ramdisk = $table_info ? ( $table_info->{use_ramdisk} // $table_info->{use_cache} // 0 ) : 0;
    if ($use_ramdisk) {
        $self->ramdisk_ensure($tableid);
    }
    my $table_path  = $self->table_path($tableid);
    my $idx_path    = $use_ramdisk ? $self->ramdisk_path($tableid) : $table_path;
    my $file_path   = ( $use_ramdisk == 2 && -e "$idx_path.$self->{db_ext}" ) ? "$idx_path.$self->{db_ext}" : "$table_path.$self->{db_ext}";

    if ( $use_ramdisk == 3 ) {
        return unless $self->_check_ramdisk_ttl( $tableid, $file_path );
    }

    return unless -e $file_path;

    my $count;

    # no_index: schema-based or request-based bypass
    my $no_index  = $table_info->{no_index} || $opts{no_index};
    my $keys_only = $opts{keys_only}        || $self->config('keys_only');

    # Determine default read direction: defaults to 'desc' (newest first: N..1)
    my $dir = lc( $opts{dir} // $opts{order} // 'desc' );
    $dir = ( $dir eq 'asc' || $dir eq '1' ) ? 'asc' : 'desc';

    # If sort option specifies direction for primary key (e.g. sort => 'asc', sort => -0, sort => { reverse => 1 }, sort => { dir => 'asc' })
    if ( $opts{sort} ) {
        my $s_norm = $self->normalize_sort_opt( $opts{sort} );
        if ( $s_norm && ( !$s_norm->{blk} || $s_norm->{blk} eq '0' || $s_norm->{blk} eq 'id' ) ) {
            $dir = $s_norm->{dir};
        }
    }

    # 0. Sorted reading option (.inx binary key sequence)
    if ( my $s_opt = $opts{sort} ) {
        my $s_norm    = $self->normalize_sort_opt($s_opt);
        my $blk       = $s_norm->{blk};
        my $s_dir     = $s_norm->{dir};

        if ( $blk && $blk ne '0' && $blk ne 'id' ) {
            my $jnkmode  = $table_info->{use_junk} ? $self->get_jnktype( $table_info, \%opts ) : 'ALL';
            my $tier_pfx = ( $jnkmode eq 'A' ) ? 'A:' : ( $jnkmode eq 'B' ) ? 'B:' : '';
            my $key        = "$tier_pfx$blk:keys";
            my $index_path = ( -e "$idx_path.inx" ) ? "$idx_path.inx" : "$table_path.inx";

            if ( $jnkmode ne 'AB' && $jnkmode ne 'BA' && -e $index_path && !$no_index && !$opts{range} ) {
                my ( $total_count, @sliced_ids ) = $self->index_get( $index_path, $key, "ids", $offset, $limit, $s_dir );

                if (@sliced_ids) {
                    if ($keys_only) {
                        return $limit ? ( $total_count, @sliced_ids ) : @sliced_ids;
                    }

                    my @recs = $self->read_list( $tableid, \@sliced_ids );
                    return $format_return->( $total_count, @recs );
                }
            }
        }
    }

    # 1. Primary record index (.inx binary key sequence)
    if ( $table_info->{record_index} && !$no_index ) {
        my $index_path = ( -e "$idx_path.inx" ) ? "$idx_path.inx" : "$table_path.inx";
        my $use_junk   = $table_info->{use_junk};
        my $jnkmode    = $use_junk ? $self->get_jnktype( $table_info, \%opts ) : 'ALL';

        my $has_sort = $opts{sort} && ( ref($opts{sort}) eq 'HASH' ? $opts{sort}->{blk} : $opts{sort} );
        my $is_secondary_sort = ( $has_sort && $has_sort ne '0' && $has_sort ne 'id' && $has_sort !~ /^(asc|desc|reverse)$/i ) ? 1 : 0;
        my $primary_key = ( $jnkmode eq 'A' ) ? 'A:keys' : ( $jnkmode eq 'B' ) ? 'B:keys' : ( $jnkmode eq 'ALL' || !$use_junk ) ? 'keys' : undef;

        if ( $primary_key && !$is_secondary_sort && !$opts{range} && $limit && -e $index_path ) {
            my ( $cnt, @paged_ids ) = $self->index_get( $index_path, $primary_key, "ids", $offset, $limit, $dir );
            if ($keys_only) {
                return $limit ? ( $cnt, @paged_ids ) : @paged_ids;
            }
            my @recs = $self->read_list( $tableid, \@paged_ids );
            return $format_return->( $cnt, @recs );
        }

        my @all_ids;
        if ( -e $index_path ) {
            if ( $jnkmode eq 'A' ) {
                ( undef, @all_ids ) = $self->index_get( $index_path, "A:keys", "ids", 0, 0, $dir );
            }
            elsif ( $jnkmode eq 'B' ) {
                ( undef, @all_ids ) = $self->index_get( $index_path, "B:keys", "ids", 0, 0, $dir );
            }
            elsif ( $jnkmode eq 'AB' ) {
                my ( undef, @a_ids ) = $self->index_get( $index_path, "A:keys", "ids", 0, 0, $dir );
                my ( undef, @b_ids ) = $self->index_get( $index_path, "B:keys", "ids", 0, 0, $dir );
                @all_ids = ( @a_ids, @b_ids );
            }
            elsif ( $jnkmode eq 'BA' ) {
                my ( undef, @a_ids ) = $self->index_get( $index_path, "A:keys", "ids", 0, 0, $dir );
                my ( undef, @b_ids ) = $self->index_get( $index_path, "B:keys", "ids", 0, 0, $dir );
                @all_ids = ( @b_ids, @a_ids );
            }
            else {
                ( undef, @all_ids ) = $self->index_get( $index_path, "keys", "ids", 0, 0, $dir );
            }
        }

        if ( my $ranges = $self->normalize_range_opts( $tableid, \%opts ) ) {
            @all_ids = $self->filter_ids_by_range( $tableid, \@all_ids, $ranges );
        }

        if (@all_ids) {
            my $has_sort = $opts{sort} && ( ref($opts{sort}) eq 'HASH' ? $opts{sort}->{blk} : $opts{sort} );
            my $is_secondary_sort = ( $has_sort && $has_sort ne '0' && $has_sort ne 'id' && $has_sort !~ /^(asc|desc|reverse)$/i ) ? 1 : 0;
            if ($is_secondary_sort) {
                my @sorted_ids = $self->sort_by_block( $tableid, \@all_ids, $opts{sort} );
                my ( $cnt, @paged_ids );
                if ($limit) {
                    ( $cnt, @paged_ids ) = $self->recs_cutting( $offset, $limit, @sorted_ids );
                }
                else {
                    ( $cnt, @paged_ids ) = ( scalar @sorted_ids, @sorted_ids );
                }

                if ($keys_only) {
                    return $limit ? ( $cnt, @paged_ids ) : @paged_ids;
                }
                my @recs = $self->read_list( $tableid, \@paged_ids );
                return $format_return->( $cnt, @recs );
            }
            else {
                my ( $cnt, @paged_ids );
                if ($limit) {
                    ( $cnt, @paged_ids ) = $self->recs_cutting( $offset, $limit, @all_ids );
                }
                else {
                    ( $cnt, @paged_ids ) = ( scalar @all_ids, @all_ids );
                }

                if ($keys_only) {
                    return $limit ? ( $cnt, @paged_ids ) : @paged_ids;
                }
                my @recs = $self->read_list( $tableid, \@paged_ids );
                return $format_return->( $cnt, @recs );
            }
        }
        else {
            return $limit ? ( 0, () ) : ();
        }
    }

    # Fallback: direct table scan (.db from RAM-disk when use_ramdisk == 2, or main disk .db)
    my $scan_path = $file_path;

    $self->table_read($scan_path) or do { cluck "[DB_TIE] $scan_path can't open.\n"; return; };
    @records = $self->recs_keys($scan_path);
    if ( !scalar @records ) {
        $self->table_close($scan_path);
        return $opts{inflate} ? $format_return->( 0, () ) : ( $limit ? ( 0, () ) : () );
    }

    if ( my $ranges = $self->normalize_range_opts( $tableid, \%opts ) ) {
        @records = $self->filter_ids_by_range( $tableid, \@records, $ranges );
    }

    # 2. Sort keys (in-memory sort_by_block if sort option requested)
    my $has_sort = $opts{sort} && ( ref($opts{sort}) eq 'HASH' ? $opts{sort}->{blk} : $opts{sort} );
    my $is_secondary_sort = ( $has_sort && $has_sort ne '0' && $has_sort ne 'id' && $has_sort !~ /^(asc|desc|reverse)$/i ) ? 1 : 0;
    if ($is_secondary_sort) {
        @records = $self->sort_by_block( $tableid, \@records, $opts{sort} );
    }
    else {
        my $id_sort_type = ( $self->config('simple') || ( $table_info && $table_info->{use_simple} ) ) ? 'ascii' : 'num';
        @records = $self->array_sort( $id_sort_type, $dir, undef, @records );
    }

    # 3. Apply slicing if limit is set
    if ($limit) {
        ( $count, @records ) = $self->recs_cutting( $offset, $limit, @records );
    }
    else {
        $count = scalar @records;
    }

    # 4. Fetch full record data unless keys_only
    unless ($keys_only) {
        my $recs_data = $self->recs_get( $scan_path, @records );
        foreach my $rec (@records) {
            my $val     = $recs_data ? $recs_data->{$rec} : undef;
            my @decoded = defined $val ? $self->db_decode($val) : ();
            my @clean   = $self->dec_validate( $tableid, \@decoded );
            $rec = [ $rec, @clean ];
        }
    }
    $self->table_close($scan_path);

    return $format_return->( $count, @records );
}



# get a list of records from table.
# ------------------------------------------------
sub read_list {

    my ( $self, $tableid, $ids ) = @_;

    $tableid or return;
    $ids     or return;

    ref $ids eq "ARRAY" or $ids = [$ids];
    return unless @$ids;

    if ( $self->config('keys_only') ) {
        return @$ids;
    }

    my $table_info  = $self->table_info($tableid);
    my $use_ramdisk = $table_info ? ( $table_info->{use_ramdisk} // $table_info->{use_cache} // 0 ) : 0;
    if ($use_ramdisk) {
        $self->ramdisk_ensure($tableid);
    }

    my $links      = $self->read_links( $tableid, @$ids );
    my $table_path = $self->table_path($tableid);
    my $data_path  = ( $use_ramdisk == 2 ) ? $self->ramdisk_path($tableid) : $table_path;
    my $file_path  = "$data_path.$self->{db_ext}";
    if ( $use_ramdisk == 2 && !-e $file_path ) {
        $file_path = "$table_path.$self->{db_ext}";
    }
    if ( $use_ramdisk == 3 ) {
        return unless $self->_check_ramdisk_ttl( $tableid, $file_path );
    }
    return unless -e $file_path;

    my %rec_by_id;
    my @lookup_keys;
    my %esc_map;
    foreach my $orig_id (@$ids) {
        my $rid = $links->{$orig_id} || $orig_id;
        next if $rec_by_id{$rid};
        push @lookup_keys, $rid;
        my $key_esc = $self->key_encode($rid);
        if ( defined $key_esc && $key_esc ne $rid ) {
            push @lookup_keys, $key_esc;
            $esc_map{$rid} = $key_esc;
        }
    }

    $self->table_read($file_path) or do { cluck "[DB_TIE] $file_path can't open.\n"; return; };
    my $recs_data = $self->recs_get( $file_path, @lookup_keys );
    $self->table_close($file_path);
    if ($recs_data) {
        foreach my $orig_id (@$ids) {
            my $rid = $links->{$orig_id} || $orig_id;
            next if $rec_by_id{$rid};

            my $key_esc = $esc_map{$rid};
            my $value   = $recs_data->{$rid} // ( defined $key_esc ? $recs_data->{$key_esc} : undef );
            next unless defined $value && $value ne '';

            my @decoded = $self->db_decode($value);
            @decoded    = $self->dec_validate( $tableid, \@decoded );
            $rec_by_id{$rid} = [ $rid, @decoded ];
        }
    }

    if ( $use_ramdisk == 3 && %rec_by_id ) {
        utime( undef, undef, $file_path );
    }

    $self->auth_read( $tableid, $table_path, @$ids );

    # Preserve exact requested ID order
    my @records;
    foreach my $orig_id (@$ids) {
        my $rid = $links->{$orig_id} || $orig_id;
        if ( my $rec = $rec_by_id{$rid} ) {
            push @records, $rec;
        }
    }

    return @records;
}

# my @records = $adb->read_links($tableid, @rids);
# Returns rid -> canonical_rid mapping from .lnk file.
# ------------------------------------------------
sub read_links {

    my ( $self, $tableid, @records ) = @_;

    $tableid        or return;
    scalar @records or return;

    my $table_path = $self->table_path($tableid);
    return unless -e "$table_path.$self->{db_ext}";
    return unless -e "$table_path.lnk";

    if ( (scalar @records) == 1 && ref $records[0] eq "ARRAY" ) {
        @records = @{ $records[0] };
    }

    my $links = {};
    scalar @records or return $links;

    my @lookup_keys;
    my %esc_map;
    foreach my $rid (@records) {
        push @lookup_keys, $rid;
        my $rid_escape = $self->key_encode($rid);
        if ( defined $rid_escape && $rid_escape ne $rid ) {
            push @lookup_keys, $rid_escape;
            $esc_map{$rid} = $rid_escape;
        }
    }

    my $lnk_path = "$table_path.lnk";
    $self->table_read($lnk_path) or return $links;
    my $recs_data = $self->recs_get( $lnk_path, @lookup_keys );
    $self->table_close($lnk_path);
    if ($recs_data) {
        foreach my $rid (@records) {
            my $rid_escape = $esc_map{$rid};
            my $val = $recs_data->{$rid} // ( defined $rid_escape ? $recs_data->{$rid_escape} : undef );
            if ( defined $val && $val ne '' ) {
                $links->{$rid} = $val;
            }
        }
    }
    return $links;
}

# Returns first record by numerical order or specified sort block (alias to read_id with type => 'first').
# ------------------------------------------------
sub read_firstid {

    my ( $self, $tableid, @args ) = @_;

    $tableid or return;
    my $opts = ( @args == 1 && ref($args[0]) eq 'HASH' ) ? { %{ $args[0] } }
             : ( @args >= 2 && ref($args[1]) eq 'HASH' ) ? { %{ $args[1] } }
             : ( @args && ref($args[-1]) eq 'HASH' )     ? { %{ $args[-1] } }
             : ( @args && !ref($args[-1]) && $args[-1] =~ /^(?:inflate|counter|no_counter|deleted|alias|links)$/i ) ? { $args[-1] => 1 }
             : ( @args == 1 && !ref($args[0]) && $args[0] ne '' && $args[0] ne '0' ) ? { sort => $args[0] }
             : ( @args >= 2 && !ref($args[1]) && $args[1] ne '' && $args[1] ne '0' ) ? { sort => $args[1] }
             : {};
    $opts->{type} = 'first';
    return $self->read_id( $tableid, 0, $opts );
}

# Returns last record by numerical order or specified sort block (alias to read_id with type => 'last').
# ------------------------------------------------
sub read_lastid {

    my ( $self, $tableid, @args ) = @_;

    $tableid or return;
    my $opts = ( @args == 1 && ref($args[0]) eq 'HASH' ) ? { %{ $args[0] } }
             : ( @args >= 2 && ref($args[1]) eq 'HASH' ) ? { %{ $args[1] } }
             : ( @args && ref($args[-1]) eq 'HASH' )     ? { %{ $args[-1] } }
             : ( @args && !ref($args[-1]) && $args[-1] =~ /^(?:inflate|counter|no_counter|deleted|alias|links)$/i ) ? { $args[-1] => 1 }
             : ( @args == 1 && !ref($args[0]) && $args[0] ne '' && $args[0] ne '0' ) ? { sort => $args[0] }
             : ( @args >= 2 && !ref($args[1]) && $args[1] ne '' && $args[1] ne '0' ) ? { sort => $args[1] }
             : {};
    $opts->{type} = 'last';
    return $self->read_id( $tableid, 0, $opts );
}

# Returns random record (alias to read_id with type => 'rand').
# ------------------------------------------------
sub read_randid {

    my ( $self, $tableid, @args ) = @_;

    $tableid or return;
    my $opts = ( @args == 1 && ref($args[0]) eq 'HASH' ) ? { %{ $args[0] } }
             : ( @args >= 2 && ref($args[1]) eq 'HASH' ) ? { %{ $args[1] } }
             : ( @args && ref($args[-1]) eq 'HASH' )     ? { %{ $args[-1] } }
             : ( @args && !ref($args[-1]) && $args[-1] =~ /^(?:inflate|counter|no_counter|deleted|alias|links)$/i ) ? { $args[-1] => 1 }
             : {};
    $opts->{type} = 'rand';
    return $self->read_id( $tableid, 0, $opts );
}

# Returns read count of a record from .cnt file.
# ------------------------------------------------
sub read_count {

    my ( $self, $tableid, $rid ) = @_;

    $tableid or return;
    $rid     or return;

    # Resolve table path and read record
    my $table_path = $self->table_path($tableid);
    my $count_path = "$table_path.cnt";

    # Plural support: If $rid is an ARRAY ref [ $id1, $id2, ... ]
    if ( ref($rid) eq 'ARRAY' ) {
        my %counts;
        for my $id (@$rid) {
            next unless defined $id && $id ne '';
            if ( -e $count_path ) {
                my @c = $self->table_readid( $count_path, $id );
                $counts{$id} = $c[1] || 0;
            }
            else {
                $counts{$id} = 0;
            }
        }
        return \%counts;
    }

    # Singular path
    return 0 unless -e $count_path;
    my @count = $self->table_readid( $count_path, $rid );

    return ( $count[1] || 0 );
}

# my @rids = $adb->read_field("invoice_active", 2, $values);
# Returns record IDs matching specified value via .fld index. $values may be arrayref.
# ------------------------------------------------
sub read_field {

    my ( $self, $tableid, $field, $values ) = @_;

    $tableid or return;
    defined $field && $field ne '' or return;

    my $table_info = $self->table_info($tableid);
    my $table_path = $self->table_path($tableid);
    my $field_path = "${table_path}.fld";
    my $unq_path   = "${table_path}.unq";

    return unless -e $field_path;

    if ($values) {
        my @values = $self->get_fieldlist( $values, $table_path, $table_info, $field );

        if ( @values == 1 ) {
            my $val = $values[0];
            my $key = "$field:$val";
            my ( undef, @ids ) = $self->index_get( $field_path, $key );
            if ( !@ids && -e $unq_path ) {
                my ($c) = $self->index_get( $unq_path, "$field:s:$val", 'raw' );
                if ( defined $c && $c ne '' ) {
                    ( undef, @ids ) = $self->index_get( $field_path, "$field:$c" );
                }
            }
            return @ids;
        }

        my @query_keys = map { "$field:$_" } @values;
        my $raw_hash = $self->index_get( $field_path, \@query_keys, 'raw' );
        my @raw_buffers;
        for my $val (@values) {
            my $k = "$field:$val";
            my $raw = $raw_hash->{$k} if $raw_hash && ref($raw_hash) eq 'HASH';
            if ( ( !defined $raw || length($raw) < 8 ) && -e $unq_path ) {
                my ($c) = $self->index_get( $unq_path, "$field:s:$val", 'raw' );
                if ( defined $c && $c ne '' ) {
                    ($raw) = $self->index_get( $field_path, "$field:$c", 'raw' );
                }
            }
            push @raw_buffers, $raw if defined $raw && length($raw) >= 8;
        }
        return () unless @raw_buffers;
        return $self->bin_crop( { mode => 'or' }, \@raw_buffers );
    }
    else {
        if ( -e $field_path && $self->table_read($field_path) ) {
            my @all = $self->recs_keys($field_path);
            $self->table_close($field_path);
            my $pfx = "$field:";
            @all = map { s/^\Q$pfx\E//; $_ } grep { /^\Q$pfx\E/ } @all;
            return @all;
        }
        return ();
    }
}

# my @record_ids = $adb->read_search("invoice_active", [ blok2, blok4 ], $search_string);
# Searches across multiple .src blocks; returns IDs present in all blocks (AND logic).
# ------------------------------------------------
sub read_search {
    my ( $self, $tableid, $blok, $string, %opts ) = @_;

    $tableid or return;
    $blok    or return;
    $string  or return;

    my $table_path = $self->table_path($tableid);
    ref($blok) eq "ARRAY" or $blok = [$blok];
    my %words = $self->get_words( $string, "read", $tableid );
    return () unless %words;

    my $unified_src = "${table_path}.src";
    if ( -e $unified_src ) {
        # Cross-block search mode (each word may match in any of the specified blocks)
        if ( $opts{cross_block} || ( $opts{mode} && $opts{mode} eq 'cross' ) ) {
            my @word_groups;
            for my $word ( keys %words ) {
                my @keys = map { "$_:$word" } @$blok;
                my $raw_hash = $self->index_get( $unified_src, \@keys, 'raw' );
                my @raws;
                if ( $raw_hash && ref($raw_hash) eq 'HASH' ) {
                    for my $k (@keys) {
                        my $r = $raw_hash->{$k};
                        push @raws, $r if defined $r && length($r) >= 8;
                    }
                }
                return () unless @raws;
                push @word_groups, \@raws;
            }
            return $self->bin_crop( { mode => 'and' }, @word_groups );
        }

        # Per-block AND search, then union of blocks
        my @all_matched;
        my @word_list = keys %words;
        my $word_cnt  = scalar @word_list;

        for my $b (@$blok) {
            my @keys = map { "$b:$_" } @word_list;
            my $raw_hash = $self->index_get( $unified_src, \@keys, 'raw' );
            my @word_groups;
            if ( $raw_hash && ref($raw_hash) eq 'HASH' ) {
                for my $k (@keys) {
                    my $raw = $raw_hash->{$k};
                    push @word_groups, $raw if defined $raw && length($raw) >= 8;
                }
            }
            next unless @word_groups == $word_cnt;
            my @b_ids = $self->bin_crop( { mode => 'and' }, @word_groups );
            push @all_matched, @b_ids;
        }

        if ( @$blok == 1 ) {
            return @all_matched;
        }
        return @all_matched ? $self->array_nodup(@all_matched) : ();
    }

    return ();
}


# my @records = $adb->field_fetch("tableid", $blokno, "fetch");
# my ($count, @records) = $adb->field_fetch("tableid", $blokno, [ "fetch1", "fetch2" ], $offset, $limit);
# ------------------------------------------------
sub field_fetch {

    my ( $self, $tableid, $block, $fetch, @args ) = @_;

    $tableid     or return;
    $block ne "" or return;
    $fetch ne "" or return;

    my ( $offset, $limit, %opts );
    if ( @args == 1 && ref( $args[0] ) eq 'HASH' ) {
        %opts   = %{ $args[0] };
        $offset = $opts{offset} // $opts{start} // 0;
        $limit  = $opts{limit}  // 0;
    }
    else {
        if ( @args && ( !defined $args[0] || $args[0] =~ /^\d+$/ ) ) {
            $offset = shift @args;
        }
        if ( @args && ( !defined $args[0] || $args[0] =~ /^\d+$/ ) ) {
            $limit = shift @args;
        }
        if ( @args && @args % 2 == 0 ) {
            %opts = @args;
        }
    }
    $offset //= $opts{offset} // $opts{start} // 0;
    $limit  //= $opts{limit}  // 0;

    my $dir = lc( $opts{dir} // $opts{order} // 'desc' );
    $dir = ( $dir eq 'asc' || $dir eq '1' ) ? 'asc' : 'desc';

    my ( $count, @records );
    my $format_return = sub {
        my ( $cnt, @recs ) = @_;
        if ( my $inf = $opts{inflate} ) {
            my $res = $self->inflate( $tableid, \@recs, $inf );
            return $limit ? ( $cnt, $res ) : $res;
        }
        return $limit ? ( $cnt, @recs ) : @recs;
    };

    my $table_info  = $self->table_info($tableid);
    my $use_ramdisk = $table_info ? ( $table_info->{use_ramdisk} // $table_info->{use_cache} // 0 ) : 0;
    if ($use_ramdisk) {
        $self->ramdisk_ensure($tableid);
    }
    my $table_path = $self->table_path($tableid);
    my $idx_path   = $use_ramdisk ? $self->ramdisk_path($tableid) : $table_path;
    my $file_path  = ( $use_ramdisk == 2 && -e "$idx_path.$self->{db_ext}" ) ? "$idx_path.$self->{db_ext}" : "$table_path.$self->{db_ext}";
    return unless -e $file_path;

    my @fld_fetch_ids = $self->get_fieldlist( $fetch, $idx_path, $table_info, $block );

    my $field_path = ( -e "${idx_path}.fld" ) ? "${idx_path}.fld" : "${table_path}.fld";

    if ( -e $field_path ) {
        my $use_junk = $table_info ? $table_info->{use_junk} : undef;
        my $jnkmode  = $use_junk ? $self->get_jnktype( $table_info, \%opts ) : 'ALL';

        # ---------------------------------------------------------------------
        # CASE 1: Single value, default sort, pagination ($limit) requested -> O(1) Fast Slice!
        # ---------------------------------------------------------------------
        if ( @fld_fetch_ids == 1 && !$opts{sort} && $limit && $limit > 0 && ( $jnkmode eq 'ALL' || $jnkmode eq 'A' || $jnkmode eq 'B' ) ) {
            my $val = $fld_fetch_ids[0];
            my $tier_pfx = ( $jnkmode eq 'A' ) ? 'A:' : ( $jnkmode eq 'B' ) ? 'B:' : '';
            my $key = "$tier_pfx$block:$val";
            my ( $total, @slice_ids ) = $self->index_get( $field_path, $key, 'ids', $offset, $limit, $dir );
            if ($total) {
                $count = $total;
                @records = @slice_ids;
                if ( $opts{keys_only} || $self->config('keys_only') ) {
                    return ( $count, @records );
                }
                @records = $self->read_list( $tableid, [@records] );
                return $format_return->( $count, @records );
            }
        }

        # ---------------------------------------------------------------------
        # CASE 2: Multi-value, sort, or tiered concatenation (AB/BA) -> collect buffers
        # ---------------------------------------------------------------------
        my $get_tier_raw_buffers = sub {
            my ($pfx) = @_;
            my @buffers;
            if ( @fld_fetch_ids == 1 ) {
                my $val = $fld_fetch_ids[0];
                my $key = "$pfx$block:$val";
                my ($raw) = $self->index_get( $field_path, $key, 'raw' );
                push @buffers, $raw if defined $raw && length($raw) >= 8;
            }
            else {
                my @query_keys = map { "$pfx$block:$_" } @fld_fetch_ids;
                my $raw_hash = $self->index_get( $field_path, \@query_keys, 'raw' );
                for my $val (@fld_fetch_ids) {
                    my $k = "$pfx$block:$val";
                    my $raw = $raw_hash->{$k} if $raw_hash && ref($raw_hash) eq 'HASH';
                    push @buffers, $raw if defined $raw && length($raw) >= 8;
                }
            }
            return @buffers;
        };

        if ( $jnkmode eq 'ALL' ) {
            my @raw_buffers = $get_tier_raw_buffers->('');
            return unless @raw_buffers;
            @records = $self->bin_crop( { mode => 'or', dir => $dir }, \@raw_buffers );
        }
        elsif ( $jnkmode eq 'A' ) {
            my @raw_buffers = $get_tier_raw_buffers->('A:');
            return unless @raw_buffers;
            @records = $self->bin_crop( { mode => 'or', dir => $dir }, \@raw_buffers );
        }
        elsif ( $jnkmode eq 'B' ) {
            my @raw_buffers = $get_tier_raw_buffers->('B:');
            return unless @raw_buffers;
            @records = $self->bin_crop( { mode => 'or', dir => $dir }, \@raw_buffers );
        }
        elsif ( $jnkmode eq 'AB' ) {
            my @a_bufs = $get_tier_raw_buffers->('A:');
            my @b_bufs = $get_tier_raw_buffers->('B:');
            my @a_recs = @a_bufs ? $self->bin_crop( { mode => 'or', dir => $dir }, \@a_bufs ) : ();
            my @b_recs = @b_bufs ? $self->bin_crop( { mode => 'or', dir => $dir }, \@b_bufs ) : ();
            @records = ( @a_recs, @b_recs );
        }
        elsif ( $jnkmode eq 'BA' ) {
            my @a_bufs = $get_tier_raw_buffers->('A:');
            my @b_bufs = $get_tier_raw_buffers->('B:');
            my @a_recs = @a_bufs ? $self->bin_crop( { mode => 'or', dir => $dir }, \@a_bufs ) : ();
            my @b_recs = @b_bufs ? $self->bin_crop( { mode => 'or', dir => $dir }, \@b_bufs ) : ();
            @records = ( @b_recs, @a_recs );
        }
        else {
            my @raw_buffers = $get_tier_raw_buffers->('');
            return unless @raw_buffers;
            @records = $self->bin_crop( { mode => 'or', dir => $dir }, \@raw_buffers );
        }

        return unless @records;

        if ( my $ranges = $self->normalize_range_opts( $tableid, \%opts ) ) {
            @records = $self->filter_ids_by_range( $tableid, \@records, $ranges );
            return unless @records;
        }

        # Sort
        if ( $opts{sort} ) {
            @records = $self->sort_by_block( $tableid, \@records, $opts{sort} );
        }
        elsif ( $jnkmode eq 'ALL' ) {
            my $id_sort_type = ( $self->config('simple') || ( $table_info && $table_info->{use_simple} ) ) ? 'ascii' : 'num';
            @records = $self->array_sort( $id_sort_type, $dir, undef, @records );
        }

        $count = scalar @records;

        # Slice if limit set
        if ($limit) {
            ( $count, @records ) = $self->recs_cutting( $offset, $limit, @records );
        }

        # Return keys only if requested
        if ( $opts{keys_only} || $self->config('keys_only') ) {
            return $limit ? ( $count, @records ) : @records;
        }

        # Read records
        @records = $self->read_list( $tableid, [@records] );
    }

    # If index file does not exist (unindexed fallback)...
    else {
        my @raw_fetch = $self->get_fieldlist($fetch);
        my %fetch = map { $_ => 1 } ( @raw_fetch, @fld_fetch_ids );

        $self->table_read($file_path) or return;
        $self->recs_scan(
            $file_path,
            sub {
                my ( $key, $val ) = @_;
                my @fields = ( $key, $self->db_decode($val) );
                $block <= $#fields or return;
                defined $fields[$block] or return;
                my @fld_val = $self->get_fieldlist( $fields[$block] );
                foreach my $fld_one (@fld_val) {
                    if ( $fld_one && exists( $fetch{$fld_one} ) ) {
                        push( @records, [@fields] );
                        last;
                    }
                }
            }
        );
        $self->table_close($file_path);
        scalar @records or return;

        if ( my $ranges = $self->normalize_range_opts( $tableid, \%opts ) ) {
            @records = $self->filter_ids_by_range( $tableid, \@records, $ranges );
            return unless @records;
        }

        # Sorting
        if ( $opts{sort} ) {
            @records = $self->sort_by_block_records( $tableid, \@records, $opts{sort} );
        }
        else {
            my $id_sort_type = ( $self->config('simple') || ( $table_info && $table_info->{use_simple} ) ) ? 'ascii' : 'num';
            @records = $self->array_sort( $id_sort_type, $dir, 0, @records );
        }
        $count = scalar @records;

        if ($limit) {
            ( $count, @records ) = $self->recs_cutting( $offset, $limit, @records );
        }

        if ( $opts{keys_only} || $self->config('keys_only') ) {
            @records = map { $$_[0] } @records;
            return $limit ? ( $count, @records ) : @records;
        }
    }

    return $format_return->( $count, @records );
}

# all keys of a blok from table — .fld index varsa ondan, yoksa tam tarama ile.
# my @record_ids = $adb->field_keys("tablename", 2);
# ------------------------------------------------
sub field_keys {

    my ( $self, $tableid, $field ) = @_;

    $tableid or return;
    defined $field && $field ne '' or return;

    my $table_info  = $self->table_info($tableid);
    my $use_ramdisk = $table_info ? ( $table_info->{use_ramdisk} // $table_info->{use_cache} // 0 ) : 0;
    if ($use_ramdisk) {
        $self->ramdisk_ensure($tableid);
    }
    my $table_path = $self->table_path($tableid);
    my $idx_path   = $use_ramdisk ? $self->ramdisk_path($tableid) : $table_path;
    my $file_path  = ( $use_ramdisk == 2 && -e "$idx_path.$self->{db_ext}" ) ? "$idx_path.$self->{db_ext}" : "$table_path.$self->{db_ext}";

    # Plural support: If $field is an ARRAY ref [ $f1, $f2, ... ]
    if ( ref($field) eq 'ARRAY' ) {
        my %multi_keys;
        for my $f (@$field) {
            my @keys = $self->field_keys( $tableid, $f );
            $multi_keys{$f} = \@keys;
        }
        return \%multi_keys;
    }

    my $field_path = ( -e "${idx_path}.fld" ) ? "${idx_path}.fld" : "${table_path}.fld";

    # read from index file and get keys.
    my @allkeys;
    if ( -e $field_path ) {
        if ( $self->table_read($field_path) ) {
            @allkeys = $self->recs_keys($field_path);
            $self->table_close($field_path);
            my $pfx = "$field:";
            @allkeys = map { s/^\Q$pfx\E//; $_ } grep { /^\Q$pfx\E/ } @allkeys;
            @allkeys = $self->db_sortid( $tableid, @allkeys );
        }
    }
    else {
        my %fetch_list;
        if ( -e $file_path && $self->table_read($file_path) ) {
            $self->recs_scan(
                $file_path,
                sub {
                    my ( $key, $val ) = @_;
                    my @temp = ( $key, $self->db_decode($val) );
                    $fetch_list{ $temp[$field] } = 1 if defined $temp[$field];
                }
            );
            $self->table_close($file_path);
            @allkeys = $self->db_sortid( $tableid, ( keys %fetch_list ) );
        }
    }

    return @allkeys;
}

# Returns map of value -> ID list for a .fld block. If $keyid is passed, returns list for that key only.
# my $results = $adb->field_keyvals(TABLENAME, FIELD);
# my $results = $adb->field_keyvals(TABLENAME, FIELD, [KEY]);
# ------------------------------------------------
sub field_keyvals {

    my ( $self, $tableid, $field, $keyid ) = @_;

    $tableid or return;
    defined $field && $field ne '' or return;

    my $table_info  = $self->table_info($tableid);
    my $use_ramdisk = $table_info ? ( $table_info->{use_ramdisk} // $table_info->{use_cache} // 0 ) : 0;
    if ($use_ramdisk) {
        $self->ramdisk_ensure($tableid);
    }

    # set table path.
    my $table_path = $self->table_path($tableid);
    my $idx_path   = $use_ramdisk ? $self->ramdisk_path($tableid) : $table_path;
    my $file_path  = ( $use_ramdisk == 2 && -e "$idx_path.$self->{db_ext}" ) ? "$idx_path.$self->{db_ext}" : "$table_path.$self->{db_ext}";
    my $field_path = ( -e "${idx_path}.fld" ) ? "${idx_path}.fld" : "${table_path}.fld";

    # read from index file and get keys.
    my %records;
    if ( -e $field_path ) {
        if ( defined $keyid && $keyid ne '' ) {
            my @req_keys = ref($keyid) eq 'ARRAY' ? @$keyid : ($keyid);
            for my $k_item (@req_keys) {
                my @req_ids = $self->get_fieldlist( $k_item, $idx_path, $table_info, $field );
                next unless @req_ids;

                # Single key fast path
                if ( @req_ids == 1 ) {
                    my $qk = "$field:$req_ids[0]";
                    my ($raw) = $self->index_get( $field_path, $qk, 'raw' );
                    if ( defined $raw && length($raw) >= 8 ) {
                        my ( undef, @ids ) = $self->bin_decode($raw);
                        $records{$k_item} = \@ids;
                    }
                    else {
                        $records{$k_item} = [];
                    }
                    next;
                }

                # Plural keys: batch fetch all raw buffers in one single pass & bin_crop union
                my @qks = map { "$field:$_" } @req_ids;
                my $raw_hash = $self->index_get( $field_path, \@qks, 'raw' );
                my @raw_buffers;
                if ( $raw_hash && ref($raw_hash) eq 'HASH' ) {
                    for my $qid (@req_ids) {
                        my $qk = "$field:$qid";
                        my $r = $raw_hash->{$qk};
                        push @raw_buffers, $r if defined $r && length($r) >= 8;
                    }
                }

                if (@raw_buffers) {
                    my @ids = $self->bin_crop( { mode => 'or' }, \@raw_buffers );
                    $records{$k_item} = \@ids;
                }
                else {
                    $records{$k_item} = [];
                }
            }
        }
        else {
            if ( $self->table_read($field_path) ) {
                $self->recs_scan(
                    $field_path,
                    sub {
                        my ( $key, $v ) = @_;
                        my $pfx = "$field:";
                        return unless $key =~ /^\Q$pfx\E/;
                        $key =~ s/^\Q$pfx\E//;
                        return unless defined $v && length($v) >= 8;
                        my ( undef, @ids ) = $self->bin_decode($v);
                        $records{$key} = \@ids;
                    }
                );
                $self->table_close($field_path);
            }
        }
    }
    else {
        if ( -e $file_path && $self->table_read($file_path) ) {
            $self->recs_scan(
                $file_path,
                sub {
                    my ( $key, $val ) = @_;
                    my @temp = ( $key, $self->db_decode($val) );
                    if ( defined $keyid && $keyid ne '' ) {
                        return unless $temp[$field] eq $keyid;
                    }
                    push @{ $records{ $temp[$field] } }, $key if defined $temp[$field];
                }
            );
            $self->table_close($file_path);
        }
    }

    return \%records;
}

# Performs comparative field search across database blocks.
# my $field_obj = $adb->field_filter("table_name", { filter => { f1 => v1, f2 => [v2,v3] }, offset=>0, limit=>20 })
# my $field_obj = $adb->field_filter("table_name", [field1, find1], [field2, find2] ...);
# my $field_obj = $adb->field_filter("table_name", [field1, find1], $offset, $limit)
# $field_obj    = { count => $count, keys => \@keys }
# ------------------------------------------------
sub field_filter {

    my ( $self, $tableid, @args ) = @_;

    $tableid or return;
    @args    or return;

    my $table_info = $self->table_info($tableid);

    my ( $type, $offset, $limit, $s_opt, %filter, %opts );

    if ( ref( $args[0] ) eq 'HASH' ) {
        if ( @args >= 2 && ref( $args[1] ) eq 'HASH' ) {
            %opts = %{ $args[1] };
            $opts{filter} //= $args[0];
        }
        else {
            %opts = %{ $args[0] };
        }
        $type   = lc( $opts{type}   || 'and' );
        $offset = $opts{offset}     // $opts{start} // 0;
        $limit  = $opts{limit}      || 0;
        $s_opt  = $opts{sort};
        %filter = %{ $opts{where}   || $opts{filter} || $opts{match} || {} };
        if ( !%filter ) {
            for my $k ( keys %opts ) {
                next if $k =~ /^(type|offset|start|limit|sort|range)$/;
                $filter{$k} = $opts{$k};
            }
        }
    }
    else {
        $type = 'and';
        if ( $args[0] =~ /^(and|or)$/i ) { $type = lc( shift @args ) }
        if ( @args >= 2 && ref( $args[-1] ) ne 'ARRAY' && ref( $args[-2] ) ne 'ARRAY' ) {
            $limit  = pop @args;
            $offset = pop @args;
        }
        foreach my $flt (@args) {
            ref($flt) eq 'ARRAY'                     or next;
            defined( $flt->[0] ) && $flt->[0] ne '' or next;
            defined( $flt->[1] ) && $flt->[1] ne '' or next;
            $filter{ $flt->[0] } = $flt->[1];
        }
    }

    $type =~ /^(and|or)$/ or $type = 'and';

    $table_info  = $self->table_info($tableid);
    my $use_ramdisk = $table_info ? ( $table_info->{use_ramdisk} // $table_info->{use_cache} // 0 ) : 0;
    if ($use_ramdisk) {
        $self->ramdisk_ensure($tableid);
    }
    my $table_path = $self->table_path($tableid);
    my $idx_path   = $use_ramdisk ? $self->ramdisk_path($tableid) : $table_path;
    my $file_path  = ( $use_ramdisk == 2 && -e "$idx_path.$self->{db_ext}" ) ? "$idx_path.$self->{db_ext}" : "$table_path.$self->{db_ext}";

    my ( @records, %fld_cnt );
    my $all_cnt = scalar keys %filter;

    my $use_junk = $table_info->{use_junk} if $table_info;
    my $jnkmode  = $use_junk ? $self->get_jnktype( $table_info, \%opts ) : 'ALL';

    my $run_filter_tier = sub {
        my ($tier) = @_;
        my $pfx = ( $tier eq 'A' ) ? 'A:' : ( $tier eq 'B' ) ? 'B:' : '';
        my $unified_fld = ( -e "${idx_path}.fld" ) ? "${idx_path}.fld" : "${table_path}.fld";

        if ( -e $unified_fld ) {
            my @filter_groups;
            my @all_req_keys;
            my %blk_vals_map;

            for my $blk ( keys %filter ) {
                my @values = $self->get_fieldlist( $filter{$blk}, $idx_path, $table_info, $blk );
                $blk_vals_map{$blk} = \@values;
                push @all_req_keys, map { "$pfx$blk:$_" } @values;
            }

            my $raw_hash = $self->index_get( $unified_fld, \@all_req_keys, 'raw' );

            for my $blk ( keys %filter ) {
                my @raw_buffers;
                my @values = @{ $blk_vals_map{$blk} };

                for my $val (@values) {
                    my $k = "$pfx$blk:$val";
                    my $raw = $raw_hash->{$k} if $raw_hash && ref($raw_hash) eq 'HASH';
                    push @raw_buffers, $raw if defined $raw && length($raw) >= 8;
                }
                return () if $type eq 'and' && !@raw_buffers;
                push @filter_groups, \@raw_buffers if @raw_buffers;
            }

            return () unless @filter_groups;
            return $self->bin_crop( { mode => $type }, @filter_groups );
        }

        return ();
    };

    my $has_fld = ( -e "${idx_path}.fld" || -e "${table_path}.fld" ) ? 1 : 0;

    if ($has_fld) {
        if ( $jnkmode eq 'ALL' ) {
            @records = $run_filter_tier->('ALL');
        }
        else {
            my ( @a_records, @b_records );
            if ( $jnkmode =~ /A/ ) {
                @a_records = $run_filter_tier->('A');
            }
            if ( $jnkmode =~ /B/ ) {
                @b_records = $run_filter_tier->('B');
            }

            if    ( $jnkmode eq 'A' )  { @records = @a_records }
            elsif ( $jnkmode eq 'B' )  { @records = @b_records }
            elsif ( $jnkmode eq 'AB' ) { @records = ( @a_records, @b_records ) }
            elsif ( $jnkmode eq 'BA' ) { @records = ( @b_records, @a_records ) }
        }
    }
    else {
        # Full scan fallback
        my %allowed_map;
        foreach my $blk ( keys %filter ) {
            my @vals = $self->get_fieldlist( $filter{$blk} );
            $allowed_map{$blk} = { map { $_ => 1 } @vals };
        }

        if ( -e $file_path && $self->table_read($file_path) ) {
            if ( $type eq 'and' ) {
                $self->recs_scan(
                    $file_path,
                    sub {
                        my ( $uid, $val ) = @_;
                        my @fields = ( $uid, $self->db_decode($val) );
                        foreach my $blk ( keys %allowed_map ) {
                            return unless $blk <= $#fields && defined $fields[$blk];
                            my @fld_vals = $self->get_fieldlist( $fields[$blk] );
                            my $matched = 0;
                            foreach my $one (@fld_vals) {
                                if ( exists $allowed_map{$blk}{$one} ) {
                                    $matched = 1;
                                    last;
                                }
                            }
                            return unless $matched;
                        }
                        push @records, $uid;
                    }
                );
            }
            else {
                $self->recs_scan(
                    $file_path,
                    sub {
                        my ( $uid, $val ) = @_;
                        my @fields = ( $uid, $self->db_decode($val) );
                        foreach my $blk ( keys %allowed_map ) {
                            next unless $blk <= $#fields && defined $fields[$blk];
                            my @fld_vals = $self->get_fieldlist( $fields[$blk] );
                            foreach my $one (@fld_vals) {
                                if ( exists $allowed_map{$blk}{$one} ) {
                                    push @records, $uid;
                                    return;
                                }
                            }
                        }
                    }
                );
            }
            $self->table_close($file_path);
        }
    }

    my %range_ctx = ref( $args[0] ) eq 'HASH' ? %{ $args[0] } : ();
    if ( @args >= 2 && ref( $args[1] ) eq 'HASH' ) {
        %range_ctx = ( %range_ctx, %{ $args[1] } );
    }
    if ( my $ranges = $self->normalize_range_opts( $tableid, \%range_ctx ) ) {
        @records = $self->filter_ids_by_range( $tableid, \@records, $ranges );
    }

    my $count = scalar @records;
    if ($s_opt) {
        @records = $self->sort_by_block( $tableid, \@records, $s_opt );
    }
    else {
        @records = $self->db_sortid( $tableid, @records );
    }

    $self->set_cache($tableid, "filter", \@records) if $table_info && ( $table_info->{use_facet} || $table_info->{use_cache} );

    if ($limit) {
        ( undef, @records ) = $self->recs_cutting( $offset, $limit, @records );
    }
    return { count => $count, ids => \@records || [] }
}

# Performs database search...
# my @search = $adb->search_table($tableid, $string);
# my ($count, @search) = $adb->search_table($tableid, $string, $and_or, $offset, $limit);
# my ($count, @search) = $adb->search_table($tableid, $string, offset => 0, limit => 20, sort => -4, filter => { field => 6, value => 12 });
# ------------------------------------------------
sub search_table {

    my ( $self, $tableid, $string, @args ) = @_;

    $tableid or return;
    $string  or return;

    my ( $offset, $limit, $and_or, %opts );
    if ( @args == 1 && ref( $args[0] ) eq 'HASH' ) {
        %opts   = %{ $args[0] };
        $offset = $opts{offset} // $opts{start} // 0;
        $limit  = $opts{limit}  // 0;
        $and_or = $opts{and_or} // $opts{type} // $opts{mode} // 'and';
    }
    elsif ( @args >= 2 && @args % 2 == 0 && defined $args[0] && $args[0] =~ /^(offset|start|limit|sort|filter|where|match|field|value|and_or|type|mode|keys_only)$/ ) {
        %opts   = @args;
        $offset = $opts{offset} // $opts{start} // 0;
        $limit  = $opts{limit}  // 0;
        $and_or = $opts{and_or} // $opts{type} // $opts{mode} // 'and';
    }
    else {
        if ( @args && defined $args[0] && ( $args[0] =~ /^(and|or)$/i || $args[0] eq '' ) ) {
            my $first = shift @args;
            $and_or = $first if $first =~ /^(and|or)$/i;
        }
        if ( @args && ( !defined $args[0] || $args[0] =~ /^\d+$/ ) ) {
            $offset = shift @args;
        }
        if ( @args && ( !defined $args[0] || $args[0] =~ /^\d+$/ ) ) {
            $limit = shift @args;
        }
        if ( @args && defined $args[0] && $args[0] =~ /^(and|or)$/i ) {
            $and_or = shift @args;
        }
        if ( @args && @args % 2 == 0 ) {
            %opts = @args;
        }
    }

    $offset //= $opts{offset} // $opts{start} // 0;
    $limit  //= $opts{limit} // 0;
    $and_or //= $opts{and_or} // $opts{type} // $opts{mode} // "and";
    $and_or =~ /^(and|or)$/i or $and_or = "and";

    # Normalize filter criteria (if filter requested)
    my %filter_map;
    my $filter = $opts{filter} // $opts{where} // $opts{match} // ( ( defined $opts{field} && defined $opts{value} ) ? { field => $opts{field}, value => $opts{value} } : undef );

    if ($filter) {
        if ( ref($filter) eq 'HASH' ) {
            if ( exists $filter->{field} && ( exists $filter->{value} || exists $filter->{val} ) ) {
                my $fld = $filter->{field};
                my $val = $filter->{value} // $filter->{val};
                if ( defined $fld && $fld ne '' && defined $val && $val ne '' ) {
                    $filter_map{$fld} = ref($val) eq 'ARRAY' ? $val : [ split /\s*[,;]\s*/, $val ];
                }
            }
            else {
                for my $fld ( keys %$filter ) {
                    my $val = $filter->{$fld};
                    if ( defined $fld && $fld ne '' && defined $val && $val ne '' ) {
                        $filter_map{$fld} = ref($val) eq 'ARRAY' ? $val : [ split /\s*[,;]\s*/, $val ];
                    }
                }
            }
        }
        elsif ( ref($filter) eq 'ARRAY' ) {
            if ( @$filter && ref( $filter->[0] ) eq 'ARRAY' ) {
                for my $pair (@$filter) {
                    if ( defined $pair->[0] && $pair->[0] ne '' && defined $pair->[1] && $pair->[1] ne '' ) {
                        my $val = $pair->[1];
                        $filter_map{ $pair->[0] } = ref($val) eq 'ARRAY' ? $val : [ split /\s*[,;]\s*/, $val ];
                    }
                }
            }
            elsif ( @$filter >= 2 && !ref( $filter->[0] ) ) {
                my $fld = $filter->[0];
                my $val = $filter->[1];
                if ( defined $fld && $fld ne '' && defined $val && $val ne '' ) {
                    $filter_map{$fld} = ref($val) eq 'ARRAY' ? $val : [ split /\s*[,;]\s*/, $val ];
                }
            }
        }
    }

    my $table_info  = $self->table_info($tableid);
    my $use_ramdisk = $table_info ? ( $table_info->{use_ramdisk} // $table_info->{use_cache} // 0 ) : 0;
    if ($use_ramdisk) {
        $self->ramdisk_ensure($tableid);
    }
    my ( $count, @records );
    my $table_path = $self->table_path($tableid);
    my $idx_path   = $use_ramdisk ? $self->ramdisk_path($tableid) : $table_path;
    my $file_path  = ( $use_ramdisk == 2 && -e "$idx_path.$self->{db_ext}" ) ? "$idx_path.$self->{db_ext}" : "$table_path.$self->{db_ext}";

    # ------------------------------------------------
    # A) Search Block Indexed Search (.src)
    # ------------------------------------------------
    if ( $table_info->{search_block} ) {

        my $use_junk = $table_info->{use_junk};
        my $jnkmode  = $use_junk ? $self->get_jnktype( $table_info, \%opts ) : 'ALL';

        my $run_search = sub {
            my ($tier) = @_;
            my $pfx = ( $tier eq 'A' ) ? 'A:' : ( $tier eq 'B' ) ? 'B:' : '';
            my %words = $self->get_words( $string, "read", $tableid );
            my $i     = keys %words;
            return () unless $i;

            my $unified_src = ( -e "${idx_path}.src" ) ? "${idx_path}.src" : "${table_path}.src";
            my @word_groups;

            if ( -e $unified_src ) {
                my @blocks;
                for my $blk ( @{ $table_info->{search_block} } ) {
                    my $b_idx = ref($blk) eq "ARRAY" ? $blk->[0] : $blk;
                    push @blocks, $b_idx;
                }
                for my $word ( keys %words ) {
                    my @keys = map { "$pfx$_:$word" } @blocks;
                    my $raw_hash = $self->index_get( $unified_src, \@keys, 'raw' );
                    my @blocks_raw;
                    if ( $raw_hash && ref($raw_hash) eq 'HASH' ) {
                        for my $k (@keys) {
                            my $r = $raw_hash->{$k};
                            push @blocks_raw, $r if defined $r && length($r) >= 8;
                        }
                    }
                    return () if $and_or eq "and" && !@blocks_raw;
                    push @word_groups, \@blocks_raw if @blocks_raw;
                }
            }
            return () unless @word_groups;
            my @tier_recs = $self->bin_crop( { mode => $and_or }, @word_groups );

            # Filter keys (.fld) and intersect (only if filter requested)
            if ( $filter && %filter_map && @tier_recs ) {
                my $unified_fld = ( -e "${idx_path}.fld" ) ? "${idx_path}.fld" : "${table_path}.fld";
                for my $fld ( keys %filter_map ) {
                    if ( -e $unified_fld ) {
                        my @mapped_vals = $self->get_fieldlist( $filter_map{$fld}, $idx_path, $table_info, $fld );
                        my @raw_fld_bufs;
                        if ( @mapped_vals == 1 ) {
                            my $k = "$pfx$fld:$mapped_vals[0]";
                            my ($raw) = $self->index_get( $unified_fld, $k, 'raw' );
                            push @raw_fld_bufs, $raw if defined $raw && length($raw) >= 8;
                        }
                        else {
                            my @qks = map { "$pfx$fld:$_" } @mapped_vals;
                            my $raw_hash = $self->index_get( $unified_fld, \@qks, 'raw' );
                            if ( $raw_hash && ref($raw_hash) eq 'HASH' ) {
                                for my $v (@mapped_vals) {
                                    my $k = "$pfx$fld:$v";
                                    my $r = $raw_hash->{$k};
                                    push @raw_fld_bufs, $r if defined $r && length($r) >= 8;
                                }
                            }
                        }

                        if (@raw_fld_bufs) {
                            # Pure index probing:
                            # Instead of decoding posting lists into giant hashes or touching .db,
                            # probe candidate IDs directly against the sorted 8-byte aligned buffers.
                            if ( @tier_recs <= 100 ) {
                                my @survivors;
                                for my $cid (@tier_recs) {
                                    my $target_bytes = pack( "Q>", $cid );
                                    my $found = 0;
                                    for my $raw (@raw_fld_bufs) {
                                        my $buf_count = int( length($raw) / 8 );
                                        my ( $low, $high ) = ( 0, $buf_count - 1 );
                                        while ( $low <= $high ) {
                                            my $mid = int( ( $low + $high ) / 2 );
                                            my $val = substr( $raw, $mid * 8, 8 );
                                            if ( $val eq $target_bytes ) {
                                                $found = 1;
                                                last;
                                            }
                                            elsif ( $val lt $target_bytes ) {
                                                $low = $mid + 1;
                                            }
                                            else {
                                                $high = $mid - 1;
                                            }
                                        }
                                        last if $found;
                                    }
                                    push @survivors, $cid if $found;
                                }
                                @tier_recs = @survivors;
                            }
                            else {
                                my $cand_raw = pack( "Q>*", @tier_recs );
                                @tier_recs = $self->bin_crop( { mode => 'and' }, [$cand_raw], \@raw_fld_bufs );
                            }
                        }
                        else {
                            @tier_recs = ();
                        }
                    }
                    else {
                        # Fallback when no .fld index file exists (unindexed table):
                        my %allowed = map { $_ => 1 } @{ $filter_map{$fld} };
                        my @recs = $self->read_list( $tableid, \@tier_recs );
                        my @filtered;
                        for my $rec (@recs) {
                            next unless @$rec > $fld;
                            my @fld_vals = $self->get_fieldlist( $rec->[$fld] );
                            if ( grep { exists $allowed{$_} } @fld_vals ) {
                                push @filtered, $rec->[0];
                            }
                        }
                        @tier_recs = @filtered;
                    }
                    last unless @tier_recs;
                }
            }

            return @tier_recs;
        };

        if ( $jnkmode eq 'ALL' ) {
            @records = $run_search->('ALL');
        }
        else {
            my ( @a_records, @b_records );
            if ( $jnkmode =~ /A/ ) {
                @a_records = $run_search->('A');
            }
            if ( $jnkmode =~ /B/ ) {
                @b_records = $run_search->('B');
            }

            if    ( $jnkmode eq 'A' )  { @records = @a_records }
            elsif ( $jnkmode eq 'B' )  { @records = @b_records }
            elsif ( $jnkmode eq 'AB' ) { @records = ( @a_records, @b_records ) }
            elsif ( $jnkmode eq 'BA' ) { @records = ( @b_records, @a_records ) }
        }

        if ( my $ranges = $self->normalize_range_opts( $tableid, \%opts ) ) {
            @records = $self->filter_ids_by_range( $tableid, \@records, $ranges );
        }

        $count = scalar @records;

        # ------------------------------------------------
        # C & D) Sort at Index Level (.inx)
        # ------------------------------------------------
        if ( $opts{sort} && @records ) {
            my $s_norm = $self->normalize_sort_opt( $opts{sort} );
            my $s_blk  = $s_norm->{blk};
            my $dir    = $s_norm->{dir};

            if ( !$s_blk || $s_blk eq '0' || $s_blk eq 'id' ) {
                my $id_sort_type = ( $self->config('simple') || ( $table_info && $table_info->{use_simple} ) ) ? 'ascii' : 'num';
                @records = $self->array_sort( $id_sort_type, $dir, undef, @records );
            }
            else {
                my $key        = "$s_blk:keys";
                my $index_path = ( -e "${idx_path}.inx" ) ? "${idx_path}.inx" : "${table_path}.inx";
                if ( -e $index_path ) {
                    my ( undef, @sorted_master_keys ) = $self->index_get( $index_path, $key, "ids", 0, 0, $dir );
                    if (@sorted_master_keys) {
                        my %matched = map { $_ => 1 } @records;
                        my @ordered = grep { delete $matched{$_} } @sorted_master_keys;
                        push @ordered, keys %matched if %matched;
                        @records = @ordered;
                    }
                    else {
                        @records = $self->sort_by_block( $tableid, \@records, $opts{sort} );
                    }
                }
                else {
                    @records = $self->sort_by_block( $tableid, \@records, $opts{sort} );
                }
            }
        }
        else {
            @records = $self->db_sortid( $tableid, @records );
        }

        # ------------------------------------------------
        # E) Slice limit & record fetching
        # ------------------------------------------------
        if ($limit) {
            ( $count, @records ) = $self->recs_cutting( $offset, $limit, @records );
        }

        if ( $opts{keys_only} || $self->config('keys_only') ) {
            return $limit ? ( $count, @records ) : @records;
        }

        @records = $self->read_list( $tableid, [@records] );

    }

    # simple mod
    else {

        my %tmp = $self->get_words( $string, "read", $tableid );
        my @tmp = keys %tmp;

        if ( -e $file_path && $self->table_read($file_path) ) {
            if (@tmp) {
                # If logic is OR
                if ( lc($and_or) eq "or" ) {
                    $self->recs_scan(
                        $file_path,
                        sub {
                            my ( $key, $value ) = @_;
                            my @dec_fields = $self->db_decode($value);
                            my $search_text = join( " ", grep { defined && !ref($_) } @dec_fields );
                            my %string = $self->get_words( $search_text, "write", $tableid );
                            foreach my $str (@tmp) {
                                if ( $string{$str} ) {
                                    push( @records, [ $key, $self->dec_validate( $tableid, \@dec_fields ) ] );
                                    return;
                                }
                            }
                        }
                    );
                }
                # If logic is AND
                else {
                    $self->recs_scan(
                        $file_path,
                        sub {
                            my ( $key, $value ) = @_;
                            my @dec_fields = $self->db_decode($value);
                            my $search_text = join( " ", grep { defined && !ref($_) } @dec_fields );
                            my %string = $self->get_words( $search_text, "write", $tableid );
                            foreach my $str (@tmp) {
                                unless ( $string{$str} ) {
                                    return;
                                }
                            }
                            push( @records, [ $key, $self->dec_validate( $tableid, \@dec_fields ) ] );
                        }
                    );
                }
            }
            $self->table_close($file_path);
        }

        # Apply field filter(s) if provided
        if ( $filter && %filter_map && @records ) {
            for my $fld ( keys %filter_map ) {
                my %allowed = map { $_ => 1 } @{ $filter_map{$fld} };
                my @filtered;
                for my $rec (@records) {
                    # $rec is [$key, fld1, fld2, ...]
                    next unless @$rec > $fld;
                    my @fld_vals = $self->get_fieldlist( $rec->[$fld] );
                    if ( grep { exists $allowed{$_} } @fld_vals ) {
                        push @filtered, $rec;
                    }
                }
                @records = @filtered;
                last unless @records;
            }
        }

        if ( my $ranges = $self->normalize_range_opts( $tableid, \%opts ) ) {
            @records = $self->filter_ids_by_range( $tableid, \@records, $ranges );
        }

        # Sorting
        if ( $opts{sort} && @records ) {
            my $s_norm = $self->normalize_sort_opt( $opts{sort} );
            my $s_blk  = $s_norm->{blk};
            my $dir    = $s_norm->{dir};
            my $key        = "$s_blk:keys";
            my $index_path = "${table_path}.inx";

            if ( $s_blk && -e $index_path ) {
                my ( undef, @sorted_master_keys ) = $self->index_get( $index_path, $key, "ids", 0, 0, $dir );
                if (@sorted_master_keys) {
                    my %rec_map = map { $_->[0] => $_ } @records;
                    my @ordered = map { $rec_map{$_} } grep { exists $rec_map{$_} } @sorted_master_keys;
                    my %seen = map { $_->[0] => 1 } @ordered;
                    push @ordered, grep { !$seen{ $_->[0] } } @records;
                    @records = @ordered;
                }
                else {
                    @records = $self->sort_by_block_records( $tableid, \@records, $opts{sort} );
                }
            }
            else {
                @records = $self->sort_by_block_records( $tableid, \@records, $opts{sort} );
            }
        }
        else {
            @records = $self->db_sortid( $tableid, @records );
        }
        $count = scalar @records;

        if ($limit) {
            ( $count, @records ) = $self->recs_cutting( $offset, $limit, @records );
        }

        if ( $opts{keys_only} || $self->config('keys_only') ) {
            @records = map { $$_[0] } @records;
            return $limit ? ( $count, @records ) : @records;
        }
    }

    # Inflate integration
    if ( my $inf = $opts{inflate} ) {
        my $res = $self->inflate( $tableid, \@records, $inf );
        return $limit ? ( $count, $res ) : $res;
    }

    return $limit ? ( $count, @records ) : @records;
}

# my $ok = $adb->search_string($input_string, $search_string);
# ---------------------------------------------------------------------
sub search_string {

    my ( $self, $input_string, $search_string ) = @_;

    my %input_words =
      ( ref($input_string) eq "HASH" )
      ? %{$input_string}
      : $self->get_words($input_string);
    my %search_words =
      ( ref($search_string) eq "HASH" )
      ? %{$search_string}
      : $self->get_words($search_string);

    my $statu = 1;
    foreach my $word ( keys %search_words ) {
        if ( !$input_words{$word} ) {
            $statu = 0;
            last;
        }
    }

    return $statu;
}

# Calculates record count.
# my $count = $adb->table_count($tableid);
# ------------------------------------------------
sub table_count {

    my ( $self, $tableid ) = @_;

    $tableid or return;

    my $table_info = $self->table_info($tableid);
    my $table_path = $self->table_path($tableid);

    if ( ( $table_info->{use_ramdisk} // 0 ) == 3 ) {
        my $file_path = "$table_path.$self->{db_ext}";
        unless ( $self->_check_ramdisk_ttl( $tableid, $file_path ) ) {
            $self->set_cache( $tableid, 'count', undef );
            $self->set_cache( $tableid, 'keys',  undef );
            return 0;
        }
    }

    # 1. In-memory cache check ($self->{_cache})
    my $cached_count = $self->get_cache( $tableid, 'count' );
    return $cached_count if defined $cached_count;

    my $count = 0;
    my $is_simple = $self->config('simple') || ( $table_info && $table_info->{use_simple} ) || ( $table_info && $table_info->{id_type} && $table_info->{id_type} eq 'ascii' );

    # Read from index file if record_index exists and table is not in simple mode, otherwise count all records
    if ( !$is_simple && $table_info->{record_index} ) {
        if ( -e "$table_path.inx" ) {
            my ($cnt) = $self->index_get( "$table_path.inx", "count", "raw" );
            if ( defined $cnt && $cnt =~ /^\d+$/ ) {
                $self->set_cache( $tableid, 'count', $cnt );
                return $cnt;
            }
            my ($raw) = $self->index_get( "$table_path.inx", "keys", "raw" );
            if ( length($raw) >= 8 ) {
                $count = int( bytes::length($raw) / 8 );
                $self->set_cache( $tableid, 'count', $count );
                return $count;
            }
        }

        my @record = $self->table_keys($tableid);
        $count = scalar @record;
        my ($last) = sort { $b <=> $a } grep { /^\d+$/ } @record;
        $last //= 0;
        if ( $self->table_write("$table_path.inx") ) {
            $self->index_put( "$table_path.inx", "keys",   \@record, "ids" );
            $self->index_put( "$table_path.inx", "lastid", $last,    "raw" );
            $self->table_close("$table_path.inx");
        }
    }

    # If record_index is absent, read keys from main table and count
    else {
        my $file_path = "$table_path.$self->{db_ext}";
        if ( -e $file_path ) {
            $self->table_read($file_path) or return 0;
            my @keys = $self->recs_keys($file_path);
            $count = scalar @keys;
            $self->table_close($file_path);
        }
        else {
            $count = 0;
        }
    }

    $self->set_cache( $tableid, 'count', $count );
    return $count;
}

# Finds last record ID. Check cache first, then .inx, then full scan.
# my $last_id = $adb->table_lastid($tableid);
# ------------------------------------------------
sub table_lastid {

    my ( $self, $tableid, $last_id ) = @_;

    $tableid or return;
    $last_id ||= 0;

    my $table_info  = $self->table_info($tableid);
    my $use_ramdisk = $table_info ? ( $table_info->{use_ramdisk} // $table_info->{use_cache} // 0 ) : 0;
    my $table_path  = $self->table_path($tableid);
    my $file_path   = "$table_path.$self->{db_ext}";

    if ( $use_ramdisk == 3 ) {
        unless ( $self->_check_ramdisk_ttl( $tableid, $file_path ) ) {
            $self->set_cache( $tableid, 'lastid',      undef );
            $self->set_cache( $tableid, 'last_autoid', undef );
            return $last_id;
        }
    }

    # 1. In-memory cache check ($self->{_cache})
    my $cached_last = $self->get_cache( $tableid, 'lastid' );
    return $cached_last if defined $cached_last;

    if ($use_ramdisk) {
        $self->ramdisk_ensure($tableid);
    }
    my $idx_path   = $use_ramdisk ? $self->ramdisk_path($tableid) : $table_path;
    $file_path     = ( $use_ramdisk == 2 && -e "$idx_path.$self->{db_ext}" ) ? "$idx_path.$self->{db_ext}" : "$table_path.$self->{db_ext}";
    my $index_path = ( -e "$idx_path.inx" ) ? "$idx_path.inx" : "$table_path.inx";

    if ( -e $index_path ) {
        if ( $self->table_read($index_path) ) {
            my ($lastid_inx) = $self->index_get( $index_path, "lastid", "raw" );
            $self->table_close($index_path);
            if ( defined $lastid_inx && $lastid_inx =~ /^[0-9]+$/ ) {
                $self->set_cache( $tableid, 'lastid', $lastid_inx );
                return $lastid_inx;
            }
        }
    }

    return $last_id unless -e $file_path;

    my @all_keys = $self->table_keys($tableid);
    my @nums = sort { $b <=> $a } grep /^[0-9]+$/, @all_keys;
    $last_id  = $nums[0] // 0;
    if (    defined $last_id
        and $last_id =~ /^[0-9]+$/
        and $table_info->{record_index} )
    {
        if ( $self->table_write("$table_path.inx") ) {
            $self->index_put( "$table_path.inx", "lastid", $last_id, "raw" );
            $self->table_close("$table_path.inx");
        }
        if ( $use_ramdisk && $self->table_write("$idx_path.inx") ) {
            $self->index_put( "$idx_path.inx", "lastid", $last_id, "raw" );
            $self->table_close("$idx_path.inx");
        }
    }

    $self->set_cache( $tableid, 'lastid', $last_id );
    return $last_id;
}

# my @record_ids = $adb->table_keys($tableid);
# ------------------------------------------------
sub table_keys {

    my ( $self, $tableid, @args ) = @_;

    $tableid or return;

    my $dir = 'desc';
    if ( @args && defined $args[0] && !ref($args[0]) && $args[0] =~ /^(asc|desc)$/i ) {
        $dir = lc($args[0]);
    }
    elsif ( @args && ref($args[0]) eq 'HASH' ) {
        $dir = lc( $args[0]->{dir} // $args[0]->{order} // 'desc' );
    }
    $dir = ( $dir eq 'asc' || $dir eq '1' ) ? 'asc' : 'desc';

    my $table_info  = $self->table_info($tableid);
    my $use_ramdisk = $table_info ? ( $table_info->{use_ramdisk} // $table_info->{use_cache} // 0 ) : 0;
    my $table_path  = $self->table_path($tableid);
    my $file_path   = "$table_path.$self->{db_ext}";

    if ( $use_ramdisk == 3 ) {
        unless ( $self->_check_ramdisk_ttl( $tableid, $file_path ) ) {
            $self->set_cache( $tableid, 'keys',  undef );
            $self->set_cache( $tableid, 'count', undef );
            return ();
        }
    }

    # 1. In-memory RAM cache check
    my $cache_key   = "keys_$dir";
    my $cached_keys = $self->get_cache( $tableid, $cache_key ) // ( $dir eq 'desc' ? $self->get_cache( $tableid, 'keys' ) : undef );
    if ( defined $cached_keys && ref($cached_keys) eq 'ARRAY' ) {
        return @$cached_keys;
    }
    my $alt_key  = ( $dir eq 'asc' ) ? 'keys_desc' : 'keys_asc';
    my $alt_keys = $self->get_cache( $tableid, $alt_key ) // ( $dir eq 'asc' ? $self->get_cache( $tableid, 'keys' ) : undef );
    if ( defined $alt_keys && ref($alt_keys) eq 'ARRAY' ) {
        my @rev = reverse @$alt_keys;
        $self->set_cache( $tableid, $cache_key, \@rev );
        return @rev;
    }

    if ($use_ramdisk) {
        $self->ramdisk_ensure($tableid);
    }
    my $idx_path   = $use_ramdisk ? $self->ramdisk_path($tableid) : $table_path;
    my $index_path = ( -e "$idx_path.inx" ) ? "$idx_path.inx" : "$table_path.inx";

    my (@keys);

    # Index check (.inx)
    if ( -e $index_path ) {
        my ( $total, @keys_list ) = $self->index_get( $index_path, "keys", "ids", 0, 0, $dir );
        if (@keys_list) {
            $self->set_cache( $tableid, $cache_key, \@keys_list );
            $self->set_cache( $tableid, 'keys', \@keys_list ) if $dir eq 'desc';
            return @keys_list;
        }
    }

    # Otherwise scan main table (.db from RAM-disk if use_ramdisk == 2)
    my $scan_path = ( $use_ramdisk == 2 && -e "$idx_path.$self->{db_ext}" ) ? "$idx_path.$self->{db_ext}" : $file_path;
    return unless -e $scan_path;
    $self->table_read($scan_path) or do { cluck "[DB_TIE] $scan_path can't open.\n"; return; };
    @keys = $self->recs_keys($scan_path);
    $self->table_close($scan_path);

    my $id_sort_type = ( $self->config('simple') || ( $table_info && $table_info->{use_simple} ) ) ? 'ascii' : 'num';
    @keys = $self->array_sort( $id_sort_type, $dir, undef, @keys );
    $self->set_cache( $tableid, $cache_key, \@keys );
    $self->set_cache( $tableid, 'keys', \@keys ) if $dir eq 'desc';

    return @keys;
}

# Sanitizes and validates a record ID according to table mode.
# If simple mode (global simple or table use_simple): allows safe arbitrary keys (max 255 bytes, no control chars).
# If standard mode: strictly enforces positive integer numeric ID.
# my $clean_id = $adb->id_check($tableid, $rid);
# ------------------------------------------------
sub id_check {
    my ( $self, $tableid, $rid ) = @_;

    return unless defined $rid && $rid ne '';
    return if ref $rid;

    my $table_info = $tableid ? $self->table_info($tableid) : {};
    my $is_simple  = $self->config('simple') || ( $table_info && $table_info->{use_simple} );

    # 1. Simple Mode: Safe Key Sanitization (no binary control chars, max 255 bytes)
    if ($is_simple) {
        return if $rid =~ /[\x00-\x1f\x7f]/;
        $rid = $self->trim_space($rid);
        return unless defined $rid && length($rid) > 0;
        return if length($rid) > 255;
        return $rid;
    }

    # 2. Standard Mode: Strict positive integer numeric ID
    $rid =~ s/\D//g;
    return ( length($rid) > 0 && $rid > 0 ) ? $rid : undef;
}

# Sets or gets table auto id.
# my $id = $adb->table_autoid($tableid, [$id]);
# ------------------------------------------------
sub table_autoid {

    my ( $self, $tableid, $aid ) = @_;

    $tableid or return;
    my $table_info = $self->table_info($tableid);
    my $is_simple  = $self->config('simple') || ( $table_info && $table_info->{use_simple} );

    if ( defined $aid && $aid ne '' && $aid ne '0' ) {
        $aid = $self->id_check( $tableid, $aid );
        return unless defined $aid && $aid ne '';

        # Numeric ID must be greater than current lastid unless simple mode
        if ( !$is_simple && $aid =~ /^\d+$/ ) {
            my $cached_auto = $self->get_cache( $tableid, 'last_autoid' );
            my $last = $cached_auto // ( $self->table_lastid($tableid) || 0 );

            if ( $aid <= $last ) {
                my $table_path = $self->table_path($tableid);
                my $file_path  = "$table_path.$self->{db_ext}";
                $self->transact_error( $file_path, "ID must be greater than last ID ($last): $aid" );
                return;
            }

            $self->set_cache( $tableid, 'last_autoid', $aid );
        }
    }
    else {
        my $last = $self->table_lastid($tableid) || 0;
        my $cached_auto = $self->get_cache( $tableid, 'last_autoid' );
        $last = $cached_auto if ( $cached_auto && $cached_auto > $last );
        $aid = ++$last;
        $self->set_cache( $tableid, 'last_autoid', $aid );
    }

    return $aid;
}

# Creates empty DB file.
# my $ok = $adb->table_create($tableid);
# ------------------------------------------------
sub table_create {

    my ( $self, $tableid, $schema ) = @_;

    $tableid or return;

    $self->table_attr( $tableid, $schema ) if defined $schema && ref($schema) eq 'HASH';

    my $table_path = $self->table_path($tableid);
    my $file_path  = "$table_path.$self->{db_ext}";

    $self->table_write($file_path)
      or (
        warn( "[DB_TIE] $file_path DB table could not be created.\n" )
        and return
      );
    $self->table_close($file_path);

    return 1;
}

# Opens DB_File read-only, returns tie handle.
# my $fh = $adb->table_read($table_path);
# ------------------------------------------------
sub table_read {
    my ( $self, $file_path ) = @_;

    return $self->{_db}->{$file_path} if $self->{_db}->{$file_path};
    return unless -e $file_path;

    my $db_obj;
    my %db;
    for my $attempt ( 1 .. 30 ) {
        $db_obj = tie( %db, "DB_File", $file_path, O_RDONLY, 0644, $hash_info );
        last if $db_obj;
        require Time::HiRes;
        Time::HiRes::usleep(10000);
    }
    unless ($db_obj) {
        return;
    }

    $self->{_db}->{$file_path}  = $db_obj;
    $self->{_tie}->{$file_path} = \%db;
    return $self->{_db}->{$file_path};
}

# Opens DB_File read/write, applies exclusive flock.
# $adb->table_write($file_path);
# ------------------------------------------------
sub table_write {
    my ( $self, $file_path ) = @_;

    if ( $self->{_db}->{$file_path} ) {
        return $self->{_db}->{$file_path} if $self->{_dbm}->{$file_path};
        $self->table_close($file_path);
    }

    # Ensure parent directory exists
    if ( my ($dir) = $file_path =~ m{^(.*)[/\\]} ) {
        $self->make_path($dir);
    }

    # Open table with retry
    my $db_obj;
    my %db;
    for my $attempt ( 1 .. 30 ) {
        $db_obj = tie( %db, "DB_File", $file_path, O_RDWR | O_CREAT, 0644, $hash_info );
        last if $db_obj;
        require Time::HiRes;
        Time::HiRes::usleep(10000);
    }
    unless ($db_obj) {
        $self->transact_error( $file_path, "DB table cannot be opened: $!" );
        return;
    }

    $self->{_db}->{$file_path} = $db_obj;

    # Lock table
    $self->{_fd}->{$file_path} = $db_obj->fd;

    # SECURITY CHECK: If fd invalid, do not execute open()!
    if ( !defined $self->{_fd}->{$file_path}
        || $self->{_fd}->{$file_path} eq '' )
    {
        $self->table_close($file_path);
        $self->transact_error( $file_path, "Could not obtain valid file descriptor for $file_path" );
        return;
    }

    open( $self->{_dbm}->{$file_path}, "+<&=", $self->{_fd}->{$file_path} )
      or do {
        $self->table_close($file_path);
        $self->transact_error( $file_path, "Cannot dup filehandle for $file_path: $!" );
        return;
      };
    flock( $self->{_dbm}->{$file_path}, LOCK_EX );

    $self->{_tie}->{$file_path} = \%db;
    return $self->{_db}->{$file_path};
}

# Unlocks, closes file, cleans up internal handle pool.
# $adb->table_close($file_path);
# ------------------------------------------------
sub table_close {

    my ( $self, $file_path ) = @_;

    return 1 unless $file_path;

    if ( $self->{_db}->{$file_path} ) {
        eval { $self->{_db}->{$file_path}->sync() };
    }
    if ( $self->{_dbm}->{$file_path} ) {
        flock( $self->{_dbm}->{$file_path}, LOCK_UN );
        close( $self->{_dbm}->{$file_path} );
        delete( $self->{_dbm}->{$file_path} );
    }

    my $tie_ref = delete $self->{_tie}->{$file_path};
    delete $self->{_db}->{$file_path};
    delete $self->{_fd}->{$file_path};

    if ( $tie_ref && ref($tie_ref) eq 'HASH' ) {
        no warnings 'untie';
        eval { untie %$tie_ref };
    }

    return 1;
}

# Closes all open DB files. Called automatically by DESTROY.
# $adb->close_all();
# ------------------------------------------------
sub close_all {

    my ($self) = @_;

    if ( ref( $self->{_tie} ) eq "HASH" ) {
        foreach my $file_path ( keys %{ $self->{_tie} } ) {
            $self->table_close($file_path);
        }
    }

    if ( ref( $self->{_lock} ) eq "HASH" ) {
        foreach my $lock_name ( keys %{ $self->{_lock} } ) {
            if ( my $fh = delete $self->{_lock}->{$lock_name} ) {
                flock( $fh, LOCK_UN );
                close $fh;
            }
        }
    }

    return 1;
}

# Locks a single record or entire table file.
# $adb->flock_open($table_id, [$mode], [$record_id]);
# $mode: "write" (LOCK_EX, default) or "read" (LOCK_SH)
# If $record_id provided -> locks dbstore/lock/${table_id}_${record_id}.lock (record-level)
# If $record_id omitted  -> locks dbstore/lock/${table_id}.lock (table-level)
# ------------------------------------------------
sub flock_open {
    my ( $self, $tableid, $mode, $record_id ) = @_;

    $tableid or return;
    $mode ||= "write";

    my $lock_dir = $self->{_path}->{lock_dir} ||= ( ( $self->path('dbase_dir') || "." ) . "/lock" );
    unless ( -d $lock_dir ) {
        $self->make_path($lock_dir);
    }

    my $safe_tid = $self->sanitize_table($tableid);
    $safe_tid =~ s{/}{-}g;
    my $safe_rid = defined($record_id) ? "$record_id" : "";
    $safe_rid =~ s{[^\w.\-]+}{}g;

    my $lock_name = ( $safe_rid ne "" )
      ? "${safe_tid}_${safe_rid}"
      : "${safe_tid}";

    if ( my $existing = $self->{_lock}->{$lock_name} ) {
        return $existing;
    }

    my $lock_file = "$lock_dir/${lock_name}.lock";

    open my $fh, ">>", $lock_file or do {
        cluck "[DB_LOCK] Cannot open lock file: $lock_file ($!)\n";
        return;
    };

    my $flags = ( $mode eq "read" ) ? LOCK_SH : LOCK_EX;
    flock( $fh, $flags );

    $self->{_lock}->{$lock_name} = $fh;

    return $fh;
}

# Unlocks and closes lock file for record or table.
# $adb->flock_close($table_id, [$record_id]);
# ------------------------------------------------
sub flock_close {
    my ( $self, $tableid, $record_id ) = @_;

    $tableid or return;

    my $safe_tid = $self->sanitize_table($tableid);
    $safe_tid =~ s{/}{-}g;
    my $safe_rid = defined($record_id) ? "$record_id" : "";
    $safe_rid =~ s{[^\w.\-]+}{}g;

    my $lock_name = ( $safe_rid ne "" )
      ? "${safe_tid}_${safe_rid}"
      : "${safe_tid}";

    if ( my $fh = delete $self->{_lock}->{$lock_name} ) {
        flock( $fh, LOCK_UN );
        close $fh;
    }

    return 1;
}

# Reads directly from DB_File for a single key; returns decoded (rid, @fields).
# Legacy helper - recs_get preferred for bulk reads.
# my @fields = $adb->table_readid("file_path", $id);
# ------------------------------------------------
sub table_readid {

    my ( $self, $file_path, $rid ) = @_;

    # Input validation
    ( $file_path and $rid ) or return;
    return unless -e $file_path;

    # Strip spaces and apply key encoding
    my $rid_escape = $self->key_encode($rid);

    my @lookup = ($rid);
    push @lookup, $rid_escape if defined $rid_escape && $rid_escape ne $rid;

    my $was_open = $self->{_db}->{$file_path} ? 1 : 0;
    $self->table_read($file_path) or return;
    my $res = $self->recs_get( $file_path, @lookup );
    $self->table_close($file_path) unless $was_open;
    my $fields = $res ? ( $res->{$rid} // ( defined $rid_escape ? $res->{$rid_escape} : undef ) ) : undef;

    return $fields ? ( $rid, $self->db_decode($fields) ) : ();
}

# Checks presence of one or more keys in open DB_File table.
# Usage:
#   my $exists = $adb->recs_exist($file_path, $rid);        # Returns 1 or 0 (single key)
#   my $map    = $adb->recs_exist($file_path, @keys);       # Returns { key1 => 1, key2 => 0, ... }
# ------------------------------------------------
sub recs_exist {
    my ( $self, $file_path, @records ) = @_;

    return unless $file_path;
    return unless scalar @records;

    # if not opened, open the table
    if ( !$self->{_db}->{$file_path} ) {
        $self->table_read($file_path)
          or do { cluck "[DB_TIE] $file_path can't open for get.\n"; return; };
    }

    my $db = $self->{_db}->{$file_path};
    my %result = ();

    foreach my $rid (@records) {
        my $k = $self->utf_encode("$rid");
        my $val;
        my $ret = $db->get( $k, $val );
        $result{$rid} = ( $ret == 0 && defined $val ) ? 1 : 0;
    }

    if ( scalar @records == 1 ) {
        return $result{ $records[0] };
    }

    return \%result;
}

# Reads all keys from DB_File handle in sequential order using C-level seq.
# Usage:
#   my @keys = $adb->recs_keys($file_path);
# ------------------------------------------------
sub recs_keys {
    my ( $self, $file_path ) = @_;
    return $self->recs_scan( $file_path, 'keys' );
}

# Scans key-value pairs sequentially using DB_File seq.
# Usage:
#   $adb->recs_scan($file_path, sub { my ($key, $val) = @_; ... }); # Custom callback
#   my $hash   = $adb->recs_scan($file_path);           # Default / 'hash': { key => raw_val }
#   my $keys   = $adb->recs_scan($file_path, 'keys');   # 'keys': [$k1, $k2, ...] or ($k1, $k2, ...)
#   my $values = $adb->recs_scan($file_path, 'values'); # 'values' / 'value': [$v1, $v2, ...] or ($v1, $v2, ...)
#   my $pairs  = $adb->recs_scan($file_path, 'each');   # 'each' / 'pairs': [ [$k1, $v1], ... ]
#   my $count  = $adb->recs_scan($file_path, 'count');  # 'count': total record count (scalar)
# ------------------------------------------------
sub recs_scan {
    my ( $self, $file_path, $mode ) = @_;

    return unless $file_path;

    # if not opened, open the table
    if ( !$self->{_db}->{$file_path} ) {
        $self->table_read($file_path)
          or do { cluck "[DB_TIE] $file_path can't open for get.\n"; return; };
    }

    my $db = $self->{_db}->{$file_path};

    # 1. Custom Callback Mode
    if ( ref($mode) eq 'CODE' ) {
        my ( $k, $v );
        for ( my $status = $db->seq( $k, $v, R_FIRST ); $status == 0; $status = $db->seq( $k, $v, R_NEXT ) ) {
            my $res = $mode->( $self->utf_decode($k), $v );
            last if defined $res && $res eq 'last';
        }
        return 1;
    }

    $mode = lc( $mode // 'hash' );

    # 2. Keys Mode
    if ( $mode eq 'keys' ) {
        my @keys;
        my ( $k, $v );
        for ( my $status = $db->seq( $k, $v, R_FIRST ); $status == 0; $status = $db->seq( $k, $v, R_NEXT ) ) {
            push @keys, $self->utf_decode($k);
        }
        return wantarray ? @keys : \@keys;
    }

    # 3. Values Mode
    if ( $mode eq 'values' || $mode eq 'value' ) {
        my @values;
        my ( $k, $v );
        for ( my $status = $db->seq( $k, $v, R_FIRST ); $status == 0; $status = $db->seq( $k, $v, R_NEXT ) ) {
            push @values, $v;
        }
        return wantarray ? @values : \@values;
    }

    # 4. Each / Pairs Mode: [ [$k, $v], ... ]
    if ( $mode eq 'each' || $mode eq 'pairs' ) {
        my @pairs;
        my ( $k, $v );
        for ( my $status = $db->seq( $k, $v, R_FIRST ); $status == 0; $status = $db->seq( $k, $v, R_NEXT ) ) {
            push @pairs, [ $self->utf_decode($k), $v ];
        }
        return wantarray ? @pairs : \@pairs;
    }

    # 5. Count Mode
    if ( $mode eq 'count' ) {
        my $cnt = 0;
        my ( $k, $v );
        for ( my $status = $db->seq( $k, $v, R_FIRST ); $status == 0; $status = $db->seq( $k, $v, R_NEXT ) ) {
            $cnt++;
        }
        return $cnt;
    }

    # 6. Default / Hash Mode: { key => raw_val }
    my %result;
    my ( $k, $v );
    for ( my $status = $db->seq( $k, $v, R_FIRST ); $status == 0; $status = $db->seq( $k, $v, R_NEXT ) ) {
        $result{ $self->utf_decode($k) } = $v;
    }
    return wantarray ? %result : \%result;
}

# Reads multiple keys in single pass over open DB_File handle. Returns { key => raw_val }.
# my $recs_val = $adb->recs_get($file_path, @rec_ids);
# ------------------------------------------------
sub recs_get {

    my ( $self, $file_path, @records ) = @_;

    return unless $file_path;
    return unless scalar @records;

    # if not opened, open the table
    if ( !$self->{_db}->{$file_path} ) {
        $self->table_read($file_path)
          or do { cluck "[DB_TIE] $file_path can't open for get.\n"; return; };
    }

    my $db = $self->{_db}->{$file_path};
    my %result = ();

    foreach my $rid (@records) {
        my $k = $self->utf_encode("$rid");
        my $val;
        my $ret = $db->get( $k, $val );
        if ( $ret == 0 && defined $val ) {
            $result{$rid} = $val;
        }
    }

    return \%result;
}

# Writes records in bulk to open DB_File handle. Each item must be in [$rid, @fields] format.
# my $ok = $adb->recs_put($file_path, @records);
# my $ok = $adb->recs_put([$file_path, $tableid], @records);
# ------------------------------------------------
sub recs_put {

    my ( $self, $target, @records ) = @_;

    my ( $file_path, $tableid, $no_mirror );
    if ( ref($target) eq 'ARRAY' ) {
        ( $file_path, $tableid, $no_mirror ) = @$target;
    }
    else {
        $file_path = $target;
        ($tableid) = $file_path =~ m{([^/\\:]+)\.[^.]+$} if defined $file_path;
    }

    return unless $file_path && @records;

    # if not opened for write, open the table in write mode
    if ( !$self->{_db}->{$file_path} || !$self->{_dbm}->{$file_path} ) {
        $self->table_write($file_path)
          or do { cluck "[DB_TIE] $file_path can't open.\n"; return; };
    }

    my $db = $self->{_db}->{$file_path};
    my $is_txn = $self->is_transact($tableid);

    foreach my $record (@records) {
        my ( $rid, @fields ) = @{$record};    # Separate ID
        next unless defined $rid && $rid ne '';

        my $k   = $self->utf_encode("$rid");
        my $val = @fields == 1 ? $fields[0] : $self->db_encode(@fields);
        next unless defined $val && $val ne '';

        if ( $is_txn && !$self->{_txn}->{logged}->{"$file_path\x1e$rid"}++ ) {
            my $old_raw;
            my $ret = $db->get( $k, $old_raw );
            my $action  = ( $ret == 0 && defined $old_raw ) ? 'edit' : 'add';
            my $old_val = ( $ret == 0 && defined $old_raw ) ? $old_raw : '__NULL__';
            $self->_txn_log( 'recs', $tableid, $file_path, $rid, $action, $old_val );
        }

        my $v   = $self->utf_encode("$val");
        my $ret = $db->put( $k, $v );
        warn "[DB_TIE] $file_path can't put $rid record.\n" if $ret < 0;
    }

    # RAM-disk Tier 2 (mirror) or (Tier 4 in active transaction) dual-write
    if ( !$no_mirror && $tableid && $self->ramdisk_is_mounted() ) {
        my $table_info  = eval { $self->table_info($tableid) };
        my $use_ramdisk = $table_info ? $self->_normalize_ramdisk_tier( $table_info->{use_ramdisk} // $table_info->{use_cache} // 0 ) : 0;
        if ( $use_ramdisk == 2 || ( $use_ramdisk == 4 && $is_txn ) ) {
            my $ram_dir   = $self->ramdisk_dir();
            my $is_in_ram = ( $ram_dir && index( $file_path, $ram_dir ) == 0 ) ? 1 : 0;
            my ($ext)     = $file_path =~ m{\.([^.]+)$};
            my $mirror_file;
            if ( $ext && $ext =~ /^(?:\Q$self->{db_ext}\E|inx|src|fld|fac|unq|slg)$/ ) {
                if ($is_in_ram) {
                    my $tbl_path = $self->table_path($tableid);
                    $mirror_file = "$tbl_path.$ext" if $tbl_path;
                }
                else {
                    my $r_path = $self->ramdisk_path($tableid);
                    $mirror_file = "$r_path.$ext" if $r_path;
                }
                if ( $mirror_file && $mirror_file ne $file_path ) {
                    $self->recs_put( [ $mirror_file, $tableid, 1 ], @records );
                }
            }
        }
    }

    return 1;
}

# Deletes provided IDs from open DB_File handle.
# my $ok = $adb->recs_del($file_path, @recs); # ID's
# my $ok = $adb->recs_del([$file_path, $tableid], @recs);
# ------------------------------------------------
sub recs_del {

    my ( $self, $target, @recs ) = @_;

    my ( $file_path, $tableid, $no_mirror );
    if ( ref($target) eq 'ARRAY' ) {
        ( $file_path, $tableid, $no_mirror ) = @$target;
    }
    else {
        $file_path = $target;
        ($tableid) = $file_path =~ m{([^/\\:]+)\.[^.]+$} if defined $file_path;
    }

    return unless $file_path && @recs;

    # if not opened for write, open the table in write mode
    if ( !$self->{_db}->{$file_path} || !$self->{_dbm}->{$file_path} ) {
        $self->table_write($file_path)
          or do { cluck "[DB_TIE] $file_path can't open.\n"; return; };
    }

    my $db = $self->{_db}->{$file_path};
    my $is_txn = $self->is_transact($tableid);

    foreach my $rid (@recs) {
        next unless defined $rid && $rid ne '';
        my $k = $self->utf_encode("$rid");

        if ( $is_txn && !$self->{_txn}->{logged}->{"$file_path\x1e$rid"}++ ) {
            my $old_raw;
            my $ret = $db->get( $k, $old_raw );
            if ( $ret == 0 && defined $old_raw ) {
                $self->_txn_log( 'recs', $tableid, $file_path, $rid, 'del', $old_raw );
            }
        }

        my $ret = $db->del($k);
        warn "[DB_TIE] $file_path can't delete $rid.\n" if $ret < 0;
    }

    # RAM-disk Tier 2 (mirror) or (Tier 4 in active transaction) dual-write
    if ( !$no_mirror && $tableid && $self->ramdisk_is_mounted() ) {
        my $table_info  = eval { $self->table_info($tableid) };
        my $use_ramdisk = $table_info ? $self->_normalize_ramdisk_tier( $table_info->{use_ramdisk} // $table_info->{use_cache} // 0 ) : 0;
        if ( $use_ramdisk == 2 || ( $use_ramdisk == 4 && $is_txn ) ) {
            my $ram_dir   = $self->ramdisk_dir();
            my $is_in_ram = ( $ram_dir && index( $file_path, $ram_dir ) == 0 ) ? 1 : 0;
            my ($ext)     = $file_path =~ m{\.([^.]+)$};
            my $mirror_file;
            if ( $ext && $ext =~ /^(?:\Q$self->{db_ext}\E|inx|src|fld|fac|unq|slg)$/ ) {
                if ($is_in_ram) {
                    my $tbl_path = $self->table_path($tableid);
                    $mirror_file = "$tbl_path.$ext" if $tbl_path;
                }
                else {
                    my $r_path = $self->ramdisk_path($tableid);
                    $mirror_file = "$r_path.$ext" if $r_path;
                }
                if ( $mirror_file && $mirror_file ne $file_path ) {
                    $self->recs_del( [ $mirror_file, $tableid, 1 ], @recs );
                }
            }
        }
    }

    return 1;
}

# Reads an index entry directly from tied hash handle (_tie).
# Uniform return format: ($total_count, @ids)
# Returns (0, ()) if file/key is missing or empty.
# Reads an index entry using direct DB_File C object methods ($db->get).
# Usage:
#   my ($total, @ids) = $adb->index_get($table_path, $key);
#   my ($total, @ids) = $adb->index_get($table_path, $key, 'ids', $offset, $limit, $dir);
#   my ($count)        = $adb->index_get($table_path, "count", "raw");
#   my ($val)          = $adb->index_get($table_path, $rid, "raw");
# Mode / Type:
#   'ids'  (default)  -> Decodes packed binary ID sequence via bin_decode.
#   'raw' / 'scalar'  -> Returns raw scalar string ($raw).
# ------------------------------------------------
# Reads single or multiple keys from one or multiple index files.
# Plural Usage:
#   my $res_hash  = $adb->index_get($table_path, \@keys);             # { key => \@ids }
#   my $raw_hash  = $adb->index_get($table_path, \@keys, 'raw');      # { key => $raw }
#   my @all_ids   = $adb->index_get(\@table_paths, $key);             # merges across files
# Singular Usage (Backward-Compatible):
#   my ($cnt, @ids) = $adb->index_get($table_path, $key);
#   my ($raw)       = $adb->index_get($table_path, $key, 'raw');
# ------------------------------------------------
sub index_get {
    my ( $self, $table_path, $key, @args ) = @_;

    return "" unless defined $table_path && defined $key;

    # -------------------------------------------------------------------------
    # PLURAL PATHS: Search across multiple index files (e.g. across search blocks)
    # -------------------------------------------------------------------------
    if ( ref($table_path) eq 'ARRAY' ) {
        my @all_results;
        my %merged_hash;
        for my $tp ( @$table_path ) {
            next unless $tp && -e $tp;
            my @res = $self->index_get( $tp, $key, @args );
            if ( ref($key) eq 'ARRAY' ) {
                if ( ref($res[0]) eq 'HASH' ) {
                    for my $k ( keys %{ $res[0] } ) {
                        push @{ $merged_hash{$k} }, @{ $res[0]{$k} };
                    }
                }
            }
            else {
                if ( @args && defined $args[0] && $args[0] =~ /^(raw|scalar|text)$/i ) {
                    push @all_results, $res[0] if defined $res[0];
                }
                else {
                    shift @res if @res && $res[0] =~ /^\d+$/ && scalar(@res) > 1;
                    push @all_results, @res;
                }
            }
        }
        return \%merged_hash if ref($key) eq 'ARRAY';
        return @all_results;
    }

    # -------------------------------------------------------------------------
    # PLURAL KEYS: Read multiple keys from a single index file
    # Returns hashref { key => \@ids } or { key => $raw_str }
    # -------------------------------------------------------------------------
    if ( ref($key) eq 'ARRAY' ) {
        my %result;
        return \%result unless @$key;
        return \%result unless -e $table_path;

        my $db = $self->table_read($table_path);
        return \%result unless $db;

        my ( $type, $offset, $limit, $dir );
        if ( @args && defined $args[0] && $args[0] =~ /^(raw|scalar|text|ids|bin|list)$/i ) {
            $type = lc( shift @args );
        }
        if (@args) { $offset = shift @args; }
        if (@args) { $limit  = shift @args; }
        if (@args) { $dir    = shift @args; }

        my $is_unq = ( $table_path =~ /\.unq$/ ) ? 1 : 0;

        for my $k_orig ( @$key ) {
            next unless defined $k_orig && $k_orig ne '';
            my $k_enc = $self->utf_encode("$k_orig");
            my $raw;
            my $status = $db->get( $k_enc, $raw );
            next unless $status == 0 && defined $raw && $raw ne '';

            if ( $type && ( $type eq 'raw' || $type eq 'scalar' || $type eq 'text' ) ) {
                $result{$k_orig} = $raw;
                next;
            }

            my $len = bytes::length($raw);
            if ( $len >= 8 && $len % 8 == 0 ) {
                my ( $cnt, @ids ) = $self->bin_decode( $raw, $offset // 0, $limit // 0, $dir // 'desc' );
                $result{$k_orig} = \@ids;
            }
            else {
                my @ids = $raw =~ /[\x1e,;\s]/ ? split( /[\x1e,;\s]+/, $raw ) : ($raw);
                @ids = grep { defined && $_ ne '' } @ids;
                $result{$k_orig} = \@ids;
            }
        }
        return \%result;
    }

    # -------------------------------------------------------------------------
    # SINGULAR PATH: Original single-key, single-file implementation
    # -------------------------------------------------------------------------
    my ( $type, $offset, $limit, $dir );
    if ( @args && defined $args[0] && $args[0] =~ /^(raw|scalar|text|ids|bin|list)$/i ) {
        $type = lc( shift @args );
    }
    if (@args) { $offset = shift @args; }
    if (@args) { $limit  = shift @args; }
    if (@args) { $dir    = shift @args; }

    my $is_bin_index = ( $type && $type eq 'ids' ) || ( !$type && $table_path =~ /\.(fld|jfld|src|jsrc|inx|jinx)$/ );

    return ( $is_bin_index ? ( 0, () ) : () ) unless $table_path && -e $table_path;
    return ( $is_bin_index ? ( 0, () ) : () ) unless defined $key && $key ne '';

    my $db = $self->table_read($table_path);
    return ( $is_bin_index ? ( 0, () ) : () ) unless $db;

    my $k = $self->utf_encode("$key");

    my $raw;
    my $status = $db->get( $k, $raw );
    if ( $status != 0 || !defined $raw || $raw eq '' ) {
        # Virtual O(1) count fallback: derive count directly from binary keys length
        my $keys_raw;
        if ( $k eq 'count' && $db->get( 'keys', $keys_raw ) == 0 && defined $keys_raw ) {
            return ( int( bytes::length($keys_raw) / 8 ) );
        }
        elsif ( $k eq 'A:count' && $db->get( 'A:keys', $keys_raw ) == 0 && defined $keys_raw ) {
            return ( int( bytes::length($keys_raw) / 8 ) );
        }
        elsif ( $k eq 'B:count' && $db->get( 'B:keys', $keys_raw ) == 0 && defined $keys_raw ) {
            return ( int( bytes::length($keys_raw) / 8 ) );
        }
        elsif ( $k =~ /^([A-Za-z0-9_:]+):count$/ && $db->get( "$1:keys", $keys_raw ) == 0 && defined $keys_raw ) {
            return ( int( bytes::length($keys_raw) / 8 ) );
        }
        return ( $is_bin_index ? ( 0, () ) : () );
    }

    # If type is explicitly 'raw' / 'scalar' -> return raw string
    if ( $type && ( $type eq 'raw' || $type eq 'scalar' || $type eq 'text' ) ) {
        return ($raw);
    }

    # Auto-detection if type not explicitly specified:
    if ( !$type ) {
        if (   $k eq 'count'
            || $k =~ /:count$/
            || $k eq 'lastid'
            || $table_path =~ /\.slg$/
            || $table_path =~ /\.unq$/
            || ( $table_path =~ /\.fac$/ && $k ne 'active' ) )
        {
            return ($raw);
        }
    }

    # 2. Binary ID sequence index payloads (.inx 'keys' / '$tier:keys' / '$blk:keys', .fld, .src, .fac 'active')
    my $len = bytes::length($raw);
    if ( $k eq 'keys' || $k =~ /:keys$/ || $k eq 'allkeys' || $k eq 'active' || ( $len >= 8 && $len % 8 == 0 ) ) {
        return $self->bin_decode( $raw, $offset // 0, $limit // 0, $dir // 'desc' );
    }

    # 3. Fallback for legacy text index payload (.fld, .src, .inx)
    my @ids = $raw =~ /[\x1e,;\s]/ ? split( /[\x1e,;\s]+/, $raw ) : ($raw);
    @ids = grep { defined && $_ ne '' } @ids;
    return ( scalar @ids, @ids );
}

# Writes single or multiple index entries.
# Plural Usage:
#   $adb->index_put($table_path, \%key_vals);         # puts multiple keys at once
#   $adb->index_put($table_path, \%key_vals, 'ids');  # explicit 'ids' type
#   $adb->index_put([$table_path, $tableid], \%key_vals, $type);
# Singular Usage (Backward-Compatible):
#   $adb->index_put($table_path, $key, \@ids);
#   $adb->index_put($table_path, $key, $val, 'raw');
#   $adb->index_put([$table_path, $tableid], $key, $val, $type);
# ------------------------------------------------
sub index_put {
    my ( $self, $target, $key, $val, $type ) = @_;

    my ( $table_path, $tableid, $no_mirror );
    if ( ref($target) eq 'ARRAY' ) {
        ( $table_path, $tableid, $no_mirror ) = @$target;
    }
    else {
        $table_path = $target;
        ($tableid) = $table_path =~ m{([^/\\:]+)\.[^.]+$} if defined $table_path;
    }

    return unless $table_path && defined $key;

    my $is_unq = ( $table_path =~ /\.unq$/ ) ? 1 : 0;

    # -------------------------------------------------------------------------
    # PLURAL PUT: If $key is a HASH ref { $k1 => $v1, $k2 => $v2, ... }
    # -------------------------------------------------------------------------
    if ( ref($key) eq 'HASH' ) {
        my $kv_map = $key;
        return 0 unless %$kv_map;

        $type = lc( $val // 'ids' );

        if ( !$self->{_db}->{$table_path} || !$self->{_dbm}->{$table_path} ) {
            $self->table_write($table_path)
              or do { cluck "[DB_TIE] $table_path can't open for index_put.\n"; return 0; };
        }

        my $db = $self->{_db}->{$table_path};
        return 0 unless $db;

        my $is_txn = $self->is_transact($tableid);
        my $put_count = 0;

        for my $k_orig ( keys %$kv_map ) {
            next unless defined $k_orig && $k_orig ne '';
            my $v_item = $kv_map->{$k_orig};
            next unless defined $v_item;

            my $k = $self->utf_encode("$k_orig");

            # Transaction logging: capture before-image once per transaction
            if ( $is_txn && !$self->{_txn}->{logged}->{"$table_path\x1e$k_orig"}++ ) {
                my $old_raw;
                my $ret     = $db->get( $k, $old_raw );
                my $action  = ( $ret == 0 && defined $old_raw ) ? 'edit' : 'add';
                my $old_hex = ( $ret == 0 && defined $old_raw ) ? unpack("H*", $old_raw) : '__NULL__';
                $self->_txn_log( 'index', $tableid, $table_path, $k_orig, $action, $old_hex );
            }

            my $v_encoded;
            if ( ref($v_item) eq 'ARRAY' ) {
                next unless @$v_item;
                $v_encoded = $self->bin_encode($v_item);
            }
            elsif ( ( $type eq 'bin' || $type eq 'raw_bin' ) && !ref($v_item) ) {
                $v_encoded = $v_item;
            }
            elsif ($is_unq) {
                # .unq dictionary strings may contain Unicode
                $v_encoded = $self->utf_encode($v_item);
            }
            else {
                # .inx, .fac, .slg, .fld, .src: numeric or binary payloads — zero utf overhead
                $v_encoded = $v_item;
            }

            next unless defined $v_encoded && $v_encoded ne '';
            my $ret = $db->put( $k, $v_encoded );
            if ( $ret == 0 ) {
                $put_count++;
            }
            else {
                warn "[DB_TIE] $table_path can't put key $k.\n";
            }
        }

        # RAM-disk Tier 2 (mirror) or (Tier 4 in active transaction) dual-write
        if ( !$no_mirror && $tableid && $self->ramdisk_is_mounted() ) {
            my $table_info  = eval { $self->table_info($tableid) };
            my $use_ramdisk = $table_info ? $self->_normalize_ramdisk_tier( $table_info->{use_ramdisk} // $table_info->{use_cache} // 0 ) : 0;
            if ( $use_ramdisk == 2 || ( $use_ramdisk == 4 && $is_txn ) ) {
                my $ram_dir   = $self->ramdisk_dir();
                my $is_in_ram = ( $ram_dir && index( $table_path, $ram_dir ) == 0 ) ? 1 : 0;
                my ($ext)     = $table_path =~ m{\.([^.]+)$};
                my $mirror_path;
                if ( $ext && $ext =~ /^(?:\Q$self->{db_ext}\E|inx|src|fld|fac|unq|slg)$/ ) {
                    if ($is_in_ram) {
                        my $tbl_path = $self->table_path($tableid);
                        $mirror_path = "$tbl_path.$ext" if $tbl_path;
                    }
                    else {
                        my $r_path = $self->ramdisk_path($tableid);
                        $mirror_path = "$r_path.$ext" if $r_path;
                    }
                    if ( $mirror_path && $mirror_path ne $table_path ) {
                        $self->index_put( [ $mirror_path, $tableid, 1 ], $kv_map, $type );
                    }
                }
            }
        }

        return $put_count;
    }

    # -------------------------------------------------------------------------
    # SINGULAR PUT: Single key/val put
    # -------------------------------------------------------------------------
    return unless defined $key && $key ne '' && defined $val;

    if ( !$self->{_db}->{$table_path} || !$self->{_dbm}->{$table_path} ) {
        $self->table_write($table_path)
          or do { cluck "[DB_TIE] $table_path can't open for index_put.\n"; return; };
    }

    my $db = $self->{_db}->{$table_path};
    return unless $db;

    my $is_txn = $self->is_transact($tableid);
    my $k = $self->utf_encode("$key");

    # Transaction logging: capture before-image once per transaction
    if ( $is_txn && !$self->{_txn}->{logged}->{"$table_path\x1e$key"}++ ) {
        my $old_raw;
        my $ret     = $db->get( $k, $old_raw );
        my $action  = ( $ret == 0 && defined $old_raw ) ? 'edit' : 'add';
        my $old_hex = ( $ret == 0 && defined $old_raw ) ? unpack("H*", $old_raw) : '__NULL__';
        $self->_txn_log( 'index', $tableid, $table_path, $key, $action, $old_hex );
    }

    $type = lc( $type // '' );

    my $v_encoded;
    if ( ref($val) eq 'ARRAY' ) {
        return unless @$val;
        $v_encoded = $self->bin_encode($val);
    }
    elsif ( ( $type eq 'bin' || $type eq 'raw_bin' ) && !ref($val) ) {
        $v_encoded = $val;
    }
    elsif ($is_unq) {
        # .unq dictionary strings may contain Unicode
        $v_encoded = $self->utf_encode($val);
    }
    else {
        # .inx, .fac, .slg, .fld, .src: numeric or binary payloads — zero utf overhead
        $v_encoded = $val;
    }

    return unless defined $v_encoded && $v_encoded ne '';

    my $ret = $db->put( $k, $v_encoded );
    warn "[DB_TIE] $table_path can't put key $k.\n" if $ret < 0;

    # RAM-disk Tier 2 (mirror) or (Tier 4 in active transaction) dual-write
    if ( !$no_mirror && $tableid && $self->ramdisk_is_mounted() ) {
        my $table_info  = eval { $self->table_info($tableid) };
        my $use_ramdisk = $table_info ? $self->_normalize_ramdisk_tier( $table_info->{use_ramdisk} // $table_info->{use_cache} // 0 ) : 0;
        if ( $use_ramdisk == 2 || ( $use_ramdisk == 4 && $is_txn ) ) {
            my $ram_dir   = $self->ramdisk_dir();
            my $is_in_ram = ( $ram_dir && index( $table_path, $ram_dir ) == 0 ) ? 1 : 0;
            my ($ext)     = $table_path =~ m{\.([^.]+)$};
            my $mirror_path;
            if ( $ext && $ext =~ /^(?:\Q$self->{db_ext}\E|inx|src|fld|fac|unq|slg)$/ ) {
                if ($is_in_ram) {
                    my $tbl_path = $self->table_path($tableid);
                    $mirror_path = "$tbl_path.$ext" if $tbl_path;
                }
                else {
                    my $r_path = $self->ramdisk_path($tableid);
                    $mirror_path = "$r_path.$ext" if $r_path;
                }
                if ( $mirror_path && $mirror_path ne $table_path ) {
                    $self->index_put( [ $mirror_path, $tableid, 1 ], $key, $val, $type );
                }
            }
        }
    }

    return $ret == 0 ? 1 : 0;
}

# Deletes single or multiple index keys.
# Plural Usage:
#   $adb->index_del($table_path, \@keys);
#   $adb->index_del([$table_path, $tableid], \@keys);
# Singular Usage:
#   $adb->index_del($table_path, $key);
#   $adb->index_del([$table_path, $tableid], $key);
# ------------------------------------------------
sub index_del {
    my ( $self, $target, $key, @more_keys ) = @_;

    my ( $table_path, $tableid, $no_mirror );
    if ( ref($target) eq 'ARRAY' ) {
        ( $table_path, $tableid, $no_mirror ) = @$target;
    }
    else {
        $table_path = $target;
        ($tableid) = $table_path =~ m{([^/\\:]+)\.[^.]+$} if defined $table_path;
    }

    return unless $table_path && defined $key;

    my $is_unq = ( $table_path =~ /\.unq$/ ) ? 1 : 0;

    my @keys_to_del;
    if ( ref($key) eq 'ARRAY' ) {
        @keys_to_del = @$key;
    }
    elsif ( @more_keys ) {
        @keys_to_del = ( $key, @more_keys );
    }
    else {
        # Singular fast path
        return unless $key ne '';
        if ( !$self->{_db}->{$table_path} || !$self->{_dbm}->{$table_path} ) {
            $self->table_write($table_path)
              or do { cluck "[DB_TIE] $table_path can't open for index_del.\n"; return; };
        }
        my $db = $self->{_db}->{$table_path};
        return unless $db;

        my $is_txn = $self->is_transact($tableid);
        my $k = $self->utf_encode("$key");

        if ( $is_txn && !$self->{_txn}->{logged}->{"$table_path\x1e$key"}++ ) {
            my $old_raw;
            my $ret = $db->get( $k, $old_raw );
            if ( $ret == 0 && defined $old_raw ) {
                my $old_hex = unpack("H*", $old_raw);
                $self->_txn_log( 'index', $tableid, $table_path, $key, 'del', $old_hex );
            }
        }

        my $ret = $db->del($k);

        # RAM-disk Tier 2 (mirror) or (Tier 4 in active transaction) dual-write
        if ( !$no_mirror && $tableid && $self->ramdisk_is_mounted() ) {
            my $table_info  = eval { $self->table_info($tableid) };
            my $use_ramdisk = $table_info ? $self->_normalize_ramdisk_tier( $table_info->{use_ramdisk} // $table_info->{use_cache} // 0 ) : 0;
            if ( $use_ramdisk == 2 || ( $use_ramdisk == 4 && $is_txn ) ) {
                my $ram_dir   = $self->ramdisk_dir();
                my $is_in_ram = ( $ram_dir && index( $table_path, $ram_dir ) == 0 ) ? 1 : 0;
                my ($ext)     = $table_path =~ m{\.([^.]+)$};
                my $mirror_path;
                if ( $ext && $ext =~ /^(?:\Q$self->{db_ext}\E|inx|src|fld|fac|unq|slg)$/ ) {
                    if ($is_in_ram) {
                        my $tbl_path = $self->table_path($tableid);
                        $mirror_path = "$tbl_path.$ext" if $tbl_path;
                    }
                    else {
                        my $r_path = $self->ramdisk_path($tableid);
                        $mirror_path = "$r_path.$ext" if $r_path;
                    }
                    if ( $mirror_path && $mirror_path ne $table_path ) {
                        $self->index_del( [ $mirror_path, $tableid, 1 ], $key );
                    }
                }
            }
        }

        return $ret == 0 ? 1 : 0;
    }

    # Plural path:
    return 0 unless @keys_to_del;
    if ( !$self->{_db}->{$table_path} || !$self->{_dbm}->{$table_path} ) {
        $self->table_write($table_path)
              or do { cluck "[DB_TIE] $table_path can't open for index_del.\n"; return 0; };
    }
    my $db = $self->{_db}->{$table_path};
    return 0 unless $db;

    my $is_txn = $self->is_transact($tableid);
    my $del_count = 0;
    for my $k_item (@keys_to_del) {
        next unless defined $k_item && $k_item ne '';
        my $k = $self->utf_encode("$k_item");

        if ( $is_txn && !$self->{_txn}->{logged}->{"$table_path\x1e$k_item"}++ ) {
            my $old_raw;
            my $ret = $db->get( $k, $old_raw );
            if ( $ret == 0 && defined $old_raw ) {
                my $old_hex = unpack("H*", $old_raw);
                $self->_txn_log( 'index', $tableid, $table_path, $k_item, 'del', $old_hex );
            }
        }

        my $ret = $db->del($k);
        $del_count++ if $ret == 0;
    }

    # RAM-disk Tier 2 (mirror) or (Tier 4 in active transaction) dual-write
    if ( !$no_mirror && $tableid && $self->ramdisk_is_mounted() ) {
        my $table_info  = eval { $self->table_info($tableid) };
        my $use_ramdisk = $table_info ? $self->_normalize_ramdisk_tier( $table_info->{use_ramdisk} // $table_info->{use_cache} // 0 ) : 0;
        if ( $use_ramdisk == 2 || ( $use_ramdisk == 4 && $is_txn ) ) {
            my $ram_dir   = $self->ramdisk_dir();
            my $is_in_ram = ( $ram_dir && index( $table_path, $ram_dir ) == 0 ) ? 1 : 0;
            my ($ext)     = $table_path =~ m{\.([^.]+)$};
            my $mirror_path;
            if ( $ext && $ext =~ /^(?:\Q$self->{db_ext}\E|inx|src|fld|fac|unq|slg)$/ ) {
                if ($is_in_ram) {
                    my $tbl_path = $self->table_path($tableid);
                    $mirror_path = "$tbl_path.$ext" if $tbl_path;
                }
                else {
                    my $r_path = $self->ramdisk_path($tableid);
                    $mirror_path = "$r_path.$ext" if $r_path;
                }
                if ( $mirror_path && $mirror_path ne $table_path ) {
                    $self->index_del( [ $mirror_path, $tableid, 1 ], \@keys_to_del );
                }
            }
        }
    }

    return $del_count;
}

# Writes add|edit|del operation to daily CSV backup audit stream (backup/YYYY/YYYY-MM-DD.csv).
# Exits silently if no_backup is set (globally or in table schema).
# my $ok = $adb->recs_back("add|edit|del", $tableid, @records);
# ------------------------------------------------
sub recs_back {

    my ( $self, $action, $tableid, @records ) = @_;

    ( $action and $tableid and scalar @records ) or return;

    # Global config check: disables backup for all tables
    return 1 if $self->config('no_backup');

    # Table schema check: no_backup => 1 in table schema or volatile Tier 3 RAM-disk
    my $table_info = $self->table_info($tableid);
    return 1 if $table_info->{no_backup} || ( $table_info->{use_ramdisk} // 0 ) == 3;

    my $user = $self->config('user') || 'system';

    $tableid =~ s/[:\/\\]/--/g;

    my $backup_base = $self->path('backup_dir')
      || ( $self->path('dbase_dir') ? $self->path('dbase_dir') . "/backup" : "backup" );
    my $year = ( $self->{date} && $self->{date}->{year} ) ? $self->{date}->{year} : (localtime)[5] + 1900;
    my $month = ( $self->{date} && $self->{date}->{month} ) ? $self->{date}->{month} : sprintf( "%02d", (localtime)[4] + 1 );
    my $day = ( $self->{date} && $self->{date}->{day} ) ? $self->{date}->{day} : sprintf( "%02d", (localtime)[3] );
    my $date_iso = "$year-$month-$day";
    my $time_str = ( $self->{date} && $self->{date}->{str} ) ? $self->{date}->{str} : "$date_iso " . sprintf( "%02d:%02d:%02d", (localtime)[2], (localtime)[1], (localtime)[0] );

    my $backup_file;
    if ( $self->config('simple') ) {
        $backup_file = "$backup_base/$date_iso.csv";
    }
    else {
        my $year_dir = "$backup_base/$year";
        $self->make_path($year_dir);
        $backup_file = "$year_dir/$date_iso.csv";
    }

    open my $YAZ, ">>:encoding(UTF-8)", $backup_file
      or do {
        cluck "[DB_BACKUP] Cannot open backup file $backup_file: $!\n";
        return;
      };

    foreach my $record (@records) {
        ref($record) eq "ARRAY" or $record = [$record];
        my $rid     = $record->[0];
        my $bac_val = $self->db_encode( @{$record}[ 1 .. $#$record ] );
        print $YAZ "$time_str\t$user\t$action\t$tableid\t$rid\t$bac_val\n";
    }
    close $YAZ;

    return 1;
}

# my $view_pre = $adb->auth_view($tableid, $rid);
# Returns add/edit/del audit history on record as HTML <pre>.
# ------------------------------------------------
sub auth_view {

    my ( $self, $tableid, $rid ) = @_;

    return unless $rid;
    return unless $tableid;
    return unless ref $self->{_auth}->{$tableid}->{$rid} eq "ARRAY";

    my $string;
    foreach my $line ( @{ $self->{_auth}->{$tableid}->{$rid} } ) {
        if ( ref $line eq "ARRAY" ) {
            my $date = $self->dateid2str( $line->[2] );
            if ( $line->[1] ne "edit" ) { $line->[1] .= " " }
            $string .= "    $line->[1]\t$date\t$line->[0]\n";

        }
        else {
            $string .= "--> $line\n";
            $string .= "----------------\n";
        }
    }

    return $string;
}

# Loads record ownership audit trail into memory (_auth) from .aut file.
# AUTH called internally only from read_list and read_id.
# my $ok = $adb->auth_read($tableid, $table_path, @record_ids);
# ------------------------------------------------
sub auth_read {

    my ( $self, $tableid, $table_path, @record_ids ) = @_;

    return unless $tableid;
    return unless -e "$table_path.$self->{db_ext}";
    return unless -e "$table_path.aut";
    return unless scalar @record_ids;

    my $table_info = $self->table_info($tableid);
    return unless $table_info->{log_owner};

    my @lookup_keys;
    my %esc_map;
    foreach my $rid (@record_ids) {
        $self->{_auth}->{$tableid}->{$rid} and next;
        my $rid_escape = $self->key_encode($rid) // $rid;
        push @lookup_keys, $rid_escape;
        $esc_map{$rid} = $rid_escape;
    }

    return 1 unless @lookup_keys;

    my $aut_path = "$table_path.aut";
    $self->table_read($aut_path) or return 1;
    my $res = $self->recs_get( $aut_path, @lookup_keys );
    $self->table_close($aut_path);
    if ($res) {
        foreach my $rid (@record_ids) {
            $self->{_auth}->{$tableid}->{$rid} and next;
            my $rid_escape = $esc_map{$rid} // $rid;
            my $val = $res->{$rid_escape} // $res->{$rid};
            if ( defined $val && $val ne '' ) {
                $self->{_auth}->{$tableid}->{$rid} = [ $self->db_decode($val) ];
            }
        }
    }

    return 1;
}

# Writes user/action audit to .aut file. Active when log_owner is enabled.
# my $ok = $adb->auth_write($tableid, $table_path, "add|edit|del", $rid);
# ------------------------------------------------
sub auth_write {

    my ( $self, $tableid, $table_path, $action, $rid ) = @_;

    return unless $tableid;
    my $table_info = $self->table_info($tableid);
    return
      unless ( $rid
        && $action
        && $table_path
        && $table_info->{record_index}
        && $table_info->{log_owner}
        && $action =~ /^(add|edit|del)$/ );
    return unless -e "$table_path.$self->{db_ext}";

    my $file_path = "$table_path.aut";

    $self->table_write($file_path)
      or do { cluck "[DB_TIE] $tableid -> $action, Autority write error. Can't open.\n"; return; };

    my $value = $self->recs_get( $file_path, $rid );

    my @record = $self->db_decode( $value->{$rid} );
    my $user   = $self->config('user') || 'user_system';
    if ( !scalar @record ) {
        if ( $action ne "add" ) {
            @record = (
                "root", [ "root", "add", $self->{date}->{year} . "01010000" ]
            );
        }
        else {
            @record = ( $user );
        }
    }
    push @record,
      [ $user, $action, $self->{date}->{minute_id} ];
    $self->recs_put( [ $file_path, $tableid ], [ $rid, @record ] );
    $self->table_close($file_path);

    return 1;
}

# Cache and buffer methods have been moved to AmberDB::Cache.
# Transaction methods have been moved to AmberDB::Transact.

1;

__END__

=encoding utf8

=head1 NAME

AmberDB - High-performance embedded NoSQL database engine for Perl

=head1 SYNOPSIS

  use AmberDB;
  my $adb = AmberDB->new(
      cfg  => { language => "gb" },
      path => { dbase_dir => "./dbstore" }
  );

  my @record = ( 0, "John Doe", "New York", 1980, 'john@example.com' );

  # Insert record
  $adb->insert_id("table_id", @record);

  # Update record (update_id / modify_id)
  $adb->update_id("table_id", @record_updated);

  # Delete record
  $adb->delete_id("table_id", $record_id);

  # Read record by ID
  my @record = $adb->read_id("table_id", $record_id);

  # Read all records
  my @records = $adb->read_all("table_id");

  # Read list of records by IDs
  my @records = $adb->read_list("table_id", \@id_list);

  # Search for the string "New York" in field 2 using the match function.
  my @records = $adb->field_fetch("table_id", 2, "New York");
  # or if the New York ID is 142
  my @records = $adb->field_fetch("table_id", 2, 142);


  # Full-text string search
  my @records = $adb->search_table("table_id", "search string");

  # If `read_all`, `field_fetch`, and `search_table` take the `$limit` parameter, they will not read all records; they will read a specific range based on `offset` and `limit`, and return the number of records at the beginning.
  my ($count, @records) = $adb->read_all("table_id", $offset, $limit);
  my ($count, @records) = $adb->field_fetch("table_id", $field_no, $match_value, $offset, $limit);
  my ($count, @records) = $adb->search_table("table_id", "search string", $offset, $limit);

  # Direct low-level table access
  $adb->table_write($file_path);
  my $records = $adb->recs_get($file_path, @rec_ids);
  my $ok      = $adb->recs_put($file_path, @records);
  $adb->table_close($file_path);

  # Transaction example (Checkout / Stock operation)
  my $res = $adb->transact_start();
  my $order_id = $adb->insert_id("order", 0, $user_id, $item_id, $qty);
  if ( !$order_id ) {
      $adb->transact_error();
  }
  my $stock_id = $adb->modify_id("stock", $item_id, $user_id, $item_id, $new_qty);
  $adb->transact_end();

=head1 DESCRIPTION

C<AmberDB> is a high-performance, flat-file NoSQL database engine for Perl built on top of Berkeley DB (C<DB_File>). It combines the speed of flat-file storage with enterprise features: schema-driven multi-dimensional indexing, ACID-compliant transactions with Strict Two-Phase Locking (Strict 2PL), columnar faceted navigation, multilingual locale processing, and native RAM-disk caching.

=head1 SUBMODULE ARCHITECTURE & INHERITANCE

C<AmberDB> is built as a unified coordinator that incorporates all functionality from specialized submodules via inheritance (C<use parent>). When you instantiate an C<AmberDB> object (C<$adb>), all methods from the following submodules are directly available as methods on C<$adb>:

=over 4

=item * B<L<AmberDB::Date>> - Compact chronological ID getters (C<day_id>, C<second_id>, C<month_id>), date string parsing (C<str2dateid>, C<dateid2str>), range generation (C<day_range>), ISO week numbers (C<dateid2week>), and relative offset calculation (C<offset2date>).

=item * B<L<AmberDB::Locale>> - Multilingual text processing, locale-aware casing (C<uc>, C<lc>, C<ucfirst>), Unicode Collation (UCA) sorting (C<sort>), ASCII transliteration (C<to_ascii>), number-to-words / cheque conversion (C<num2text>), number formatting (C<format_number>), currency formatting (C<format_currency>), ISO 4217 currency dictionary (definitions, symbols, UI dropdowns), and CLDR pluralization (C<plural>) across 10 supported languages (C<gb> [default], C<en>, C<tr>, C<de>, C<fr>, C<es>, C<ru>, C<az>, C<ar>, C<ja>).

=item * B<L<AmberDB::Tools>> - Enterprise database utilities: backup (C<.amberdb> tar archive with SHA-256 integrity), atomic restore, CSV migration (C<tie2csv>, C<csv2tie>), vacuum compaction, and reindexing.

=back

All submodules (except C<AmberDB::Tools> which takes an C<$adb> handle) can also be instantiated and used independently in standalone scripts.

=head1 TABLE NAMING CONVENTIONS

AmberDB enforces a strict, deterministic lowercase snake_case table naming convention:

=over 4

=item * B<Format:> All table identifiers must consist of lowercase alphanumeric characters in snake_case, structured as C<E<lt>databaseE<gt>_E<lt>table_nameE<gt>> (e.g. C<catalog_product>, C<member_address>, C<orders_item>).

=item * B<Database Prefix Resolution:> The segment before the first underscore (C<_>) represents the logical database/schema group (mapped to C<E<lt>databaseE<gt>.dbase>).

=item * B<Schema Files:> A table C<catalog_product> automatically resolves its schema from C<catalog_product.table> and its database group settings from C<catalog.dbase>.

=item * B<Constraint:> Uppercase or mixed-case table names (e.g. C<Catalog_Product>) are not supported and will fail database group extraction.

=back

=head1 SCHEMA DEFINITION & CONFIGURATION (.table & IN-MEMORY)

AmberDB is schema-driven. Table schemas define primary key constraints, field blocks, multi-dimensional indexes, automatic URL slug generation, facet filters, lifecycle junk rules, and repeating nested items.

Schemas can be defined in two ways:

=over 4

=item 1.

B<Disk-Based Schema Files:> Placed in the C<dbstore/schema/E<lt>table_nameE<gt>.table> directory. AmberDB loads and parses them automatically upon first access.

=item 2.

B<Programmatic In-Memory Schemas:> Defined directly on the AmberDB instance via C<$adb-E<gt>table_attr('table_id', { ... })>.

=back

=head2 Example Table Schema (C<catalog_product.table>)

Defining blocks in the schema is not mandatory. However, `record_index`, `match_block`, `search_block`, and `sort_block` are crucial, especially for the automatic creation of indexes during record keeping. `record_index` only takes the value 0/1. `match_block` and `search_block` determine which blocks will be indexed, while `sort_block` determines both the blocks to be sorted and the sort type.

  {
      name         => "Product Catalog",
      record_index => 1,                      # Enable .inx primary record index
      match_block  => [1, 2, 3, 11],          # .fld exact field match indexes (Category, Brand, etc.)
      search_block => [4, 5, 7],              # .src full-text search fields (Title, Subtitle, Description)
      sort_block   => [ 4, { blk => 10, type => 'num' } ], # .inx pre-sorted ID buffers
      keep_deleted => 1,                      # Enable soft-delete audit log (.del)
      log_owner    => 1,                      # Enable change audit logging (.aut)
  }

=head2 Dynamic Runtime Schema Manipulation (C<table_attr>)

Schemas can be dynamically reconfigured in-memory at runtime without modifying disk files or requiring table migrations:

  # Dynamically change full-text search fields on the fly
  $adb->table_attr("catalog_product", { search_block => [ 4, 9 ] });

  # Toggle ramdisk acceleration or soft-delete modes dynamically
  $adb->table_attr("catalog_product", { use_ramdisk => 0, keep_deleted => 0 });

=head2 Expandable Records without SQL JOINs (Repeating Blocks)

AmberDB supports hierarchical, JSON-like extensible records without the need for child tables or relational C<JOIN> queries. Multiple repeating child items (e.g., order lines, cart items, invoice lines) can be appended directly to the parent record. C<repeat_start> should indicate the block number where the last repeating record started. The AmberDB engine writes the first ID of each row from C<repeat_start> to the end, concatenated by commas, to the C<repeat_ids> block. You must ensure that this block number also appears in C<match_block>.

  # Schema configuration for expanding order table
  {
      name         => "Customer Orders",
      record_index => 1,
      match_block  => [1, 2, 4],    # Customer ID, Order Date, Products
      repeat_ids   => 4,            # products field: item ids, separated by comma
      repeat_start => 5,            # repeat block begin at block 5
      blocks       => [
          { id => "id",          name => "Order ID",     type => "auto_id" },
          { id => "customer_id", name => "Customer ID",  type => "text" },
          { id => "order_date",  name => "Order Date",   type => "text" },
          { id => "total_price", name => "Total Amount", type => "num" },
          { id => "products",    name => "Products",     type => "text" },
          # Repeating line items:
          { id => "item_id",     name => "Item ID",      type => "text" },
          { id => "item_title",  name => "Product Title",type => "text" },
          { id => "item_qty",    name => "Quantity",     type => "num" },
          { id => "item_price",  name => "Unit Price",   type => "num" },
      ],
  }

=head1 TRANSACTIONS

Transactions provide multi-table atomic updates backed by undo-log journals.
If a database error occurs (e.g. file lock failure, duplicate ID), or if custom business validation fails (e.g. insufficient stock),
all base records and indexes across all affected tables are restored to their exact pre-transaction state.

=head2 Checkout / Stock Deduction Example

  $adb->transact_start();

  # 1. Check & update stock
  my @product = $adb->read_id("product", $product_id);
  my $current_stock = $product[4];

  if ($current_stock < $quantity) {
      # Operational condition (out of stock): Directly roll back and release locks
      $adb->transact_rollback();
      return { success => 0, error => "Out of stock" };
  }

  $product[4] -= $quantity;
  $adb->modify_id("product", $product_id, @product);

  # 2. Insert order record
  my $order_id = $adb->insert_id("orders", 0, $user_id, $product_id, $quantity, time());

  # 3. Finalize transaction (auto-rollbacks if base error occurred)
  my $txn = $adb->transact_end();
  if ($txn->{status} eq 'commit') {
      return { success => 1, order_id => $order_id };
  } else {
      return { success => 0, error => "The operation failed, the changes were reverted." };
  }

B<Note / Limitations:> Bulk/list operations (C<insert_list>, C<modify_list>, C<delete_list>) do not support the transact operation. There is a fundamental reason for this. Junk operations are designed for loading, editing, or deleting a list containing records of the same type. Records in a list do not hierarchically affect each other. For example, when entering 1000 product records in bulk via XML, if one or more of them cannot be saved due to incorrect formatting, it does not cause a problem for the other records.

Furthermore, if the user truly wants to perform an operation on the list using transact, they can put it in a loop and use the individual C<insert_id>, C<modify_id>, C<delete_id> operations.

=head1 SIMPLE MODE (SCHEMA-LESS FLAT STORE)

In addition to its schema-driven enterprise mode, AmberDB provides a lightweight B<Simple Mode> (C<simple =E<gt> 1>). In Simple Mode, the database operates as an ultra-fast, schemaless NoSQL key-value/document store directly on flat C<.db> (or custom extension) files without secondary binary indexes (C<.inx>, C<.src>, C<.fld>, C<.fac>, C<.slg>, C<.aut>, C<.del>).

=head2 Key Characteristics of Simple Mode

=over 4

=item * B<Arbitrary & Flexible Keys:> The 8-byte ASCII limit and numeric constraints are bypassed. Keys can be emails (C<user@example.com>), UUIDs, long tokens, or Unicode/multilingual strings.

=item * B<Flat Directory Structure:> All tables reside directly under C<dbase_dir> (e.g. C<$dbase_dir/table.db>). No C<table/> or C<schema/> subfolders are required.

=item * B<Rich Nested Structures:> Records can store nested array and hash references (ARRAY/HASH) directly.

=item * B<Continuous Daily Backup Logs:> Text-based continuous daily WAL/CSV logs (C<recs_back>) automatically record all C<add>, C<edit>, and C<del> operations directly into C<$dbase_dir/YYYY-MM-DD.csv> alongside database tables (can be silenced with C<no_backup =E<gt> 1>).

=item * B<ACID Transactions:> Full multi-table transaction support with atomic rollback (restoring raw records in the C<.db> file).

=item * B<Streaming Queries & Sorting:> Methods like C<read_all>, C<field_fetch>, and C<search_table> operate via direct sequential streaming scans with full support for pagination (C<offset>/C<limit>, with legacy C<start>), C<keys_only>, and in-memory sorting.

=item * B<Zero-Latency RAM-Disk Caching:> Simple mode instances can be initialized directly on RAM-disk mount points (Linux C</dev/shm>, macOS C</Volumes/AmberDB_RAM>, or Windows ImDisk C<R:>) to provide nanosecond-speed transient session and cache stores.

=back

=head2 Simple Mode Example

  # 1. Initialize simple mode
  my $adb = AmberDB->new(
      path => { dbase_dir => "/var/data/sessions" },
      cfg  => { simple    => 1, user => 'admin' },
  );

  # 2. Insert with arbitrary key
  $adb->insert_id('sessions', 'user@example.com', 'Active', 'Chrome', time());

  # 3. Read record (O(1))
  my @sess = $adb->read_id('sessions', 'user@example.com');

  # 4. Search and filter without indexes
  my ($count, @active) = $adb->field_fetch('sessions', 1, 'Active', 0, 10);

  # 5. Volatile in-memory simple store
  my $ram_db = AmberDB->new(
      path => { dbase_dir => "/dev/shm/amber_tokens" },
      cfg  => { simple    => 1, no_backup => 1 },
  );
  $ram_db->insert_id('tokens', $token_id, $user_id, time());

=head1 RAM-DISK ACCELERATION

AmberDB features a built-in, transparent physical RAM-disk acceleration engine (Linux C<tmpfs>, macOS C<APFS RAM-Disk> via C<hdiutil>, or Windows C<ImDisk>). It enables high-traffic tables and hot indexes to operate at pure volatile memory speeds while ensuring persistent durability on permanent disk.

=head2 What is it?

RAM-disk acceleration routes file I/O for database tables to an operating system RAM-disk filesystem mounted under C<dbstore/ramdisk/> or a custom path (e.g. C<R:\amberdb> on Windows or C</Volumes/AmberDB_RAM> on macOS). Unlike key-value network caches (such as Redis or Memcached), it works directly at the filesystem block level using AmberDB's native file architecture without requiring external server processes, network daemons, or custom serialization protocols.

=head2 How It Works

=over 4

=item * B<Native File Formats:> AmberDB stores all table data and index files on RAM-disk using their exact native file extensions (C<.db>, C<.inx>, C<.fld>, C<.src>, C<.fac>, C<.unq>, C<.slg>). No proprietary cache file format is used.

=item * B<Dual-Write Synchronization:> For accelerated tables, reads are served at microsecond RAM speeds directly from RAM-disk. Writes synchronously update both the persistent disk file and the RAM-disk file, ensuring complete data durability without stale reads.

=item * B<ACID Transaction Safety:> Transactions (C<transact_start>, C<transact_end>, C<transact_rollback>) protect RAM-disk operations with disk-backed undo journals and strict two-phase locking (Strict 2PL).

=item * B<Automated Mount Detection & Graceful Fallback:> The engine automatically verifies whether the RAM-disk filesystem is actively mounted. If unmounted, AmberDB gracefully falls back to persistent disk storage without throwing errors or interrupting application operations.

=back

=head2 Acceleration Tiers (C<use_ramdisk>)

Tables can be assigned an acceleration tier via the C<use_ramdisk> schema flag or dynamically via C<table_attr()>:

=over 4

=item * B<Tier 1 (Hybrid Index-Only, C<use_ramdisk =E<gt> 1>):> Only secondary index files (C<.inx>, C<.fld>, C<.src>, C<.fac>, C<.unq>, C<.slg>) are placed in RAM-disk. Primary table data (C<.db>) remains on persistent disk. Lookups and filters run at memory speeds, while RAM consumption remains minimal.

=item * B<Tier 2 (Full Table Mirror, C<use_ramdisk =E<gt> 2>):> Both primary records (C<.db>) and all index files are mirrored on RAM-disk. Reads are served directly from RAM-disk with synchronous dual-writing to permanent storage.

=item * B<Tier 3 (Volatile In-Memory, C<use_ramdisk =E<gt> 3>):> Operates purely in RAM-disk as an unindexed simple store (C<use_simple =E<gt> 1>) with zero physical disk files. Ideal for ephemeral sessions, shopping carts, and temporary tokens. Supports sliding TTL expiration (C<ramdisk_ttl =E<gt> 300>).

=back

=head2 Transparent Management (C<use_ramdisk>)

AmberDB manages the RAM-disk layer entirely in the background. Developers do not need to call any low-level RAM-disk functions or manually orchestrate memory synchronization. Everything is controlled declaratively via the C<use_ramdisk> option:

=over 4

=item * B<Global Configuration:> Set globally at instantiation (C<AmberDB-E<gt>new(cfg =E<gt> { use_ramdisk =E<gt> 1 })>) or at runtime via C<$adb-E<gt>config(use_ramdisk =E<gt> 2)>.

=item * B<Per-Table Customization:> Set independently for each table in its C<.table> schema or via C<$adb-E<gt>table_attr($table, use_ramdisk =E<gt> $tier)>.

=item * B<Standard CRUD Workflow:> Continue using standard AmberDB methods (C<read_id>, C<search_table>, C<insert_id>, C<modify_id>). The engine automatically reads from memory at microsecond speeds and dual-writes to permanent storage.

=item * B<Unified CLI Administration:> Use C<amberdb_setup.pl> to manage infrastructure, RAM-disk mounts, permissions, migrations, and service automation across all operating systems:

  - Mount RAM-disk:   perl bin/amberdb_setup.pl --action=ramdisk --start --size 512M
  - Status check:     perl bin/amberdb_setup.pl --action=ramdisk --status
  - Full Provision:   perl bin/amberdb_setup.pl --action=install --user=eticaretim --size 256M --cron --service

=back

=head1 COMMAND-LINE TOOLS (CLI)

AmberDB provides two standalone command-line utilities in its C<bin/> directory for infrastructure provisioning, maintenance, and interactive database operations:

=over 4

=item * B<amberdb_cli.pl:> Management console and interactive query utility. Supports token-based session lifecycles, database dashboards, CRUD operations, dynamic schema mutations (C<table_attr>), CSV import/export, and index rebuilding. Run C<perl bin/amberdb_cli.pl> without arguments to view the active database dashboard, or see C<perldoc bin/amberdb_cli.pl>.

=item * B<amberdb_setup.pl:> Consolidated infrastructure provisioning engine. Automates physical RAM-disk mounts (Linux tmpfs, macOS APFS, Windows ImDisk), user/group permissions, storage format migrations, CPAN engine updates, and crontab/systemd watchdog services. See C<perl bin/amberdb_setup.pl --help>.

=back

=head1 METHODS

=head2 new(%options)

Instantiates a new C<AmberDB> object.

    my $adb = AmberDB->new(
        cfg  => { language => "gb" },
        path => { dbase_dir => "./dbstore" },
    );

=head2 config([$key], [%options])

Gets or sets runtime configuration flags deterministically with automatic hook/side-effect dispatching (e.g. locale reloading, table path invalidation):

    # Single scalar getter
    my $lang = $adb->config('language');

    # Bulk getter (returns a safe shallow copy)
    my $cfg = $adb->config();

    # Key-value setter with method chaining
    $adb->config( language => 'gb', no_write => 1 );

    # Hashref setter
    $adb->config({ simple => 1, ramdisk_size => '1024M' });

=head2 insert_id($table_id, [$record_id], @record)

Inserts a new record into specified table. It automatically generates search, match, slug, and facet indexes if they are defined in the table schema. It supports transact operations. In normal records, there is no need to enter an ID value. It can be entered as empty, undef, or 0. The system automatically generates the ID using an incrementing counter and returns the ID value.

    # Auto-increment primary key ID (pass 0 or undef)
    my $new_id = $adb->insert_id("catalog_product", 0, "Widget Pro", "Electronics", 1250);

    # Explicit primary key ID
    $adb->insert_id("catalog_product", 5001, "Custom Widget", "Electronics", 2000);

=head2 insert_list($table_id, @records)

Inserts multiple records in a single bulk operation. Aside from Transact, it processes records, search, match, slug, and facet indexes all at once with high performance.

    $adb->insert_list("catalog_product",
        [ 0, "Item 1", "Category A", 100 ],
        [ 0, "Item 2", "Category B", 200 ],
    );

=head2 insert_links($table_id, @records)

Writes alias link bindings into the table's C<.lnk> routing index. Used specifically when duplicate records are deleted and consolidated/merged into a canonical record (requires C<use_alias =E<gt> 1> in table schema):

    # Map deleted duplicate ID 452 to canonical active ID 586
    $adb->delete_id("catalog_product", 452);
    $adb->insert_links("catalog_product", [ 452, 586 ]);

    # Multiple mappings in a single call
    $adb->insert_links("catalog_product", [ 452, 586 ], [ 453, 586 ]);

    # read_id queries for 452 will automatically/transparently fetch canonical record 586:
    my @rec = $adb->read_id("catalog_product", 452);

=head2 update_id($table_id, $record_id, @record)

Updates existing record data (alias: C<modify_id>). It automatically updates the search, match, slug, and facet indexes if they are defined in the table schema. It supports transact operations.

    $adb->update_id("catalog_product", 101, "Widget Pro v2", "Electronics", 1300);

=head2 modify_id($table_id, $record_id, @record)

Legacy alias for C<update_id>.

    $adb->modify_id("catalog_product", 101, "Widget Pro v2", "Electronics", 1300);

=head2 update_list($table_id, @records)

Modifies multiple records in a single bulk operation (alias: C<modify_list>). Aside from Transact, it processes records, search, match, slug, and facet indexes all at once with high performance.

    $adb->update_list("catalog_product",
        [ 101, "Item 1 Updated", "Category A", 150 ],
        [ 102, "Item 2 Updated", "Category B", 250 ],
    );

=head2 modify_list($table_id, @records)

Legacy alias for C<update_list>.

=head2 delete_id($table_id, $record_id)

Deletes specified record from table. Supports transaction logging.

    $adb->delete_id("catalog_product", 101);

=head2 delete_list($table_id, @records)

Deletes multiple records in a single bulk operation. Aside from Transact, it processes records, search, match, slug, and facet indexes all at once with high performance.

    $adb->delete_list("catalog_product", 101, 102, 103);

=head2 read_id($table_id, [$record_id], [\%options])

Reads a single record by primary key ID (or dynamic positional type) in $O(1)$ time.

Options:

=over 4

=item * C<type>: Positional selector (C<'last'>, C<'first'>, C<'rand'>). When specified, a dummy ID (e.g. C<0>) can be passed to preserve standard 3-argument positional signature consistency: C<< $adb->read_id("products", 0, { type => "last" }) >> (omitting the ID is also supported: C<< $adb->read_id("products", { type => "last" }) >>).

=item * C<sort>: Optional sort block (numeric index, schema block name like C<"price">, C<"price desc">, or hashref C<< { block => "price", dir => "asc" } >>). Used in combination with C<< type => 'first' >> or C<'last'> to retrieve the first or last record according to that block. For example, C<< type => 'first', sort => 'price' >> fetches the lowest price item, and C<< type => 'last', sort => 'price' >> fetches the highest price item.

=item * C<range>: Optional numerical/chronological range filter hashref C<< { block => 4, min => 1000, max => 2000 } >> to constrain candidate records before positional selection.

=item * C<inflate>: Boolean (C<1> or string C<"inflate">) to inflate record fields into a named HASH reference based on table schema blocks.

=item * C<counter> / C<use_counter>: Explicit boolean (C<1> or C<0>) or string C<"counter"> to force or disable incrementing the read counter (C<.cnt>).

=item * C<no_counter>: Explicit boolean (C<1>) or string C<"no_counter"> to suppress incrementing the read counter.

=item * C<deleted> / C<force>: Boolean (C<1>) or string C<"deleted"> / C<"force"> to read from soft-deleted archive (C<.del>) if missing from active table.

=item * C<links> / C<alias>: Boolean (C<1>) or string C<"links"> / C<"alias"> to resolve a deleted/merged record ID from alias link index (C<.lnk>) to its canonical record.

=back

    # Standard array return: ($id, @fields)
    my @record = $adb->read_id("catalog_product", 101);

    # Inflate record into named HASH ref
    my $record_hash = $adb->read_id("catalog_product", 101, { inflate => 1 });
    # or shorthand string:
    my $record_hash = $adb->read_id("catalog_product", 101, "inflate");

    # Positional reads using type (consistent 3-arg with dummy ID 0 or 2-arg):
    my @last_rec  = $adb->read_id("catalog_product", 0, { type => "last" });
    my @first_rec = $adb->read_id("catalog_product", 0, { type => "first" });
    my @rand_rec  = $adb->read_id("catalog_product", 0, { type => "rand" });
    # with inflate:
    my $last_hash = $adb->read_id("catalog_product", 0, { type => "last", inflate => 1 });

    # Positional reads with sort by a specific block (first or last):
    my @cheapest = $adb->read_id("catalog_product", 0, { type => "first", sort => "price" });
    my @priciest = $adb->read_id("catalog_product", 0, { type => "last", sort => "price" });

    # Shorthand string options:
    my @rec_nc = $adb->read_id("catalog_product", 101, "no_counter");
    my @rec_dl = $adb->read_id("catalog_product", 101, "deleted");
    # Alias lookup (e.g. duplicate record 452 was deleted and merged/linked to 586):
    my @rec_lk = $adb->read_id("catalog_product", 452, "alias");

=head2 read_lastid($table_id, [\%options])

Convenience alias for:

    $adb->read_id($table_id, 0, { type => "last", %opts });

Supports passing a sort block directly, e.g.:

    $adb->read_lastid("catalog_product", "price");
    # or
    $adb->read_lastid("catalog_product", { sort => "price" });

=head2 read_firstid($table_id, [\%options])

Convenience alias for:

    $adb->read_id($table_id, 0, { type => "first", %opts });

Supports passing a sort block directly, e.g.:

    $adb->read_firstid("catalog_product", "price");
    # or
    $adb->read_firstid("catalog_product", { sort => "price" });

=head2 read_randid($table_id, [\%options])

Convenience alias for:

    $adb->read_id($table_id, 0, { type => "rand", %opts });

=head2 read_all($table_id, [\%options])

Reads active records from table. Supports pagination, binary index optimization (C<.inx>), sorting, and C<keys_only>.

B<IMPORTANT (Return Signature Convention):>
When C<$limit> is passed and C<E<gt> 0> (paginated), C<read_all> returns C<($total_count, @records)> where the first scalar is the total matching count integer. When C<$limit> is omitted or C<0> (unpaginated), it returns C<@records> directly. Unpacking a paginated query into C<my @records> causes C<$records[0]> to be an integer scalar, which will crash if dereferenced as an array reference.

    # 1. Unpaginated (returns array of record arrayrefs directly)
    my @records     = $adb->read_all("catalog_product");
    my @sorted_desc = $adb->read_all("catalog_product", { sort => 2 });
    my @sorted_asc  = $adb->read_all("catalog_product", { sort => -2 });
    my @all_ids     = $adb->read_all("catalog_product", { keys_only => 1 });

    # 2. Paginated (limit > 0: first element is total matching count integer)
    my ($total_count, @page_records) = $adb->read_all("catalog_product", { offset => 0, limit => 20 });
    my ($total_count, @page_records) = $adb->read_all("catalog_product", { offset => 0, limit => 20, sort => -2 });

    # Tiered query mode: 'A' (Active only), 'B' (Junk only), 'AB' (Active first, then Junk)
    my @active_only = $adb->read_all("catalog_product", { jnktype => 'A' });
    my ($total_count, @all_tiered) = $adb->read_all("catalog_product", { offset => 0, limit => 20, jnktype => 'AB' });

    # Return only scalar record IDs (memory-efficient pipeline)
    my ($count, @ids) = $adb->read_all("catalog_product", { offset => 0, limit => 50, keys_only => 1 });

    # Numerical / chronological range filtering (min defaults to 0 if omitted; max unbounded if omitted):
    my @in_range  = $adb->read_all("catalog_product", { range => { block => 4, min => 1000, max => 2000 } });
    my @min_only  = $adb->read_all("catalog_product", { range => { block => 'price', min => 1800 } });
    my @max_only  = $adb->read_all("catalog_product", { range => { block => 'price', max => 500 } });

=head2 read_list($table_id, \@id_list)

Reads multiple records matching provided ID list while preserving exact list ordering.

    # Read the entire active order list.
    my @records = $adb->read_all("order_active");

    # Extract customer IDs from block 1 using the map.
    my %customer_ids = map { $_->[1] => 1 } @records;

    # You've found the customer ID keys, now read them using read_list.
    my @customers = $adb->read_list("customers", [ keys %customer_ids ]);

=head2 field_fetch($table_id, $block, $value, [\%options])

Fetches records matching one or more block values using the C<.fld> match index (or sequential table scan fallback if unindexed). Supports multi-value queries, automatic deduplication, sorting, pagination, and C<keys_only>.

B<IMPORTANT (Return Signature Convention):>
When C<$limit> is passed and C<E<gt> 0> (paginated), C<field_fetch> returns C<($total_count, @records)> where the first scalar is the total matching count integer. When C<$limit> is omitted or C<0> (unpaginated), it returns C<@records> directly. Unpacking a paginated query into C<my @records> causes C<$records[0]> to be an integer scalar, which will crash if dereferenced as an array reference.

    # 1. Unpaginated (returns array of record arrayrefs directly)
    my @records    = $adb->field_fetch("products", 1, "5");
    my @sorted_asc = $adb->field_fetch("products", 1, "5", { sort => -10 });

    # 2. Paginated (first element is total matching count integer)
    my ($total_count, @records) = $adb->field_fetch(
        "products", 1, "5",
        { offset => 0, limit => 20, sort => -10 }
    );

    # Multi-value matching (comma string, semicolon, or ARRAY ref)
    my @records = $adb->field_fetch("products", 1, ["5", "8"]);
    my @records = $adb->field_fetch("products", 1, "5, 8");

    # Return only record IDs: keys_only flag
    my @all_ids             = $adb->field_fetch("products", 1, "5", { keys_only => 1 });
    my ($total_count, @ids) = $adb->field_fetch("products", 1, "5", { offset => 0, limit => 20, keys_only => 1 });

    # Tiered Junk query mode
    my @active = $adb->field_fetch("products", 1, "5", { jnktype => 'A' }); # Only Active records

    # Numerical / chronological range filtering on an auxiliary block:
    my @range_prods = $adb->field_fetch("products", 2, "Smartphones", { range => { block => "price", min => 1000, max => 1500 } });

C<field_fetch> uses the C<match_block> definition in the schema and accesses inverted match index files (C<.fld>), providing $O(1)$ average-time lookup per indexed key (total retrieval cost scales with the number of requested values and matching record IDs). If C<match_block> is not defined or if running in simple mode, C<field_fetch> falls back to a sequential table scan.

=head2 search_table($table_id, $query, [\%options])

It performs searches matching query terms using the full-text C<.src> index (or a sorted table scan backup method if unindexed). C<search_table> uses the C<AmberDB::Locale> module. It features advanced language normalization according to the selected language (apostrophe stop words, accent normalization, phonetic silencing as in Turkish C<b/d/g -E<gt> p/t/k>, circumflex vowels C<â/î/û>), block filtering, tier mode selection (C<jnktype =E<gt> 'A' | 'AB' | 'B' | 'BA'>), sorting, pagination, and C<keys_only> features.

B<IMPORTANT (Return Signature Convention):>
When C<$limit> is passed and C<E<gt> 0> (paginated), C<search_table> returns C<($total_count, @records)> where the first scalar is the total matching count integer. When C<$limit> is omitted or C<0> (unpaginated), it returns C<@records> directly. Unpacking a paginated query into C<my @records> causes C<$records[0]> to be an integer scalar, which will crash if dereferenced as an array reference.

    # 1. Unpaginated (returns array of record arrayrefs directly)
    my @records        = $adb->search_table("catalog_product", "wireless headphones");
    my @sorted_records = $adb->search_table("catalog_product", "headphones", { sort => -5 });

    # 2. Paginated (first element is total matching count integer)
    my ($total_count, @search) = $adb->search_table("catalog_product", "headphones", { offset => 0, limit => 20 });
    my ($total_count, @search) = $adb->search_table(
        "catalog_product", "headphones",
        {
            offset  => 0,
            limit   => 20,
            sort    => -5,
            type    => "and",
            filter  => { field => 6, value => 12 },
            range   => { block => "price", min => 100, max => 500 },
            jnktype => 'AB',
        }
    );

    # Return only scalar record IDs
    my @all_ids             = $adb->search_table("catalog_product", "headphones", { keys_only => 1 });
    my ($total_count, @ids) = $adb->search_table("catalog_product", "headphones", { offset => 0, limit => 50, keys_only => 1 });

=head2 field_filter($table_id, \%filter_options)

Performs multi-block filtered queries (AND / OR) with support for multi-value filters, tier mode selection (C<jnktype>), numerical/chronological range filtering (C<range>), sorting, and pagination:

    my $res = $adb->field_filter("catalog_product", {
        type    => "and",
        filter  => { 1 => "5", 6 => ["12", "14"] },
        range   => { block => "price", min => 1000, max => 2500 },
        sort    => { blk => 5, reverse => 1 },
        jnktype => "AB",
        offset  => 0,
        limit   => 20,
    });
    # Returns: { count => $total, ids => \@matching_ids }

=head2 exist_id($table_id, $record_id)

Checks if a single record exists in the specified table. Returns 1 if present, 0 otherwise:

    my $exists = $adb->exist_id("catalog_product", 101);

=head2 exist_list($table_id, @record_ids)

Queries the presence of multiple record IDs in a single pass. Returns a hash reference C<{ id =E<gt> 1/0 }>:

    my $map = $adb->exist_list("catalog_product", 101, 102, 103);

=head2 exist_table($table_id, [$ext])

Checks whether the physical database table or index file exists on disk. C<$ext> defaults to C<$self-E<gt>{db_ext}> (C<'db'>):

    my $has_table = $adb->exist_table("catalog_product");
    my $has_index = $adb->exist_table("catalog_product", "inx");

=head2 table_count($table_id)

Returns the total number of records in the specified table. Reads from the primary C<.inx> index if enabled, or scans the main table:

    my $total_records = $adb->table_count("catalog_product");

=head2 table_keys($table_id)

Returns an array of all record IDs present in the table (retrieved from memory cache, C<.inx> index, or sequential table scan):

    my @all_ids = $adb->table_keys("catalog_product");

=head2 table_lastid($table_id)

Returns the highest / auto-increment primary key ID currently allocated in the table:

    my $last_id = $adb->table_lastid("catalog_product");

=head2 table_info($table_id)

Loads and returns the table schema definition (hash reference). Automatically ensures metadata fields:
- C<table>: table identifier (e.g. C<"catalog_product">)
- C<dbase>: database prefix (e.g. C<"catalog">)

    my $tb_info = $adb->table_info("catalog_product");

    print $tb_info->{table}; # "catalog_product"
    print $tb_info->{dbase}; # "catalog"

=head2 table_attr($table_id, [$key_or_attributes])

Reads or dynamically customizes table schema attributes in-memory at runtime without altering schema files on disk:

    # 1. Single attribute getter (scalar)
    my $use_simple = $adb->table_attr("catalog_product", "use_simple");

    # 2. Bulk attribute getter (returns a safe shallow copy)
    my $attrs = $adb->table_attr("catalog_product");

    # 3. Key-value setter (automatically recalculates paths if year/section/lang changes)
    $adb->table_attr("catalog_product", use_simple => 1, keep_deleted => 1);

    # 4. Hashref setter
    $adb->table_attr("catalog_product", { search_block => [ 4, 9 ], use_ramdisk => 0 });

=head2 table_create($table_id)

Creates an empty physical database file (C<.db>) on disk. If a table is accessed with C<table_write> and does not exist, it is created automatically. C<table_create> is useful to prevent file-not-found errors before initial read operations on new tables:

    $adb->table_create("catalog_product");

=head2 table_read($file_path)

Opens a C<DB_File> database file in read-only mode (C<O_RDONLY>). No exclusive lock is applied. C<table_read> and C<table_write> are used for both base data files (C<.db>) and index files (note that internal encodings differ):

    my $db_obj = $adb->table_read("/path/to/table.db");

=head2 table_write($file_path)

Opens a C<DB_File> database file in read-write mode (C<O_RDWR | O_CREAT>) and acquires an exclusive write lock (C<flock LOCK_EX>). Uses the file path as the handle key:

    my $db_obj = $adb->table_write("/path/to/table.db");

=head2 table_close($file_path)

Syncs, unlocks, and closes the specified C<DB_File> handle, releasing its file lock and removing it from the internal connection pool:

    $adb->table_close("/path/to/table.db");

=head2 recs_exist($file_path, @record_ids)

Low-level existence check directly on an open C<DB_File> handle. Returns boolean C<1/0> for a single ID, or a hash reference C<{ id =E<gt> 1/0 }> for multiple IDs:

    my $is_found = $adb->recs_exist($file_path, "101");
    my $id_map   = $adb->recs_exist($file_path, "101", "102");

=head2 recs_keys($file_path)

Extracts all raw keys directly from an open C<DB_File> handle in sequential order using C-level C<seq>:

    my @raw_keys = $adb->recs_keys($file_path);

=head2 recs_scan($file_path, [$mode_or_callback])

Scans key-value pairs sequentially directly from an open C<DB_File> handle using C-level C<seq>. Supports multiple modes:
- C<\&callback>: Invokes C<callback-E<gt>($key, $val)> for each pair.
- C<'keys'>: Returns list/arrayref of all keys.
- C<'value'> / C<'values'>: Returns list/arrayref of all raw values.
- C<'each'> / C<'pairs'>: Returns list/arrayref of C<[$key, $val]> pairs.
- C<'count'>: Returns total number of records.
- C<'hash'> (default): Returns key-value hash (or hashref).

    # Examples
    my @keys   = $adb->recs_scan($file_path, "keys");
    my @values = $adb->recs_scan($file_path, "values");
    my @each   = $adb->recs_scan($file_path, "each");

    # Custom iterator
    $adb->recs_scan($file_path, sub {
        my ($key, $val) = @_;
        print "Key: $key, Val: $val\n";
    });

=head2 recs_get($file_path, @record_ids)

Direct raw record retrieval for specific record IDs from an open C<DB_File> handle. Returns C<{ id =E<gt> raw_val }>:

    my $raw_data = $adb->recs_get($file_path, 101, 102);

=head2 recs_put($file_path, @records)

Writes records in bulk directly to an open C<DB_File> write handle. Each item must be in C<[$rid, @fields]> or C<[$rid, $val]> format:

    $adb->recs_put($file_path, [ 101, "Category", "Brand", "Title" ]);

=head2 recs_del($file_path, @record_ids)

Deletes specified record IDs directly from an open C<DB_File> write handle:

    $adb->recs_del($file_path, 101, 102);

=head2 transact_start()

Starts a new transaction for atomic multi-table operations. Opens a disk-backed undo journal with non-blocking exclusive lock.

    $adb->transact_start();

=head2 transact_rollback()

Forces an immediate manual rollback of the active transaction. Reverts all inserted, modified, or deleted records in reverse LIFO order, unlinks the journal, and atomically releases all Strict 2PL locks. Use this in application code whenever an operational or business rule failure occurs (e.g., insufficient stock, credit limit exceeded):

    if ( $balance < $amount ) {
        $adb->transact_rollback();
        return { error => "Insufficient funds" };
    }

=head2 transact_commit()

Unconditionally commits the active transaction, synchronizes dirty buffers to disk, removes the active rollback journal, and releases all acquired locks.

    $adb->transact_commit();

=head2 transact_end()

Concludes the active transaction with status checking. If all operations completed without error, it commits all changes via C<transact_commit()>, unlinks the journal, releases all locks, and returns C<{ status =E<gt> "commit", ... }>. If any unhandled underlying database error occurred, it performs an automatic LIFO rollback and returns C<{ status =E<gt> "rollback", ... }>.

    my $txn = $adb->transact_end();
    if ($txn->{status} eq 'commit') { ... }

=head2 transact_error([$file_path], [$message])

I<Internal Engine Method.> Records a physical file or write error during database operations. If the target file is a base data table (matching configured C<.$db_ext>) and does not have the C<no_transact> flag, it immediately triggers C<transact_rollback()>. Secondary files (indexes, facets, logs) are logged without triggering a rollback.

=head2 flock_open($table_id, [$mode], [$record_id])

Acquires a record-level (if C<$record_id> specified) or table-level (if C<$record_id> omitted) lock.
C<$mode> can be C<"write"> (exclusive lock, default) or C<"read"> (shared lock).

    # Table-level exclusive lock
    $adb->flock_open("catalog_product", "write");

    # Record-level exclusive lock
    $adb->flock_open("catalog_product", "write", 101);

=head2 flock_close($table_id, [$record_id])

Releases a record-level or table-level lock previously acquired via C<flock_open()>.

    # Release table-level lock
    $adb->flock_close("catalog_product");

    # Release record-level lock
    $adb->flock_close("catalog_product", 101);

=head2 get_cache($group, $key)

Retrieves cached records or data from the in-memory L1 process cache for the specified group and key.

    my $data = $adb->get_cache("catalog_product", 101);

=head2 set_cache($group, $key, [@data | undef])

Writes data to the in-memory L1 process cache, or invalidates the cache entry if data is C<undef>.

    # Set cache entry
    $adb->set_cache("catalog_product", 101, @record_data);

    # Invalidate / clear cache entry
    $adb->set_cache("catalog_product", 101, undef);

=head1 AUTHOR

Maruf Cetin <marufcetin@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2005-2026 Maruf Cetin.

This library is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0.

=cut
