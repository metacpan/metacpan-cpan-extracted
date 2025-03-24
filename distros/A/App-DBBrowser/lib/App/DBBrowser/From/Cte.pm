package # hide from PAUSE
App::DBBrowser::From::Cte;

use warnings;
use strict;
use 5.014;

use List::MoreUtils qw( any );

use Term::Choose         qw();
use Term::Form::ReadLine qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::From::Subquery;

sub new {
    my ( $class, $info, $options, $d ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $d
    };
    bless $sf, $class;
}


sub cte_as_main_table {
    my ( $sf ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $sf->{d}{stmt_types} = [ 'Select' ];
    my $sql = {};
    $ax->reset_sql( $sql );
    $ax->print_sql_info( $ax->get_sql_info( $sql ) ); ##
    my $cte = $sf->cte( $sql );
    if ( ! defined $cte ) {
        return;
    }
    return $cte;
}


sub cte {
    my ( $sf, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my ( $new_cte, $remove_ctes ) = ( '  New CTE', '  Remove CTEs' );
    my $old_idx = 0;

    CHOOSE_CTE: while ( 1 ) {
        my @avail_ctes = map { '- ' . $_->{name} } @{$sf->{d}{cte_history}} ;
        my @pre;
        if ( $sf->{d}{nested_subqueries} ) {
            @pre = ( undef );
            if ( ! @avail_ctes ) {
                $ax->print_error_message( 'No ctes available.' );
                return;
            }
        }
        else {
            @pre = ( undef, $new_cte, $remove_ctes );
        }
        my $menu = [ @pre, @avail_ctes ];
        my $info = $ax->get_sql_info( $sql );
        # Choose
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, index => 1, undef => '  <=', default => $old_idx }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $idx || $idx == 0 ) {
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx = 0;
                next CHOOSE_CTE;
            }
            $old_idx = $idx;
        }
        if ( $menu->[$idx] eq $new_cte ) {
            $sf->__prepare_and_add_cte( $sql );
        }
        elsif ( $menu->[$idx] eq $remove_ctes ) {
            $sf->__remove_ctes( $sql );
        }
        else {
            $idx -= @pre;
            my $cte_name = $sf->{d}{cte_history}[$idx]{name};
            return $cte_name;
        }
    }
}


sub __prepare_and_add_cte {
    my ( $sf, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $sq = App::DBBrowser::From::Subquery->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    my $ctes = [ @{$sf->{d}{cte_history}} ];

    CHOOSE_QUERY: while ( 1 ) {
        my $selected_stmt = $sq->__choose_query( $sql, 'cte' );
        if ( ! defined $selected_stmt ) {
            return;
        }
        my $count_query_loop;

        QUERY: while ( 1 ) {
            my $info = $ax->get_sql_info( $sql ); ##
            # Readline
            my $query = $tr->readline(
                'Stmt: ',
                { default => $selected_stmt, show_context => 1, info => $info }
            );
            $ax->print_sql_info( $info );
            if ( ! length $query ) {
                next CHOOSE_QUERY;
            }
            $info .= "\n". 'Stmt: ' . $query;
            my $default_name;

            NAME: while ( 1 ) {
                # Readline
                my $full_cte_name = $tr->readline(
                    'Name: ',
                    { default => $default_name, show_context => 1, info => $info, history => [ 'cte1' .. 'cte9' ] }
                );
                $ax->print_sql_info( $info );
                if ( ! length $full_cte_name ) {
                    next CHOOSE_QUERY if ++$count_query_loop > 1;
                    next QUERY;
                }
                my $rx_quoted_identifier = $ax->regex_quoted_identifier();
                my $cte_name = $full_cte_name =~ s/^ \s* (?:RECURSIVE\s+)? ( $rx_quoted_identifier | [^\s(]+ ) \s* (?:\(.+)? \z/$1/rix;
                my $cte = {
                    full_name => $full_cte_name,
                    query => $query,
                    name => $cte_name,
                };
                $default_name = length $default_name ? '' : $full_cte_name;
                my @table_keys = keys %{$sf->{d}{tables_info}};
                my @cte_names = map { $_->{name} } @$ctes;
                if ( any { $_ eq $cte_name } @table_keys, @cte_names ) {
                    my $type = ( grep { $_ eq $cte_name } @table_keys ) ? 'table' : 'CTE';
                    my $prompt = "A $type '$cte_name' already exists.";
                    # Choose
                    $tc->choose(
                        [ 'Press ENTER' ],
                        { %{$sf->{i}{lyt_h}}, info => $info, prompt => $prompt }
                    );
                    $ax->print_sql_info( $info );
                    next NAME;
                }
                else {
                    if ( $cte->{full_name} =~ s/^\s*RECURSIVE\s+//i ) {
                        $cte->{is_recursive} = 1;
                    }
                    push @$ctes, $cte;
                    $sf->{d}{cte_history} = [ @$ctes ];
                    unshift @{$sf->{d}{subquery_history}}, $query;
                    return 1;
                }
            }
        }
    }
}


sub __remove_ctes {
    my ( $sf, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $confirm = $sf->{i}{_confirm};
    my $all = '  All CTEs';
    my $ctes = [ @{$sf->{d}{cte_history}} ];
    my @bu;

    REMOVE_CTE: while ( 1 ) {
        $sf->{d}{cte_history} = [ @$ctes ];
        my @pre = ( undef, $confirm );
        my $menu = [ @pre, map( '- ' . $_->{name}, @$ctes ) ];
        push @$menu, $all;
        my $info = $ax->get_sql_info( $sql );
        # Choose
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => 'Remove CTE:', index => 1, undef => $sf->{i}{_back} }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $idx || $idx == 0 ) {
            if ( @bu ) {
                $ctes = pop @bu;
                next REMOVE_CTE;
            }
            return;
        }
        push @bu, [ @$ctes ];
        if ( $menu->[$idx] eq $confirm ) {
            $sf->{d}{cte_history} = [ @$ctes ];
            return 1;
        }
        elsif ( $menu->[$idx] eq $all ) {
            $ctes = [];
        }
        else {
            $idx -= @pre;
            splice( @$ctes, $idx, 1 );
        }
    }
}



1;

__END__
