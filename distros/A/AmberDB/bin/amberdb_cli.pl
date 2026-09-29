#!/usr/bin/perl

# bin/amberdb_cli.pl - AmberDB Command Line Interface & Management Console
# Direct file-based embedded execution, token-based session lifecycle, dynamic method reflection, and dash-tolerant argument parser.

use 5.016;
use strict;
use warnings;
use File::Basename qw(dirname basename);
use Cwd qw(abs_path getcwd);
use File::Spec;
use File::Path qw(make_path remove_tree);
use JSON::PP qw(encode_json decode_json);
use Data::Dumper;
use Time::HiRes qw(gettimeofday tv_interval);

our $t0 = [gettimeofday];

BEGIN {
    my $script_path = __FILE__;
    $script_path =~ s{[\\/]+}{/}g;
    my $bin_dir = $script_path =~ m{^(.*)/[^/]+$} ? $1 : '.';
    my $lib_dir = "$bin_dir/../lib";
    my $abs_lib = eval { abs_path($lib_dir) } // $lib_dir;
    unshift @INC, $abs_lib if -d $abs_lib;
    unshift @INC, $lib_dir if -d $lib_dir && $lib_dir ne $abs_lib;
}

use AmberDB;
use AmberDB::Tools;

$| = 1;

our $adb = AmberDB->new( path => { dbase_dir => 'dbstore' }, connect => { username => 'cli' }, config => { no_mkdir => 1 } );
our $tools = AmberDB::Tools->new($adb);

# ============================================================================
# ============================================================================
# SESSION REGISTRY (~/.amberdb/session/)
# Stores session files per active session under ~/.amberdb/session/sess_$token
# ============================================================================

my $user_home = $ENV{USERPROFILE} // $ENV{HOME} // '.';
$user_home =~ s{\\}{/}g;
our $AMBERDB_HOME = "$user_home/.amberdb";
our $CLI_SESS_DIR = "$AMBERDB_HOME/session";

sub setup_global_workspace {
    eval {
        make_path($AMBERDB_HOME) unless -d $AMBERDB_HOME;
        make_path($CLI_SESS_DIR) unless -d $CLI_SESS_DIR;
        my $cfg_dir = "$AMBERDB_HOME/config";
        make_path($cfg_dir) unless -d $cfg_dir;
    };
}

# Auto-provision global workspace in background on first run if missing
if ( !-d $AMBERDB_HOME ) {
    setup_global_workspace();
}

sub resolve_abs_path {
    my ($path) = @_;
    return '' unless defined $path && length $path;
    $path =~ s{\\}{/}g;
    my $abs = eval { abs_path($path) };
    if ( defined $abs && length $abs ) {
        $abs =~ s{\\}{/}g;
        return $abs;
    }
    my $cwd = eval { getcwd() } // '.';
    $cwd =~ s{\\}{/}g;
    my $rel = File::Spec->rel2abs( $path, $cwd );
    $rel =~ s{\\}{/}g;
    return $rel;
}

sub cli_session_file {
    my ($token) = @_;
    return '' unless $token;
    return "$CLI_SESS_DIR/sess_$token";
}

sub get_session_path {
    my ($token) = @_;
    $token //= '';

    # 1. If token is provided, check ~/.amberdb/session/sess_$token
    if ( $token ) {
        my $file = cli_session_file($token);
        if ( -f $file && open my $fh, '<', $file ) {
            local $/;
            my $content = <$fh>;
            close $fh;
            return '' unless $content;
            my $data = eval { decode_json($content) };
            if ( $data && ref $data eq 'HASH' && $data->{path} && $data->{path}->{dbase_dir} ) {
                return $data->{path}->{dbase_dir};
            }
            # Fallback if stored as plain path string
            $content =~ s/^\s+|\s+$//g if defined $content;
            return $content if length $content && -d $content;
        }
    }

    return undef;
}

sub set_session_path {
    my ( $token, $db_path, $sess_data ) = @_;
    return unless defined $token && length $token;
    make_path($CLI_SESS_DIR) unless -d $CLI_SESS_DIR;

    my $abs_path = resolve_abs_path($db_path);

    my $file = cli_session_file($token);
    if ( open my $fh, '>', $file ) {
        if ($sess_data) {
            $sess_data->{path}->{dbase_dir} = $abs_path if $sess_data->{path};
            print $fh encode_json($sess_data);
        }
        else {
            print $fh encode_json( {
                token => $token,
                path  => { dbase_dir => $abs_path },
            } );
        }
        close $fh;
    }
}

sub del_session_path {
    my ($token) = @_;
    return unless defined $token && length $token;

    # Delete ~/.amberdb/session/sess_$token
    my $file = cli_session_file($token);
    unlink $file if defined $file && -f $file;
}

# ============================================================================
# RESOLVE DBASE_DIR FROM CLI ARGUMENTS
# 1- Argümanlı: --db=dbstore veya --dbase_dir=/path/to (ayrıca -d, db=, path-dbase_dir=)
# 2- Oturum token'ı varsa: .amberdb/session/ içinden dbase_dir tespit et
# Argümandan gelmiyorsa: bulunduğu dizinde dbstore oluşturur.
# (Not: connect'ten sonraki argüman veritabanı adıdır, dbase_dir değildir)
# ============================================================================

my $target_db;
my $from_cli_args = 0;

# 1. Argümanlı: --db=dbstore veya --dbase_dir=/path/to (ayrıca -d, db=, path-dbase_dir=)
for (my $i = 0; $i < @ARGV; $i++) {
    my $arg = $ARGV[$i];
    if ( $arg =~ /^--(?:db|dbase_dir)=(.*)$/i || $arg =~ /^(?:path-dbase_dir|db)=(.*)$/i ) {
        $target_db = resolve_abs_path($1) if defined $1 && length $1;
        $from_cli_args = 1;
        last;
    }
    elsif ( ( $arg =~ /^--(?:db|dbase_dir)$/i || $arg =~ /^-d$/i ) && $i + 1 < @ARGV && $ARGV[$i + 1] !~ /^-/ ) {
        $target_db = resolve_abs_path($ARGV[$i + 1]);
        $from_cli_args = 1;
        last;
    }
}

# 3. Oturum token'ı varsa: .amberdb/session/ içinden dbase_dir tespit et
if ( !defined $target_db ) {
    my $token;
    for (my $i = 0; $i < @ARGV; $i++) {
        my $arg = $ARGV[$i];
        if ( $arg =~ /^(?:--?)?token=(.*)$/i ) {
            $token = $1;
            last;
        }
        elsif ( ( $arg =~ /^--(?:token)$/i || $arg =~ /^-k$/i ) && $i + 1 < @ARGV && $ARGV[$i + 1] !~ /^-/ ) {
            $token = $ARGV[$i + 1];
            last;
        }
    }
    if ( !defined $token && @ARGV && $ARGV[0] =~ /^[0-9]{4}$/ ) {
        $token = $ARGV[0];
    }
    $token //= $ENV{AMBERDB_TOKEN};

    my $reg_db = get_session_path($token);
    if ( defined $reg_db && length $reg_db ) {
        $target_db = $reg_db;
    }
}

# 4. Argümandan veya oturumdan gelmiyorsa: doğrudan yerel ./dbstore kullanılır (fallback yok)
if ( !defined $target_db || !length $target_db ) {
    $target_db = "dbstore";
}
$target_db = resolve_abs_path($target_db);

# Datadir ataması (DİKKAT: Henüz diskte dizin oluşturulmaz! Sadece insert veya setup anında oluşturulur)
$adb->set_datadir($target_db);

# Auto-detect database name for CLI context (connect.pl -> core.conf -> path pattern)
my $detected_dbname;
if ( -f "$target_db/config/connect.pl" ) {
    my $c_data = do "$target_db/config/connect.pl";
    $detected_dbname = $c_data->{database} if ref($c_data) eq 'HASH' && $c_data->{database};
}
if ( !$detected_dbname && -f "$target_db/config/core.conf" ) {
    if ( open my $cfh, '<', "$target_db/config/core.conf" ) {
        while ( my $line = <$cfh> ) {
            if ( $line =~ /^site_id\s+([^\s\t]+)/ ) {
                $detected_dbname = $1;
                last;
            }
        }
        close $cfh;
    }
}
if ( !$detected_dbname && $target_db =~ m{([^\/\\]+)[\/\\]dbstore$}i ) {
    my $candidate = $1;
    $detected_dbname = $candidate if $candidate && $candidate ne 'dbstore';
}
if ( $detected_dbname && $detected_dbname ne 'dbstore' ) {
    $adb->{_connect}->{database} = $detected_dbname;
    $adb->clear_cache('ramdisk');
    $adb->ramdisk_setup();
}

my $explicit_db      = $from_cli_args;
my $has_cfg_updates  = 0;
my $has_path_updates = 0;

# ============================================================================
# SESSION MANAGEMENT (TOKEN & STATE PERSISTENCE UNDER $adb->path('session_dir'))
# ============================================================================

sub generate_token {
    # 4-digit session token (e.g. 1000..9999) with collision avoidance
    for ( 1 .. 1000 ) {
        my $token = sprintf( "%04d", int( rand(9000) ) + 1000 );
        my $sf = session_file($token);
        next if defined $sf && -f $sf;
        my $cf = cli_session_file($token);
        next if defined $cf && -f $cf;
        return $token;
    }
    return sprintf( "%04d", int( rand(9000) ) + 1000 );
}

sub session_file {
    my ($token) = @_;
    return unless defined $token && length $token;

    # 1. Local session file in working directory: .amberdb/session/sess_$token
    my $local_sess = cli_session_file($token);
    return $local_sess if defined $local_sess && -f $local_sess;

    # 2. Database session file: RAM-disk veya standart disk
    my $db_sess = $adb->path('session_dir') . "/cli_$token";
    return $db_sess if -f $db_sess;

    return $local_sess;
}

sub save_session {
    my ( $token, $data ) = @_;
    return unless defined $token && length $token;

    # 1. Save in working directory: .amberdb/session/sess_$token
    set_session_path( $token, $adb->path('dbase_dir'), $data );

    # 2. Also save in database's own session_dir ($adb->path('session_dir')/cli_$token)
    my $sess_dir = $adb->path('session_dir');
    my $db_file = "$sess_dir/cli_$token";
    if ( open my $dfh, '>', $db_file ) {
        print $dfh encode_json($data);
        close $dfh;
    }
}

sub load_session {
    my ($token) = @_;
    return unless defined $token && length $token;

    # 1. Try local session in .amberdb/session/sess_$token
    my $local_file = cli_session_file($token);
    if ( defined $local_file && -f $local_file ) {
        if ( open my $fh, '<', $local_file ) {
            local $/;
            my $json = <$fh>;
            close $fh;
            my $data = eval { decode_json($json) };
            # Touch mtime to mark as recently used
            utime undef, undef, $local_file if $data;
            return $data if $data;
        }
    }

    # 2. Try candidate session file from database session_dir
    my $file = session_file($token);
    if ( defined $file && -f $file && $file ne ( $local_file // '' ) ) {
        if ( open my $fh, '<', $file ) {
            local $/;
            my $json = <$fh>;
            close $fh;
            return eval { decode_json($json) };
        }
    }

    return undef;
}

sub delete_session {
    my ($token) = @_;
    return unless defined $token && length $token;

    # 1. Delete from working directory: .amberdb/session/sess_$token
    del_session_path($token);

    # 2. Delete from database session_dir
    my $db_sess = $adb->path('session_dir') . "/cli_$token";
    unlink $db_sess if -f $db_sess;
}

sub resolve_active_token {
    my ( $cli_token, $allow_last_token ) = @_;
    return $cli_token if defined $cli_token && length $cli_token;
    return $ENV{AMBERDB_TOKEN} if defined $ENV{AMBERDB_TOKEN} && length $ENV{AMBERDB_TOKEN};
    return undef;
}

# ============================================================================
# VALUE PARSING & NESTED KEY BUILDER
# ============================================================================

sub parse_value {
    my ($v) = @_;
    return 1 unless defined $v;
    $v =~ s/^\s+|\s+$//g;
    # Strip wrapping quotes if preserved literally by shell (e.g. cmd.exe single quotes)
    if ( ( $v =~ /^'(.*)'$/s ) || ( $v =~ /^"(.*)"$/s ) ) {
        $v = $1;
        $v =~ s/^\s+|\s+$//g;
    }
    if ( ( $v =~ /^\[.*\]$/s ) || ( $v =~ /^\{.*\}$/s ) ) {
        my $decoded = eval { decode_json($v) };
        return $decoded if defined $decoded;

        # Fallback if inner quotes were removed by shell: [Book,15] or ['Book',15]
        if ( $v =~ /^\[(.*)\]$/s ) {
            my $inner = $1;
            my @items;
            while ( $inner =~ /([^,]+)/g ) {
                my $item = $1;
                $item =~ s/^\s+|\s+$//g;
                $item =~ s/^['"]//;
                $item =~ s/['"]$//;
                $item = 0 + $item if $item =~ /^-?\d+$/;
                push @items, $item;
            }
            return \@items if @items;
        }

        # Fallback if inner quotes were removed by shell: {name:Ahmet,role:admin}
        if ( $v =~ /^\{(.*)\}$/s ) {
            my $inner = $1;
            my %hash;
            while ( $inner =~ /([^,:]+)\s*:\s*([^,]+)/g ) {
                my ( $k, $item ) = ( $1, $2 );
                $k    =~ s/^\s+|\s+$//g;
                $k    =~ s/^['"]//;
                $k    =~ s/['"]$//;
                $item =~ s/^\s+|\s+$//g;
                $item =~ s/^['"]//;
                $item =~ s/['"]$//;
                $item = 0 + $item if $item =~ /^-?\d+$/;
                $hash{$k} = $item;
            }
            return \%hash if keys %hash;
        }
    }
    return 1 if $v =~ /^(?:true|yes)$/i;
    return 0 if $v =~ /^(?:false|no)$/i;
    return 0 + $v if $v =~ /^-?\d+$/;
    return $v;
}

sub set_nested_key {
    my ( $target, $path, $val ) = @_;
    my $curr = $target;
    for my $i ( 0 .. $#$path - 1 ) {
        my $p = $path->[$i];
        $curr->{$p} = {} unless ref $curr->{$p} eq 'HASH';
        $curr = $curr->{$p};
    }
    $curr->{ $path->[-1] } = $val;
}

sub format_bytes {
    my ($bytes) = @_;
    return "0 B" unless defined $bytes && $bytes > 0;
    if ( $bytes < 1024 ) {
        return "$bytes B";
    }
    elsif ( $bytes < 1024 * 1024 ) {
        return sprintf( "%.1f KB", $bytes / 1024 );
    }
    elsif ( $bytes < 1024 * 1024 * 1024 ) {
        return sprintf( "%.1f MB", $bytes / ( 1024 * 1024 ) );
    }
    else {
        return sprintf( "%.2f GB", $bytes / ( 1024 * 1024 * 1024 ) );
    }
}

# ============================================================================
# OUTPUT FORMATTING
# ============================================================================

sub format_cell {
    my ($val) = @_;
    return '' unless defined $val;
    if ( ref $val ) {
        my $json = eval { JSON::PP->new->utf8(0)->canonical(1)->encode($val) };
        if ( defined $json ) {
            $json =~ s/\r?\n/ /g;
            return $json;
        }
    }
    elsif ( $val =~ /^\{([^{}]*)\}$/s && $val !~ /"/ ) {
        # Unquoted hash string from shell: {name:Ahmet,role:admin}
        my $inner = $1;
        my %hash;
        while ( $inner =~ /([^,:]+)\s*:\s*([^,]+)/g ) {
            my ( $k, $item ) = ( $1, $2 );
            $k    =~ s/^\s+|\s+$//g;
            $k    =~ s/^['"]//;
            $k    =~ s/['"]$//;
            $item =~ s/^\s+|\s+$//g;
            $item =~ s/^['"]//;
            $item =~ s/['"]$//;
            $hash{$k} = ( $item =~ /^-?\d+$/ ? 0 + $item : $item );
        }
        if ( keys %hash ) {
            my $json = eval { JSON::PP->new->utf8(0)->canonical(1)->encode(\%hash) };
            if ( defined $json ) {
                $json =~ s/\r?\n/ /g;
                return $json;
            }
        }
    }
    return "$val";
}

sub format_tsv_cell {
    my ($val) = @_;
    my $cell = format_cell($val);
    $cell =~ s/\t/ /g;
    $cell =~ s/\r?\n/ /g;
    return $cell;
}

sub render_table_box {
    my ( $headers, $rows ) = @_;
    return unless @$headers;

    # 1. Calculate max widths
    my @widths = map { length($_) } @$headers;
    for my $row (@$rows) {
        for my $i ( 0 .. $#$headers ) {
            my $cell = format_cell( $row->[$i] );
            $widths[$i] = length($cell) if length($cell) > $widths[$i];
        }
    }

    # 2. Border lines
    my $sep_line = "+" . join( "+", map { "-" x ( $_ + 2 ) } @widths ) . "+";

    # 3. Print header
    print $sep_line, "\n";
    print "|";
    for my $i ( 0 .. $#$headers ) {
        printf( " %-${widths[$i]}s |", $headers->[$i] );
    }
    print "\n";
    print $sep_line, "\n";

    # 4. Print rows
    for my $row (@$rows) {
        print "|";
        for my $i ( 0 .. $#$headers ) {
            my $cell = format_cell( $row->[$i] );
            printf( " %-${widths[$i]}s |", $cell );
        }
        print "\n";
    }
    print $sep_line, "\n";
}

our $current_table;

sub render_records_table {
    my ( $recs, $table ) = @_;
    return unless $recs && ref $recs eq 'ARRAY' && @$recs;

    # Case 1: Pure hashes (e.g. inflated records from inflate=1: [ { id => 1, ... } ])
    if ( ref $recs->[0] eq 'HASH' ) {
        my %seen_keys;
        for my $r (@$recs) {
            next unless ref $r eq 'HASH';
            for my $k ( keys %$r ) {
                $seen_keys{$k} = 1 unless $k eq 'id';
            }
        }
        my @headers = ( ( grep { ref $_ eq 'HASH' && exists $_->{id} } @$recs ) ? ('id') : (), sort keys %seen_keys );
        my @rows;
        for my $r (@$recs) {
            push @rows, [ map { ref $r eq 'HASH' ? $r->{$_} : undef } @headers ];
        }
        render_table_box( \@headers, \@rows );
        return;
    }

    # Case 2: Block-aligned records: [ [ id, block_1, block_2, ... ], ... ]
    my @schema_blocks;
    if ( defined $table && length $table && defined $adb ) {
        my $info = eval { $adb->table_info($table) };
        if ( $info && ref $info eq 'HASH' && $info->{blocks} ) {
            if ( ref $info->{blocks} eq 'ARRAY' ) {
                for my $i ( 0 .. $#{ $info->{blocks} } ) {
                    my $b = $info->{blocks}->[$i];
                    my $bname = ref $b eq 'HASH' ? ( $b->{name} // $b->{id} ) : $b;
                    push @schema_blocks, $bname if defined $bname && length $bname;
                }
            }
            elsif ( ref $info->{blocks} eq 'HASH' ) {
                for my $k ( sort { $a <=> $b } keys %{ $info->{blocks} } ) {
                    my $b = $info->{blocks}->{$k};
                    my $bname = ref $b eq 'HASH' ? ( $b->{name} // $b->{id} ) : $b;
                    push @schema_blocks, $bname if defined $bname && length $bname;
                }
            }
        }
    }

    my $max_cols = 0;
    for my $r (@$recs) {
        my $cnt = ref $r eq 'ARRAY' ? scalar(@$r) : 1;
        $max_cols = $cnt if $cnt > $max_cols;
    }

    my @headers;
    my $has_schema = @schema_blocks ? 1 : 0;
    my $schema_has_id_at_0 = 0;
    if ( $has_schema && defined $schema_blocks[0] && $schema_blocks[0] =~ /^(?:id|ID)$/i ) {
        $schema_has_id_at_0 = 1;
    }

    for my $c ( 0 .. ( $max_cols - 1 ) ) {
        if ( $c == 0 ) {
            if ($has_schema) {
                push @headers, $schema_has_id_at_0 ? $schema_blocks[0] : 'id';
            }
            else {
                push @headers, '0';
            }
        }
        else {
            if ($has_schema) {
                my $s_idx = $schema_has_id_at_0 ? $c : ( $c - 1 );
                my $name = $schema_blocks[$s_idx] // "$c";
                push @headers, $name;
            }
            else {
                push @headers, "$c";
            }
        }
    }

    my @rows;
    for my $r (@$recs) {
        my @row;
        if ( ref $r eq 'ARRAY' ) {
            @row = @$r;
            while ( @row < $max_cols ) {
                push @row, undef;
            }
        }
        else {
            @row = ($r);
        }
        push @rows, \@row;
    }
    render_table_box( \@headers, \@rows );
}

sub output_result {
    my ( $data, $format, $table ) = @_;
    $format = lc( $format // '' );
    $table //= $current_table;

    if ( $format eq 'json' ) {
        print encode_json($data), "\n";
        return;
    }
    elsif ( $format eq 'pretty' ) {
        print JSON::PP->new->ascii->pretty->canonical->encode($data);
        return;
    }
    elsif ( $format eq 'raw' || $format eq 'dumper' || $format eq 'perl' ) {
        print Dumper($data);
        return;
    }
    elsif ( $format eq 'tsv' ) {
        if ( ref $data eq 'HASH' ) {
            if ( exists $data->{count} && exists $data->{records} && ref $data->{records} eq 'ARRAY' ) {
                my $recs = $data->{records};
                if ( @$recs && ref $recs->[0] eq 'HASH' ) {
                    my @cols = sort keys %{ $recs->[0] };
                    print join( "\t", @cols ), "\n";
                    for my $row (@$recs) {
                        print join( "\t", map { format_tsv_cell( $row->{$_} ) } @cols ), "\n";
                    }
                }
                else {
                    for my $row (@$recs) {
                        my @fields = ref $row eq 'ARRAY' ? @$row : ($row);
                        print join( "\t", map { format_tsv_cell($_) } @fields ), "\n";
                    }
                }
                return;
            }

            for my $k ( sort keys %$data ) {
                my $v = $data->{$k};
                print "$k\t" . format_tsv_cell($v) . "\n";
            }
            return;
        }

        if ( ref $data eq 'ARRAY' ) {
            if ( !@$data ) {
                return;
            }
            if ( ref $data->[0] eq 'HASH' ) {
                my @cols = sort keys %{ $data->[0] };
                print join( "\t", @cols ), "\n";
                for my $row (@$data) {
                    print join( "\t", map { format_tsv_cell( $row->{$_} ) } @cols ), "\n";
                }
            }
            elsif ( ref $data->[0] eq 'ARRAY' ) {
                # List of array records
                for my $row (@$data) {
                    print join( "\t", map { format_tsv_cell($_) } @$row ), "\n";
                }
            }
            else {
                # Single record: [ $id, $field_1, $field_2, ... ]
                print join( "\t", map { format_tsv_cell($_) } @$data ), "\n";
            }
            return;
        }

        print( ( defined $data ? format_tsv_cell($data) : "" ), "\n" );
        return;
    }

    # Default / Table view
    if ( !ref $data ) {
        print( ( $data // "" ), "\n" );
        return;
    }

    if ( ref $data eq 'HASH' ) {
        if ( exists $data->{count} && exists $data->{records} && ref $data->{records} eq 'ARRAY' ) {
            print "[Found " . $data->{count} . " record(s)]\n";
            my $recs = $data->{records};
            if ( @$recs ) {
                render_records_table( $recs, $table );
            }
            return;
        }

        # Single record hash (e.g. from read_id with inflate=1)
        if ( exists $data->{id} && !exists $data->{status} && !exists $data->{action} ) {
            render_records_table( [ $data ], $table );
            return;
        }

        # Simple Key-Value Hash Display
        my $max_k = 10;
        for my $k ( keys %$data ) {
            $max_k = length($k) if length($k) > $max_k;
        }
        print "-" x ( $max_k + 40 ), "\n";
        for my $k ( sort keys %$data ) {
            my $v = $data->{$k};
            my $v_str = ref $v ? encode_json($v) : ( $v // "" );
            printf( "%-${max_k}s : %s\n", $k, $v_str );
        }
        print "-" x ( $max_k + 40 ), "\n";
        return;
    }

    if ( ref $data eq 'ARRAY' ) {
        if ( !@$data ) {
            print "[0 records]\n";
            return;
        }
        if ( ref $data->[0] ) {
            # List of records: [ [ ... ], [ ... ] ] or [ { ... }, { ... } ]
            render_records_table( $data, $table );
        }
        else {
            # Single record: [ $id, ... ] or [ $id, \%hash ]
            render_records_table( [ $data ], $table );
        }
        return;
    }

    print Dumper($data);
}

# ============================================================================
# CLI ARGUMENT PARSER (DASH-TOLERANT: --key=val, -key=val, key=val)
# ============================================================================

my $opt_action;
my $opt_token;
my $opt_format;
our $opt_time   = 0;
my $opt_dry_run = 0;
my $opt_force   = 0;
our $opt_help      = 0;
our $opt_help_lang;
my $opt_database;
my $opt_user;
my $opt_pass;

my %method_args;
my @pos_args;

# Step 1: Pre-pass for space-separated flags (--db <val>, -d <val>, --token <val>, etc.)
my @raw_tokens;
my $arg_idx = 0;
while ( $arg_idx < @ARGV ) {
    my $curr = $ARGV[$arg_idx];
    if ( $curr =~ /^--(?:db|dbase|dbase_dir)=(.*)$/i ) {
        my $val = eval { abs_path($1) } // $1;
        $adb->set_datadir($val);
        $explicit_db = 1;
        $has_path_updates = 1;
    }
    elsif ( $curr =~ /^(?:path-dbase_dir|db)=(.*)$/i ) {
        my $val = eval { abs_path($1) } // $1;
        $adb->set_datadir($val);
        $explicit_db = 1;
        $has_path_updates = 1;
    }
    elsif ( ( $curr =~ /^--(?:db|dbase|dbase_dir)$/i || $curr =~ /^-d$/i ) && $arg_idx + 1 < @ARGV && $ARGV[$arg_idx + 1] !~ /^-/ ) {
        my $val = $ARGV[++$arg_idx];
        $val = eval { abs_path($val) } // $val;
        $adb->set_datadir($val);
        $explicit_db = 1;
        $has_path_updates = 1;
    }
    elsif ( $curr =~ /^(?:--?)?token=(.*)$/i ) {
        $opt_token = $1;
    }
    elsif ( ( $curr =~ /^--(?:token)$/i || $curr =~ /^-k$/i ) && $arg_idx + 1 < @ARGV && $ARGV[$arg_idx + 1] !~ /^-/ ) {
        $opt_token = $ARGV[++$arg_idx];
    }
    elsif ( ( $curr =~ /^--(?:user|username)$/i || $curr =~ /^-u$/i ) && $arg_idx + 1 < @ARGV && $ARGV[$arg_idx + 1] !~ /^-/ ) {
        $opt_user = $ARGV[++$arg_idx];
    }
    elsif ( ( $curr =~ /^--(?:pass|password|passwd)$/i || $curr =~ /^-p$/i ) && $arg_idx + 1 < @ARGV && $ARGV[$arg_idx + 1] !~ /^-/ ) {
        $opt_pass = $ARGV[++$arg_idx];
    }
    elsif ( ( $curr =~ /^--(?:format)$/i || $curr =~ /^-f$/i ) && $arg_idx + 1 < @ARGV && $ARGV[$arg_idx + 1] !~ /^-/ ) {
        $opt_format = lc($ARGV[++$arg_idx]);
    }
    elsif ( ( $curr =~ /^--(?:limit)$/i || $curr =~ /^-l$/i ) && $arg_idx + 1 < @ARGV && $ARGV[$arg_idx + 1] !~ /^-/ ) {
        $method_args{limit} = parse_value($ARGV[++$arg_idx]);
    }
    elsif ( ( $curr =~ /^--(?:offset)$/i || $curr =~ /^-o$/i ) && $arg_idx + 1 < @ARGV && $ARGV[$arg_idx + 1] !~ /^-/ ) {
        $method_args{offset} = parse_value($ARGV[++$arg_idx]);
    }
    elsif ( ( $curr =~ /^--(?:dir)$/i ) && $arg_idx + 1 < @ARGV && $ARGV[$arg_idx + 1] !~ /^-/ ) {
        $method_args{dir} = lc($ARGV[++$arg_idx]);
    }
    elsif ( ( $curr =~ /^--(?:data)$/i ) && $arg_idx + 1 < @ARGV && $ARGV[$arg_idx + 1] !~ /^-/ ) {
        $method_args{data} = parse_value($ARGV[++$arg_idx]);
    }
    elsif ( $curr =~ /^--(?:time)$/i ) {
        $opt_time = 1;
    }
    elsif ( $curr =~ /^--(?:version)$/i || $curr =~ /^-v$/i ) {
        $opt_action = 'version';
    }
    else {
        push @raw_tokens, $curr;
    }
    $arg_idx++;
}

# Step 2: Known action definitions
my %known_actions = map { $_ => 1 } qw(
    setup install ramdisk
    connect disconnect path config cfg attr table_attr user users
    status tables list info table_info read read_id read_all read_list
    search search_table fetch field_fetch count table_count
    insert insert_id update update_id delete delete_id
    reindex check vacuum migrate update_table update_storage update_version
    export tie2csv import csv2tie dump restore rename drop help usage
    help.tr usage.tr help.en usage.en version
);

# Step 3: Check if first token is a session token (e.g. 1245 or existing session file)
if ( !defined $opt_token && @raw_tokens ) {
    my $first = $raw_tokens[0];
    my $clean_first = $first;
    $clean_first =~ s/^--?//;
    if ( $clean_first !~ /=/ && !$known_actions{ lc($clean_first) } ) {
        if ( $clean_first =~ /^[a-zA-Z0-9]{4,8}$/ && @raw_tokens > 1 ) {
            $opt_token = shift @raw_tokens;
            $opt_token =~ s/^--?//;
        }
    }
}

# Step 4: Extract trailing format and time keywords if provided as standalone keywords
for ( 1 .. 2 ) {
    last unless @raw_tokens > 1;
    my $last = $raw_tokens[-1];
    if ( !defined $opt_format && $last =~ /^(?:json|pretty|tsv|dumper|perl|raw|table)$/i && $last !~ /=/ ) {
        $opt_format = lc( pop @raw_tokens );
    }
    elsif ( !$opt_time && $last =~ /^time$/i ) {
        my $act_candidate = lc( $raw_tokens[0] // '' );
        if ( @raw_tokens == 3 && ( $act_candidate eq 'search' || $act_candidate eq 'search_table' ) ) {
            last;
        }
        $opt_time = 1;
        pop @raw_tokens;
    }
    else {
        last;
    }
}

# Step 4b: Active session resolution & baseline state restoration
my $is_connect_cmd = 0;
for my $t (@raw_tokens) {
    if ( $t =~ /^--?(?:action=)?connect$/i ) {
        $is_connect_cmd = 1;
        last;
    }
}
my $is_session_cmd = 0;
for my $t (@raw_tokens) {
    if ( $t =~ /^--?(?:action=)?(connect|disconnect|config|path|attr|cfg|table_attr|user|users)$/i ) {
        $is_session_cmd = 1;
        last;
    }
}

if ( !defined $opt_token ) {
    for my $t (@raw_tokens) {
        if ( $t =~ /^(?:--?)?token=(.*)$/i ) {
            $opt_token = $1;
            last;
        }
    }
}

my $active_token;
my $session;
unless ($is_connect_cmd) {
    $active_token = resolve_active_token( $opt_token, $is_session_cmd || !@raw_tokens );
    $session      = $active_token ? load_session($active_token) : undef;

    if ( defined $opt_token && !$session ) {
        die "[AMBERDB_ERROR] Invalid or expired session token '$opt_token'.\n";
    }

    if ($session) {
        eval { $adb->connect( token => $active_token ) };
        if ( $session->{path}->{dbase_dir} && !$explicit_db ) {
            $adb->set_datadir( $session->{path}->{dbase_dir} );
        }
        $adb->path( $session->{path} ) if $session->{path};
        $adb->config( $session->{cfg} ) if $session->{cfg};
        if ( $session->{table_attrs} ) {
            for my $tbl ( keys %{ $session->{table_attrs} } ) {
                $adb->table_attr( $tbl, $session->{table_attrs}->{$tbl} );
            }
        }
    }
}

# Step 5: Process remaining tokens
for my $raw (@raw_tokens) {
    my $arg = $raw;
    $arg =~ s/^--?//;

    if ( $arg =~ /^([^=]+)=(.*)$/s ) {
        my ( $k, $v ) = ( $1, $2 );
        my $val = parse_value($v);

        if ( $k eq 'action' ) {
            $opt_action = $v;
        }
        elsif ( $k eq 'token' ) {
            $opt_token = $v;
        }
        elsif ( $k eq 'format' ) {
            $opt_format = lc($v);
        }
        elsif ( $k eq 'time' ) {
            $opt_time = $val ? 1 : 0;
        }
        elsif ( $k =~ /^(?:dry-run|dry_run)$/ ) {
            $opt_dry_run = $val ? 1 : 0;
        }
        elsif ( $k =~ /^(?:force|f)$/ ) {
            $opt_force = $val ? 1 : 0;
        }
        elsif ( $k =~ /^(?:check|c)$/i ) {
            $method_args{check} = $val ? 1 : 0;
        }
        elsif ( $k =~ /^(?:all|a)$/i ) {
            $method_args{all} = $val ? 1 : 0;
        }
        elsif ( $k =~ /^(?:no-backup|no_backup)$/i ) {
            $method_args{no_backup} = $val ? 1 : 0;
        }
        elsif ( $k eq 'cpanm' ) {
            $method_args{cpanm} = $v;
        }
        elsif ( $k eq 'manifest' ) {
            $method_args{manifest} = $v;
        }
        elsif ( $k =~ /^(?:help|h|usage)$/i ) {
            $opt_help = 1;
            if ( defined $v && $v =~ /^(?:tr|en)$/i ) {
                $opt_help_lang = lc($v);
            }
        }
        elsif ( $k =~ /^(?:help|usage)\.(tr|en)$/i ) {
            $opt_help = 1;
            $opt_help_lang = lc($1);
        }
        elsif ( $k =~ /^cfg-(.+)$/ ) {
            $adb->config( $1 => $val );
            $has_cfg_updates = 1;
        }
        elsif ( $k =~ /^path-(.+)$/ ) {
            my $pkey = $1;
            if ( $pkey eq 'dbase_dir' || $pkey eq 'db' || $pkey eq 'dbase' ) {
                my $abs = eval { abs_path($val) } // $val;
                $adb->set_datadir($abs);
                $explicit_db = 1;
            }
            else {
                $adb->path( $pkey => $val );
            }
            $has_path_updates = 1;
        }
        elsif ( $k eq 'no_write' ) {
            $adb->config( no_write => $val );
            $has_cfg_updates = 1;
        }
        elsif ( $k eq 'db' || $k eq 'dbase_dir' || $k eq 'dbase' ) {
            my $abs = eval { abs_path($val) } // $val;
            $adb->set_datadir($abs);
            $explicit_db = 1;
            $has_path_updates = 1;
        }
        elsif ( $k eq 'data' ) {
            $method_args{data} = $val;
        }
        elsif ( $k eq 'user' || $k eq 'username' ) {
            $opt_user = $val;
        }
        elsif ( $k eq 'pass' || $k eq 'password' || $k eq 'passwd' ) {
            $opt_pass = $val;
        }
        elsif ( $k eq 'database' || $k eq 'dbname' ) {
            $opt_database = $val;
            $adb->{_connect}->{database} = $val;
            $adb->clear_cache('ramdisk');
            $adb->ramdisk_setup();
        }
        else {
            if ( $k =~ /[-.]/ ) {
                my @parts = split /[-.]/, $k;
                set_nested_key( \%method_args, \@parts, $val );
            }
            else {
                $method_args{$k} = $val;
            }
        }
    }
    else {
        if ( $arg =~ /^(?:help|h|usage)$/i ) {
            $opt_help = 1;
            $opt_action //= 'help';
        }
        elsif ( $arg =~ /^(?:help|usage)\.(tr|en)$/i ) {
            $opt_help = 1;
            $opt_help_lang = lc($1);
            $opt_action //= 'help';
        }
        elsif ( $arg =~ /^(?:dry-run|dry_run)$/i ) {
            $opt_dry_run = 1;
        }
        elsif ( $arg =~ /^(?:force|f)$/i ) {
            $opt_force = 1;
        }
        elsif ( $raw =~ /^--?(?:check|c)$/i ) {
            $method_args{check} = 1;
        }
        elsif ( $raw =~ /^--?(?:all|a)$/i ) {
            $method_args{all} = 1;
        }
        elsif ( $raw =~ /^--?(?:no-backup|no_backup)$/i ) {
            $method_args{no_backup} = 1;
        }

        elsif ( $raw =~ /^--?time$/i ) {
            $opt_time = 1;
        }
        elsif ( !defined $opt_action ) {
            $opt_action = $arg;
        }
        else {
            push @pos_args, $arg;
        }
    }
}

# Step 6: Action alias normalization
if ( defined $opt_action ) {
    my $act = lc($opt_action);
    if ( $act =~ /^(?:help|usage)(?:\.(tr|en))?$/i ) {
        $opt_help = 1;
        $opt_help_lang = lc($1) if defined $1;
        $opt_action = 'help';
    }
    $opt_action = 'setup'          if $act eq 'setup' || $act eq 'install';
    $opt_action = 'status'         if $act eq 'tables' || $act eq 'list';
    $opt_action = 'user'           if $act eq 'users';
    $opt_action = 'config'         if $act eq 'cfg';
    $opt_action = 'attr'           if $act eq 'table_attr';
    $opt_action = 'info'           if $act eq 'table_info';
    $opt_action = 'search'         if $act eq 'search_table';
    $opt_action = 'fetch'          if $act eq 'field_fetch';
    $opt_action = 'count'          if $act eq 'table_count';
    $opt_action = 'insert'         if $act eq 'insert_id';
    $opt_action = 'update'         if $act eq 'update_id';
    $opt_action = 'delete'         if $act eq 'delete_id';
    $opt_action = 'migrate'        if $act eq 'update_table';
    $opt_action = 'update_storage' if $act eq 'update-storage' || $act eq 'updatedb' || $act eq 'update_storage';
    $opt_action = 'update_version' if $act eq 'update-amberdb' || $act eq 'update-version' || $act eq 'update_version';
    $opt_action = 'export'         if $act eq 'tie2csv';
    $opt_action = 'import'         if $act eq 'csv2tie';
    $opt_action = 'reindex'        if $act eq 'set_index';
    $opt_action = 'vacuum'         if $act eq 'vacuum';
}

# Step 6b: Subcommand resolution for 'update' (e.g. amberdb update storage / amberdb update version)
if ( defined $opt_action && $opt_action eq 'update' && @pos_args ) {
    if ( lc($pos_args[0]) eq 'storage' ) {
        $opt_action = 'update_storage';
        shift @pos_args;
    }
    elsif ( lc($pos_args[0]) eq 'version' || lc($pos_args[0]) eq 'engine' || lc($pos_args[0]) eq 'amberdb' ) {
        $opt_action = 'update_version';
        shift @pos_args;
    }
}

# Step 7: Natural 'read' command resolution
if ( defined $opt_action && $opt_action eq 'read' ) {
    my $tbl = delete $method_args{table} // shift @pos_args;
    $method_args{table} = $tbl;

    my $mode = shift @pos_args;
    if ( !defined $mode || $mode eq 'all' ) {
        $opt_action = 'read_all';
        my $offset = shift @pos_args;
        my $limit  = shift @pos_args;
        $method_args{offset} = parse_value($offset) if defined $offset;
        $method_args{limit}  = parse_value($limit)  if defined $limit;
    }
    elsif ( $mode =~ /,/ ) {
        $opt_action = 'read_list';
        $method_args{ids} = [ split /,/, $mode ];
    }
    elsif ( $mode =~ /^-?\d+$/ ) {
        if ( @pos_args && $pos_args[0] =~ /^-?\d+$/ ) {
            $opt_action = 'read_list';
            $method_args{ids} = [ parse_value($mode), map { parse_value($_) } @pos_args ];
            @pos_args = ();
        }
        else {
            $opt_action = 'read_id';
            $method_args{id} = parse_value($mode);
        }
    }
    else {
        $opt_action = 'read_id';
        $method_args{id} = $mode;
    }
}

# ============================================================================
# USAGE / HELP SCREEN
# ============================================================================

sub show_usage {
    my ($lang) = @_;
    $lang = lc( $lang // 'en' );

    if ( $lang eq 'tr' ) {
        print <<"USAGE_TR";
AmberDB CLI v$AmberDB::VERSION - Gömülü Veritabanı Konsolu ve Yönetim Aracı

Kullanım:
  amberdb [eylem|token] [tablo] [parametreler...]

Kullanım Biçimleri:

1. Doğrudan Yerel Kullanım (Varsayılan - Yerel ./dbstore):
  amberdb tables                              # Bulunulan dizindeki ./dbstore tablolarını listeler
  amberdb read products 10                    # ID ile tekil kayıt okuma
  amberdb read products 10 inflate=1 json     # Şema genişletmeli JSON okuma
  amberdb search products "kulaklık" limit=10 # Tam metin ve fonetik arama
  amberdb insert users 0 data='{"name":"Ali"}'# Kayıt ekler (yoksa ./dbstore oluşturur)
  amberdb update users 10 data='{"role":"admin"}'
  amberdb delete users 10

2. İsimlendirilmiş Oturum (Session Management):
  amberdb connect <database>                  # ~/.amberdb/<database> havuzuna bağlanır
  amberdb connect <database>\@<path>           # Özel bir klasöre bağlanır (örn: mydb\@./dbstore)
  amberdb 1245 tables                         # 1245 nolu oturumun tablolarını listeler
  amberdb 1245 read products 10               # 1245 nolu oturumda okuma yapar
  amberdb 1245 disconnect                     # Oturumu sonlandırır

3. Altyapı ve Kurulum:
  amberdb setup                               # ~/.amberdb global çalışma alanını kurar
  amberdb setup [dir]                         # Özel bir dizinde veritabanı iskeleti kurar
  amberdb setup ramdisk [start|stop|status]   # RAM-disk sürücü yönetimi

Bakım ve Yönetim Eylemleri:
  amberdb update storage [--check] [--force]  # Dizin & ABR v5 veri biçimi migrasyonu
  amberdb update version [--check]            # MetaCPAN çekirdek sürüm kontrolü / güncelleme
  amberdb reindex products                    # İndeksleri sıfırdan oluştur
  amberdb check products                      # Fiziksel dosya bütünlük kontrolü
  amberdb vacuum products                     # BDB disk boşluklarını temizle
  amberdb migrate products                    # Şema güncellemesi
  amberdb export products file=yedek.csv      # CSV dışa aktarımı
  amberdb import products file=yeni.csv       # CSV içe aktarımı
  amberdb dump products file=yedek.tar.gz     # Veritabanı yedeği al
  amberdb restore file=yedek.tar.gz           # Yedekten geri yükle
  amberdb rename from=eski to=yeni            # Tablo adı değiştir
  amberdb drop temp_tbl force=1               # Tabloyu kalıcı olarak sil

Genel Seçenekler:
  --format=table|json|pretty|tsv|dumper       Çıktı biçimi (Varsayılan: table. Veya sonda: json, tsv, dumper)
  --db=/path/to/dbstore                       Oturumsuz doğrudan veritabanı yolu
  --token=TOKEN                               Aktif oturum anahtarı
  --time, time, time=1                        İşlem süresini en altta satır olarak yazar
  --dry-run                                   İşlemi uygulamadan simüle eder
  --force                                     Silme eylemleri için zorunlu onay
  --version, -v, version                      Sürüm bilgisini yazar

İngilizce yardım için: amberdb usage
USAGE_TR
        exit 0;
    }

    # Default: English
    print <<"USAGE_EN";
AmberDB CLI v$AmberDB::VERSION - Embedded Database Console & Management Tool

Usage:
  amberdb [action|token] [table] [parameters...]

Usage Modes:

1. Direct Local Execution (Default - Local ./dbstore):
  amberdb tables                              # List tables in current directory ./dbstore
  amberdb read products 10                    # Read single record by ID
  amberdb read products 10 inflate=1 json     # Read record with schema inflation as JSON
  amberdb search products "headphone" limit=10# Full-text and phonetic search
  amberdb insert users 0 data='{"name":"Ali"}'# Insert record (creates ./dbstore if missing)
  amberdb update users 10 data='{"role":"admin"}'
  amberdb delete users 10

2. Named Session (Session Management):
  amberdb connect <database>                  # Connect to ~/.amberdb/<database> pool
  amberdb connect <database>\@<path>           # Connect to custom folder (e.g. mydb\@./dbstore)
  amberdb 1245 tables                         # List tables for session 1245
  amberdb 1245 read products 10               # Read record in session 1245
  amberdb 1245 disconnect                     # Terminate active session

3. Infrastructure & Setup:
  amberdb setup                               # Provision ~/.amberdb global workspace
  amberdb setup [dir]                         # Initialize database skeleton in custom directory
  amberdb setup ramdisk [start|stop|status]   # RAM-disk drive management

Maintenance & Administrative Actions:
  amberdb update storage [--check] [--force]  # Directory & ABR v5 format migration
  amberdb update version [--check]            # MetaCPAN core version check / update
  amberdb reindex products                    # Rebuild all derived indexes
  amberdb check products                      # Physical file integrity check
  amberdb vacuum products                     # Compact and reclaim BDB storage space
  amberdb migrate products                    # Schema migration
  amberdb export products file=backup.csv     # Export table to CSV
  amberdb import products file=new.csv        # Import table from CSV
  amberdb dump products file=backup.tar.gz    # Create database backup archive
  amberdb restore file=backup.tar.gz          # Restore database from backup
  amberdb rename from=old to=new              # Rename table
  amberdb drop temp_tbl force=1               # Permanently drop table and indexes

General Options:
  --format=table|json|pretty|tsv|dumper       Output format (Default: table. Or trailing: json, tsv, dumper)
  --db=/path/to/dbstore                       Direct database directory without session
  --token=TOKEN                               Active session token
  --time, time, time=1                        Prints execution time at the bottom
  --dry-run                                   Simulates execution without writes
  --force                                     Required confirmation for destructive actions
  --version, -v, version                      Display version information

For Turkish help: amberdb usage.tr
USAGE_EN
    exit 0;
}

if ( $opt_help || ( defined $opt_action && $opt_action eq 'help' ) ) {
    my $lang = $opt_help_lang;
    if ( @pos_args && $pos_args[0] =~ /^(?:tr|en)$/i ) {
        $lang //= lc(shift @pos_args);
    }
    $lang //= 'en';
    $opt_help = 1;
    show_usage($lang);
}

if ( defined $opt_action && $opt_action =~ /^(?:version|--version|-v)$/i ) {
    if ( defined $opt_format && $opt_format eq 'json' ) {
        output_result( { version => $AmberDB::VERSION, engine => 'AmberDB', platform => $^O }, $opt_format );
    }
    else {
        print "AmberDB v$AmberDB::VERSION (CLI)\n";
    }
    exit 0;
}

# ============================================================================
# LIFECYCLE: CONNECT & DISCONNECT
# ============================================================================

if ( defined $opt_action && $opt_action eq 'connect' ) {
    my $conn_arg = $opt_database // shift @pos_args;
    my ( $conn_db, $custom_path );

    if ( defined $conn_arg ) {
        # Custom directory format: <dbname>@<path> (e.g. mydb@./dbstore or mydb@C:/data)
        if ( $conn_arg =~ /^([a-zA-Z0-9_\-]+)@(.+)$/ ) {
            $conn_db     = $1;
            $custom_path = $2;
        }
        else {
            $conn_db = $conn_arg;
        }
    }

    if ( defined $conn_db && ( $conn_db eq 'dbstore' || $conn_db =~ m{[/\\\\]} || $conn_db =~ /^[a-zA-Z]:/ ) ) {
        die "[AMBERDB_ERROR] '$conn_db' is a directory path/name, not a valid database name. Database name is expected after 'connect'. For custom directory use format: <dbname>\@<path> (e.g. amberdb connect mydb\@./dbstore) or specify --db=<dir>.\n";
    }

    $conn_db //= $detected_dbname;
    unless ( defined $conn_db && length $conn_db ) {
        die "[AMBERDB_ERROR] Database name required. Usage: amberdb connect <database_name> (or <database_name>\@<path>)\n";
    }

    my $target_data_dir;
    if ( defined $custom_path && length $custom_path ) {
        $target_data_dir = resolve_abs_path($custom_path);
    }
    elsif ( $explicit_db ) {
        $target_data_dir = $adb->path('dbase_dir');
    }
    else {
        # Central store under ~/.amberdb/<dbname>
        $target_data_dir = "$AMBERDB_HOME/$conn_db";
    }
    $target_data_dir = resolve_abs_path($target_data_dir);

    # Ensure target data directory and skeleton exist
    make_path(
        "$target_data_dir/table", "$target_data_dir/schema", "$target_data_dir/journal",
        "$target_data_dir/lock",  "$target_data_dir/session", "$target_data_dir/config",
        "$target_data_dir/backup", "$target_data_dir/ramdisk"
    );
    my $conf_file = "$target_data_dir/config/core.conf";
    if ( !-f $conf_file && open my $cfh, '>', $conf_file ) {
        print $cfh "site_id        $conn_db\nlanguage       tr\n";
        close $cfh;
    }

    $adb->set_datadir($target_data_dir);
    $adb->{_connect}->{database} = $conn_db;
    $adb->clear_cache('ramdisk');
    $adb->ramdisk_setup();

    # Authenticate and generate token
    my $conn_user = 'cli';
    my $entered_user = shift @pos_args if @pos_args;
    my $conn_pass = $opt_pass // shift @pos_args // '';

    my $token = eval {
        $adb->connect(
            database => $conn_db,
            username => $conn_user,
            ( defined $conn_pass && length $conn_pass ? ( password => $conn_pass ) : () ),
        );
    };
    if ( $@ || !$token ) {
        my $err = $@ || $adb->last_error() || "Authentication failed";
        $err =~ s/ at .* line \d+.*//s;
        die "[AMBERDB_ERROR] $err\n";
    }

    # Save session with canonical absolute path in ~/.amberdb/session/sess_$token
    my $sess_data = {
        token    => $token,
        database => $conn_db,
        username => $conn_user,
        path     => { dbase_dir => $target_data_dir },
        cfg      => $adb->config(),
    };
    set_session_path( $token, $target_data_dir, $sess_data );

    my $actual_file = cli_session_file($token);

    if ( defined $opt_format && $opt_format eq 'json' ) {
        print encode_json( {
            status       => 'connected',
            token        => $token,
            session_file => $actual_file,
            database     => $conn_db,
            username     => $conn_user,
            path         => { dbase_dir => $target_data_dir },
            cfg          => $adb->config(),
        } ), "\n";
    }
    else {
        print "[AMBERDB] Connected successfully.\n";
        print "Session Token : $token\n";
        print "Database      : $conn_db\n";
        print "Data Dir      : $target_data_dir\n";
        print "Session File  : $actual_file\n";
        print "\nUsage with Token:\n";
        print "  amberdb $token tables\n";
        print "  amberdb $token read <table_name> <id>\n";
        print "Or set environment variable in current shell:\n";
        print "  export AMBERDB_TOKEN=$token  (Windows CMD: set AMBERDB_TOKEN=$token)\n";
    }
    exit 0;
}

if ( defined $opt_action && $opt_action eq 'disconnect' ) {
    my $token = $active_token || resolve_active_token( $opt_token, 1 );
    unless ($token) {
        die "[AMBERDB_ERROR] No active session token found to disconnect.\n";
    }
    $adb->disconnect($token);
    delete_session($token);
    if ( defined $opt_format && $opt_format eq 'json' ) {
        print encode_json( { status => 'disconnected', token => $token } ), "\n";
    }
    else {
        print "[AMBERDB] Disconnected session '$token' successfully.\n";
    }
    exit 0;
}

# If in session and global configs/paths changed without action, update session and exit
if ( $session && ( $has_cfg_updates || $has_path_updates ) && !defined $opt_action ) {
    $session->{path} = $adb->path();
    $session->{cfg}  = $adb->config();
    $session->{updated_at} = time();
    save_session( $active_token, $session );

    if ( defined $opt_format && $opt_format eq 'json' ) {
        print encode_json( { status => 'updated', token => $active_token, path => $adb->path(), cfg => $adb->config() } ), "\n";
    }
    else {
        print "[AMBERDB] Session '$active_token' configuration updated successfully.\n";
        print "Path   : " . encode_json( $adb->path() ) . "\n";
        print "Config : " . encode_json( $adb->config() ) . "\n";
    }
    exit 0;
}

# ============================================================================
# SESSION COMMANDS: CONFIG & PATH
# ============================================================================

if ( defined $opt_action && $opt_action eq 'config' ) {
    unless ($session) {
        die "[AMBERDB_ERROR] 'config' requires an active session. Run 'connect' first (e.g. amberdb connect path-dbase_dir=...) or specify a token.\n";
    }
    if ( %method_args || $has_cfg_updates ) {
        for my $k ( keys %method_args ) {
            $adb->config( $k => $method_args{$k} );
        }
        $session->{cfg} = $adb->config();
        $session->{updated_at} = time();
        save_session( $active_token, $session );
        output_result( { status => 'ok', action => 'config', token => $active_token, cfg => $adb->config() }, $opt_format );
    }
    else {
        output_result( $adb->config() // {}, $opt_format );
    }
    exit 0;
}

if ( defined $opt_action && $opt_action eq 'path' ) {
    unless ($session) {
        die "[AMBERDB_ERROR] 'path' requires an active session. Run 'connect' first (e.g. amberdb connect path-dbase_dir=...) or specify a token.\n";
    }
    if ( %method_args || $has_path_updates ) {
        my $old_file = session_file($active_token);
        for my $k ( keys %method_args ) {
            my $val = $method_args{$k};
            if ( $k eq 'dbase_dir' || $k eq 'db' || $k eq 'dbase' ) {
                my $new_db_dir = eval { abs_path($val) } // $val;
                $adb->set_datadir($new_db_dir);
            }
            else {
                $adb->path( $k => $val );
            }
        }
        $session->{path} = $adb->path();
        $session->{updated_at} = time();

        my $new_file = session_file($active_token);
        save_session( $active_token, $session );
        if ( defined $old_file && -f $old_file && $old_file ne $new_file ) {
            unlink $old_file;
        }
        output_result( { status => 'ok', action => 'path', token => $active_token, path => $adb->path() }, $opt_format );
    }
    else {
        output_result( $adb->path() // {}, $opt_format );
    }
    exit 0;
}

if ( defined $opt_action && $opt_action eq 'user' ) {
    my $subcmd = shift @pos_args // 'list';
    if ( $subcmd eq 'list' ) {
        my @users = $adb->user_list();
        if ( defined $opt_format && ( $opt_format eq 'json' || $opt_format eq 'pretty' ) ) {
            output_result( { status => 'ok', action => 'user_list', users => \@users }, $opt_format );
        }
        else {
            print "Database: " . ($adb->connect('database') || 'unknown') . "\n";
            print "=" x 60, "\n";
            printf( "%-20s %-15s %-15s\n", "Username", "Role", "Password Set" );
            print "-" x 60, "\n";
            for my $u (@users) {
                printf( "%-20s %-15s %-15s\n",
                    $u->{username},
                    $u->{role},
                    $u->{has_password} ? "Yes (Shadow)" : "No (Passwordless)"
                );
            }
            print "-" x 60, "\n";
        }
        exit 0;
    }
    elsif ( $subcmd eq 'add' ) {
        my $u = shift @pos_args // $opt_user;
        my $p = shift @pos_args // $opt_pass // '';
        my $role = shift @pos_args // 'user';
        die "[AMBERDB_ERROR] Usage: amberdb user add <username> [password] [role]\n" unless defined $u && length $u;
        $adb->user_add( $u, $p, role => $role );
        output_result( { status => 'ok', action => 'user_add', username => $u, role => $role }, $opt_format );
        exit 0;
    }
    elsif ( $subcmd eq 'passwd' ) {
        my $u = shift @pos_args // $opt_user;
        my $p = shift @pos_args // $opt_pass // '';
        die "[AMBERDB_ERROR] Usage: amberdb user passwd <username> <new_password>\n" unless defined $u && length $u;
        $adb->user_passwd( $u, $p );
        output_result( { status => 'ok', action => 'user_passwd', username => $u }, $opt_format );
        exit 0;
    }
    elsif ( $subcmd eq 'del' || $subcmd eq 'delete' ) {
        my $u = shift @pos_args // $opt_user;
        die "[AMBERDB_ERROR] Usage: amberdb user del <username>\n" unless defined $u && length $u;
        $adb->user_del($u);
        output_result( { status => 'ok', action => 'user_del', username => $u }, $opt_format );
        exit 0;
    }
    else {
        die "[AMBERDB_ERROR] Unknown user subcommand '$subcmd'. Available: list, add, passwd, del\n";
    }
}

# ============================================================================
# INFRASTRUCTURE SETUP & PROVISIONING (amberdb setup [dir])
# ============================================================================

if ( defined $opt_action && ( $opt_action eq 'setup' || $opt_action eq 'ramdisk' ) ) {
    my $first_arg = shift @pos_args;

    # Check if ramdisk subcommand: amberdb setup ramdisk ... or amberdb ramdisk ...
    if ( ( $opt_action eq 'ramdisk' ) || ( defined $first_arg && lc($first_arg) eq 'ramdisk' ) ) {
        my $subcmd = ( $opt_action eq 'ramdisk' ) ? ( $first_arg // 'status' ) : ( shift @pos_args // 'status' );
        $subcmd = lc($subcmd);
        $subcmd = 'start'  if $subcmd eq 'mount' || $subcmd eq '--start';
        $subcmd = 'stop'   if $subcmd eq 'unmount' || $subcmd eq '--stop';
        $subcmd = 'status' if $subcmd eq '--status';

        my $size  = delete $method_args{size}  // shift @pos_args // '512M';
        my $drive = delete $method_args{drive} // shift @pos_args // 'R:';

        my $is_win = ( $^O eq 'MSWin32' || $^O eq 'msys' || $^O eq 'cygwin' );

        if ($is_win) {
            my $script_bin = eval { abs_path(dirname(__FILE__)) } // dirname(__FILE__) // '.';
            my $bat_path = File::Spec->catfile( $script_bin, "setup_windows.bat" );
            if ( -f $bat_path ) {
                system( "cmd.exe", "/c", $bat_path, $subcmd, $size, $drive );
                exit $? >> 8;
            }
            else {
                if ( $subcmd eq 'start' ) {
                    system( "imdisk", "-a", "-s", $size, "-m", $drive, "-p", "/fs:ntfs /q /y /v:AmberDB" );
                }
                elsif ( $subcmd eq 'stop' ) {
                    system( "imdisk", "-D", "-m", $drive );
                }
                else {
                    system( "imdisk", "-l", "-m", $drive );
                }
                exit $? >> 8;
            }
        }
        else {
            if ( $subcmd eq 'status' ) {
                my $shm = -d "/dev/shm" ? "/dev/shm (Linux tmpfs available)" : "Not mounted";
                print "RAM-Disk Status: $shm\n";
                exit 0;
            }
            elsif ( $subcmd eq 'start' ) {
                eval { $adb->ramdisk_setup() };
                print "[RAM-DISK] Linux /dev/shm initialized.\n";
                exit 0;
            }
            elsif ( $subcmd eq 'stop' ) {
                print "[RAM-DISK] Stopped.\n";
                exit 0;
            }
        }
    }

    # If no argument is passed: setup global environment (~/.amberdb)
    if ( !defined $first_arg || !length $first_arg ) {
        setup_global_workspace();

        if ( defined $opt_format && $opt_format eq 'json' ) {
            output_result( {
                status       => 'ok',
                action       => 'setup',
                mode         => 'global',
                amberdb_home => $AMBERDB_HOME,
                session_dir  => $CLI_SESS_DIR,
            }, $opt_format );
            exit 0;
        }

        print "=================================================================\n";
        print " AmberDB Global Environment Setup & Initialization               \n";
        print "=================================================================\n";
        print "AmberDB Home     : $AMBERDB_HOME (~/.amberdb)\n";
        print "Session Registry : $CLI_SESS_DIR/\n";
        print "Platform         : $^O\n";
        print "-----------------------------------------------------------------\n";
        print "[SUCCESS] AmberDB global workspace initialized successfully!\n\n";
        print "Kullanım Biçimleri:\n";
        print "  1. Yerel Proje   : Proje klasörünüzde doğrudan çalıştırın (./dbstore kullanılır)\n";
        print "     amberdb insert users 0 data='{\"name\":\"Ahmet\"}'\n";
        print "     amberdb tables\n\n";
        print "  2. Merkezi Havuz : Belirtilen ada oturum açarak ~/.amberdb/<ad> kullanılır\n";
        print "     amberdb connect eticaretim\n";
        print "     amberdb 1245 tables\n\n";
        print "  3. Özel Klasör   : 'ad\@yol' formatı ile oturum açılır\n";
        print "     amberdb connect eticaretim\@./dbstore\n";
        print "=================================================================\n";
        exit 0;
    }

    # If custom directory passed (e.g. amberdb setup /var/data or amberdb setup my_dir)
    my $target_dir = resolve_abs_path($first_arg);
    my @subdirs = qw(table schema journal lock session config backup ramdisk);
    my @created;
    my @existing;
    make_path($target_dir) unless -d $target_dir;
    for my $sub (@subdirs) {
        my $dir_path = "$target_dir/$sub";
        if ( -d $dir_path ) {
            push @existing, $sub;
        }
        else {
            make_path($dir_path);
            push @created, $sub;
        }
    }
    my $core_conf = "$target_dir/config/core.conf";
    my $conf_created = 0;
    if ( !-f $core_conf && open my $fh, '>', $core_conf ) {
        print $fh "# AmberDB Core Configuration\n";
        print $fh "site_id        amberdb\n";
        print $fh "language       tr\n";
        close $fh;
        $conf_created = 1;
    }
    if ( defined $opt_format && $opt_format eq 'json' ) {
        output_result( {
            status        => 'ok',
            action        => 'setup',
            dbase_dir     => $target_dir,
            dirs_created  => \@created,
            dirs_existing => \@existing,
            config_init   => $conf_created ? 1 : 0,
        }, $opt_format );
        exit 0;
    }

    print "=================================================================\n";
    print " AmberDB Infrastructure Setup: $target_dir                       \n";
    print "=================================================================\n";
    for my $c (@created)  { print "  [+] Created  $c/\n"; }
    for my $e (@existing) { print "  [.] Exists   $e/\n"; }
    print "-----------------------------------------------------------------\n";
    print "[SUCCESS] Initialized successfully in $target_dir\n";
    print "=================================================================\n";
    exit 0;
}

# ============================================================================
# DEFAULT ACTION: DASHBOARD OVERVIEW (ALL TABLES)
# ============================================================================

if ( !defined $opt_action || $opt_action eq '' || $opt_action eq 'list' || $opt_action eq 'status' || $opt_action eq 'tables' ) {
    my $db_dir = $adb->path('dbase_dir') || ".";

    if ( !-d $db_dir || ( !-d "$db_dir/table" && !-d "$db_dir/schema" ) ) {
        if ( defined $opt_format && ( $opt_format eq 'json' || $opt_format eq 'pretty' ) ) {
            output_result( {
                database      => $adb->connect('database') || $detected_dbname || '-',
                user          => $adb->connect('username') || 'cli',
                data_dir      => $db_dir,
                total_tables  => 0,
                total_records => 0,
                total_bytes   => 0,
                tables        => [],
            }, $opt_format );
            exit 0;
        }
        print "AmberDB | Data Dir: $db_dir\n";
        print "=" x 80, "\n";
        print "[AMBERDB] '$db_dir' dizini bulunamadı veya henüz bir tablo oluşturulmamış.\n";
        print "İlk tabloyu oluşturmak için kayıt ekleyebilirsiniz:\n";
        print "  amberdb insert <tablo_adı> 0 data='{\"name\":\"sample\"}'\n";
        print "=" x 80, "\n";
        exit 0;
    }

    my @tables = $tools->all_tables();
    my @rows;
    my $total_records = 0;
    my $total_bytes   = 0;

    for my $tbl ( sort @tables ) {
        next unless defined $tbl && length $tbl;
        my $cnt   = $adb->table_count($tbl) // 0;
        my $tpath = $adb->table_path($tbl);
        my $db_file = -f "$tpath.db" ? "$tpath.db" : ( -f "$db_dir/table/$tbl.db" ? "$db_dir/table/$tbl.db" : "$db_dir/$tbl.db" );
        my $size = -f $db_file ? -s $db_file : 0;
        
        $total_records += $cnt;
        $total_bytes   += $size;

        my $has_schema = ( -f "$tpath.table" || -f "$db_dir/schema/$tbl.table" ) ? "OK" : ( $adb->config('simple') ? "Simple" : "None" );

        my @indexes;
        push @indexes, "inx" if -f "$tpath.inx";
        push @indexes, "src" if -f "$tpath.src";
        push @indexes, "fld" if -f "$tpath.fld";
        push @indexes, "slg" if -f "$tpath.slg";
        push @indexes, "del" if -f "$tpath.del";
        push @indexes, "lnk" if -f "$tpath.lnk";

        push @rows, {
            table   => $tbl,
            records => $cnt,
            size    => format_bytes($size),
            schema  => $has_schema,
            indexes => @indexes ? join( ", ", @indexes ) : "-",
        };
    }

    if ( defined $opt_format && ( $opt_format eq 'json' || $opt_format eq 'pretty' ) ) {
        output_result( {
            database      => $adb->connect('database'),
            user          => $adb->connect('username'),
            data_dir      => $adb->path('dbase_dir'),
            total_tables  => scalar(@rows),
            total_records => $total_records,
            total_bytes   => $total_bytes,
            tables        => \@rows,
        }, $opt_format );
    }
    else {
        print "AmberDB v$AmberDB::VERSION | Database: " . ($adb->connect('database') || '-') . " | User: " . ($adb->connect('username') || '-') . " | Data Dir: " . $adb->path('dbase_dir') . "\n";
        print "=" x 80, "\n";
        printf( "%-28s %-10s %-12s %-10s %-15s\n", "Table Name", "Records", "Size", "Schema", "Indexes" );
        print "-" x 80, "\n";
        for my $r (@rows) {
            printf( "%-28s %-10s %-12s %-10s %-15s\n",
                substr( $r->{table}, 0, 27 ),
                $r->{records},
                $r->{size},
                $r->{schema},
                $r->{indexes}
            );
        }
        print "-" x 80, "\n";
        printf( "Total Tables: %d | Total Records: %d | Total Size: %s\n",
            scalar(@rows), $total_records, format_bytes($total_bytes) );
    }
    exit 0;
}

# ============================================================================
# DYNAMIC METHOD DISPATCHER
# ============================================================================

my $action = $opt_action;

sub is_db_ready {
    my $dir = $adb->path('dbase_dir');
    return 0 unless defined $dir && length $dir && -d $dir;
    return 1 if -d "$dir/table" || -d "$dir/schema";
    return 0;
}

sub table_file_exists {
    my ($tbl) = @_;
    return 0 unless defined $tbl && length $tbl;
    my $dir = $adb->path('dbase_dir');
    return 0 unless defined $dir && length $dir && -d $dir;
    my $tbl_dir = $adb->path('table_dir') || "$dir/table";
    return 1 if -f "$tbl_dir/$tbl.db";
    return 1 if -f "$dir/$tbl.db";
    my $tpath = eval { $adb->table_path($tbl) };
    return 1 if defined $tpath && length $tpath && ( -f "$tpath.db" || -f $tpath );
    return 0;
}

sub normalize_list_result {
    my ( $limit, $is_inflate, @results ) = @_;
    if ($limit) {
        my $cnt = shift @results // 0;
        my $recs;
        if ($is_inflate) {
            my $raw = shift @results // [];
            $recs = ref $raw eq 'ARRAY' ? $raw : [ $raw ];
        }
        else {
            $recs = \@results;
        }
        return { count => $cnt, records => $recs };
    }
    else {
        my $recs;
        if ($is_inflate) {
            my $raw = $results[0] // [];
            $recs = ref $raw eq 'ARRAY' ? $raw : [ $raw ];
        }
        else {
            $recs = \@results;
        }
        return { count => scalar(@$recs), records => $recs };
    }
}

# 1. TABLE_ATTR / ATTR
if ( $action eq 'table_attr' || $action eq 'attr' ) {
    unless ($session) {
        die "[AMBERDB_ERROR] 'attr' requires an active session. Run 'connect' first (e.g. amberdb connect path-dbase_dir=...) or specify a token.\n";
    }
    my $table = delete $method_args{table} // shift @pos_args;
    die "[AMBERDB_ERROR] 'table' parameter required for table_attr\n" unless defined $table && length $table;

    if ( !keys %method_args ) {
        # Getter: return current attributes
        my $attrs = $session->{table_attrs}->{$table} || $adb->table_attr($table);
        output_result( $attrs, $opt_format );
        exit 0;
    }

    if ($opt_dry_run) {
        output_result( { dry_run => 1, action => 'table_attr', table => $table, attrs => \%method_args }, $opt_format );
        exit 0;
    }

    $adb->table_attr( $table, \%method_args );
    my $updated_attrs = $adb->table_attr($table);

    # Persist in session if session active
    if ($session) {
        $session->{table_attrs}->{$table} = $updated_attrs;
        $session->{updated_at}            = time();
        save_session( $active_token, $session );
    }

    output_result( { status => 'ok', action => 'table_attr', table => $table, attributes => $updated_attrs }, $opt_format );
    exit 0;
}

# 2. READ_ID
if ( $action eq 'read_id' ) {
    my $table = delete $method_args{table} // shift @pos_args;
    my $id    = delete $method_args{id}    // shift @pos_args;
    die "[AMBERDB_ERROR] 'table' parameter required for read_id\n" unless defined $table && length $table;
    die "[AMBERDB_ERROR] 'id' parameter required for read_id\n" unless defined $id && length $id;

    if ( !is_db_ready() || !table_file_exists($table) ) {
        output_result( undef, $opt_format );
        exit 0;
    }

    my @fields = $adb->read_id( $table, $id, \%method_args );
    my $res;
    if ( @fields == 1 && ref $fields[0] eq 'HASH' ) {
        $res = $fields[0];
    }
    elsif (@fields) {
        $res = \@fields;
    }
    else {
        $res = undef;
    }
    output_result( $res, $opt_format, $table );
    exit 0;
}

# 3. READ_ALL
if ( $action eq 'read_all' ) {
    my $table      = delete $method_args{table}  // shift @pos_args;
    my $offset     = delete $method_args{offset} // 0;
    my $limit      = delete $method_args{limit}  // 0;
    my $is_inflate = $method_args{inflate} ? 1 : 0;
    die "[AMBERDB_ERROR] 'table' parameter required for read_all\n" unless defined $table && length $table;

    if ( !is_db_ready() || !table_file_exists($table) ) {
        my $res = normalize_list_result( $limit, $is_inflate );
        output_result( $res, $opt_format, $table );
        exit 0;
    }

    my @results = $adb->read_all( $table, $offset, $limit, %method_args );
    my $res = normalize_list_result( $limit, $is_inflate, @results );
    output_result( $res, $opt_format, $table );
    exit 0;
}

# 4. READ_LIST
if ( $action eq 'read_list' ) {
    my $table = delete $method_args{table} // shift @pos_args;
    my $ids   = delete $method_args{ids}   // delete $method_args{id};
    $ids = [ split /,/, $ids ] if defined $ids && !ref $ids;
    $ids ||= \@pos_args;

    die "[AMBERDB_ERROR] 'table' parameter required for read_list\n" unless defined $table && length $table;
    die "[AMBERDB_ERROR] 'ids' parameter required for read_list\n" unless ref $ids eq 'ARRAY' && @$ids;

    if ( !is_db_ready() || !table_file_exists($table) ) {
        output_result( [], $opt_format, $table );
        exit 0;
    }

    my @recs = $adb->read_list( $table, $ids, \%method_args );
    output_result( \@recs, $opt_format, $table );
    exit 0;
}

# 5. FIELD_FETCH / FETCH
if ( $action eq 'field_fetch' || $action eq 'fetch' ) {
    my $table      = delete $method_args{table}  // shift @pos_args;
    my $block      = delete $method_args{block}  // shift @pos_args;
    my $fetch      = delete $method_args{fetch}  // delete $method_args{value} // shift @pos_args;

    if ( @pos_args >= 2 && $pos_args[0] =~ /^\d+$/ && $pos_args[1] =~ /^\d+$/ ) {
        $method_args{offset} //= parse_value(shift @pos_args);
        $method_args{limit}  //= parse_value(shift @pos_args);
    }
    elsif ( @pos_args == 1 && $pos_args[0] =~ /^\d+$/ ) {
        $method_args{limit} //= parse_value(shift @pos_args);
    }

    my $offset     = delete $method_args{offset} // 0;
    my $limit      = delete $method_args{limit}  // 0;
    my $is_inflate = $method_args{inflate} ? 1 : 0;

    die "[AMBERDB_ERROR] 'table', 'block', and 'fetch' parameters required for field_fetch\n"
      unless defined $table && defined $block && defined $fetch;

    if ( !is_db_ready() || !table_file_exists($table) ) {
        my $res = normalize_list_result( $limit, $is_inflate );
        output_result( $res, $opt_format, $table );
        exit 0;
    }

    my @results = $adb->field_fetch( $table, $block, $fetch, $offset, $limit, %method_args );
    my $res = normalize_list_result( $limit, $is_inflate, @results );
    output_result( $res, $opt_format, $table );
    exit 0;
}

# 6. SEARCH_TABLE / SEARCH
if ( $action eq 'search_table' || $action eq 'search' ) {
    my $table      = delete $method_args{table} // shift @pos_args;
    my $query      = delete $method_args{query} // delete $method_args{string} // delete $method_args{q} // shift @pos_args;

    if ( @pos_args && defined $pos_args[0] && $pos_args[0] =~ /^(?:and|or)$/i ) {
        $method_args{and_or} //= shift @pos_args;
    }

    if ( @pos_args >= 2 && $pos_args[0] =~ /^\d+$/ && $pos_args[1] =~ /^\d+$/ ) {
        $method_args{offset} //= parse_value(shift @pos_args);
        $method_args{limit}  //= parse_value(shift @pos_args);
    }
    elsif ( @pos_args == 1 && $pos_args[0] =~ /^\d+$/ ) {
        $method_args{limit} //= parse_value(shift @pos_args);
    }

    my $limit      = $method_args{limit} // 0;
    my $is_inflate = $method_args{inflate} ? 1 : 0;

    die "[AMBERDB_ERROR] 'table' and 'query' parameters required for search_table\n"
      unless defined $table && defined $query;

    if ( !is_db_ready() || !table_file_exists($table) ) {
        my $res = normalize_list_result( $limit, $is_inflate );
        output_result( $res, $opt_format, $table );
        exit 0;
    }

    my @results = $adb->search_table( $table, $query, %method_args );
    my $res = normalize_list_result( $limit, $is_inflate, @results );
    output_result( $res, $opt_format, $table );
    exit 0;
}

# 7. TABLE_COUNT / COUNT
if ( $action eq 'table_count' || $action eq 'count' ) {
    my $table = delete $method_args{table} // shift @pos_args;
    die "[AMBERDB_ERROR] 'table' parameter required for table_count\n" unless defined $table && length $table;

    if ( !is_db_ready() || !table_file_exists($table) ) {
        output_result( { table => $table, count => 0 }, $opt_format );
        exit 0;
    }

    my $cnt = $adb->table_count($table);
    output_result( { table => $table, count => $cnt }, $opt_format );
    exit 0;
}

# 8. TABLE_INFO / INFO
if ( $action eq 'table_info' || $action eq 'info' ) {
    my $table = delete $method_args{table} // shift @pos_args;
    die "[AMBERDB_ERROR] 'table' parameter required for table_info\n" unless defined $table && length $table;

    if ( !is_db_ready() || !table_file_exists($table) ) {
        if ( defined $opt_format && ( $opt_format eq 'json' || $opt_format eq 'pretty' ) ) {
            output_result( {}, $opt_format );
        }
        else {
            print "[AMBERDB] Table '$table' does not exist.\n";
        }
        exit 0;
    }

    my $info = $adb->table_info($table);
    if ( defined $opt_format && ( $opt_format eq 'json' || $opt_format eq 'pretty' || $opt_format eq 'raw' || $opt_format eq 'dumper' || $opt_format eq 'perl' ) ) {
        output_result( $info, $opt_format );
    }
    else {
        print "AmberDB Table Schema: $table\n";
        print "=" x 80, "\n";
        printf( "%-6s %-20s %-12s %-12s %-8s %-15s\n", "Block", "Field Name", "Type", "Index", "Search", "RDBM" );
        print "-" x 80, "\n";
        my $blocks = ( ref $info eq 'HASH' && ref $info->{blocks} eq 'ARRAY' ) ? $info->{blocks} : [];
        my $search_blocks = ( ref $info eq 'HASH' ) ? ( $info->{search_block} || [] ) : [];
        my %is_search = map { $_ => 1 } ( ref $search_blocks eq 'ARRAY' ? @$search_blocks : keys %$search_blocks );
        for my $i ( 0 .. $#$blocks ) {
            my $b = $blocks->[$i];
            my $bname = ref $b eq 'HASH' ? ( $b->{name} // "block_$i" ) : "block_$i";
            my $btype = ref $b eq 'HASH' ? ( $b->{type} // "string" ) : "string";
            my $bidx  = ref $b eq 'HASH' ? ( $b->{index} // "-" ) : "-";
            my $srch  = $is_search{$i} ? "yes" : "-";
            my $rdbm = "-";
            if ( ref $b eq 'HASH' && $b->{rdbm} ) {
                if ( ref $b->{rdbm} eq 'HASH' ) {
                    my $rt = $b->{rdbm}->{table} // '';
                    my $rb = $b->{rdbm}->{block} // '';
                    $rdbm = ( $rb ne '' ) ? "$rt,$rb" : $rt;
                }
                else {
                    $rdbm = $b->{rdbm};
                }
            }
            printf( "%-6s %-20s %-12s %-12s %-8s %-15s\n",
                $i,
                substr( $bname, 0, 19 ),
                substr( $btype, 0, 11 ),
                substr( $bidx,  0, 11 ),
                $srch,
                substr( $rdbm,  0, 14 )
            );
        }
        print "=" x 80, "\n";
        if ( ref $info eq 'HASH' ) {
            my @meta_attrs;
            for my $k ( sort keys %$info ) {
                next if $k eq 'blocks' || $k eq 'search_block';
                my $v = $info->{$k};
                push @meta_attrs, "$k=" . ( ref $v ? encode_json($v) : $v );
            }
            print "Attributes: " . join( ", ", @meta_attrs ) . "\n" if @meta_attrs;
        }
    }
    exit 0;
}

# 9. INSERT_ID / INSERT
if ( $action eq 'insert_id' || $action eq 'insert' ) {
    if ( $adb->config('no_write') ) {
        die "[AMBERDB_ERROR] no_write aktif: Bu oturumda yazma yetkisi kısıtlanmıştır!\n";
    }

    my $table = delete $method_args{table} // shift @pos_args;
    my $id    = delete $method_args{id};
    if ( !defined $id && @pos_args && $pos_args[0] =~ /^\d+$/ ) {
        $id = shift @pos_args;
    }
    $id //= 0;
    my $data  = delete $method_args{data};

    # Ensure database directory and skeleton exist on write
    my $db_dir = $adb->path('dbase_dir') || "dbstore";
    if ( !-d $db_dir || !-d "$db_dir/table" ) {
        make_path(
            "$db_dir/table", "$db_dir/schema", "$db_dir/journal",
            "$db_dir/lock",  "$db_dir/session", "$db_dir/config",
            "$db_dir/backup", "$db_dir/ramdisk"
        );
        my $conf_file = "$db_dir/config/core.conf";
        if ( !-f $conf_file && open my $cfh, '>', $conf_file ) {
            print $cfh "site_id        amberdb\nlanguage       tr\n";
            close $cfh;
        }
    }

    if ( !defined $data ) {
        $data = scalar keys %method_args ? \%method_args : [ map { parse_value($_) } @pos_args ];
    }
    elsif ( !ref $data ) {
        my $parsed = parse_value($data);
        $data = $parsed if ref $parsed;
    }

    die "[AMBERDB_ERROR] 'table' parameter required for insert\n" unless defined $table && length $table;

    if ($opt_dry_run) {
        output_result( { dry_run => 1, action => 'insert_id', table => $table, id => $id, data => $data }, $opt_format );
        exit 0;
    }

    my $res;
    if ( ref $data eq 'ARRAY' ) {
        $res = $adb->insert_id( $table, $id, @$data );
    }
    else {
        $res = $adb->insert_id( $table, $id, $data );
    }
    output_result( { status => 'ok', action => 'insert_id', table => $table, id => $res }, $opt_format );
    exit 0;
}

# 9b. UPDATE_STORAGE
if ( $action eq 'update_storage' ) {
    my %opts;
    $opts{target_dir} = $adb->path('dbase_dir');
    $opts{force}      = $opt_force if $opt_force;
    $opts{check}      = $method_args{check} if exists $method_args{check};
    $opts{no_backup}  = $method_args{no_backup} if exists $method_args{no_backup};
    $opts{tables}     = $method_args{tables} // $method_args{table} // ( @pos_args ? join(',', @pos_args) : undef );
    $opts{manifest}   = $method_args{manifest} if exists $method_args{manifest};

    my $res = $tools->update_storage(%opts);
    output_result( $res, $opt_format ) if defined $opt_format;
    exit 0;
}

# 9c. UPDATE_VERSION
if ( $action eq 'update_version' ) {
    my %opts;
    $opts{check} = $method_args{check} if exists $method_args{check};
    $opts{cpanm} = $method_args{cpanm} if exists $method_args{cpanm};

    my $res = $tools->update_version(%opts);
    output_result( $res, $opt_format ) if defined $opt_format;
    exit 0;
}

# 10. UPDATE_ID / UPDATE
if ( $action eq 'update_id' || $action eq 'update' ) {
    if ( $adb->config('no_write') ) {
        die "[AMBERDB_ERROR] no_write aktif: Bu oturumda yazma yetkisi kısıtlanmıştır!\n";
    }

    my $table = delete $method_args{table} // shift @pos_args;
    my $id    = delete $method_args{id}    // shift @pos_args;
    my $data  = delete $method_args{data};

    if ( !defined $data ) {
        $data = scalar keys %method_args ? \%method_args : [ map { parse_value($_) } @pos_args ];
    }
    elsif ( !ref $data ) {
        my $parsed = parse_value($data);
        $data = $parsed if ref $parsed;
    }

    die "[AMBERDB_ERROR] 'table' and 'id' parameters required for update\n"
      unless defined $table && defined $id && length $id;

    if ( !is_db_ready() || !table_file_exists($table) ) {
        die "[AMBERDB_ERROR] Table '$table' does not exist.\n";
    }

    if ($opt_dry_run) {
        output_result( { dry_run => 1, action => 'update_id', table => $table, id => $id, data => $data }, $opt_format );
        exit 0;
    }

    my $res;
    if ( ref $data eq 'ARRAY' ) {
        $res = $adb->update_id( $table, $id, @$data );
    }
    else {
        $res = $adb->update_id( $table, $id, $data );
    }
    output_result( { status => ( $res ? 'ok' : 'error' ), action => 'update_id', table => $table, id => $id, result => ( $res ? 1 : 0 ) }, $opt_format );
    exit 0;
}

# 11. DELETE_ID / DELETE
if ( $action eq 'delete_id' || $action eq 'delete' ) {
    if ( $adb->config('no_write') ) {
        die "[AMBERDB_ERROR] no_write aktif: Bu oturumda yazma yetkisi kısıtlanmıştır!\n";
    }

    my $table = delete $method_args{table} // shift @pos_args;
    my $id    = delete $method_args{id}    // shift @pos_args;

    die "[AMBERDB_ERROR] 'table' and 'id' parameters required for delete_id\n"
      unless defined $table && defined $id && length $id;

    if ( !is_db_ready() || !table_file_exists($table) ) {
        output_result( { status => 'not_found', table => $table, id => $id, result => 0 }, $opt_format );
        exit 0;
    }

    if ($opt_dry_run) {
        output_result( { dry_run => 1, action => 'delete_id', table => $table, id => $id }, $opt_format );
        exit 0;
    }

    my $res = $adb->delete_id( $table, $id );
    output_result( { status => ( $res ? 'ok' : 'not_found' ), action => 'delete_id', table => $table, id => $id, result => ( $res ? 1 : 0 ) }, $opt_format );
    exit 0;
}

# 12. TOOLS: REINDEX
if ( $action eq 'reindex' ) {
    my $table = delete $method_args{table} // shift @pos_args;
    my $all   = delete $method_args{all}   // 0;

    if ( $all || !$table ) {
        my $ok = $tools->index_alltables();
        output_result( { status => ( $ok ? 'ok' : 'error' ), action => 'reindex_all', log => $tools->{say} }, $opt_format );
    }
    else {
        my $ok = $tools->set_index($table);
        output_result( { status => ( $ok ? 'ok' : 'error' ), action => 'reindex', table => $table, log => $tools->{say} }, $opt_format );
    }
    exit 0;
}

# 13. TOOLS: CHECK
if ( $action eq 'check' ) {
    my $table = delete $method_args{table} // shift @pos_args;
    die "[AMBERDB_ERROR] 'table' parameter required for check\n" unless defined $table && length $table;

    my $r_ok = $tools->check_readall($table);
    my $s_ok = $tools->check_search($table);
    output_result( { status => 'ok', table => $table, check_readall => $r_ok, check_search => $s_ok }, $opt_format );
    exit 0;
}

# 14. TOOLS: VACUUM
if ( $action eq 'vacuum' ) {
    if ( $adb->config('no_write') ) {
        die "[AMBERDB_ERROR] no_write aktif: Bu oturumda yazma/vacuum yetkisi kısıtlanmıştır!\n";
    }
    my $table = delete $method_args{table} // shift @pos_args;
    die "[AMBERDB_ERROR] 'table' parameter required for vacuum\n" unless defined $table && length $table;

    my $ok = $tools->vacuum($table);
    output_result( { status => ( $ok ? 'ok' : 'error' ), action => 'vacuum', table => $table }, $opt_format );
    exit 0;
}

# 15. TOOLS: MIGRATE / UPDATE_TABLE
if ( $action eq 'migrate' || $action eq 'update_table' ) {
    if ( $adb->config('no_write') ) {
        die "[AMBERDB_ERROR] no_write aktif: Bu oturumda yazma/migrate yetkisi kısıtlanmıştır!\n";
    }
    my $table = delete $method_args{table} // shift @pos_args;
    die "[AMBERDB_ERROR] 'table' parameter required for migrate\n" unless defined $table && length $table;

    my $ok = $tools->update_table( $table, %method_args );
    output_result( { status => ( $ok ? 'ok' : 'error' ), action => 'migrate', table => $table, log => $tools->{say} }, $opt_format );
    exit 0;
}

# 16. TOOLS: EXPORT / TIE2CSV
if ( $action eq 'export' || $action eq 'tie2csv' ) {
    my $table = delete $method_args{table} // shift @pos_args;
    my $file  = delete $method_args{file}  // shift @pos_args;
    die "[AMBERDB_ERROR] 'table' and 'file' parameters required for export\n"
      unless defined $table && defined $file;

    my $ok = $tools->tie2csv( $table, $file );
    output_result( { status => ( $ok ? 'ok' : 'error' ), action => 'export', table => $table, file => $file }, $opt_format );
    exit 0;
}

# 17. TOOLS: IMPORT / CSV2TIE
if ( $action eq 'import' || $action eq 'csv2tie' ) {
    if ( $adb->config('no_write') ) {
        die "[AMBERDB_ERROR] no_write aktif: Bu oturumda yazma/import yetkisi kısıtlanmıştır!\n";
    }
    my $table = delete $method_args{table} // shift @pos_args;
    my $file  = delete $method_args{file}  // shift @pos_args;
    die "[AMBERDB_ERROR] 'table' and 'file' parameters required for import\n"
      unless defined $table && defined $file;

    my $ok = $tools->csv2tie( $table, $file );
    output_result( { status => ( $ok ? 'ok' : 'error' ), action => 'import', table => $table, file => $file }, $opt_format );
    exit 0;
}

# 18. TOOLS: DUMP
if ( $action eq 'dump' ) {
    my $table = delete $method_args{table} // shift @pos_args;
    my $file  = delete $method_args{file};
    my $ok    = $tools->dump( $table, ( $file ? ( file => $file ) : () ), %method_args );
    output_result( { status => ( $ok ? 'ok' : 'error' ), action => 'dump', table => $table, log => $tools->{say} }, $opt_format );
    exit 0;
}

# 19. TOOLS: RESTORE
if ( $action eq 'restore' ) {
    if ( $adb->config('no_write') ) {
        die "[AMBERDB_ERROR] no_write aktif: Bu oturumda yazma/restore yetkisi kısıtlanmıştır!\n";
    }
    my $file = delete $method_args{file} // shift @pos_args;
    die "[AMBERDB_ERROR] 'file' parameter required for restore\n" unless defined $file;

    my $ok = $tools->restore( $file, %method_args );
    output_result( { status => ( $ok ? 'ok' : 'error' ), action => 'restore', file => $file, log => $tools->{say} }, $opt_format );
    exit 0;
}

# 20. TOOLS: RENAME
if ( $action eq 'rename' ) {
    if ( $adb->config('no_write') ) {
        die "[AMBERDB_ERROR] no_write aktif: Bu oturumda yazma/rename yetkisi kısıtlanmıştır!\n";
    }
    my $from = delete $method_args{from} // shift @pos_args;
    my $to   = delete $method_args{to}   // shift @pos_args;
    die "[AMBERDB_ERROR] 'from' and 'to' parameters required for rename\n" unless defined $from && defined $to;

    my $ok = $tools->replace_tablename( $from, $to );
    output_result( { status => ( $ok ? 'ok' : 'error' ), action => 'rename', from => $from, to => $to, log => $tools->{say} }, $opt_format );
    exit 0;
}

# 21. TOOLS: DROP
if ( $action eq 'drop' ) {
    if ( $adb->config('no_write') ) {
        die "[AMBERDB_ERROR] no_write aktif: Bu oturumda yazma/drop yetkisi kısıtlanmıştır!\n";
    }
    my $table = delete $method_args{table} // shift @pos_args;
    die "[AMBERDB_ERROR] 'table' parameter required for drop\n" unless defined $table && length $table;

    unless ($opt_force) {
        if ( -t STDIN ) {
            print "\n[UYARI] '$table' tablosu ve ilişkili tüm indeksler kalıcı olarak silinecek!\n";
            print "Onaylamak için tablo adını ('$table') yazın: ";
            my $confirm = <STDIN>;
            chomp($confirm) if defined $confirm;
            if ( !defined $confirm || $confirm ne $table ) {
                print "[AMBERDB] Tablo silme işlemi iptal edildi.\n";
                exit 0;
            }
        }
        else {
            die "[AMBERDB_ERROR] Table drop requires 'force=1' or '--force' flag for safety.\n";
        }
    }

    my $ok = $tools->del_table($table);
    output_result( { status => ( $ok ? 'ok' : 'error' ), action => 'drop', table => $table }, $opt_format );
    exit 0;
}

# ============================================================================
# GENERIC DYNAMIC DISPATCH FALLBACK ($adb->$action or $tools->$action)
# ============================================================================

if ( $adb->can($action) ) {
    my $res = eval { $adb->$action( @pos_args, %method_args ) };
    if ($@) {
        die "[AMBERDB_ERROR] Execution of \$adb->$action failed: $@\n";
    }
    output_result( $res, $opt_format );
    exit 0;
}

if ( $tools->can($action) ) {
    my $res = eval { $tools->$action( @pos_args, %method_args ) };
    if ($@) {
        die "[AMBERDB_ERROR] Execution of \$tools->$action failed: $@\n";
    }
    output_result( $res, $opt_format );
    exit 0;
}

die "[AMBERDB_ERROR] Unknown action or method '$action'. Use 'help' to view available commands.\n";

END {
    return unless $opt_time;
    return if $opt_help;
    return if defined $? && $? != 0;
    my $elapsed = eval { tv_interval($t0) } // 0;
    my $time_str = sprintf( "%.4fs (%.2f ms)", $elapsed, $elapsed * 1000 );
    print "[Time: $time_str]\n";
}

__END__

=encoding utf8

=head1 NAME

amberdb_cli.pl - High-performance Command-Line Console & Embedded Management Utility for AmberDB

=head1 SYNOPSIS

  # 1. Overview Dashboard (lists all tables, records, size, engine status)
  perl bin/amberdb_cli.pl
  perl bin/amberdb_cli.pl format=json

  # 2. Token-Based Session Lifecycle (Connect, Configure & Disconnect)
  perl bin/amberdb_cli.pl connect mydatabase cfg-language=tr
  perl bin/amberdb_cli.pl token=K2A78T02 cfg-no_write=1
  perl bin/amberdb_cli.pl token=K2A78T02 disconnect

  # 3. Dynamic In-Memory Schema Customization (table_attr)
  perl bin/amberdb_cli.pl token=K2A78T02 action=table_attr table=products keep_deleted=1 search_block=[2,3,6]

  # 4. CRUD & Query Operations
  perl bin/amberdb_cli.pl token=K2A78T02 action=read_id table=users id=10
  perl bin/amberdb_cli.pl token=K2A78T02 action=read_all table=products offset=0 limit=20 dir=asc
  perl bin/amberdb_cli.pl token=K2A78T02 action=read_list table=users ids=1,2,5,10
  perl bin/amberdb_cli.pl token=K2A78T02 action=search_table table=products query="laptop" limit=10
  perl bin/amberdb_cli.pl token=K2A78T02 action=insert_id table=users id=0 data='{"name":"Ahmet","status":1}'
  perl bin/amberdb_cli.pl token=K2A78T02 action=update_id table=users id=10 data='{"status":2}'
  perl bin/amberdb_cli.pl token=K2A78T02 action=delete_id table=users id=10

  # 5. Maintenance, Indexing & Disaster Recovery
  perl bin/amberdb_cli.pl token=K2A78T02 action=reindex table=products
  perl bin/amberdb_cli.pl token=K2A78T02 action=check table=products
  perl bin/amberdb_cli.pl token=K2A78T02 action=vacuum table=products
  perl bin/amberdb_cli.pl token=K2A78T02 action=export table=products file=products.csv
  perl bin/amberdb_cli.pl token=K2A78T02 action=import table=products file=products.csv
  perl bin/amberdb_cli.pl token=K2A78T02 action=drop table=temp_products force=1

=head1 DESCRIPTION

C<amberdb_cli.pl> is a direct file-based command-line console and administrative utility for C<AmberDB>. It bypasses network daemon overhead, operating directly upon native database files (C<.db>, C<.inx>, C<.fld>, C<.src>, C<.fac>) at microsecond embedded speeds.

Key capabilities include:

=over 4

=item * B<Interactive & Non-Interactive Dashboard:> Running with no arguments renders an overview of all database tables, record counts, file sizes, and storage directories.

=item * B<Token-Based Session Persistence:> State, paths, language codes, safety flags, and runtime schema mutations (C<table_attr>) persist across terminal invocations via short session tokens (stored under C<.amberdb_sessions/>).

=item * B<Full CRUD Suite:> Supports positional or key-value record reading, pagination (C<offset>/C<limit>), full-text phonetic search, and bulk operations.

=item * B<Maintenance & Utilities:> Native disaster recovery archiving (C<dump>/C<restore>), CSV export/import, binary index rebuilding (C<reindex>), database compacting (C<vacuum>), and schema inspection.

=item * B<Dynamic Method Reflection:> Any method supported by C<AmberDB> or C<AmberDB::Tools> can be dispatched dynamically via C<action=E<lt>methodE<gt>>.

=back

=head1 SESSIONS & ARGUMENT CONVENTIONS

=head2 Argument Formats

Arguments can be passed flexibly using standard shell key-value syntax:

=over 4

=item * Key-value pairs: C<table=products>, C<id=10>, C<action=read_id>

=item * Option dashes: C<--table=products>, C<-table=products>, C<table:products>

=item * Nested path/config values: C<path-dbase_dir=./dbstore>, C<cfg-language=tr>, C<cfg-no_write=1>

=back

=head2 Session Lifecycle

=over 4

=item * B<connect:> Generates a new 8-character token and saves database configuration. Automatically persists to C<cli_last_token> so subsequent commands can omit C<token=...>.

=item * B<token=TOKEN:> Reuses an existing session state and its registered table attributes.

=item * B<disconnect:> Closes and purges the active session file.

=back

=head1 ACTIONS

=head2 Inspection & Dashboard

=over 4

=item * B<overview / list:> Displays table summary table (name, record count, byte size, index status).

=item * B<table_info:> Inspects table schema definitions, metadata, and block configurations.

=item * B<table_attr:> Dynamically updates or queries in-memory schema attributes (e.g. C<search_block>, C<keep_deleted>, RDBM relationships).

=back

=head2 CRUD & Queries

=over 4

=item * B<read_id:> Reads a single record by primary key ID in $O(1)$ time.

=item * B<read_all:> Scans and streams active records with support for pagination, sorting (C<dir=asc|desc>), and range filtering.

=item * B<read_list:> Bulk fetches records by a comma-separated list of IDs (C<ids=1,2,5>).

=item * B<search_table:> Full-text search matching query keywords with phonetic and accent normalization.

=item * B<insert_id:> Inserts a new record. Supports JSON format (C<data='{...}'>) or positional fields. Pass C<id=0> for auto-increment.

=item * B<update_id:> Modifies an existing record by ID.

=item * B<delete_id:> Deletes a record by ID (honors C<keep_deleted> audit archive if enabled).

=back

=head2 Maintenance & Administration

=over 4

=item * B<reindex:> Rebuilds all derived binary indexes (C<.inx>, C<.fld>, C<.src>, C<.fac>, C<.unq>, C<.slg>) via C<AmberDB::Tools>.

=item * B<check:> Validates physical table integrity and reports corruption or key anomalies.

=item * B<vacuum:> Reorganizes and compacts Berkeley DB storage files, reclaiming free space.

=item * B<export / import:> High-speed CSV data export and import.

=item * B<dump / restore:> Full portable compressed database archive management (C<.amberdb>).

=item * B<drop:> Deletes a physical table and all secondary indexes. Requires C<force=1> for safety.

=back

=head1 OUTPUT FORMATS

The output format can be controlled using C<format=E<lt>typeE<gt>>:

=over 4

=item * C<table:> (Default) Human-readable ASCII terminal table.

=item * C<json:> Machine-readable JSON output, ideal for shell pipelines, Web UIs, and external scripts.

=item * C<raw:> Direct Perl Data::Dumper serialization.

=back

=head1 SEE ALSO

L<AmberDB>, L<AmberDB::Tools>, L<amberdb_setup.pl>

Official Wiki: L<https://github.com/marufcetin/amberdb/wiki/Guide-CLI>

=head1 AUTHOR

Maruf Cetin <marufcetin@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2018-2026 Maruf Cetin.

This library is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0.

=cut
