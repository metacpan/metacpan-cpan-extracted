package AmberDB::Tools::Maintain;

use 5.016;
use warnings;
use strict;
use Carp qw(croak cluck);
use File::Spec;

our $VERSION = '5.26.0';
my $CREATED = '2018-10-08';

sub new {

    my $class = shift;
    my $self  = {};

    require AmberDB;

    my ( $adb, %inputs );

    if ( ref( $_[0] ) ) {
        $adb    = shift;
        %inputs = @_;
    }
    else {
        %inputs = @_;
        $adb    = AmberDB->new(%inputs);
    }

    $self->{_adb} = $adb;

    foreach my $in ( keys %inputs ) {
        $self->{ uc($in) } = $inputs{$in};
    }
    $self->{say} = "";

    bless $self, $class;
    return $self;
}

# my $ok = $tools->tie2csv("dbase_table");
# print $self->{say} if($ok);
# ---------------------------------------------------------------------
sub tie2csv {

    my ( $self, $tableid ) = @_;
    my $adb = $self->{_adb} or return;

    $tableid or return;
    my $table_path = $adb->table_path($tableid);

    my $i = 1;
    if ( -e "$table_path.csv" ) {
        my $day_id = $adb->day_id;
        rename( "$table_path.csv", "$table_path-$day_id.csv" );
    }

    # cevirme islemlerini yap
    my $tie_path = "${table_path}.$adb->{db_ext}";
    return 1 unless -e $tie_path;
    $adb->table_read($tie_path) or return 1;

    my @records;
    $adb->recs_scan(
        $tie_path,
        sub {
            my ( $k, $v ) = @_;
            my @fields = $adb->db_decode( $v );
            push @records, [ $k, $adb->tsv_encode( @fields ) ];
            $self->{say} .= "$i. $k ID record converted.\n\n";
            $i++;
        }
    );

    @records = sort { $a->[0] <=> $b->[0] } @records;
    open my $fh, ">", "$table_path.csv" or do {
        cluck "[DB_TOOL] Could not open $table_path.csv: $!\n";
        return;
    };
    foreach my $record ( @records ) {
        print $fh "$record->[0]\t$record->[1]\n";
    }
    close $fh;
    $adb->table_close($tie_path);

    return 1;
}

# $tools->{ISO2UTF} = 1;
# my $ok = $tools->csv2tie("file");
# ---------------------------------------------------------------------
sub csv2tie {

    my ( $self, $tableid ) = @_;
    my $adb = $self->{_adb} or return;

    $tableid or return;

    # file paths
    my $table_path = $adb->table_path($tableid);
    my $file_path  = "${table_path}.$adb->{db_ext}";
    my $csv_path   = "$table_path.csv";
    return unless -e $csv_path;

    # backup with timestamp if exists
    if ( -e "${table_path}.$adb->{db_ext}" ) {
        my $sec_id = $adb->second_id;
        rename( "${table_path}.$adb->{db_ext}",
            "${table_path}-$sec_id.$adb->{db_ext}" );
        unlink("${table_path}.$adb->{db_ext}");
    }

    # perform conversion operations
    my $i = 1;
    my @records;

    open my $FH, "<", $csv_path or do {
        cluck "[DB_TOOL] Could not open $csv_path: $!\n";
        return;
    };
    $adb->table_write($file_path) or do {
        close $FH;
        cluck "[DB_TOOL] Could not open $file_path for writing.\n";
        return;
    };
    my @chunk;
    while ( my $record = <$FH> ) {
        chomp($record);
        $record =~ s/\r$//;
        my (@fields) = $adb->db_decode($record);
        push @chunk, [@fields];
        if ( @chunk >= 2000 ) {
            $adb->recs_put( $file_path, @chunk );
            @chunk = ();
        }

        # collect into list for indexing
        push @records, [@fields];
        $self->{say} .= "$i. Record ID $fields[0] converted.\n\n" if $i % 1000 == 0;
        $i++;
    }
    if ( @chunk ) {
        $adb->recs_put( $file_path, @chunk );
    }
    close $FH;
    $adb->table_close($file_path);

    $self->set_index( $tableid, @records );

    return 1;
}

# my @tables = $tools->dir_tables();
# ------------------------------------------------
sub dir_tables {

    my ( $self, $dir ) = @_;
    my $adb = $self->{_adb} or return;

    $dir or return;
    my $target_dir = File::Spec->catdir( $adb->path('dbase_dir') || ".", $dir );
    my $ext        = $adb->{db_ext} || "db";
    my @names      = $adb->dir_files( $target_dir, "*.$ext", full_path => 0 );

    my %all_tables = map { /^(.+)\.\Q$ext\E$/i ? ( $1 => 1 ) : () } @names;

    return sort { $a cmp $b } keys %all_tables;
}

# my @tables = $tools->vacuum($tableid, 1);
# ------------------------------------------------
sub vacuum {

    my ( $self, $tableid, $reindex ) = @_;
    my $adb = $self->{_adb} or return;

    my $table_path = $adb->table_path($tableid);
    my $tie_path   = "$table_path.$adb->{db_ext}";
    return unless -e $tie_path;

    my $sec_id = $adb->second_id;
    my $pid_name = "$sec_id-$$";
    my $tie_back = "$table_path-$pid_name.$adb->{db_ext}";
    my $csv_path = "$table_path.csv";
    my $csv_back = "$table_path-$pid_name.csv";

    # Backup and reset index structure
    my $table_info = $adb->table_info($tableid);
    $adb->table_attr( $tableid, {} );

    # Fetch records
    my $count   = {};
    my @records = $adb->read_all($tableid);
    $count->{tie1} = scalar @records;
    if ( !$count->{tie1} ) {
        cluck "[DB_TOOL] Cannot vacuum table $tableid as no records were found.\n";
        return;
    }

    -e $csv_path and rename( $csv_path, $csv_back );

    open my $FH, ">", $csv_path or do {
        cluck "[DB_TOOL] Could not create $csv_path. Check file permissions: $!\n";
        return;
    };
    foreach my $record (@records) {
        my $new_record = $adb->tsv_encode(@$record);
        print $FH "$new_record\n";
        $count->{csv1}++;
    }
    close $FH;

    # Reverse operation
    rename( $tie_path, $tie_back );

    open $FH, "<", $csv_path or do {
        cluck "[DB_TOOL] Could not open $csv_path for reading: $!\n";
        return;
    };
    $adb->table_write($tie_path);
    my @chunk;
    while ( my $record = <$FH> ) {
        chomp($record);
        $record =~ s/\r$//;
        my @fields = $adb->db_decode($record);
        push @chunk, [@fields];
        if ( @chunk >= 2000 ) {
            my $ok = $adb->recs_put( $tie_path, @chunk );
            $count->{tie2} += scalar @chunk if $ok;
            @chunk = ();
        }
    }
    if ( @chunk ) {
        my $ok = $adb->recs_put( $tie_path, @chunk );
        $count->{tie2} += scalar @chunk if $ok;
    }
    close $FH;
    $adb->table_close($tie_path);

    $adb->table_attr( $tableid, $table_info );
    $self->set_index( $tableid, @records ) if $reindex;
    $self->{say} .= "Vacuum completed. Record counts: Tie old: $count->{tie1}, CSV: $count->{csv1}, Tie new: $count->{tie2}\n";

    return 1;
}

# my $tables_hash = $tools->all_tables(); # scalar context -> grouped hashref
# my @table_list  = $tools->all_tables(); # list context   -> flat array of table IDs
# ------------------------------------------------
sub all_tables {

    my ($self) = @_;
    my $adb = $self->{_adb} or return;

    my @all_tables;
    my %all_tables;

    my $dbase_dir  = $adb->path('dbase_dir')  || ".";
    my $year_dir   = $adb->path('year_dir')   || "";
    my $schema_dir = $adb->path('schema_dir') || "";

    # 1. Simple Mode: Single flat directory scan for files matching configured db_ext
    if ( $adb->config('simple') ) {
        my $ext = $adb->{db_ext} || "db";
        my @files = $adb->dir_files( $dbase_dir, "*.$ext", full_path => 0 );
        @all_tables = map { /^([a-z0-9_]+)\.\Q$ext\E$/i ? $1 : () } @files;
    }
    # 2. Standard Structured Mode: Multi-directory scan (table/ and year directories) for .db files
    else {
        my $tbl_dir = File::Spec->catdir( $dbase_dir, 'table' );
        push @all_tables, $adb->dir_files( $tbl_dir, "*.db", full_path => 0 ) if -d $tbl_dir;

        my %seen_dirs = ( "table" => 1, "schema" => 1, "backup" => 1, "lock" => 1, "ramdisk" => 1, "journal" => 1, "session" => 1, "config" => 1 );
        if ($year_dir) {
            my $yd_path = File::Spec->catdir( $dbase_dir, $year_dir );
            push @all_tables, $adb->dir_files( $yd_path, "*.db", full_path => 0 );
            $seen_dirs{$year_dir} = 1;
        }

        # Auto-discover any 4-digit year directories under $dbase_dir (e.g. 2024, 2025, 2026)
        if ( -d $dbase_dir ) {
            my @year_dirs = $adb->dir_files( $dbase_dir, qr/^\d{4}$/, full_path => 0, files_only => 0 );
            foreach my $yd (@year_dirs) {
                next if $seen_dirs{$yd} || !-d File::Spec->catdir( $dbase_dir, $yd );
                my $yd_path = File::Spec->catdir( $dbase_dir, $yd );
                push @all_tables, $adb->dir_files( $yd_path, "*.db", full_path => 0 );
            }
        }

        @all_tables = map { /^([a-z0-9_]+)\.db$/i ? $1 : () } @all_tables;
    }

    foreach my $record (@all_tables) {
        next unless $record;
        next if $record =~ /^_/; # skip internal / temp files

        if ( my ( $dbs, $tbl ) = ( $record =~ /^([a-z0-9]+)_(.+)$/i ) ) {
            $all_tables{$dbs}->{$record} = 1;
            if ( $schema_dir && !-e "$schema_dir/$dbs.dbase" ) {
                $all_tables{__NO_DBASE__}->{$dbs} = 1;
            }
            if ( $schema_dir && !-e "$schema_dir/$record.table" ) {
                $all_tables{__NO_TABLE__}->{$record} = 1;
            }
        }
        else {
            # Single-token table name without underscore
            $all_tables{_main}->{$record} = 1;
            if ( $schema_dir && !-e "$schema_dir/$record.table" ) {
                $all_tables{__NO_TABLE__}->{$record} = 1;
            }
        }
    }

    if (wantarray) {
        my @flat_list;
        foreach my $dbs ( sort keys %all_tables ) {
            next if $dbs =~ /^__/;
            push @flat_list, sort keys %{ $all_tables{$dbs} };
        }
        return @flat_list;
    }

    return \%all_tables;
}

# =====================================================================
# TABLE MIGRATION & HISTORICAL FORMAT CONVERSION ENGINE
# =====================================================================


# Helper to binary copy a file safely without external modules
sub _copy_file {
    my ( $self, $src, $dst ) = @_;
    return 0 unless -e $src;
    open my $in, '<:raw', $src or return 0;
    open my $out, '>:raw', $dst or do { close $in; return 0; };
    my $buf;
    while ( read( $in, $buf, 65536 ) ) {
        print $out $buf;
    }
    close $in;
    close $out;
    return 1;
}

# my $table_path = $tools->del_table($tableid);
# ------------------------------------------------
sub del_table {

    my ( $self, $tableid ) = @_;
    my $adb = $self->{_adb} or return;

    $tableid or return;

    $adb->config('no_write') and return;

    my $table_path = $adb->table_path($tableid);
    return unless $table_path && -e "$table_path.$adb->{db_ext}";

    my ($parent_dir, $base_name) = $table_path =~ m{^(.+)[/\\]([^/\\]+)$};
    $parent_dir //= ".";
    $base_name  //= $table_path;

    my @files1 = $adb->dir_files( $parent_dir, qr/^\Q$base_name\E(?:\.[a-z0-9]+|_[0-9]+\.[a-z0-9]+)$/i );

    foreach my $file (@files1) {
        $adb->table_close($file);
        unlink($file);
        $self->{say} .= "          * $file deleted.\n";
    }

    $self->{say} .= "    - Table $tableid deleted.\n";

    return 1;
}


sub dump {
    my ( $self, %opts ) = @_;
    my $adb = $self->{_adb} or return;

    require Archive::Tar;
    require Digest::SHA;
    require JSON::PP;
    require File::Spec;
    require File::Path;

    # 1. Determine target tables
    my @tables;
    if ( $opts{tables} && ref( $opts{tables} ) eq 'ARRAY' ) {
        @tables = @{ $opts{tables} };
    }
    elsif ( $opts{table} ) {
        @tables = ( $opts{table} );
    }
    else {
        @tables = $self->all_tables();
    }
    return unless @tables;

    # 2. Flush and close open table handles for read consistency
    $adb->close_all();

    # 3. Determine output file path
    my $year     = $adb->year;
    my $month    = $adb->month;
    my $day      = $adb->day;
    my $date_iso = "$year-$month-$day";
    my $time_id  = $adb->second_id;

    my $backup_base = $adb->path('backup_dir')
      || ( $adb->path('dbase_dir') ? $adb->path('dbase_dir') . "/backup" : "backup" );
    my $year_dir = "$backup_base/$year";
    $adb->make_path($year_dir);

    my $outfile = $opts{file} || "$year_dir/amberdb_${date_iso}_${time_id}.amberdb";

    # Ensure parent directory for $outfile exists
    if ( my ($outdir) = $outfile =~ m{^(.*)[/\\]} ) {
        $adb->make_path($outdir);
    }

    my $tar = Archive::Tar->new();

    my $manifest = {
        format          => "AmberDB Archive",
        format_version  => 1,
        amberdb_version => $AmberDB::VERSION || $VERSION,
        created_at      => "$date_iso " . sprintf( "%02d:%02d:%02d", (localtime)[2], (localtime)[1], (localtime)[0] ),
        dbase_dir       => $adb->path('dbase_dir'),
        tables          => {},
    };

    my $schema_dir = $adb->path('schema_dir')
      || ( $adb->path('dbase_dir') ? $adb->path('dbase_dir') . "/schema" : "schema" );

    # Collect .dbase database group schemas
    if ( -d $schema_dir ) {
        opendir( my $sdh, $schema_dir );
        my @dbase_files = grep { /\.dbase$/i } readdir($sdh);
        closedir $sdh;

        foreach my $df (@dbase_files) {
            my ($dbs) = $df =~ /^([^.]+)\.dbase$/i;
            next unless $dbs;

            # If dumping specific tables, only include matching dbase prefix
            if ( $opts{tables} || $opts{table} ) {
                my $matched = 0;
                foreach my $tid (@tables) {
                    if ( $tid =~ /^\Q$dbs\E_/ or $tid eq $dbs ) {
                        $matched = 1;
                        last;
                    }
                }
                next unless $matched;
            }

            my $dpath = "$schema_dir/$df";
            if ( -e $dpath ) {
                open my $dfh, "<:raw", $dpath or next;
                local $/ = undef;
                my $dcontent = <$dfh>;
                close $dfh;
                $tar->add_data( "schema/$df", $dcontent );
                $manifest->{dbases}->{$dbs} = "schema/$df";
            }
        }
    }

    foreach my $tid (@tables) {
        my $tpath = $adb->table_path($tid);
        my $db_file = "$tpath." . ( $adb->{db_ext} || "db" );
        next unless -e $db_file;

        my $table_manifest = {
            records => 0,
            files   => [],
            sha256  => {},
        };

        # A. Collect Schema file if exists
        my $schema_file = "$schema_dir/$tid.table";
        if ( -e $schema_file ) {
            open my $sfh, "<:raw", $schema_file or next;
            local $/ = undef;
            my $schema_content = <$sfh>;
            close $sfh;
            $tar->add_data( "schema/$tid.table", $schema_content );
            $table_manifest->{schema} = "schema/$tid.table";
        }

        # B. Count records from .db table safely
        my $count = scalar( $adb->table_keys($tid) ) || 0;
        $table_manifest->{records} = $count;

        # C. Collect data files (.db, .del, .aut, .cnt)
        # Suffixes that represent data, NOT derived indexes
        my @suffixes = ( ( $adb->{db_ext} || "db" ), "del", "aut", "cnt" );
        my $base_dir = $adb->path('dbase_dir') || ".";
        $base_dir =~ s{\\}{/}g;
        $base_dir =~ s{/$}{};

        foreach my $sfx (@suffixes) {
            my $fpath = "$tpath.$sfx";
            if ( -e $fpath ) {
                open my $dfh, "<:raw", $fpath or next;
                local $/ = undef;
                my $dcontent = <$dfh>;
                close $dfh;

                my $norm_fpath = $fpath;
                $norm_fpath =~ s{\\}{/}g;
                my $arch_path = $norm_fpath;
                if ( $norm_fpath =~ m{^\Q$base_dir\E/(.+)$} ) {
                    $arch_path = $1;
                }
                else {
                    $arch_path = "table/$tid.$sfx";
                }

                $tar->add_data( $arch_path, $dcontent );
                push @{ $table_manifest->{files} }, $arch_path;

                my $sha256 = Digest::SHA::sha256_hex($dcontent);
                $table_manifest->{sha256}->{$arch_path} = $sha256;
            }
        }

        # D. Collect Authoritative String Dictionary (.unq)
        my @unq_files = -e "${tpath}.unq" ? ("${tpath}.unq") : ();
        foreach my $fpath (@unq_files) {
            next unless -e $fpath;
            open my $dfh, "<:raw", $fpath or next;
            local $/ = undef;
            my $dcontent = <$dfh>;
            close $dfh;

            my $norm_fpath = $fpath;
            $norm_fpath =~ s{\\}{/}g;
            my $arch_path = $norm_fpath;
            if ( $norm_fpath =~ m{^\Q$base_dir\E/(.+)$} ) {
                $arch_path = $1;
            }
            else {
                my ($fname) = $fpath =~ m{([^/\\]+)$};
                $arch_path = "table/$fname";
            }

            $tar->add_data( $arch_path, $dcontent );
            push @{ $table_manifest->{files} }, $arch_path;

            my $sha256 = Digest::SHA::sha256_hex($dcontent);
            $table_manifest->{sha256}->{$arch_path} = $sha256;
        }

        $manifest->{tables}->{$tid} = $table_manifest;
    }

    # Add manifest.json to archive
    my $json = JSON::PP->new->utf8->pretty->encode($manifest);
    $tar->add_data( "manifest.json", $json );

    # Write tar.gz archive
    unless ( $tar->write( $outfile, Archive::Tar::COMPRESS_GZIP() ) ) {
        cluck "[DB_BACKUP] Failed to write archive $outfile: " . $tar->error() . "\n";
        return;
    }

    $self->{say} .= "Archive successfully written to $outfile (" . ( -s $outfile ) . " bytes)\n";
    return wantarray ? ( $outfile, $manifest ) : $outfile;
}

# Restores a .amberdb archive into target database, validates checksums,
# and deterministically rebuilds all binary indexes via set_index.
# my $res = $tools->restore( file => 'backup.amberdb', [force => 1], [reindex => 1] );
# ---------------------------------------------------------------------
sub restore {
    my ( $self, %opts ) = @_;
    my $adb = $self->{_adb} or return;

    my $file = $opts{file} or do {
        cluck "[DB_RESTORE] Missing required parameter 'file'.\n";
        return;
    };
    return unless -e $file;

    require Archive::Tar;
    require Digest::SHA;
    require JSON::PP;
    require File::Spec;
    require File::Path;

    my $tar = Archive::Tar->new();
    unless ( $tar->read($file) ) {
        cluck "[DB_RESTORE] Cannot read archive $file: " . $tar->error() . "\n";
        return;
    }

    # 1. Read and parse manifest.json
    my $manifest_content = $tar->get_content("manifest.json");
    unless ($manifest_content) {
        cluck "[DB_RESTORE] Archive $file is missing manifest.json.\n";
        return;
    }

    my $manifest = eval { JSON::PP->new->utf8->decode($manifest_content) };
    if ( $@ || ref($manifest) ne 'HASH' ) {
        cluck "[DB_RESTORE] Corrupted manifest.json in $file: $@\n";
        return;
    }

    # 2. Check if target DB is empty or force is set
    my $schema_dir = $adb->path('schema_dir')
      || ( $adb->path('dbase_dir') ? $adb->path('dbase_dir') . "/schema" : "schema" );
    my $table_dir = $adb->path('table_dir')
      || ( $adb->path('dbase_dir') ? $adb->path('dbase_dir') . "/table" : "table" );

    my $force = $opts{force} || $opts{overwrite};
    unless ($force) {
        # Check if existing schema or data files exist.
        # NOTE: Avoid calling table_path() here because it triggers
        # table_info() -> dbase_info() which caches empty hashes for
        # schemas that don't exist yet on the target, poisoning the
        # cache for the rest of the restore operation.
        my $has_existing = 0;
        my $db_ext = $adb->{db_ext} || "db";
        foreach my $tid ( keys %{ $manifest->{tables} || {} } ) {
            if ( -e "$table_dir/$tid.$db_ext" || -e "$schema_dir/$tid.table" ) {
                $has_existing = 1;
                last;
            }
        }
        if ($has_existing) {
            cluck "[DB_RESTORE] Target database is not empty. Use 'force => 1' to overwrite existing tables.\n";
            return;
        }
    }

    # Ensure target directories exist
    $adb->make_path($schema_dir);
    $adb->make_path($table_dir);

    # Flush all active handles before restoring
    $adb->close_all();

    my @restored_tables;
    my %table_filter = $opts{tables} ? map { $_ => 1 } @{ $opts{tables} } : ();

    # 3. Extract .dbase database group schemas
    if ( ref( $manifest->{dbases} ) eq 'HASH' ) {
        foreach my $dbs ( sort keys %{ $manifest->{dbases} } ) {
            my $arch_path = $manifest->{dbases}->{$dbs};
            my $scontent = $tar->get_content($arch_path);
            if ( defined $scontent ) {
                my $target_dbase = "$schema_dir/$dbs.dbase";
                open my $dfh, ">:raw", $target_dbase or do {
                    cluck "[DB_RESTORE] Cannot write dbase schema $target_dbase: $!\n";
                    return;
                };
                print $dfh $scontent;
                close $dfh;
            }
        }
    }

    # 4. Extract table schemas and data files
    my $base_dir = $adb->path('dbase_dir') || ".";
    $base_dir =~ s{\\}{/}g;
    $base_dir =~ s{/$}{};

    foreach my $tid ( sort keys %{ $manifest->{tables} || {} } ) {
        next if ( %table_filter && !$table_filter{$tid} );

        my $tinfo = $manifest->{tables}->{$tid};

        # A. Restore Schema
        if ( $tinfo->{schema} ) {
            my $scontent = $tar->get_content( $tinfo->{schema} );
            if ( defined $scontent ) {
                my $target_schema = "$schema_dir/$tid.table";
                open my $sfh, ">:raw", $target_schema or do {
                    cluck "[DB_RESTORE] Cannot write schema $target_schema: $!\n";
                    return;
                };
                print $sfh $scontent;
                close $sfh;
            }
        }

        # B. Restore Data Files (.db, .del, .aut, .cnt)
        my $tpath = $adb->table_path($tid);

        foreach my $arch_path ( @{ $tinfo->{files} || [] } ) {
            my $dcontent = $tar->get_content($arch_path);
            next unless defined $dcontent;

            # Verify checksum if present
            if ( my $expected_sha = $tinfo->{sha256}->{$arch_path} ) {
                my $actual_sha = Digest::SHA::sha256_hex($dcontent);
                if ( $expected_sha ne $actual_sha ) {
                    cluck "[DB_RESTORE] Checksum mismatch for $arch_path! Expected $expected_sha, got $actual_sha.\n";
                    return;
                }
            }

            # Native archive path: e.g. table/products.db or 2026/sales.db
            my $target_file = "$base_dir/$arch_path";

            if ( my ($tdir) = $target_file =~ m{^(.*)[/\\]} ) {
                $adb->make_path($tdir);
            }

            open my $dfh, ">:raw", $target_file or do {
                cluck "[DB_RESTORE] Cannot write data file $target_file: $!\n";
                return;
            };
            print $dfh $dcontent;
            close $dfh;
        }

        push @restored_tables, $tid;
    }

    # 5. Rebuild all indexes if reindex is requested (default: 1)
    my $reindex = defined $opts{reindex} ? $opts{reindex} : 1;
    if ($reindex) {
        foreach my $tid (@restored_tables) {
            do { my $idx = $self->can('set_index') ? $self : do { require AmberDB::Tools::Index; AmberDB::Tools::Index->new($adb); }; $idx->set_index($tid); };
        }
    }

    $self->{say} .= "Restored " . scalar(@restored_tables) . " tables from $file.\n";

    return {
        ok             => 1,
        file           => $file,
        tables         => \@restored_tables,
        manifest       => $manifest,
        reindexed      => $reindex ? 1 : 0,
    };
}


1;
