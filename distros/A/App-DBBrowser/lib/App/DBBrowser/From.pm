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
    my ( $sf, $table ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my ( $qt_table, $qt_columns, $qt_aliases );
    if ( $table eq 'Join' ) {
        require App::DBBrowser::From::Join;
        my $new_j = App::DBBrowser::From::Join->new( $sf->{i}, $sf->{o}, $sf->{d} );
        $sf->{d}{table_origin} = 'join';
        if ( ! eval { ( $qt_table, $qt_columns, $qt_aliases ) = $new_j->join_tables(); 1 } ) {
            $ax->print_error_message( $@ );
            return;
        }
        return if ! defined $qt_table;
    }
    elsif ( $table eq 'Union' ) {
        require App::DBBrowser::From::Union;
        my $new_u = App::DBBrowser::From::Union->new( $sf->{i}, $sf->{o}, $sf->{d} );
        $sf->{d}{table_origin} = 'union';
        if ( ! eval { $qt_table = $new_u->union_tables(); 1 } ) {
            $ax->print_error_message( $@ );
            return;
        }
        return if ! defined $qt_table;
    }
    elsif ( $table eq 'Subquery' ) {
        require App::DBBrowser::Subquery;
        my $sq = App::DBBrowser::Subquery->new( $sf->{i}, $sf->{o}, $sf->{d} );
        $sf->{d}{table_origin} = 'subquery';
        if ( ! eval { $qt_table = $sq->subquery_as_main_table(); 1 } ) {
            $ax->print_error_message( $@ );
            return;
        }
        return if ! defined $qt_table;
    }
    elsif ( $table eq 'Cte' ) {
        require App::DBBrowser::From::Cte;
        my $cte = App::DBBrowser::From::Cte->new( $sf->{i}, $sf->{o}, $sf->{d} );
        $sf->{d}{table_origin} = 'cte';
        if ( ! eval { $qt_table = $cte->cte_as_main_table() ; 1 } ) {
            $ax->print_error_message( $@ );
            return;
        }
        return if ! defined $qt_table;
    }
    else {
        $sf->{d}{table_origin} = 'ordinary';
        $table =~ s/^[-\ ]\s//;
        if ( ! eval { $qt_table = $sf->__ordinary_table( $table ); 1 } ) {
            $ax->print_error_message( $@ );
            return;
        }
        return if ! defined $qt_table;
    }
    my ( $column_names, $column_types ) = $ax->column_names_and_types( $qt_table );
    if ( ! defined $column_names ) {
        return;
    }
    if ( $sf->{d}{table_origin} ne 'join' ) {
        $qt_columns = $ax->quote_cols( $column_names );
    }
    my $data_types = {};
    @{$data_types}{@$qt_columns} = @$column_types; ##
    my $sql = {};
    $ax->reset_sql( $sql );
    $sql->{table} = $qt_table;
    $sql->{columns} = $qt_columns;
    $sql->{data_types} = $data_types;
    $sql->{alias} = $qt_aliases // {};
    return $sql;
}


sub __ordinary_table {
    my ( $sf, $table ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $sf->{d}{stmt_types} = [ 'Select' ];
    my $sql = { table => '()' };
    $ax->reset_sql( $sql );
    $ax->print_sql_info( $ax->get_sql_info( $sql ) ); ##
    $sf->{d}{table_key} = $table;
    my $qt_table = $ax->qq_table( $sf->{d}{tables_info}{$table} );
    my $qt_alias = $ax->table_alias( $sql, 'ordinary_table', $qt_table );
    if ( length $qt_alias ) {
        $qt_table .= " " . $qt_alias;
    }
    return $qt_table;
}



1;

__END__
