package App::DBBrowser;

use warnings;
use strict;
use 5.008003;
no warnings 'utf8';

our $VERSION = '1.058';

use Encode                qw( decode );
use File::Basename        qw( basename );
use File::Spec::Functions qw( catfile catdir );
use Getopt::Long          qw( GetOptions );

use Encode::Locale   qw( decode_argv );
use File::HomeDir    qw();
use File::Which      qw( which );
use Term::Choose     qw();
use Term::TablePrint qw( print_table );

use App::DBBrowser::Opt;
use App::DBBrowser::DB;
#use App::DBBrowser::Join_Union;  # 'require'-d
#use App::DBBrowser::CreateTable; # 'require'-d
use App::DBBrowser::Table;
use App::DBBrowser::Auxil;

BEGIN {
    decode_argv(); # not at the end of the BEGIN block if less than perl 5.16
    1;
}


sub new {
    my ( $class ) = @_;
    my $info = {
        lyt_1      => {                      layout => 1, order => 0, justify => 2, clear_screen => 1, mouse => 0, undef => '<<'     },
        lyt_stmt_h => { prompt => 'Choose:', layout => 1, order => 0, justify => 2, clear_screen => 0, mouse => 0, undef => '<<'     },
        lyt_3      => {                      layout => 3,             justify => 0, clear_screen => 1, mouse => 0, undef => '  BACK' },
        lyt_stmt_v => { prompt => 'Choose:', layout => 3,             justify => 0, clear_screen => 0, mouse => 0, undef => '  BACK' },
        lyt_stop   => {                                                             clear_screen => 0, mouse => 0                    },
        quit       => 'QUIT',
        back       => 'BACK',
        _quit      => '  QUIT',
        _back      => '  BACK',
        _continue  => '  CONTINUE',
        _confirm   => '  CONFIRM',
        _reset     => '  RESET',
        ok         => '- OK -',
        back_short => '  <=',
        clear_screen      => "\e[H\e[J",
        line_fold         => { Charset=> 'utf8', OutputCharset => '_UNICODE_', Urgent => 'FORCE' },
        config_generic    => 'Generic',
        stmt_init_tab     => 4,
        avail_aggregate   => [ "AVG(X)", "COUNT(X)", "COUNT(*)", "MAX(X)", "MIN(X)", "SUM(X)" ],
        avail_operators   => [ "REGEXP", "REGEXP_i", "NOT REGEXP", "NOT REGEXP_i", "LIKE", "NOT LIKE",
                               "IS NULL", "IS NOT NULL", "IN", "NOT IN", "BETWEEN", "NOT BETWEEN",
                               " = ", " != ", " <> ", " < ", " > ", " >= ", " <= ",
                               " = col", " != col", " <> col", " < col", " > col", " >= col", " <= col",
                               "LIKE %col%", "NOT LIKE %col%",  "LIKE col%", "NOT LIKE col%", "LIKE %col", "NOT LIKE %col" ],
                               # "LIKE col", "NOT LIKE col"
        lock             => 0,
        scalar_func_h    => { Epoch_to_Date => 'DATE', Truncate => 'TRUNC', Epoch_to_DateTime => 'DATETIME',
                              Bit_Length => 'BIT_LENGTH', Char_Length => 'CHAR_LENGTH' },
        scalar_func_keys => [ qw( Epoch_to_Date Bit_Length Truncate Char_Length Epoch_to_DateTime ) ],
        csv_opt          => [ qw( allow_loose_escapes allow_loose_quotes allow_whitespace auto_diag
                                  blank_is_undef binary empty_is_undef eol escape_char quote_char sep_char ) ],
    };
    return bless { info => $info }, $class;
}


sub __init {
    my ( $self ) = @_;
    my $home = decode( 'locale', File::HomeDir->my_home() );
    if ( ! $home ) {
        print "'File::HomeDir->my_home()' could not find the home directory!\n";
        print "'db-browser' requires a home directory\n";
        exit;
    }
    my $config_home;
    if ( which( 'xdg-user-dir' ) ) {
        $config_home = decode 'locale_fs', File::HomeDir::FreeDesktop->my_config();
    }
    else {
        $config_home = decode 'locale_fs', File::HomeDir->my_data();
    }
    my $app_dir = $config_home ? catdir( $config_home, 'db_browser' ) : catdir( $home, '.db_browser' );
    mkdir $app_dir or die $! if ! -d $app_dir;
    $self->{info}{home_dir}      = $home;
    $self->{info}{app_dir}       = $app_dir;
    $self->{info}{conf_file_fmt} = catfile $app_dir, 'config_%s.json';
    $self->{info}{db_cache_file} = catfile $app_dir, 'cache_db_search.json';
    $self->{info}{input_files}   = catfile $app_dir, 'file_history.txt';

    if ( ! eval {
        my $obj_opt = App::DBBrowser::Opt->new( $self->{info}, {}, {} );
        $self->{opt}    = $obj_opt->__read_config_files();
        $self->{db_opt} = $obj_opt->__read_db_config_files();
        my $help;
        GetOptions (
            'h|?|help' => \$help,
            's|search' => \$self->{info}{sqlite_search},
        );
        if ( $help ) {
            if ( $self->{opt}{table}{mouse} ) {
                for my $key ( keys %{$self->{info}} ) {
                    next if $key !~ /^lyt_/;
                    $self->{info}{$key}{mouse} = $self->{opt}{table}{mouse};
                }
            }
            ( $self->{opt}, $self->{db_opt} ) = $obj_opt->__set_options();
            if ( defined $self->{opt}{table}{mouse} ) {
                for my $key ( keys %{$self->{info}} ) {
                    next if $key !~ /^lyt_/;
                    $self->{info}{$key}{mouse} = $self->{opt}{table}{mouse};
                }
            }
        }
        1 }
    ) {
        my $auxil = App::DBBrowser::Auxil->new( $self->{info} );
        $auxil->__print_error_message( $@, 'Configfile/Options' );
        my $obj_opt = App::DBBrowser::Opt->new( $self->{info}, {}, {} );
        $self->{opt} = $obj_opt->defaults();
        while ( $ARGV[0] && $ARGV[0] =~ /^-/ ) {
            my $arg = shift @ARGV;
            last if $arg eq '--';
        }
    }
    if ( $self->{opt}{table}{mouse} ) {
        for my $key ( keys %{$self->{info}} ) {
            next if $key !~ /^lyt_/;
            $self->{info}{$key}{mouse} = $self->{opt}{table}{mouse};
        }
    }
}


sub __prepare_connect_parameter {
    my ( $self, $db ) = @_;
    my $obj_db = App::DBBrowser::DB->new( $self->{info}, $self->{opt} );
    my $env_variables = $obj_db->environment_variables();
    my $read_arg      = $obj_db->read_arguments();
    my $chosen_arg    = $obj_db->choose_arguments();
    my $connect_parameter = {
        use_env_var => {},
        required    => {},
        keep_secret => {},
        read_arg    => {},
        chosen_arg  => {},
        dir_sqlite  => [],
    };
    my $db_plugin = $self->{info}{db_plugin};
    my $section = $db ? $db_plugin . '_' . $db : $db_plugin;
    for my $env_var ( @$env_variables ) {
        if ( defined $db && ! defined $self->{db_opt}{$section}{$env_var} ) {
            $section = $db_plugin;
        }
        $connect_parameter->{use_env_var}{$env_var} = $self->{db_opt}{$section}{$env_var};
    }
    for my $option ( keys %{$self->{db_opt}{$db_plugin}} ) {
        if ( defined $db && ! defined $self->{db_opt}{$section}{$option} ) {
            $section = $db_plugin;
        }
        if ( defined $self->{info}{driver_prefix} && $option =~ /^\Q$self->{info}{driver_prefix}\E/ ) {
            $connect_parameter->{chosen_arg}{$option} = $self->{db_opt}{$section}{$option};
        }
    }
    for my $attr ( @$chosen_arg ) {
        my $name = $attr->{name};
        if ( defined $db && ! defined $self->{db_opt}{$section}{$name} ) {
            $section = $db_plugin;
        }
        if ( ! defined $self->{db_opt}{$section}{$name} ) {
            $self->{db_opt}{$section}{$name} = $attr->{avail_values}[$attr->{default_index}];
        }
        $connect_parameter->{chosen_arg}{$name} = $self->{db_opt}{$section}{$name};
    }
    for my $item ( @$read_arg ) {
        my $name = $item->{name};
        my $required_field = 'field_' . $name;
        $connect_parameter->{keep_secret}{$name} = $item->{keep_secret};
        if ( defined $db && ! defined $self->{db_opt}{$section}{$required_field} ) {
            $section = $db_plugin;
        }
        if ( ! defined $self->{db_opt}{$section}{$required_field} ) {
            $self->{db_opt}{$section}{$required_field} = 1; # All fields required by default
        }
        $connect_parameter->{required}{$name} = $self->{db_opt}{$section}{$required_field};
        if ( ! $self->{info}{login_error} ) {
            if ( defined $db && ! defined $self->{db_opt}{$section}{$name} ) {
                $section = $db_plugin;
            }
            $connect_parameter->{read_arg}{$name} = $self->{db_opt}{$section}{$name};
        }
    }
    if ( $self->{info}{db_driver} eq 'SQLite' && ! defined $self->{db_opt}{$db_plugin}{directories_sqlite} ) {
        $self->{db_opt}{$db_plugin}{directories_sqlite} = [ $self->{info}{home_dir} ];
    }
    $connect_parameter->{dir_sqlite} = $self->{db_opt}{$db_plugin}{directories_sqlite};
    if ( exists $self->{info}{login_error} ) {
        delete $self->{info}{login_error};
    }
    return $connect_parameter;
}


sub run {
    my ( $self ) = @_;
    $self->__init();
    my $lyt_3 = Term::Choose->new( $self->{info}{lyt_3} );
    my $auxil = App::DBBrowser::Auxil->new( $self->{info} );
    my $auto_one = 0;

    DB_PLUGIN: while ( 1 ) {

        my $db_plugin;
        if ( @{$self->{opt}{G}{db_plugins}} == 1 ) {
            $auto_one++;
            $db_plugin = $self->{opt}{G}{db_plugins}[0];
        }
        else {
            # Choose
            $db_plugin = $lyt_3->choose(
                [ undef, @{$self->{opt}{G}{db_plugins}} ],
                { %{$self->{info}{lyt_1}}, prompt => 'DB Plugin: ', undef => $self->{info}{quit} }
            );
            last DB_PLUGIN if ! defined $db_plugin;
        }
        $self->{info}{db_plugin} = $db_plugin;
        my $obj_db;
        if ( ! eval {
            $obj_db = App::DBBrowser::DB->new( $self->{info}, $self->{opt} );
            $self->{info}{db_driver} = $obj_db->db_driver();
            die "No database driver!" if ! $self->{info}{db_driver};
            $self->{info}{driver_prefix} = $obj_db->driver_prefix(); #
            1 }
        ) {
            $auxil->__print_error_message( $@, 'DB plugin - driver - prefix' );
            next DB_PLUGIN;
        }
        my $db_driver = $self->{info}{db_driver};

        # DATABASES

        my $databases = [];
        if ( ! eval {
            my $connect_parameter = $self->__prepare_connect_parameter();
            my ( $user_db, $system_db ) = $obj_db->available_databases( $connect_parameter );
            $user_db   = [] if ! defined $user_db;
            $system_db = [] if ! defined $system_db;
            if ( $db_driver eq 'SQLite' ) {
                $databases = [ @$user_db, @$system_db ];
            }
            else {
                $databases = [ map( "- $_", @$user_db ), map( "  $_", @$system_db ) ];
            }
            $self->{info}{sqlite_search} = 0 if $self->{info}{sqlite_search};
            1 }
        ) {
            $auxil->__print_error_message( $@, 'Available databases' );
            $self->{info}{login_error} = 1;
            next DB_PLUGIN;
        }
        if ( ! @$databases ) {
            $auxil->__print_error_message( "no $db_driver-databases found\n" );
            exit if @{$self->{opt}{G}{db_plugins}} == 1;
            next DB_PLUGIN;
        }

        my $db;
        my $old_idx_db = 0;

        DATABASE: while ( 1 ) {

            if ( @$databases == 1 ) {
                $db = $databases->[0];
                $auto_one++ if $auto_one == 1;
            }
            else {
                my $back;
                if ( $db_driver eq 'SQLite' ) {
                    $back = $auto_one ? $self->{info}{quit} : $self->{info}{back};
                }
                else {
                    $back = $auto_one ? $self->{info}{_quit} : $self->{info}{_back};
                }
                my $prompt = 'Choose Database:';
                my $choices_db = [ undef, @$databases ];
                # Choose
                my $idx_db = $lyt_3->choose(
                    $choices_db,
                    { prompt => $prompt, index => 1, default => $old_idx_db, undef => $back }
                );
                $db = undef;
                $db = $choices_db->[$idx_db] if defined $idx_db;
                if ( ! defined $db ) {
                    last DB_PLUGIN if @{$self->{opt}{G}{db_plugins}} == 1;
                    next DB_PLUGIN;
                }
                if ( $self->{opt}{G}{menus_db_memory} ) {
                    if ( $old_idx_db == $idx_db ) {
                        $old_idx_db = 0;
                        next DATABASE;
                    }
                    else {
                        $old_idx_db = $idx_db;
                    }
                }
            }
            $db =~ s/^[-\ ]\s// if $db_driver ne 'SQLite';

            # DB-HANDLE

            my $dbh;
            if ( ! eval {
                print $self->{info}{clear_screen};
                print 'DB: "'. basename( $db ) . '"' . "\n";
                my $connect_parameter = $self->__prepare_connect_parameter( $db );
                $dbh = $obj_db->get_db_handle( $db, $connect_parameter );
                1 }
            ) {
                $auxil->__print_error_message( $@, 'Get database handle' );
                # remove database from @databases
                $self->{info}{login_error} = 1;
                next DATABASE;
            }

            # SCHEMAS

            my @schemas;
            if ( ! eval {
                my ( $user_schemas, $system_schemas ) = $obj_db->get_schema_names( $dbh, $db );
                $user_schemas   = [] if ! defined $user_schemas;
                $system_schemas = [] if ! defined $system_schemas;
                if ( ( @$user_schemas + @$system_schemas ) > 1 ) {
                    @schemas = ( map( "- $_", @$user_schemas ), map( "  $_", @$system_schemas ) );
                }
                else {
                    @schemas = ( @$user_schemas , @$system_schemas );
                }
                1 }
            ) {
                $auxil->__print_error_message( $@, 'Get schema names' );
                next DATABASE;
            }
            my $old_idx_sch = 0;

            SCHEMA: while ( 1 ) {

                my $schema;
                if ( $self->{info}{redo_schema} ) {
                    $schema = $self->{info}{redo_schema};
                    delete $self->{info}{redo_schema};
                }
                elsif ( @schemas <= 1 ) {
                    $schema = $schemas[0];
                    $auto_one++ if $auto_one == 2
                }
                else {
                    my $back   = $auto_one == 2 ? $self->{info}{_quit} : $self->{info}{_back};
                    my $prompt = 'DB "'. basename( $db ) . '" - choose Schema:';
                    my $choices_schema = [ undef, @schemas ];
                    # Choose
                    my $idx_sch = $lyt_3->choose(
                        $choices_schema,
                        { prompt => $prompt, index => 1, default => $old_idx_sch, undef => $back }
                    );
                    $schema = $choices_schema->[$idx_sch] if defined $idx_sch;
                    if ( ! defined $schema ) {
                        next DATABASE  if @$databases                    > 1;
                        next DB_PLUGIN if @{$self->{opt}{G}{db_plugins}} > 1;
                        last DB_PLUGIN;
                    }
                    if ( $self->{opt}{G}{menus_db_memory} ) {
                        if ( $old_idx_sch == $idx_sch ) {
                            $old_idx_sch = 0;
                            next SCHEMA;
                        }
                        else {
                            $old_idx_sch = $idx_sch;
                        }
                    }
                    $schema =~ s/^[-\ ]\s//;
                }

                # TABLES

                my $data = {};
                my @tables;
                if ( ! eval {
                    my ( $user_tbl, $system_tbl ) = $obj_db->get_table_names( $dbh, $schema );
                    $user_tbl   = [] if ! defined $user_tbl;
                    $system_tbl = [] if ! defined $system_tbl;
                    $data->{tables} = [ @$user_tbl, @$system_tbl ];
                    @tables = ( map( "- $_", @$user_tbl ), map( "  $_", @$system_tbl ) );
                    1 }
                ) {
                    $auxil->__print_error_message( $@, 'Get table names' );
                    next DATABASE;
                }
                my $old_idx_tbl = 1;

                TABLE: while ( 1 ) {

                    my $db_string = 'DB: "'. basename( $db ) . ( @schemas > 1 ? '.' . $schema : '' ) . '"';
                    my ( $join, $union, $new, $db_setting ) = ( '  Join', '  Union', '  New', '  Database settings' );
                    my $hidden = $db_string;
                    my $choices_table = [ $hidden, undef, @tables, $join, $union, $db_setting ];
                    my $back = $auto_one == 3 ? $self->{info}{_quit} : $self->{info}{_back};
                    # Choose
                    my $idx_tbl = $lyt_3->choose(
                        $choices_table,
                        { prompt => '', index => 1, default => $old_idx_tbl, undef => $back }
                    );
                    my $table = $choices_table->[$idx_tbl] if defined $idx_tbl;
                    if ( ! defined $table ) {
                        next SCHEMA    if @schemas                       > 1;
                        next DATABASE  if @$databases                    > 1;
                        next DB_PLUGIN if @{$self->{opt}{G}{db_plugins}} > 1;
                        last DB_PLUGIN;
                    }
                    if ( $self->{opt}{G}{menus_db_memory} ) {
                        if ( $old_idx_tbl == $idx_tbl ) {
                            $old_idx_tbl = 1;
                            next TABLE;
                        }
                        else {
                            $old_idx_tbl = $idx_tbl;
                        }
                    }
                    if ( $table eq $db_setting ) {
                        my $new_db_settings;
                        if ( ! eval {
                            my $obj_opt = App::DBBrowser::Opt->new( $self->{info}, $self->{opt}, $self->{db_opt} );
                            $new_db_settings = $obj_opt->__database_setting( $db );
                            1 }
                        ) {
                            $auxil->__print_error_message( $@, 'Database settings' );
                            next TABLE;
                        }
                        next SCHEMA if $new_db_settings;
                        next TABLE;
                    }
                    my $sql = {
                        print => {
                            db     => $db,
                            schema => $schema,
                        }
                    };
                    if ( $table eq $hidden ) { # prompt "table-menu"
                        my $old_idx_hdn = 0;

                        HIDDEN: while ( 1 ) {
                            my ( $create_table, $drop_table ) = ( '- CREATE table', '- DROP   table' );
                            my $choices_hidden = [ undef, $create_table, $drop_table ];
                            # Choose
                            my $idx_hdn = $lyt_3->choose(
                                $choices_hidden,
                                { prompt => $db_string, index => 1, default => $old_idx_hdn, undef => $self->{info}{_back} }
                            );
                            my $choice = $choices_hidden->[$idx_hdn] if defined $idx_hdn;
                            if ( ! defined $choice ) {
                                next TABLE;
                            }
                            if ( $self->{opt}{G}{menus_db_memory} ) {
                                if ( $old_idx_hdn == $idx_hdn ) {
                                    $old_idx_hdn = 0;
                                    next HIDDEN;
                                }
                                else {
                                    $old_idx_hdn = $idx_hdn;
                                }
                            }
                            if ( $db_driver eq 'SQLite' ) {
                                $dbh->disconnect();
                                my $connect_parameter = $self->__prepare_connect_parameter( $db );
                                $dbh = $obj_db->get_db_handle( $db, $connect_parameter );
                            }
                            if ( $choice eq $create_table ) {
                                if ( ! eval {
                                    require App::DBBrowser::CreateTable;
                                    my $obj_ct = App::DBBrowser::CreateTable->new( $self->{info}, $self->{opt} );
                                    $table = $obj_ct->__create_new_table( $sql, $dbh );
                                    1 }
                                ) {
                                    $auxil->__print_error_message( $@, 'Create table' );
                                    next HIDDEN;
                                }
                                next HIDDEN if ! $table;
                                $self->{info}{redo_schema} = $schema;
                                next SCHEMA;
                            }
                            elsif ( $choice eq $drop_table ) {
                                my $ok;
                                if ( ! eval {
                                    require App::DBBrowser::CreateTable;
                                    my $obj_ct = App::DBBrowser::CreateTable->new( $self->{info}, $self->{opt} );
                                    $ok = $obj_ct->__delete_table( $sql, $dbh );
                                    1 }
                                ) {
                                    $auxil->__print_error_message( $@, 'Drop table' );
                                    next HIDDEN;
                                }
                                next HIDDEN if ! $ok;
                                $self->{info}{redo_schema} = $schema;
                                next SCHEMA;
                            }
                        }
                    }
                    if ( $table eq $join ) {
                        $self->{info}{multi_tbl} = 'join';
                        my $ok;
                        if ( ! eval {
                            require App::DBBrowser::Join_Union;
                            my $obj_ju = App::DBBrowser::Join_Union->new( $self->{info}, $self->{opt} );
                            $ok = $obj_ju->__join_tables( $sql, $dbh, $data );
                            $table = 'joined_tables';
                            $sql->{print}{table} = $table;
                            1 }
                        ) {
                            $auxil->__print_error_message( $@, 'Join tables' );
                            next TABLE;
                        }
                        next TABLE if ! $ok;
                    }
                    elsif ( $table eq $union ) {
                        $self->{info}{multi_tbl} = 'union';
                        my $ok;
                        if ( ! eval {
                            require App::DBBrowser::Join_Union;
                            my $obj_ju = App::DBBrowser::Join_Union->new( $self->{info}, $self->{opt} );
                            $ok = $obj_ju->__union_tables( $sql, $dbh, $data );
                            if ( $sql->{union_all} ) {
                                $table = 'union_all_tables';
                            }
                            else {
                                $table = 'union_selected_tables';
                            }
                            delete $sql->{union_all};
                            $sql->{print}{table} = $table;
                            1 }
                        ) {
                            $auxil->__print_error_message( $@, 'Union tables' );
                            next TABLE;
                        }
                        next TABLE if ! $ok;
                    }
                    else {
                        $self->{info}{multi_tbl} = '';
                        $table =~ s/^[-\ ]\s//;
                        my $qt_table = $dbh->quote_identifier( undef, $schema, $table );
                        my $sth = $dbh->prepare( "SELECT * FROM " . $qt_table . " LIMIT 0" );
                        $sth->execute();
                        for my $col ( @{$sth->{NAME}} ) {
                            $sql->{quote}{columns}{$col} = $dbh->quote_identifier( $col );
                            push @{$sql->{print}{columns}}, $col;
                        }
                        $sth->finish();
                        $sql->{quote}{table} = $qt_table;
                        $sql->{print}{table} = $table;
                    }
                    #if ( ! eval {
                         $self->__browse_the_table( $dbh, $sql );
                    #    1 }
                    #) {
                    #    $auxil->__print_error_message( $@, 'Browse table' );
                    #    next TABLE;
                    #}
                }
            }
            $dbh->disconnect();
        }
    }
}


sub __browse_the_table {
    my ( $self, $dbh, $sql ) = @_;
    my $db_plugin = $self->{info}{db_plugin};
    my $db        = $sql->{print}{db};
    $self->{opt}{table}{binary_filter} = $self->{db_opt}{$db_plugin . '_' . $db}{binary_filter};
    if ( ! defined $self->{opt}{table}{binary_filter} ) {
        $self->{opt}{table}{binary_filter} = $self->{db_opt}{$db_plugin}{binary_filter};
    }
    $self->{info}{lock} = $self->{opt}{G}{lock_stmt};
    my $auxil = App::DBBrowser::Auxil->new( $self->{info} );
    $auxil->__reset_sql( $sql );

    PRINT_TABLE: while ( 1 ) {
        my $all_arrayref;
        if ( ! eval {
            my $obj_table = App::DBBrowser::Table->new( $self->{info}, $self->{opt} );
            ( $all_arrayref, $sql ) = $obj_table->__on_table( $sql, $dbh );
            1 }
        ) {
            $auxil->__print_error_message( $@, 'Print table' );
            next PRINT_TABLE;
        }
        if ( ! defined $all_arrayref ) {
            last PRINT_TABLE;
        }


        print_table( $all_arrayref, $self->{opt}{table} );


        delete $self->{opt}{table}{max_rows};
    }
    if ( $db_plugin eq 'Debug' ) {
        my $obj_db = App::DBBrowser::DB->new( $self->{info}, $self->{opt} );
        $obj_db->debug( $dbh, $self->{info}, $self->{opt}, $self->{db_opt} );
    }
}


1;


__END__

=pod

=encoding UTF-8

=head1 NAME

App::DBBrowser - Browse SQLite/MySQL/PostgreSQL databases and their tables interactively.

=head1 VERSION

Version 1.058

=head1 DESCRIPTION

See L<db-browser> for further information.

=head1 AUTHOR

Matthäus Kiem <cuer2s@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2018 Matthäus Kiem.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For
details, see the full text of the licenses in the file LICENSE.

=cut
