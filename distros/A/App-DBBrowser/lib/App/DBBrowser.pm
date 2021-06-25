package App::DBBrowser;

use warnings;
use strict;
use 5.010001;

our $VERSION = '2.268';

use File::Basename        qw( basename );
use File::Spec::Functions qw( catfile catdir );
use Getopt::Long          qw( GetOptions );

use Encode::Locale qw( decode_argv );
use File::HomeDir  qw();
use File::Which    qw( which );

use Term::Choose         qw();
use Term::Choose::Screen qw( clear_screen );
use Term::TablePrint     qw();

#use App::DBBrowser::AttachDB;    # required
use App::DBBrowser::Auxil;
#use App::DBBrowser::CreateTable; # required
use App::DBBrowser::DB;
#use App::DBBrowser::DropTable;   # required
#use App::DBBrowser::Join;        # required
use App::DBBrowser::Opt::Get;
#use App::DBBrowser::Opt::Set;    # required
#use App::DBBrowser::Opt::DBSet   # required
#use App::DBBrowser::Subqueries;  # required
#use App::DBBrowser::Table;       # required
#use App::DBBrowser::Union;       # required

BEGIN {
    decode_argv(); # not at the end of the BEGIN block if less than perl 5.16
    1;
}


sub new {
    my ( $class ) = @_;
    my $page = 2; ##
    my $info = {
        tc_default      => { hide_cursor => 0, clear_screen => 1, page => $page, undef => '<<', prompt => 'Choose:' },
        tf_default      => { hide_cursor => 2, clear_screen => 1, page => $page },
        tcu_default     => { hide_cursor => 0, clear_screen => 1, page => $page },
        lyt_h           => { order => 0, alignment => 2 },
        lyt_v           => { undef => '  BACK', layout => 3 },
        dots            => [ [ '...', 3 ], [ '|', 1 ], [] ],
        quit            => 'QUIT',
        back            => 'BACK',
        confirm         => 'CONFIRM',
        _quit           => '  QUIT',
        _back           => '  BACK',
        _continue       => '  CONTINUE',
        _confirm        => '  CONFIRM',
        _reset          => '  RESET',
        ok              => '-OK-',
        working         => 'Working ... ',
        always_footer   => $page == 2 ? 1 : 0, ##
    };
    return bless { i => $info }, $class;
}


sub __init {
    my ( $sf ) = @_;
    my $home = File::HomeDir->my_home();
    if ( ! $home ) {
        print "'File::HomeDir->my_home()' could not find the home directory!\n";
        print "'db-browser' requires a home directory\n";
        exit;
    }
    my $config_home;
    if ( which( 'xdg-user-dir' ) ) {
        $config_home = File::HomeDir::FreeDesktop->my_config();
    }
    else {
        $config_home = File::HomeDir->my_data();
    }
    my $app_dir = catdir( $config_home // $home, 'db_browser' );
    mkdir $app_dir or die $! if ! -d $app_dir;
    $sf->{i}{home_dir} = $home;
    $sf->{i}{app_dir}  = $app_dir;
    $sf->{i}{f_settings}           = catfile $app_dir, 'general_settings.json';
    $sf->{i}{conf_file_fmt}        = catfile $app_dir, 'config_%s.json';
    $sf->{i}{f_attached_db}        = catfile $app_dir, 'attached_DB.json';
    $sf->{i}{f_dir_history}        = catfile $app_dir, 'dir_history.json';
    $sf->{i}{f_subqueries}         = catfile $app_dir, 'subqueries.json';
    $sf->{i}{f_search_and_replace} = catfile $app_dir, 'search_and_replace.json';
    $sf->{i}{f_copy_and_paste}     = catfile $app_dir, 'tmp_file_copy_and_paste.csv';
    $sf->{i}{f_plain}              = catfile $app_dir, 'tmp_file_plain.csv';
    END {
        no warnings qw( closure );
        unlink $sf->{i}{f_copy_and_paste} if -e $sf->{i}{f_copy_and_paste};
        unlink $sf->{i}{f_plain}          if -e $sf->{i}{f_plain};
    }
}


sub __options {
    my ( $sf ) = @_;
    if ( ! eval {
        my $opt_get = App::DBBrowser::Opt::Get->new( $sf->{i}, {} );
        $sf->{o} = $opt_get->read_config_files();
        my $help;
        GetOptions (
            'h|?|help' => \$help,
            's|search' => \$sf->{i}{sqlite_search},
        );
        if ( $help ) {
            if ( $sf->{o}{table}{mouse} ) {
                $sf->{i}{tc_default}{mouse}  = $sf->{o}{table}{mouse};
                $sf->{i}{tcu_default}{mouse} = $sf->{o}{table}{mouse};
            }
            print clear_screen();
            require App::DBBrowser::Opt::Set;
            my $opt_set = App::DBBrowser::Opt::Set->new( $sf->{i}, $sf->{o} );
            $sf->{o} = $opt_set->set_options();
        }
        1 }
    ) {
        my $ax = App::DBBrowser::Auxil->new( $sf->{i}, {}, {} );
        $ax->print_error_message( $@ );
        my $opt_get = App::DBBrowser::Opt::Get->new( $sf->{i}, {} );
        $sf->{o} = $opt_get->defaults();
        while ( $ARGV[0] && $ARGV[0] =~ /^-/ ) {
            my $arg = shift @ARGV;
            last if $arg eq '--';
        }
    }
    if ( $sf->{o}{table}{mouse} ) {
        $sf->{i}{tc_default}{mouse}  = $sf->{o}{table}{mouse};
        $sf->{i}{tcu_default}{mouse} = $sf->{o}{table}{mouse};
    }
}


sub run {
    my ( $sf ) = @_;
    local $| = 1;
    local $SIG{INT} = local $SIG{TERM} = local $SIG{HUP} = sub {
        if ( defined $sf->{i}{f_copy_and_paste} && -e $sf->{i}{f_copy_and_paste} ) {
            unlink $sf->{i}{f_copy_and_paste};
        }
        if ( defined $sf->{i}{f_plain} && -e $sf->{i}{f_plain} ) {
            unlink $sf->{i}{f_plain};
        }
        exit;
    };
    $sf->__init();
    $sf->__options();
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, {} );
    my $auto_one = 0;
    my $old_idx_plugin = 0;

    PLUGIN: while ( 1 ) {

        my $plugin;
        if ( @{$sf->{o}{G}{plugins}} == 1 ) {
            $auto_one++;
            $plugin = $sf->{o}{G}{plugins}[0];
            print clear_screen();
        }
        else {
            my $menu_plugins = [ undef, map( "- $_", @{$sf->{o}{G}{plugins}} ) ];
            # Choose
            my $idx_plugin = $tc->choose(
                $menu_plugins,
                { %{$sf->{i}{lyt_v}}, prompt => 'DB Plugin: ', index => 1, default => $old_idx_plugin,
                  undef => $sf->{i}{_quit} }
            );
            if ( defined $idx_plugin ) {
                $plugin = $menu_plugins->[$idx_plugin];
            }
            if ( ! defined $plugin ) {
                last PLUGIN;
            }
            if ( $sf->{o}{G}{menu_memory} ) {
                if ( $old_idx_plugin == $idx_plugin && ! $ENV{TC_RESET_AUTO_UP} ) {
                    $old_idx_plugin = 0;
                    next PLUGIN;
                }
                $old_idx_plugin = $idx_plugin;
            }
            $plugin =~ s/^[-\ ]\s//;
        }
        $plugin = 'App::DBBrowser::DB::' . $plugin;
        $sf->{i}{plugin} = $plugin;
        my $plui;
        my $driver;
        if ( ! eval {
            $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
            $driver = $sf->{i}{driver} = $plui->get_db_driver();
            #die "No database driver!" if ! $driver;
            1 }
        ) {
            $ax->print_error_message( $@ );
            next PLUGIN if @{$sf->{o}{G}{plugins}} > 1;
            last PLUGIN;
        }

        # DATABASES

        my @databases;
        my $prefix;
        my ( $user_dbs, $sys_dbs ) = ( [], [] ); #
        if ( ! eval {
            ( $user_dbs, $sys_dbs ) = $plui->get_databases();
            $prefix = $driver eq 'SQLite' ? '' : '- ';
            if ( $prefix ) {
                @databases = ( map( $prefix . $_, @$user_dbs ), $sf->{o}{G}{metadata} ? map( '  ' . $_, @$sys_dbs ) : () );
            }
            else {
                @databases = ( @$user_dbs, $sf->{o}{G}{metadata} ? @$sys_dbs : () );
            }
            $sf->{i}{sqlite_search} = 0 if $sf->{i}{sqlite_search};
            1 }
        ) {
            $ax->print_error_message( $@ );
            $sf->{i}{login_error} = 1;
            next PLUGIN if @{$sf->{o}{G}{plugins}} > 1;
            last PLUGIN;
        }
        if ( ! @databases ) {
            $ax->print_error_message( "$plugin: no databases found\n" );
            next PLUGIN if @{$sf->{o}{G}{plugins}} > 1;
            last PLUGIN;
        }
        my $db;
        my $old_idx_db = 0;

        DATABASE: while ( 1 ) {

            if ( $sf->{redo_db} ) {
                $db = delete $sf->{redo_db};
                $db = $prefix . $db if $prefix;
            }
            elsif ( @databases == 1 ) {
                $db = $databases[0];
                $auto_one++ if $auto_one == 1;
            }
            else {
                my $back;
                if ( $prefix ) {
                    $back = $auto_one ? $sf->{i}{_quit} : $sf->{i}{_back};
                }
                else {
                    $back = $auto_one ? $sf->{i}{quit} : $sf->{i}{back};
                }
                my $prompt = 'Choose Database:';
                my $menu_db = [ undef, @databases ];
                # Choose
                my $idx_db = $tc->choose(
                    $menu_db,
                    { %{$sf->{i}{lyt_v}}, prompt => $prompt, index => 1, default => $old_idx_db, undef => $back }
                );
                $db = undef;
                if ( defined $idx_db ) {
                    $db = $menu_db->[$idx_db];
                }
                if ( ! defined $db ) {
                    next PLUGIN if @{$sf->{o}{G}{plugins}} > 1;
                    last PLUGIN;
                }
                if ( $sf->{o}{G}{menu_memory} ) {
                    if ( $old_idx_db == $idx_db && ! $ENV{TC_RESET_AUTO_UP} ) {
                        $old_idx_db = 0;
                        next DATABASE;
                    }
                    $old_idx_db = $idx_db;
                }
            }
            $db =~ s/^[-\ ]\s// if $prefix;

            # DB-HANDLE

            my $dbh;
            if ( ! eval {
                $dbh = $plui->get_db_handle( $db );
                $sf->{i}{quote_char} = $dbh->get_info(29)  // '"', # SQL_IDENTIFIER_QUOTE_CHAR
                $sf->{i}{sep_char}   = $dbh->get_info(41)  // '.'; # SQL_CATALOG_NAME_SEPARATOR # name
                1 }
            ) {
                $ax->print_error_message( $@ );
                # remove database from @databases
                $sf->{i}{login_error} = 1;
                $dbh->disconnect() if defined $dbh || $dbh->{Active};
                next DATABASE if @databases              > 1;
                next PLUGIN   if @{$sf->{o}{G}{plugins}} > 1;
                last PLUGIN;
            }
            $sf->{d} = {
                db       => $db,
                dbh      => $dbh,
                user_dbs => $user_dbs,
                sys_dbs  => $sys_dbs,
            };
            $sf->{db_attached} = 0;
            if ( $driver eq 'SQLite' && -s $sf->{i}{f_attached_db} ) {
                my $h_ref = $ax->read_json( $sf->{i}{f_attached_db} ) // {};
                my $attached_db = $h_ref->{$db} // [];
                if ( @$attached_db ) {
                    for my $ref ( @$attached_db ) {
                        my $stmt = sprintf "ATTACH DATABASE %s AS %s", $dbh->quote_identifier( $ref->[0] ), $dbh->quote( $ref->[1] );
                        $dbh->do( $stmt );
                    }
                    $sf->{db_attached} = 1;
                    if ( ! exists $sf->{backup_qtn} ) {
                        $sf->{backup_qtn} = $sf->{o}{G}{qualified_table_name};
                    }
                    $sf->{o}{G}{qualified_table_name} = 1;
                }
            }
            if ( exists $sf->{backup_qtn} && ! $sf->{db_attached} ) {
                $sf->{o}{G}{qualified_table_name} = delete $sf->{backup_qtn};
            }
            $sf->{i}{stmt_history} = [];
            $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );

            # SCHEMAS

            my @schemas;
            my ( $user_schemas, $sys_schemas ) = ( [], [] );
            if ( ! eval {
                ( $user_schemas, $sys_schemas ) = $plui->get_schemas( $dbh, $db );
                @schemas = ( map( "- $_", @$user_schemas ), $sf->{o}{G}{metadata} ? map( "  $_", @$sys_schemas ) : () );
                1 }
            ) {
                $ax->print_error_message( $@ );
                $dbh->disconnect();
                next DATABASE if @databases              > 1;
                next PLUGIN   if @{$sf->{o}{G}{plugins}} > 1;
                last PLUGIN;
            }
            my $old_idx_sch = 0;

            SCHEMA: while ( 1 ) {

                my $db_string = 'DB ' . basename( $db ) . '';
                my $schema;
                if ( $sf->{redo_schema} ) {
                    $schema = delete $sf->{redo_schema};
                }
                elsif ( ! @schemas ) {
                    if ( $driver eq 'Pg' ) {
                        # no @schemas if 'metadata' is disabled with no user-schemas
                        # with an undefined schema 'information_schema' would be used
                        @schemas = ( 'public' );
                        $schema = $schemas[0];
                    }
                }
                elsif ( @schemas == 1 ) {
                    $schema = $schemas[0];
                    $schema =~ s/^[-\ ]\s//;
                    $auto_one++ if $auto_one == 2
                }
                else {
                    my $back   = $auto_one == 2 ? $sf->{i}{_quit} : $sf->{i}{_back};
                    my $prompt = $db_string . ' - choose Schema:';
                    my $menu_schema = [ undef, @schemas ];
                    # Choose
                    my $idx_sch = $tc->choose(
                        $menu_schema,
                        { %{$sf->{i}{lyt_v}}, prompt => $prompt, index => 1, default => $old_idx_sch, undef => $back }
                    );
                    if ( defined $idx_sch ) {
                        $schema = $menu_schema->[$idx_sch];
                    }
                    if ( ! defined $schema ) {
                        $dbh->disconnect();
                        next DATABASE if @databases              > 1;
                        next PLUGIN   if @{$sf->{o}{G}{plugins}} > 1;
                        last PLUGIN;
                    }
                    if ( $sf->{o}{G}{menu_memory} ) {
                        if ( $old_idx_sch == $idx_sch && ! $ENV{TC_RESET_AUTO_UP} ) {
                            $old_idx_sch = 0;
                            next SCHEMA;
                        }
                        $old_idx_sch = $idx_sch;
                    }
                    $schema =~ s/^[-\ ]\s//;
                }
                $db_string = 'DB ' . basename( $db ) . ( @schemas > 1 ? '.' . $schema : '' ) . '';
                $sf->{d}{schema}       = $schema;
                $sf->{d}{user_schemas} = $user_schemas;
                $sf->{d}{sys_schemas}  = $sys_schemas;
                $sf->{d}{db_string}    = $db_string;
                $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );

                # TABLES

                my $tables_info;
                if ( ! eval {
                    # if a SQLite database has databases attached, set $schema to undef so 'table_info' in 'tables_data'
                    # returns also the tables from the attached databases
                    $tables_info = $plui->tables_data( $dbh, $sf->{db_attached} ? undef : $schema );
                    1 }
                ) {
                    $ax->print_error_message( $@ );
                    next SCHEMA    if @schemas                > 1;
                    $dbh->disconnect();
                    next DATABASE  if @databases              > 1;
                    next PLUGIN    if @{$sf->{o}{G}{plugins}} > 1;
                    last PLUGIN;
                }
                my ( $user_tables, $sys_tables ) = ( [], [] );
                for my $table ( keys %$tables_info ) {
                    if ( $tables_info->{$table}[3] =~ /SYSTEM/ ) {
                        push @$sys_tables, $table;
                    }
                    else {
                        push @$user_tables, $table;
                    }
                }
                #if ( $sf->{backup_qtn} ) {
                #    for my $table ( @user_tables ) {
                #        my $tmp = delete $tables_info->{$table};
                #        $table = '[' . $tmp->[1] . ']' . $tmp->[2];
                #        $tables_info->{$table} = $tmp;
                #    }
                #}
                $sf->{d}{tables_info} = $tables_info;
                $sf->{d}{user_tables} = $user_tables;
                $sf->{d}{sys_tables}  = $sys_tables;
                my $old_idx_tbl = 1;

                TABLE: while ( 1 ) {

                    my ( $join, $union, $from_subquery, $db_setting ) = ( '  Join', '  Union', '  Derived', '  DB settings' );
                    my $hidden = $db_string;
                    my $table;
                    if ( $sf->{redo_table} ) {
                        $table = delete $sf->{redo_table};
                    }
                    else {
                        my $menu_table = [ $hidden, undef, map( "- $_", sort @$user_tables ) ];
                        push @$menu_table, map( "  $_", sort @$sys_tables ) if $sf->{o}{G}{metadata};
                        push @$menu_table, $from_subquery                   if $sf->{o}{enable}{m_derived};
                        push @$menu_table, $join                            if $sf->{o}{enable}{join};
                        push @$menu_table, $union                           if $sf->{o}{enable}{union};
                        push @$menu_table, $db_setting                      if $sf->{o}{enable}{db_settings};
                        my $back = $auto_one == 3 ? $sf->{i}{_quit} : $sf->{i}{_back};
                        # Choose
                        my $idx_tbl = $tc->choose(
                            $menu_table,
                            { %{$sf->{i}{lyt_v}}, prompt => '', index => 1, default => $old_idx_tbl, undef => $back }
                        );
                        if ( defined $idx_tbl ) {
                            $table = $menu_table->[$idx_tbl];
                        }
                        if ( ! defined $table ) {
                            next SCHEMA         if @schemas                > 1;
                            $dbh->disconnect();
                            next DATABASE       if @databases              > 1;
                            next PLUGIN         if @{$sf->{o}{G}{plugins}} > 1;
                            last PLUGIN;
                        }
                        if ( $sf->{o}{G}{menu_memory} ) {
                            if ( $old_idx_tbl == $idx_tbl && ! $ENV{TC_RESET_AUTO_UP} ) {
                                $old_idx_tbl = 1;
                                next TABLE;
                            }
                            $old_idx_tbl = $idx_tbl;
                        }
                    }
                    if ( $table eq $db_setting ) {
                        my $changed;
                        if ( ! eval {
                            require App::DBBrowser::Opt::DBSet;
                            my $db_opt_set = App::DBBrowser::Opt::DBSet->new( $sf->{i}, $sf->{o} );
                            $changed = $db_opt_set->database_setting( $db );
                            1 }
                        ) {
                            $ax->print_error_message( $@ );
                            next TABLE;
                        }
                        if ( $changed ) {
                            $sf->{redo_db} = $db;
                            $sf->{redo_schema} = $schema;
                            $dbh->disconnect(); # reconnects
                            next DATABASE;
                        }
                        next TABLE;
                    }
                    if ( $table eq $hidden ) {
                        $sf->__create_drop_or_attach( $table );
                        if ( $sf->{redo_db} ) {
                            $dbh->disconnect();
                            next DATABASE;
                        }
                        elsif ( $sf->{redo_schema} ) {
                            next SCHEMA;
                        }
                        next TABLE;
                    }
                    my ( $qt_table, $qt_columns );
                    if ( $table eq $join ) {
                        require App::DBBrowser::Join;
                        my $new_j = App::DBBrowser::Join->new( $sf->{i}, $sf->{o}, $sf->{d} );
                        $sf->{i}{special_table} = 'join';
                        if ( ! eval { ( $qt_table, $qt_columns ) = $new_j->join_tables(); 1 } ) {
                            $ax->print_error_message( $@ );
                            next TABLE;
                        }
                        next TABLE if ! defined $qt_table;
                    }
                    elsif ( $table eq $union ) {
                        require App::DBBrowser::Union;
                        my $new_u = App::DBBrowser::Union->new( $sf->{i}, $sf->{o}, $sf->{d} );
                        $sf->{i}{special_table} = 'union';
                        if ( ! eval { ( $qt_table, $qt_columns ) = $new_u->union_tables(); 1 } ) {
                            $ax->print_error_message( $@ );
                            next TABLE;
                        }
                        next TABLE if ! defined $qt_table;
                    }
                    elsif ( $table eq $from_subquery ) {
                        $sf->{i}{special_table} = 'subquery';
                        if ( ! eval { ( $qt_table, $qt_columns ) = $sf->__derived_table(); 1 } ) {
                            $ax->print_error_message( $@ );
                            next TABLE;
                        }
                        next TABLE if ! defined $qt_table;
                    }
                    else {
                        $sf->{i}{special_table} = '';
                        if ( ! eval {
                            $table =~ s/^[-\ ]\s//;
                            $sf->{d}{table} = $table;
                            my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
                            $qt_table = $ax->quote_table( $sf->{d}{tables_info}{$table} );
                            my $sth = $dbh->prepare( "SELECT * FROM " . $qt_table . " LIMIT 0" );
                            $sth->execute() if $driver ne 'SQLite';
                            $sf->{d}{cols} = [ @{$sth->{NAME}} ];
                            $qt_columns = $ax->quote_simple_many( $sf->{d}{cols} );
                            1 }
                        ) {
                            $ax->print_error_message( $@ );
                            next TABLE;
                        }
                    }
                    if ( $sf->{i}{special_table} ) {
                        $sf->{d}{table} = ucfirst $sf->{i}{special_table};
                        my $qc = $sf->{i}{quote_char};
                        if ( $qt_table =~ /\sAS\s\Q$qc\E([^\Q$qc\E]+)\Q$qc\E\z/ ) {
                            $sf->{d}{table} .= ': ' . $1;
                        }
                    }
                    $sf->__browse_the_table( $qt_table, $qt_columns );
                }
            }
        }
    }
    # END of App
}


sub __browse_the_table {
    my ( $sf, $qt_table, $qt_columns ) = @_;
    require App::DBBrowser::Table;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $sql = {};
    $ax->reset_sql( $sql );
    $sql->{table} = $qt_table;
    $sql->{cols} = $qt_columns;
    $sf->{i}{stmt_types} = [ 'Select' ];
    $ax->print_sql_info( $sql );

    PRINT_TABLE: while ( 1 ) {
        my $all_arrayref;
        if ( ! eval {
            my $tbl = App::DBBrowser::Table->new( $sf->{i}, $sf->{o}, $sf->{d} );
            ( $all_arrayref, $sql ) = $tbl->on_table( $sql );
            1 }
        ) {
            $ax->print_error_message( $@ );
            last PRINT_TABLE;
        }
        if ( ! defined $all_arrayref ) {
            last PRINT_TABLE;
        }

        my $tp = Term::TablePrint->new( $sf->{o}{table} );
        $tp->print_table(
            $all_arrayref,
            { table_name => "     '" . $sf->{d}{table} . "'     " }
        );

        delete $sf->{o}{table}{max_rows}   if exists $sf->{o}{table}{max_rows};
        delete $sf->{o}{table}{table_name} if exists $sf->{o}{table}{table_name};
    }
}


sub __create_drop_or_attach {
    my ( $sf, $table ) = @_;
    my $old_idx = exists $sf->{old_idx_hidden} ? delete $sf->{old_idx_hidden} : 1;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );

    CREATE_DROP_ATTACH: while ( 1 ) {
        my $hidden = $sf->{d}{db_string};
        my ( $create_table,    $drop_table,      $create_view,    $drop_view,      $attach_databases, $detach_databases ) = (
          '- Create TABLE', '- Drop   TABLE', '- Create VIEV', '- Drop   VIEW', '- Attach DB',     '- Detach DB',
        );
        my @entries;
        push @entries, $create_table if $sf->{o}{enable}{create_table};
        push @entries, $drop_table   if $sf->{o}{enable}{drop_table};
        push @entries, $create_view  if $sf->{o}{enable}{create_view};
        push @entries, $drop_view    if $sf->{o}{enable}{drop_view};
        if ( $sf->{i}{driver} eq 'SQLite' ) {
            push @entries, $attach_databases;
            push @entries, $detach_databases if $sf->{db_attached};
        }
        if ( ! @entries ) {
            return;
        }
        my @pre = ( $hidden, undef );
        my $menu = [ @pre, @entries ];
        # Choose
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, prompt => '', index => 1, default => $old_idx, undef => '  <=' }
        );
        if ( ! defined $idx || ! defined $menu->[$idx] ) {
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx = 1;
                next CREATE_DROP_ATTACH;
            }
            $old_idx = $idx;
        }
        my $choice = $menu->[$idx];
        if ( $choice eq $hidden ) {
            require App::DBBrowser::Opt::Set;
            my $opt_set = App::DBBrowser::Opt::Set->new( $sf->{i}, $sf->{o} );
            my $groups = [ { name => 'group_insert', text => '' } ];
            $opt_set->set_options( $groups );
            next CREATE_DROP_ATTACH;
        }
        elsif ( $choice =~ /^-\ Create/i ) {
            require App::DBBrowser::CreateTable;
            my $ct = App::DBBrowser::CreateTable->new( $sf->{i}, $sf->{o}, $sf->{d} );
            if ( $choice eq $create_table ) {
                if ( ! eval { $ct->create_table(); 1 } ) {
                    $ax->print_error_message( $@ );
                }
            }
            elsif ( $choice eq $create_view ) {
                if ( ! eval { $ct->create_view(); 1 } ) {
                    $ax->print_error_message( $@ );
                }
            }
            #my $file_fs = $sf->{i}{gc}{file_fs} // $sf->{i}{gc}{previous_file_fs};
            #my $book = $sf->{i}{S_R}{$file_fs}{book};
            #if ( defined $sf->{i}{S_R}{$file_fs}{book} && -s $file_fs > 50_000_000 ) {
            #    delete $sf->{i}{S_R};
            #}
        }
        elsif ( $choice =~ /^-\ Drop/i ) {
            require App::DBBrowser::DropTable;
            my $dt = App::DBBrowser::DropTable->new( $sf->{i}, $sf->{o}, $sf->{d} );
            if ( $choice eq $drop_table ) {
                if ( ! eval { $dt->drop_table(); 1 } ) {
                    $ax->print_error_message( $@ );
                }
            }
            elsif ( $choice eq $drop_view ) {
                if ( ! eval { $dt->drop_view(); 1 } ) {
                    $ax->print_error_message( $@ );
                }
            }
        }
        elsif ( $choice =~ /^-\ (?:Attach|Detach)/ ) {
            require App::DBBrowser::AttachDB;
            my $att = App::DBBrowser::AttachDB->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $changed;
            if ( $choice eq $attach_databases ) {
                if ( ! eval { $changed = $att->attach_db(); 1 } ) {
                    $ax->print_error_message( $@ );
                    next CREATE_DROP_ATTACH;
                }
            }
            elsif ( $choice eq $detach_databases ) {
                if ( ! eval { $changed = $att->detach_db(); 1 } ) {
                    $ax->print_error_message( $@ );
                    next CREATE_DROP_ATTACH;
                }
            }
            if ( ! $changed ) {
                next CREATE_DROP_ATTACH;
            }
        }
        $sf->{old_idx_hidden} = $old_idx;
        $sf->{redo_db}     = $sf->{d}{db};
        $sf->{redo_schema} = $sf->{d}{schema};
        $sf->{redo_table}  = $table;
        return;
    }
}


sub __derived_table {
    my ( $sf ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    require App::DBBrowser::Subqueries;
    my $sq = App::DBBrowser::Subqueries->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $sf->{i}{stmt_types} = [ 'Select' ];
    my $tmp = { table => '()' };
    $ax->reset_sql( $tmp );
    $ax->print_sql_info( $tmp );
    my $qt_table = $sq->choose_subquery( $tmp );
    if ( ! defined $qt_table ) {
        return;
    }
    my $alias = $ax->alias( 'subqueries', $qt_table, 'From_SQ' );
    $qt_table .= " AS " . $ax->quote_col_qualified( [ $alias ] );
    $tmp->{table} = $qt_table;
    $ax->print_sql_info( $tmp );
    my $sth = $sf->{d}{dbh}->prepare( "SELECT * FROM " . $qt_table . " LIMIT 0" );
    $sth->execute() if $sf->{i}{driver} ne 'SQLite';
    my $qt_columns = $ax->quote_simple_many( $sth->{NAME} );
    return $qt_table, $qt_columns;
}







1;


__END__

=pod

=encoding UTF-8

=head1 NAME

App::DBBrowser - Browse SQLite/MySQL/PostgreSQL databases and their tables interactively.

=head1 VERSION

Version 2.268

=head1 DESCRIPTION

See L<db-browser> for further information.

=head1 AUTHOR

Matthäus Kiem <cuer2s@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2021 Matthäus Kiem.

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE
IMPLIED WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For
details, see the full text of the licenses in the file LICENSE.

=cut
