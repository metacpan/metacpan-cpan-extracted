package # hide from PAUSE
App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments;

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


sub get_arguments {
    my ( $sf, $sql, $clause, $func, $args_data, $r_data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $info = $ax->get_sql_info( $sql );
    my @args;

    for my $arg_data ( @$args_data ) {
        my $tmp_info = $info . $ext->nested_func_info( $r_data );
        # Readline
        my $arg = $ext->argument(
            $sql, $clause, $r_data,
            { info => $tmp_info, history => $arg_data->{history}, prompt => $arg_data->{prompt},
              is_numeric => $arg_data->{is_numeric} }
        );
        #last if ! defined $arg; ##
        if ( ! length $arg || $arg eq "''" ) {
            if ( $arg_data->{empty_ok} ) {
                return @args if ! defined $arg;
                $arg = "''";
            }
            elsif ( $arg_data->{skip_ok} ) {
                next;
            }
            else {
                return @args;
            }
        }
        if ( $arg_data->{unquote} ) {
            $arg = $ax->unquote_constant( $arg );
        }
        if ( $arg_data->{history_only} ) {
            die "'history_only' without 'history!'" if ! @{$arg_data->{history}//[]};
            my $rx_history = join '|', @{$arg_data->{history}};
            if ( $arg !~ /^(?:$rx_history)\z/i ) {
                my $message = ( $arg_data->{prompt} // 'Valid:') . $ax->format_list( $arg_data->{history} );
                $ax->print_error_message( $message, $tmp_info );
                redo;
            }
        }
        push @args, $arg;
        push @{$r_data->[-1]}, $arg;
    }
    return @args;
}


sub choose_columns {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $const = '[value]';
    my @pre = ( undef, $sf->{i}{ok}, $sf->{i}{menu_addition}, $const );
    my $menu = [ @pre, @$cols ];
    my $subset = [];
    my $info = $ax->get_sql_info( $sql );
    my @bu;
    my @bu_args_sofar = @{$r_data->[-1]};

    COLUMNS: while ( 1 ) {
        $r_data->[-1] = [ @bu_args_sofar, @$subset ];
        my $tmp_info = $info . $ext->nested_func_info( $r_data );
        # Choose
        my @idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_h}}, info => $tmp_info, prompt => 'Columns:', meta_items => [ 0 .. $#pre - 1 ], ##
              no_spacebar => [ $#pre ], include_highlighted => 2, index => 1 }
        );
        if ( ! $idx[0] ) {
            if ( @bu ) {
                $subset = pop @bu;
                next COLUMNS;
            }
            return;
        }
        if ( $menu->[$idx[0]] eq $sf->{i}{ok} ) {
            shift @idx;
            $sf->__add_chosen_cols_to_subset( $sql, $clause, $subset, [ @{$menu}[@idx] ], $r_data );
            $r_data->[-1] = [ @bu_args_sofar, @$subset ];
            if ( ! @$subset ) {
                return;
            }
            return $subset;
        }
        elsif ( $menu->[$idx[0]] eq $sf->{i}{menu_addition} ) {
            # recursion
            my $complex_col = $ext->column( $sql, $clause, $r_data );
            if ( ! defined $complex_col ) {
                next COLUMNS;
            }
            push @bu, [ @$subset ];
            push @$subset, $complex_col;
        }
        elsif ( $menu->[$idx[0]] eq $const ) {
            my $history;
            if ( $func eq 'CONCAT' ) { ##
                $history = [ '%', '_', '*', '?', '|' ];
            }
            my $value = $tr->readline(
                'Value: ',
                { info => $tmp_info, history => $history }
            );
            if ( ! defined $value ) {
                next COLUMNS;
            }
            push @bu, [ @$subset ];
            push @$subset, $ax->quote_if_not_numeric( $value );
        }
        else {
            push @bu, [ @$subset ];
            $sf->__add_chosen_cols_to_subset( $sql, $clause, $subset, [ @{$menu}[@idx] ], $r_data );
        }
    }
}


sub __add_chosen_cols_to_subset {
    my ( $sf, $sql, $clause, $subset, $chosen_cols, $r_data ) = @_;
    if ( $sql->{aggregate_mode} && $clause =~ /^(?:select|having|order_by)\z/ ) {
        my $sa = App::DBBrowser::Table::Substatement::Aggregate->new( $sf->{i}, $sf->{o}, $sf->{d} );
        for my $aggr ( @$chosen_cols ) {
            my $prep_aggr = $sa->get_prepared_aggr_func( $sql, $clause, $aggr, $r_data );
            if ( ! length $prep_aggr ) {
                next;
            }
            push @$subset, $prep_aggr;
            push @{$r_data->[-1]}, $prep_aggr;
        }
    }
    else {
        push @$subset, @$chosen_cols;
    }
}


sub choose_a_column {
    my ( $sf, $sql, $clause, $cols, $r_data, $prompt ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    $prompt //= 'Column:';
    my $info = $ax->get_sql_info( $sql ) . $ext->nested_func_info( $r_data );
    my @pre = ( undef, $sf->{i}{menu_addition} );

    while ( 1 ) {
        # Choose
        my $col = $tc->choose(
            [ @pre, @$cols ],
            { %{$sf->{i}{lyt_h}}, info => $info, prompt => $prompt }
        );
        if ( ! defined $col ) {
            return;
        }
        my $chosen_col;
        if ( $col eq $sf->{i}{menu_addition} ) {
            # recursion
            my $complex_col = $ext->column( $sql, $clause, $r_data );
            if ( ! defined $complex_col ) {
                next;
            }
            $chosen_col = $complex_col;
        }
        elsif ( $sql->{aggregate_mode} && $clause =~ /^(?:select|having|order_by)\z/ ) {
            my $sa = App::DBBrowser::Table::Substatement::Aggregate->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $prep_aggr = $sa->get_prepared_aggr_func( $sql, $clause, $col, $r_data );
            if ( ! length $prep_aggr ) {
                next;
            }
            $chosen_col = $prep_aggr;
        }
        else {
            $chosen_col = $col;
        }
        push @{$r_data->[-1]}, $chosen_col;
        return $chosen_col;
    }
}


sub sqlite_modifiers {
    my ( $sf, $sql, $r_data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $history = [
        'n days',
        'n hours',
        'n minutes',
        'n seconds',
        'n months',
        'n years',
        '[+-]YYYY-MM-DD HH:MM:SS.SSS',
        'ceiling',
        'floor',
        'start of month',
        'start of year',
        'start of day',
        'weekday n',
        'unixepoch',
        'julianday',
        'auto',
        'localtime',
        'utc',
        'subsec',
    ];
    my @modifiers;
    my ( $ok, $add_modifier ) = ( '-OK-', 'Add modifier' );
    my @args_sofar = @{$r_data->[-1]};

    while ( 1 ) {
        $r_data->[-1] = [ @args_sofar, @modifiers ];
        my $info = $ax->get_sql_info( $sql ) . $ext->nested_func_info( $r_data );
        # Choose
        my $choice = $tc->choose(
            [ undef, $ok, $add_modifier ],
            { %{$sf->{i}{lyt_h}}, info => $info }
        );
        if ( ! defined $choice ) {
            if ( @modifiers ) {
                pop @modifiers;
                next;
            }
            $r_data->[-1] = [ @args_sofar ];
            return;
        }
        if ( $choice eq $ok ) {
            $r_data->[-1] = [ @args_sofar, @modifiers ];
            return join ',', @modifiers;
        }
        else {
            my $modifier = $tr->readline(
                'Modifier: ',
                { info => $info, history => $history }
            );
            $ax->print_sql_info( $info );
            if ( ! length $modifier ) {
                next;
            }
            push @modifiers, "'$modifier'";
        }
    }
}

1;

__END__
