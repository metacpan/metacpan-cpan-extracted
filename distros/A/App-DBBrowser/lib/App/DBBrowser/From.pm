package # hide from PAUSE
App::DBBrowser::From;

use warnings;
use strict;
use 5.014;

use App::DBBrowser::Auxil;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $d
    }, $class;
}


sub from_sql {
    my ( $sf, $table_key ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my ( $table, $table_alias, $columns, $aliases );
    if ( $table_key eq 'Join' ) {
        require App::DBBrowser::From::Join;
        my $new_j = App::DBBrowser::From::Join->new( $sf->{i}, $sf->{o}, $sf->{d} );
        $sf->{d}{table_origin} = 'join';
        if ( ! eval { ( $table, $columns, $aliases ) = $new_j->join_tables(); 1 } ) {
            $ax->print_error_message( $@ );
            return;
        }
        return if ! defined $table;
    }
    elsif ( $table_key eq 'Union' ) {
        require App::DBBrowser::From::Union;
        my $new_u = App::DBBrowser::From::Union->new( $sf->{i}, $sf->{o}, $sf->{d} );
        $sf->{d}{table_origin} = 'union';
        if ( ! eval { ( $table, $table_alias ) = $new_u->union_tables(); 1 } ) {
            $ax->print_error_message( $@ );
            return;
        }
        return if ! defined $table;
    }
    elsif ( $table_key eq 'Subquery' ) {
        require App::DBBrowser::From::Subquery;
        my $sq = App::DBBrowser::From::Subquery->new( $sf->{i}, $sf->{o}, $sf->{d} );
        $sf->{d}{table_origin} = 'subquery';
        if ( ! eval { ( $table, $table_alias ) = $sq->subquery_as_main_table(); 1 } ) {
            $ax->print_error_message( $@ );
            return;
        }
        return if ! defined $table;
    }
    elsif ( $table_key eq 'Cte' ) {
        require App::DBBrowser::From::Cte;
        my $cte = App::DBBrowser::From::Cte->new( $sf->{i}, $sf->{o}, $sf->{d} );
        $sf->{d}{table_origin} = 'cte';
        if ( ! eval { $table = $cte->cte_as_main_table() ; 1 } ) {
            $ax->print_error_message( $@ );
            return;
        }
        return if ! defined $table;
    }
    else {
        $sf->{d}{table_origin} = 'ordinary';
        if ( ! eval { ( $table, $table_alias ) = $sf->__ordinary_table( $table_key ); 1 } ) {
            $ax->print_error_message( $@ );
            return;
        }
        return if ! defined $table;
    }
    if ( length $table_alias ) {
        $table .= ' ' . $table_alias;
    }
    my ( $column_names, $column_types ) = $ax->column_names_and_types( $table );
    if ( ! defined $column_names ) {
        return;
    }
    if ( $sf->{d}{table_origin} ne 'join' ) {
        # not with join otherwise possible qualifications of the column names will be lost
        $columns = $column_names;
    }
    my $data_types = {};
    @{$data_types}{@$columns} = @$column_types; ##
    my $sql = {};
    $ax->reset_sql( $sql );
    $sql->{table} = $table;
    $sql->{table_alias} = $table_alias;
    $sql->{columns} = $columns;
    $sql->{data_types} = $data_types;
    $sql->{alias} = $aliases // {};
    return $sql;
}


sub __ordinary_table {
    my ( $sf, $table_key ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $sf->{d}{stmt_types} = [ 'Select' ];
    my $sql = { table => '()' };
    $ax->reset_sql( $sql );
    $ax->print_sql_info( $ax->get_sql_info( $sql ) ); ##
    $sf->{d}{table_key} = $table_key;
    my $table = $ax->qq_table( $sf->{d}{tables_info}{$table_key} );
    my $alias = $ax->table_alias( $sql, 'ordinary_table', $table );
    return $table, $alias;
}



1;

__END__
