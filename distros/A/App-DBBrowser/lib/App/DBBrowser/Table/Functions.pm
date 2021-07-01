package # hide from PAUSE
App::DBBrowser::Table::Functions;

use warnings;
use strict;
use 5.010001;

use List::MoreUtils qw( all );

use Term::Choose           qw();
use Term::Choose::LineFold qw( print_columns );
use Term::Choose::Util     qw( unicode_sprintf );
use Term::Form             qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::DB;


sub new {
    my ( $class, $info, $options, $data ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $data
    }, $class;
}


sub __choose_columns {
    my ( $sf, $function, $cols, $multi_col ) = @_;
    if ( $multi_col ) {
        my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
        # Choose
        my $subset = $tu->choose_a_subset(
            $cols,
            { info => '|' . $function, cs_label => 'Columns: ', layout => 1, cs_separator => ',', keep_chosen => 1, confirm => $sf->{i}{ok}, back => '<<' }
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
            { %{$sf->{i}{lyt_h}}, info => '|' . $function, prompt => 'Choose column: ' }
        );
        if ( ! defined $choice ) {
            return;
        }
        return [ $choice ];
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
    my @functions_sorted = qw( Bit_Length Char_Length Concat Epoch_to_Date Epoch_to_DateTime Replace Round Truncate );
    my $function = $tc->choose(
        [ undef, map( "  $_", @functions_sorted ) ],
        { %{$sf->{i}{lyt_v}}, prompt => 'Function:', undef => '  <=' } # <= BACK
    );
    if ( ! defined $function ) {
        return;
    }
    $function =~ s/^\s\s//;
    my $multi_col = 0;
    if (    $clause =~ /^(?:select|group_by|order_by)\z/
         || $clause eq 'where' && $sql->{where_stmt} =~ /\s(?:NOT\s)?IN\s*\z/
         || $function eq 'concat'
    ) {
        $multi_col = 1;
    }
    my $col_with_func;
    if ( $function eq 'Bit_Length' ) {
        $col_with_func = $sf->__func_Bit_Length( $sql, $cols, $function, $multi_col );
    }
    elsif ( $function eq 'Char_Length' ) {
        $col_with_func = $sf->__func_Char_Length( $sql, $cols, $function, $multi_col );
    }
    elsif ( $function eq 'Concat' ) {
        $col_with_func = $sf->__func_Concat( $sql, $cols, $function, $multi_col );
    }
    elsif ( $function eq 'Replace' ) {
        $col_with_func = $sf->__func_Replace( $sql, $cols, $function, $multi_col );
    }
    elsif ( $function eq 'Round' ) {
        $col_with_func = $sf->__func_Round( $sql, $cols, $function, $multi_col );
    }
    elsif ( $function eq 'Truncate' ) {
        $col_with_func = $sf->__func_Truncate( $sql, $cols, $function, $multi_col );
    }
    elsif ( $function =~ /^Epoch_to_Date(?:Time)?\z/ ) {
        $col_with_func = $sf->__func_Date_Time( $sql, $cols, $function, $multi_col );
    }
    return $col_with_func;
}


sub __func_Bit_Length {
    my ( $sf, $sql, $cols, $func, $multi_col ) = @_;
    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    my $chosen_cols = $sf->__choose_columns( $func, $cols, $multi_col );
    if ( ! defined $chosen_cols ) {
        return;
    }
    my @items;
    for my $qt_col ( @$chosen_cols ) {
        push @items, $plui->bit_length( $qt_col );
    }
    my $quote_f = join ', ', @items;
    return $quote_f;
}


sub __func_Char_Length {
    my ( $sf, $sql, $cols, $func, $multi_col ) = @_;
    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    my $chosen_cols = $sf->__choose_columns( $func, $cols, $multi_col );
    if ( ! defined $chosen_cols ) {
        return;
    }
    my @items;
    for my $qt_col ( @$chosen_cols ) {
        push @items, $plui->char_length( $qt_col );
    }
    my $quote_f = join ', ', @items;
    return $quote_f;
}


sub __func_Concat {
    my ( $sf, $sql, $cols, $func, $multi_col ) = @_;
    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $subset = $sf->__choose_columns( $func, $cols, $multi_col );
    if ( ! defined $subset ) {
        return;
    }
    my $info = "\n" . 'Concat( ' . join( ',', @$subset ) . ' )';
    my $sep = $tf->readline(
        'Separator: ',
        { info => $info }
    );
    if ( ! defined $sep ) {
        return;
    }
    my $quote_f = $plui->concatenate( $subset, $sep );
    return $quote_f;
}


sub __func_Replace {
    my ( $sf, $sql, $cols, $func, $multi_col ) = @_;
    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $fields = [
        [ ' from str', ],
        [ '   to str', ],
    ];
    my $chosen_cols = $sf->__choose_columns( $func, $cols, $multi_col );
    if ( ! defined $chosen_cols ) {
        return;
    }
    my @items;
    COL: for my $qt_col ( @$chosen_cols ) {
        my $info = $func . '(' . $qt_col . ', from_str, to_str)';
        my $form = $tf->fill_form(
            $fields,
            { info => $info, prompt => '', auto_up => 2,
            confirm => '  OK', back => '  <<' }
        );
        if ( ! $form ) {
            next COL;
        }
        #if ( ! defined $form->[0][1] ) {
        #    next COL;
        #}
        my $string_to_replace =  $sf->{d}{dbh}->quote( $form->[0][1] );
        my $replacement_string = $sf->{d}{dbh}->quote( $form->[1][1] );
        push @items, $plui->replace( $qt_col, $string_to_replace, $replacement_string );
        $fields = $form;
    }
    if ( ! @items ) {
        return;
    }
    my $quote_f = join ', ', @items;
    return $quote_f;
}


sub __func_Round {
    my ( $sf, $sql, $cols, $func, $multi_col ) = @_;
    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $chosen_cols = $sf->__choose_columns( $func, $cols, $multi_col );
    if ( ! defined $chosen_cols ) {
        return;
    }
    my @items;
    my $default_number = 2;

    COL: for my $qt_col ( @$chosen_cols ) {
        my $info = $func . ': ' . $qt_col;
        my $name = "Decimal places: ";
        my $precision = $tu->choose_a_number( 2,
            { cs_label => $name, info => $info, small_first => 1, default_number => $default_number }
        );
        if ( ! defined $precision ) {
            next COL;
        }
        $default_number = $precision;
        my $default_sign = 1;
        my $positive_precision = 'ROUND(' . $qt_col . ',  ' . $precision . ')';
        my $negative_precision = 'ROUND(' . $qt_col . ', -' . $precision . ')';
        my $choice = $tc->choose(
            [ undef, $positive_precision, $negative_precision ],
            { layout => 3, undef => '<<', prompt => 'Choose sign:', default => $default_sign }
        );
        if ( ! defined $choice ) {
            next COL;
        }
        if ( $choice eq $negative_precision  ) {
            $precision = -$precision;
            $default_sign = 2;
        }
        else {
            $default_sign = 1;
        }
        push @items, $plui->round( $qt_col, $precision );
    }
    if ( ! @items ) {
        return;
    }
    my $quote_f = join ', ', @items;
    return $quote_f;
}


sub __func_Truncate {
    my ( $sf, $sql, $cols, $func, $multi_col ) = @_;
    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $chosen_cols = $sf->__choose_columns( $func, $cols, $multi_col );
    if ( ! defined $chosen_cols ) {
        return;
    }
    my @items;
    my $default_number = 2;

    COL: for my $qt_col ( @$chosen_cols ) {
        my $info = $func . ': ' . $qt_col;
        my $name = "Decimal places: ";
        my $precision = $tu->choose_a_number( 2,
            { cs_label => $name, info => $info, small_first => 1, default_number => $default_number }
        );
        if ( ! defined $precision ) {
            next COL;
        }
        $default_number = $precision;
        push @items, $plui->truncate( $qt_col, $precision );
    }
    if ( ! @items ) {
        return;
    }
    my $quote_f = join ', ', @items;
    return $quote_f;
}


sub __func_Date_Time {
    my ( $sf, $sql, $cols, $func, $multi_col ) = @_;
    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $chosen_cols = $sf->__choose_columns( $func, $cols, $multi_col );
    if ( ! defined $chosen_cols ) {
        return;
    }
    my $maxrows = 100;
    my $len_epoch = {};

    COL: for my $qt_col ( @$chosen_cols ) {
        my $first_epochs = $sf->{d}{dbh}->selectcol_arrayref(
            "SELECT $qt_col FROM $sql->{table} WHERE REGEXP(?,$qt_col,0)",
            { Columns=>[1], MaxRows => $maxrows },
            '\S'
        );

        LEN_EPOCH: for my $epoch ( @$first_epochs ) {
            if ( $epoch !~ /^\d+\z/ ) {
                ++$len_epoch->{$qt_col}{not_an_integer};
                next LEN_EPOCH;
            }
            ++$len_epoch->{$qt_col}{ '1' x length( $epoch ) };
        }
    }
    my $auto_interval = {};
    my $longest_key = 0;
    for my $qt_col ( keys %$len_epoch ) {
        if ( keys %{$len_epoch->{$qt_col}} == 1 ) {
            my $key = ( keys %{$len_epoch->{$qt_col}} )[0];
            if ( $key eq 'not_an_integer' ) {
                next;
            }
            $auto_interval->{$qt_col} = $key;
            if ( print_columns( $qt_col ) > $longest_key ) {
                $longest_key = print_columns( $qt_col );
            }
        }
    }
    if ( $longest_key > 30 ) {
        $longest_key = 30;
    }
    my $info_dates = 10;
    if ( all { exists $auto_interval->{$_} } @$chosen_cols ) {
        my @items;
        my @tmp_info = ( 'Converted columns:' );
        for my $qt_col ( @$chosen_cols ) {
            my ( $converted_epoch, $first_dates ) = $sf->__interval_to_converted_epoch( $sql, $func, $maxrows, $qt_col, $auto_interval->{$qt_col} );
            push @items, $converted_epoch;
            push @tmp_info,
                    unicode_sprintf( $qt_col, $longest_key, { right_justify => 0 } )
                . ': '
                . join( ', ', @{$first_dates}[0 .. $info_dates - 1] )
                . ( @{$first_dates} > $info_dates ? ', ...' : '' );
        }
        my $info = join( "\n", @tmp_info );
        # Choose
        my $choice = $tc->choose(
            [ undef, $sf->{i}{_confirm} ],
            { %{$sf->{i}{lyt_v}}, info => $info, tabs_info => [ 0, $longest_key ], layout => 3, prompt => 'Choose:' }
        );
        if ( ! $choice ) {
            $auto_interval = {};
        }
        elsif ( $choice eq $sf->{i}{_confirm} ) {
            my $quote_f = join ', ', @items;
            return $quote_f;
        }
    }
    my @items;

    COL: for my $qt_col ( @$chosen_cols ) {
        my $info_rows = 20;
        my $div;

        GET_DIV: while ( 1 ) {
            my $interval;
            if ( $auto_interval->{$qt_col} ) {
                $interval = ( keys %{$len_epoch->{$qt_col}} )[0];
            }
            else {
                my $first_epochs = $sf->{d}{dbh}->selectcol_arrayref(
                    "SELECT $qt_col FROM $sql->{table} WHERE REGEXP(?,$qt_col,0)",
                    { Columns=>[1], MaxRows => $maxrows },
                    '\S'
                );
                my @tmp_info = ( 'Choose interval.', $qt_col . " epochs." );
                push @tmp_info, @{$first_epochs}[0 .. $info_rows - 1];
                if ( @$first_epochs > $info_rows ) {
                    push @tmp_info, '...';
                }
                my $menu = [ undef, map( '*********|' . ( '*' x $_ ), reverse( 0 .. 6 ) ) ];
                my $info = join( "\n", @tmp_info );
                # Choose
                $interval = $tc->choose( # menu-memory
                    $menu,
                    { %{$sf->{i}{lyt_v}}, prompt => '', info => $info, keep => 7, layout => 3, undef => '<<' }
                );
                if ( ! defined $interval ) {
                    next COL;
                }
            }
            my $div = 10 ** ( length( $interval ) - 10 );
            my ( $converted_epoch, $first_dates ) = $sf->__interval_to_converted_epoch( $sql, $func, $maxrows, $qt_col, $interval );
            my @tmp_info = ( $qt_col . " dates:" );
            push @tmp_info, @{$first_dates}[0 .. $info_rows - 1];
            if ( @$first_dates > $info_rows ) {
                push @tmp_info, '...';
            }
            my $info = join( "\n", @tmp_info );
            # Choose
            my $choice = $tc->choose(
                [ undef, $sf->{i}{_confirm} ],
                { %{$sf->{i}{lyt_v}}, info => $info, layout => 3 }
            );
            if ( ! $choice ) {
                if ( exists $auto_interval->{$qt_col} ) {
                    delete $auto_interval->{$qt_col};
                }
                redo GET_DIV;
            }
            elsif ( $choice eq $sf->{i}{_confirm} ) {
                push @items, $converted_epoch;
                next COL;
            }
        }
    }
    if ( ! @items ) {
        return;
    }
    my $quote_f = join ', ', @items;
    return $quote_f;
}




sub __interval_to_converted_epoch { #
    my ( $sf, $sql, $func, $maxrows, $qt_col, $interval ) = @_;
    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    my $div = 10 ** ( length( $interval ) - 10 );
    my $converted_epoch;
    if ( $func eq 'Epoch_to_DateTime' ) {
        $converted_epoch = $plui->epoch_to_datetime( $qt_col, $div );
    }
    else {
        $converted_epoch = $plui->epoch_to_date( $qt_col, $div );
    }
    my $first_dates = $sf->{d}{dbh}->selectcol_arrayref(
        "SELECT $converted_epoch FROM $sql->{table} WHERE REGEXP(?,$qt_col,0)",
        { Columns=>[1], MaxRows => $maxrows },
        '\S'
    );
    return $converted_epoch, $first_dates;
}

1;


__END__
