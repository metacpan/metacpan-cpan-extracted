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


sub __choose_columns {
    my ( $sf, $func, $cols, $func_info, $multi_col ) = @_;
    $func_info .= "\n";
    if ( $multi_col ) {
        my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
        # Choose
        my $subset = $tu->choose_a_subset(
            $cols,
            { info => $func_info, cs_label => 'Columns: ', prompt => '', layout => 1,
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
            { %{$sf->{i}{lyt_h}}, info => $func_info, prompt => 'Choose column: ' }
        );
        if ( ! defined $choice ) {
            return;
        }
        return [ $choice ];
    }
}


sub __get_info_rows {
    my ( $sf, $chosen_cols, $function_stmts, $incomplete ) = @_;
    my @tmp;
#    if ( @$chosen_cols > 1 ) {
        $function_stmts //= [];
        @tmp = ( @$function_stmts );
        if ( @$chosen_cols > 1 ) {
            push @tmp, @{$chosen_cols}[@$function_stmts .. $#$chosen_cols];
        }
#    }
    if ( defined $incomplete ) {
        if ( @tmp ) {
            push @tmp, '';
        }
        push @tmp, $incomplete;
    }
    return @tmp;
}


sub __confirm_all {
    my ( $sf, $chosen_cols, $info ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
#    if ( @$chosen_cols == 1 ) {
#        return 1;
#    }
#    else {
        my $confirm = ucfirst( lc $sf->{i}{confirm} );
        my $back = ucfirst( lc $sf->{i}{back} );
        # Choose
        my $choice = $tc->choose(
            [ undef, $confirm ],
            { %{$sf->{i}{lyt_v}}, info => $info, layout => 2, keep => 3, undef => $back, prompt => '' }
        );
        if ( ! $choice ) {
            return;
        }
        elsif ( $choice eq $confirm ) {
            return 1;
        }
#    }
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
    my @simple_functions = ( 'TRIM', 'LTRIM', 'RTRIM', 'UPPER', 'LOWER' );
    my @length;
    if ( $driver eq 'DB2' ) {
        @length = ( 'OCTET_LENGTH', 'CHAR_LENGTH_16', 'CHAR_LENGTH_32' );
    }
    else {
        @length = ( 'OCTET_LENGTH', 'CHAR_LENGTH' );
    }
    push @simple_functions, @length;
    my $Cast              = 'CAST';
    my $Concat            = 'CONCAT';
    my $Epoch_to_Date     = 'EPOCH_TO_DATE';
    my $Epoch_to_DateTime = 'EPOCH_TO_DATETIME';
    my $Replace           = 'REPLACE';
    my $Substr            = 'SUBSTR';
    my $Round             = 'ROUND';
    my $Truncate          = 'TRUNCATE';
    my @functions;
    if ( $driver eq 'Informix' ) {
        @functions = ( @simple_functions, $Cast, $Concat,                 $Epoch_to_DateTime, $Replace, $Substr, $Round, $Truncate );
    }
    else {
        @functions = ( @simple_functions, $Cast, $Concat, $Epoch_to_Date, $Epoch_to_DateTime, $Replace, $Substr, $Round, $Truncate );
    }
    my $joined_simple_functions = join( '|', @simple_functions );
    my $prefix = '- ';
    my @pre = ( undef, $sf->{i}{confirm} );
    my $menu = [ @pre, map( $prefix . lc $_, @functions ) ];

    SCALAR_FUNCTION: while( 1 ) {
        my $func_info = '';
        my @chosen_func;

        CHOOSE_FUNCTIONS: while ( 1 ) {
            my $func_str = '';
            for my $func ( @chosen_func ) {
                $func_str = lc( $func ) . '(' . $func_str . ')';
            }
            $func_info = 'Function: ' . $func_str;
            # Choose
            my $idx = $tc->choose(
                $menu,
                { %{$sf->{i}{lyt_v}}, info => $func_info, prompt => '', index => 1, undef => $sf->{i}{back} }
            );
            if ( ! defined $idx || ! defined $menu->[$idx] ) {
                if ( @chosen_func ) {
                    pop @chosen_func;
                    next CHOOSE_FUNCTIONS;
                }
                else {
                    return;
                }
            }
            if ( $menu->[$idx] eq $sf->{i}{confirm} ) {
                last CHOOSE_FUNCTIONS;
            }
            push @chosen_func, $functions[$idx-@pre];
        }
        my $function_stmts = [];

        CHOOSE_COLUMNS: while ( 1 ) {
            for my $i ( 0 .. $#chosen_func ) {
                my $func = $chosen_func[$i];
                my $chosen_cols = [];
                if ( $i == 0 ) {
                    my $multi_col = 0;
                    if (   $clause eq 'select'
                        || $clause eq 'where' && $sql->{where_stmt} =~ /\s(?:NOT\s)?IN\s*\z/
                        || $func eq $Concat
                    ) {
                        $multi_col = 1;
                    }
                    $chosen_cols = $sf->__choose_columns( $func, $cols, $func_info, $multi_col );
                    if ( ! defined $chosen_cols ) {
                        next SCALAR_FUNCTION;
                    }
                }
                else {
                    $chosen_cols = $function_stmts;
                }
                if ( $func =~ /^(?:$joined_simple_functions)\z/ ) {
                    $function_stmts = $sf->__func_with_col( $sql, $chosen_cols, $func );
                }
                elsif ( $func eq $Cast ) {
                    my $prompt = 'Data type: ';
                    $function_stmts = $sf->__func_with_col_and_arg( $sql, $chosen_cols, $func, $prompt, [] );
                }
                elsif ( $func =~ /^(?:$Round|$Truncate)\z/ ) {
                    my $prompt = 'Decimal places: ';
                    $function_stmts = $sf->__func_with_col_and_arg( $sql, $chosen_cols, $func, $prompt, [ 0 .. 9 ] );
                }
                elsif ( $func eq $Replace ) {
                    my $prompts = [ 'from str', '  to str' ];
                    $function_stmts = $sf->__func_with_col_and_2args( $sql, $chosen_cols, $func, $prompts );
                }
                elsif ( $func eq $Substr ) {
                    my $prompts = [ 'StartPos', 'Length  ' ];
                    $function_stmts = $sf->__func_with_col_and_2args( $sql, $chosen_cols, $func, $prompts );
                }
                elsif ( $func eq $Concat ) {
                    $function_stmts = $sf->__func_Concat( $sql, $chosen_cols, $func );
                }
                elsif ( $func =~ /^(?:$Epoch_to_Date|$Epoch_to_DateTime)\z/ ) {
                    $function_stmts = $sf->__func_Date_Time( $sql, $chosen_cols, $func );
                }
                if ( ! $function_stmts ) {
                    next CHOOSE_COLUMNS;
                }
            }
            return $function_stmts;
        }
    }
}


sub __func_with_col {
    my ( $sf, $sql, $chosen_cols, $func ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $fsql = App::DBBrowser::Table::Functions::SQL->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $function_stmts = [];
    for my $qt_col ( @$chosen_cols ) {
        push @$function_stmts, $fsql->function_with_col( $func, $qt_col );
    }
    return $function_stmts;
}


sub __func_with_col_and_arg {
    my ( $sf, $sql, $chosen_cols, $func, $prompt, $history ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $fsql = App::DBBrowser::Table::Functions::SQL->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    my @tmp_history;
    my $function_stmts = [];
    my $value;
    my $i = 0;

    COLUMN: while ( 1 ) {
        my $qt_col = $chosen_cols->[$i];
        my $incomplete = $func . '(' . $qt_col . ',?)';
        my @tmp_info = $sf->__get_info_rows( $chosen_cols, $function_stmts, $incomplete );
        my $info = join "\n", @tmp_info;
        my $readline = $tr->readline(
            $prompt,
            { info => $info, default => $value, history => [ @tmp_history, @{$history//[]} ] }
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
            $i++;
            if ( $i > $#$chosen_cols ) {
                my @tmp_info = $sf->__get_info_rows( $chosen_cols, $function_stmts );
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


sub __func_with_col_and_2args {
    my ( $sf, $sql, $chosen_cols, $func, $prompts ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $fsql = App::DBBrowser::Table::Functions::SQL->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $fields = [
        [ $prompts->[0], ],
        [ $prompts->[1], ],
    ];
    my $function_stmts = [];
    my $i = 0;

    COLUMN: while ( 1 ) {
        my $qt_col = $chosen_cols->[$i];
        my $incomplete = $func . '(' . $qt_col . ',?,?)';
        my @tmp_info = $sf->__get_info_rows( $chosen_cols, $function_stmts, $incomplete );
        my $info = join "\n", @tmp_info;
        my $pad = ' ' x ( length( $fields->[0][0] ) - 1 );
        my $form = $tf->fill_form(
            $fields,
            { info => $info, prompt => '', auto_up => 2,
            confirm => 'OK' . $pad, back => '<<' . $pad }
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
            my $arg1 = $form->[0][1];
            my $arg2 = $form->[1][1];
            push @$function_stmts, $fsql->function_with_col_and_2args( $func, $qt_col, $arg1, $arg2 );
            $fields = $form;
            $i++;
            if ( $i > $#$chosen_cols ) {
                my @tmp_info = $sf->__get_info_rows( $chosen_cols, $function_stmts );
                my $info = join "\n", @tmp_info;
                my $ok = $sf->__confirm_all( $chosen_cols, $info );
                if ( ! $ok ) {
                    $fields = [
                        [ $prompts->[0], ],
                        [ $prompts->[1], ],
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


sub __func_Concat {
    my ( $sf, $sql, $chosen_cols, $func ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $fsql = App::DBBrowser::Table::Functions::SQL->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    my $info = 'Concat(' . join( ',', @$chosen_cols ) . ')';
    my $sep = $tr->readline(
        'Separator: ',
        { info => $info }
    );
    if ( ! defined $sep ) {
        return;
    }
    my $function_stmts = [ $fsql->concatenate( $chosen_cols, $sep ) ];
    my $unquoted_chosen_cols = [ map { $ax->unquote_identifier( $_ ) } @$chosen_cols ];
    return $function_stmts;
}


sub __func_Date_Time {
    my ( $sf, $sql, $chosen_cols, $func ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
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
            my @tmp_info;# = @top;
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
    if ( $func eq 'EPOCH_TO_DATETIME' ) {
        $stmt_convert_epoch = $fsql->epoch_to_datetime( $qt_col, $interval );
    }
    else {
        $stmt_convert_epoch = $fsql->epoch_to_date( $qt_col, $interval );
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
    my @top = @$chosen_cols;
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
            my @tmp_info = ( @top, '', $qt_col );
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
                    pop @$function_stmts;
                    pop @$all_example_results;
                    $top[$i] = $chosen_cols->[$i];
                    next COLUMN;
                }
            }
            my $interval = $epoch_formats->[$idx-@pre][1];
            my ( $stmt_convert_epoch, $example_results );
            @tmp_info = ( @top, '', $qt_col . ':' );
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
                $top[$i] .= ': ' . $epoch_formats->[$idx-@pre][0] =~ s/^\s+//r;
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
