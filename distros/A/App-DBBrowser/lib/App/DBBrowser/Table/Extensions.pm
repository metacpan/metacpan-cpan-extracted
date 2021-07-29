package # hide from PAUSE
App::DBBrowser::Table::Extensions;

use warnings;
use strict;
use 5.010001;

use Term::Choose qw();

use App::DBBrowser::Auxil;
#use App::DBBrowser::Subqueries;        # required
#use App::DBBrowser::Table::Functions;  # required


sub new {
    my ( $class, $info, $options, $data ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $data
    }, $class;
}


sub complex_unit {
    my ( $sf, $sql, $clause, $want_array ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my ( $function, $subquery, $set_to_null ) = ( 'f()', 'SQ', '=N' );
    my @types;
    if ( $sf->{o}{enable}{'expand_' . $clause} ) {
        if ( $clause eq 'set' ) {
            @types = ( $function, $subquery, $set_to_null );
        }
        else {
            @types = ( $function, $subquery );
        }
    }
    my $info = $ax->get_sql_info( $sql );
    # Choose
    my $type = $tc->choose(
        [ undef, @types ],
        { %{$sf->{i}{lyt_h}}, info => $info }
    );
    $ax->print_sql_info( $info );
    if ( ! defined $type ) {
        return;
    }
    my $complex_units = [];
    if ( $type eq $set_to_null ) {
        return "NULL";
    }
    elsif ( $type eq $subquery ) {
        require App::DBBrowser::Subqueries;
        my $new_sq = App::DBBrowser::Subqueries->new( $sf->{i}, $sf->{o}, $sf->{d} );
        my $subq = $new_sq->choose_subquery( $sql );
        if ( ! defined $subq ) {
            return;
        }
        if ( $want_array ) {
            return [ $subq ];
        }
        else {
            return $subq;
        }
    }
    elsif ( $type eq $function ) {
        require App::DBBrowser::Table::Functions;
        my $new_func = App::DBBrowser::Table::Functions->new( $sf->{i}, $sf->{o}, $sf->{d} );
        my $col_with_func = $new_func->col_function( $sql, $clause );
        if ( ! defined $col_with_func ) {
            return;
        }
        if ( $want_array ) { # SELECT
            return $col_with_func;
        }
        else {
            return join( ', ', @$col_with_func );
            # with 'WHERE' + ('IN' or 'NOT IN') possible @$func > 1
        }
    }
}




1;


__END__
