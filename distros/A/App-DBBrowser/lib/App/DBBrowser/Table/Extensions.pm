package # hide from PAUSE
App::DBBrowser::Table::Extensions;

use warnings;
use strict;
use 5.008003;

use Term::Choose qw( choose );

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
    my ( $sf, $sql, $stmt_type, $clause ) = @_;
    my $stmt_h = Term::Choose->new( $sf->{i}{lyt_stmt_h} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my ( $function, $subquery ) = ( 'f()', 'SQ' );
    my @values = ( undef, [ $function ], [ $subquery ], [ $function, $subquery ] );
    my @types = @{$values[$sf->{o}{G}{"extend_$clause"}]};
    my $type;
    if ( @types == 1 ) {
        $type = $types[0];
    }
    else {
        # Choose
        $type = $stmt_h->choose( [ undef, @types ], { undef => '<<' } );
        if ( ! defined $type ) {
            return;
        }
    }
    my $ext_col;
    if ( $type eq $subquery ) {
        require App::DBBrowser::Subqueries;
        my $new_sq = App::DBBrowser::Subqueries->new( $sf->{i}, $sf->{o}, $sf->{d} );
        my $subq = $new_sq->choose_subquery( $sql, $stmt_type, $clause );
        if ( ! defined $subq ) {
            return;
        }
        $ext_col = $subq;
    }
    elsif ( $type eq $function ) {
        require App::DBBrowser::Table::Functions;
        my $new_func = App::DBBrowser::Table::Functions->new( $sf->{i}, $sf->{o}, $sf->{d} );
        my $func = $new_func->col_function( $sql, $stmt_type, $clause );
        if ( ! defined $func ) {
            return;
        }
        $ext_col = $func;
    }
    $ax->print_sql( $sql, [ $stmt_type ] );
    my $alias = $ax->alias( 'subqueries', $ext_col );
    if ( defined $alias && length $alias ) {
        $sql->{alias}{$ext_col} = $ax->quote_col_qualified( [ $alias ] );
    }
    $ax->print_sql( $sql, [ $stmt_type ] );
    return $ext_col;
}




1;


__END__
