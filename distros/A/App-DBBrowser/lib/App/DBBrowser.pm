package App::DBBrowser;
use warnings;
use strict;
use 5.016;

our $VERSION = '2.438';

use File::Basename        qw( basename );
use File::Spec::Functions qw( catfile catdir );
use Getopt::Long          qw( GetOptions );

use DBI::Const::GetInfoType;
use Encode::Locale           qw( decode_argv );
use File::HomeDir            qw();
use File::Which              qw( which );

use Term::Choose         qw();
use Term::Choose::Screen qw( clear_screen );

use App::DBBrowser::Auxil;
#use App::DBBrowser::CreateDropAttach;  # required
use App::DBBrowser::DB;
#use App::DBBrowser::From               # required
#use App::DBBrowser::Options;           # required
use App::DBBrowser::Options::Defaults;
use App::DBBrowser::Options::ReadWrite;
#use App::DBBrowser::Table;             # required


BEGIN { decode_argv() }


sub new {
    my ( $class ) = @_;
    my $info = {
        dots          => [ '...', 3 ],
        quit          => 'Quit',
        back          => 'Back',
#        continue      => 'Continue'
        confirm       => 'Confirm',
        reset         => 'Reset',
        _quit         => '  Quit',
        _back         => '  Back',
        _continue     => '  Continue',
        _confirm      => '  Confirm',
        _reset        => '  Reset',
        s_back        => '<<',
        ok            => '-OK-',
        menu_addition => '%%',
        info_thsd_sep => ',',
    };
    $info->{tc_default}  = { hide_cursor => 0, clear_screen => 1, page => 2, keep => 8, undef => $info->{s_back}, prompt => 'Your choice:' }; ##
    $info->{tcu_default} = { hide_cursor => 0, clear_screen => 1, page => 2, keep => 8, confirm => $info->{ok}, back => $info->{s_back} };
    $info->{tf_default}  = { hide_cursor => 2, clear_screen => 1, page => 2, keep => 8, auto_up => 1, skip_items => qr/^\s*\z/ };
    $info->{tr_default}  = { hide_cursor => 2, clear_screen => 1, page => 2, history => [ 0 .. 1000 ] };
    $info->{lyt_h}       = { order => 0, alignment => 2 };
    $info->{lyt_v}       = { undef => $info->{_back}, layout => 2 };
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
    $sf->{i}{home_dir} = $home;
    my $config_home;
    if ( which( 'xdg-user-dir' ) ) {
        $config_home = File::HomeDir::FreeDesktop->my_config();
    }
    else {
        $config_home = File::HomeDir->my_data();
    }
    my $app_dir = catdir( $config_home // $home, 'db_browser' );
    mkdir $app_dir or die $! if ! -d $app_dir;
    $sf->{i}{app_dir} = $app_dir;
    $sf->{i}{f_attached_db}        = catfile $app_dir, 'attached_DB.json';
    $sf->{i}{f_dir_history}        = catfile $app_dir, 'dir_history.json';
    $sf->{i}{f_subqueries}         = catfile $app_dir, 'subqueries.json';
    $sf->{i}{f_search_and_replace} = catfile $app_dir, 'search_and_replace.json';
    $sf->{i}{f_global_settings}    = catfile $app_dir, 'global_settins.json';
    my $db_cache_dir = catdir( $app_dir, 'cache_database_names' );
    mkdir $db_cache_dir or die $! if ! -d $db_cache_dir;
    $sf->{i}{db_cache_file_fmt} = catfile $db_cache_dir, 'databases_%s.json';
    my $plugin_config_dir = catdir( $app_dir, 'config_plugins' );
    mkdir $plugin_config_dir or die $! if ! -d $plugin_config_dir;
    $sf->{i}{plugin_config_file_fmt} = catfile $plugin_config_dir, 'config_%s.json';
    $sf->{i}{db_config_file_fmt}     = catfile $plugin_config_dir, 'config_%s_Databases.json';
}


sub __options {
    my ( $sf ) = @_;
    if ( ! eval {
        my $help;
        GetOptions (
            'h|?|help' => \$help,
            's|search' => \$sf->{i}{search},
        );
        if ( $help ) {
            print clear_screen();
            require App::DBBrowser::Options;
            my $op = App::DBBrowser::Options->new( $sf->{i}, $sf->{o} );
            $op->set_options();
        }
        1 }
    ) {
        my $ax = App::DBBrowser::Auxil->new( $sf->{i}, {}, {} );
        $ax->print_error_message( $@ );
        while ( $ARGV[0] && $ARGV[0] =~ /^-/ ) {
            my $arg = shift @ARGV;
            last if $arg eq '--';
        }
    }
    my $op_rw = App::DBBrowser::Options::ReadWrite->new( $sf->{i}, {} );
    $sf->{o} = $op_rw->read_config_file();
}


sub run {
    my ( $sf ) = @_;
    local $| = 1;
    $sf->__init();
    $sf->__options();
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, {} );
    my $skipped_menus = 0;
    my $old_idx_plugin = 0;
    my $available_plugins = $sf->{o}{G}{plugins};

    PLUGIN: while ( 1 ) {

        my $plugin;
        if ( @$available_plugins == 1 ) {
            $skipped_menus++;
            $plugin = $available_plugins->[0];
            print clear_screen();
        }
        else {
            my $menu_plugins = [ undef, map( "- $_", @$available_plugins ) ];
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
        $sf->{i}{plugin} = $plugin;

        my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
        my $driver;
        if ( ! eval {
            $driver = $sf->{i}{driver} = $plui->get_db_driver();
            #die "No database driver!" if ! $driver;
            1 }
        ) {
            $ax->print_error_message( $@ );
            next PLUGIN if @$available_plugins > 1;
            last PLUGIN;
        }
        my $op_rw = App::DBBrowser::Options::ReadWrite->new( $sf->{i}, $sf->{o} );
        delete $sf->{o}{connect_data};
        delete $sf->{o}{connect_attr};
        $op_rw->read_config_file( $driver, $plugin );

        # DATABASES

        my @databases;
        my ( $user_dbs, $sys_dbs ) = ( [], [] );
        if ( ! eval {
            ( $user_dbs, $sys_dbs ) = $plui->get_databases();
            1 }
        ) {
            $ax->print_error_message( $@ );
            $sf->{i}{login_error} = 1;
            next PLUGIN if @$available_plugins > 1;
            last PLUGIN;
        }
        my $prefix = $driver =~ /^(?:SQLite|DuckDB|Firebird)\z/ ? '' : '- ';
        if ( $sf->{o}{G}{metadata} ) {
            if ( $prefix ) {
                @databases = ( map( $prefix . $_, @$user_dbs ), map( '  ' . $_, @$sys_dbs ) );
            }
            else {
                @databases = ( @$user_dbs, @$sys_dbs );
            }
        }
        else {
            if ( $prefix ) {
                @databases = ( map( $prefix . $_, @$user_dbs ) );
            }
            else {
                @databases = @$user_dbs;
            }
        }
        $sf->{i}{search} = 0 if $sf->{i}{search};
        if ( ! @databases ) {
            $ax->print_error_message( "$plugin: no databases found\n" ); ##
            next PLUGIN if @$available_plugins > 1;
            last PLUGIN;
        }
        my $old_idx_db = 0;

        DATABASE: while ( 1 ) {

            my $db;
            my $is_system_db = 0;
            if ( $sf->{redo_db} ) {
                $db = delete $sf->{redo_db};
                $is_system_db = delete $sf->{redo_is_system_db};
            }
            elsif ( @databases == 1 ) {
                $db = $databases[0];
                $db =~ s/^[-\ ]\s// if $prefix;
                if ( ! @$user_dbs ) {
                    $is_system_db = 1;
                }
                $skipped_menus++ if $skipped_menus == 1;
            }
            else {
                my $back;
                if ( $prefix ) {
                    $back = $skipped_menus ? $sf->{i}{_quit} : $sf->{i}{_back};
                }
                else {
                    $back = $skipped_menus ? $sf->{i}{quit} : $sf->{i}{back};
                }
                my $prompt = 'Choose Database:';
                my $menu_db = [ undef, @databases ];
                # Choose
                my $idx_db = $tc->choose(
                    $menu_db,
                    { %{$sf->{i}{lyt_v}}, prompt => $prompt, index => 1, default => $old_idx_db, undef => $back }
                );
                if ( defined $idx_db ) {
                    $db = $menu_db->[$idx_db];
                }
                if ( ! defined $db ) {
                    next PLUGIN if @$available_plugins > 1;
                    last PLUGIN;
                }
                if ( $sf->{o}{G}{menu_memory} ) {
                    if ( $old_idx_db == $idx_db && ! $ENV{TC_RESET_AUTO_UP} ) {
                        $old_idx_db = 0;
                        next DATABASE;
                    }
                    $old_idx_db = $idx_db;
                }
                $db =~ s/^[-\ ]\s// if $prefix;
                if ( $idx_db - 1 > $#$user_dbs ) {
                    $is_system_db = 1;
                }
            }
            $sf->{d} = {
                db => $db,
                user_dbs => $user_dbs,
                sys_dbs => $sys_dbs,
            };
            $op_rw->read_config_file( $driver, $plugin, $db );

            # DB-HANDLE

            my $dbh;
            if ( ! eval {
                $dbh = $plui->get_db_handle( $db );
                $sf->{d}{identifier_quote_char} = $dbh->get_info( $GetInfoType{SQL_IDENTIFIER_QUOTE_CHAR} ) // '"';
                #$sf->{d}{catalog_name_sep}     = $dbh->get_info( $GetInfoType{SQL_CATALOG_NAME_SEPARATOR} ) // '.';
                #$sf->{d}{catalog_location}     = $dbh->get_info( $GetInfoType{SQL_CATALOG_LOCATION} ) || 1;
                1 }
            ) {
                $ax->print_error_message( $@ );
                # remove database from @databases
                $sf->{i}{login_error} = 1;
                $dbh->disconnect() if defined $dbh && $dbh->{Active};
                next DATABASE if @databases          > 1;
                next PLUGIN   if @$available_plugins > 1;
                last PLUGIN;
            }
            $sf->{d}{dbh} = $dbh;
            if ( $driver eq 'ODBC' ) {
                my $dbms_name = $dbh->get_info( $GetInfoType{SQL_DBMS_NAME} );
                if ( $dbms_name =~ /sql server/i ) {
                    $sf->{i}{dbms} = 'MSSQL';
                }
                elsif ( $dbms_name =~ /postgresql/i ) {
                    $sf->{i}{dbms} = 'Pg';
                }
                else {
                    for my $type ( qw( Oracle DB2 Informix MariaDB mysql SQLite DuckDB Firebird ) ) {
                        if ( $dbms_name =~ /$type/i ) {
                            $sf->{i}{dbms} = $type;
                            last;
                        }
                    }
                }
            }
            else {
                $sf->{i}{dbms} = $driver;
            }
            if ( $sf->{i}{dbms} =~ /^(?:SQLite|DuckDB)\z/ && -f $sf->{i}{f_attached_db} ) {
                if ( ! eval {
                    require App::DBBrowser::CreateDropAttach::AttachDB;
                    my $att = App::DBBrowser::CreateDropAttach::AttachDB->new( $sf->{i}, $sf->{o}, $sf->{d} );
                    my $h_ref = $ax->read_json( $sf->{i}{f_attached_db} ) // {};
                    my $attached_db = $h_ref->{$plugin}{$db} // {};
                    if ( %$attached_db ) {
                        for my $alias ( sort keys %$attached_db ) {
                            my $stmt = $att->attach_stmt( $dbh, $attached_db->{$alias}, $alias );
                            $dbh->do( $stmt );
                        }
                        $sf->{d}{db_attached} = 1;
                    }
                    1 }
                ) {
                    $ax->print_error_message( $@ );
                    $dbh->disconnect() if defined $dbh && $dbh->{Active};
                    next DATABASE if @databases          > 1;
                    next PLUGIN   if @$available_plugins > 1;
                    last PLUGIN;
                }
            }

            # SCHEMAS

            my @schemas;
            my ( $user_schemas, $sys_schemas ) = ( [], [] );
            if ( ! eval {
                ( $user_schemas, $sys_schemas ) = $plui->get_schemas( $dbh, $db, $is_system_db );
                1 }
            ) {
                $ax->print_error_message( $@ );
                $dbh->disconnect();
                next DATABASE if @databases          > 1;
                next PLUGIN   if @$available_plugins > 1;
                last PLUGIN;
            }
            my $undef_str = '';
            if ( $sf->{o}{G}{metadata} ) {
                @schemas = ( map( '- ' . ( $_ // $undef_str ), @$user_schemas ),
                             map( '  ' . ( $_ // $undef_str ), @$sys_schemas  ) );
            }
            else {
                @schemas = ( map( '- ' . ( $_ // $undef_str ), @$user_schemas ) );
            }
            my $old_idx_sch = 0;

            SCHEMA: while ( 1 ) {

                my $db_string = 'DB ' . basename( $db ) . '';
                my $schema;
                my $is_system_schema = 0;
                if ( $sf->{redo_schema} ) {
                    $schema = delete $sf->{redo_schema};
                    $is_system_schema = delete $sf->{redo_is_system_schema};
                }
                elsif ( ! @schemas ) {
                    # `$schema` remains undefined
                }
                elsif ( @schemas == 1 ) {
                    $schema = ( @$user_schemas, @$sys_schemas )[0]; # to preserve unstringified `undef`
                    $skipped_menus++ if $skipped_menus == 2;
                }
                else {
                    my $back = $skipped_menus == 2 ? $sf->{i}{_quit} : $sf->{i}{_back};
                    my $prompt = $db_string . ':';
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
                        next DATABASE if @databases          > 1;
                        next PLUGIN   if @$available_plugins > 1;
                        last PLUGIN;
                    }
                    if ( $sf->{o}{G}{menu_memory} ) {
                        if ( $old_idx_sch == $idx_sch && ! $ENV{TC_RESET_AUTO_UP} ) {
                            $old_idx_sch = 0;
                            next SCHEMA;
                        }
                        $old_idx_sch = $idx_sch;
                    }
                    $schema = ( @$user_schemas, @$sys_schemas )[ $idx_sch - 1 ]; # to preserve unstringified `undef`
                    if ( $idx_sch - 1 > $#$user_schemas ) {
                        $is_system_schema = 1;
                    }
                }
                $db_string = 'DB ' . basename( $db ) . ( @schemas > 1 ? '.' . ( $schema // $undef_str ) : '' ) . ':';
                $sf->{d}{schema} = $schema;
                $sf->{d}{is_system_schema} = $is_system_schema;
                $sf->{d}{user_schemas} = $user_schemas;
                $sf->{d}{sys_schemas} = $sys_schemas;
                $sf->{d}{db_string}  = $db_string;

                # TABLES

                my ( $tables_info, $user_table_keys, $sys_table_keys );
                if ( ! eval {
                    ( $tables_info, $user_table_keys, $sys_table_keys ) = $plui->tables_info( $dbh, $schema, $is_system_schema, $sf->{d}{db_attached} );
                    1 }
                ) {
                    $ax->print_error_message( $@ );
                    next SCHEMA    if @schemas            > 1;
                    $dbh->disconnect();
                    next DATABASE  if @databases          > 1;
                    next PLUGIN    if @$available_plugins > 1;
                    last PLUGIN;
                }
                $sf->{d}{tables_info} = $tables_info;
                $sf->{d}{user_table_keys} = $user_table_keys;
                $sf->{d}{sys_table_keys} = $sys_table_keys;
                $sf->{d}{cte_history} = [];
                my $old_idx_tbl = 1;

                TABLE: while ( 1 ) {

                    my ( $from_join, $from_union, $from_subquery, $from_cte ) = ( '  Join', '  Union', '  Subquery', '  Cte' ); ##
                    my $hidden = $db_string;
                    my $table_key;
                    if ( $sf->{redo_table} ) {
                        $table_key = delete $sf->{redo_table};
                    }
                    else {
                        my @pre = ( $hidden, undef );
                        my $menu_table;
                        if ( $sf->{o}{G}{metadata} ) {
                            my $sys_prefix = $is_system_schema ? '- ' : '  ';
                            $menu_table = [ @pre, map( "- $_", @$user_table_keys ), map( $sys_prefix . $_, @$sys_table_keys ) ];
                        }
                        else {
                            $menu_table = [ @pre, map( "- $_", @$user_table_keys ) ];
                        }
                        push @$menu_table, $from_subquery if $sf->{o}{enable}{m_derived};
                        push @$menu_table, $from_cte      if $sf->{o}{enable}{m_cte};
                        push @$menu_table, $from_join     if $sf->{o}{enable}{join};
                        push @$menu_table, $from_union    if $sf->{o}{enable}{union};
                        my $back = $skipped_menus == 3 ? $sf->{i}{_quit} : $sf->{i}{_back};
                        # Choose
                        my $idx_tbl = $tc->choose(
                            $menu_table,
                            { %{$sf->{i}{lyt_v}}, prompt => '', index => 1, default => $old_idx_tbl, undef => $back }
                        );
                        if ( defined $idx_tbl ) {
                            $table_key = $menu_table->[$idx_tbl];
                        }
                        if ( ! defined $table_key ) {
                            $sf->{d}{cte_history} = [];
                            next SCHEMA         if @schemas            > 1;
                            $dbh->disconnect();
                            next DATABASE       if @databases          > 1;
                            next PLUGIN         if @$available_plugins > 1;
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
                    if ( $table_key eq $hidden ) {
                        require App::DBBrowser::CreateDropAttach;
                        my $cda = App::DBBrowser::CreateDropAttach->new( $sf->{i}, $sf->{o}, $sf->{d} );
                        my $ret = $cda->create_drop_or_attach();
                        if ( ! $ret ) {
                            next TABLE;
                        }
                        elsif ( $ret == 1 ) {
                            # update the list of available tables
                            $sf->{redo_schema} = $schema;
                            $sf->{redo_is_system_schema} = $is_system_schema;
                            $sf->{redo_table} = $table_key; # stay in the $hidden submenu
                            next SCHEMA;
                        }
                        elsif ( $ret == 2 ) {
                            # attached/dedached databases and therefore redo attache database stmts
                            $sf->{redo_db} = $db;
                            $sf->{redo_is_system_db} = $is_system_db;
                            $sf->{redo_table} = $table_key; # stay in the $hidden submenu
                            next DATABASE;
                        }
                        elsif ( $ret == 3 ) {
                            # new db-settings and therefore reconnect to the database
                            $sf->{redo_db} = $db;
                            $sf->{redo_is_system_db} = $is_system_db;
                            $sf->{redo_schema} = $schema;
                            $sf->{redo_is_system_schema} = $is_system_schema;
                            $sf->{redo_table} = $table_key; # stay in the $hidden submenu
                            $dbh->disconnect(); # reconnects
                            next DATABASE;
                        }
                    }
                    $sf->{d}{default_table_alias_count} = 0;
                    $sf->{d}{table_aliases} = {};
                    require App::DBBrowser::From; ##
                    my $fr = App::DBBrowser::From->new( $sf->{i}, $sf->{o}, $sf->{d} );
                    my $sql = $fr->from_sql( $table_key =~ s/[-\ ]\ //r );
                    if ( ! defined $sql ) {
                        next TABLE;
                    }
                    $ax->print_sql_info( $ax->get_sql_info( $sql ) ); ##
                    require App::DBBrowser::Table;
                    my $tbl = App::DBBrowser::Table->new( $sf->{i}, $sf->{o}, $sf->{d} );
                    $tbl->browse_the_table( $sql );
                }
            }
        }
    }
    # END of App
}



1;


__END__

=pod

=encoding UTF-8

=head1 NAME

App::DBBrowser - Browse SQLite/MySQL/PostgreSQL databases and their tables interactively.

=head1 VERSION

Version 2.438

=head1 DESCRIPTION

See L<db-browser> for further information.

=head1 AUTHOR

Matthäus Kiem <cuer2s@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2025 Matthäus Kiem.

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE
IMPLIED WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For
details, see the full text of the licenses in the file LICENSE.

=cut
