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
    my ( $sf, $sql, $clause ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my ( $none, $function, $subquery, $all ) = @{$sf->{i}{menu_additions}};
    my $set_to_null = '=N';
    my @values;
    if ( $clause eq 'set' ) {
        @values = ( undef, [ $function ], [ $subquery ], [ $set_to_null ], [ $function, $subquery, $set_to_null ] );
    }
    else {
        @values = ( undef, [ $function ], [ $subquery ], [ $function, $subquery ] );
    }
    my $i = $sf->{o}{enable}{'expand_' . $clause};
    my @types = @{$values[$i]};
    my $type;
    if ( @types == 1 ) {
        $type = $types[0];
    }
    else {
        my $info = $ax->get_sql_info( $sql );
        # Choose
        $type = $tc->choose(
            [ undef, @types ],
            { %{$sf->{i}{lyt_h}}, info => $info }
        );
        if ( ! defined $type ) {
            return;
        }
    }
    my ( $complex_unit, $alias_type );
    if ( $type eq $subquery ) {
        require App::DBBrowser::Subqueries;
        my $new_sq = App::DBBrowser::Subqueries->new( $sf->{i}, $sf->{o}, $sf->{d} );
        my $subq = $new_sq->choose_subquery( $sql );
        if ( ! defined $subq ) {
            return;
        }
        $complex_unit = $subq;
        $alias_type = 'subqueries';
    }
    elsif ( $type eq $function ) {
        require App::DBBrowser::Table::Functions;
        my $new_func = App::DBBrowser::Table::Functions->new( $sf->{i}, $sf->{o}, $sf->{d} );
        my $func = $new_func->col_function( $sql, $clause );
        if ( ! defined $func ) {
            return;
        }
        $complex_unit = $func;
        $alias_type = 'functions';
    }
    elsif ( $type eq $set_to_null ) {
        return "NULL";
    }
    #if ( $clause !~ /^(?:set|where|having|group_by|order_by)\z/i ) {
    if ( $clause eq 'select' ) {
        my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
        my $alias = $ax->alias( $alias_type, $complex_unit );
        if ( defined $alias && length $alias ) {
            $sql->{alias}{$complex_unit} = $ax->quote_col_qualified( [ $alias ] );
        }
    }
    return $complex_unit;
}




1;


__END__
