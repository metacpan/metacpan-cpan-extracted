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
    my $driver = $sf->{i}{driver};
    return "RANDOM()"          if $driver =~ /^(?:SQLite|Pg)\z/;
    return "DBMS_RANDOM.VALUE" if $driver eq 'Oracle';
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
    my $driver = $sf->{i}{driver};
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    my $args_data = [
        { prompt => 'Decimal places: ', is_numeric => 1 }
    ];
    my ( $places ) = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
    if ( ! defined $places ) {
        return if $func eq 'TRUNCATE' && $driver =~ /^(?:mysql|MariaDB)\z/;
        return "$func($col)";
    }
    return "$func($col,$places)";
}


sub function_mod {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    my $args_data = [
        { prompt => 'Divider: ', is_numeric => 1 }
    ];
    my ( $divider ) = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
    return if ! defined $divider;
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
