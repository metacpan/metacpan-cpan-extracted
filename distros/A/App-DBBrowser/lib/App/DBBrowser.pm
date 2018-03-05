package App::DBBrowser;

use warnings;
use strict;
use 5.008003;
no warnings 'utf8';

our $VERSION = '2.003';

use Encode                qw( decode );
use File::Basename        qw( basename );
use File::Spec::Functions qw( catfile catdir );
use Getopt::Long          qw( GetOptions );

use Encode::Locale qw( decode_argv );
use File::HomeDir  qw();
use File::Which    qw( which );

use Term::Choose     qw( choose );
use Term::TablePrint qw( print_table );

#use App::DBBrowser::AttachDB;    # 'require'-d
use App::DBBrowser::Auxil;
#use App::DBBrowser::CreateTable; # 'require'-d
use App::DBBrowser::DB;
#use App::DBBrowser::Join_Union;  # 'require'-d
use App::DBBrowser::Opt;
use App::DBBrowser::OptDB;
use App::DBBrowser::Table;


BEGIN {
    decode_argv(); # not at the end of the BEGIN block if less than perl 5.16
    1;
}


sub new {
    my ( $class ) = @_;
    my $info = {
        lyt_m         => { undef => '<<'                                                                 },
        lyt_3         => { undef => '  BACK', layout => 3,                      clear_screen => 1        },
        lyt_stmt_h    => { undef => '<<',     layout => 1, prompt => 'Choose:', order => 0, justify => 2 },
        lyt_stmt_v    => { undef => '  BACK', layout => 3, prompt => 'Choose:'                           },
        quit          => 'QUIT',
        back          => 'BACK',
        _quit         => '  QUIT',
        _back         => '  BACK',
        _continue     => '  CONTINUE',
        _confirm      => '  CONFIRM',
        _reset        => '  RESET',
        ok            => '-OK-',
        back_s        => '<<',
        back_config   => '  <=',
        clear_screen  => "\e[H\e[J", #
        stmt_init_tab => 4,
    };
    return bless { i => $info }, $class;
}
# <, >, ... work numeric:

# MySQL     mysql_bind_type_guessing    enabled     always
# MySQL     mysql_bind_type_guessing    disabled    with INT

# postgreSQL                                        with INT

# SQLite                                            with INT
# SQLite    sqlite_see_if_its_a_number  enabled     with no data tpyes


sub __init {
    my ( $sf ) = @_;
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
    my $app_dir;
    if ( $config_home ) {
        $app_dir = catdir( $config_home, 'db_browser' );
    }
    else {
        $app_dir = catdir( $home, '.db_browser' );
    }
    mkdir $app_dir or die $! if ! -d $app_dir;
    $sf->{i}{home_dir}         = $home;
    $sf->{i}{app_dir}          = $app_dir;
    $sf->{i}{file_settings}    = catfile $app_dir, 'general_settings.json';
    $sf->{i}{conf_file_fmt}    = catfile $app_dir, 'config_%s.json';
    $sf->{i}{input_files}      = catfile $app_dir, 'file_history.txt';
    $sf->{i}{file_attached_db} = catfile $app_dir, 'SQLite_attached_DB.json';
    # check all info

    if ( ! eval {
        my $obj_opt = App::DBBrowser::Opt->new( $sf->{i}, {} ); #
        my $help;
        GetOptions (
            'h|?|help' => \$help,
            's|search' => \$sf->{i}{sqlite_search},
        );
        if ( $help ) {
            if ( $sf->{o}{table}{mouse} ) {
                for my $key ( keys %{$sf->{i}} ) {
                    next if $key !~ /^lyt_/;
                    $sf->{i}{$key}{mouse} = $sf->{o}{table}{mouse};
                }
            }
            $sf->{o} = $obj_opt->set_options(); #
            if ( defined $sf->{o}{table}{mouse} ) {
                for my $key ( keys %{$sf->{i}} ) {
                    next if $key !~ /^lyt_/;
                    $sf->{i}{$key}{mouse} = $sf->{o}{table}{mouse};
                }
            }
        }
        else {
            $sf->{o} = $obj_opt->read_config_files(); #
        }
        1 }
    ) {
        my $ax = App::DBBrowser::Auxil->new( $sf->{i}, {} );
        $ax->print_error_message( $@, 'Configfile/Options' );
        my $obj_opt = App::DBBrowser::Opt->new( $sf->{i}, {} ); #
        $sf->{o} = $obj_opt->defaults();
        while ( $ARGV[0] && $ARGV[0] =~ /^-/ ) {
            my $arg = shift @ARGV;
            last if $arg eq '--';
        }
    }
    if ( $sf->{o}{table}{mouse} ) {
        for my $key ( keys %{$sf->{i}} ) {
            next if $key !~ /^lyt_/;
            $sf->{i}{$key}{mouse} = $sf->{o}{table}{mouse};
        }
    }
}


sub run {
    my ( $sf ) = @_;
    $sf->__init();
    my $lyt_3 = Term::Choose->new( $sf->{i}{lyt_3} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o} );
    my $auto_one = 0;

    DB_PLUGIN: while ( 1 ) {

        my $plugin;
        if ( @{$sf->{o}{G}{plugins}} == 1 ) {
            $auto_one++;
            $plugin = $sf->{o}{G}{plugins}[0];
        }
        else {
            # Choose
            $plugin = choose(
                [ undef, @{$sf->{o}{G}{plugins}} ],
                { %{$sf->{i}{lyt_m}}, order => 0, clear_screen => 1,
                  justify => 2, prompt => 'DB Plugin: ', undef => $sf->{i}{quit} }
            );
            last DB_PLUGIN if ! defined $plugin;
        }
        $plugin = 'App::DBBrowser::DB::' . $plugin;
        $sf->{i}{plugin} = $plugin;
        my $obj_db;
        if ( ! eval {
            $obj_db = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
            $sf->{i}{driver} = $obj_db->driver();
            die "No database driver!" if ! $sf->{i}{driver};
            1 }
        ) {
            $ax->print_error_message( $@, 'load plugin' );
            next DB_PLUGIN if @{$sf->{o}{G}{plugins}} > 1;
            last DB_PLUGIN;
        }
        my $driver = $sf->{i}{driver};
        my $obj_o_db = App::DBBrowser::OptDB->new( $sf->{i}, $sf->{o} );
        my $db_o = $obj_o_db->__read_db_config_files();

        # DATABASES

        my @databases;
        my ( $user_dbs, $sys_dbs ) = ( [], [] ); #
        if ( ! eval {
            ( $user_dbs, $sys_dbs ) = $obj_db->databases( $obj_o_db->connect_parameter( $db_o ) );
            if ( $driver eq 'SQLite' ) {
                @databases = ( @$user_dbs, $sf->{o}{G}{meta} ? @$sys_dbs : () );
            }
            else {
                @databases = ( map( "- $_", @$user_dbs ), $sf->{o}{G}{meta} ? map( "  $_", @$sys_dbs ) : () );
            }
            $sf->{i}{sqlite_search} = 0 if $sf->{i}{sqlite_search};
            1 }
        ) {
            $ax->print_error_message( $@, 'Available databases' );
            $sf->{i}{login_error} = 1;
            next DB_PLUGIN if @{$sf->{o}{G}{plugins}} > 1;
            last DB_PLUGIN;
        }
        if ( ! @databases ) {
            $ax->print_error_message( "no $driver-databases found\n" );
            next DB_PLUGIN if @{$sf->{o}{G}{plugins}} > 1;
            last DB_PLUGIN;
        }
        my $db;
        my $old_idx_db = 0;

        DATABASE: while ( 1 ) {

            if ( $sf->{i}{redo_db} ) {
                $db = delete $sf->{i}{redo_db};
                $db = '- ' . $db if $driver ne 'SQLite';
            }
            elsif ( @databases == 1 ) {
                $db = $databases[0];
                $auto_one++ if $auto_one == 1;
            }
            else {
                my $back;
                if ( $driver eq 'SQLite' ) {
                    $back = $auto_one ? $sf->{i}{quit} : $sf->{i}{back};
                }
                else {
                    $back = $auto_one ? $sf->{i}{_quit} : $sf->{i}{_back};
                }
                my $prompt = 'Choose Database:';
                my $choices_db = [ undef, @databases ];
                # Choose
                $ENV{TC_RESET_AUTO_UP} = 0;
                my $idx_db = $lyt_3->choose(
                    $choices_db,
                    { prompt => $prompt, index => 1, default => $old_idx_db, undef => $back }
                );
                $db = undef;
                $db = $choices_db->[$idx_db] if defined $idx_db;
                if ( ! defined $db ) {
                    next DB_PLUGIN if @{$sf->{o}{G}{plugins}} > 1;
                    last DB_PLUGIN;
                }
                if ( $sf->{o}{G}{menu_memory} ) {
                    if ( $old_idx_db == $idx_db && ! $ENV{TC_RESET_AUTO_UP} ) {
                        $old_idx_db = 0;
                        next DATABASE;
                    }
                    else {
                        $old_idx_db = $idx_db;
                    }
                }
                delete $ENV{TC_RESET_AUTO_UP};
            }
            $db =~ s/^[-\ ]\s// if $driver ne 'SQLite';

            # DB-HANDLE

            my $dbh;
            if ( ! eval {
                print $sf->{i}{clear_screen};
                print 'DB: "'. basename( $db ) . '"' . "\n";
                $dbh = $obj_db->db_handle( $db, $obj_o_db->connect_parameter( $db_o, $db) );
                $sf->{i}{sep_char} = $dbh->get_info(41)  || '.'; # SQL_CATALOG_NAME_SEPARATOR
                1 }
            ) {
                $ax->print_error_message( $@, 'Get database handle' );
                # remove database from @databases
                $sf->{i}{login_error} = 1;
                $dbh->disconnect() if defined $dbh || $dbh->{Active};
                next DATABASE  if @databases              > 1;
                next DB_PLUGIN if @{$sf->{o}{G}{plugins}} > 1;
                last DB_PLUGIN;
            }
            $sf->{i}{db_attached} = 0;
            if ( $driver eq 'SQLite' && -s $sf->{i}{file_attached_db} ) {
                my $h_ref = $ax->read_json( $sf->{i}{file_attached_db} );
                my $attached_db = $h_ref->{$db} || [];
                if ( @$attached_db ) {
                    for my $ref ( @$attached_db ) {
                        my $stmt = sprintf "ATTACH DATABASE %s AS %s", $dbh->quote_identifier( $ref->[0] ), $dbh->quote( $ref->[1] );
                        $dbh->do( $stmt );
                    }
                    $sf->{i}{db_attached} = 1;
                    if ( ! exists $sf->{i}{backup_qualy} ) {
                        $sf->{i}{backup_qualy} = $sf->{o}{G}{qualified_table_name};
                    }
                    $sf->{o}{G}{qualified_table_name} = 1;
                }
            }
            if ( exists $sf->{i}{backup_qualy} && ! $sf->{i}{db_attached} ) {
                $sf->{o}{G}{qualified_table_name} = delete $sf->{i}{backup_qualy};
            }

            # SCHEMAS

            my @schemas;
            my ( $user_schemas, $sys_schemas ) = ( [], [] );
            if ( ! eval {
                ( $user_schemas, $sys_schemas ) = $obj_db->schemas( $dbh, $db );
                @schemas = ( map( "- $_", @$user_schemas ), $sf->{o}{G}{meta} ? map( "  $_", @$sys_schemas ) : () );
                1 }
            ) {
                $ax->print_error_message( $@, 'Get schema names' );
                $dbh->disconnect();
                next DATABASE  if @databases              > 1;
                next DB_PLUGIN if @{$sf->{o}{G}{plugins}} > 1;
                last DB_PLUGIN;
            }
            my $old_idx_sch = 0;

            SCHEMA: while ( 1 ) {

                my $schema;
                if ( $sf->{i}{redo_schema} ) {
                    $schema = delete $sf->{i}{redo_schema};
                }
                elsif ( @schemas <= 1 ) {
                    $schema = $schemas[0];
                    $schema =~ s/^[-\ ]\s//;
                    $auto_one++ if $auto_one == 2
                }
                else {
                    my $back   = $auto_one == 2 ? $sf->{i}{_quit} : $sf->{i}{_back};
                    my $prompt = 'DB "'. basename( $db ) . '" - choose Schema:';
                    my $choices_schema = [ undef, @schemas ];
                    # Choose
                    $ENV{TC_RESET_AUTO_UP} = 0;
                    my $idx_sch = $lyt_3->choose(
                        $choices_schema,
                        { prompt => $prompt, index => 1, default => $old_idx_sch, undef => $back }
                    );
                    $schema = $choices_schema->[$idx_sch] if defined $idx_sch;
                    if ( ! defined $schema ) {
                        $dbh->disconnect();
                        next DATABASE  if @databases              > 1;
                        next DB_PLUGIN if @{$sf->{o}{G}{plugins}} > 1;
                        last DB_PLUGIN;
                    }
                    if ( $sf->{o}{G}{menu_memory} ) {
                        if ( $old_idx_sch == $idx_sch && ! $ENV{TC_RESET_AUTO_UP} ) {
                            $old_idx_sch = 0;
                            next SCHEMA;
                        }
                        else {
                            $old_idx_sch = $idx_sch;
                        }
                    }
                    delete $ENV{TC_RESET_AUTO_UP};
                    $schema =~ s/^[-\ ]\s//;
                }

                # TABLES

                my $data = {
                    db => $db,
                    schema => $schema,
                    user_dbs => $user_dbs,
                    sys_dbs  => $sys_dbs,
                    user_schemas => $user_schemas,
                    sys_schemas  => $sys_schemas,
                };
                my @tables;
                if ( ! eval {
                    ( $data->{tables}, $data->{user_tbls}, $data->{sys_tbls} ) = $sf->__tables_data( $dbh, $schema, $data );
                    @tables = (                     map( "- $_", sort @{$data->{user_tbls}} ),
                                $sf->{o}{G}{meta} ? map( "  $_", sort @{$data->{sys_tbls}} ) : () );
                    1 }
                ) {
                    $ax->print_error_message( $@, 'Get table names' );
                    next SCHEMA    if @schemas                > 1;
                    $dbh->disconnect();
                    next DATABASE  if @databases              > 1;
                    next DB_PLUGIN if @{$sf->{o}{G}{plugins}} > 1;
                    last DB_PLUGIN;
                }
                my $old_idx_tbl = 1;

                TABLE: while ( 1 ) {

                    my $db_string = 'DB: "'. basename( $db ) . ( @schemas > 1 ? '.' . $schema : '' ) . '"';
                    my ( $join, $union, $new, $db_setting ) = ( '  Join', '  Union', '  New', '  Database settings' );
                    my $hidden = $db_string;
                    my $choices_table = [ $hidden, undef, @tables, $join, $union, $db_setting ]; # db_setting only if any
                    my $back = $auto_one == 3 ? $sf->{i}{_quit} : $sf->{i}{_back};
                    # Choose
                    $ENV{TC_RESET_AUTO_UP} = 0;
                    my $idx_tbl = $lyt_3->choose(
                        $choices_table,
                        { prompt => '', index => 1, default => $old_idx_tbl, undef => $back }
                    );
                    my $table = $choices_table->[$idx_tbl] if defined $idx_tbl;
                    if ( ! defined $table ) {
                        next SCHEMA         if @schemas                > 1;
                        $dbh->disconnect();
                        next DATABASE       if @databases              > 1;
                        next DB_PLUGIN      if @{$sf->{o}{G}{plugins}} > 1;
                        last DB_PLUGIN;
                    }
                    if ( $sf->{o}{G}{menu_memory} ) {
                        if ( $old_idx_tbl == $idx_tbl && ! $ENV{TC_RESET_AUTO_UP} ) {
                            $old_idx_tbl = 1;
                            next TABLE;
                        }
                        else {
                            $old_idx_tbl = $idx_tbl;
                        }
                    }
                    delete $ENV{TC_RESET_AUTO_UP};
                    if ( $table eq $db_setting ) {
                        my $changed;
                        if ( ! eval {
                            my $obj_o_db = App::DBBrowser::OptDB->new( $sf->{i}, $sf->{o} );
                            $changed = $obj_o_db->database_setting( $db );
                            1 }
                        ) {
                            $ax->print_error_message( $@, 'Database settings' );
                            next TABLE;
                        }
                        if ( $changed ) {
                            $sf->{i}{redo_db} = $db;
                            $sf->{i}{redo_schema} = $schema;
                            $dbh->disconnect(); # reconnects
                            next DATABASE;
                        }
                        next TABLE;
                    }
                    if ( $table eq $hidden ) {
                        my $old_idx_hdn = 0;

                        HIDDEN: while ( 1 ) {
                            my ( $create_table, $drop_table, $attach_databases, $detach_databases ) = (
                                '- CREATE table', '- DROP   table', '- Attach DB', '- Detach DB'
                            );
                            my $choices_hidden = [ undef, $create_table, $drop_table ];
                            if ( $driver eq 'SQLite' ) {
                                push @$choices_hidden, $attach_databases;
                                push @$choices_hidden, $detach_databases if $sf->{i}{db_attached};
                            }
                            # Choose
                            $ENV{TC_RESET_AUTO_UP} = 0;
                            my $idx_hdn = $lyt_3->choose(
                                $choices_hidden,
                                { prompt => $db_string, index => 1, default => $old_idx_hdn, undef => $sf->{i}{_back} }
                            );
                            my $choice = $choices_hidden->[$idx_hdn] if defined $idx_hdn;
                            if ( ! defined $choice ) {
                                next TABLE;
                            }
                            if ( $sf->{o}{G}{menu_memory} ) {
                                if ( $old_idx_hdn == $idx_hdn && ! $ENV{TC_RESET_AUTO_UP} ) {
                                    $old_idx_hdn = 0;
                                    next HIDDEN;
                                }
                                else {
                                    $old_idx_hdn = $idx_hdn;
                                }
                            }
                            delete $ENV{TC_RESET_AUTO_UP};
                            if ( $choice eq $create_table || $choice eq $drop_table  ){
                                if ( $driver eq 'SQLite' ) {
                                    $dbh->disconnect();
                                    $dbh = $obj_db->db_handle( $db, $obj_o_db->connect_parameter( $db_o, $db ) );
                                }
                                if ( $choice eq $create_table ) {
                                    my $created;
                                    if ( ! eval {
                                        require App::DBBrowser::CreateTable;
                                        my $obj_ct = App::DBBrowser::CreateTable->new( $sf->{i}, $sf->{o} );
                                        $created = $obj_ct->create_new_table( $dbh, $data );
                                        1 }
                                    ) {
                                        $ax->print_error_message( $@, 'Create table' );
                                        next HIDDEN;
                                    }
                                    next HIDDEN if ! $created;
                                    $sf->{i}{redo_schema} = $schema;
                                    next SCHEMA;
                                }
                                elsif ( $choice eq $drop_table ) {
                                    my $deleted;
                                    if ( ! eval {
                                        require App::DBBrowser::CreateTable;
                                        my $obj_ct = App::DBBrowser::CreateTable->new( $sf->{i}, $sf->{o} );
                                        $deleted = $obj_ct->delete_table( $dbh, $data );
                                        1 }
                                    ) {
                                        $ax->print_error_message( $@, 'Drop table' );
                                        next HIDDEN;
                                    }
                                    next HIDDEN if ! $deleted;
                                    $sf->{i}{redo_schema} = $schema;
                                    next SCHEMA;
                                }
                            }
                            else {
                                if ( $choice eq $attach_databases ) {
                                    my $changed;
                                    if ( ! eval {
                                        require App::DBBrowser::AttachDB;
                                        my $att = App::DBBrowser::AttachDB->new( $sf->{i}, $sf->{o} );
                                        $changed = $att->attach_db( $dbh, $data );
                                        1 }
                                    ) {
                                        $ax->print_error_message( $@, 'Attach DB' );
                                        next HIDDEN;
                                    }
                                    $sf->{i}{redo_schema} = $schema;
                                    $sf->{i}{redo_db}     = $db;
                                    $dbh->disconnect();
                                    next DATABASE;
                                }
                                elsif ( $choice eq $detach_databases ) {
                                    if ( ! eval {
                                        require App::DBBrowser::AttachDB;
                                        my $att = App::DBBrowser::AttachDB->new( $sf->{i}, $sf->{o} );
                                        $att->detach_db( $dbh, $data );
                                        1 }
                                    ) {
                                        $ax->print_error_message( $@, 'Detach DB' );
                                        next HIDDEN;
                                    }
                                    $sf->{i}{redo_schema} = $schema;
                                    $sf->{i}{redo_db}     = $db;
                                    $dbh->disconnect();
                                    next DATABASE;
                                }
                            }
                        }
                    }
                    my ( $qt_table, $qt_columns );
                    if ( $table eq $join ) {
                        $sf->{i}{multi_tbl} = 'join';
                        if ( ! eval {
                            require App::DBBrowser::Join_Union;
                            my $obj_ju = App::DBBrowser::Join_Union->new( $sf->{i}, $sf->{o} );
                            ( $qt_table, $qt_columns ) = $obj_ju->join_tables( $dbh, $data );
                            1 }
                        ) {
                            $ax->print_error_message( $@, 'Join tables' );
                            next TABLE;
                        }
                        next TABLE if ! defined $qt_table;
                    }
                    elsif ( $table eq $union ) {
                        $sf->{i}{multi_tbl} = 'union';
                        my $ok;
                        if ( ! eval {
                            require App::DBBrowser::Join_Union;
                            my $obj_ju = App::DBBrowser::Join_Union->new( $sf->{i}, $sf->{o} );
                            ( $qt_table, $qt_columns ) = $obj_ju->union_tables( $dbh, $data );
                            1 }
                        ) {
                            $ax->print_error_message( $@, 'Union tables' );
                            next TABLE;
                        }
                        next TABLE if ! defined $qt_table;
                    }
                    else {
                        $sf->{i}{multi_tbl} = '';
                        $table =~ s/^[-\ ]\s//;
                        $qt_table = $ax->quote_table( $dbh, $data->{tables}{$table} );
                        my $sth = $dbh->prepare( "SELECT * FROM " . $qt_table . " LIMIT 0" );
                        $sth->execute() if $driver ne 'SQLite';
                        $qt_columns = $ax->quote_simple_many( $dbh, $sth->{NAME} );
                        $sth->finish();
                    }
                    #if ( ! eval {
                    $sf->__browse_the_table( $dbh, $qt_table, $qt_columns );
                    #    1 }
                    #) {
                    #    $ax->print_error_message( $@, 'Browse table' );
                    #    next TABLE;
                    #}
                }
            }
        }
    }
}


sub __browse_the_table {
    my ( $sf, $dbh, $qt_table, $qt_columns ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o} );
    $sf->{i}{lock} = $sf->{o}{G}{lock_stmt};
    my $sql = {};
    $ax->reset_sql( $sql );
    $sql->{table} = $qt_table;
    $sql->{cols} = $qt_columns;

    PRINT_TABLE: while ( 1 ) {
        my $all_arrayref;
        if ( ! eval {
            my $obj_table = App::DBBrowser::Table->new( $sf->{i}, $sf->{o} );
            ( $all_arrayref, $sql ) = $obj_table->on_table( $sql, $dbh );
            1 }
        ) {
            $ax->print_error_message( $@, 'Print table' );
            last PRINT_TABLE;
        }
        if ( ! defined $all_arrayref ) {
            last PRINT_TABLE;
        }

        print_table( $all_arrayref, $sf->{o}{table} );

        delete $sf->{o}{table}{max_rows};
    }
}


sub __tables_data {
    my ( $sf, $dbh, $schema ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o} );
    my $driver = $sf->{i}{driver};
    my ( $user_tbls, $sys_tbls ) = ( [], [] );
    my $table_data = {};
    my ( $table_schem, $table_name );
    if ( $driver eq 'Pg' ) {
        $table_schem = 'pg_schema';
        $table_name  = 'pg_table';
    }
    else {
        $table_schem = 'TABLE_SCHEM';
        $table_name  = 'TABLE_NAME';
    }
    my @keys = ( 'TABLE_CAT', $table_schem, $table_name, 'TABLE_TYPE' );
    if ( $sf->{i}{db_attached} ) {
        $schema = undef;
        # More than one schema if a SQLite database has databases attached
    }
    my $sth = $dbh->table_info( undef, $schema, undef, undef );
    my $info = $sth->fetchall_arrayref( { map { $_ => 1 } @keys } );
    for my $href ( @$info ) {
        my $table = defined $schema ? $href->{$table_name} : $ax->quote_table( $dbh, [ @{$href}{@keys} ] );
        if ( $href->{TABLE_TYPE} =~ /SYSTEM/ ) {
            #next if ! $sf->{add_metadata};
            next if $href->{$table_name} eq 'sqlite_temp_master';
            push @$sys_tbls, $table;
        }
        elsif ( $href->{TABLE_TYPE} eq 'TABLE' ) { # || $href->{TABLE_TYPE} eq 'VIEW' || $href->{TABLE_TYPE} eq 'LOCAL TEMPORARY' ) {
            push @$user_tbls, $table;
        }
        $table_data->{$table} = [ @{$href}{@keys} ];
    }
    return $table_data, $user_tbls, $sys_tbls;
}



1;


__END__

=pod

=encoding UTF-8

=head1 NAME

App::DBBrowser - Browse SQLite/MySQL/PostgreSQL databases and their tables interactively.

=head1 VERSION

Version 2.003

=head1 DESCRIPTION

DEVELOPER RELEASE

See L<db-browser> for further information.

=head1 AUTHOR

Matthäus Kiem <cuer2s@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2018 Matthäus Kiem.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For
details, see the full text of the licenses in the file LICENSE.

=cut
