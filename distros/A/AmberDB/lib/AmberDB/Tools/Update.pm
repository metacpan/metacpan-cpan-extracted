package AmberDB::Tools::Update;

use 5.016;
use warnings;
use strict;
use Carp qw(croak cluck);
use File::Spec;
use File::Path qw(make_path);
use File::Copy qw(move);
use Cwd qw(abs_path getcwd);
use version;

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

# ---------------------------------------------------------------------
# update_table($tableid, %options)
# Scans an entire table record-by-record, detects any legacy formats (2003-2026),
# creates a timestamped backup with detected dominant version, and rewrites the table
# directly in ABR v1 format preserving original IDs.
# Rebuilds indexes using ($self->can('set_index') ? $self : do { require AmberDB::Tools::Index; AmberDB::Tools::Index->new($adb); })->set_index($tableid).
# Preserves companion data files ('del', 'aut').
# ---------------------------------------------------------------------
sub update_table {
    my ( $self, $tableid, %opts ) = @_;
    my $adb = $self->{_adb} or return;
    $tableid or return;

    my $table_path = $adb->table_path($tableid);
    my $ext        = $adb->{db_ext} || "db";
    my $file_path  = "$table_path.$ext";

    # Use exist_table to verify primary table existence
    return { status => 'not_found', table => $tableid }
      unless $adb->exist_table( $tableid );

    # Format modification timestamp: YYYY-MMDD
    my @mtime_parts = localtime( ( stat($file_path) )[9] || time() );
    my $mtime_str   = sprintf( "%04d-%02d%02d", $mtime_parts[5] + 1900, $mtime_parts[4] + 1, $mtime_parts[3] );

    # 1. Once mevcut tablodaki kayitlari tara
    my %format_counts;
    my $total                 = 0;
    my $already_current = 0;
    my $legacy_count    = 0;
    my @decoded_records;
    my $recovered_from_backup = 0;

    $adb->recs_scan( $file_path, sub {
        my ( $k, $v ) = @_;
        $total++;
        my $fmt = $adb->detect_tsv_format($v);
        $format_counts{$fmt}++;

        my @fields;
        if ( $fmt eq 'v5' ) {
            @fields = $adb->db_decode($v);
            $already_current++;
        }
        else {
            @fields = $adb->tsv_decode( $v, $k );
            $legacy_count++;
        }
        push @decoded_records, [ $k, @fields ];
        } );
    $adb->table_close($file_path);

    # Eger aktif dosya bos ise (ornegin onceki basarisiz bir calismada yedeklenip bos kalmissa):
    # Dizin icindeki yedek dosyasini bulup kayitlari oradan kurtar
    my $backup_file;
    if ( $total == 0 ) {
        my ( $pdir ) = $file_path =~ m{^(.*)[/\\]};
        $pdir //= ".";
        my @cand_backups;
        if ( opendir( my $dh, $pdir ) ) {
            while ( my $f = readdir($dh) ) {
                next if $f eq '.' || $f eq '..';
                if ( $f =~ /^\Q$tableid\E-.*?\.\Q$ext\E$/i ) {
                    push @cand_backups, "$pdir/$f";
                }
            }
            closedir($dh);
        }
        @cand_backups = sort { ( -s $b ) <=> ( -s $a ) } @cand_backups;
        for my $cb (@cand_backups) {
            next unless -e $cb && -s $cb;
            my @b_records;
            my %b_counts;
            my $b_legacy = 0;
            $adb->recs_scan( $cb, sub {
            my ( $k, $v ) = @_;
                my $fmt = $adb->detect_tsv_format($v);
                $b_counts{$fmt}++;
                my @fields = ( $fmt eq 'v5' ) ? $adb->db_decode($v) : $adb->tsv_decode( $v, $k );
                $b_legacy++ if $fmt ne 'v5';
                push @b_records, [ $k, @fields ];
        } );
            $adb->table_close($cb);
            if (@b_records) {
                @decoded_records       = @b_records;
                %format_counts         = %b_counts;
                $total                 = scalar @b_records;
                $legacy_count          = $b_legacy;
                $already_current       = $total - $b_legacy;
                $recovered_from_backup = 1;
                $backup_file           = $cb;
                last;
            }
        }
    }

    # 2. Eslikci veri dosyalarini ('del', 'aut') tara ve formatlarini tespit et
    my %companion_info;
    my $companion_legacy_total = 0;
    for my $cext (qw(del aut)) {
        next unless $adb->exist_table( $tableid, $cext );
        my $cfile = "$table_path.$cext";
        my $c_total   = 0;
        my $c_legacy  = 0;
        my $c_current = 0;
        my @c_decoded;

        $adb->recs_scan( $cfile, sub {
            my ( $ck, $cv ) = @_;
            $c_total++;
            my $cfmt = $adb->detect_tsv_format($cv);
            if ( $cfmt eq 'v5' ) {
                $c_current++;
                push @c_decoded, [ $ck, $adb->db_decode($cv) ];
            }
            else {
                $c_legacy++;
                push @c_decoded, [ $ck, $adb->tsv_decode( $cv, $ck ) ];
            }
        } );
        $adb->table_close($cfile);

        $companion_legacy_total += $c_legacy;
        $companion_info{$cext} = {
            exists  => 1,
            file    => $cfile,
            total   => $c_total,
            legacy  => $c_legacy,
            current => $c_current,
            decoded => \@c_decoded,
        };
    }

    # Eksik indeks dosyalarini kontrol et
    my $table_info = $adb->table_info($tableid);
    my $missing_indexes = 0;
    if ($table_info) {
        if ( $table_info->{record_index} && !-e "$table_path.inx" ) {
            $missing_indexes = 1;
        }
        if ( $table_info->{match_block} && !-e "$table_path.fld" ) {
            $missing_indexes = 1;
        }
        if ( $table_info->{use_facet} && !-e "$table_path.fac" ) {
            $missing_indexes = 1;
        }
    }

    # Eger ana tablo ve tum eslikci dosyalar zaten guncelse, eksik indeks yoksa ve force istenmemisse
    if ( $legacy_count == 0 && $companion_legacy_total == 0 && !$opts{force} && !$recovered_from_backup && !$missing_indexes ) {
        $self->{say} .= "Table '$tableid' is already up to date in ABR v1 format ($already_current records).\n";
        my $res = {
            status          => 'already_current',
            table           => $tableid,
            total           => $total,
            updated         => 0,
            already_current => $already_current,
        };
        for my $cext (qw(del aut)) {
            if ( my $ci = $companion_info{$cext} ) {
                $res->{"${cext}_status"} = ( $ci->{total} == 0 )
                  ? "0 records (empty)"
                  : "already ABR v1 ($ci->{total} records)";
            }
        }
        return $res;
    }

    # 3. En baskin eski formati tespit et
    my $dom_ver = 'v4';
    my $max_c   = -1;
    for my $v (qw(v4 v3 v2 v1)) {
        if ( ( $format_counts{$v} // 0 ) > $max_c ) {
            $max_c   = $format_counts{$v} // 0;
            $dom_ver = $v;
        }
    }

    # 4. Ana tablo donusumu (gerekliyse veya force ise)
    if ( $legacy_count > 0 || $recovered_from_backup || $opts{force} ) {
        # Eger yedekten kurtarilmadiysa, aktif dosyayi nihai yedek adiyla yedekle
        if ( !$recovered_from_backup ) {
    my $backup_base = "$table_path-$dom_ver-$mtime_str";
            $backup_file = "$backup_base.$ext";
    my $counter     = 1;
    while ( -e $backup_file ) {
        $backup_file = "$backup_base-$counter.$ext";
        $counter++;
    }
    rename( $file_path, $backup_file ) or do {
        cluck "[DB_TOOL] Could not backup $file_path to $backup_file: $!\n";
        return { status => 'error', table => $tableid, error => "Backup failed: $!" };
    };
        }

        # Yeni dosyayi sifir temiz yazma modunda ac
        $adb->table_close($file_path);
        $adb->clear_cache($tableid);
        my $new_db = $adb->table_write($file_path);
        unless ($new_db) {
            return { status => 'error', table => $tableid, error => "Could not open $file_path for writing" };
        }

        # Kayitlari yeni ikili ABR v1 formatinda tek tek yaz
        $self->{say} .= "  - Writing $total records in ABR v1 format...\n";
        for my $rec (@decoded_records) {
            my ( $k, @fields ) = @$rec;
            my $v_new   = $adb->db_encode(@fields);
            my $k_enc   = $adb->utf_encode("$k");
            my $val_enc = $adb->utf_encode("$v_new");
            $new_db->put( $k_enc, $val_enc );
        }
        $adb->table_close($file_path);

        # Eski turetilen indeks dosyalarini temizle
    for my $iext (qw(inx src fld fac slg)) {
        my $idx_f = "$table_path.$iext";
        unlink $idx_f if -e $idx_f;
    }
    $adb->clear_cache($tableid);
    }
    else {
        $backup_file //= "None (already ABR v1)";
        $self->{say} .= "  - Main table is already in ABR v1 format ($already_current records).\n";
    }

    # 5. Eslikci veri dosyalarini ('del', 'aut') donustur (indeks insasindan once calisir)
    my %companion_stats;
    for my $cext (qw(del aut)) {
        my $ci = $companion_info{$cext};
        next unless $ci;
        my $cfile = $ci->{file};

        if ( $ci->{legacy} > 0 || $opts{force} ) {
            if ( $ci->{total} > 0 ) {
                $self->{say} .= "  - Migrating companion file ($cext: $ci->{total} records)...\n";
        my $c_backup_base = "$table_path-$dom_ver-$mtime_str.$cext";
        my $c_backup = $c_backup_base;
        my $cnt = 1;
        while ( -e $c_backup ) {
            $c_backup = "$table_path-$dom_ver-$mtime_str-$cnt.$cext";
            $cnt++;
        }
        rename( $cfile, $c_backup ) or next;

        my $new_cdb = $adb->table_write($cfile);
        if ($new_cdb) {
                    for my $crec ( @{ $ci->{decoded} } ) {
                my ( $ck, @cfields ) = @$crec;
                my $cv_new = $adb->db_encode(@cfields);
                $new_cdb->put( $adb->utf_encode("$ck"), $adb->utf_encode("$cv_new") );
            }
            $adb->table_close($cfile);
                    $companion_stats{"${cext}_migrated"} = $ci->{total};
            $companion_stats{"${cext}_backup"}   = $c_backup;
    }
    else {
            rename( $c_backup, $cfile );
    }
    }
            else {
                $companion_stats{"${cext}_status"} = "0 records (empty)";
            }
        }
        else {
            $companion_stats{"${cext}_status"} = "already ABR v1 ($ci->{total} records)";
        }
    }

    # 6. Indeksleri insa et (gerekliyse veya eksikse)
    my $is_simple = $adb->config('simple') || ( $table_info && $table_info->{use_simple} ) || ( $table_info && $table_info->{id_type} && $table_info->{id_type} eq 'ascii' );
    if ( $is_simple ) {
        $self->{say} .= "  - Table '$tableid' is in simple mode, skipping index generation.\n";
    }
    elsif ( $legacy_count > 0 || $recovered_from_backup || $opts{force} ) {
        $self->{say} .= "  - Rebuilding indexes...\n";
        eval {
            ($self->can('set_index') ? $self : do { require AmberDB::Tools::Index; AmberDB::Tools::Index->new($adb); })->set_index( $tableid, @decoded_records );
            1;
        } or do {
            warn "  [ERROR in set_index]: $@\n";
        };
    }
    elsif ($missing_indexes) {
        $self->{say} .= "  - Rebuilding missing indexes...\n";
        eval {
            ($self->can('set_index') ? $self : do { require AmberDB::Tools::Index; AmberDB::Tools::Index->new($adb); })->set_index( $tableid, @decoded_records );
            1;
        } or do {
            warn "  [ERROR in set_index]: $@\n";
        };
    }

    # 7. Eslikci sozluk ve sayac (.unq, .cnt) dosyalarini koru ve yedekle
    my $has_unq = $adb->exist_table($tableid, 'unq');
    my $unq_backup;
    if ($has_unq) {
        my $unq_file = "$table_path.unq";
        my $u_backup_base = "$table_path-$dom_ver-$mtime_str.unq";
        $unq_backup = $u_backup_base;
        my $cnt = 1;
        while ( -e $unq_backup ) {
            $unq_backup = "$table_path-$dom_ver-$mtime_str-$cnt.unq";
            $cnt++;
        }
        require File::Copy;
        File::Copy::copy( $unq_file, $unq_backup );
    }

    my $has_cnt = $adb->exist_table($tableid, 'cnt');
    my $cnt_backup;
    if ($has_cnt) {
        my $cnt_file = "$table_path.cnt";
        my $c_backup_base = "$table_path-$dom_ver-$mtime_str.cnt";
        $cnt_backup = $c_backup_base;
        my $cnt = 1;
        while ( -e $cnt_backup ) {
            $cnt_backup = "$table_path-$dom_ver-$mtime_str-$cnt.cnt";
            $cnt++;
        }
        require File::Copy;
        File::Copy::copy( $cnt_file, $cnt_backup );
    }

    $self->{say} .= "Table '$tableid' updated to ABR v1: $total records migrated ($legacy_count converted, backup: $backup_file).\n";

    return {
        status          => ( ( $legacy_count > 0 || $companion_legacy_total > 0 || $recovered_from_backup || $opts{force} ) ? 'updated' : 'already_current' ),
        table           => $tableid,
        total           => $total,
        updated         => $legacy_count,
        already_current => $already_current,
        dominant_format => $dom_ver,
        backup_file     => $backup_file,
        del_migrated    => $companion_stats{del_migrated} // 0,
        del_backup      => $companion_stats{del_backup},
        del_status      => $companion_stats{del_status},
        aut_migrated    => $companion_stats{aut_migrated} // 0,
        aut_backup      => $companion_stats{aut_backup},
        aut_status      => $companion_stats{aut_status},
        has_unq         => $has_unq ? 1 : undef,
        unq_backup      => $unq_backup,
        has_cnt         => $has_cnt ? 1 : undef,
        cnt_backup      => $cnt_backup,
    };
}

# ---------------------------------------------------------------------
# update_all(%options)
# Iterates through all discovered tables and runs update_table on each.
# ---------------------------------------------------------------------
sub update_all {
    my ( $self, %opts ) = @_;
    my $adb = $self->{_adb} or return;

    my @tables = ($self->can('all_tables') ? $self->all_tables() : do { require AmberDB::Tools::Maintain; AmberDB::Tools::Maintain->new($self->{_adb})->all_tables(); });
    my @results;

    foreach my $table (@tables) {
        my $res = $self->update_table( $table, %opts );
        push @results, $res if $res;
    }

    return wantarray ? @results : \@results;
}

# my $status = dbase_tableold
# ------------------------------------------------
sub replace_tablename {

    my ( $self, $find, $replace ) = @_;
    my $adb = $self->{_adb} or return;

    my @tables;
    my $dbase_dir = $adb->path('dbase_dir') || ".";
    my $year_dir  = $adb->path('year_dir') || "";

    if ( $adb->config('simple') ) {
        @tables = glob "$dbase_dir/$find.*";
        push @tables, ( glob "$dbase_dir/${find}_*" );
    }
    else {
        @tables = glob "$dbase_dir/table/$find.*";
        push @tables, ( glob "$dbase_dir/table/${find}_*" );
        if ( $adb->config('use_section') ) {
            my @sections = glob "$dbase_dir/section_*";
            foreach my $sec_file (@sections) {
                push @tables, ( glob "$sec_file/$find.*" );
                push @tables, ( glob "$sec_file/${find}_*" );
            }
        }

        if ( $adb->config('use_year') && $year_dir ) {
            @tables = glob "$dbase_dir/$year_dir/$find.*";
            push @tables, ( glob "$dbase_dir/$year_dir/${find}_*" );
            if ( $adb->config('use_section') ) {
                my @sections = glob "$dbase_dir/$year_dir/section_*";
                foreach my $sec_file (@sections) {
                    push @tables, ( glob "$sec_file/${find}.*" );
                    push @tables, ( glob "$sec_file/${find}_*" );
                }
            }
        }
    }

    foreach my $old_file (@tables) {
        my $new_file = "$old_file";
        $new_file =~ s/\/$find([\.\_])/$replace$1/;
        rename( $old_file, $new_file );
    }
    $self->{say} .= "    - database table $find renamed to $replace.\n";

    return 1;
}

# my %files = (
# "dbase_table1" => 0,
# "dbase_table2" => 2,
# "dbase_table3" => { BLOCK => 1, START => 2, STARTBLOCK => 3 },
# );
# my %replace = (
# "fields1" => "new_fields1",
# "fields2" => "new_fields2",
# );
# my $status = $tools->replace_blockdata(\%files, \%replace);
# ------------------------------------------------
sub replace_blockdata {

    my ( $self, $files, $replace ) = @_;
    my $adb = $self->{_adb} or return {};

    my $status = {};
    ref($files) eq "HASH"   or return $status;
    ref($replace) eq "HASH" or return $status;

    while ( my ( $file, $block ) = each %{$files} ) {
        my @datas = $adb->read_all($file);
        foreach my $record (@datas) {
            my $change = 0;
            if ( $block =~ /^[0-9]+$/ ) {
                if ( exists( $replace->{ $record->[$block] } ) ) {
                    $record->[$block] = $replace->{ $record->[$block] };
                    $change = 1;
                }
            }
            elsif ( ref($block) eq "HASH" ) {
                if ( $block->{BLOCK} ) {
                    my $b = $block->{BLOCK};
                    if ( exists( $replace->{ $record->[$b] } ) ) {
                        $record->[$b] = $replace->{ $record->[$b] };
                        $change = 1;
                    }
                }

                if ( $block->{START} && $block->{STARTBLOCK} ) {
                    my $s = $block->{START};
                    my $b = $block->{STARTBLOCK};
                    foreach my $line ( @{$record}[ $s .. $#$record ] ) {
                        if ( exists( $replace->{ $line->[$b] } ) ) {
                            $line->[$b] = $replace->{ $line->[$b] };
                            $change = 1;
                        }
                    }
                }
            }
            if ($change) {
                $adb->modify_id( $file, @$record );
                $status->{$file}->{ $record->[0] } = 1;
                $self->{say} .= "          * $file: $record->[0] ID updated.\n";
            }
        }
    }

    return $status;
}

# my $table_path = $tools->del_table($tableid);
# ------------------------------------------------

sub db_simple {

    my ( $self, $dir, $ext ) = @_;

    $ext //= "db";
    require AmberDB;
    my $db_obje = AmberDB->new(
        ext  => { db        => $ext },
        path => { dbase_dir => $dir },
        cfg  => {
            simple  => 1,
        }
    );
    return $db_obje;
}

# Rebuilds and converts binary indexes for all tables in database directory.
# my $status = $tools->convert_tables();
# ------------------------------------------------
sub convert_tables {
    my ($self) = @_;
    my $adb = $self->{_adb} or return;

    my $db_dir = $adb->path('dbase_dir');
    return unless $db_dir && -d $db_dir;

    my @dirs = ($db_dir);
    push @dirs, File::Spec->catdir( $db_dir, 'table' ) if -d File::Spec->catdir( $db_dir, 'table' );

    my @db_files;
    foreach my $d (@dirs) {
        if ( opendir my $dh, $d ) {
            push @db_files, map { File::Spec->catfile( $d, $_ ) }
                            grep { /\.\Q$adb->{db_ext}\E$/ }
                            readdir($dh);
            closedir $dh;
        }
    }
    my %converted;

    foreach my $file (@db_files) {
        my ($tableid) = $file =~ /([^\\\/]+)\.\w+$/;
        next unless $tableid;
        next if $tableid =~ /^\_/;

        $self->{say} .= "Processing table $tableid...\n";
        my $ok = ($self->can('set_index') ? $self : do { require AmberDB::Tools::Index; AmberDB::Tools::Index->new($adb); })->set_index($tableid);
        if ($ok) {
            $converted{$tableid} = 1;
            $self->{say} .= "  -> Rebuilt packed binary indexes (.inx, .fld, .src) for $tableid\n";
        }
    }

    return \%converted;
}

# Creates a compressed, portable .amberdb archive containing table schemas,
# native data files (.db, .del, .aut, .cnt), and integrity manifest.
# my $archive = $tools->dump( [file => 'backup.amberdb'], [tables => ['t1', 't2']] );
# ---------------------------------------------------------------------


# ---------------------------------------------------------------------
# update_version(%opts)
# Checks MetaCPAN API for latest AmberDB release and optionally installs via cpanm.
# ---------------------------------------------------------------------
sub update_version {
    my ( $self, %opts ) = @_;
    my $opt_check = $opts{check} // 0;
    my $opt_cpanm = $opts{cpanm} // '';

    print "=================================================================\n";
    print " AmberDB Core Engine Update Utility                              \n";
    print "=================================================================\n";
    print "Current Engine Version   : v$AmberDB::VERSION\n";

    my $api_url = "https://fastapi.metacpan.org/v1/release/AmberDB";
    my $json_text;

    require HTTP::Tiny;
    require JSON::PP;
    require version;

    my $http = HTTP::Tiny->new( timeout => 5, verify_SSL => 1 );
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
        my $data = eval { JSON::PP::decode_json($json_text) };
        $latest_version = $data->{version} if $data && ref($data) eq 'HASH';
    }

    if ( !defined $latest_version || $latest_version eq '' ) {
        print "[WARNING] Could not retrieve release information from MetaCPAN (offline or API unavailable).\n";
        print "You can manually verify or install via: cpanm AmberDB\n";
        print "=================================================================\n";
        return { status => 'warning', message => 'Could not retrieve release info from MetaCPAN' };
    }

    print "Latest MetaCPAN Version: $latest_version\n";
    print "-----------------------------------------------------------------\n";

    my $v_curr = eval { version->parse($AmberDB::VERSION) };
    my $v_late = eval { version->parse($latest_version) };

    if ( $v_curr && $v_late && $v_curr >= $v_late ) {
        print "[OK] AmberDB engine is up to date (v$AmberDB::VERSION).\n";
        print "=================================================================\n";
        return { status => 'up_to_date', version => $AmberDB::VERSION, latest => $latest_version };
    }

    print "[UPDATE AVAILABLE] AmberDB can be updated from v$AmberDB::VERSION to v$latest_version.\n";

    if ( $opt_check ) {
        print "[CHECK MODE] Skipping package installation.\n";
        print "=================================================================\n";
        return { status => 'update_available', current => $AmberDB::VERSION, latest => $latest_version, check_mode => 1 };
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
            print "=================================================================\n";
            return { status => 'updated', version => $latest_version };
        }
        else {
            print "[WARNING] Installer exited with status $exit_code. You can run '$cpanm_cmd AmberDB' manually.\n";
            print "=================================================================\n";
            return { status => 'error', exit_code => $exit_code };
        }
    }
    else {
        print "[INFO] Neither 'cpanm' nor 'cpan' executable was detected in PATH.\n";
        print "Please run the following command to update AmberDB:\n";
        print "  cpanm AmberDB\n";
        print "=================================================================\n";
        return { status => 'manual_required', latest => $latest_version };
    }
}

# ---------------------------------------------------------------------
# update_storage(%opts)
# Migrates storage directory layout (scheme->schema, tables->table),
# upgrades table record formats to native ABR v5, rebuilds secondary indexes,
# and stamps config/storage_version.json.
# ---------------------------------------------------------------------
sub update_storage {
    my ( $self, %opts ) = @_;
    my $adb = $self->{_adb};

    my $target_dir = $opts{target_dir}
      || ( $adb ? $adb->path('dbase_dir') : undef )
      || $opts{dbase_dir}
      || $opts{dbase};

    if ( !defined $target_dir || $target_dir eq '' ) {
        my $cwd = eval { Cwd::abs_path(Cwd::getcwd()) } // '.';
        if ( -d File::Spec->catdir( $cwd, "dbstore" ) ) {
            $target_dir = File::Spec->catdir( $cwd, "dbstore" );
        }
        elsif ( -d File::Spec->catdir( $cwd, "dbase" ) ) {
            $target_dir = File::Spec->catdir( $cwd, "dbase" );
        }
        elsif ( -d File::Spec->catdir( $cwd, "tables" ) ) {
            $target_dir = $cwd;
        }
        else {
            $target_dir = $cwd;
        }
    }
    $target_dir = eval { Cwd::abs_path($target_dir) } // $target_dir;

    my $opt_force     = $opts{force} // 0;
    my $opt_check     = $opts{check} // 0;
    my $opt_no_backup = $opts{no_backup} // $opts{'no-backup'} // 0;
    my $opt_tables    = $opts{tables} // $opts{table} // '';
    my $opt_manifest  = $opts{manifest} // '';

    print "=================================================================\n";
    print " AmberDB Storage, Directory & Compatibility Migration Engine     \n";
    print "=================================================================\n";
    print "Database Directory : $target_dir\n";

    my $config_dir = File::Spec->catdir( $target_dir, "config" );
    my $ver_file   = File::Spec->catfile( $config_dir, "storage_version.json" );

    require JSON::PP;
    require version;
    require HTTP::Tiny;
    require File::Path;
    require File::Copy;

    # 1. Inspect existing storage version
    my $current_storage_ver;
    if ( -e $ver_file ) {
        if ( open my $fh, '<', $ver_file ) {
            local $/;
            my $content = <$fh>;
            close $fh;
            my $data = eval { JSON::PP::decode_json($content) };
            if ( $data && $data->{storage_version} ) {
                $current_storage_ver = $data->{storage_version};
            }
        }
    }

    if ( !defined $current_storage_ver || $current_storage_ver eq '' ) {
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
        $manifest = eval { JSON::PP::decode_json($json_manifest) };
    }

    if ( !$manifest || ref($manifest) ne 'HASH' || !$manifest->{current_storage_version} ) {
        my $local_manifest_file = File::Spec->catfile( $target_dir, "migrations", "manifest.json" );
        if ( !-e $local_manifest_file ) {
            my ($vol, $dir, undef) = File::Spec->splitpath(__FILE__);
            my $proj = File::Spec->catdir($dir, "..", "..", "..");
            $local_manifest_file = File::Spec->catfile( $proj, "migrations", "manifest.json" );
        }
        if ( -e $local_manifest_file && open my $lfh, '<', $local_manifest_file ) {
            local $/;
            my $lcont = <$lfh>;
            close $lfh;
            $manifest = eval { JSON::PP::decode_json($lcont) };
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
        return { status => 'already_current', current_version => $current_storage_ver };
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
        return { status => 'check', current_version => $current_storage_ver, target_version => $target_storage_ver };
    }

    # 3. Pre-migration Safety Snapshot (unless --no-backup)
    if ( !$opt_no_backup ) {
        print "Taking pre-migration safety snapshot...\n";
        my $backup_file = File::Spec->catfile( $target_dir, "backup_pre_storage_update_" . time() . ".amberdb" );
        eval {
            require AmberDB;
            my $snap_adb = AmberDB->new( path => { dbase_dir => $target_dir } );
            my $maintainer = $self->can('dump') ? $self : do {
                require AmberDB::Tools::Maintain;
                AmberDB::Tools::Maintain->new($snap_adb);
            };
            $maintainer->dump( file => $backup_file );
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
        $self->_inline_migrate_5_21_0($target_dir);
    }

    # 5. Stage v5.25.0 Migration: tables -> table, ABR v5 format & complete re-indexing
    if ( $v_curr < version->parse('5.25.0') || $opt_force ) {
        print "\n>>> [Stage v5.25.0 Migration] Tables to Table, ABR v5 Binary Pack & Index Rebuild...\n";
        $self->_inline_migrate_5_25_0(
            $target_dir,
            force  => $opt_force,
            tables => $opt_tables,
        );
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
    );
    for my $d (@dirs) {
        if ( !-d $d ) {
            File::Path::make_path($d);
            print "  [+] Created $d\n";
        }
    }

    # 7. Stamp storage version
    File::Path::make_path($config_dir) unless -d $config_dir;
    if ( open my $fh, '>', $ver_file ) {
        my $stamp = {
            storage_version => $target_storage_ver,
            amberdb_engine  => $AmberDB::VERSION,
            record_format   => "abr_v5",
            encoding        => "utf-8",
            last_updated    => scalar localtime,
        };
        print $fh JSON::PP::encode_json($stamp);
        close $fh;
        print "\n[OK] Storage version stamped as v$target_storage_ver in $ver_file\n";
    }

    print "=================================================================\n";
    print " Storage migration completed successfully!                      \n";
    print "=================================================================\n";
    return { status => 'ok', target_version => $target_storage_ver };
}

sub _inline_migrate_5_21_0 {
    my ( $self, $tdir ) = @_;
    my $scheme_dir = File::Spec->catdir($tdir, 'scheme');
    my $schema_dir = File::Spec->catdir($tdir, 'schema');

    if (-d $scheme_dir) {
        if (!-d $schema_dir) {
            if (rename($scheme_dir, $schema_dir)) {
                print "  [v5.21.0] Renamed '$scheme_dir' -> '$schema_dir'\n";
            }
            else {
                File::Path::make_path($schema_dir);
                opendir(my $dh, $scheme_dir) or die "Cannot open $scheme_dir: $!";
                my $moved = 0;
                while (my $f = readdir($dh)) {
                    next if $f eq '.' || $f eq '..';
                    File::Copy::move(File::Spec->catfile($scheme_dir, $f), File::Spec->catfile($schema_dir, $f));
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
                    File::Copy::move($src, $dst);
                    $moved++;
                }
            }
            closedir($dh);
            rmdir($scheme_dir);
            print "  [v5.21.0] Merged $moved file(s) from '$scheme_dir' into '$schema_dir'\n";
        }
    }
    else {
        File::Path::make_path($schema_dir) unless -d $schema_dir;
        print "  [v5.21.0] Verified schema directory '$schema_dir'\n";
    }
}

sub _inline_migrate_5_25_0 {
    my ( $self, $tdir, %opts ) = @_;
    my $tables_dir = File::Spec->catdir($tdir, 'tables');
    my $table_dir  = File::Spec->catdir($tdir, 'table');
    my $opt_force  = $opts{force} // 0;
    my $opt_tables = $opts{tables} // '';

    # 1. Rename tables to table
    if (-d $tables_dir) {
        if (!-d $table_dir) {
            if (rename($tables_dir, $table_dir)) {
                print "  [v5.25.0] Renamed directory: '$tables_dir' -> '$table_dir'\n";
            }
            else {
                File::Path::make_path($table_dir);
                opendir(my $dh, $tables_dir) or die "Cannot open $tables_dir: $!";
                my $moved = 0;
                while (my $f = readdir($dh)) {
                    next if $f eq '.' || $f eq '..';
                    File::Copy::move(File::Spec->catfile($tables_dir, $f), File::Spec->catfile($table_dir, $f));
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
                    if (File::Copy::move($src, $dst)) {
                        $moved++;
                    }
                    else {
                        warn "  [!] Failed to move '$src' -> '$dst': $!\n";
                    }
                }
                else {
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

                    if (File::Copy::move($src, $stamped_dst)) {
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
        File::Path::make_path($table_dir) unless -d $table_dir;
        print "  [v5.25.0] Verified table directory '$table_dir'\n";
    }

    # 2. Convert legacy table records to ABR v5
    require AmberDB;
    my $fresh_adb = AmberDB->new( path => { dbase_dir => $tdir } );
    my $updater = $self->can('update_table') ? $self : do {
        require AmberDB::Tools::Update;
        AmberDB::Tools::Update->new($fresh_adb);
    };

    my @target_tables;
    if ($opt_tables) {
        @target_tables = ref($opt_tables) eq 'ARRAY' ? @$opt_tables : split /,/, $opt_tables;
    }
    else {
        my $maintainer = $self->can('all_tables') ? $self : do {
            require AmberDB::Tools::Maintain;
            AmberDB::Tools::Maintain->new($fresh_adb);
        };
        @target_tables = $maintainer->all_tables();
    }

    if (@target_tables) {
        print "  [v5.25.0] Upgrading legacy table formats to native ABR v5...\n";
        for my $tbl (@target_tables) {
            $tbl =~ s/^\s+|\s+$//g;
            next unless $tbl;

            print "    - Migrating table '$tbl' ... ";
            my $res = $updater->update_table( $tbl, force => $opt_force );
            if (!$res || $res->{status} eq 'error') {
                my $err = $res->{error} // 'Unknown error';
                print "FAILED! ($err)\n";
            }
            elsif ($res->{status} eq 'already_current') {
                print "ALREADY CURRENT ABR v5 (" . ($res->{already_current} // 0) . " records)\n";
            }
            elsif ($res->{status} eq 'updated') {
                print "Migrated! ($res->{total} records, format: $res->{dominant_format})\n";
            }
            else {
                print "OK\n";
            }
        }

        # 3. Rebuild all secondary binary indexes
        print "  [v5.25.0] Rebuilding all derived secondary binary indexes...\n";
        my $indexer = $self->can('set_index') ? $self : do {
            require AmberDB::Tools::Index;
            AmberDB::Tools::Index->new($fresh_adb);
        };
        for my $tbl (@target_tables) {
            $tbl =~ s/^\s+|\s+$//g;
            next unless $tbl;
            $indexer->set_index($tbl);
        }
    }
    else {
        print "  [v5.25.0] No tables found to migrate in '$tdir'.\n";
    }
}

1;
