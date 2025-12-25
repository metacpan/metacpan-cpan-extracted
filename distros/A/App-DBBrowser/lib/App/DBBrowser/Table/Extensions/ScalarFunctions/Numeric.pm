package # hide from PAUSE
App::DBBrowser::Table::Extensions::ScalarFunctions::Numeric;

use warnings;
use strict;
use 5.016;

use App::DBBrowser::Auxil;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $d
    }, $class;
}


sub function_rand {
    my ( $sf ) = @_;
    my $dbms = $sf->{i}{dbms};
    return "RANDOM()"          if $dbms =~ /^(?:SQLite|Pg|DuckDB)\z/;
    return "DBMS_RANDOM.VALUE" if $dbms eq 'Oracle';
    return "RAND()";
}


sub function_round {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    return $sf->__round_trunc_truncate( $sql, $clause, $func, $cols, $r_data );
}


sub function_trunc {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    return $sf->__round_trunc_truncate( $sql, $clause, $func, $cols, $r_data );
}


sub function_truncate {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    return $sf->__round_trunc_truncate( $sql, $clause, $func, $cols, $r_data );
}


sub __round_trunc_truncate {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $dbms = $sf->{i}{dbms};
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    if ( $dbms eq 'DuckDB' && $func eq 'TRUNC' ) {
        return "$func($col)";
    }
    my $args_data = [
        { prompt => 'Decimal places: ', is_numeric => 1 }
    ];
    my ( $places ) = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
    if ( ! defined $places ) {
        return if $func eq 'TRUNCATE' && $dbms =~ /^(?:mysql|MariaDB)\z/;
        return if $dbms eq 'MSSQL';
        return "$func($col)";
    }
    return "ROUND($col,$places,1)" if $func eq 'TRUNC' && $dbms eq 'MSSQL';
    return "$func($col,$places)";
}


sub function_mod {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $dbms = $sf->{i}{dbms};
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    my $args_data = [
        { prompt => 'Divider: ', is_numeric => 1 }
    ];
    my ( $divider ) = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
    return if ! defined $divider;
    return "($col % $divider)" if $dbms eq 'MSSQL';
    return "MOD($col,$divider)";
}


sub function_power {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    my $args_data = [
        { prompt => 'Exponent: ', is_numeric => 1 }
    ];
    my ( $exponent ) = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
    return if ! defined $exponent;
    return "POWER($col,$exponent)";
}


1;
