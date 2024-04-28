package # hide from PAUSE
App::DBBrowser::Table::Extensions::ScalarFunctions::EpochToDate;

use warnings;
use strict;
use 5.014;

use Scalar::Util qw( looks_like_number );

use List::MoreUtils qw( minmax );

use Term::Choose       qw();
use Term::Choose::Util qw( get_term_height );

use App::DBBrowser::Auxil;
use App::DBBrowser::Table::Extensions::ScalarFunctions::SQL;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $d
    }, $class;
}


sub func_Date_Time {
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
    if ( $func eq 'EPOCH_TO_DATETIME' ) {
        $function_stmt = $fsql->epoch_to_datetime( $chosen_col, $interval );
    }
    elsif ( $func eq 'EPOCH_TO_TIMESTAMP' ) {
        $function_stmt = $fsql->epoch_to_timestamp( $chosen_col, $interval );
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
