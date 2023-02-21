package # hide from PAUSE
App::DBBrowser::Table::Functions;

use warnings;
use strict;
use 5.014;

use Scalar::Util qw( looks_like_number );

use List::MoreUtils qw( all minmax uniq );

use Term::Choose           qw();
use Term::Choose::LineFold qw( print_columns line_fold );
use Term::Choose::Util     qw( unicode_sprintf get_term_height get_term_width );
use Term::Form             qw();
use Term::Form::ReadLine   qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::Table::Functions::SQL;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $d
    }, $class;
}

sub __func_info {
    my ( $sf, $func ) = @_;
    return 'Function: ' . uc $func;
}


sub __choose_columns {
    my ( $sf, $func, $cols, $multi_col ) = @_;
    if ( $multi_col ) {
        my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
        # Choose
        my $subset = $tu->choose_a_subset(
            $cols,
            { info => $sf->__func_info( $func ) . "\n", cs_label => 'Columns: ', layout => 1,
              cs_separator => ',', keep_chosen => 1, confirm => $sf->{i}{ok}, back => '<<' }
        );
        if ( ! @{$subset//[]} ) {
            return;
        }
        return $subset;
    }
    else {
        my $tc = Term::Choose->new( $sf->{i}{tc_default} );
        # Choose
        my $choice = $tc->choose(
            [ undef, @$cols ],
            { %{$sf->{i}{lyt_h}}, info => $sf->__func_info( $func ) . "\n", prompt => 'Choose column: ' }
        );
        if ( ! defined $choice ) {
            return;
        }
        return [ $choice ];
    }
}


sub __get_info_rows {
    my ( $sf, $chosen_cols, $func, $function_stmts, $incomplete ) = @_;
    my @tmp = ( $sf->__func_info( $func ) );
    my ( $prompt, $subseq_tab );
    if ( @$chosen_cols > 1 ) {
        $prompt = 'Columns: ';
        $subseq_tab = ' ' x 13;
    }
    else {
        $prompt = 'Column: ';
        $subseq_tab = ' ' x 12;
    }
    push @tmp, line_fold( $prompt . join( ', ', @$chosen_cols ), get_term_width, { subseq_tab => $subseq_tab, join => 0 } );
    push @tmp, '';
    if ( defined $function_stmts ) {
        push @tmp, @$function_stmts;
    }
    if ( defined $incomplete ) {
        push @tmp, $incomplete;
    }
    return @tmp;
}


sub __confirm_all {
    my ( $sf, $chosen_cols, $info ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    if ( @$chosen_cols == 1 ) {
        return 1;
    }
    else {
        # Choose
        my $choice = $tc->choose(
            [ undef, $sf->{i}{_confirm} ],
            { %{$sf->{i}{lyt_v}}, info => $info, layout => 2, keep => 3 }
        );
        if ( ! $choice ) {
            return;
        }
        elsif ( $choice eq $sf->{i}{_confirm} ) {
            return 1;
        }
    }
}


sub col_function {
    my ( $sf, $sql, $clause ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $driver = $sf->{i}{driver};
    my $changed = 0;
    my $cols;
    if ( $clause eq 'select' && ( @{$sql->{group_by_cols}} || @{$sql->{aggr_cols}} ) ) {
        $cols = [ @{$sql->{group_by_cols}}, @{$sql->{aggr_cols}} ];
    }
    elsif ( $clause eq 'having' ) {
        $cols = [ @{$sql->{aggr_cols}} ];
    }
    else {
        $cols = [ @{$sql->{cols}} ];
    }
    my @simple_functions = (
        'Bit_Length',
        'Char_Length',
        'Upper',
        'Lower',
        'Trim',
        'LTrim',
        'RTrim'
    );
    if ( $driver eq 'Informix' ) {
        push @simple_functions, 'Length', 'Initcap';
    }
    my $Cast              = 'Cast';
    my $Concat            = 'Concat';
    my $Epoch_to_Date     = 'Epoch_to_Date';
    my $Epoch_to_DateTime = 'Epoch_to_DateTime';
    my $Replace           = 'Replace';
    my $Round             = 'Round';
    my $Truncate          = 'Truncate';
    my @functions;
    if ( $driver =~ /^(?:Informix|Sybase)\z/ ) {
        @functions = ( @simple_functions, $Cast, $Concat, $Replace, $Round, $Truncate );
    }
    else {
        @functions = ( @simple_functions, $Cast, $Concat, $Epoch_to_Date, $Epoch_to_DateTime, $Replace, $Round, $Truncate );
    }
    my $joined_simple_functions = join( '|', @simple_functions );
    my $prefix = '  ';
    my @pre = ( undef );
    my $menu = [ @pre, map( $prefix . $_, sort @functions ) ];
    my $old_idx = 0;

    CHOOSE_FUNCTION: while( 1 ) {
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, prompt => 'Funktion:', default => $old_idx, index => 1, undef => '  <=' } # <= BACK
        );
        if ( ! defined $idx || ! defined $menu->[$idx] ) {
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx = 0;
                next CHOOSE_FUNCTION;
            }
            $old_idx = $idx;
        }
        my $func = $menu->[$idx] =~ s/^\Q${prefix}\E//r;
        my $multi_col = 0;
        if (   $clause eq 'select'
            || $clause eq 'where' && $sql->{where_stmt} =~ /\s(?:NOT\s)?IN\s*\z/
            || $func eq $Concat
        ) {
            $multi_col = 1;
        }
        my $function_stmts = [];
        if ( $func =~ /^(?:$joined_simple_functions)\z/ ) {
            $function_stmts = $sf->__func_with_col( $sql, $cols, $func, $multi_col );
        }
        elsif ( $func eq $Cast ) {
            $function_stmts = $sf->__func_with_col_and_arg( $sql, $cols, $func, $multi_col, 'Data type: ', [] );
        }
        elsif ( $func =~ /^(?:$Round|$Truncate)\z/ ) {
            $function_stmts = $sf->__func_with_col_and_arg( $sql, $cols, $func, $multi_col, 'Decimal places: ', [ 0 .. 9 ] );
        }
        elsif ( $func eq $Concat ) {
            $function_stmts = $sf->__func_Concat( $sql, $cols, $func, $multi_col );
        }
        elsif ( $func eq $Replace ) {
            $function_stmts = $sf->__func_Replace( $sql, $cols, $func, $multi_col );
        }

        elsif ( $func eq $Epoch_to_Date || $func eq $Epoch_to_DateTime ) {
            $function_stmts = $sf->__func_Date_Time( $sql, $cols, $func, $multi_col );
        }
        if ( ! $function_stmts ) {
            next CHOOSE_FUNCTION;
        }
        return $function_stmts;
    }
}


sub __func_with_col {
    my ( $sf, $sql, $cols, $func, $multi_col ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $fsql = App::DBBrowser::Table::Functions::SQL->new( $sf->{i}, $sf->{o} );
    my $chosen_cols = $sf->__choose_columns( $func, $cols, $multi_col );
    if ( ! defined $chosen_cols ) {
        return;
    }
    my $function_stmts = [];
    for my $qt_col ( @$chosen_cols ) {
        push @$function_stmts, $fsql->function_with_col( $func, $qt_col );
        $sf->{d}{default_alias}{$function_stmts->[-1]} = lc( $func ) . '_' . $ax->unquote_identifier( $qt_col );
    }
    return $function_stmts;
}


sub __func_with_col_and_arg {
    my ( $sf, $sql, $cols, $func, $multi_col, $prompt, $history ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $fsql = App::DBBrowser::Table::Functions::SQL->new( $sf->{i}, $sf->{o} );
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    my $chosen_cols = $sf->__choose_columns( $func, $cols, $multi_col );
    if ( ! defined $chosen_cols ) {
        return;
    }
    my @tmp_history;
    my $function_stmts = [];
    my $value;
    my $i = 0;

    COLUMN: while ( 1 ) {
        my $qt_col = $chosen_cols->[$i];
        my $incomplete = $func . '(' . $qt_col . ',?)';
        my @tmp_info = $sf->__get_info_rows( $chosen_cols, $func, $function_stmts, $incomplete );
        my $info = join "\n", @tmp_info;
        my $readline = $tr->readline(
            $prompt,
            { info => $info, history => [ @tmp_history, @{$history//[]} ] }
        );
        if ( ! length $readline ) {
            if ( $i == 0 ) {
                return;
            }
            else {
                $i--;
                pop @$function_stmts;
                next COLUMN;
            }
        }
        else {
            $value = $readline;
            @tmp_history = ( uniq $value, @tmp_history );
            push @$function_stmts, $fsql->function_with_col_and_arg( $func, $qt_col, $value );
            $sf->{d}{default_alias}{$function_stmts->[-1]} = lc( $func ) . '_' . $ax->unquote_identifier( $qt_col );
            $i++;
            if ( $i > $#$chosen_cols ) {
                my @tmp_info = $sf->__get_info_rows( $chosen_cols, $func, $function_stmts );
                my $info = join "\n", @tmp_info;
                my $ok = $sf->__confirm_all( $chosen_cols, $info );
                if ( ! $ok ) {
                    $value = undef;
                    $function_stmts = [];
                    $i = 0;
                    next COLUMN;
                }
                else {
                    return $function_stmts;
                }
            }
        }
    }
}


sub __func_Concat {
    my ( $sf, $sql, $cols, $func, $multi_col ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $fsql = App::DBBrowser::Table::Functions::SQL->new( $sf->{i}, $sf->{o} );
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    my $chosen_cols = $sf->__choose_columns( $func, $cols, $multi_col );
    if ( ! defined $chosen_cols ) {
        return;
    }
    my @tmp_info = ( $sf->__func_info( $func ) );
    push @tmp_info, '';
    push @tmp_info, 'Concat(' . join( ',', @$chosen_cols ) . ')';
    my $sep = $tr->readline(
        'Separator: ',
        { info => join( "\n", @tmp_info ) }
    );
    if ( ! defined $sep ) {
        return;
    }
    my $function_stmts = [ $fsql->concatenate( $chosen_cols, $sep ) ];
    my $unquoted_chosen_cols = [ map { $ax->unquote_identifier( $_ ) } @$chosen_cols ];
    $sf->{d}{default_alias}{$function_stmts->[-1]} = lc( $func ) . '_' . join( '_', @$unquoted_chosen_cols );
    return $function_stmts;
}


sub __func_Replace {
    my ( $sf, $sql, $cols, $func, $multi_col ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $fsql = App::DBBrowser::Table::Functions::SQL->new( $sf->{i}, $sf->{o} );
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $fields = [
        [ 'from str', ],
        [ '  to str', ],
    ];
    my $chosen_cols = $sf->__choose_columns( $func, $cols, $multi_col );
    if ( ! defined $chosen_cols ) {
        return;
    }
    my $function_stmts = [];
    my $i = 0;

    COLUMN: while ( 1 ) {
        my $qt_col = $chosen_cols->[$i];
        my $incomplete = $func . '(' . $qt_col . ',?,?)';
        my @tmp_info = $sf->__get_info_rows( $chosen_cols, $func, $function_stmts, $incomplete );
        my $info = join "\n", @tmp_info;
        my $form = $tf->fill_form(
            $fields,
            { info => $info, prompt => '', auto_up => 2,
            confirm => 'CONFIRM  ', back => 'BACK     ' }
        );
        if ( ! $form ) { # if ( ! defined $form->[0][1] ) {
            if ( $i == 0 ) {
                return;
            }
            else {
                $i--;
                pop @$function_stmts;
                next COLUMN;
            }
        }
        else {
            my $string_to_replace =  $sf->{d}{dbh}->quote( $form->[0][1] );
            my $replacement_string = $sf->{d}{dbh}->quote( $form->[1][1] );
            push @$function_stmts, $fsql->replace( $qt_col, $string_to_replace, $replacement_string );
            my $alias_tail = sprintf "_%s_%s_%s", $string_to_replace, $replacement_string, $ax->unquote_identifier( $qt_col );
            $sf->{d}{default_alias}{$function_stmts->[-1]} = lc( $func ) . $alias_tail;
            $fields = $form;
            $i++;
            if ( $i > $#$chosen_cols ) {
                my @tmp_info = $sf->__get_info_rows( $chosen_cols, $func, $function_stmts );
                my $info = join "\n", @tmp_info;
                my $ok = $sf->__confirm_all( $chosen_cols, $info );
                if ( ! $ok ) {
                    $fields = [
                        [ 'from str', ],
                        [ 'to   str', ],
                    ];
                    $function_stmts = [];
                    $i = 0;
                    next COLUMN;
                }
                else {
                    return $function_stmts;
                }
            }
        }
    }
}


sub __func_Date_Time {
    my ( $sf, $sql, $cols, $func, $multi_col ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $chosen_cols = $sf->__choose_columns( $func, $cols, $multi_col );
    if ( ! defined $chosen_cols ) {
        return;
    }
    my @top = ( $sf->__get_info_rows( $chosen_cols, $func ) );
    my $key_length = 0;
    my $epochs_all_cols = {};
    my $maxrows = 30;

    for my $qt_col ( @$chosen_cols ) {
        my $stmt = $sf->__select_stmt( $sql, $qt_col, $qt_col );
        my $epochs = $sf->{d}{dbh}->selectcol_arrayref( $stmt, { Columns => [1], MaxRows => 100 }, @{$sql->{where_args}//[]} );
        $epochs_all_cols->{$qt_col} = $epochs;
        $key_length = ( minmax $key_length, print_columns( $qt_col ) )[1];
    }
    $key_length = ( minmax 30, $key_length )[0];
    my ( $function_stmts, $all_example_results ) = $sf->__guess_interval( $sql, $func, $chosen_cols, $epochs_all_cols, $maxrows );
    my $manual = 0;

    while ( 1 ) {
        if ( ! defined $function_stmts ) {
            ( $function_stmts, $all_example_results ) = $sf->__choose_interval( $sql, $func, $chosen_cols, $epochs_all_cols, $maxrows );
            if ( ! defined $function_stmts ) {
                return;
            }
            $manual = 1;
        }
        if ( ! @$function_stmts ) {
            return;
        }
        elsif ( @$chosen_cols == 1 && $manual ) {
            return $function_stmts;
        }
        else {
            my @tmp_info = @top;
            my $max_info = 20;

            for my $i ( 0 .. $#$chosen_cols ) {
                my $qt_col = $chosen_cols->[$i];
                my $example_results = $all_example_results->[$i];
                my $info_row = unicode_sprintf( $qt_col, $key_length, { right_justify => 0 } ) . ': ';
                if ( @$example_results > $max_info ) {
                    $info_row .= join( ', ', @{$example_results}[0 .. $max_info - 1] ) . ', ...';
                }
                else {
                    $info_row .= join( ', ', @$example_results );
                }
                push @tmp_info, line_fold( $info_row, get_term_width, { subseq_tab => ' ' x ( $key_length + 2 ) } );
            }
            my $info = join( "\n", @tmp_info );
            # Choose
            my $choice = $tc->choose(
                [ undef, $sf->{i}{_confirm} ],
                { %{$sf->{i}{lyt_v}}, info => $info, layout => 2, keep => 3 }
            );
            if ( ! defined $choice ) {
                $function_stmts = undef;
                $all_example_results = undef;
                next;
            }
            else {
                return $function_stmts;
            }
        }
    }
}


sub __select_stmt {
    my ( $sf, $sql, $select_col, $where_col ) = @_;
    my $stmt;
    if ( length $sql->{where_stmt} ) {
        $stmt = "SELECT $select_col FROM $sql->{table} " . $sql->{where_stmt} . " AND $where_col IS NOT NULL";
    }
    else {
        $stmt = "SELECT $select_col FROM $sql->{table} WHERE $where_col IS NOT NULL";
    }
    if ( $sf->{i}{driver} =~ /^(?:Firebird|DB2|Oracle)\z/ ) {
        $stmt .= " " . $sql->{offset_stmt} if $sql->{offset_stmt};
        $stmt .= " " . $sql->{limit_stmt}  if $sql->{limit_stmt};
    }
    else {
        $stmt .= " " . $sql->{limit_stmt}  if $sql->{limit_stmt};
        $stmt .= " " . $sql->{offset_stmt} if $sql->{offset_stmt};
    }
    return $stmt;
}


sub __interval_to_converted_epoch { #
    my ( $sf, $sql, $func, $maxrows, $qt_col, $interval ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $fsql = App::DBBrowser::Table::Functions::SQL->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $stmt_convert_epoch;
    if ( $func eq 'Epoch_to_DateTime' ) {
        $stmt_convert_epoch = $fsql->epoch_to_datetime( $qt_col, $interval );
        $sf->{d}{default_alias}{$stmt_convert_epoch} = 'to_datetime_' . $ax->unquote_identifier( $qt_col );
    }
    else {
        $stmt_convert_epoch = $fsql->epoch_to_date( $qt_col, $interval );
        $sf->{d}{default_alias}{$stmt_convert_epoch} = 'to_date_' . $ax->unquote_identifier( $qt_col );
    }
    my $stmt = $sf->__select_stmt( $sql, $stmt_convert_epoch, $qt_col );
    my $example_results = $sf->{d}{dbh}->selectcol_arrayref( $stmt, { Columns => [1], MaxRows => $maxrows }, @{$sql->{where_args}//[]} );
    return $stmt_convert_epoch, $example_results;
}


sub __guess_interval {
    my ( $sf, $sql, $func, $chosen_cols, $epochs_all_cols, $maxrows ) = @_;
    my $function_stmts = [];
    my $all_example_results = [];
    if ( ! eval {
        for my $qt_col ( @$chosen_cols ) {
            my $epochs = $epochs_all_cols->{$qt_col};
            my %count;

            for my $epoch ( @$epochs ) {
                if ( ! looks_like_number( $epoch ) ) {
                    return;
                }
                ++$count{length( $epoch )};
            }
            if ( keys %count != 1 ) {
                return;
            }
            my $epoch_w = ( keys %count )[0];
            my $interval;
            if ( $epoch_w <= 10 ) {
                $interval = 1;
            }
            elsif ( $epoch_w <= 13 ) {
                $interval = 1_000;
            }
            else {
                $interval = 1_000_000;
            }
            my ( $stmt_convert_epoch, $example_results ) = $sf->__interval_to_converted_epoch( $sql, $func, $maxrows, $qt_col, $interval );
            push @$function_stmts, $stmt_convert_epoch;
            push @$all_example_results, $example_results;
        }
        1 }
    ) {
        return;
    }
    else {
        return $function_stmts, $all_example_results;
    }
}


sub __choose_interval {
    my ( $sf, $sql, $func, $chosen_cols, $epochs_all_cols, $maxrows  ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @top = ( $sf->__get_info_rows( $chosen_cols, $func ) );
    my $function_stmts = [];
    my $all_example_results = [];
    my $i = 0;

    COLUMN: while ( 1 ) {
        my $qt_col = $chosen_cols->[$i];
        my $epoch_formats = [
            [ '      Seconds',  1             ],
            [ 'Milli-Seconds',  1_000         ],
            [ 'Micro-Seconds',  1_000_000     ],
        ];

        CHOOSE_INTERVAL: while ( 1 ) {
            my $info_rows_count = get_term_height() - ( @top + 9 );
            # 9 = col_name +  '...' + prompt + 4 $menu + empty + footer
            my $epochs = $epochs_all_cols->{$qt_col};
            my $count_epochs = @$epochs;
            $info_rows_count = ( minmax $info_rows_count, $maxrows, $count_epochs )[0];
            my @tmp_info = ( @top, $qt_col . ':' );
            push @tmp_info, @{$epochs}[0 .. $info_rows_count - 1];
            push @tmp_info, '...';
            my @pre = ( undef );
            my $menu = [ @pre, map( $_->[0], @$epoch_formats ) ];
            # Choose
            my $idx = $tc->choose( # menu-memory
                $menu,
                { %{$sf->{i}{lyt_v}}, prompt => 'Choose interval:', info => join( "\n", @tmp_info ),
                    index => 1, keep => @$menu + 1, layout => 2, undef => '<<' }
            );
            if ( ! $idx ) {
                if ( $i == 0 ) {
                    delete @{$sf->{d}{default_alias}}{@$function_stmts};
                    return;
                }
                else {
                    $i--;
                    pop @$function_stmts;
                    pop @$all_example_results;
                    next COLUMN;
                }
            }
            my $interval = $epoch_formats->[$idx-@pre][1];
            my ( $stmt_convert_epoch, $example_results );
            @tmp_info = ( @top, $qt_col . ':' );
            if ( ! eval {
                ( $stmt_convert_epoch, $example_results ) = $sf->__interval_to_converted_epoch( $sql, $func, $maxrows, $qt_col, $interval );
                if ( ! $stmt_convert_epoch || ! $example_results ) {
                    die "No results!";
                }
                1 }
            ) {
                my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
                $ax->print_error_message( $@ );
                next CHOOSE_INTERVAL;
            }
            else {
                push @tmp_info, map { defined ? $_ : 'undef' } @{$example_results}[0 .. $info_rows_count - 1];
                push @tmp_info, '...';
            }
            # Choose
            my $choice = $tc->choose(
                [ undef, $sf->{i}{_confirm} ],
                { %{$sf->{i}{lyt_v}}, info => join( "\n", @tmp_info ), layout => 2, keep => 3 }
            );
            if ( ! $choice ) {
                next CHOOSE_INTERVAL;
            }
            elsif ( $choice eq $sf->{i}{_confirm} ) {
                push @$function_stmts, $stmt_convert_epoch;
                push @$all_example_results, $example_results;
                if ( $i == $#$chosen_cols ) {
                    return $function_stmts, $all_example_results;
                }
                else {
                    $i++;
                    next COLUMN;
                }
            }
        }
    }
}








1;


__END__
