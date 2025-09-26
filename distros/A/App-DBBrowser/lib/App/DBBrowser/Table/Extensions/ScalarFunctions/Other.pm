package # hide from PAUSE
App::DBBrowser::Table::Extensions::ScalarFunctions::Other;

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


sub function_cast {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    my $args_data = [
        { prompt => 'Data type: ', unquote => 1, history => [ qw(VARCHAR CHAR TEXT INT DECIMAL DATE DATETIME TIME TIMESTAMP) ] },
    ];
    my ( $data_type ) = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
    return if ! defined $data_type;
    return "CAST($col AS $data_type)";
}


sub function_coalesce {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $chosen_cols = $ga->choose_columns( $sql, $clause, $func, $cols, $r_data );
    if ( ! defined $chosen_cols ) {
        return;
    }
    return "COALESCE(" . join( ',', @$chosen_cols ) . ")"
}





1;
