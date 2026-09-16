package AmberDB::Base;

use 5.016;
use warnings;
use Encode qw(is_utf8 encode decode);
use Carp qw(croak cluck);
use File::Spec;
use Fcntl qw(:DEFAULT :flock);
use Digest::SHA qw(sha256_hex);
use parent qw(AmberDB::Locale AmberDB::Array);

our $VERSION = '5.25.2';
my $CREATED = '2014-12-20';

# ------------------------------------------------
sub new {
    my $class = shift;
    my %args  = ( ref $_[0] eq 'HASH' ) ? %{ $_[0] } : @_;

    # Initialise the Language engine with the supplied language tag.
    # SUPER::new is AmberDB::Locale::new — it handles locale loading.
    my $self = $class->SUPER::new(%args);
    return $self;
}

# ============================================================================
# STRING UTILITIES (Trim & Whitespace Normalization)
# ============================================================================

# $adb->trim_space($string, [$flatten])
# Strips leading/trailing whitespace and normalizes internal spaces/newlines.
# ---------------------------------------------------------------------
sub trim_space {
    my ( $self, $string, $flatten ) = @_;

    return '' unless defined $string && length $string;

    $string =~ s/ / /g;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    $string =~ s/\r\n/\n/g;

    if ($flatten) {
        $string =~ s/[\r\n\t\s]+/ /g;
        $string =~ s/ *([,;]) */$1/g;
        $string =~ s/^\s+//;
        $string =~ s/\s+$//;
    }
    else {
        $string =~ s/\n/\\n/g;
        $string =~ s/\t/\\t/g;
        $string =~ s/\s+/ /g;
        $string =~ s/ *([,;]) */$1/g;
        $string =~ s/ *\\n */\n/g;
        $string =~ s/ *\\t */\t/g;
    }

    return $string;
}

# $data = $adb->set_charset($from, $to, $data);
# Converts between character encoding tables...
# ------------------------------------------------
sub set_charset {
    my ( $self, $from, $to, $data ) = @_;

    ( $from && $to && $data ) or return;

    return $data if ( $to eq "utf8" && utf8::is_utf8($data) );
    return encode( $to, decode( $from, $data ) );
}

# Extracts search words from string...
# my %words = $self->get_words($string);
# my %words = $self->get_words($string, $write, $table);
# ------------------------------------------------
sub get_words {
    my ( $self, $string, $action, $table ) = @_;

    $string or return;

    if ( ref($string) eq 'ARRAY' ) {
        $string = join " ", @$string;
    }

    my $is_write = ( $action && ( $action eq "write" || $action eq "1" ) ) ? 1 : 0;

    # 1. En basta kelimeleri split et
    my @tokens = split /\s+/, $string;
    return () unless @tokens;

    my %words;
    my ( $minchar, %jump, $has_meta );

    foreach my $str (@tokens) {
        next unless length $str;

        # 2. Kelime bazinda cache kontrolu: $self->get_cache('gw', $rawword) => islenmis
        my $str_val = $self->get_cache( 'gw', $str );

        if ( !defined $str_val ) {
            # Cache'in altina alinan minchar ve stop_word ayarlari
            if ( !$has_meta ) {
                if ($table) {
                    my $table_info = $self->table_info($table);
                    if ( $table_info && $table_info->{stop_word} ) {
                        my $stop_word = $self->to_ascii( $table_info->{stop_word} );
                        $stop_word = $self->trim_space($stop_word);
                        $stop_word = lc($stop_word);
                        %jump      = map { $_ => 1 } split /\s+/, $stop_word;
                    }
                    $minchar = ( $table_info && $table_info->{min_char} ) ? $table_info->{min_char} : 2;
                }
                else {
                    $minchar = 2;
                }
                $has_meta = 1;
            }

            # Eger kelime minchar'dan kisa ise bosluk olarak cachele
            if ( $minchar && length($str) < $minchar ) {
                $self->set_cache( 'gw', $str, '' );
                next;
            }

            $str_val = $self->normalize_word( $str, $is_write );

            # mincharlari islerken onlari da bosluk olarak cachele
            my @sub;
            foreach my $w ( split /\s+/, $str_val ) {
                next unless length $w;
                if ( $minchar && length($w) < $minchar ) {
                    $self->set_cache( 'gw', $w, '' );
                    next;
                }
                push @sub, $w;
            }
            $str_val = join( " ", @sub );
            $self->set_cache( 'gw', $str, $str_val );
        }

        next unless length $str_val;

        if ( $table && !$has_meta ) {
            my $table_info = $self->table_info($table);
            if ( $table_info && $table_info->{stop_word} ) {
                my $stop_word = $self->to_ascii( $table_info->{stop_word} );
                $stop_word = $self->trim_space($stop_word);
                $stop_word = lc($stop_word);
                %jump      = map { $_ => 1 } split /\s+/, $stop_word;
            }
            $has_meta = 1;
        }

        foreach my $w ( split /\s+/, $str_val ) {
            next unless length $w;
            if ( $jump{$w} ) {
                $self->set_cache( 'gw', $w, '' );
                $self->set_cache( 'gw', $str, '' ) if $str eq $w;
                next;
            }
            $words{$w} = $w;
        }
    }

    return %words;
}

# ============================================================================


# ============================================================================
# FILESYSTEM DIRECTORY UTILITIES
# ============================================================================

# $bool = $adb->dir_exist($dir);
# Checks if a directory, alias, symbolic link, or filesystem entry exists.
# ------------------------------------------------
sub dir_exist {
    my ( $self, $dir ) = @_;

    return 0 unless defined $dir && length $dir;
    return ( -d $dir || -l $dir || -e $dir ) ? 1 : 0;
}

# my @files = $adb->dir_files($dir, [$pattern], [%opts]);
# ------------------------------------------------
sub dir_files {
    my ( $self, $dir, $pattern, %opts ) = @_;

    return () unless defined $dir && length($dir) && -d $dir;

    my $full_path  = $opts{full_path}  // 1;
    my $files_only = $opts{files_only} // 1;
    my $do_sort    = $opts{sort}       // 1;

    my $regex;
    if ( defined $pattern && length($pattern) ) {
        if ( ref($pattern) eq 'Regexp' ) {
            $regex = $pattern;
        }
        else {
            my $p = $pattern;
            $p = quotemeta($p);
            $p =~ s/\\\*/.*/g;
            $p =~ s/\\\?/./g;
            $regex = qr/^$p$/;
        }
    }

    opendir my $dh, $dir or return ();
    my @entries = grep { $_ ne '.' && $_ ne '..' } readdir($dh);
    closedir $dh;

    my @results;
    foreach my $entry (@entries) {
        if ( $regex ) {
            next unless $entry =~ $regex;
        }

        my $path = File::Spec->catfile( $dir, $entry );
        if ( $files_only ) {
            next unless -f $path;
        }

        push @results, $full_path ? $path : $entry;
    }

    return $do_sort ? sort { $a cmp $b } @results : @results;
}

# ============================================================================
# RECORD SORTING BY ID (Fallback utility)
# ============================================================================

# @liste = $self->db_sortid("_", @liste);       # if no table
# @liste = $self->db_sortid("table_id", @liste);
# ------------------------------------------------
sub db_sortid {
    my ( $self, $table, @records ) = @_;

    scalar @records or return ();

    my $is_simple = $table ? ( $self->table_attr( $table, 'use_simple' ) // $self->config('simple') ) : $self->config('simple');
    my $field     = ( ref( $records[0] ) eq "ARRAY" ) ? 0 : undef;
    my $sort_type = $is_simple ? 'ascii' : 'num';

    return $self->array_sort( $sort_type, 'desc', $field, @records );
}

# ============================================================================
# PATHS AND CONFIGURATION
# ============================================================================

# $self->set_datadir("/path/to/dbase")
# ------------------------------------------------
sub set_datadir {
    my ( $self, $dbase_dir ) = @_;

    $dbase_dir or return;

    # declarations
    my @dirs = qw(
      dbase_dir table_dir schema_dir backup_dir
      ramdisk_dir table_rdir schema_rdir conf_rdir
      buffer_dir journal_dir lock_dir session_dir
    );
    foreach my $dir (@dirs) {
        $self->{_path}->{$dir} //= "";
    }

    $self->{_path}->{dbase_dir} = $dbase_dir;

    # db_ext tanımlı ve "db" değil ise simple moduna al
    my $db_ext = $self->config('db_ext');
    if ( length($db_ext) && $db_ext ne "db" ) {
        $self->config( simple => 1 );
    }

    # do not proceed if simple mode
    if ( $self->config('simple') ) {
        $self->{_path}->{table_dir}   = $dbase_dir;
        $self->{_path}->{schema_dir}  = $dbase_dir;
        $self->{_path}->{backup_dir}  = $dbase_dir;
        $self->{_path}->{buffer_dir}  = $dbase_dir;
        $self->{_path}->{journal_dir} = $dbase_dir;
        $self->{_path}->{lock_dir}    = "$dbase_dir/lock";
        $self->{_path}->{session_dir} = "$dbase_dir/session";
        return 1;
    }

    $self->{_path}->{journal_dir} = "$dbase_dir/journal";
    $self->{_path}->{backup_dir}  = "$dbase_dir/backup";
    $self->{_path}->{buffer_dir}  = "$dbase_dir/buffer";
    $self->{_path}->{schema_dir}  = "$dbase_dir/schema";
    $self->{_path}->{table_dir}   = "$dbase_dir/table";
    $self->{_path}->{lock_dir}    = "$dbase_dir/lock";
    $self->{_path}->{session_dir} = "$dbase_dir/session";

    # Auto-load connect.pl if present in datadir, or fallback database name to leaf folder
    my $conn_file = "$dbase_dir/config/connect.pl";
    if ( -f $conn_file ) {
        my $target = ( $conn_file =~ m{^(?:\./|[a-zA-Z]:|/|\\)} ) ? $conn_file : "./$conn_file";
        my $cfg = do $target;
        if ( $cfg && ref($cfg) eq 'HASH' && $cfg->{database} ) {
            $self->{_connect}->{database} = $cfg->{database};
        }
    }
    if ( !defined $self->{_connect}->{database} || !length $self->{_connect}->{database} ) {
        my ($leaf) = $dbase_dir =~ m{([^/\\\\]+)[/\\\\]*$};
        $self->{_connect}->{database} = $leaf if defined $leaf && length $leaf;
    }

    unless ( $self->config('test') ) {
        if ( defined $dbase_dir && $dbase_dir ne "." && $dbase_dir ne "" ) {
            for my $dir (
                $self->{_path}->{dbase_dir},
                $self->{_path}->{table_dir},
                $self->{_path}->{schema_dir},
                $self->{_path}->{backup_dir},
                $self->{_path}->{buffer_dir},
                $self->{_path}->{journal_dir},
                $self->{_path}->{lock_dir},
                $self->{_path}->{session_dir},
            ) {
                if ( defined $dir && length($dir) && !$self->dir_exist($dir) ) {
                    $self->make_path($dir);
                }
            }
        }
    }

    $self->ramdisk_setup();
    return 1;
}

# Utility method to create a directory path.
# ------------------------------------------------
sub make_path {
    my ( $self, $path ) = @_;
    unless ( -d $path ) {
        require File::Path;
        File::Path::make_path($path);
    }
    return 1;
}

# my $cfg_val = $adb->config("language");
# ------------------------------------------------
sub config {
    my ( $self, @args ) = @_;

    # 1. No arguments: return shallow copy of all configuration
    if ( !@args ) {
        return { %{ $self->{_cfg} || {} } };
    }

    # 2. Single scalar argument: getter -> $adb->config('language')
    if ( @args == 1 && !ref( $args[0] ) ) {
        if ( $args[0] eq 'user' ) {
            return $self->{_connect}->{username} // $self->{_cfg}->{user} // 'user_system';
        }
        return $self->{_cfg}->{ $args[0] } // '';
    }

    # 3. Setter: key-value list or hashref
    my %pairs = ( @args == 1 && ref( $args[0] ) eq 'HASH' ) ? %{ $args[0] } : @args;

    my $hooks = {
        language => sub {
            my $val = shift;
            $self->{_cfg}->{language} = $val;
            $self->_load_locale($val);
        },
        db_ext => sub {
            my $val = shift;
            $self->{_cfg}->{db_ext} = $val;
            $self->{db_ext} = $val;
            if ( defined $val && $val ne "db" ) {
                $self->{_cfg}->{simple} = 1;
            }
            $self->_invalidate_table_paths();
        },
        simple => sub {
            my $val = shift;
            $self->{_cfg}->{simple} = $val ? 1 : 0;
            $self->_invalidate_table_paths();
        },
        use_ramdisk => sub {
            my $val = shift;
            my $tier = $self->_normalize_ramdisk_tier($val);
            if ( $tier == 3 ) {
                $tier = 0;
            }
            $self->{_cfg}->{use_ramdisk} = $tier;
            $self->_invalidate_table_paths();
        },
    };

    while ( my ( $key, $val ) = each %pairs ) {
        if ( exists $hooks->{$key} ) {
            $hooks->{$key}->($val);
        }
        else {
            $self->{_cfg}->{$key} = $val;
            if ( $key eq 'user' ) {
                $self->{_connect}->{username} = $val;
            }
        }
    }

    return $self;
}

# my $dbase_dir = $adb->path("dbase_dir");
# ------------------------------------------------
sub path {
    my ( $self, @args ) = @_;

    # 1. No arguments: return shallow copy of all path mappings
    if ( !@args ) {
        return { %{ $self->{_path} || {} } };
    }

    # 2. Single scalar argument: getter -> $adb->path('dbase_dir')
    if ( @args == 1 && !ref( $args[0] ) ) {
        return $self->{_path}->{ $args[0] } // '';
    }

    # 3. Setter: key-value list or hashref
    my %pairs = ( @args == 1 && ref( $args[0] ) eq 'HASH' ) ? %{ $args[0] } : @args;

    for my $key ( keys %pairs ) {
        $self->{_path}->{$key} = $pairs{$key};
    }
    $self->_invalidate_table_paths();

    return $self;
}

# Invalidate cached table paths if global path-affecting configurations change
# ------------------------------------------------
sub _invalidate_table_paths {
    my ($self) = @_;

    if ( $self->{_table} && ref( $self->{_table} ) eq 'HASH' ) {
        for my $tbl ( keys %{ $self->{_table} } ) {
            delete $self->{_table}->{$tbl}->{_path}
              if ref( $self->{_table}->{$tbl} ) eq 'HASH';
        }
    }
}

# ============================================================================
# AUTHENTICATION & PASSWORD CRYPTOGRAPHY (Salted SHA-256)
# ============================================================================

# my $shadow = $adb->hash_password($password, [$salt]);
# ---------------------------------------------------------------------
sub hash_password {
    my ( $self, $password, $salt ) = @_;
    return '' unless defined $password && length $password;

    # 16-character cryptographically secure hex salt
    $salt //= sprintf( "%08x%08x", int( rand(0xFFFFFFFF) ), int( rand(0xFFFFFFFF) ) );

    my $hash = sha256_hex( $salt . $password );
    return "sha256\$$salt\$$hash";
}

# my $ok = $adb->verify_password($password, $stored_shadow);
# ---------------------------------------------------------------------
sub verify_password {
    my ( $self, $password, $stored_shadow ) = @_;
    # Passwordless allowed if stored shadow is empty or undef
    return 1 if !defined $stored_shadow || !length $stored_shadow;
    $password //= '';

    my ( $algo, $salt, $expected ) = split /\$/, $stored_shadow;
    return 0 unless defined $algo && defined $salt && defined $expected;

    if ( $algo eq 'sha256' ) {
        my $computed = sha256_hex( $salt . $password );
        return lc($computed) eq lc($expected) ? 1 : 0;
    }
    return $stored_shadow eq $password ? 1 : 0;
}

# ============================================================================
# DATABASE CONNECTION & CLIENT AUTH PROFILE (connect.pl)
# ============================================================================

sub _connect_file {
    my ($self) = @_;
    my $conf_dir = $self->path('conf_dir') || ( ( $self->path('dbase_dir') || "." ) . "/config" );
    return "$conf_dir/connect.pl";
}

sub _load_connect_config {
    my ($self) = @_;
    my $file = $self->_connect_file();
    return undef unless -f $file;

    my $target = ( $file =~ m{^(?:\./|[a-zA-Z]:|/|\\)} ) ? $file : "./$file";
    my $data = do $target;
    return undef unless ref($data) eq 'HASH';

    # Auto-upgrade: if any user entry or top-level entry has plain 'password', hash into 'shadow' and delete 'password'
    my $modified = 0;
    if ( defined $data->{password} && length $data->{password} ) {
        $data->{shadow} = $self->hash_password( delete $data->{password} );
        $modified = 1;
    }
    if ( $data->{users} && ref( $data->{users} ) eq 'HASH' ) {
        for my $u ( keys %{ $data->{users} } ) {
            my $u_info = $data->{users}->{$u};
            next unless ref($u_info) eq 'HASH';
            if ( defined $u_info->{password} && length $u_info->{password} ) {
                $u_info->{shadow} = $self->hash_password( delete $u_info->{password} );
                $modified = 1;
            }
        }
    }
    if ($modified) {
        $self->_save_connect_config($data);
    }

    return $data;
}

sub _save_connect_config {
    my ( $self, $data ) = @_;
    my $file = $self->_connect_file();
    return unless defined $file && ref($data) eq 'HASH';

    my ($dir) = $file =~ m{^(.+)[/\\][^/\\]+$};
    $self->make_path($dir) if $dir && !$self->dir_exist($dir);

    require Data::Dumper;
    local $Data::Dumper::Terse    = 1;
    local $Data::Dumper::Indent   = 1;
    local $Data::Dumper::Sortkeys = 1;
    my $dump = Data::Dumper::Dumper($data);
    $dump =~ s/^\s+|\s+$//g;

    if ( open my $fh, '>', $file ) {
        print $fh "# AmberDB Database Connection & Client Auth Profile\n";
        print $fh "return " . $dump . ";\n";
        close $fh;
        return 1;
    }
    return 0;
}

# my $sess_path = $adb->session_file($token);
# ---------------------------------------------------------------------
sub session_file {
    my ( $self, $token ) = @_;
    return '' unless defined $token && length $token;
    my $sess_dir = $self->path('session_dir') || ( ( $self->path('dbase_dir') || "." ) . "/session" );
    return "$sess_dir/cli_$token";
}

# my $token = $adb->generate_token();
# ---------------------------------------------------------------------
sub generate_token {
    my ($self) = @_;
    for ( 1 .. 1000 ) {
        my $token = sprintf( "%04d", int( rand(9000) ) + 1000 );
        my $sf = $self->session_file($token);
        next if $sf && -f $sf;
        my $cf = ".amberdb/session/sess_$token";
        next if -f $cf;
        return $token;
    }
    return sprintf( "%04d", int( rand(9000) ) + 1000 );
}

sub _load_session {
    my ( $self, $token ) = @_;
    return undef unless defined $token && length $token;
    my @files = ( $self->session_file($token), ".amberdb/session/sess_$token" );

    for my $sf (@files) {
        next unless $sf && -f $sf;
        my $target = ( $sf =~ m{^(?:\./|[a-zA-Z]:|/|\\)} ) ? $sf : "./$sf";
        my $data = do $target;
        return $data if ref($data) eq 'HASH';

        if ( open my $fh, '<', $sf ) {
            local $/;
            my $raw = <$fh>;
            close $fh;
            if ( $raw && $raw =~ /^\s*\{/ ) {
                require JSON::PP;
                my $jdata = eval { JSON::PP::decode_json($raw) };
                return $jdata if $jdata && ref($jdata) eq 'HASH';
            }
        }
    }
    return undef;
}

sub _save_session {
    my ( $self, $token, $data ) = @_;
    return unless defined $token && length $token;
    my $sf = $self->session_file($token);
    return unless $sf;

    my ($dir) = $sf =~ m{^(.+)[/\\][^/\\]+$};
    $self->make_path($dir) if $dir && !$self->dir_exist($dir);

    require Data::Dumper;
    local $Data::Dumper::Terse    = 1;
    local $Data::Dumper::Indent   = 1;
    local $Data::Dumper::Sortkeys = 1;
    my $dump = Data::Dumper::Dumper($data);
    $dump =~ s/^\s+|\s+$//g;

    if ( open my $fh, '>', $sf ) {
        print $fh "# AmberDB Active CLI Session Token: $token\n";
        print $fh "return " . $dump . ";\n";
        close $fh;
    }

    # Also sync local .amberdb/session/sess_$token
    my $local_dir = ".amberdb/session";
    $self->make_path($local_dir) unless -d $local_dir;
    my $local_file = "$local_dir/sess_$token";
    if ( open my $lfh, '>', $local_file ) {
        require JSON::PP;
        print $lfh JSON::PP::encode_json($data);
        close $lfh;
    }

    return 1;
}

sub _delete_session {
    my ( $self, $token ) = @_;
    return unless defined $token && length $token;
    my $sf = $self->session_file($token);
    unlink $sf if $sf && -f $sf;
    my $local_file = ".amberdb/session/sess_$token";
    unlink $local_file if -f $local_file;
}

# my $val_or_token = $adb->connect([$key | %args]);
# ---------------------------------------------------------------------
sub connect {
    my ( $self, @args ) = @_;

    # 1. Single scalar argument: attribute getter -> $adb->connect('database')
    if ( @args == 1 && !ref( $args[0] ) ) {
        my $k = $args[0];
        $k = 'database' if $k eq 'dbase' || $k eq 'dbname';
        $k = 'username' if $k eq 'user'  || $k eq 'usr';
        $k = 'password' if $k eq 'pass'  || $k eq 'passwd';
        return $self->{_connect}->{$k} // '';
    }

    # If called with no args and already connected with valid token, return active token
    if ( !@args && defined $self->{_connect}->{token} && length $self->{_connect}->{token} ) {
        return $self->{_connect}->{token};
    }

    # 2. Connection / Authentication Action -> $adb->connect(%args) or $adb->connect()
    my %opts = ( @args == 1 && ref( $args[0] ) eq 'HASH' ) ? %{ $args[0] } : @args;

    my $token    = delete $opts{token}    // delete $opts{tok};
    my $database = delete $opts{database} // delete $opts{dbase} // delete $opts{dbname} // delete $opts{db} // $self->{_connect}->{database};
    my $username = delete $opts{username} // delete $opts{user}  // delete $opts{usr}    // $self->{_connect}->{username};
    my $password = delete $opts{password} // delete $opts{pass}  // delete $opts{passwd}  // $self->{_connect}->{password};

    # Sub-case A: Resume session via token
    if ( defined $token && length $token ) {
        my $sess = $self->_load_session($token);
        if ( $sess && ref($sess) eq 'HASH' ) {
            $self->{_connect}->{token}    = $token;
            $self->{_connect}->{database} = $sess->{connect}->{database} // $sess->{database} // $self->{_connect}->{database} // '';
            $self->{_connect}->{username} = $sess->{connect}->{username} // $sess->{username} // $self->{_connect}->{username} // 'user_system';
            $self->{_connect}->{password} = $sess->{connect}->{password} // $sess->{password} // '';
            $self->{_cfg}->{user}         = $self->{_connect}->{username};
            return $token;
        }
        return undef;
    }

    # Sub-case B: Authenticate credentials & generate session token
    my $connect_cfg = $self->_load_connect_config();

    # Dbase dir leaf name as default database if not specified
    if ( !defined $database || !length $database ) {
        if ( $connect_cfg && $connect_cfg->{database} ) {
            $database = $connect_cfg->{database};
        }
        else {
            my $dbase_dir = $self->path('dbase_dir') || ".";
            my ($leaf) = $dbase_dir =~ m{([^/\\\\]+)[/\\\\]*$};
            $database = $leaf // 'amberdb';
        }
    }

    $username //= 'cli';
    $password //= '';

    # Bootstrap connect.pl on first connection if missing or empty
    if ( !$connect_cfg || !ref($connect_cfg->{users}) || !keys %{ $connect_cfg->{users} } ) {
        $connect_cfg = {
            database   => $database,
            created_at => time(),
            users      => {
                $username => {
                    shadow => ( defined $password && length $password ) ? $self->hash_password($password) : '',
                    role   => 'admin',
                },
                web => {
                    shadow => '',
                    role   => 'web',
                },
                cli => {
                    shadow => '',
                    role   => 'cli',
                },
            },
        };
        $self->_save_connect_config($connect_cfg);
    }
    else {
        # Check database mismatch if specified
        if ( $connect_cfg->{database} && $database && lc($connect_cfg->{database}) ne lc($database) ) {
            croak "[AMBERDB_AUTH_ERROR] Database mismatch: requested '$database' but store is '$connect_cfg->{database}'";
        }
        $database = $connect_cfg->{database} if $connect_cfg->{database};

        # Check user
        my $user_info = $connect_cfg->{users}->{$username};
        if ( !$user_info ) {
            croak "[AMBERDB_AUTH_ERROR] User '$username' not authorized for database '$database'";
        }

        # Auto-upgrade plain text password in connect.pl to shadow if present
        if ( exists $user_info->{password} && defined $user_info->{password} && length $user_info->{password} ) {
            my $plain = delete $user_info->{password};
            $user_info->{shadow} = $self->hash_password($plain);
            $self->_save_connect_config($connect_cfg);
        }

        # Password check:
        # If both shadow and password are empty/missing: passwordless access allowed (local trust / backwards compat)
        my $shadow = $user_info->{shadow} // '';
        if ( length $shadow ) {
            if ( !defined $password || !length $password ) {
                croak "[AMBERDB_AUTH_ERROR] Password required for user '$username'";
            }
            if ( !$self->verify_password( $password, $shadow ) ) {
                croak "[AMBERDB_AUTH_ERROR] Invalid password for user '$username'";
            }
        }
    }

    # Authentication successful: issue token
    my $new_token = $self->generate_token();
    $self->{_connect}->{database} = $database;
    $self->{_connect}->{username} = $username;
    $self->{_connect}->{password} = $password;
    $self->{_connect}->{token}    = $new_token;
    $self->{_cfg}->{user}         = $username;

    # Save session
    my $sess_data = {
        token      => $new_token,
        created_at => time(),
        updated_at => time(),
        connect    => {
            database => $database,
            username => $username,
        },
        path       => { %{ $self->path() } },
        cfg        => { %{ $self->config() } },
    };
    $self->_save_session( $new_token, $sess_data );

    return $new_token;
}

sub disconnect {
    my ( $self, $token ) = @_;
    $token //= $self->{_connect}->{token};
    if ( defined $token && length $token ) {
        $self->_delete_session($token);
    }
    $self->{_connect}->{token}    = '';
    $self->{_connect}->{password} = '';
    return 1;
}

# ============================================================================
# USER MANAGEMENT METHODS (connect.pl API)
# ============================================================================

sub user_add {
    my ( $self, $username, $password, %opts ) = @_;
    croak "Username required" unless defined $username && length $username;

    my $cfg = $self->_load_connect_config() // { database => $self->connect('database') || 'amberdb', users => {} };
    $cfg->{users} //= {};

    my $shadow = ( defined $password && length $password ) ? $self->hash_password($password) : '';
    $cfg->{users}->{$username} = {
        shadow     => $shadow,
        role       => $opts{role} // 'user',
        created_at => time(),
    };
    $self->_save_connect_config($cfg);
    return 1;
}

sub user_passwd {
    my ( $self, $username, $password ) = @_;
    croak "Username required" unless defined $username && length $username;

    my $cfg = $self->_load_connect_config();
    croak "Database connection config not found" unless $cfg && $cfg->{users}->{$username};

    $cfg->{users}->{$username}->{shadow} = ( defined $password && length $password ) ? $self->hash_password($password) : '';
    $cfg->{users}->{$username}->{updated_at} = time();
    $self->_save_connect_config($cfg);
    return 1;
}

sub user_del {
    my ( $self, $username ) = @_;
    croak "Username required" unless defined $username && length $username;

    my $cfg = $self->_load_connect_config();
    return 0 unless $cfg && exists $cfg->{users}->{$username};

    delete $cfg->{users}->{$username};
    $self->_save_connect_config($cfg);
    return 1;
}

sub user_list {
    my ($self) = @_;
    my $cfg = $self->_load_connect_config();
    return () unless $cfg && ref($cfg->{users}) eq 'HASH';

    my @list;
    for my $u ( sort keys %{ $cfg->{users} } ) {
        my $ud = $cfg->{users}->{$u};
        push @list, {
            username     => $u,
            role         => $ud->{role} // 'user',
            has_password => ( defined $ud->{shadow} && length $ud->{shadow} ) ? 1 : 0,
            created_at   => $ud->{created_at} // 0,
        };
    }
    return @list;
}

sub user_verify {
    my ( $self, $username, $password ) = @_;
    return 0 unless defined $username && length $username;

    my $cfg = $self->_load_connect_config();
    return 0 unless $cfg && ref($cfg->{users}) eq 'HASH';

    my $ud = $cfg->{users}->{$username};
    return 0 unless $ud;

    my $shadow = $ud->{shadow} // '';
    return 1 if !length($shadow);    # Passwordless allowed
    return 0 unless defined $password && length $password;
    return $self->verify_password( $password, $shadow );
}

# my ($count, @records) = $adb->recs_cutting($offset, $limit, @records);
# ------------------------------------------------
sub recs_cutting {
    my ( $self, $offset, $limit, @records ) = @_;

    $offset ||= 0;
    $limit  ||= 0;
    $offset = 0 if $offset < 0;
    my $count = scalar @records;
    return ( $count, @records ) unless $limit;

    my $end = ( $offset + $limit ) > $count ? $count : ( $offset + $limit );
    @records = @records[ $offset .. ( $end - 1 ) ];

    return ( $count, @records );
}

# Minimal date helper without external dependencies.
# Populates $self->{date}: year, day_id, minute_id, second_id, str
# ------------------------------------------------
sub init_date {
    my ($self) = @_;

    if ( $self->can('get_date') ) {
        $self->{date} = $self->get_date();
    }
    else {
        my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime(time);
        $year += 1900;
        $mon  += 1;

        my $month = sprintf "%02d", $mon;
        my $day   = sprintf "%02d", $mday;
        my $hr    = sprintf "%02d", $hour;
        my $mn    = sprintf "%02d", $min;
        my $sc    = sprintf "%02d", $sec;

        $self->{date} = {
            year      => $year,
            day_id    => "${year}${month}${day}",
            minute_id => "${year}${month}${day}${hr}${mn}",
            second_id => "${year}${month}${day}${hr}${mn}${sc}",
            str       => "${day}/${month}/${year} - ${hr}:${mn}:${sc}",
        };
    }

    return $self->{date};
}

# ============================================================================
# JOURNAL FILE OPERATIONS (Streaming Append, Safe Read, Atomic Rotate)
# Default Directory: $dbase_dir/journal/
# File Naming:
#   Active Queue:  dbstore/journal/sync_ramdisk
#   Rotated Queue: dbstore/journal/sync_ramdisk_1741512300
#   Transaction:   dbstore/journal/txn_1741512300_1_4820
# ============================================================================

sub journal_dir {
    my ($self) = @_;
    my $dir = $self->path('journal_dir')
           || ( ( $self->path('dbase_dir') || "." ) . "/journal" );
    $dir =~ s{[\\/]+$}{};
    unless ( -d $dir ) {
        $self->make_path($dir);
    }
    return $dir;
}

sub journal_slot {
    my ( $self, $name ) = @_;
    $name //= 'journal';

    my $jdir = $self->journal_dir();

    my $prefix = '';
    if ( $self->config('use_section') ) {
        $prefix = ( $self->config('section') // "center" ) . "-";
    }

    my $file_name = "${prefix}${name}";
    return wantarray ? ( $jdir, $file_name ) : "$jdir/$file_name";
}

sub _resolve_journal_path {
    my ( $self, $target ) = @_;
    return unless defined $target && length $target;

    if ( $target =~ m{[/\\]} ) {
        return $target;
    }
    return $self->journal_slot($target);
}

sub journal_append {
    my ( $self, $slot_or_path, @entries ) = @_;

    my $target_path = $self->_resolve_journal_path($slot_or_path);
    return unless defined $target_path && length $target_path;
    return unless @entries;

    my $lock_file = "${target_path}.lock";
    open my $lfh, '>>', $lock_file or do {
        cluck "[DB_JOURNAL] Cannot open lock file $lock_file: $!\n";
        return;
    };
    flock( $lfh, LOCK_EX );

    open my $fh, '>>', $target_path or do {
        flock( $lfh, LOCK_UN );
        close $lfh;
        cluck "[DB_JOURNAL] Cannot open $target_path for append: $!\n";
        return;
    };

    foreach my $item (@entries) {
        my $line;
        if ( ref($item) eq 'ARRAY' ) {
            $line = $self->journal_encode( @$item );
        }
        else {
            $line = "$item";
        }
        chomp $line;
        print $fh "$line\n";
    }

    $fh->flush;
    close $fh;

    flock( $lfh, LOCK_UN );
    close $lfh;

    return 1;
}

sub journal_read {
    my ( $self, $slot_or_path ) = @_;

    my $target_path = $self->_resolve_journal_path($slot_or_path);
    return () unless defined $target_path && -e $target_path;

    my $lock_file = "${target_path}.lock";
    my $lfh;
    if ( -e $lock_file ) {
        open $lfh, '<', $lock_file;
        flock( $lfh, LOCK_SH ) if $lfh;
    }

    open my $fh, '<', $target_path or do {
        if ($lfh) { flock( $lfh, LOCK_UN ); close $lfh; }
        cluck "[DB_JOURNAL] Cannot open $target_path for read: $!\n";
        return ();
    };

    my @lines = <$fh>;
    close $fh;

    if ($lfh) {
        flock( $lfh, LOCK_UN );
        close $lfh;
    }

    my @records;
    for my $line (@lines) {
        my $rec = $self->journal_decode($line);
        push @records, $rec if $rec;
    }

    return @records;
}

sub journal_rotate {
    my ( $self, $slot_or_path, $epoch ) = @_;

    my $target_path = $self->_resolve_journal_path($slot_or_path);
    return unless defined $target_path && -e $target_path && -s $target_path;

    my $lock_file = "${target_path}.lock";
    open my $lfh, '>>', $lock_file or return;
    flock( $lfh, LOCK_EX );

    unless ( -e $target_path && -s $target_path ) {
        flock( $lfh, LOCK_UN );
        close $lfh;
        return;
    }

    $epoch //= time();
    my $base_rotated = "${target_path}_${epoch}";
    my $rotated_path = $base_rotated;
    my $counter = 1;
    while ( -e $rotated_path ) {
        $rotated_path = "${base_rotated}_${counter}";
        $counter++;
    }

    my $ok = rename( $target_path, $rotated_path );

    flock( $lfh, LOCK_UN );
    close $lfh;

    return $ok ? $rotated_path : undef;
}

sub journal_delete {
    my ( $self, $slot_or_path ) = @_;

    my $target_path = $self->_resolve_journal_path($slot_or_path);
    return unless defined $target_path;

    if ( -e $target_path ) {
        unlink $target_path;
    }
    my $lock_file = "${target_path}.lock";
    if ( -e $lock_file ) {
        unlink $lock_file;
    }
    return 1;
}

sub journal_scan {
    my ( $self, $prefix ) = @_;
    $prefix //= 'sync_ramdisk_';

    my $jdir = $self->journal_dir();
    return () unless -d $jdir;

    my $sec_prefix = '';
    if ( $self->config('use_section') ) {
        $sec_prefix = ( $self->config('section') // "center" ) . "-";
    }
    my $full_prefix = "${sec_prefix}${prefix}";

    opendir my $dh, $jdir or return ();
    my @found;
    while ( my $f = readdir($dh) ) {
        next if $f eq '.' || $f eq '..' || $f =~ /\.lock$/;
        if ( index($f, $full_prefix) == 0 && $f =~ /_\d+(?:_\d+)?$/ ) {
            push @found, "$jdir/$f";
        }
    }
    closedir $dh;

    return sort @found;
}

1;
