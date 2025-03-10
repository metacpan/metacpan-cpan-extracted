package # hide from PAUSE
App::DBBrowser::From::Cte;

use warnings;
use strict;
use 5.014;

use List::MoreUtils qw( any );

use Term::Choose         qw();
use Term::Form::ReadLine qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::Subquery;

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
    my ( $new_cte, $reset_unused ) = ( '  New CTE', '  Reset' );
    my @pre = ( undef );
    my $old_idx = 0;

    CHOOSE_CTE: while ( 1 ) {
        my $ctes = [ @{$sf->{d}{cte_history}} ];
        my @avail_ctes = map { '- ' . $_->{name} } @$ctes;
        my $menu;
        if ( $sf->{d}{nested_subqueries} ) {
            $menu = [ @pre, @avail_ctes ];
            if ( ! @avail_ctes ) {
                $ax->print_error_message( 'No ctes available.' );
                return;
            }
        }
        else {
            $menu = [ @pre, @avail_ctes, $new_cte, $reset_unused ];
        }
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
            $sf->__prepare_and_add_cte( $sql, $ctes );
            $old_idx++;
        }
        elsif ( $menu->[$idx] eq $reset_unused ) {
            my $stmt_type = $sf->{d}{stmt_types}[0];
            my $bu_cte_history = [ @{$sf->{d}{cte_history}} ];
            $sf->{d}{cte_history} = [];
            my $stmt = $ax->get_stmt( $sql, $stmt_type, 'prepare' );
            $sf->{d}{cte_history} = $bu_cte_history;
            if ( $stmt_type eq 'Join' ) {
                $stmt = "SELECT * FROM " . $stmt;
            }
            $sf->__reset_unused_ctes( $sql, $ctes, $stmt );
        }
        else {
            $idx -= @pre;
            my $cte_name = $ctes->[$idx]{name};
            return $cte_name;
        }
    }
}


sub __prepare_and_add_cte {
    my ( $sf, $sql, $ctes ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $sq = App::DBBrowser::Subquery->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );

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
                    my $type = ( grep { $_ eq $cte_name } @table_keys ) ? 'table' : 'cte';
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


sub __reset_unused_ctes {
    my ( $sf, $sql, $ctes, $stmt ) = @_;
    my $all_tables_used_in_stmts = $sf->__table_names_in_query( $stmt );

    CTE: for my $cte ( reverse @$ctes ) {
        if ( any { $_ eq $cte->{name} } @$all_tables_used_in_stmts ) {
            my $tables_in_cte = $sf->__table_names_in_query( $cte->{query} );
            push @$all_tables_used_in_stmts, @$tables_in_cte;
            $cte->{keep} = 1;
        }
    }
    $ctes = [ grep { delete $_->{keep} } @$ctes ];
    $sf->{d}{cte_history} = [ @$ctes ];
}


sub __table_names_in_query {
    my ( $sf, $stmt ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $rx_quoted_literal = $ax->regex_quoted_literal();
    my $rx_quoted_identifier = $ax->regex_quoted_identifier();
    my $rx_sql_elem = qr/ (?: $rx_quoted_identifier | [^',\s]+ ) /x;
    $rx_sql_elem = qr/ $rx_sql_elem (?: \. $rx_sql_elem ){0,2} /x;
    my $rx_split_stmt = qr/ ( $rx_quoted_literal | $rx_sql_elem | \s*,\s* ) \s+ /x;
    my $tables = [];
    my $implicit_join;
    my @token = grep { length } split $rx_split_stmt, $stmt;

    while ( @token ) {
        my $t = shift @token;
        if( $t =~ /^JOIN\z/i ) {
            if ( @token ) {
                push @$tables, shift @token;
            }
        }
        elsif ( $t =~ /^FROM\z/i || $implicit_join ) {
            if ( @token ) {
                push @$tables, shift @token;
            }
            if ( defined $token[1] && $token[1] eq ',' ) {
                shift @token;
            }
            elsif ( defined $token[2] && $token[2] eq ',' && $token[0] =~ /^AS\z/i ) {
                shift @token;
                shift @token;
            }
            $implicit_join = defined $token[0] && $token[0] eq ',' ? 1 : 0;
        }
    }
    return $tables;
}



1;


__END__
