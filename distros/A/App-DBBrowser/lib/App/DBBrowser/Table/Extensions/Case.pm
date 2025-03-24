package # hide from PAUSE
App::DBBrowser::Table::Extensions::Case;

use warnings;
use strict;
use 5.014;

use Term::Choose         qw();
use Term::Form::ReadLine qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::Table::Extensions;
use App::DBBrowser::Table::Substatement::Condition;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $d
    }, $class;
}


sub case {
    my ( $sf, $sql, $clause, $cols, $r_data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $sc = App::DBBrowser::Table::Substatement::Condition->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $depth = 0;
    for my $e ( reverse @$r_data ) {
        last if $e->[0] ne 'case';
        $depth++;
    }
    my $case_parts = [ "CASE" ];
    push @$r_data, [ 'case', @$case_parts ];
    my @bu;
    my $else_on = 0;

    SUBSTMT: while ( 1 ) {
        my ( $when, $else, $end ) = ( 'WHEN', 'ELSE', 'END' );
        my @pre = ( undef );
        my $menu;
        if ( $else_on ) {
             $menu = [ @pre, $end ];
        }
        else {
            $menu = [ @pre, $when, $else, $end ];
        }
        $r_data->[-1] = [ 'case', @$case_parts, '' ];
        my $info = $ax->get_sql_info( $sql ) . $ext->nested_func_info( $r_data );
        # Choose
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_h}}, info => $info, prompt => 'Your choice:', index => 1, undef => '<=' }
        );
        $ax->print_sql_info( $info );
        if ( ! $idx ) {
            if ( @bu ) {
                $case_parts = pop @bu;
                $r_data->[-1] = [ 'case', @$case_parts ];
                $else_on = 0;
                next SUBSTMT;
            }
            pop @$r_data;
            return;
        }
        if ( $menu->[$idx] eq $end ) {
            pop @$r_data;
            push @$case_parts, "END";
            my $case_stmt = $sf->format_case( $case_parts, $depth );
            if ( ! $depth ) {
                $case_stmt = $ax->normalize_space_in_stmt( $case_stmt );
            }
            return $case_stmt;
        }
        push @bu, [ @$case_parts ];
        my $operator = '=';
        if ( $menu->[$idx] eq $when ) {
            push @$case_parts, "WHEN";
            $r_data->[-1] = [ 'case', @$case_parts ];
            my $clause_when = $clause . '_WHEN';
            my $tmp_sql = $ax->clone_data( $sql );
            my $ret = $sc->add_condition( $tmp_sql, $clause_when, $cols, $r_data );
            if ( ! defined $ret ) {
                $case_parts = pop @bu;
                next SUBSTMT;
            }
            $case_parts->[-1] = $tmp_sql->{when_stmt} . " THEN";
        }
        elsif ( $menu->[$idx] eq $else ) {
            $else_on = 1;
            push @$case_parts, "ELSE";
        }
        $r_data->[-1] = [ 'case', @$case_parts ];
        my $value = $ext->value( $sql, $clause, $r_data, $operator, { is_numeric => -1 } );
        if ( ! defined $value ) {
            $case_parts = pop @bu;
            next SUBSTMT;
        }
        $case_parts->[-1] .= ' ' . $value;
    }
}


sub format_case {
    my ( $sf, $case_parts, $depth ) = @_;
    $depth++;
    my $in = ' ' x $sf->{o}{G}{base_indent};
#    my $pad1 = $in x $depth;
#    my $pad2 = $in x ( $depth + 1 );
    my $pad1 = '';
    my $pad2 = '';
    if ( $depth == 1 ) {
        $pad1 = '';
        $pad2 = $in x 2;
    }
    else {
        my $d = $depth * 2;
        $pad1 = $in x $d;
        $pad2 = $in x ( $d + 2);
    }
    $pad1 .= $in;
    $pad2 .= $in;
    my $CASE = shift @$case_parts;
    my $END;
    if ( @$case_parts && $case_parts->[-1] eq "END" ) {
        $END = pop @$case_parts;
    }
    my $case_stmt;
    if ( $depth > 1 ) {
        $case_stmt .= "\n";
    }
    $case_stmt .= $pad1 . $CASE;
    for my $part ( @$case_parts ) {
        $case_stmt .= "\n" . $pad2 . $part;
    }
    if ( length $END ) {
        $case_stmt .= "\n" . $pad1 . "END";
    }
    return $case_stmt;
}





1;

__END__
