package App::DBBrowser;

use warnings;
use strict;
use 5.014;

our $VERSION = '2.324';

use File::Basename        qw( basename );
use File::Spec::Functions qw( catfile catdir );
use Getopt::Long          qw( GetOptions );

use Encode::Locale qw( decode_argv );
use File::HomeDir  qw();
use File::Which    qw( which );

use Term::Choose         qw();
use Term::Choose::Screen qw( clear_screen );

use App::DBBrowser::Auxil;
#use App::DBBrowser::CreateDropAttach; # required
use App::DBBrowser::DB;
#use App::DBBrowser::Join;             # required
use App::DBBrowser::Opt::Get;
#use App::DBBrowser::Opt::Set;         # required
#use App::DBBrowser::Opt::DBSet        # required
#use App::DBBrowser::Subqueries;       # required
#use App::DBBrowser::Table;            # required
#use App::DBBrowser::Union;            # required

BEGIN {
    decode_argv(); # not at the end of the BEGIN block if less than perl 5.16
    1;
}


sub new {
    my ( $class ) = @_;
    my $info = {
        tc_default    => { hide_cursor => 0, clear_screen => 1, page => 2, keep => 6, undef => '<<', prompt => 'Your choice:' },
        tf_default    => { hide_cursor => 2, clear_screen => 1, page => 2, keep => 6 },
        tr_default    => { hide_cursor => 2, clear_screen => 1, page => 2 },
        tcu_default   => { hide_cursor => 0, clear_screen => 1, page => 2, keep => 6 }, ##
        lyt_h         => { order => 0, alignment => 2 },
        lyt_v         => { undef => '  BACK', layout => 2 },
        dots          => '...',
        quit          => 'QUIT',
        back          => 'BACK',
        confirm       => 'CONFIRM',
        _quit         => '  QUIT',
        _back         => '  BACK',
        _continue     => '  CONTINUE',
        _confirm      => '  CONFIRM',
        _reset        => '  RESET',
        ok            => '-OK-',
        info_thsd_sep => ',',
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
}


sub __options {
    my ( $sf ) = @_;
    if ( ! eval {
        my $opt_get = App::DBBrowser::Opt::Get->new( $sf->{i}, {} );
        $sf->{o} = $opt_get->read_config_files();
        my $help;
        GetOptions (
            'h|?|help' => \$help,
            's|search' => \$sf->{i}{search},
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
    $sf->__init();
    $sf->__options();
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, {} );
    my $skipped_menus = 0;
    my $old_idx_plugin = 0;

    PLUGIN: while ( 1 ) {

        my $plugin;
        if ( @{$sf->{o}{G}{plugins}} == 1 ) {
            $skipped_menus++;
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
        my ( $user_dbs, $sys_dbs ) = ( [], [] );
        if ( ! eval {
            ( $user_dbs, $sys_dbs ) = $plui->get_databases();
            1 }
        ) {
            $ax->print_error_message( $@ );
            $sf->{i}{login_error} = 1;
            next PLUGIN if @{$sf->{o}{G}{plugins}} > 1;
            last PLUGIN;
        }
        $prefix = $driver =~ /^(?:SQLite|Firebird)\z/ ? '' : '- ';
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
            $ax->print_error_message( "$plugin: no databases found\n" );
            next PLUGIN if @{$sf->{o}{G}{plugins}} > 1;
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

            # DB-HANDLE

            $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $dbh;
            if ( ! eval {
                $dbh = $plui->get_db_handle( $db );
                $sf->{d}{identifier_quote_char} = $dbh->get_info(29) // '"', # SQL_IDENTIFIER_QUOTE_CHAR
                #$sf->{d}{catalog_name_sep} = $dbh->get_info(41) // '.';  # SQL_CATALOG_NAME_SEPARATOR
                #$sf->{d}{catalog_location} = $dbh->get_info(114) || 1;   # SQL_CATALOG_LOCATION
                1 }
            ) {
                $ax->print_error_message( $@ );
                # remove database from @databases
                $sf->{i}{login_error} = 1;
                $dbh->disconnect() if defined $dbh && $dbh->{Active};
                next DATABASE if @databases              > 1;
                next PLUGIN   if @{$sf->{o}{G}{plugins}} > 1;
                last PLUGIN;
            }
            $sf->{d}{dbh} = $dbh;
            if ( $driver eq 'SQLite' && -s $sf->{i}{f_attached_db} ) {
                if ( ! eval {
                    my $h_ref = $ax->read_json( $sf->{i}{f_attached_db} ) // {};
                    my $attached_db = $h_ref->{$db} // {};
                    if ( %$attached_db ) {
                        for my $key ( sort keys %$attached_db ) {
                            my $stmt = sprintf "ATTACH DATABASE %s AS %s", $dbh->quote_identifier( $attached_db->{$key} ), $dbh->quote( $key );
                            $dbh->do( $stmt );
                        }
                        $sf->{d}{db_attached} = 1;
                    }
                    1 }
                ) {
                    $ax->print_error_message( $@ );
                    $dbh->disconnect() if defined $dbh && $dbh->{Active};
                    next DATABASE if @databases              > 1;
                    next PLUGIN   if @{$sf->{o}{G}{plugins}} > 1;
                    last PLUGIN;
                }
            }

            # SCHEMAS

            my @schemas;
            my ( $user_schemas, $sys_schemas ) = ( [], [] );
            if ( ! eval {
                ( $user_schemas, $sys_schemas ) = $plui->get_schemas( $dbh, $db, $is_system_db, $sf->{d}{db_attached} );
                1 }
            ) {
                $ax->print_error_message( $@ );
                $dbh->disconnect();
                next DATABASE if @databases              > 1;
                next PLUGIN   if @{$sf->{o}{G}{plugins}} > 1;
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
                    if ( @$sys_schemas ) {
                        $schema = $sys_schemas->[0];
                        $is_system_schema = 1;
                    }
                    else {
                        $schema = $user_schemas->[0];
                    }
                    $skipped_menus++ if $skipped_menus == 2
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
                    ( $tables_info, $user_table_keys, $sys_table_keys ) = $plui->tables_info( $dbh, $schema, $is_system_schema );
                    1 }
                ) {
                    $ax->print_error_message( $@ );
                    next SCHEMA    if @schemas                > 1;
                    $dbh->disconnect();
                    next DATABASE  if @databases              > 1;
                    next PLUGIN    if @{$sf->{o}{G}{plugins}} > 1;
                    last PLUGIN;
                }
                $sf->{d}{tables_info} = $tables_info;
                $sf->{d}{user_table_keys} = $user_table_keys;
                $sf->{d}{sys_table_keys} = $sys_table_keys;
                my $old_idx_tbl = 1;

                TABLE: while ( 1 ) {

                    my ( $join, $union, $from_subquery, $db_setting ) = ( '  Join', '  Union', '  Derived', '  DB settings' );
                    my $hidden = $db_string;
                    my $table;
                    if ( $sf->{redo_table} ) {
                        $table = delete $sf->{redo_table};
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
                        push @$menu_table, $join          if $sf->{o}{enable}{join};
                        push @$menu_table, $union         if $sf->{o}{enable}{union};
                        push @$menu_table, $db_setting    if $sf->{o}{enable}{db_settings};
                        my $back = $skipped_menus == 3 ? $sf->{i}{_quit} : $sf->{i}{_back};
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
                            $sf->{redo_is_system_db} = $is_system_db;
                            $sf->{redo_schema} = $schema;
                            $sf->{redo_is_system_schema} = $is_system_schema;
                            $dbh->disconnect(); # reconnects
                            next DATABASE;
                        }
                        next TABLE;
                    }
                    if ( $table eq $hidden ) {
                        require App::DBBrowser::CreateDropAttach;
                        my $cda = App::DBBrowser::CreateDropAttach->new( $sf->{i}, $sf->{o}, $sf->{d} );
                        my $ret = $cda->create_drop_or_attach();
                        if ( ! $ret ) {
                            next TABLE;
                        }
                        elsif ( $ret == 1 ) {
                            # update the list of available tables and reenter the $hidden submenu
                            $sf->{redo_schema} = $schema;
                            $sf->{redo_is_system_schema} = $is_system_schema;
                            $sf->{redo_table}  = $table;
                            next SCHEMA;
                        }
                        elsif ( $ret == 2 ) {
                            # reattach databases and therefore recall `get_scheams`
                            # and reenter the $hidden submenu
                            $sf->{redo_db} = $db;
                            $sf->{redo_is_system_db} = $is_system_db;
                            $sf->{redo_table}  = $table;
                            next DATABASE;
                        }
                    }
                    my ( $qt_table, $qt_columns );
                    if ( $table eq $join ) {
                        require App::DBBrowser::Join;
                        my $new_j = App::DBBrowser::Join->new( $sf->{i}, $sf->{o}, $sf->{d} );
                        $sf->{d}{special_table} = 'join';
                        if ( ! eval { ( $qt_table, $qt_columns ) = $new_j->join_tables(); 1 } ) {
                            $ax->print_error_message( $@ );
                            next TABLE;
                        }
                        next TABLE if ! defined $qt_table;
                    }
                    elsif ( $table eq $union ) {
                        require App::DBBrowser::Union;
                        my $new_u = App::DBBrowser::Union->new( $sf->{i}, $sf->{o}, $sf->{d} );
                        $sf->{d}{special_table} = 'union';
                        if ( ! eval { ( $qt_table, $qt_columns ) = $new_u->union_tables(); 1 } ) {
                            $ax->print_error_message( $@ );
                            next TABLE;
                        }
                        next TABLE if ! defined $qt_table;
                    }
                    elsif ( $table eq $from_subquery ) {
                        $sf->{d}{special_table} = 'subquery';
                        if ( ! eval { ( $qt_table, $qt_columns ) = $sf->__derived_table(); 1 } ) {
                            $ax->print_error_message( $@ );
                            next TABLE;
                        }
                        next TABLE if ! defined $qt_table;
                    }
                    else {
                        $sf->{d}{special_table} = '';
                        if ( ! eval {
                            $table =~ s/^[-\ ]\s//;
                            $sf->{d}{table_key} = $table;
                            my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
                            $qt_table = $ax->quote_table( $sf->{d}{tables_info}{$table} );
                            $sf->{d}{cols} = $ax->column_names( $qt_table );
                            $qt_columns = $ax->quote_cols( $sf->{d}{cols} );
                            1 }
                        ) {
                            $ax->print_error_message( $@ );
                            next TABLE;
                        }
                    }
                    my $table_footer;
                    if ( $sf->{d}{special_table} ) {
                        $table_footer = ucfirst $sf->{d}{special_table};
                        my $qc = quotemeta $sf->{d}{identifier_quote_char};
                        if ( $qt_table =~ /\sAS\s$qc([^$qc]+)$qc\z/ ) {
                            $table_footer .= ': ' . $1;
                        }
                    }
                    else {
                        $table_footer = $sf->{d}{table_key};
                    }
                    $sf->{d}{table_footer} = "     '$table_footer'     ";
                    require App::DBBrowser::Table;
                    my $tbl = App::DBBrowser::Table->new( $sf->{i}, $sf->{o}, $sf->{d} );
                    $tbl->browse_the_table( $qt_table, $qt_columns );
                }
            }
        }
    }
    # END of App
}


sub __derived_table {
    my ( $sf ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    require App::DBBrowser::Subqueries;
    my $sq = App::DBBrowser::Subqueries->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $sf->{d}{stmt_types} = [ 'Select' ];
    my $tmp = { table => '()' };
    $ax->reset_sql( $tmp );
    $ax->print_sql_info( $ax->get_sql_info( $tmp ) );
    my $qt_table = $sq->choose_subquery( $tmp );
    if ( ! defined $qt_table ) {
        return;
    }
    my $alias = $ax->alias( $tmp, 'derived_table', $qt_table, 'Derived_Table' );
    if ( length $alias ) {
        $qt_table .= " AS " . $ax->prepare_identifier( $alias );
    }
    $tmp->{table} = $qt_table;
    my $columns = $ax->column_names( $qt_table );
    my $qt_columns = $ax->quote_cols( $columns );
    return $qt_table, $qt_columns;
}







1;


__END__

=pod

=encoding UTF-8

=head1 NAME

App::DBBrowser - Browse SQLite/MySQL/PostgreSQL databases and their tables interactively.

=head1 VERSION

Version 2.324

=head1 DESCRIPTION

See L<db-browser> for further information.

=head1 AUTHOR

Matthäus Kiem <cuer2s@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2023 Matthäus Kiem.

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE
IMPLIED WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For
details, see the full text of the licenses in the file LICENSE.

=cut
