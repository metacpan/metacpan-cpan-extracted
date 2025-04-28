package # hide from PAUSE
App::DBBrowser::Table::Extensions::Maths;

use warnings;
use strict;
use 5.016;

use Term::Choose         qw();
use Term::Form::ReadLine qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::Table::Extensions;
use App::DBBrowser::Table::Substatement::Aggregate;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $d
    }, $class;
}


sub maths {
    my ( $sf, $sql, $clause, $cols, $r_data ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my ( $num, $op ) = ( '[num]', '[op]' );
    my @pre = ( undef, $sf->{i}{ok}, $sf->{i}{menu_addition}, $num, $op );
    my $menu = [ @pre, @$cols ];
    my $info_sql = $ax->get_sql_info( $sql );
    my $items = [];
    push @$r_data, [ 'math' ];
    my @bu;

    CHOICE: while ( 1 ) {
        $r_data->[-1] = [ 'math', @$items ];
        my $info = $info_sql . $ext->nested_func_info( $r_data );
        # Choose
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_h}}, info => $info, prompt => 'Math:', index => 1 }
        );
        if ( ! $idx ) {
            if ( @bu ) {
                $items = pop @bu;
                next CHOICE;
            }
            pop @$r_data;
            return;
        }
        if ( $menu->[$idx] eq $sf->{i}{ok} ) {
            pop @$r_data;
            if ( ! @$items ) {
                return;
            }
            my $result = join ' ', @$items; ##
            $result =~ s/\(\s/(/g;
            $result =~ s/\s\)/)/g;
            return '(' . $result . ')';
        }
        elsif ( $menu->[$idx] eq $sf->{i}{menu_addition} ) {
            my $complex_col = $ext->column( $sql, $clause, $r_data );
            if ( ! defined $complex_col ) {
                next CHOICE;
            }
            push @bu, [ @$items ];
            push @$items, $complex_col;
        }
        elsif ( $menu->[$idx] eq $op ) {
            # Choose
            my $operator = $tc->choose(
                [ undef, ' + ',   ' - ', ' * ', ' / ', ' % ', ' ( ', ' ) ' ],
                { %{$sf->{i}{lyt_h}}, info => $info, prompt => 'Operator:', undef => '<=' }
            );
            if ( ! defined $operator ) {
                next CHOICE;
            }
            push @bu, [ @$items ];
            $operator =~ s/^\s+|\s+\z//g;
            push @$items, $operator;
        }
        elsif ( $menu->[$idx] eq $num ) {
            my $number = $tr->readline(
                'Number: ',
                { info => $info }
            );
            if ( ! length $number ) {
                next CHOICE;
            }
            push @bu, [ @$items ];
            push @$items, $number;
        }
        else {
            push @bu, [ @$items ];
            if ( $sql->{aggregate_mode} && $clause =~ /^(?:select|having|order_by)\z/ ) {
                my $sa = App::DBBrowser::Table::Substatement::Aggregate->new( $sf->{i}, $sf->{o}, $sf->{d} );
                my $prep_aggr = $sa->get_prepared_aggr_func( $sql, $clause, $menu->[$idx], $r_data );
                if ( length $prep_aggr ) {
                    push @$items, $prep_aggr;
                }
            }
            else {
                push @$items, $menu->[$idx];
            }
        }
    }
}



1;
__END__
