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

use App::DBBrowser::DB;
#use App::DBBrowser::Opt::Set; # required


sub new {
    my ( $class, $info, $options, $data ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $data
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
    my ( $sf, $chosen_cols, $func, $col_with_func, $incomplete ) = @_;
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
    if ( defined $col_with_func ) {
        push @tmp, @$col_with_func;
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
    my $Cast              = 'Cast';
    my $Concat            = 'Concat';
    my $Epoch_to_Date     = 'Epoch_to_Date';
    my $Epoch_to_DateTime = 'Epoch_to_DateTime';
    my $Replace           = 'Replace';
    my $Round             = 'Round';
    my $Truncate          = 'Truncate';
    my @functions = ( @simple_functions, $Cast, $Concat, $Epoch_to_Date, $Epoch_to_DateTime, $Replace, $Round, $Truncate );
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
        my $col_with_func = [];
        if ( $func =~ /^(?:$joined_simple_functions)\z/ ) {
            $col_with_func = $sf->__func_with_col( $sql, $cols, $func, $multi_col );
        }
        elsif ( $func eq $Cast ) {
            $col_with_func = $sf->__func_with_col_and_arg( $sql, $cols, $func, $multi_col, 'Data type: ', [] );
        }
        elsif ( $func =~ /^(?:$Round|$Truncate)\z/ ) {
            $col_with_func = $sf->__func_with_col_and_arg( $sql, $cols, $func, $multi_col, 'Decimal places: ', [ 0 .. 9 ] );
        }
        elsif ( $func eq $Concat ) {
            $col_with_func = $sf->__func_Concat( $sql, $cols, $func, $multi_col );
        }
        elsif ( $func eq $Replace ) {
            $col_with_func = $sf->__func_Replace( $sql, $cols, $func, $multi_col );
        }

        elsif ( $func eq $Epoch_to_Date || $func eq $Epoch_to_DateTime ) {
            $col_with_func = $sf->__func_Date_Time( $sql, $cols, $func, $multi_col );
        }
        if ( ! $col_with_func ) {
            next CHOOSE_FUNCTION;
        }
        return $col_with_func;
    }
}


sub __func_with_col {
    my ( $sf, $sql, $cols, $func, $multi_col ) = @_;
    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    my $chosen_cols = $sf->__choose_columns( $func, $cols, $multi_col );
    if ( ! defined $chosen_cols ) {
        return;
    }
    my $col_with_func = [];
    for my $qt_col ( @$chosen_cols ) {
        push @$col_with_func, $plui->function_with_col( $func, $qt_col );
    }
    return $col_with_func;
}


sub __func_with_col_and_arg {
    my ( $sf, $sql, $cols, $func, $multi_col, $prompt, $history ) = @_;
    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    my $chosen_cols = $sf->__choose_columns( $func, $cols, $multi_col );
    if ( ! defined $chosen_cols ) {
        return;
    }
    my @local_history;
    my $col_with_func = [];
    my $value;
    my $i = 0;

    COLUMN: while ( 1 ) {
        my $qt_col = $chosen_cols->[$i];
        my $incomplete = $func . '(' . $qt_col . ', ? )';
        my @tmp_info = $sf->__get_info_rows( $chosen_cols, $func, $col_with_func, $incomplete );
        my $info = join "\n", @tmp_info;
        my $readline = $tr->readline(
            $prompt,
            { info => $info, history => [ @local_history, @{$history//[]} ] }
        );
        if ( ! length $readline ) {
            if ( $i == 0 ) {
                return;
            }
            else {
                $i--;
                pop @$col_with_func;
                next COLUMN;
            }
        }
        else {
            $value = $readline;
            @local_history = ( uniq $value, @local_history );
            push @$col_with_func, $plui->function_with_col_and_arg( $func, $qt_col, $value );
            $i++;
            if ( $i > $#$chosen_cols ) {
                my @tmp_info = $sf->__get_info_rows( $chosen_cols, $func, $col_with_func );
                my $info = join "\n", @tmp_info;
                my $ok = $sf->__confirm_all( $chosen_cols, $info );
                if ( ! $ok ) {
                    $value = undef;
                    $col_with_func = [];
                    $i = 0;
                    next COLUMN;
                }
                else {
                    return $col_with_func;
                }
            }
        }
    }
}


sub __func_Concat {
    my ( $sf, $sql, $cols, $func, $multi_col ) = @_;
    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    my $subset = $sf->__choose_columns( $func, $cols, $multi_col );
    if ( ! defined $subset ) {
        return;
    }
    my @tmp_info = ( $sf->__func_info( $func ) );
    push @tmp_info, '';
    push @tmp_info, 'Concat( ' . join( ',', @$subset ) . ' )';
    my $sep = $tr->readline(
        'Separator: ',
        { info => join( "\n", @tmp_info ) }
    );
    if ( ! defined $sep ) {
        return;
    }
    my $col_with_func = [ $plui->concatenate( $subset, $sep ) ];
    return $col_with_func;
}


sub __func_Replace {
    my ( $sf, $sql, $cols, $func, $multi_col ) = @_;
    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $fields = [
        [ 'from str', ],
        [ 'to   str', ],
    ];
    my $chosen_cols = $sf->__choose_columns( $func, $cols, $multi_col );
    if ( ! defined $chosen_cols ) {
        return;
    }
    my $col_with_func = [];
    my $i = 0;

    COLUMN: while ( 1 ) {
        my $qt_col = $chosen_cols->[$i];
        my $incomplete = $func . '(' . $qt_col . ', ? , ? )';
        my @tmp_info = $sf->__get_info_rows( $chosen_cols, $func, $col_with_func, $incomplete );
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
                pop @$col_with_func;
                next COLUMN;
            }
        }
        else {
            my $string_to_replace =  $sf->{d}{dbh}->quote( $form->[0][1] );
            my $replacement_string = $sf->{d}{dbh}->quote( $form->[1][1] );
            push @$col_with_func, $plui->replace( $qt_col, $string_to_replace, $replacement_string );
            $fields = $form;
            $i++;
            if ( $i > $#$chosen_cols ) {
                my @tmp_info = $sf->__get_info_rows( $chosen_cols, $func, $col_with_func );
                my $info = join "\n", @tmp_info;
                my $ok = $sf->__confirm_all( $chosen_cols, $info );
                if ( ! $ok ) {
                    $fields = [
                        [ 'from str', ],
                        [ 'to   str', ],
                    ];
                    $col_with_func = [];
                    $i = 0;
                    next COLUMN;
                }
                else {
                    return $col_with_func;
                }
            }
        }
    }
}


sub __func_Date_Time {
    my ( $sf, $sql, $cols, $func, $multi_col ) = @_;
    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $chosen_cols = $sf->__choose_columns( $func, $cols, $multi_col );
    if ( ! defined $chosen_cols ) {
        return;
    }
    my @top = ( $sf->__get_info_rows( $chosen_cols, $func ) );
    my $key_length = 0;
    my $epochs_all_cols = {};
    my $maxrows = 30;
    my $select_sprintf_fmt = $sf->__get_select_sprintf_fmt( $sql );

    for my $qt_col ( @$chosen_cols ) {
        my $epochs = $sf->{d}{dbh}->selectcol_arrayref(
            sprintf( $select_sprintf_fmt, $qt_col, $qt_col ),
            { Columns=>[1], MaxRows => 100 },
            @{$sql->{where_args}//[]}
        );
        $epochs_all_cols->{$qt_col} = $epochs;
        $key_length = ( minmax $key_length, print_columns( $qt_col ) )[1];
    }
    $key_length = ( minmax 30, $key_length )[0];
    my ( $col_with_func, $all_first_dates ) = $sf->__get_auto_interval( $sql, $func, $chosen_cols, $epochs_all_cols, $maxrows );
    my $manual = 0;

    while ( 1 ) {
        if ( ! defined $col_with_func ) {
            ( $col_with_func, $all_first_dates ) = $sf->__get_manual_interval( $sql, $func, $chosen_cols, $epochs_all_cols, $maxrows );
            if ( ! defined $col_with_func ) {
                return;
            }
            $manual = 1;
        }
        my $filtered_chosen_cols = [ @$chosen_cols ];

        for my $i ( reverse( 0 .. $#$chosen_cols ) ) {
            if ( ! defined $col_with_func->[$i] ) {
                splice( @$col_with_func,        $i, 1 );
                splice( @$all_first_dates,      $i, 1 );
                splice( @$filtered_chosen_cols, $i, 1 );
            }
        }
        if ( ! @$col_with_func ) {
            return;
        }
        elsif ( @$chosen_cols == 1 && $manual ) {
            return $col_with_func;
        }
        else {
            my @tmp_info = @top;
            my $max_info = 20;

            for my $i ( 0 .. $#$filtered_chosen_cols ) {
                my $qt_col = $filtered_chosen_cols->[$i];
                my $first_dates = $all_first_dates->[$i];
                my $info_row = unicode_sprintf( $qt_col, $key_length, { right_justify => 0 } ) . ': ';
                if ( @$first_dates > $max_info ) {
                    $info_row .= join( ', ', @{$first_dates}[0 .. $max_info - 1] ) . ', ...';
                }
                else {
                    $info_row .= join( ', ', @$first_dates );
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
                $col_with_func = undef;
                $all_first_dates = undef;
                next;
            }
            else {
                return $col_with_func;
            }
        }
    }
}


sub __get_select_sprintf_fmt {
    my ( $sf, $sql ) = @_;
    my $fmt;
    if ( length $sql->{where_stmt} ) {
        $fmt = "SELECT %s FROM $sql->{table} " . $sql->{where_stmt} . " AND %s IS NOT NULL";
    }
    else {
        $fmt = "SELECT %s FROM $sql->{table} WHERE %s IS NOT NULL";
    }
    if ( $sf->{i}{driver} =~ /^(?:Firebird|DB2|Oracle)\z/ ) {
        $fmt .= " " . $sql->{offset_stmt} if $sql->{offset_stmt};
        $fmt .= " " . $sql->{limit_stmt}  if $sql->{limit_stmt};
    }
    else {
        $fmt .= " " . $sql->{limit_stmt}  if $sql->{limit_stmt};
        $fmt .= " " . $sql->{offset_stmt} if $sql->{offset_stmt};
    }
    return $fmt;
}


sub __interval_to_converted_epoch { #
    my ( $sf, $sql, $func, $maxrows, $qt_col, $div ) = @_;
    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    my $converted_epoch;
    if ( $func eq 'Epoch_to_DateTime' ) {
        $converted_epoch = $plui->epoch_to_datetime( $qt_col, $div );
    }
    else {
        $converted_epoch = $plui->epoch_to_date( $qt_col, $div );
    }
    my $select_sprintf_fmt = $sf->__get_select_sprintf_fmt( $sql );
    my $first_dates = $sf->{d}{dbh}->selectcol_arrayref(
        sprintf( $select_sprintf_fmt, $converted_epoch, $qt_col ),
        { Columns=>[1], MaxRows => $maxrows },
        @{$sql->{where_args}//[]}
    );
    if ( ! defined $first_dates ) {
        return;
    }
    return $converted_epoch, $first_dates;
}


sub __get_auto_interval {
    my ( $sf, $sql, $func, $chosen_cols, $epochs_all_cols, $maxrows ) = @_;
    my $col_with_func = [];
    my $all_first_dates = [];
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
            my $interval = ( keys %count )[0];
            my $div;
            if ( $interval <= 10 ) {
                $div = 1;
            }
            elsif ( $interval <= 13 ) {
                $div = 1_000;
            }
            else {
                $div = 1_000_000;
            }
            my ( $converted_epoch, $first_dates ) = $sf->__interval_to_converted_epoch( $sql, $func, $maxrows, $qt_col, $div );
            push @$col_with_func, $converted_epoch;
            push @$all_first_dates, $first_dates;
        }
        1 }
    ) {
        return;
    }
    else {
        return $col_with_func, $all_first_dates;
    }
}


sub __get_manual_interval {
    my ( $sf, $sql, $func, $chosen_cols, $epochs_all_cols, $maxrows  ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @top = ( $sf->__get_info_rows( $chosen_cols, $func ) );
    my $col_with_func = [];
    my $all_first_dates = [];
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
                    return;
                }
                else {
                    $i--;
                    pop @$col_with_func;
                    pop @$all_first_dates;
                    next COLUMN;
                }
            }
            my $div = $epoch_formats->[$idx-@pre][1];
            my ( $converted_epoch, $first_dates );
            @tmp_info = ( @top, $qt_col . ':' );
            if ( ! eval {
                ( $converted_epoch, $first_dates ) = $sf->__interval_to_converted_epoch( $sql, $func, $maxrows, $qt_col, $div );
                1 }
            ) {
                push @tmp_info, $@;
            }
            else {
                push @tmp_info, @{$first_dates}[0 .. $info_rows_count - 1];
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
                push @$col_with_func, $converted_epoch;
                push @$all_first_dates, $first_dates;
                if ( $i == $#$chosen_cols ) {
                    return $col_with_func, $all_first_dates;
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
