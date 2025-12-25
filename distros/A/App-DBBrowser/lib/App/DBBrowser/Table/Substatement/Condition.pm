package # hide from PAUSE
App::DBBrowser::Table::Substatement::Condition;

use warnings;
use strict;
use 5.016;

use List::MoreUtils qw( any uniq );

use Term::Choose         qw();
use Term::Form::ReadLine qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::Table::Extensions;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $d
    };
    bless $sf, $class;
}


sub add_condition {
    my ( $sf, $sql, $clause, $cols, $r_data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $AND_OR = '';
    my @bu;
    my $stmt;
    if ( $clause =~ s/_(when)\z//i ) {
        $stmt = 'when_stmt';
        $sql->{$stmt} = uc $1;
    }
    elsif( $clause =~ /^on\z/i ) {
        $stmt = lc( $clause ) . '_stmt';
        $sql->{$stmt} = uc $clause;
    }
    else {
        $stmt = lc( $clause ) . '_stmt';
        @bu = @{$sql->{'bu_' . $stmt}//[]};
        $sql->{$stmt} = pop ( @bu ) // uc $clause;
    }
    my @pre = ( undef, $sf->{i}{ok} );
    if ( $sf->{o}{enable}{extended_cols} ) {
        push @pre, $sf->{i}{menu_addition};
    }

    COL: while ( 1 ) {
        my $info = $sf->__info_add_condition( $sql, $stmt, $r_data );
        # Choose
        my $col = $tc->choose(
            [ @pre, @$cols ],
            { %{$sf->{i}{lyt_h}}, info => $info }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $col ) {
            if ( @bu ) {
                $sql->{$stmt} = pop @bu;
                next COL;
            }
            $sql->{'bu_' . $stmt} = [];
            $sql->{$stmt} = '';
            return;
        }
        if ( $col eq $sf->{i}{ok} ) {
            if ( ! @bu ) {
                $sql->{$stmt} = '';
            }
            else {
                push @bu, $sql->{$stmt};
            }
            $sql->{'bu_' . $stmt} = [ @bu ];
            return 1;
        }
        if ( $col eq $sf->{i}{menu_addition} ) {
            $r_data->[-1][-1] = $sql->{$stmt} if @{$r_data//[]};
            my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $complex_col = $ext->column( $sql, $clause, $r_data, { add_parentheses => 1 } );
            if ( ! defined $complex_col ) {
                next COL;
            }
            $col = $complex_col;
        }
        push @bu, $sql->{$stmt};

        if ( $col eq ')' ) {
            $sql->{$stmt} .= ")";
            next COL;
        }
        if ( @bu == 1 || $sql->{$stmt} =~ /\(\z/ ) {
            $AND_OR = '';
        }
        else {
            my $info = $sf->__info_add_condition( $sql, $stmt, $r_data );
            # Choose
            my $choice = $tc->choose(
                [ undef, "AND", "OR" ],
                { %{$sf->{i}{lyt_h}}, info => $info }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $choice ) {
                $sql->{$stmt} = pop @bu;
                next COL;
            }
            $AND_OR = ' ' . $choice;
        }
        if ( $col eq '(' ) {
            $sql->{$stmt} .= $AND_OR . " (";
            next COL;
        }
        if ( $clause eq 'having' ) {
            my $sa = App::DBBrowser::Table::Substatement::Aggregate->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $col = $sa->get_prepared_aggr_func( $sql, $clause, $col );
            if ( ! defined $col ) {
                $sql->{$stmt} = pop @bu;
                next COL;
            }
        }
        if ( $sql->{$stmt} =~ /\(\z/ ) {
            $sql->{$stmt} .= $col;
        }
        else {
            $sql->{$stmt} .= $AND_OR . ' ' . $col;
        }
        my $ok = $sf->__add_operator_and_value( $sql, $clause, $stmt, $col, $r_data );
        if ( ! $ok ) {
            $sql->{$stmt} = pop @bu;
            next COL;
        }
    }
}


sub __add_operator_and_value {
    my ( $sf, $sql, $clause, $stmt, $col, $r_data ) = @_;
    my $driver = $sf->{i}{driver};
    my $dbms = $sf->{i}{dbms};
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @operators = @{$sf->{o}{G}{operators}};
    my $not_equal = ( any { $_ =~ /^\s?!=\s?\z/ } @operators ) ? "!=" : "<>";
    if ( ! length $col ) {
        $sql->{$stmt} =~ s/\s\z//;
        @operators = ( "EXISTS", "NOT EXISTS" );
    }
    elsif ( $dbms eq 'SQLite' ) {
        @operators = grep { ! /^(?:ANY|ALL)\z/ } @operators;
        @operators = grep { ! /REGEXP/ } @operators if $driver eq 'ODBC';
    }
    elsif ( $dbms eq 'Firebird' ) {
        @operators = uniq map { s/REGEXP(?:_i)?\z/SIMILAR TO/; $_ } @operators;
    }
    elsif ( $dbms eq 'Informix' ) {
        @operators = uniq map { s/REGEXP(?:_i)?\z/MATCHES/; $_ } @operators;
    }

    elsif ( $dbms eq 'MSSQL' ) {
        my $major_server_version = $ax->major_server_version();
        if ( $major_server_version < 17 ) {
            @operators = grep { ! /REGEXP/ } @operators;
        }
    }
    elsif ( $dbms eq 'other' ) {
        @operators = grep { ! /REGEXP/ } @operators;
    }
    my $bu_stmt = $sql->{$stmt};

    OPERATOR: while( 1 ) {
        my $operator;
        #if ( @operators == 1 ) { ##
        #    $operator = $operators[0];
        #}
        #else {
            my @pre = ( undef );
            my $info = $sf->__info_add_condition( $sql, $stmt, $r_data );
            # Choose
            $operator = $tc->choose(
                [ @pre, @operators ],
                { %{$sf->{i}{lyt_h}}, info => $info }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $operator ) {
                $sql->{$stmt} = $bu_stmt;
                return;
            }
        #}
        $operator =~ s/^\s+|\s+\z//g;
        if ( $operator =~ /(?:REGEXP(?:_i)?|SIMILAR\sTO)\z/ ) {
            my $not_match = $operator =~ /^NOT/ ? 1 : 0;
            my $case_sensitive = $operator =~ /REGEXP_i\z/ ? 0 : 1;
            my $regex_op = $sf->__pattern_match( $sql, $col, $not_match, $case_sensitive );
            if ( ! $regex_op ) {
                next OPERATOR if @operators > 1;
                return;
            }
            $sql->{$stmt} =~ s/ (?: (?<=\() | \s ) \Q$col\E \z //x;
            if ( $sql->{$stmt} =~ /\(\z/ ) {
                $regex_op =~ s/^\s//;
            }
            $sql->{$stmt} .= $regex_op;
        }
        elsif ( $operator =~ /^(?:ALL|ANY)\z/) {
            my @comb_op = ( "= $operator", "$not_equal $operator", "> $operator", "< $operator", ">= $operator", "<= $operator" );
            my @pre = ( undef );
            my $info = $sf->__info_add_condition( $sql, $stmt, $r_data );
            # Choose
            $operator = $tc->choose(
                [ @pre, @comb_op ],
                { %{$sf->{i}{lyt_h}}, info => $info }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $operator ) {
                next OPERATOR if @operators > 1;
                return;
            }
            $sql->{$stmt} .= ' ' . $operator;
        }
        elsif ( $operator =~ /^(?:NOT )?EXISTS\z/ ) {
            if ( $sql->{$stmt} =~ /\(\z/ ) {
                $sql->{$stmt} .= $operator;
            }
            else {
                $sql->{$stmt} .= ' ' . $operator;
            }
        }
        else {
            $sql->{$stmt} .= ' ' . $operator;
        }
        my $ok = $sf->read_and_add_value( $sql, $clause, $stmt, $col, $operator, $r_data );
        if ( $ok ) {
            return 1;
        }
        else {
            $sql->{$stmt} = $bu_stmt;
            next OPERATOR if @operators > 1;
            return;
        }
    }
}


sub __info_add_condition {
    my ( $sf, $sql, $stmt, $r_data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $info = $ax->get_sql_info( $sql );
    if ( @{$r_data//[]} ) {
        my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
        $r_data->[-1][-1] = $sql->{$stmt};
        $info .= $ext->nested_func_info( $r_data );
    }
    return $info;
}


sub read_and_add_value {
    my ( $sf, $sql, $clause, $stmt, $col, $operator, $r_data ) = @_;
    my $dbms = $sf->{i}{dbms};
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $is_numeric = $ax->is_numeric( $sql, $col );
    $r_data->[-1][-1] = $sql->{$stmt} if @{$r_data//[]};
    if ( $operator =~ /^IS\s(?:NOT\s)?NULL\z/ ) {
        return 1;
    }
    elsif ( $operator =~ /^(?:NOT\s)?IN\z/ ) {
        my $bu_stmt = $sql->{$stmt};
        $sql->{$stmt} .= ' (';
        my @args;

        IN: while ( 1 ) {
            # Readline
            my $value = $ext->value( $sql, $clause, $r_data, $operator, { is_numeric => $is_numeric } );
            if ( ! defined $value ) {
                if ( ! @args ) {
                    $sql->{$stmt} = $bu_stmt;
                    return;
                }
                pop @args;
                $sql->{$stmt} = $bu_stmt . ' ('  . join ',', @args;
                next IN;
            }
            if ( ! length $value || $value eq "''" ) {
                if ( ! @args ) {
                    $sql->{$stmt} = $bu_stmt;
                    return;
                }
                if ( @args == 1 && $args[0] =~ /^\s*\((.+)\)\s*\z/ ) {
                    # if the only argument is a subquery:
                    # remove the parenthesis around the subquery
                    # because "IN ((subquery))" is not alowed
                    $sql->{$stmt} = $bu_stmt . ' (' . $1;
                }
                $sql->{$stmt} .= ')';
                return 1;
            }
            push @args, $value;
            $sql->{$stmt} = $bu_stmt . ' ('  . join ',', @args;
            $r_data->[-1][-1] = $sql->{$stmt} if @{$r_data//[]};
        }
    }
    elsif ( $operator =~ /^(?:NOT\s)?BETWEEN\z/ ) {
        # Readline
        my $value_1 = $ext->value( $sql, $clause, $r_data, $operator, { is_numeric => $is_numeric } );
        if ( ! defined $value_1 ) {
            return;
        }
        my $bu_stmt = $sql->{$stmt};
        $sql->{$stmt} .= ' ' . $value_1 . ' AND';
        $r_data->[-1][-1] = $sql->{$stmt} if @{$r_data//[]};
        # Readline
        my $value_2 = $ext->value( $sql, $clause, $r_data, $operator, { is_numeric => $is_numeric } );
        if ( ! defined $value_2 ) {
            $sql->{$stmt} = $bu_stmt;
            return;
        }
        $sql->{$stmt} .= ' ' . $value_2;
        return 1;
    }
    elsif ( $operator =~ /(?:REGEXP(?:_i)?|SIMILAR\sTO|MATCHES|LIKE)\z/ ) {
        # Readline
        my $value = $ext->value( $sql, $clause, $r_data, $operator, { is_numeric => 0 } );
        if ( ! defined $value ) {
            return;
        }
        #if ( ! length $value ) {
        #    $value = "''";
        #}
        if ( $operator =~ /SIMILAR\sTO\z/ ) {
            $sql->{$stmt} =~ s/ \? (?=\sESCAPE\s'\\'\z) /$value/x;
        }
        elsif ( $operator =~ /REGEXP(?:_i)?\z/ ) {
            if ( $dbms eq 'SQLite' ) {
                $sql->{$stmt} =~ s/ (?<=\sREGEXP\() \? (?=,\Q$col\E,[01]\)\z) /$value/x;
            }
            elsif ( $dbms =~ /^(?:DB2|Oracle|MSSQL)\z/ ) {
                $sql->{$stmt} =~ s/ \?  (?=,'[ci]'\)\z) /$value/x;
            }
            else {
                $sql->{$stmt} .= ' ' . $value;
            }
        }
        else {
            $sql->{$stmt} .= ' ' . $value;
        }
        return 1;
    }
    else {
        my $value;
        if ( $clause eq 'on' ) {
            $value = $sf->__choose_a_column( $sql, $clause, $stmt, $r_data );
        }
        else {
            # Readline
            $value = $ext->value( $sql, $clause, $r_data, $operator, { is_numeric => $is_numeric } );
        }
        if ( ! defined $value ) {
            return;
        }
        $sql->{$stmt} .= ' ' . $value;
        return 1;
    }
}


sub __choose_a_column {
    my ( $sf, $sql, $clause, $stmt, $r_data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @pre = ( undef );
    if ( $sf->{o}{enable}{extended_cols} ) {
        push @pre, $sf->{i}{menu_addition};
    }
    my @choices = @{$sql->{cols_join_condition}};

    COL: while ( 1 ) {
        my $info = $sf->__info_add_condition( $sql, $stmt, $r_data );
        # Choose
        my $col = $tc->choose(
            [ @pre, @choices ],
            { %{$sf->{i}{lyt_h}}, info => $info }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $col ) {
            return;
        }
        if ( $col eq $sf->{i}{menu_addition} ) {
            if ( @{$r_data//[]} ) {
                $r_data->[-1][-1] = $sql->{$stmt};
            }
            my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $complex_col = $ext->column( $sql, $clause, $r_data );
            if ( ! defined $complex_col ) {
                next COL;
            }
            $col = $complex_col;
        }
        return $col;
    }
}


sub __pattern_match {
    my ( $sf, $sql, $col, $not_match, $case_sensitive ) = @_;
    my $dbms = $sf->{i}{dbms};
    if ( $dbms eq 'SQLite' ) {
        if ( $not_match ) {
            return sprintf " NOT REGEXP(?,%s,%d)", $col, $case_sensitive;
        }
        else {
            return sprintf " REGEXP(?,%s,%d)", $col, $case_sensitive;
        }
    }
    elsif ( $dbms =~ /^(?:mysql|MariaDB)\z/ ) {
        if ( $not_match ) {
            return " $col NOT REGEXP"        if ! $case_sensitive;
            return " $col NOT REGEXP BINARY" if   $case_sensitive;
        }
        else {
            return " $col REGEXP"        if ! $case_sensitive;
            return " $col REGEXP BINARY" if   $case_sensitive;
        }
    }
    elsif ( $dbms eq 'Pg' ) {
        my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
        my $col = $ax->pg_column_to_text( $sql, $col );
        if ( $not_match ) {
            return " $col !~*" if ! $case_sensitive;
            return " $col !~"  if   $case_sensitive;
        }
        else {
            return " $col ~*" if ! $case_sensitive;
            return " $col ~"  if   $case_sensitive;
        }
    }
    elsif ( $dbms eq 'Firebird' ) {
        if ( $not_match ) {
            return " $col NOT SIMILAR TO ? ESCAPE '\\'";
        }
        else {
            return " $col SIMILAR TO ? ESCAPE '\\'";
        }
    }
    elsif ( $dbms =~ /^(?:DB2|Oracle|MSSQL)\z/ ) {
        if ( $not_match ) {
            return " NOT REGEXP_LIKE($col,?,'i')" if ! $case_sensitive;
            return " NOT REGEXP_LIKE($col,?,'c')" if   $case_sensitive;
        }
        else {
            return " REGEXP_LIKE($col,?,'i')" if ! $case_sensitive;
            return " REGEXP_LIKE($col,?,'c')" if   $case_sensitive;
        }
    }
}



# The pattern must match the entire string:
#
# SIMILAR TO:   %   _       no default Escape
# MATCHES:      *   ?       \
# LIKE:         %   _       \    SQLite, Firebird, DB2 and Oracle no default Escape




1;

__END__
