package # hide from PAUSE
App::DBBrowser::Table::Substatements::Operators;

use warnings;
use strict;
use 5.010001;

use List::MoreUtils qw( any );

use Term::Choose qw();
use Term::Form   qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::Table::Extensions;


sub new {
    my ( $class, $info, $options, $data ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $data,
    };
    bless $sf, $class;
}


sub build_having_col {
    my ( $sf, $sql, $aggr ) = @_;
    my $quote_aggr;
    if ( any { '@' . $_ eq $aggr } @{$sql->{aggr_cols}} ) {
        ( $quote_aggr = $aggr ) =~ s/^\@//;
        $sql->{having_stmt} .= ' ' . $quote_aggr;
    }
    elsif ( $aggr eq 'COUNT(*)' ) {
        $quote_aggr = $aggr;
        $sql->{having_stmt} .= ' ' . $quote_aggr;
    }
    else {
        $aggr =~ s/\(\S\)\z//;
        $sql->{having_stmt} .= ' ' . $aggr . "(";
        $quote_aggr          =       $aggr . "(";
        my $tc = Term::Choose->new( $sf->{i}{default} );
        my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
        $ax->print_sql( $sql );
        # Choose
        my $quote_col = $tc->choose(
            [ undef, @{$sql->{cols}} ],
            { %{$sf->{i}{lyt_h}} }
        );
        if ( ! defined $quote_col ) {
            return;
        }
        $sql->{having_stmt} .= $quote_col . ")";
        $quote_aggr         .= $quote_col . ")";
    }
    return $quote_aggr;
}


sub add_operator_with_value {
    my ( $sf, $sql, $clause, $quote_col ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{default} );
    my $tf = Term::Form->new();
    my $stmt = $clause . '_stmt';
    my $args = $clause . '_args';
    my $sign_idx = $sf->{o}{enable}{'expand_' . $clause};
    my $expand_sign;
    my @operators;
    my @operators_ext;
    if ( $clause eq 'set' ) {
        $expand_sign = $sf->{i}{expand_signs_set}[$sign_idx];
        @operators = ( " = " );
        @operators_ext = ( " = " );
    }
    else {
        $expand_sign = '=' . $sf->{i}{expand_signs}[$sign_idx];
        @operators = @{$sf->{o}{G}{operators}};
        @operators_ext = ( " = ", " != ", " < ", " > ", " >= ", " <= ", "IN", "NOT IN" );
    }
    if ( $sign_idx ) {
        unshift @operators, $expand_sign;
    }
    my $ext_col;

    OPERATOR: while( 1 ) {
        my $op;
        if ( @operators == 1 ) {
            $op = $operators[0];
        }
        else {
            my @pre = ( undef );
            $ax->print_sql( $sql );
            # Choose
            $op = $tc->choose(
                [ @pre, @operators ],
                { %{$sf->{i}{lyt_h}} }
            );
            if ( ! defined $op ) {
                return;
            }
        }
        my $bu_stmt = $sql->{$stmt};
        if ( $op eq $expand_sign ) {
            if ( @operators_ext == 1 ) {
                $op = $operators_ext[0];
            }
            else {
                my @pre = ( undef );
                $sql->{$stmt} .= ' ? Func/SQ';
                $ax->print_sql( $sql );
                # Choose
                $op = $tc->choose(
                    [ @pre, @operators_ext ],
                    { %{$sf->{i}{lyt_h}} }
                );
                if ( ! defined $op ) {
                    $sql->{$stmt} = $bu_stmt;
                    next OPERATOR;
                }
                $op =~ s/^\s+|\s+\z//g;
                $sql->{$stmt} = $bu_stmt . ' ' . $op;
                $ax->print_sql( $sql );

            }
            my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $ext_col = $ext->extended_col( $sql, $clause );
            $sql->{$stmt} = $bu_stmt;
            if ( ! defined $ext_col ) {
                next OPERATOR;
            }
        }
        $op =~ s/^\s+|\s+\z//g;
        my $ok;
        if ( $op =~ /^IS\s(?:NOT\s)?NULL\z/ ) {
            $sql->{$stmt} .= ' ' . $op;
            $ok = 1;
        }
        elsif ( $op =~ /\s%?col%?\z/ ) {
            $ok = $sf->__col_op( $sql, $op, $stmt );
        }
        elsif ( $op =~ /REGEXP(_i)?\z/ ) {
            $ok = $sf->__regex_op( $sql, $op, $stmt, $args, $quote_col );
        }
        elsif ( $op =~ /^(?:NOT\s)?IN\z/ ) {
            $ok = $sf->__in_op( $sql, $op, $stmt, $args, $ext_col );
        }
        elsif ( $op =~ /^(?:NOT\s)?BETWEEN\z/ ) {
            $ok = $sf->__between_op( $sql, $op, $stmt, $args );
        }
        else {
            $ok = $sf->__default_op( $sql, $op, $stmt, $args, $ext_col );
        }
        if ( ! $ok ) {
            $sql->{$stmt} = $bu_stmt;
            next OPERATOR;
        }
        last OPERATOR;
    }
    return 1;
}


sub __col_op {
    my ( $sf, $sql, $op, $stmt ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{default} );
    my $arg;
    if ( $op =~ /^(.+)\s(%?col%?)\z/ ) {
        $op = $1;
        $arg = $2;
    }
    $sql->{$stmt} .= ' ' . $op;
    $ax->print_sql( $sql );
    my $quote_col;
    #if ( defined $ext_col ) {   #
    #    $quote_col = $ext_col;  #
    #}                           #
    #else {                      #
        if ( $stmt eq 'having_stmt' ) {
            my @pre = ( undef, $sf->{i}{ok} );
            my @choices = ( @{$sf->{aggregate}}, map( '@' . $_,  @{$sql->{aggr_cols}} ) );
            # Choose
            my $aggr = $tc->choose(
                [ @pre, @choices ],
                { %{$sf->{i}{lyt_h}} }
            );
            if ( ! defined $aggr ) {
                return;
            }
            if ( $aggr eq $sf->{i}{ok} ) {
            }
            my $backup_tmp = $sql->{$stmt};
            $quote_col =  $sf->build_having_col( $sql, $aggr );
            $sql->{$stmt} = $backup_tmp;
        }
        else {
            # Choose
            $quote_col = $tc->choose(
                $sql->{cols},
                { %{$sf->{i}{lyt_h}}, prompt => 'Col:' }
            );
        }
        if ( ! defined $quote_col ) {
            return;
        }
    #}                           #
    if ( $arg !~ /%/ ) {
        $sql->{$stmt} .= ' ' . $quote_col;
    }
    else {
        if ( ! eval {
            my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
            my @el = map { "'$_'" } grep { length $_ } $arg =~ /^(%?)(col)(%?)\z/g;
            my $qt_arg = $plui->concatenate( \@el );
            $qt_arg =~ s/'col'/$quote_col/;
            $sql->{$stmt} .= ' ' . $qt_arg;
            1 }
        ) {
            $ax->print_error_message( $@, $op . ' ' . $arg );
            return;
        }
    }
    return 1
}


sub __regex_op {
    my ( $sf, $sql, $op, $stmt, $args, $quote_col ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $ax->print_sql( $sql );
    $sql->{$stmt} =~ s/ (?: (?<=\() | \s ) \Q$quote_col\E \z //x;
    my $do_not_match_regexp = $op =~ /^NOT/       ? 1 : 0;
    my $case_sensitive      = $op =~ /REGEXP_i\z/ ? 0 : 1;
    my $regex_op;
    if ( ! eval {
        my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
        $regex_op = $plui->regexp( $quote_col, $do_not_match_regexp, $case_sensitive );
        1 }
    ) {
        $ax->print_error_message( $@, $op );
        return;
    }
    #if ( $ext_col ) {                       #
    #    $regex_op =~ s/\?/$ext_col/;        #
    #    $sql->{$stmt} .= $regex_op;         #
    #    return 1;                           #
    #}                                       #
    $regex_op =~ s/^\s// if $sql->{$stmt} =~ /\(\z/;
    $sql->{$stmt} .= $regex_op;
    push @{$sql->{$args}}, '...';
    $ax->print_sql( $sql );
    my $tf = Term::Form->new();
    # Readline
    my $value = $tf->readline( 'Pattern: ' );
    if ( ! defined $value ) {
        return;
    }
    $value = '^$' if ! length $value;
    pop @{$sql->{$args}};
    push @{$sql->{$args}}, $value;
    return 1
}


sub __in_op {
    my ( $sf, $sql, $op, $stmt, $args, $ext_col ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tf = Term::Form->new();
    $sql->{$stmt} .= ' ' . $op;
    if ( $ext_col ) {                           #
        $ext_col =~ s/^\s*\(|\)\s*\z//g;        #
        $sql->{$stmt} .= '(' . $ext_col . ')';  #
        return 1;                               #
    }                                           #
    my $col_sep = '';
    $sql->{$stmt} .= '(';

    IN: while ( 1 ) {
        $ax->print_sql( $sql );
        # Readline
        my $value = $tf->readline( 'Value: ' );
        if ( ! defined $value ) {
            return;
        }
        if ( $value eq '' ) {
            if ( $col_sep eq '' ) {
                return;
            }
            $sql->{$stmt} .= ')';
            return 1;
        }
        $sql->{$stmt} .= $col_sep . '?';
        push @{$sql->{$args}}, $value;
        $col_sep = ',';
    }
}


sub __between_op {
    my ( $sf, $sql, $op, $stmt, $args ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tf = Term::Form->new();
    $sql->{$stmt} .= ' ' . $op;
    #if ( $ext_col ) {                       #
    #    $sql->{$stmt} .= ' ' . $ext_col;    #
    #    return 1;                           #
    #}                                       #
    $ax->print_sql( $sql );
    # Readline
    my $value_1 = $tf->readline( 'Value 1: ' );
    if ( ! defined $value_1 ) {
        return;
    }
    $sql->{$stmt} .= ' ' . '?' . ' AND';
    push @{$sql->{$args}}, $value_1;
    $ax->print_sql( $sql );
    # Readline
    my $value_2 = $tf->readline( 'Value 2: ' );
    if ( ! defined $value_2 ) {
        return;
    }
    $sql->{$stmt} .= ' ' . '?';
    push @{$sql->{$args}}, $value_2;
    return 1;
}


sub __default_op {
    my ( $sf, $sql, $op, $stmt, $args, $ext_col ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tf = Term::Form->new();
    $sql->{$stmt} .= ' ' . $op;
    if ( $ext_col ) {                       #
        $sql->{$stmt} .= ' ' . $ext_col;    #
        return 1;                           #
    }                                       #
    $ax->print_sql( $sql );
    my $prompt = $op =~ /^(?:NOT\s)?LIKE\z/ ? 'Pattern: ' : 'Value: '; #
    # Readline
    my $value = $tf->readline( $prompt );
    if ( ! defined $value ) {
        return;
    }
    $sql->{$stmt} .= ' ' . '?';
    push @{$sql->{$args}}, $value;
    return 1;

}




1;


__END__
