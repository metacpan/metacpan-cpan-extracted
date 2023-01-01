package # hide from PAUSE
App::DBBrowser::Table;

use warnings;
use strict;
use 5.014;

use Cwd                   qw( realpath );
use Encode                qw( encode decode );
use File::Spec::Functions qw( catfile );

#use String::Unescape  qw( unescape );             # required
#use Text::CSV         qw( csv );                  # required

use Term::Choose         qw();
use Term::Choose::Screen qw( hide_cursor clear_screen );
use Term::Form::ReadLine qw();
use Term::TablePrint     qw();

use App::DBBrowser::Auxil;
#use App::DBBrowser::Opt::Set;                      # required
use App::DBBrowser::Table::Substatements;
#use App::DBBrowser::Table::InsertUpdateDelete;     # required


sub new {
    my ( $class, $info, $options, $data ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $data
    }, $class;
}


sub browse_the_table {
    my ( $sf, $qt_table, $qt_columns ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $sql = {};
    $ax->reset_sql( $sql );
    $sql->{table} = $qt_table;
    $sql->{cols} = $qt_columns;
    $sf->{i}{stmt_types} = [ 'Select' ];
    $sf->{i}{changed_sql} = {};
    $ax->print_sql_info( $ax->get_sql_info( $sql ) );

    PRINT_TABLE: while ( 1 ) {
        my $all_arrayref;
        if ( ! eval {
            ( $all_arrayref, $sql ) = $sf->__on_table( $sql );
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
            { footer => "     '" . $sf->{d}{table} . "'     " }
        );

        delete $sf->{o}{table}{max_rows}   if exists $sf->{o}{table}{max_rows};
        delete $sf->{o}{table}{table_name} if exists $sf->{o}{table}{table_name};
    }
}


sub __on_table {
    my ( $sf, $sql ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $sb = App::DBBrowser::Table::Substatements->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $hidden = 'Customize:';
    my ( $print_table, $select, $aggregate, $distinct, $where, $group_by, $having, $order_by, $limit, $export ) =
       ( 'Print TABLE',
         '- SELECT',
         '- AGGREGATE',
         '- DISTINCT',
         '- WHERE',
         '- GROUP BY',
         '- HAVING',
         '- ORDER BY',
         '- LIMIT',
         '  Export',
    );
    my @pre = ( $hidden, undef );
    my @choices = ( $print_table, $select, $aggregate, $distinct, $where, $group_by, $having, $order_by, $limit, $export );
    $sf->{i}{stmt_types} = [ 'Select' ];
    my $old_idx = 1;

    CUSTOMIZE: while ( 1 ) {
        my $menu = [ @pre, @choices ];
        my $info = $ax->get_sql_info( $sql );
        # Choose
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => '', index => 1, default => $old_idx, undef => $sf->{i}{back} }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $idx || ! defined $menu->[$idx] ) {
            for my $key ( keys %{$sf->{changed_sql}} ) {
                if ( $sf->{changed_sql}{$key} ) {
                    delete $sf->{changed_sql};
                    $ax->reset_sql( $sql );
                    next CUSTOMIZE;
                }
            }
            last CUSTOMIZE;
        }
        my $chosen = $menu->[$idx];
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx = 1;
                next CUSTOMIZE;
            }
            $old_idx = $idx;
        }
        my $backup_sql = $ax->backup_href( $sql );
        if ( $chosen eq $select ) {
            my $ret = $sb->select( $sql );
            if ( ! defined $ret ) { $sql = $backup_sql }
            else { $sf->{changed_sql}{$chosen} = $ret };
        }
        elsif ( $chosen eq $distinct ) {
            my $ret = $sb->distinct( $sql );
            if ( ! defined $ret ) { $sql = $backup_sql }
            else { $sf->{changed_sql}{$chosen} = $ret };
        }
        elsif ( $chosen eq $aggregate ) {
            my $ret = $sb->aggregate( $sql );
            if ( ! defined $ret ) { $sql = $backup_sql }
            else { $sf->{changed_sql}{$chosen} = $ret };
        }
        elsif ( $chosen eq $where ) {
            my $ret = $sb->where( $sql );
            if ( ! defined $ret ) { $sql = $backup_sql }
            else { $sf->{changed_sql}{$chosen} = $ret };
        }
        elsif ( $chosen eq $group_by ) {
            my $ret = $sb->group_by( $sql );
            if ( ! defined $ret ) { $sql = $backup_sql }
            else { $sf->{changed_sql}{$chosen} = $ret };
        }
        elsif ( $chosen eq $having ) {
            my $ret = $sb->having( $sql );
            if ( ! defined $ret ) { $sql = $backup_sql }
            else { $sf->{changed_sql}{$chosen} = $ret };
        }
        elsif ( $chosen eq $order_by ) {
            my $ret = $sb->order_by( $sql );
            if ( ! defined $ret ) { $sql = $backup_sql }
            else { $sf->{changed_sql}{$chosen} = $ret };
        }
        elsif ( $chosen eq $limit ) {
            my $ret = $sb->limit_offset( $sql );
            if ( ! defined $ret ) { $sql = $backup_sql }
            else { $sf->{changed_sql}{$chosen} = $ret };
        }
        elsif ( $chosen eq $hidden ) {
            require App::DBBrowser::Table::InsertUpdateDelete;
            my $write = App::DBBrowser::Table::InsertUpdateDelete->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $write->table_write_access( $sql );
            $sf->{i}{stmt_types} = [ 'Select' ];
            $old_idx = 1;
            $sql = $backup_sql; # so no need for table_write_access to return $sql
        }
        elsif ( $chosen eq $export ) {
            my $file_fs = $sf->__get_filename_fs( $sql );
            if ( ! length $file_fs ) {
                next CUSTOMIZE;
            }
            if ( ! eval {
                print 'Working ...' . "\r" if $sf->{o}{table}{progress_bar};
                my $all_arrayref = $sf->__selected_statement_result( $sql );
                my $open_mode;
                if ( length $sf->{o}{export}{file_encoding} ) { ##
                    $open_mode = '>:encoding(' . $sf->{o}{export}{file_encoding} . ')';
                }
                else {
                    $open_mode = '>';
                }
                open my $fh, $open_mode, $file_fs or die $!;
                require String::Unescape;
                my $options = {
                    map { $_ => String::Unescape::unescape( $sf->{o}{csv_out}{$_} ) }
                    grep { defined $sf->{o}{csv_out}{$_} }
                    keys %{$sf->{o}{csv_out}}
                };
                require Text::CSV;
                my $csv = Text::CSV->new( $options );
                $csv->say( $fh, $_ ) for @$all_arrayref;
                close $fh;
                1 }
            ) {
                $ax->print_error_message( $@ );
            }
        }
        elsif ( $chosen eq $print_table ) {
            local $| = 1;
            print hide_cursor(); # safety
            print clear_screen();
            print 'Computing:' . "\r" if $sf->{o}{table}{progress_bar};
            my $all_arrayref = $sf->__selected_statement_result( $sql );
            # return $sql explicitly since after a restore-backup $sql refers to a different hash.
            return $all_arrayref, $sql;
        }
    }
}


sub __selected_statement_result {
    my ( $sf, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $statement = $ax->get_stmt( $sql, 'Select', 'prepare' );
    my @arguments = ( @{$sql->{where_args}}, @{$sql->{having_args}} );
    unshift @{$sf->{i}{history}{ $sf->{d}{db} }{print}}, [ $statement, \@arguments ];
    if ( $#{$sf->{i}{history}{ $sf->{d}{db} }{print}} > 50 ) {
        $#{$sf->{i}{history}{ $sf->{d}{db} }{print}} = 50;
    }
    if ( $sf->{o}{G}{auto_limit} && ! $sql->{limit_stmt} ) {
        $statement .= $ax->sql_limit( $sf->{o}{G}{auto_limit} );
        $sf->{o}{table}{max_rows} = $sf->{o}{G}{auto_limit};
    }
    else {
        $sf->{o}{table}{max_rows} = 0;
    }
    my $sth = $sf->{d}{dbh}->prepare( $statement );
    $sth->execute( @arguments );
    my $col_names = $sth->{NAME}; # not quoted
    my $all_arrayref = $sth->fetchall_arrayref;
    unshift @$all_arrayref, $col_names;
    return $all_arrayref;
}


sub __get_filename_fs {
    my ( $sf, $sql ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $file_name;
    my $count = 0;

    FILE_NAME: while ( 1 ) {
        if ( ++$count > 2 ) {
            $file_name = '';
        }
        my $info = $ax->get_sql_info( $sql );
        # Readline
        $file_name = $tr->readline(
            'File name: ',
            { info => $info, default => $file_name, hide_cursor => 2 }
        );
        $ax->print_sql_info( $info );
        if ( ! length $file_name ) {
            return;
        }

        FULL_FILE_NAME: while ( 1 ) {
            my $file_name_plus = $file_name;
            if ( $sf->{o}{export}{add_extension} && $file_name !~ /\.csv\z/i ) {
                $file_name_plus .= '.csv';
            }
            my $dir = $sf->{o}{export}{export_dir};
            $file_name_plus = catfile $dir, $file_name_plus;
            my $file_fs = realpath encode( 'locale_fs', $file_name_plus );
            my ( $new_name, $overwrite ) = ( '- New name', '- Overwrite' );
            my $chosen;
            if ( -e $file_fs ) {
                my $menu;
                my $prompt;
                if ( -d $file_fs ) {
                    $prompt = 'A directory with name "' . $file_name_plus . '" already exists.';
                    $menu = [ undef, $new_name ];
                }
                else {
                    $prompt =  'A file with name "' . $file_name_plus . '" already exists.';
                    $menu = [ undef, $new_name, $overwrite ];
                }
                # Choose
                $chosen = $tc->choose(
                    $menu,
                    { %{$sf->{i}{lyt_v}}, info => $info, prompt => $prompt, keep => scalar( @$menu ) }
                );
                $ax->print_sql_info( $info );
                if ( ! defined $chosen ) {
                    return;
                }
                elsif ( $chosen eq $new_name ) {
                    next FILE_NAME;
                }
            }
            my ( $yes, $no ) = ( '- YES', '- NO' );
            my $hidden;
            if ( defined $chosen && $chosen eq $overwrite ) {
                $hidden = 'Overwrite "' . decode( 'locale_fs', $file_fs ) . '"?';
            }
            else {
                $hidden = 'Write data to "' . decode( 'locale_fs', $file_fs ) . '"?';
            }
            # Choose
            my $choice = $tc->choose(
                [ $hidden, undef, $yes, $no ],
                { info => $info, prompt => '', default => 1, layout => 2, undef => '  <<' }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $choice ) {
                next FILE_NAME;
            }
            elsif ( $choice eq $hidden ) {
                require App::DBBrowser::Opt::Set;
                my $opt_set = App::DBBrowser::Opt::Set->new( $sf->{i}, $sf->{o} );
                $sf->{o} = $opt_set->set_options( [ { name => 'group_export', text => '' } ] );
                next FULL_FILE_NAME;
            }
            elsif ( $choice eq $no ) {
                return;
            }
            else {
                return $file_fs;
            }
        }
    }
}


1;


__END__
