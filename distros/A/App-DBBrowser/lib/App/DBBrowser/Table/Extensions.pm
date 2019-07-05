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


sub extended_col {
    my ( $sf, $sql, $clause ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my ( $none, $function, $subquery, $all ) = @{$sf->{i}{expand_signs}};
    my $set_to_null = '=N';
    my @values;
    if ( $clause eq 'set' ) {
        @values = ( undef, [ $function ], [ $subquery ], [ $set_to_null ], [ $function, $subquery, $set_to_null ] );
    }
    else {
        @values = ( undef, [ $function ], [ $subquery ], [ $function, $subquery ] );
    }
    my $sign_idx = $sf->{o}{enable}{'expand_' . $clause};
    my @types = @{$values[$sign_idx]};
    my $type;
    if ( @types == 1 ) {
        $type = $types[0];
    }
    else {
        # Choose
        $type = $tc->choose(
            [ undef, @types ],
            { %{$sf->{i}{lyt_h}} }
        );
        if ( ! defined $type ) {
            return;
        }
    }
    my ( $ext_col, $alias_type );
    if ( $type eq $subquery ) {
        require App::DBBrowser::Subqueries;
        my $new_sq = App::DBBrowser::Subqueries->new( $sf->{i}, $sf->{o}, $sf->{d} );
        my $subq = $new_sq->choose_subquery( $sql );
        if ( ! defined $subq ) {
            return;
        }
        $ext_col = $subq;
        $alias_type = 'subqueries';
    }
    elsif ( $type eq $function ) {
        require App::DBBrowser::Table::Functions;
        my $new_func = App::DBBrowser::Table::Functions->new( $sf->{i}, $sf->{o}, $sf->{d} );
        my $func = $new_func->col_function( $sql, $clause );
        if ( ! defined $func ) {
            return;
        }
        $ext_col = $func;
        $alias_type = 'functions';
    }
    elsif ( $type eq $set_to_null ) {
        return "NULL";
    }
    if ( $clause !~ /^(?:set|where|having|group_by|order_by)\z/i ) {
        my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
        my $alias = $ax->alias( $alias_type, $ext_col );
        if ( defined $alias && length $alias ) {
            $sql->{alias}{$ext_col} = $ax->quote_col_qualified( [ $alias ] );
        }
    }
    return $ext_col;
}




1;


__END__
