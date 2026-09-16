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

our $adb = AmberDB->new( path => { dbase_dir => 'dbstore' }, connect => { username => 'cli' } );
our $tools = AmberDB::Tools->new($adb);

# ============================================================================
# SESSION REGISTRY (.amberdb/session/)
# Stores session files per active session under .amberdb/session/sess_$token
# in the current working directory where CLI is executed.
# ============================================================================

our $CLI_SESS_DIR = ".amberdb/session";

sub cli_session_file {
    my ($token) = @_;
    return '' unless $token;
    return "$CLI_SESS_DIR/sess_$token";
}

sub get_session_path {
    my ($token) = @_;
    $token //= '';

    # 1. If token is provided, check .amberdb/session/sess_$token
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

    my $file = cli_session_file($token);
    if ( open my $fh, '>', $file ) {
        if ($sess_data) {
            print $fh encode_json($sess_data);
        }
        else {
            print $fh encode_json( {
                token => $token,
                path  => { dbase_dir => $db_path },
            } );
        }
        close $fh;
    }
}

sub del_session_path {
    my ($token) = @_;
    return unless defined $token && length $token;

    # Delete .amberdb/session/sess_$token
    my $file = cli_session_file($token);
    unlink $file if defined $file && -f $file;
}

# ============================================================================
# RESOLVE DBASE_DIR FROM CLI ARGUMENTS
# 1- Connect'ten sonraki string: amberdb connect /path/to/dbstore
# 2- Argümanlı: --db=dbstore veya --dbase_dir=/path/to
# 3- Oturum token'ı varsa: .amberdb_cli_sessions içinden dbase_dir tespit et
# Argümandan gelmiyorsa: bulunduğu dizinde dbstore oluşturur.
# ============================================================================

my $target_db;
my $from_cli_args = 0;

# 1. Connect'ten sonraki string (örn: amberdb connect /path/to/dbstore)
for (my $i = 0; $i < @ARGV; $i++) {
    my $arg = $ARGV[$i];
    if ( $arg =~ /^--?(?:action=)?connect$/i ) {
        for (my $j = $i + 1; $j < @ARGV; $j++) {
            my $next = $ARGV[$j];
            next if $next =~ /^-/;
            next if $next =~ /=/;
            next if $next =~ /^(?:json|pretty|tsv|dumper|perl|raw|table|time)$/i;
            $target_db = $next;
            $from_cli_args = 1;
            last;
        }
        last;
    }
}

# 2. Argümanlı: --db=dbstore veya --dbase_dir=/path/to (ayrıca -d, db=, path-dbase_dir=)
if ( !defined $target_db ) {
    for (my $i = 0; $i < @ARGV; $i++) {
        my $arg = $ARGV[$i];
        if ( $arg =~ /^--(?:db|dbase_dir)=(.*)$/i || $arg =~ /^(?:path-dbase_dir|db)=(.*)$/i ) {
            $target_db = $1 if defined $1 && length $1;
            $from_cli_args = 1;
            last;
        }
        elsif ( ( $arg =~ /^--(?:db|dbase_dir)$/i || $arg =~ /^-d$/i ) && $i + 1 < @ARGV && $ARGV[$i + 1] !~ /^-/ ) {
            $target_db = $ARGV[$i + 1];
            $from_cli_args = 1;
            last;
        }
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

# 4. Argümandan gelmiyorsa: bulunduğu dizinde dbstore oluşturur
if ( !defined $target_db || !length $target_db ) {
    $target_db = "dbstore";
    make_path($target_db) unless -d $target_db;
}
else {
    make_path($target_db) unless -d $target_db;
}
$target_db = eval { abs_path($target_db) } // $target_db;

# şimdi datadiri atama yap
$adb->set_datadir($target_db);

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
    if ($allow_last_token) {
        # Check active session in .amberdb/session/sess_* by mtime
        my ($latest_tok) = get_session_path();
        return $latest_tok if defined $latest_tok && length $latest_tok;
    }
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

sub output_result {
    my ( $data, $format ) = @_;
    $format = lc( $format // '' );

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
        if ( ref $data eq 'ARRAY' ) {
            if ( @$data && ref $data->[0] eq 'HASH' ) {
                my @cols = sort keys %{ $data->[0] };
                print join( "\t", @cols ), "\n";
                for my $row (@$data) {
                    print join( "\t", map { defined $row->{$_} ? ( ref $row->{$_} ? encode_json( $row->{$_} ) : $row->{$_} ) : "" } @cols ), "\n";
                }
            }
            else {
                for my $item (@$data) {
                    print( ( ref $item ? encode_json($item) : ( $item // "" ) ), "\n" );
                }
            }
        }
        elsif ( ref $data eq 'HASH' ) {
            for my $k ( sort keys %$data ) {
                my $v = $data->{$k};
                print "$k\t" . ( ref $v ? encode_json($v) : ( $v // "" ) ) . "\n";
            }
        }
        else {
            print( ( $data // "" ), "\n" );
        }
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
                if ( ref $recs->[0] eq 'HASH' ) {
                    my @keys = sort keys %{ $recs->[0] };
                    print join( " | ", map { sprintf( "%-15s", $_ ) } @keys ), "\n";
                    print "-" x ( 18 * scalar(@keys) ), "\n";
                    for my $r (@$recs) {
                        print join( " | ", map { sprintf( "%-15s", substr( ref $r->{$_} ? encode_json( $r->{$_} ) : ( $r->{$_} // "" ), 0, 15 ) ) } @keys ), "\n";
                    }
                }
                else {
                    for my $r (@$recs) {
                        print Dumper($r);
                    }
                }
            }
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
        if ( @$data && ref $data->[0] eq 'HASH' ) {
            my @keys = sort keys %{ $data->[0] };
            print join( " | ", map { sprintf( "%-15s", $_ ) } @keys ), "\n";
            print "-" x ( 18 * scalar(@keys) ), "\n";
            for my $r (@$data) {
                print join( " | ", map { sprintf( "%-15s", substr( ref $r->{$_} ? encode_json( $r->{$_} ) : ( $r->{$_} // "" ), 0, 15 ) ) } @keys ), "\n";
            }
        }
        else {
            print Dumper($data);
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
our $opt_help   = 0;
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
    else {
        push @raw_tokens, $curr;
    }
    $arg_idx++;
}

# Step 2: Known action definitions
my %known_actions = map { $_ => 1 } qw(
    connect disconnect path config cfg attr table_attr user users
    status tables list info table_info read read_id read_all read_list
    search search_table fetch field_fetch count table_count
    insert insert_id update update_id delete delete_id
    reindex check vacuum migrate update_table
    export tie2csv import csv2tie dump restore rename drop help
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
        elsif ( $k =~ /^(?:help|h)$/ ) {
            $opt_help = 1;
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
        if ( $arg =~ /^(?:help|h)$/i ) {
            $opt_help = 1;
        }
        elsif ( $arg =~ /^(?:dry-run|dry_run)$/i ) {
            $opt_dry_run = 1;
        }
        elsif ( $arg =~ /^(?:force|f)$/i ) {
            $opt_force = 1;
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
    $opt_action = 'status'      if $act eq 'tables' || $act eq 'list';
    $opt_action = 'user'        if $act eq 'users';
    $opt_action = 'config'      if $act eq 'cfg';
    $opt_action = 'attr'        if $act eq 'table_attr';
    $opt_action = 'info'        if $act eq 'table_info';
    $opt_action = 'search'      if $act eq 'search_table';
    $opt_action = 'fetch'       if $act eq 'field_fetch';
    $opt_action = 'count'       if $act eq 'table_count';
    $opt_action = 'insert'      if $act eq 'insert_id';
    $opt_action = 'update'      if $act eq 'update_id';
    $opt_action = 'delete'      if $act eq 'delete_id';
    $opt_action = 'migrate'     if $act eq 'update_table';
    $opt_action = 'export'      if $act eq 'tie2csv';
    $opt_action = 'import'      if $act eq 'csv2tie';
    $opt_action = 'reindex'     if $act eq 'set_index';
    $opt_action = 'vacuum'      if $act eq 'vacuum';
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
    print <<"USAGE";
AmberDB CLI v$AmberDB::VERSION - Embedded Database Console & Management Tool

Kullanım:
  amberdb [token] <komut> [parametreler...] [anahtar=değer...]

Doğrudan (Oturumsuz) Kullanım:
  amberdb read products 10                    # ID ile tekil kayıt okuma
  amberdb read products 10 inflate=1 json     # Şema genişletmeli JSON okuma
  amberdb read products all 0 20 keys_only=1  # Sayfalamalı ve sıralı okuma
  amberdb search products "kulaklık" limit=10 # Tam metin ve fonetik arama
  amberdb fetch orders 2 completed            # Blok alan değeri filtreleme
  amberdb info products                       # Tablo şema yapısını listeleme
  amberdb count products                      # Toplam kayıt sayısı
  amberdb tables                              # Tüm tabloların durum panosu

Oturum Komutları (Session Management):
  amberdb connect path-dbase_dir=dbstore      # Oturum açar (örn: Token 1245)
  amberdb 1245 attr products search_block=[1] # Oturumda tablo şema niteliklerini belirleme
  amberdb 1245 config no_write=1              # Oturumda salt-okunur mod
  amberdb 1245 path dbase_dir=/var/data       # Oturum veri dizinini değiştirme
  amberdb 1245 disconnect                     # Oturumu sonlandırır

Veri Eylemleri (CRUD & Arama):
  amberdb insert users 0 data='{"name":"Ali"}'
  amberdb update users 10 data='{"role":"admin"}'
  amberdb delete users 10

Bakım ve Yönetim Eylemleri:
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
  --format=table|json|pretty|tsv|dumper       Çıktı biçimi (veya sonda: json, dumper)
  --db=/path/to/dbstore                       Oturumsuz doğrudan veritabanı yolu
  --token=TOKEN                               Aktif oturum anahtarı
  --time, time, time=1                        İşlem süresini en altta satır olarak yazar
  --dry-run                                   İşlemi uygulamadan simüle eder
  --force                                     Silme eylemleri için zorunlu onay
USAGE
    exit 0;
}

if ( $opt_help || ( defined $opt_action && $opt_action eq 'help' ) ) {
    $opt_help = 1;
    show_usage();
}

# ============================================================================
# LIFECYCLE: CONNECT & DISCONNECT
# ============================================================================

if ( defined $opt_action && $opt_action eq 'connect' ) {
    if ( @pos_args ) {
        my $first = $pos_args[0];
        if ( -d $first || $first =~ m{[/\\\\]} || ( defined $target_db && ( $first eq $target_db || ( eval { abs_path($first) } // '' ) eq ( eval { abs_path($target_db) } // '' ) ) ) ) {
            my $target = shift @pos_args;
            if ( defined $target && length $target && $target !~ /^format=/i ) {
                my $abs = eval { abs_path($target) } // $target;
                make_path($abs) unless -d $abs;
                $adb->set_datadir($abs);
                $explicit_db = 1;
            }
        }
        elsif ( @pos_args >= 3 && !defined $opt_database && !defined $opt_user ) {
            # Positional format: amberdb connect dir db user pass
            my $target = shift @pos_args;
            if ( defined $target && length $target && $target !~ /^format=/i ) {
                my $abs = eval { abs_path($target) } // $target;
                make_path($abs) unless -d $abs;
                $adb->set_datadir($abs);
                $explicit_db = 1;
            }
        }
    }

    my $conn_db   = $opt_database // shift @pos_args;
    # Even if username is entered differently, CLI always operates and authenticates as 'cli'
    my $conn_user = 'cli';
    my $entered_user = shift @pos_args if @pos_args;
    my $conn_pass = $opt_pass // shift @pos_args // '';

    my $token = eval {
        $adb->connect(
            ( defined $conn_db && length $conn_db ? ( database => $conn_db ) : () ),
            username => $conn_user,
            ( defined $conn_pass                  ? ( password => $conn_pass ) : () ),
        );
    };
    if ( $@ || !$token ) {
        my $err = $@ || $adb->last_error() || "Authentication failed";
        $err =~ s/ at .* line \d+.*//s;
        die "[AMBERDB_ERROR] $err\n";
    }

    my $actual_file = session_file($token);

    if ( defined $opt_format && $opt_format eq 'json' ) {
        print encode_json( {
            status       => 'connected',
            token        => $token,
            session_file => $actual_file,
            database     => $adb->connect('database'),
            username     => $adb->connect('username'),
            path         => $adb->path(),
            cfg          => $adb->config(),
        } ), "\n";
    }
    else {
        print "[AMBERDB] Connected successfully.\n";
        print "Session Token : $token\n";
        print "Session File  : $actual_file\n";
        print "Database      : " . ($adb->connect('database') || '') . "\n";
        print "User          : " . ($adb->connect('username') || '') . "\n";
        print "Data Dir      : " . $adb->path('dbase_dir') . "\n";
        print "Config        : " . encode_json( $adb->config() ) . "\n" if %{ $adb->config() };
        print "To use in shell:\n";
        print "  export AMBERDB_TOKEN=$token\n";
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
# DEFAULT ACTION: DASHBOARD OVERVIEW (ALL TABLES)
# ============================================================================

if ( !defined $opt_action || $opt_action eq '' || $opt_action eq 'list' || $opt_action eq 'status' || $opt_action eq 'tables' ) {
    my @tables = $tools->all_tables();
    my @rows;
    my $total_records = 0;
    my $total_bytes   = 0;

    my $db_dir = $adb->path('dbase_dir') || ".";

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
    output_result( $res, $opt_format );
    exit 0;
}

# 3. READ_ALL
if ( $action eq 'read_all' ) {
    my $table      = delete $method_args{table}  // shift @pos_args;
    my $offset     = delete $method_args{offset} // 0;
    my $limit      = delete $method_args{limit}  // 0;
    my $is_inflate = $method_args{inflate} ? 1 : 0;
    die "[AMBERDB_ERROR] 'table' parameter required for read_all\n" unless defined $table && length $table;

    my @results = $adb->read_all( $table, $offset, $limit, %method_args );
    my $res = normalize_list_result( $limit, $is_inflate, @results );
    output_result( $res, $opt_format );
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

    my @recs = $adb->read_list( $table, $ids, \%method_args );
    output_result( \@recs, $opt_format );
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

    my @results = $adb->field_fetch( $table, $block, $fetch, $offset, $limit, %method_args );
    my $res = normalize_list_result( $limit, $is_inflate, @results );
    output_result( $res, $opt_format );
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

    my @results = $adb->search_table( $table, $query, %method_args );
    my $res = normalize_list_result( $limit, $is_inflate, @results );
    output_result( $res, $opt_format );
    exit 0;
}

# 7. TABLE_COUNT / COUNT
if ( $action eq 'table_count' || $action eq 'count' ) {
    my $table = delete $method_args{table} // shift @pos_args;
    die "[AMBERDB_ERROR] 'table' parameter required for table_count\n" unless defined $table && length $table;

    my $cnt = $adb->table_count($table);
    output_result( { table => $table, count => $cnt }, $opt_format );
    exit 0;
}

# 8. TABLE_INFO / INFO
if ( $action eq 'table_info' || $action eq 'info' ) {
    my $table = delete $method_args{table} // shift @pos_args;
    die "[AMBERDB_ERROR] 'table' parameter required for table_info\n" unless defined $table && length $table;

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
    my $id    = delete $method_args{id}    // 0;
    my $data  = delete $method_args{data};

    if ( !defined $data ) {
        $data = scalar keys %method_args ? \%method_args : \@pos_args;
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

# 10. UPDATE_ID / UPDATE
if ( $action eq 'update_id' || $action eq 'update' ) {
    if ( $adb->config('no_write') ) {
        die "[AMBERDB_ERROR] no_write aktif: Bu oturumda yazma yetkisi kısıtlanmıştır!\n";
    }

    my $table = delete $method_args{table} // shift @pos_args;
    my $id    = delete $method_args{id}    // shift @pos_args;
    my $data  = delete $method_args{data};

    if ( !defined $data ) {
        $data = scalar keys %method_args ? \%method_args : \@pos_args;
    }
    elsif ( !ref $data ) {
        my $parsed = parse_value($data);
        $data = $parsed if ref $parsed;
    }

    die "[AMBERDB_ERROR] 'table' and 'id' parameters required for update\n"
      unless defined $table && defined $id && length $id;

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
    output_result( { status => 'ok', action => 'update_id', table => $table, id => $id, result => $res }, $opt_format );
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

    if ($opt_dry_run) {
        output_result( { dry_run => 1, action => 'delete_id', table => $table, id => $id }, $opt_format );
        exit 0;
    }

    my $res = $adb->delete_id( $table, $id );
    output_result( { status => 'ok', action => 'delete_id', table => $table, id => $id, result => $res }, $opt_format );
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
  perl bin/amberdb_cli.pl connect path-dbase_dir=./dbstore cfg-language=tr
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
