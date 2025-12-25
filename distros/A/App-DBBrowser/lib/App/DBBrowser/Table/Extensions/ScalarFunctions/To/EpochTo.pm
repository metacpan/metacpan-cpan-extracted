package # hide from PAUSE
App::DBBrowser::Table::Extensions::ScalarFunctions::To::EpochTo;

use warnings;
use strict;
use 5.016;

use Scalar::Util qw( looks_like_number );

use List::MoreUtils qw( minmax );

use Term::Choose       qw();
use Term::Choose::Util qw( get_term_height );

use App::DBBrowser::Auxil;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $d
    }, $class;
}


sub epoch_to {
    my ( $sf, $sql, $col, $func ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $stmt = $sf->__select_stmt( $sql, $col, $col );
    my $epochs = $sf->{d}{dbh}->selectcol_arrayref( $stmt, { Columns => [1], MaxRows => 500 });
    my $info = $ax->get_sql_info( $sql );
    my $avail_h = get_term_height() - ( $info =~ tr/\n// + 10 ); # 10 = "\n" + col_name +  '...' + prompt + (4 menu) + empty row + footer
    my $max_examples = 50;
    $max_examples = ( minmax $max_examples, $avail_h, scalar( @$epochs ) )[0];
    my ( $function_stmt, $example_results ) = $sf->__guess_interval( $sql, $func, $col, $epochs, $max_examples, $info );

    while ( 1 ) {
        if ( ! defined $function_stmt ) {
            ( $function_stmt, $example_results ) = $sf->__choose_interval( $sql, $func, $col, $epochs, $max_examples, $info );
            if ( ! defined $function_stmt ) {
                return;
            }
            return $function_stmt;
        }
        my @info_rows = ( $col );
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
    if ( $sql->{order_by_stmt} ) {
        $stmt .= " " . $sql->{order_by_stmt};
    }
    if ( $sql->{limit_stmt} =~ /^LIMIT\b/i ) {
        $stmt .= " " . $sql->{limit_stmt};
        $stmt .= " " . $sql->{offset_stmt} if $sql->{offset_stmt};
    }
    else {
        $stmt .= " " . $sql->{offset_stmt} if $sql->{offset_stmt};
        $stmt .= " " . $sql->{limit_stmt}  if $sql->{limit_stmt};
    }
    return $stmt;
}


sub __interval_to_converted_epoch {
    my ( $sf, $sql, $func, $max_examples, $col, $interval ) = @_;
    my $function_stmt;
    if ( $func eq 'EPOCH_TO_DATETIME' ) {
        $function_stmt = $sf->__stmt_epoch_to_datetime( $col, $interval );
    }
    elsif ( $func eq 'EPOCH_TO_TIMESTAMP' ) {
        $function_stmt = $sf->__stmt_epoch_to_timestamp( $col, $interval );
    }
    else {
        $function_stmt = $sf->__stmt_epoch_to_date( $col, $interval );
    }
    my $stmt = $sf->__select_stmt( $sql, $function_stmt, $col );
    my $example_results = $sf->{d}{dbh}->selectcol_arrayref(
        $stmt,
        { Columns => [1], MaxRows => $max_examples }
    );
    return $function_stmt, [ map { $_ // 'undef' } @$example_results ];
}


sub __guess_interval {
    my ( $sf, $sql, $func, $col, $epochs, $max_examples ) = @_;
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
        ( $function_stmt, $example_results ) = $sf->__interval_to_converted_epoch( $sql, $func, $max_examples, $col, $interval );

        1 }
    ) {
        return;
    }
    else {
        return $function_stmt, $example_results;
    }
}


sub __choose_interval {
    my ( $sf, $sql, $func, $col, $epochs, $max_examples, $info  ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $epoch_formats = [
        [ '      Seconds',  1             ],
        [ 'Milli-Seconds',  1_000         ],
        [ 'Micro-Seconds',  1_000_000     ],
    ];
    my $old_idx = 0;

    CHOOSE_INTERVAL: while ( 1 ) {
        my @example_epochs = ( $col );
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
            ( $function_stmt, $example_results ) = $sf->__interval_to_converted_epoch( $sql, $func, $max_examples, $col, $interval );
            if ( ! $function_stmt || ! $example_results ) {
                die "No results!";
            }
            1 }
        ) {
            my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $ax->print_error_message( $@ );
            next CHOOSE_INTERVAL;
        }
        unshift @$example_results, $col;
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



sub __stmt_epoch_to_date {
    my ( $sf, $col, $interval ) = @_;
    #my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $dbms = $sf->{i}{dbms};
    if ( $dbms eq 'SQLite' ) {
        return "DATE($col/$interval,'unixepoch','localtime')";
    }
    elsif ( $dbms =~ /^(?:mysql|MariaDB)\z/ ) {
        return "FROM_UNIXTIME($col/$interval,'%Y-%m-%d')";
    }
    elsif ( $dbms =~ /^(?:Pg|DuckDB)\z/ ) { ##
        return "TO_TIMESTAMP(${col}::bigint/$interval)::date";
    }
    elsif ( $dbms eq 'Firebird' ) {
        #my $firebird_major_version = $ax->major_server_version();
        my $firebird_major_version = 3; ##
        if ( $firebird_major_version >= 4 ) {
            #return "DATEADD(CAST($col AS BIGINT)/$interval SECOND TO DATE '1970-01-01 UTC') AT LOCAL";
            return "CAST(DATEADD(CAST($col AS BIGINT)/$interval SECOND TO DATE '1970-01-01 UTC') AT LOCAL AS VARCHAR(10))";
        }
        else {
            #   return "DATEADD(CAST($col AS BIGINT)/$interval SECOND TO DATE '1970-01-01')";
            return "CAST(DATEADD(CAST($col AS BIGINT)/$interval SECOND TO DATE '1970-01-01') AS VARCHAR(10))";
        }
    }
    elsif ( $dbms eq 'DB2' ) {
        return "TIMESTAMP('1970-01-01') + ($col/$interval) SECONDS";
    }
    elsif ( $dbms eq 'Informix' ) {
        return "TO_CHAR(DBINFO('utc_to_datetime',$col/$interval),'%Y-%m-%d')";
    }
    elsif ( $dbms eq 'Oracle' ) {
        return "TO_CHAR((TIMESTAMP '1970-01-01 00:00:00 UTC' + $col/$interval * INTERVAL '1' SECOND) AT TIME ZONE SESSIONTIMEZONE,'YYYY-MM-DD')";
    }
    elsif ( $dbms eq 'MSSQL' ) { # no timezone
        return "CAST(DATEADD(s,$col,'1970-01-01') AS DATE)"            if $interval == 1;
        return "CAST(DATEADD(s,$col/$interval,'1970-01-01') AS DATE)";
    }
}


sub __stmt_epoch_to_timestamp {
    my ( $sf, $col, $interval ) = @_;
    #my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $dbms = $sf->{i}{dbms};
    if ( $dbms =~ /^(?:Pg|DuckDB)\z/ ) { ##
        return "TO_TIMESTAMP(${col}::bigint)"              if $interval == 1;
        return "TO_TIMESTAMP(${col}::bigint/$interval.0)";
    }
    elsif ( $dbms eq 'Firebird' ) {
        #my $firebird_major_version = $ax->major_server_version();
        my $firebird_major_version = 3; ##
        if ( $firebird_major_version >= 4 ) {
            return "DATEADD(SECOND,$col,TIMESTAMP '1970-01-01 UTC') AT LOCAL"                                 if $interval == 1;
            return "DATEADD(MILLISECOND,CAST($col AS BIGINT),TIMESTAMP '1970-01-01 UTC') AT LOCAL"            if $interval == 1_000;
            $interval /= 1_000;
            return "DATEADD(MILLISECOND,CAST($col AS BIGINT)/$interval,TIMESTAMP '1970-01-01 UTC') AT LOCAL";
        }
        else {
            return "DATEADD(SECOND,$col,TIMESTAMP '1970-01-01')"                                 if $interval == 1;
            return "DATEADD(MILLISECOND,CAST($col AS BIGINT),TIMESTAMP '1970-01-01')"            if $interval == 1_000;
            $interval /= 1_000;
            return "DATEADD(MILLISECOND,CAST($col AS BIGINT)/$interval,TIMESTAMP '1970-01-01')";
        }
    }
    elsif ( $dbms eq 'Oracle' ) {
        return "(TIMESTAMP '1970-01-01 00:00:00 UTC' + $col * INTERVAL '1' SECOND) AT TIME ZONE SESSIONTIMEZONE"            if $interval == 1;
        return "(TIMESTAMP '1970-01-01 00:00:00 UTC' + $col/$interval * INTERVAL '1' SECOND) AT TIME ZONE SESSIONTIMEZONE";
    }
    elsif ( $dbms eq 'MSSQL' ) {
        #return "DATEADD(s,$col,CAST('1970-01-01T00:00:00+00:00' AS datetimeoffset(0)))"             if $interval == 1;;
        #return "DATEADD(s,$col/$interval.0,CAST('1970-01-01T00:00:00+00:00' AS datetimeoffset(3)))" if $interval == 1_000;
        #return "DATEADD(s,$col/$interval.0,CAST('1970-01-01T00:00:00+00:00' AS datetimeoffset(6)))" if $interval == 1_000_000;
        return "DATEADD(s,$col,'1970-01-01 00:00:00') AT TIME ZONE 'UTC'"                                                                    if $interval == 1;
        return "DATEADD(ms,$col%$interval,DATEADD(s,$col/$interval,CONVERT(datetime2(3),'1970-01-01 00:00:00.000'))) AT TIME ZONE 'UTC'"     if $interval == 1_000;
        return "DATEADD(mcs,$col%$interval,DATEADD(s,$col/$interval,CONVERT(datetime2(6),'1970-01-01 00:00:00.000000'))) AT TIME ZONE 'UTC'" if $interval == 1_000_000;
        #return "DATEADD(ns,$col%1000000000,DATEADD(s,$col/1000000000,CONVERT(datetime2(7),'1970-01-01 00:00:00.0000000'))) AT TIME ZONE 'UTC'"
    }
}


sub __stmt_epoch_to_datetime {
    my ( $sf, $col, $interval ) = @_;
    #my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $dbms = $sf->{i}{dbms};
    if ( $dbms eq 'SQLite' ) {
        return "DATETIME($col,'unixepoch','localtime')"                       if $interval == 1;
        return "DATETIME($col/$interval.0,'unixepoch','localtime','subsec')";
    }
    elsif ( $dbms =~ /^(?:mysql|MariaDB)\z/ ) {   # DATE_FORMAT and STR_TO_DATE ##
        # mysql: FROM_UNIXTIME doesn't work with negative timestamps
        return "FROM_UNIXTIME($col)"             if $interval == 1;
        return "FROM_UNIXTIME($col * 0.001)"     if $interval == 1_000;
        return "FROM_UNIXTIME($col * 0.000001)";
    }
    elsif ( $dbms eq 'Pg' ) {
        return "TO_CHAR(TO_TIMESTAMP(${col}::bigint)::timestamp,'yyyy-mm-dd hh24:mi:ss')"                 if $interval == 1;
        return "TO_CHAR(TO_TIMESTAMP(${col}::bigint/$interval.0)::timestamp,'yyyy-mm-dd hh24:mi:ss.ff3')" if $interval == 1_000;
        return "TO_CHAR(TO_TIMESTAMP(${col}::bigint/$interval.0)::timestamp,'yyyy-mm-dd hh24:mi:ss.ff6')";
    }
    elsif ( $dbms eq 'DuckDB' ) {
        return "TO_TIMESTAMP($col)::timestamp"                                            if $interval == 1;
        return "STRFTIME(TO_TIMESTAMP($col/$interval)::timestamp,'%Y-%m-%d %H:%M:%S.%g')" if $interval == 1_000;
        return "TO_TIMESTAMP($col/$interval)::timestamp";
    }
    elsif ( $dbms eq 'Firebird' ) {
        #my $firebird_major_version = $ax->major_server_version();
        my $firebird_major_version = 3; ##
        if ( $firebird_major_version >= 4 ) {
            return "SUBSTRING(CAST(DATEADD(SECOND,CAST($col AS BIGINT),TIMESTAMP '1970-01-01 UTC') AT LOCAL AS VARCHAR(24)) FROM 1 FOR 19)"      if $interval == 1;
            return "SUBSTRING(CAST(DATEADD(MILLISECOND,CAST($col AS BIGINT),TIMESTAMP '1970-01-01 UTC') AT LOCAL AS VARCHAR(24)) FROM 1 FOR 23)" if $interval == 1_000;
            $interval /= 1_000;                        # don't remove the ".0"
            return "CAST(DATEADD(MILLISECOND,CAST($col AS BIGINT)/$interval.0,TIMESTAMP '1970-01-01 UTC') AT LOCAL AS VARCHAR(24))";
        }
        else {
            return "SUBSTRING(CAST(DATEADD(SECOND,CAST($col AS BIGINT),TIMESTAMP '1970-01-01') AS VARCHAR(24)) FROM 1 FOR 19)"      if $interval == 1;
            return "SUBSTRING(CAST(DATEADD(MILLISECOND,CAST($col AS BIGINT),TIMESTAMP '1970-01-01') AS VARCHAR(24)) FROM 1 FOR 23)" if $interval == 1_000;
            $interval /= 1_000;                        # don't remove the ".0"
            return "CAST(DATEADD(MILLISECOND,CAST($col AS BIGINT)/$interval.0,TIMESTAMP '1970-01-01') AS VARCHAR(24))";
        }
    }
    elsif ( $dbms eq 'DB2' ) { # TO_DATE and TO_CHAR ##
        return "TIMESTAMP('1970-01-01 00:00:00',0) + $col SECONDS"              if $interval == 1;
        return "TIMESTAMP('1970-01-01 00:00:00',3) + ($col/$interval) SECONDS"  if $interval == 1_000;
        return "TIMESTAMP('1970-01-01 00:00:00',6) + ($col/$interval) SECONDS";
    }
    elsif ( $dbms eq 'Informix' ) { # TO_CHAR ##
        return "DBINFO('utc_to_datetime',$col)"            if $interval == 1;
        return "DBINFO('utc_to_datetime',$col/$interval)";
    }
    elsif ( $dbms eq 'Oracle' ) {
        return "TO_CHAR((TIMESTAMP '1970-01-01 00:00:00 UTC' + $col * INTERVAL '1' SECOND) AT TIME ZONE SESSIONTIMEZONE,'YYYY-MM-DD HH24:MI:SS')"                if $interval == 1;
        return "TO_CHAR((TIMESTAMP '1970-01-01 00:00:00 UTC' + $col/$interval * INTERVAL '1' SECOND) AT TIME ZONE SESSIONTIMEZONE,'YYYY-MM-DD HH24:MI:SS.FF3')"  if $interval == 1_000;
        return "TO_CHAR((TIMESTAMP '1970-01-01 00:00:00 UTC' + $col/$interval * INTERVAL '1' SECOND) AT TIME ZONE SESSIONTIMEZONE,'YYYY-MM-DD HH24:MI:SS.FF6')";
    }
    elsif ( $dbms eq 'MSSQL' ) {
        return "CONVERT(VARCHAR(19),DATEADD(s,$col,'1970-01-01 00:00:00'),20)"            if $interval == 1;
        return "CONVERT(VARCHAR(19),DATEADD(s,$col/$interval,'1970-01-01 00:00:00'),20)";
        #return "FORMAT(DATEADD(SECOND,$col,'1970-01-01 00:00:00'),'yyyy-MM-dd HH:mm:ss')"            if $interval == 1; ##
        #return "FORMAT(DATEADD(SECOND,$col/$interval,'1970-01-01 00:00:00'),'yyyy-MM-dd HH:mm:ss')";
    }
}



1;
