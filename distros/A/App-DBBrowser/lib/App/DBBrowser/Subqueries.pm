package # hide from PAUSE
App::DBBrowser::Subqueries;

use warnings;
use strict;
use 5.014;

use File::Spec::Functions qw( catfile );

use List::MoreUtils qw( any );

use Term::Choose           qw();
use Term::Choose::LineFold qw( line_fold );
use Term::Choose::Util     qw( get_term_width );
use Term::Form::ReadLine   qw();

use App::DBBrowser::Auxil;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $d
    };
    bless $sf, $class;
}


sub __session_history {
    my ( $sf ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    # Subquery history:
    # Subqueries in `$sf->{d}{subquery_history}` to survive the end of Subqueries.pm in a controlled way.
    my $subquery_history = $sf->{d}{subquery_history};
    my $tmp_subquery_history = [];
    for my $subquery ( @$subquery_history ) {
        if ( any { $_->{stmt} eq $subquery->{stmt} } @$tmp_subquery_history ) {
            next;
        }
        push @$tmp_subquery_history, $subquery;
        if ( @$tmp_subquery_history == 10 ) {
            last;
        }
    }
    $subquery_history = $tmp_subquery_history;
    # Print history:
    my $tmp_table_print_history = [];
    my $print_history = [];
    for my $stmt ( @{$sf->{d}{table_print_history}} ) {
        $stmt =~ s/\s*\n\s*/ /g;
        if ( any { $_->{stmt} eq $stmt } @$subquery_history, @$print_history ) {
            next;
        }
        push @$tmp_table_print_history, $stmt;
        push @$print_history, { stmt => $stmt, name => $stmt };
        if ( @$tmp_table_print_history == 7 ) {
            $sf->{d}{table_print_history} = $tmp_table_print_history;
            last;
        }
    }
    return( $subquery_history, $print_history );
}


sub __get_history {
    my ( $sf ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $h_ref = $ax->read_json( $sf->{i}{f_subqueries} ) // {};
    my $saved_subqueries = $h_ref->{ $sf->{i}{driver} }{ $sf->{d}{db} } // [];
    my ( $subquery_history, $print_history ) = $sf->__session_history();
    return $saved_subqueries, $subquery_history, $print_history;
}


sub choose_subquery {
    my ( $sf, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my ( $saved_subqueries, $subquery_history, $print_history ) = $sf->__get_history();
    my $edit_sq_history_file = 'Choose SQ:';
    my $readline = 'Read-Line';
    my @pre = ( $edit_sq_history_file, undef, $readline );
    my $old_idx = 1;

    SUBQUERY: while ( 1 ) {
        my @queries;
        push @queries, map {  '- ' . $_->{name} } @$saved_subqueries;
        push @queries, map {  '  ' . $_->{name} } @$subquery_history;
        push @queries, map {  '| ' . $_->{name} } @$print_history;
        my $menu = [ @pre, @queries ];
        my $info = $ax->get_sql_info( $sql );
        # Choose
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => '', index => 1, default => $old_idx, undef => '<=' }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $idx || ! defined $menu->[$idx] ) {
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx = 1;
                next SUBQUERY;
            }
            $old_idx = $idx;
        }
        my ( $prompt, $history, $chosen_stmt );
        if ( $menu->[$idx] eq $edit_sq_history_file ) {
            if ( $sf->__edit_sq_history_file() ) {
                ( $saved_subqueries, $subquery_history, $print_history ) = $sf->__get_history();
                @queries = ();
                push @queries, map {  '- ' . $_->{name} } @$saved_subqueries;
                push @queries, map {  '  ' . $_->{name} } @$subquery_history;
                push @queries, map {  '| ' . $_->{name} } @$print_history;
                $menu = [ @pre, @queries ];
            }
            next SUBQUERY;
        }
        elsif ( $menu->[$idx] eq $readline ) {
            $prompt = 'Enter SQ: ';
            if ( @{$sql->{group_by_cols}} || @{$sql->{aggr_cols}} ) {
                $history = [  @{$sql->{group_by_cols}}, @{$sql->{aggr_cols}} ];
            }
            else {
                $history = [ @{$sql->{cols}} ];
            }
        }
        else {
            $prompt = 'Edit SQ: ';
            $idx -= @pre;
            $chosen_stmt = ( @$saved_subqueries, @$subquery_history, @$print_history )[$idx]{stmt};
        }
        $info = $ax->get_sql_info( $sql );
        my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
        # Readline
        my $stmt = $tr->readline(
            $prompt,
            { default => $chosen_stmt, show_context => 1, info => $info, history => $history }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $stmt || ! length $stmt ) {
            next SUBQUERY;
        }
        while ( $stmt =~ /^\s*\((.+)\)\s*\z/ ) {
            $stmt = $1;
        }
        unshift @{$sf->{d}{subquery_history}}, { stmt => $stmt, name => $stmt };
        if ( $stmt =~ /^\s*SELECT\s/i ) {
            return "(" . $stmt . ")";
        }
        else {
            return $stmt;
        }
    }
}


sub __edit_sq_history_file {
    my ( $sf ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $driver = $sf->{i}{driver};
    my $db = $sf->{d}{db};
    my @pre = ( undef );
    my ( $add, $edit, $remove ) = ( '- Add', '- Edit', '- Remove' );
    my $any_change = 0;
    my $old_idx = 0;

    STORED: while ( 1 ) {
        my $top_lines = [ $sf->{d}{db_string}, 'Stored Subqueries:' ];
        my $h_ref = $ax->read_json( $sf->{i}{f_subqueries} ) // {};
        my $saved_subqueries = $h_ref->{$driver}{$db} // [];
        my @tmp_info = (
            @$top_lines,
            map( line_fold(
                $_->{name}, get_term_width(),
                { init_tab => '  ', subseq_tab => '    ', join => 1 }
            ), @$saved_subqueries ), #
            ' '
        );
        my $info = join( "\n", @tmp_info );
        my $menu = [ @pre, $add, $edit, $remove ];
        # Choose
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, index => 1, undef => '  <=', default => $old_idx }
        );
        $ax->print_sql_info( $info );
        my $changed = 0;
        if ( ! $idx ) {
            return $any_change;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx = 0;
                next STORED;
            }
            $old_idx = $idx;
        }
        my $choice = $menu->[$idx];
        if ( $choice eq $add ) {
            $changed = $sf->__add_subqueries( $saved_subqueries, $top_lines );
        }
        elsif ( $choice eq $edit ) {
            $changed = $sf->__edit_subqueries( $saved_subqueries );
        }
        elsif ( $choice eq $remove ) {
            $changed = $sf->__remove_subqueries( $saved_subqueries );
        }
        if ( $changed ) {
            if ( @$saved_subqueries ) {
                $h_ref->{$driver}{$db} = $saved_subqueries;
            }
            else {
                delete $h_ref->{$driver}{$db};
            }
            $ax->write_json( $sf->{i}{f_subqueries}, $h_ref );
            $any_change++;
        }
    }
}


sub __add_subqueries {
    my ( $sf, $saved_subqueries, $top_lines ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my ( $subquery_history, $print_history ) = $sf->__session_history();
    my $used = [];
    my $readline = '  Read-Line';
    my @pre = ( undef, $sf->{i}{_confirm}, $readline );
    my @bu;
    my $added_sq = [];

    while ( 1 ) {
        my @tmp_info = (
            @$top_lines,
            map( line_fold(
                $_->{name}, get_term_width(),
                { init_tab => '  ', subseq_tab => '    ', join => 1 }
            ), @$saved_subqueries ), #
        );
        if ( @$added_sq ) {
            push @tmp_info, map( line_fold(
                $_->{name}, get_term_width(),
                { init_tab => '| ', subseq_tab => '    ', join => 1 }
            ), @$added_sq ); #
        }
        push @tmp_info, ' ';
        my $menu = [ @pre ];
        push @$menu, map {  '- ' . $_->{name} } @$subquery_history;
        push @$menu, map {  '  ' . $_->{name} } @$print_history;
        my $info = join( "\n", @tmp_info );
        # Choose
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, prompt => 'Add:', info => $info, index => 1 }
        );
        $ax->print_sql_info( $info );
        if ( ! $idx ) {
            if ( @bu ) {
                $added_sq = pop @bu;
                next;
            }
            return;
        }
        elsif ( $menu->[$idx] eq $sf->{i}{_confirm} ) {
            push @$saved_subqueries, @$added_sq;
            return 1;
        }
        else {
            my $default = $menu->[$idx] eq $readline ? undef : ( @$subquery_history, @$print_history )[$idx-@pre]{stmt};
            my $info = join( "\n", @tmp_info );
            # Readline
            my $stmt = $tr->readline(
                'Stmt: ',
                { info => $info, show_context => 1, clear_screen => 1, default => $default, history => [] }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $stmt || ! length $stmt ) {
                    next;
            }
            my $folded_stmt = "\n" . line_fold(
                'Stmt: ' . $stmt, get_term_width(),
                { init_tab => '', subseq_tab => ' ' x length( 'Stmt: ' ), join => 1 }
            );
            $info = join( "\n", @tmp_info ) . $folded_stmt;
            # Readline
            my $name = $tr->readline(
                'Name: ',
                { info => $info, show_context => 1, history => [] }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $name ) {
                next;
            }
            push @bu, [ @$added_sq ];
            push @$added_sq, { stmt => $stmt, name => length $name ? $name : $stmt };
        }
    }
}


sub __edit_subqueries {
    my ( $sf, $saved_subqueries ) = @_;
    if ( ! @$saved_subqueries ) {
        return;
    }
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $indexes = [];
    my @pre = ( undef );
    my $info = $sf->{d}{db_string};
    my $prompt = 'Edit Subquery:';
    my $menu = [ @pre, map { '- ' . $_->{name} } @$saved_subqueries ];
    # Choose
    my $idx = $tc->choose(
        $menu,
        { %{$sf->{i}{lyt_v}}, info => $info, prompt => $prompt, index => 1, undef => '  <=' }
    );
    if ( ! $idx ) {
        return;
    }
    $idx -= @pre;
    my @tmp_info = ( $info, $prompt, '' );
    $info = join( "\n", @tmp_info );
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    # Readline
    my $stmt = $tr->readline(
        'Stmt: ',
        { info => $info, default => $saved_subqueries->[$idx]{stmt}, show_context => 1, clear_screen => 1,
          history => [] }
    );
    if ( ! defined $stmt || ! length $stmt ) {
        return;
    }
    my $folded_stmt = "\n" . line_fold(
        'Stmt: ' . $stmt, get_term_width(),
        { init_tab => '', subseq_tab => ' ' x length( 'Stmt: ' ), join => 1 }
    );
    $info .= $folded_stmt;
    my $default_name;
    if ( $saved_subqueries->[$idx]{stmt} ne $saved_subqueries->[$idx]{name} ) {
        $default_name = $saved_subqueries->[$idx]{name};
    }
    # Readline
    my $name = $tr->readline(
        'Name: ',
        { info => $info, default => $default_name, show_context => 1, history => [] }
    );
    if ( ! defined $name ) {
        return;
    }
    if ( $stmt ne $saved_subqueries->[$idx]{stmt} || $name ne $saved_subqueries->[$idx]{name} ) {
        $saved_subqueries->[$idx] = { stmt => $stmt, name => length $name ? $name : $stmt };
        return 1;
    }
    return;
}


sub __remove_subqueries {
    my ( $sf, $saved_subqueries, $top_lines ) = @_;
    if ( ! @$saved_subqueries ) {
        return;
    }
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @indexes;
    my @to_remove;
    my $old_idx = 0;

    REMOVE: while ( 1 ) {
        my $info = $sf->{d}{db_string};
        my $prompt = 'Remove subquery:';
        my @pre = ( undef );
        my $menu = [ @pre, map { '- ' . $_->{name} } @$saved_subqueries ];
        my $idx = $tc->choose(
            $menu,
            { info => $info, prompt => $prompt, undef => '  <=', layout => 2, index => 1, default => $old_idx  }
        );
        if ( ! $idx ) {
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx = 0;
                next REMOVE;
            }
            $old_idx = $idx;
        }
       $idx -= @pre;
        my @tmp_prompt = ( $prompt, '' );
        push @tmp_prompt, line_fold(
            'Name: ' . $saved_subqueries->[$idx]{name}, get_term_width(),
            { init_tab => '', subseq_tab => ' ' x length( 'Name: ' ), join => 0 }
        );
        push @tmp_prompt, line_fold(
            'Stmt: ' . $saved_subqueries->[$idx]{stmt}, get_term_width(),
            { init_tab => '', subseq_tab => ' ' x length( 'Stmt: ' ), join => 0 }
        );
        my $ok = $tc->choose(
            [ undef, 'YES' ],
            { info => $info, prompt => join( "\n", @tmp_prompt ), undef => 'NO' }
        );
        if ( ! defined $ok ) {
            next REMOVE;
        }
        else {
            splice @$saved_subqueries, $idx, 1;
            return 1;
        }
    }
}





1;


__END__
