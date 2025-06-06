package # hide from PAUSE
App::DBBrowser::Table::Extensions;

use warnings;
use strict;
use 5.016;

use List::MoreUtils qw( uniq );

use Term::Choose         qw();
use Term::Form::ReadLine qw();

use App::DBBrowser::Auxil;
#use App::DBBrowser::From::Subquery;                      # required
#use App::DBBrowser::Table::Extensions::Maths;            # required
#use App::DBBrowser::Table::Extensions::Case;             # required
#use App::DBBrowser::Table::Extensions::ColAliases;       # required
#use App::DBBrowser::Table::Extensions::Columns;          # required
#use App::DBBrowser::Table::Extensions::ScalarFunctions;  # required
#use App::DBBrowser::Table::Extensions::WindowFunctions;  # required
use App::DBBrowser::Table::Substatement::Aggregate;


my $e_const = 'Value';
my $e_subquery = 'SQL';
my $e_scalar_func = 'scalar()';
my $e_window_func = 'win()';
my $e_case = 'case';
my $e_math = 'math';
my $e_col = 'column';
my $e_null = 'NULL';
my $e_close_IN = ')end';
my $e_par_open = '(';
my $e_par_close = ')';
my $e_col_aliases = 'alias';
my $e_skip_col = ''; # no length
my $e_multi_col = 'mc';


sub new {
    my ( $class, $info, $options, $d ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $d
    };
    bless $sf, $class;
}


sub column {
    my ( $sf, $sql, $clause, $r_data, $opt ) = @_;
    $r_data //= [];
    my $extensions = [];
    if ( $clause =~ /^(?:select|order_by)\z/i ) {
        # Window functions are permitted only in SELECT and ORDER BY
        $extensions = [ $e_subquery, $e_scalar_func, $e_window_func, $e_case, $e_math ];
        if ( $clause eq 'select' && ! @$r_data ) {
            push @$extensions, $e_col_aliases;
        }
    }
    else {
        $extensions = [ $e_subquery, $e_scalar_func, $e_case, $e_math ];
    }
    if ( $clause =~ /^where\z/i ) {
        push @$extensions, $e_skip_col, $e_multi_col;
    }
    if ( $opt->{add_parentheses} ) {
        push @$extensions, $e_par_open, $e_par_close;
        delete $opt->{add_parentheses};
    }
    if ( length $opt->{from} ) {
        # no recursion:
        if ( $opt->{from} eq 'window_function' ) {
            $extensions = [ grep { ! /^\Q$e_window_func\E\z/ } @$extensions ];
        }
    }
    #my $last_idx = $#$r_data;
    my $ext_column = $sf->__choose_extension( $sql, $clause, $r_data, 'column', $extensions, $opt );
    #die if $#$r_data != $last_idx;
    return $ext_column;
}


sub value {
    my ( $sf, $sql, $clause, $r_data, $operator, $opt ) = @_;
    $r_data //= [];
    my $ext_express = $sf->{o}{enable}{extended_values};
    my $extensions = [];
    if ( $ext_express ) {
        if ( $clause =~ /^(?:select|order_by)\z/i ) {
            $extensions = [ $e_const, $e_subquery, $e_scalar_func, $e_window_func, $e_case, $e_math, $e_col ];
        }
        else {
            $extensions = [ $e_const, $e_subquery, $e_scalar_func, $e_case, $e_math, $e_col ];
        }
        if ( $clause eq 'set' ) {
            push @$extensions, $e_null;
        }
        if ( $operator =~ /\s(?:ALL|ANY)\z/ || $operator =~ /^(?:NOT )?EXISTS\z/ ) {
            $extensions = [ $e_subquery ];
        }
        elsif ( $operator =~ /^(?:NOT\s)?IN\z/ ) {
            unshift @$extensions, $e_close_IN;
        }
    }
    else {
        if ( $operator =~ /\s(?:ALL|ANY)\z/ ) {
            $extensions = [ $e_subquery ];
        }
        else {
            $extensions = [ $e_const ];
        }
    }
    #my $last_idx = $#$r_data;
    my $ext_value = $sf->__choose_extension( $sql, $clause, $r_data, 'value', $extensions, $opt );
    #die if $#$r_data != $last_idx;
    return $ext_value;
}


sub argument {
    my ( $sf, $sql, $clause, $r_data, $opt ) = @_;
    $r_data //= [];
    my $ext_express = $sf->{o}{enable}{extended_args};
    my $extensions = [];
    if ( $ext_express ) {
        $extensions = [ $e_const, $e_subquery, $e_scalar_func, $e_case, $e_math, $e_col ];
    }
    else {
        $extensions = [ $e_const ];
    }
    #my $last_idx = $#$r_data;
    my $ext_argument = $sf->__choose_extension( $sql, $clause, $r_data, 'argument', $extensions, $opt );
    #die if $#$r_data != $last_idx;
    return $ext_argument;
}


sub enable_extended_arguments {
    my ( $sf, $info ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $prompt = 'Extended arguments:';
    my $yes = '- YES';
    # Choose
    my $choice = $tc->choose(
        [ undef, '- NO', $yes ],
        { %{$sf->{i}{lyt_v}}, info => $info, prompt => $prompt, undef => '<=' }
    );
    if ( ! defined $choice ) {
        return;
    }
    if ( $choice eq $yes ) {
        $sf->{o}{enable}{extended_args} = 1;
    }
    else {
        $sf->{o}{enable}{extended_args} = 0;
    }
}


sub __avail_cols_in_extenstions {
    my ( $sf, $sql, $clause, $extension ) = @_;
    my $cols;
    # in functions cols are used without aliases
    if ( $clause eq 'on' ) {
        $cols = [ @{$sql->{cols_join_condition}} ];
    }
    elsif ( $sql->{aggregate_mode} ) {
        my $sa = App::DBBrowser::Table::Substatement::Aggregate->new( $sf->{i}, $sf->{o}, $sf->{d} );
        my $avail_aggr = $sa->available_aggregate_functions();
        if ( $clause =~ /^(?:select|having|order_by)\z/ && ! $sql->{used_in_aggregate_function} ) {
            $cols = [ uniq( @{$sql->{group_by_cols}}, @$avail_aggr, @{$sql->{selected_cols}} ) ];
        }
        else {
            $cols = [ @{$sql->{columns}} ];
        }
    }
    else {
        my @selected_cols;
        if ( $extension eq $e_window_func || $clause eq 'where' ) {
            @selected_cols = grep { ! /\)\s*OVER\s*\(/i } @{$sql->{selected_cols}};
        }
        else {
             @selected_cols = @{$sql->{selected_cols}};
        }
        if ( $clause =~ /^(?:select|where|order_by)\z/ ) {
            $cols = [ uniq( @{$sql->{columns}}, @selected_cols ) ];
        }
        else {
            $cols = [ @{$sql->{columns}} ];
        }
    }
    return $cols;
}


sub __choose_extension {
    my ( $sf, $sql, $clause, $r_data, $caller, $extensions, $opt ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $old_idx = 0;

    EXTENSION: while ( 1 ) {
        my $info = $ax->get_sql_info( $sql ) . $sf->nested_func_info( $r_data );
        my $extension;
        #if ( @$extensions == 1 ) { ##
        #    $extension = $extensions->[0];
        #}
        #else {
            my $empty;
            if ( $caller eq 'column' && $clause eq 'where' ) {
                $empty = 'skip'; ##
            }
            my @pre = ( undef );
            # Choose
            my $idx = $tc->choose(
                [ @pre, @$extensions ],
                { %{$sf->{i}{lyt_h}}, info => $info, index => 1, default => $old_idx,
                  prompt => $opt->{prompt}, undef => '<<', empty => $empty }
            );
            $ax->print_sql_info( $info );
            if ( ! $idx ) { ##
                return;
            }
            if ( $sf->{o}{G}{menu_memory} ) {
                if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                    $old_idx = 0;
                    next EXTENSION;
                }
                $old_idx = $idx;
            }
            $extension = $extensions->[$idx-@pre];
        #}
        my $cols = $sf->__avail_cols_in_extenstions( $sql, $clause, $extension );
        if ( $extension eq $e_const ) {
            my $prompt = $opt->{prompt} // 'Value: ';
            # Readline
            my $value = $tr->readline(
                $prompt,
                { info => $info, history => $opt->{history} }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $value ) {
                return if @$extensions = 1;
                next EXTENSION;
            }
            # return if ! length $value; ##
            if ( $opt->{is_numeric} ) {
                #  1 numeric
                # -1 unkown
                return $ax->quote_constant( $value );
            }
            else {
                return $sf->{d}{dbh}->quote( $value );
            }
        }
        elsif ( $extension eq $e_subquery ) {
            require App::DBBrowser::From::Subquery;
            my $new_sq = App::DBBrowser::From::Subquery->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $subq = $new_sq->subquery( $sql, $info );
            if ( ! defined $subq ) {
                return if @$extensions == 1;
                next EXTENSION;
            }
            return $subq;
        }
        elsif ( $extension eq $e_scalar_func ) {
            require App::DBBrowser::Table::Extensions::ScalarFunctions;
            my $new_func = App::DBBrowser::Table::Extensions::ScalarFunctions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $scalar_func_stmt = $new_func->scalar_function( $sql, $clause, $cols, $r_data ); # recursion yes
            if ( ! defined $scalar_func_stmt ) {
                return if @$extensions == 1;
                next EXTENSION;
            }
            return $scalar_func_stmt;
        }
        elsif ( $extension eq $e_window_func ) {
            require App::DBBrowser::Table::Extensions::WindowFunctions;
            my $wf = App::DBBrowser::Table::Extensions::WindowFunctions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $win_func_stmt = $wf->window_function( $sql, $clause, $cols, $r_data );
            if ( ! defined $win_func_stmt ) {
                return if @$extensions == 1;
                next EXTENSION;
            }
            return $win_func_stmt;
        }
        elsif ( $extension eq $e_case  ) {
            require App::DBBrowser::Table::Extensions::Case;
            my $new_cs = App::DBBrowser::Table::Extensions::Case->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $case_stmt = $new_cs->case( $sql, $clause, $cols, $r_data ); # recursion yes
            if ( ! defined $case_stmt ) {
                return if @$extensions == 1;
                next EXTENSION;
            }
            return $case_stmt;
        }
        elsif ( $extension eq $e_math  ) {
            require App::DBBrowser::Table::Extensions::Maths;
            my $new_math = App::DBBrowser::Table::Extensions::Maths->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $arith = $new_math->maths( $sql, $clause, $cols, $r_data ); # recursion yes
            if ( ! defined $arith ) {
                return if @$extensions == 1;
                next EXTENSION;
            }
            return $arith;
        }
        elsif ( $extension eq $e_col ) {
            require App::DBBrowser::Table::Extensions::Columns;
            my $new_col = App::DBBrowser::Table::Extensions::Columns->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $col = $new_col->columns( $sql, $cols, $info );
            if ( ! defined $col ) {
                return if @$extensions == 1;
                next EXTENSION;
            }
            return $col;
        }
        elsif ( $extension eq $e_null ) {
            return "NULL";
        }
        elsif ( $extension eq $e_close_IN ) {
            return "''";
        }
        elsif ( $extension eq $e_par_open ) {
            return "(";
        }
        elsif ( $extension eq $e_par_close ) {
            return ")";
        }
        elsif ( $extension eq $e_skip_col  ) {
            return '';
        }
        elsif ( $extension eq $e_col_aliases  ) {
            require App::DBBrowser::Table::Extensions::ColAliases;
            my $new_ca = App::DBBrowser::Table::Extensions::ColAliases->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $col_aliases = $new_ca->column_aliases( $sql );
            if ( ! defined $col_aliases ) {
                return if @$extensions == 1;
                next EXTENSION;
            }
            return $col_aliases;
        }
        elsif ( $extension eq $e_multi_col ) {
            # Choose
            my $chosen_cols = $tu->choose_a_subset(
                $cols,
                { info => $info, prompt => '', layout => 1, index => 0, all_by_default => 0,
                  cs_label => 'Columns: ', cs_begin => '(', cs_separator => ',', cs_end => ')' }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $chosen_cols ) {
                return if @$extensions == 1;
                next EXTENSION;
            }
            return "(" . join( ",", @$chosen_cols ) . ")";
        }
    }
}


sub nested_func_info {
    my ( $sf, $r_data ) = @_;
    if ( ! @$r_data ) {
        return '';
    }
    my @copy = map { [ @$_ ] } @$r_data;
    my ( $scalar, $win, $math, $aggr, $case ) = qw(scalar win math aggr case);
    my $last_type = '';
    my $case_count = 0;
    my @close;
    my $info = "\n";
    for my $i ( 0 .. $#copy ) {
        my $func_info = $copy[$i];
        my $type = shift @$func_info;
        if ( $type eq $scalar ) {
            my $func = shift @$func_info;
            $info .= "$func(" . join ',', @$func_info;
            if ( $func =~ /^(?:CONCAT|COALESCE)/i && @$func_info && $i != $#copy ) { ##
                $info .= ',';
            }
            push @close, ')';
        }
        elsif ( $type eq $win ) {
            if ( @$func_info ) {
                $info .= shift @$func_info;
                push @close, shift @$func_info;
            }
        }
        elsif ( $type eq $math ) {
            $info .= "(" . join '', @$func_info;
            push @close, ')';
        }
        elsif ( $type eq $aggr ) {
            my ( $aggr_func, $distinct ) = @$func_info;
            if ( $aggr_func ) {
                $info .= $aggr_func . ( $distinct ? ' ' . $distinct : '' );
                push @close, ')';
            }
        }
        elsif ( $type eq $case ) {
            require App::DBBrowser::Table::Extensions::Case;
            my $new_cs = App::DBBrowser::Table::Extensions::Case->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $case_stmt = $new_cs->format_case( $func_info, $case_count );
            $case_stmt =~ s/^\s+// if $info =~ /\(\z/;
            $info .= $case_stmt . ' ';
        }
        $last_type = $type;
        $case_count = $type eq $case ? ++$case_count : 0;
    }
    return '' if $info eq "\n";
    $info =~ s/\s\z// if $info =~ /\s\z/;
    $info .= ' ... ';
    $info .= join '', reverse @close;
    $info .= "\n" if $last_type eq $case;
    return $info;
}



1;

__END__
