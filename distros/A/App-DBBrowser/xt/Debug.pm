package # hide from PAUSE
App::DBBrowser::DB::Debug;

use warnings;
use strict;
use 5.008003;
no warnings 'utf8';

#our $VERSION = '';

use Encode                qw( encode decode );
use File::Find            qw( find );
use File::Spec::Functions qw( catdir );
use Scalar::Util          qw( looks_like_number );

use DBI             qw();
use Encode::Locale  qw();
use List::MoreUtils qw( none );

use App::DBBrowser::Auxil;

$SIG{__WARN__} = sub { die @_ };

sub new {
    my ( $class, $opt ) = @_;
    $opt->{db_driver} = 'SQLite';
    $opt->{driver_prefix} = 'sqlite';
    $opt->{plugin_api_version} = 1.4;
    bless $opt, $class;
}


my @info_check = sort( qw(
    _back
    _confirm
    _continue
    _quit
    _reset
    app_dir
    avail_aggregate
    avail_operators
    back
    back_short
    clear_screen
    conf_file_fmt
    config_generic
    csv_opt
    db_cache_file
    db_driver
    db_plugin
    driver_prefix
    home_dir
    input_files
    line_fold
    lock
    lyt_1
    lyt_3
    lyt_stmt_h
    lyt_stmt_v
    lyt_stop
    ok
    quit
    scalar_func_h
    scalar_func_keys
    sqlite_search
    stmt_init_tab

    backup_max_rows
    login_error
    write_config
) );

my $opt_check = {
    G => [ qw(
        db_plugins
        lock_stmt
        menu_sql_memory
        menus_config_memory
        menus_db_memory
        metadata
        operators
        parentheses_h
        parentheses_w
        thsd_sep
    ) ],
    insert => [ qw(
        allow_loose_escapes
        allow_loose_quotes
        allow_whitespace
        auto_diag
        binary
        blank_is_undef
        empty_is_undef
        escape_char
        file_encoding
        input_modes
        i_f_s
        i_r_s
        max_files
        parse_mode
        quote_char
        sep_char
    ) ],
        table => [ qw(
        binary_filter
        binary_string
        keep_header
        max_rows
        min_col_width
        mouse
        progress_bar
        tab_width
        table_expand
        undef
    ) ],
};


my $db_opt_check = {
    Debug => [ qw(
        binary_filter
        directories_sqlite
        field
        host
        port
        user
        sqlite_see_if_its_a_number
        sqlite_unicode
    ) ],
};


#        login_mode_field
#        login_mode_host
#        login_mode_pass
#        login_mode_port
#        login_mode_user



sub debug {
    my ( $self, $dbh, $info, $opt, $db_opt ) = @_;
    $dbh->disconnect();
    my $dir = catdir $self->{home_dir}, 'lib/CPAN/App-DBBrowser/';
    my $info_regex;
    my $opt_regex;
    my $db_opt_regex;
    File::Find::find( {
        wanted => sub {
            my $file = $_;
            return if $file !~ /\.p[lm]\z/;
            return if $file =~ /Debug\.pm/;
            open my $fh, '<', $file or die "$file: $!";
            while ( my $line = <$fh> ) {
                map { $info_regex->{$_}++ }          $line =~ /self->\{info\}\{([^}{\$]+)\}/g;
                map { $opt_regex->{G}{$_}++ }        $line =~ /self->\{opt\}\{G\}\{([^}{\$]+)\}/g;
                map { $opt_regex->{insert}{$_}++ }   $line =~ /self->\{opt\}\{insert\}\{([^}{\$]+)\}/g;
                map { $opt_regex->{table}{$_}++ }    $line =~ /self->\{opt\}\{table\}\{([^}{\$]+)\}/g;
                map { $db_opt_regex->{Debug}{$_}++ } $line =~ /self->\{db_opt\}\{Debug\}\{([^}{\$]+)\}/g;
            }
            close $fh;
        },
        no_chdir => 1
    }, $dir );


    # info keys
    for my $key ( keys %$info ) {
        if ( none { $key eq $_ } @info_check ) {
            print $key, "\n";
        }
    }
    for my $key_r ( keys %$info_regex ) {
        if ( none { $key_r eq $_ } @info_check ) {
            print $key_r, "\n";
        }
    }
    my $total_info;
    for my $key ( keys %$info, keys %$info_regex ) {
        $total_info->{$key}++;
    }
    my @info_total = sort keys %$total_info;
    if ( "@info_check" ne "@info_total" ) {
        printf "info keys: %d - %d\n", scalar @info_total, scalar @info_check;
        print "info      : @info_total\n";
        print "info_check: @info_check\n";

    }


    # opt sections
    my @section_check = sort keys %$opt_check;
    my @section = sort keys %$opt;
    if ( "@section" ne "@section_check" ) {
        print "opt      : @section\n";
        print "opt_check: @section_check\n";
    }


    # opt sections keys
    for my $sect ( @section ) {
        my @option_check = sort @{$opt_check->{$sect}};

        my @option = sort keys %{$opt->{$sect}};
        if ( "@option" ne "@option_check" ) {
            print "$sect:\n";
            print "orig : @option\n";
            print "check: @option_check\n\n";
        }

        for my $key_r ( keys %{$opt_regex->{$sect}} ) {
            if ( none { $key_r eq $_ } @option_check ) {
                print "$sect: $key_r\n";
            }
        }
    }


    # db_opt Debug
    my $sect = 'Debug';
    my @debug_check = @{$db_opt_check->{$sect}};

    my $not_ok = 0;
    my @debug = sort keys %{$db_opt->{$sect}};
    for my $key ( @debug ) {
        if ( none { $key eq $_ } @debug_check ) {
            print $key, "\n";
            $not_ok = 1;
            last;
        }
    }
    if ( $not_ok ) {
        print "debug      : @debug\n";
        print "debug_check: @debug_check\n";
    }

    $not_ok = 0;
    my @debug_regex = sort keys %{$db_opt_regex->{$sect}};
    for my $key_r ( @debug_regex ) {
        if ( none { $key_r eq $_ } @debug_check ) {
            print $key_r, "\n";
            $not_ok = 1;
            last;
        }
    }
    if ( $not_ok ) {
        print "debug_regex: @debug_regex\n";
        print "debug_check: @debug_check\n";
    }


    die "End Debug.";
    return 1;

}



sub plugin_api_version {
    my ( $self ) = @_;
    return $self->{plugin_api_version};
}


sub db_driver {
    my ( $self ) = @_;
    return $self->{db_driver};
}


sub driver_prefix {
    my ( $self ) = @_;
    return $self->{driver_prefix};
}


sub read_argument {
    my ( $self ) = @_;
    return [
        { name => 'field', prompt => "Field",    keep_secret => 0 },
        { name => 'host',  prompt => "Host",     keep_secret => 0 },
        { name => 'port',  prompt => "Port",     keep_secret => 0 },
        { name => 'user',  prompt => "User",     keep_secret => 0 },
        { name => 'pass',  prompt => "Password", keep_secret => 1 },
    ];
}


sub choose_arguments {
    my ( $self ) = @_;
    return [
        { name => 'sqlite_unicode',             default_index => 1, avail_values => [ 0, 1 ] },
        { name => 'sqlite_see_if_its_a_number', default_index => 1, avail_values => [ 0, 1 ] },
    ];
}


sub get_db_handle {
    my ( $self, $db, $connect_parameter ) = @_;
    my $dsn = "dbi:$self->{db_driver}:dbname=$db";
    my $dbh = DBI->connect( $dsn, '', '', {
        PrintError => 0,
        RaiseError => 1,
        AutoCommit => 1,
        ShowErrorStatement => 1,
        %{$connect_parameter->{chosen_arg}},
    } ) or die DBI->errstr;
    $dbh->sqlite_create_function( 'regexp', 3, sub {
            my ( $regex, $string, $case_sensitive ) = @_;
            $string = '' if ! defined $string;
            return $string =~ m/$regex/sm if $case_sensitive;
            return $string =~ m/$regex/ism;
        }
    );
    $dbh->sqlite_create_function( 'truncate', 2, sub {
            my ( $number, $places ) = @_;
            return if ! defined $number;
            return $number if ! looks_like_number( $number );
            return sprintf "%.*f", $places, int( $number * 10 ** $places ) / 10 ** $places;
        }
    );
    $dbh->sqlite_create_function( 'bit_length', 1, sub {
            use bytes;
            return length $_[0];
        }
    );
    $dbh->sqlite_create_function( 'char_length', 1, sub {
            return length $_[0];
        }
    );
    return $dbh;
}


sub available_databases {
    my ( $self, $connect_parameter ) = @_;
    return \@ARGV if @ARGV;
    my $dirs = $connect_parameter->{dir_sqlite};
    my $cache_key = $self->{db_plugin} . '_' . join ' ', @$dirs;
    my $auxil = App::DBBrowser::Auxil->new();
    my $db_cache = $auxil->read_json( $self->{db_cache_file} );
    if ( $self->{sqlite_search} ) {
        delete $db_cache->{$cache_key};
    }
    my $databases = [];
    if ( ! defined $db_cache->{$cache_key} ) {
        print 'Searching...' . "\n";
        for my $dir ( @$dirs ) {
            File::Find::find( {
                wanted => sub {
                    my $file = $_;
                    return if ! -f $file;
                    return if ! -s $file; #
                    return if ! -r $file; #
                    #print "$file\n";
                    if ( ! eval {
                        open my $fh, '<:raw', $file or die "$file: $!";
                        defined( read $fh, my $string, 13 ) or die "$file: $!";
                        close $fh;
                        push @$databases, decode( 'locale_fs', $file ) if $string eq 'SQLite format';
                        1 }
                    ) {
                        utf8::decode( $@ );
                        print $@;
                    }
                },
                no_chdir => 1,
            },
            encode( 'locale_fs', $dir ) );
        }
        print 'Ended searching' . "\n";
        $db_cache->{$cache_key} = $databases;
        $auxil->write_json( $self->{db_cache_file}, $db_cache );
    }
    else {
        $databases = $db_cache->{$cache_key};
    }
    return $databases;
}


sub get_schema_names {
    my ( $self, $dbh, $db ) = @_;
    return [ 'main' ];
}


sub get_table_names {
    my ( $self, $dbh, $schema ) = @_;
    my $regexp_system_tbl = '^sqlite_';
    my $stmt = "SELECT name FROM sqlite_master WHERE type = 'table'";
    if ( ! $self->{add_metadata} ) {
        $stmt .= " AND name NOT REGEXP ?";
    }
    $stmt .= " ORDER BY name";
    my $tables = $dbh->selectcol_arrayref( $stmt, {}, $self->{add_metadata} ? () : ( $regexp_system_tbl ) );
    if ( $self->{add_metadata} ) {
        my $user_tbl   = [];
        my $system_tbl = [];
        for my $table ( @{$tables} ) {
            if ( $table =~ /(?:$regexp_system_tbl)/ ) {
                push @$system_tbl, $table;
            }
            else {
                push @$user_tbl, $table;
            }
        }
        push @$system_tbl, 'sqlite_master';
        return $user_tbl, $system_tbl;
    }
    else {
        return $tables;
    }
}


sub column_names_and_types {
    my ( $self, $dbh, $db, $schema, $tables ) = @_;
    my ( $col_names, $col_types );
    for my $table ( @$tables ) {
        my $sth = $dbh->prepare( "SELECT * FROM " . $dbh->quote_identifier( undef, undef, $table ) );
        $col_names->{$table} = $sth->{NAME};
        $col_types->{$table} = $sth->{TYPE};
    }
    return $col_names, $col_types;
}


sub primary_and_foreign_keys {
    my ( $self, $dbh, $db, $schema, $tables ) = @_;
    my $pk_cols = {};
    my $fks     = {};
    for my $table ( @$tables ) {
        for my $c ( @{$dbh->selectall_arrayref( "pragma foreign_key_list( $table )" )} ) {
            $fks->{$table}{$c->[0]}{foreign_key_col}  [$c->[1]] = $c->[3];
            $fks->{$table}{$c->[0]}{reference_key_col}[$c->[1]] = $c->[4];
            $fks->{$table}{$c->[0]}{reference_table} = $c->[2];
        }
        $pk_cols->{$table} = [ $dbh->primary_key( undef, $schema, $table ) ];
    }
    return $pk_cols, $fks;
}


sub sql_regexp {
    my ( $self, $quote_col, $do_not_match_regexp, $case_sensitive ) = @_;
    if ( $do_not_match_regexp ) {
        return sprintf ' NOT REGEXP(?,%s,%d)', $quote_col, $case_sensitive;
    }
    else {
        return sprintf ' REGEXP(?,%s,%d)', $quote_col, $case_sensitive;
    }
}


sub concatenate {
    my ( $self, $arg ) = @_;
    return join( ' || ', @$arg );
}



# scalar functions

sub epoch_to_datetime {
    my ( $self, $col, $interval ) = @_;
    return "DATETIME($col/$interval,'unixepoch','localtime')";
}

sub epoch_to_date {
    my ( $self, $col, $interval ) = @_;
    return "DATE($col/$interval,'unixepoch','localtime')";
}

sub truncate {
    my ( $self, $col, $precision ) = @_;
    return "TRUNCATE($col,$precision)";
}

sub bit_length {
    my ( $self, $col ) = @_;
    return "BIT_LENGTH($col)";
}

sub char_length {
    my ( $self, $col ) = @_;
    return "CHAR_LENGTH($col)";
}




1;


__END__
