package # hide from PAUSE
App::DBBrowser::Table::Extensions::ScalarFunctions;

use warnings;
use strict;
use 5.014;

use Scalar::Util qw( looks_like_number );

use List::MoreUtils qw( all minmax uniq );

use Term::Choose           qw();
use Term::Choose::LineFold qw( line_fold );
use Term::Choose::Util     qw( unicode_sprintf get_term_height get_term_width );
use Term::Form             qw(); ##
use Term::Form::ReadLine   qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::Table::Extensions;
use App::DBBrowser::Table::Extensions::ScalarFunctions::SQL;
use App::DBBrowser::Table::Substatements;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $d
    }, $class;
}


sub __choose_columns {
    my ( $sf, $sql, $clause, $qt_cols, $info, $r_data ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $const = '[val]';
    my @pre = ( undef, $sf->{i}{ok}, $sf->{i}{menu_addition}, $const );
    my $menu = [ @pre, @$qt_cols ];
    my $subset = [];
    my @bu;

    COLUMNS: while ( 1 ) {
        my $fill_string = join( ',', @$subset, '?' );
        $fill_string =~ s/,\?/ ?/;
        my $tmp_info = $info . "\n" . $sf->__nested_func_info( $r_data->{nested_func}, $fill_string );
        # Choose
        my @idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_h}}, info => $tmp_info, prompt => 'Columns:', meta_items => [ 0 .. $#pre - 1 ], ##
              no_spacebar => [ $#pre ], include_highlighted => 2, index => 1 }
        );
        if ( ! $idx[0] ) {
            if ( @bu ) {
                $subset = pop @bu;
                next COLUMNS;
            }
            return;
        }
        if ( $menu->[$idx[0]] eq $sf->{i}{ok} ) {
            shift @idx;
            push @$subset, @{$menu}[@idx];
            if ( ! @$subset ) {
                return;
            }
            return $subset;
        }
        elsif ( $menu->[$idx[0]] eq $sf->{i}{menu_addition} ) {
            # recursion
            my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $bu_nested_func = $ax->clone_data( $r_data );
            # reset nested_func and add an array-ref so the child function knows that the parent is a multi-col function.
            # Children of a  multi-col function start with an empty nested_func. Only whenn they return to
            # the parent multi-col function their results are integrated in the parent nested_func.
            $r_data->{nested_func} = [ [ $sf->__nested_func_info( $r_data->{nested_func}, $fill_string ) ] ];
            my $complex_col = $ext->column(
                $sql, $clause, $r_data,
                { info => $tmp_info }
            );
            $r_data = $bu_nested_func;
            if ( ! defined $complex_col ) {
                next COLUMNS;
            }
            push @bu, [ @$subset ];
            push @$subset, $complex_col;
        }
        elsif ( $menu->[$idx[0]] eq $const ) {
            my $value = $tr->readline(
                'Value: ',
                { info => $tmp_info }
            );
            if ( ! defined $value ) {
                next COLUMNS;
            }
            push @bu, [ @$subset ];
            push @$subset, $ax->quote_constant( $value );
        }
        else {
            push @bu, [ @$subset ];
            if ( $sql->{aggregate_mode} && $clause =~ /^(?:having|order_by)\z/ ) {
                my $sb = App::DBBrowser::Table::Substatements->new( $sf->{i}, $sf->{o}, $sf->{d} );
                push @$subset, grep { length } map { $sb->get_prepared_aggr_func( $sql, $clause, $_ ) } @{$menu}[@idx];
            }
            else {
                push @$subset, @{$menu}[@idx];
            }
        }
    }
}


sub __choose_a_column {
    my ( $sf, $sql, $clause, $qt_cols, $info, $r_data ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    $info .= "\n" . $sf->__nested_func_info( $r_data->{nested_func}, '?' );
    my @pre = ( undef, $sf->{i}{menu_addition} );

    while ( 1 ) {
        # Choose
        my $choice = $tc->choose(
            [ @pre, @$qt_cols ],
            { %{$sf->{i}{lyt_h}}, info => $info, prompt => 'Column:' }
        );
        if ( ! defined $choice ) {
            return;
        }
        elsif ( $choice eq $sf->{i}{menu_addition} ) {
            # recursion
            my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $complex_col = $ext->column(
                $sql, $clause, $r_data,
                { info => $info }
            );
            if ( ! defined $complex_col ) {
                next;
            }
            return $complex_col;
        }
        if ( $sql->{aggregate_mode} && $clause =~ /^(?:having|order_by)\z/ ) {
            my $sb = App::DBBrowser::Table::Substatements->new( $sf->{i}, $sf->{o}, $sf->{d} );
            return $sb->get_prepared_aggr_func( $sql, $clause, $choice );
        }
        return $choice;
    }
}


sub __nested_func_info {
    my ( $sf, $nested_func, $fill_string ) = @_;
    return join( '', map { $_ . '(' } @$nested_func ) . ( $fill_string // '' ) . ( ')' x @$nested_func );
}


sub col_function {
    my ( $sf, $sql, $clause, $qt_cols, $r_data ) = @_;
    if ( ! defined $r_data->{nested_func} ) {
        # reset recursion data other than nested_func
        # at the first call of col_function
        $r_data = { nested_func => [] };
    }
    my $parent;
    if ( ref $r_data->{nested_func}[0] eq 'ARRAY' ) {
        # because called from a multi-col function
        $parent = shift @{$r_data->{nested_func}};
        $parent = $parent->[0];
        # $r_data->{nested_func} is now empty
    }
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $driver = $sf->{i}{driver};
    my %functions;

    my $char_length  = 'CHAR_LENGTH';
    my $concat       = 'CONCAT';
    my $left         = 'LEFT';
    my $lower        = 'LOWER';
    my $lpad         = 'LPAD';
    my $ltrim        = 'LTRIM';
    my $octet_length = 'OCTET_LENGTH';
    my $position     = 'POSITION';
    my $replace      = 'REPLACE';
    my $reverse      = 'REVERSE';
    my $right        = 'RIGHT';
    my $rpad         = 'RPAD';
    my $rtrim        = 'RTRIM';
    my $substr       = 'SUBSTR';
    my $trim         = 'TRIM';
    my $upper        = 'UPPER';
    $functions{string} = [ sort( $char_length, $concat, $left, $lower, $lpad, $ltrim, $octet_length, $position, $replace, $reverse, $right, $rpad, $rtrim, $substr, $trim, $upper ) ];
    if ( $sf->{i}{driver} eq 'SQLite' ) {
        $functions{string} = [ grep { ! /^(?:$reverse)\z/ } @{$functions{string}} ];
    }
    if ( $sf->{i}{driver} eq 'DB2' ) {
        $functions{string} = [ grep { ! /^(?:$reverse)\z/ } @{$functions{string}} ];
    }

    my $abs          = 'ABS';
    my $ceil         = 'CEIL';
    my $exp          = 'EXP';
    my $floor        = 'FLOOR';
    my $log          = 'LN';
    my $mod          = 'MOD';
    my $power        = 'POWER';
    my $rand         = 'RAND';
    my $round        = 'ROUND';
    my $sign         = 'SIGN';
    my $sqrt         = 'SQRT';
    my $truncate     = 'TRUNCATE';
    $functions{numeric} = [ sort( $abs, $ceil, $exp, $floor, $log, $mod, $power, $rand, $round, $sign, $sqrt, $truncate ) ];
    if ( $sf->{i}{driver} eq 'Informix' ) {
        $functions{numeric} = [ grep { ! /^$rand\z/ } @{$functions{numeric}} ];
    }

    my $dateadd      = 'DATEADD';
    my $epoch_to_d   = 'EPOCH_TO_DATE';
    my $epoch_to_dt  = 'EPOCH_TO_DATETIME';
    my $extract      = 'EXTRACT';
    my $now          = 'NOW';
    my $year         = 'YEAR';
    my $quarter      = 'QUARTER';
    my $month        = 'MONTH';
    my $week         = 'WEEK';
    my $day          = 'DAY';
    my $hour         = 'HOUR';
    my $minute       = 'MINUTE';
    my $second       = 'SECOND';
    my $day_of_week  = 'DAYOFWEEK';
    my $day_of_year  = 'DAYOFYEAR';
    my $unix_ts      = 'UNIX_TIMESTAMP';
    $functions{date} = [ sort( $dateadd, $epoch_to_d, $epoch_to_dt, $extract, $now, $year, $quarter, $month, $week, $day, $hour, $minute, $second, $day_of_week, $day_of_year ) ]; # , $unix_ts # ###
    if ( $sf->{i}{driver} eq 'Informix' ) {
        $functions{date} = [ grep { ! /^(?:$week|$day_of_year|$unix_ts)\z/ } @{$functions{date}} ];
    }

    my $cast         = 'CAST';
    my $coalesce     = 'COALESCE';
    $functions{other} = [ sort( $cast, $coalesce ) ];

    my @only_func = ( $now, $rand );
    my @one_col_func = (
        $trim, $ltrim, $rtrim, $upper, $lower, $octet_length, $char_length, $reverse,
        $abs, $ceil, $exp, $floor, $log, $sign, $sqrt,
        $year, $quarter, $month, $week, $day, $hour, $minute, $second, $day_of_week, $day_of_year, $unix_ts
    );
    my @one_col_one_arg_func = (
        $left, $position, $right,
        $mod, $power, $round, $truncate,
        $extract,
        $cast,
    );
    my @one_col_two_arg_func = (
        $lpad, $replace, $rpad, $substr,
        $dateadd,
    );
    my @multi_col_func = (
        $concat,
        $coalesce,
    );
    my @epoch_dt_func = (
        $epoch_to_d, $epoch_to_dt,
    );

    my $rx_only_func = join( '|', @only_func );
    my $rx_one_col_func = join( '|', @one_col_func );
    my $rx_one_col_one_arg_func = join( '|', @one_col_one_arg_func );
    my $rx_one_col_two_arg_func = join( '|', @one_col_two_arg_func );
    my $rx_multi_col_func = join( '|', @multi_col_func );
    my $rx_epoch_dt_func = join( '|', @epoch_dt_func );

    my $hidden = 'Scalar functions:';
    my $info = $ax->get_sql_info( $sql );
    my $old_idx_cat = 1;

    CATEGORY: while( 1 ) {

        my $tmp_info = $info;
        if ( length $parent ) {
            # $parent only available at the first recursion after parent
            $tmp_info .= "\n" . $parent;
        }
        if ( @{$r_data->{nested_func}} ) {
            $tmp_info .= "\n" . $sf->__nested_func_info( $r_data->{nested_func}, '?' );
        }
        my @pre = ( $hidden, undef );
        my $menu = [ @pre, '- String', '- Numeric', '- Date', '- Other' ];
        # Choose
        my $idx_cat = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $tmp_info, prompt => '', index => 1, default => $old_idx_cat, undef => '<=' }
        );
        if ( ! defined $idx_cat || ! defined $menu->[$idx_cat] ) {
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx_cat == $idx_cat && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx_cat = 1;
                next CATEGORY;
            }
            $old_idx_cat = $idx_cat;
        }
        my $choice = $menu->[$idx_cat];
#        my $func;
        if ( $choice eq $hidden ) {
            $ext->enable_extended_arguments( $tmp_info );
            if ( $sf->{o}{enable}{extended_args} ) {
                $hidden = 'Scalar functions:*';
            }
            else {
                $hidden = 'Scalar functions:';
            }
            next CATEGORY;
        }
        my $old_idx_func = 0;

        FUNCTION: while( 1 ) {
            my $type = lc( $choice =~ s/^-\s//r );
            @pre = ( undef );
            $menu = [ @pre, map { '- ' . $_ } @{$functions{$type}} ];
            # Choose
            my $idx_func = $tc->choose(
                $menu,
                { %{$sf->{i}{lyt_v}}, info => $tmp_info, prompt => '', index => 1, default => $old_idx_func, undef => '<=' }
            );
            if ( ! defined $idx_func || ! defined $menu->[$idx_func] ) {
                next CATEGORY;
            }
            if ( $sf->{o}{G}{menu_memory} ) {
                if ( $old_idx_func == $idx_func && ! $ENV{TC_RESET_AUTO_UP} ) {
                    $old_idx_func = 0;
                    next FUNCTION;
                }
                $old_idx_func = $idx_func;
            }
            my $func = $menu->[$idx_func] =~ s/^-\s//r;
            push @{$r_data->{nested_func}}, $func;
            my $function_stmt;
            if ( $func =~ /^(?:$rx_only_func)\z/i ) {
                $function_stmt =  $sf->__func_with_no_col( $func );
            }
            elsif ( $func =~ /^(?:$rx_multi_col_func)\z/i ) {
                my $chosen_cols = $sf->__choose_columns( $sql, $clause, $qt_cols, $info, $r_data );
                if ( ! defined $chosen_cols ) {
                    if ( @{$r_data->{nested_func}} == 1 ) {
                        $r_data->{nested_func} = [];
                        next FUNCTION;
                    }
                    pop @{$r_data->{nested_func}};
                    return;
                }
                if ( $func =~ /^$concat\z/i ) {
                    $function_stmt = $sf->__func_Concat( $sql, $chosen_cols, $func, $info );
                }
                elsif ( $func =~ /^$coalesce\z/i ) {
                    $function_stmt = $sf->__func_Coalesce( $sql, $chosen_cols, $func );
                }
            }
            else {
                my $chosen_col = $sf->__choose_a_column( $sql, $clause, $qt_cols, $info, $r_data );
                if ( ! defined $chosen_col ) {
                    if ( @{$r_data->{nested_func}} == 1 ) {
                        $r_data->{nested_func} = [];
                        next FUNCTION;
                    }
                    pop @{$r_data->{nested_func}};
                    return;
                }
                if ( $func =~ /^(?:$rx_one_col_func)\z/i ) {
                    $function_stmt = $sf->__func_with_col( $sql, $chosen_col, $func );
                }
                elsif ( $func =~ /^(?:$rx_one_col_one_arg_func)\z/i ) {
                    my ( $prompt, $history );
                    if ( $func =~ /^$cast\z/i ) {
                        $prompt = 'Data type: ';
                        $history = [ sort qw(VARCHAR CHAR TEXT INT DECIMAL DATE DATETIME TIME TIMESTAMP) ];
                    }
                    if ( $func =~ /^$extract\z/i ) {
                        $prompt = 'Field: ';
                        $history = [ qw(YEAR QUARTER MONTH WEEK DAY HOUR MINUTE SECOND DAYOFWEEK DAYOFYEAR) ];
                        if ( $sf->{i}{driver} eq 'Informix' ) {
                            $history = [ grep { ! /^(?:WEEK|DAYOFYEAR)\z/ } @$history ];
                        }
                    }
                    elsif ( $func =~ /^(?:$round|$truncate)\z/i ) {
                        $prompt = 'Decimal places: ';
                    }
                    elsif ( $func =~ /^(?:$position)\z/i ) {
                        $prompt = 'Substr: ';
                        $history = [];
                    }
                    elsif ( $func =~ /^(?:$left|$right)\z/i ) {
                        $prompt = 'Length: ';
                    }
                    elsif ( $func =~ /^(?:$mod)\z/i ) {
                        $prompt = 'Divider: ';
                    }
                    elsif ( $func =~ /^(?:$power)\z/i ) {
                        $prompt = 'Exponent: ';
                    }
                    $function_stmt = $sf->__func_with_col_and_arg( $sql, $clause, $chosen_col, $func, $info, $prompt, $history );
                }
                elsif ( $func =~ /^(?:$rx_one_col_two_arg_func)\z/i ) {
                    my ( $prompts, $histories );;
                    if ( $func =~ /^(?:$replace)\z/i ) {
                        $prompts = [ 'From string: ', 'To string: ' ];
                    }
                    elsif ( $func =~ /^(?:$substr)\z/i ) {
                        $prompts = [ 'StartPos: ', 'Length: ' ];
                    }
                    elsif ( $func =~ /^(?:$lpad|$rpad)\z/i ) {
                        $prompts = [ 'Length: ', 'Fill: ' ];
                    }
                    elsif ( $func =~ /^(?:$dateadd)\z/i ) {
                        $histories = [
                            undef,
                            [ qw(YEAR MONTH DAY HOUR MINUTE SECOND) ],
                        ];
                        $prompts = [ 'Amount: ', 'Unit: ' ];
                    }
                    $function_stmt = $sf->__func_with_col_and_2args( $sql, $clause, $chosen_col, $func, $info, $prompts, $histories );
                }
                elsif ( $func =~ /^(?:$rx_epoch_dt_func)\z/i ) {
                    $function_stmt = $sf->__func_Date_Time( $sql, $chosen_col, $func, $info );
                }
            }
            if ( ! $function_stmt ) {
                return;
            }
            return $function_stmt;
        }
    }
}

sub __func_with_no_col {
    my ( $sf, $func ) = @_;
    my $fsql = App::DBBrowser::Table::Extensions::ScalarFunctions::SQL->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $function_stmt = $fsql->function_with_no_col( $func );
    return $function_stmt;
}


sub __func_with_col {
    my ( $sf, $sql, $chosen_col, $func ) = @_;
    my $fsql = App::DBBrowser::Table::Extensions::ScalarFunctions::SQL->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $function_stmt = $fsql->function_with_col( $func, $chosen_col );
    return $function_stmt;
}


sub __func_with_col_and_arg {
    my ( $sf, $sql, $clause, $chosen_col, $func, $info, $prompt, $history ) = @_;
    my $fsql = App::DBBrowser::Table::Extensions::ScalarFunctions::SQL->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $info .= "\n" . $func . '(' . $chosen_col . ',?)';
    my $value = $ext->argument( $sql, $clause, { info => $info, history => $history, prompt => $prompt } );
    if ( ! length $value && $func !~ /^(?:ROUND|TRUNCATE)\z/i ) {
        return;
    }
    my $function_stmt = $fsql->function_with_col_and_arg( $func, $chosen_col, $value );
    return $function_stmt;
}


sub __func_with_col_and_2args {
    my ( $sf, $sql, $clause, $chosen_col, $func, $info, $prompts, $history ) = @_;
    my $fsql = App::DBBrowser::Table::Extensions::ScalarFunctions::SQL->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tail = ',?)';
    my ( $arg1, $arg2 );

    while( 1 ) {
        my $tmp_info = $info . "\n" . $func . '(' . $chosen_col . $tail;
        # Readline ##
        $arg1 = $ext->argument( $sql, $clause, { info => $tmp_info, history => $history->[0], prompt => $prompts->[0] } );
        if ( ! length $arg1 ) {
            return;
        }
        $tmp_info =~ s/\Q$tail\E\z/,${arg1}${tail}/;
        # Readline ##
        $arg2 = $ext->argument( $sql, $clause, { info => $tmp_info, history => $history->[1], prompt => $prompts->[1] } );
        if ( ! length $arg2 && $func !~ /^(?:SUBSTR)\z/i ) {
            next;
        }
        last;
    }
    my $function_stmt = $fsql->function_with_col_and_2args( $func, $chosen_col, $arg1, $arg2 );
    return $function_stmt;
}


sub __func_Concat {
    my ( $sf, $sql, $chosen_cols, $func, $info ) = @_;
    my $fsql = App::DBBrowser::Table::Extensions::ScalarFunctions::SQL->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    $info .= "\n" . 'Concat(' . join( ',', @$chosen_cols ) . ')';
    my $sep = $tr->readline(
        'Separator: ',
        { info => $info, history => [ '-', ' ', '_', ',', '/', '=', '+' ] }
    );
    if ( ! defined $sep ) {
        return;
    }
    my $function_stmt = $fsql->concatenate( $chosen_cols, $sep );
    return $function_stmt;
}


sub __func_Coalesce {
    my ( $sf, $sql, $chosen_cols, $func ) = @_;
    my $fsql = App::DBBrowser::Table::Extensions::ScalarFunctions::SQL->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $function_stmt = $fsql->coalesce( $chosen_cols );
    return $function_stmt;
}


sub __func_Date_Time {
    my ( $sf, $sql, $chosen_col, $func, $info ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $stmt = $sf->__select_stmt( $sql, $chosen_col, $chosen_col );
    my $epochs = $sf->{d}{dbh}->selectcol_arrayref( $stmt, { Columns => [1], MaxRows => 500 });
    my $avail_h = get_term_height() - ( $info =~ tr/\n// + 10 ); # 10 = "\n" + col_name +  '...' + prompt + (4 menu) + empty row + footer
    my $max_examples = 50;
    $max_examples = ( minmax $max_examples, $avail_h, scalar( @$epochs ) )[0];
    my ( $function_stmt, $example_results ) = $sf->__guess_interval( $sql, $func, $chosen_col, $epochs, $max_examples, $info );

    while ( 1 ) {
        if ( ! defined $function_stmt ) {
            ( $function_stmt, $example_results ) = $sf->__choose_interval( $sql, $func, $chosen_col, $epochs, $max_examples, $info );
            if ( ! defined $function_stmt ) {
                return;
            }
            return $function_stmt;
        }
        my @info_rows = ( $chosen_col );
        push @info_rows, @$example_results;
        if ( @$epochs > $max_examples ) {
            push @info_rows, '...';
        }
        my $tmp_info = $info . "\n" . join( "\n", @info_rows );
        # Choose
        my $choice = $tc->choose(
            [ undef, $sf->{i}{_confirm} ],
            { %{$sf->{i}{lyt_v}}, info => $tmp_info, layout => 2, keep => 3 }
        );
        if ( ! defined $choice ) {
            $function_stmt = undef;
            $example_results = undef;
            next;
        }
        else {
            return $function_stmt;
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


sub __interval_to_converted_epoch {
    my ( $sf, $sql, $func, $max_examples, $chosen_col, $interval ) = @_;
    my $fsql = App::DBBrowser::Table::Extensions::ScalarFunctions::SQL->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $function_stmt;
    if ( $func =~ /^EPOCH_TO_DATETIME\z/i ) {
        $function_stmt = $fsql->epoch_to_datetime( $chosen_col, $interval );
    }
    else {
        $function_stmt = $fsql->epoch_to_date( $chosen_col, $interval );
    }
    my $stmt = $sf->__select_stmt( $sql, $function_stmt, $chosen_col );
    my $example_results = $sf->{d}{dbh}->selectcol_arrayref(
        $stmt,
        { Columns => [1], MaxRows => $max_examples }
    );
    return $function_stmt, [ map { $_ // 'undef' } @$example_results ];
}


sub __guess_interval {
    my ( $sf, $sql, $func, $chosen_col, $epochs, $max_examples ) = @_;
    my ( $function_stmt, $example_results );
    if ( ! eval {
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
        ( $function_stmt, $example_results ) = $sf->__interval_to_converted_epoch( $sql, $func, $max_examples, $chosen_col, $interval );

        1 }
    ) {
        return;
    }
    else {
        return $function_stmt, $example_results;
    }
}


sub __choose_interval {
    my ( $sf, $sql, $func, $chosen_col, $epochs, $max_examples, $info  ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $epoch_formats = [
        [ '      Seconds',  1             ],
        [ 'Milli-Seconds',  1_000         ],
        [ 'Micro-Seconds',  1_000_000     ],
    ];
    my $old_idx = 0;

    CHOOSE_INTERVAL: while ( 1 ) {
        my @example_epochs = ( $chosen_col );
        if ( @$epochs > $max_examples ) {
            push @example_epochs, @{$epochs}[0 .. $max_examples - 1];
            push @example_epochs, '...';
        }
        else {
            push @example_epochs, @$epochs;
        }
        my $epoch_info = $info . "\n" . join( "\n", @example_epochs );
        my @pre = ( undef );
        my $menu = [ @pre, map( $_->[0], @$epoch_formats ) ];
        # Choose
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, prompt => 'Choose interval:', info => $epoch_info, default => $old_idx,
                index => 1, keep => @$menu + 1, layout => 2, undef => '<<' }
        );
        if ( ! $idx ) {
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx = 0;
                next CHOOSE_INTERVAL;
            }
            $old_idx = $idx;
        }
        my $interval = $epoch_formats->[$idx-@pre][1];
        my ( $function_stmt, $example_results );
        if ( ! eval {
            ( $function_stmt, $example_results ) = $sf->__interval_to_converted_epoch( $sql, $func, $max_examples, $chosen_col, $interval );
            if ( ! $function_stmt || ! $example_results ) {
                die "No results!";
            }
            1 }
        ) {
            my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $ax->print_error_message( $@ );
            next CHOOSE_INTERVAL;
        }
        unshift @$example_results, $chosen_col;
        if ( @$epochs > $max_examples ) {
            push @$example_results, '...';
        }
        my $result_info = $info . "\n" . join( "\n", @$example_results );
        # Choose
        my $choice = $tc->choose(
            [ undef, $sf->{i}{_confirm} ],
            { %{$sf->{i}{lyt_v}}, info => $result_info, layout => 2, keep => 3 }
        );
        if ( ! $choice ) {
            next CHOOSE_INTERVAL;
        }
        return $function_stmt, $example_results;
    }
}




1;


__END__
