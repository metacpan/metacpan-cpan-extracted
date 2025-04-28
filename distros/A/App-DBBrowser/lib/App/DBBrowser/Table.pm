package # hide from PAUSE
App::DBBrowser::Table;

use warnings;
use strict;
use 5.016;

use Cwd                   qw( realpath );
use Encode                qw( encode decode );
use File::Spec::Functions qw( catfile );

#use String::Unescape  qw( unescape );             # required
#use Text::CSV_XS      qw();                       # required

use Term::Choose         qw();
use Term::Choose::Screen qw( hide_cursor clear_screen );
use Term::Form::ReadLine qw();
use Term::TablePrint     qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::Opt::Set;
use App::DBBrowser::Table::Substatement;
#use App::DBBrowser::Table::InsertUpdateDelete;     # required


sub new {
    my ( $class, $info, $options, $d ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $d
    }, $class;
}


sub browse_the_table {
    my ( $sf, $sql, $return_stmt_prompt ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $sb = App::DBBrowser::Table::Substatement->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $sf->{d}{stmt_types} = [ 'Select' ];
    my $changed = {};
    my $hidden = 'Customize:';
    my ( $print_table, $select, $distinct, $where, $group_by, $having, $order_by, $limit, $offset, $export ) =
       ( 'Print TABLE',
         '- SELECT',
         '- DISTINCT',
         '- WHERE',
         '- GROUP BY',
         '- HAVING',
         '- ORDER BY',
         '- LIMIT',
         '- OFFSET',
         '  Export',
    );
    my @choices = ( $print_table, $select, $distinct, $where, $group_by, $having, $order_by, $limit, $offset, $export );
    my @pre = ( $hidden, undef );
    my $back = $sf->{i}{back};
    my ( $return_statement, $hidden_print ) = ( $sf->{i}{_confirm}, $return_stmt_prompt );
    if ( $return_stmt_prompt ) {
        $choices[0] = $return_statement;
        @pre = ( $hidden_print, undef );
        $back = $sf->{i}{_back};
    }
    my $footer = $sf->{d}{table_origin} eq 'ordinary' ? $sf->{d}{table_key} : ucfirst $sf->{d}{table_origin};
    $sf->{d}{table_footer} = "     '$footer'     ";
    my $old_idx = 1;

    CUSTOMIZE: while ( 1 ) {
        my $menu = [ @pre, @choices ];
        my $info = $ax->get_sql_info( $sql );
        # Choose
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => '', index => 1, default => $old_idx, undef => $back }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $idx || ! defined $menu->[$idx] ) {
            for my $key ( keys %{$changed} ) {
                if ( $changed->{$key} ) {
                    $changed = {};
                    $ax->reset_sql( $sql );
                    next CUSTOMIZE;
                }
            }
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx = 1;
                next CUSTOMIZE;
            }
            $old_idx = $idx;
        }
        my $sub_stmt = $menu->[$idx];
        if ( $sub_stmt eq $select ) {
            my $ret = $sb->select( $sql );
            $changed->{$sub_stmt} = $ret;
        }
        elsif ( $sub_stmt eq $distinct ) {
            my $ret = $sb->distinct( $sql );
            $changed->{$sub_stmt} = $ret;
        }
        elsif ( $sub_stmt eq $where ) {
            my $ret = $sb->where( $sql );
            $changed->{$sub_stmt} = $ret;
        }
        elsif ( $sub_stmt eq $group_by ) {
            my $ret = $sb->group_by( $sql );
            $changed->{$sub_stmt} = $ret;
        }
        elsif ( $sub_stmt eq $having ) {
            my $ret = $sb->having( $sql );
            $changed->{$sub_stmt} = $ret;
        }
        elsif ( $sub_stmt eq $order_by ) {
            my $ret = $sb->order_by( $sql );
            $changed->{$sub_stmt} = $ret;
        }
        elsif ( $sub_stmt eq $limit ) {
            my $ret = $sb->limit( $sql );
            $changed->{$sub_stmt} = $ret;
        }
        elsif ( $sub_stmt eq $offset ) {
            my $ret = $sb->offset( $sql );
            $changed->{$sub_stmt} = $ret;
        }
        elsif ( $sql->{aggregate_mode} && ! @{$sql->{selected_cols}} ) { ##
            $ax->print_error_message( "No columns selected!", $info );
            next CUSTOMIZE;
        }
        elsif ( $sub_stmt eq $hidden ) {
            if ( ! eval {
                require App::DBBrowser::Table::InsertUpdateDelete;
                my $write = App::DBBrowser::Table::InsertUpdateDelete->new( $sf->{i}, $sf->{o}, $sf->{d} );
                my $backup_sql = $ax->clone_data( $sql );
                $write->table_write_access( $sql );
                for my $key ( keys %$backup_sql ) { ##
                    $sql->{$key} = $backup_sql->{$key};
                }
                1 }
            ) {
                $ax->print_error_message( $@ );
            }
            $sf->{d}{stmt_types} = [ 'Select' ];
            $old_idx = 1;
        }
        elsif ( $sub_stmt eq $return_statement ) {
            my $bu_cte_history = [ @{$sf->{d}{cte_history}} ];
            $sf->{d}{cte_history} = [];
            # empty the cte_history else every substatemnt
            # would contain the cte clauses.
            my $statement = $ax->get_stmt( $sql, 'Select', 'prepare' );
            $sf->{d}{cte_history} = $bu_cte_history;
            return $statement;
        }
        elsif ( $sub_stmt eq $export ) {
            if ( ! eval {
                $sf->__export( $sql );
                1 }
            ) {
                $ax->print_error_message( $@ );
                next CUSTOMIZE;
            }
        }
        elsif ( $sub_stmt eq $print_table || $sub_stmt eq $hidden_print ) {
            local $| = 1;
            print hide_cursor(); # safety
            print clear_screen();
            print 'Computing:' . "\r" if $sf->{o}{table}{progress_bar};
            my $all_arrayref;
            if ( ! eval {
                $all_arrayref = $sf->__selected_statement_result( $sql );
                1 }
            ) {
                $ax->print_error_message( $@ );
                next CUSTOMIZE;
            }
            my $tp = Term::TablePrint->new( $sf->{o}{table} );
            if ( ! $sf->{o}{G}{warnings_table_print} ) {
                local $SIG{__WARN__} = sub {};
                $tp->print_table( $all_arrayref, { footer => $sf->{d}{table_footer} } );
            }
            else {
                $tp->print_table( $all_arrayref, { footer => $sf->{d}{table_footer} } );
            }
        }
    }
}


sub __selected_statement_result {
    my ( $sf, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $statement = $ax->get_stmt( $sql, 'Select', 'prepare' );
    unshift @{$sf->{d}{table_print_history}}, $statement;
    if ( $#{$sf->{d}{table_print_history}} > 50 ) {
        $#{$sf->{d}{table_print_history}} = 50;
    }
    my $sth = $sf->{d}{dbh}->prepare( $statement );
    $sth->execute();
    my $col_names = $sth->{NAME}; # not quoted
    my $all_arrayref = $sth->fetchall_arrayref;
    unshift @$all_arrayref, $col_names;

    if ( $sf->{i}{driver} eq 'DB2' && length $sf->{o}{G}{db2_encoding} ) {
        print 'Decoding: ...' . "\r"  if $sf->{o}{table}{progress_bar};
        my $encoding = Encode::find_encoding( $sf->{o}{G}{db2_encoding} );
        if ( ! ref $encoding ) {
            die qq(encoding "$sf->{o}{G}{db2_encoding}" not found);
        }
        for my $row ( @$all_arrayref ) {
            $_ = $encoding->decode( $_ ) for @$row;
        }
    }
    return $all_arrayref;
}


sub __export {
    my ( $sf, $sql ) = @_;
    my $file_fs = $sf->__get_filename_fs( $sql );
    if ( ! length $file_fs ) {
        return;
    }
    print 'Working ...' . "\r" if $sf->{o}{table}{progress_bar};
    my $all_arrayref = $sf->__selected_statement_result( $sql );
    my $open_mode;
    if ( length $sf->{o}{export}{file_encoding} ) {
        $open_mode = '>:encoding(' . $sf->{o}{export}{file_encoding} . ')';
    }
    else {
        $open_mode = '>';
    }
    open my $fh, $open_mode, $file_fs or die "$file_fs: $!";
    require String::Unescape;
    my $options = {
        map { $_ => String::Unescape::unescape( $sf->{o}{csv_out}{$_} ) }
        grep { length $sf->{o}{csv_out}{$_} } # keep the default value if the option is set to ''
        keys %{$sf->{o}{csv_out}}
    };
    if ( ! length $options->{eol} ) {
        $options->{eol} = $/; # for `eol` use `$/` as the default value
    }
    require Text::CSV_XS;
    my $csv = Text::CSV_XS->new( $options ) or die Text::CSV_XS->error_diag();
    $csv->print( $fh, $_ ) for @$all_arrayref;
    close $fh;
    return 1;
}


sub __get_filename_fs {
    my ( $sf, $sql ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $file_name;
    if ( $sf->{o}{export}{default_filename} ) {
        $file_name = $sf->{d}{table_key};
    }
    my $count = 0;

    FILE_NAME: while ( 1 ) {
        if ( ++$count > 2 ) {
            $file_name = '';
        }
        my $info = $ax->get_sql_info( $sql );
        # Readline
        $file_name = $tr->readline(
            'File name: ',
            { info => $info, default => $file_name, hide_cursor => 2, history => [] }
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
            my $export_dir = $sf->{o}{export}{export_dir};
            my $dir_fs = realpath( encode( 'locale_fs', $export_dir ) ) or die "$export_dir: $!";
            my $file_fs = catfile $dir_fs, encode( 'locale_fs', $file_name_plus );
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
                my $opt_set = App::DBBrowser::Opt::Set->new( $sf->{i}, $sf->{o} );
                $sf->{o} = $opt_set->set_options( 'export' );
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
