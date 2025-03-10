package # hide from PAUSE
App::DBBrowser::Subquery;

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

my $pf_saved_subqueries = '- ';
my $pf_subquery_history = '  ';
my $pf_print_history    = '| ';


sub new {
    my ( $class, $info, $options, $d ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $d
    };
    bless $sf, $class;
}


sub subquery_as_main_table {
    my ( $sf ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $sf->{d}{stmt_types} = [ 'Select' ];
    #my $sql = { table => '()' };
    my $sql = {}; ##
    $ax->reset_sql( $sql );
    $ax->print_sql_info( $ax->get_sql_info( $sql ) ); ##
    my $subquery = $sf->subquery( $sql );
    if ( ! defined $subquery ) {
        return;
    }
    # Oracle: key word "AS" not supported in Table aliases
    my $alias = $ax->table_alias( $sql, 'derived_table', $subquery );
    if ( length $alias ) {
        $subquery .= " " . $alias;
    }
    return $subquery;
}


sub subquery {
    my ( $sf, $sql, $ext_info ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );

    CHOOSE_QUERY: while ( 1 ) {
        $sf->{from_build_SQ} = 0;
        my $selected_stmt = $sf->__choose_query( $sql, 'subquery', $ext_info );
        if ( ! defined $selected_stmt ) {
            return;
        }
        if ( $sf->{from_build_SQ} && ! $sf->{o}{G}{edit_sql_menu_sq} ) {
            $sf->{from_build_SQ} = 0;
            return "($selected_stmt)";
        }
        my $prompt = 'Query: ';
        my $info = $ext_info || $ax->get_sql_info( $sql );
        # Readline
        my $stmt = $tr->readline(
            #'Query: ',
            $prompt,
            { default => $selected_stmt, show_context => 1, info => $info }
        );
        $ax->print_sql_info( $info );
        if ( ! length $stmt ) {
            next CHOOSE_QUERY;
        }
        unshift @{$sf->{d}{subquery_history}}, $stmt;
        if ( $stmt =~ /^\s*(?:SELECT|WITH)\s/i ) {
            # A statement entered with readline could have a WITH clause.
            return "($stmt)";
        }
        else {
            return $stmt;
        }
    }
}


sub __choose_query {
    my ( $sf, $sql, $caller, $ext_info ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my ( $saved_subqueries, $subquery_history, $print_history ) = $sf->__get_history();
    my $edit_sq_history_file = 'Choose:';
    my ( $readline, $build_SQ ) = ( 'Readline', 'SQL Menu' );
    my @pre = ( $edit_sq_history_file, undef, $build_SQ, $readline );
    my $old_idx = 1;

    SUBQUERY: while ( 1 ) {
        my @queries = $sf->__get_queries( $saved_subqueries, $subquery_history, $print_history );
        my $menu = [ @pre, @queries ];
        my $info = $ext_info || $ax->get_sql_info( $sql );
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
        my $selected_stmt;
        if ( $menu->[$idx] eq $edit_sq_history_file ) {
            if ( $sf->__edit_sq_history_file() ) {
                ( $saved_subqueries, $subquery_history, $print_history ) = $sf->__get_history();
                @queries = $sf->__get_queries( $saved_subqueries, $subquery_history, $print_history );
                $menu = [ @pre, @queries ];
            }
            next SUBQUERY;
        }
        elsif ( $menu->[$idx] eq $readline ) {
            $selected_stmt = '';
        }
        elsif ( $menu->[$idx] eq $build_SQ ) {
            # Don't backup $sf->{d}{default_table_alias_count}
            my $bu_stmt_types = [ @{$sf->{d}{stmt_types}} ];
            my $bu_table_origin = $sf->{d}{table_origin};
            my $bu_main_info = $sf->{d}{main_info};
            $sf->{d}{main_info} = $ext_info || $ax->get_sql_info( $sql );
            $sf->{d}{nested_subqueries}++;
            my $stmt = $sf->__build_SQ( $caller );
            $sf->{d}{nested_subqueries}--;
            $sf->{d}{stmt_types} = $bu_stmt_types;
            $sf->{d}{table_origin} = $bu_table_origin;
            $sf->{d}{main_info} = $bu_main_info;
            if ( ! defined $stmt ) {
                next SUBQUERY;
            }
            $sf->{from_build_SQ} = 1;
            $selected_stmt = $ax->normalize_space_in_stmt( $stmt );
        }
        else {
            $idx -= @pre;
            if ( $idx < @$saved_subqueries ) {
                $selected_stmt = $saved_subqueries->[$idx]{stmt};
            }
            else {
                $idx -= @$saved_subqueries;
                $selected_stmt = ( @$subquery_history, @$print_history )[$idx];
            }
        }
        return $selected_stmt;
    }
}


sub __session_history {
    my ( $sf ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    # Print history:
    my $print_history = [];

    for my $stmt ( @{$sf->{d}{table_print_history}} ) {
        $stmt = $ax->normalize_space_in_stmt( $stmt );
        $stmt =~ s/^ WITH \s .+ \) \s ( SELECT \s .+ ) \z/$1/ix;
        if ( $stmt =~ /^ SELECT \s \* \s FROM \s \(( SELECT \s .+ ) \) \s \S+ \z/ix ) {
            # union stmt
            $stmt = $1;
        }
        if ( any { $_ eq $stmt } @$print_history ) {
            next;
        }
        push @$print_history, $stmt;
        if ( @$print_history == 7 ) {
            $sf->{d}{table_print_history} = [ @$print_history ];
            last;
        }
    }
    # Subquery history:
    # Subqueries in `$sf->{d}{subquery_history}` to survive the end of Subqueries.pm in a controlled way.
    my $subquery_history = $sf->{d}{subquery_history};
    my $tmp_subquery_history = [];

    for my $subquery ( @$subquery_history ) {
        if ( any { $_ eq $subquery } @$tmp_subquery_history, @$print_history ) {
            next;
        }
        push @$tmp_subquery_history, $subquery;
        if ( @$tmp_subquery_history == 5 ) {
            last;
        }
    }
    $subquery_history = $tmp_subquery_history;
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


sub __get_queries {
    my ( $sf, $saved_subqueries, $subquery_history, $print_history ) = @_;
    my @queries;
    push @queries, map { $pf_saved_subqueries . $_->{name} } @$saved_subqueries;
    push @queries, map { $pf_subquery_history . $_         } @$subquery_history;
    push @queries, map { $pf_print_history    . $_         } @$print_history;
    return @queries;
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
    my $readline = '  Read-Line'; ##
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
                { init_tab => $pf_saved_subqueries, subseq_tab => '    ', join => 1 }
            ), @$added_sq ); #
        }
        push @tmp_info, ' ';
        my $menu = [ @pre ];
        push @$menu, map { $pf_subquery_history . $_ } @$subquery_history;
        push @$menu, map { $pf_print_history    . $_ } @$print_history;
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
            my $default = $menu->[$idx] eq $readline ? undef : ( @$subquery_history, @$print_history )[$idx-@pre];
            my $info = join( "\n", @tmp_info );
            # Readline
            my $stmt = $tr->readline(
                'Stmt: ',
                { info => $info, show_context => 1, clear_screen => 1, default => $default, history => [] }
            );
            $ax->print_sql_info( $info );
            if ( ! length $stmt ) {
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
            if ( ! defined $name ) { ##
                next;
            }
            push @bu, [ @$added_sq ];
            push @$added_sq, { stmt => $stmt, name => length $name ? $name : $stmt }; ##
        }
    }
}


sub __edit_subqueries {
    my ( $sf, $saved_subqueries ) = @_;
    if ( ! @$saved_subqueries ) {
        return;
    }
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @pre = ( undef );
    my $info = $sf->{d}{db_string};
    my $prompt = 'Edit Subquery:';
    my $menu = [ @pre, map { $pf_saved_subqueries . $_->{name} } @$saved_subqueries ];
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
    if ( ! length $stmt ) {
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
    if ( ! defined $name ) { ##
        return;
    }
    if ( $stmt ne $saved_subqueries->[$idx]{stmt} || $name ne $saved_subqueries->[$idx]{name} ) {
        $saved_subqueries->[$idx] = { stmt => $stmt, name => length $name ? $name : $stmt }; ##
        return 1;
    }
    return;
}


sub __remove_subqueries {
    my ( $sf, $saved_subqueries ) = @_;
    if ( ! @$saved_subqueries ) {
        return;
    }
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $old_idx = 0;

    REMOVE: while ( 1 ) {
        my $info = $sf->{d}{db_string};
        my $prompt = 'Remove subquery:';
        my @pre = ( undef );
        my $menu = [ @pre, map { $pf_saved_subqueries . $_->{name} } @$saved_subqueries ];
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
        my @tmp_prompt = ( '' );
        push @tmp_prompt, line_fold(
            'Name: ' . $saved_subqueries->[$idx]{name}, get_term_width(),
            { init_tab => '', subseq_tab => ' ' x length( 'Name: ' ), join => 0 }
        );
        push @tmp_prompt, line_fold(
            'Stmt: ' . $saved_subqueries->[$idx]{stmt}, get_term_width(),
            { init_tab => '', subseq_tab => ' ' x length( 'Stmt: ' ), join => 0 }
        );
        push @tmp_prompt, '', $prompt;
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


sub __build_SQ {
    my ( $sf, $caller ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $user_table_keys  = $sf->{d}{user_table_keys};
    my $sys_table_keys   = $sf->{d}{sys_table_keys};
    my $pf = '- ';
    my $old_idx_tbl = 0;

    TABLE: while ( 1 ) {
        my ( $from_join, $from_union, $from_subquery, $from_cte ) = ( '  Join', '  Union', '  Subquery', '  Cte' ); ##
        my $table_key;
        my @pre = ( undef );
        my $menu_table;
        if ( $sf->{o}{G}{metadata} ) {
            my $sys_prefix = $sf->{d}{is_system_schema} ? $pf : '  ';
            $menu_table = [ @pre, map( $pf . $_, @$user_table_keys ), map( $sys_prefix . $_, @$sys_table_keys ) ];
        }
        else {
            $menu_table = [ @pre, map( $pf . $_, @$user_table_keys ) ];
        }
        push @$menu_table, $from_subquery if $sf->{o}{enable}{m_derived};
        push @$menu_table, $from_cte      if $sf->{o}{enable}{m_cte};
        push @$menu_table, $from_join     if $sf->{o}{enable}{join};
        push @$menu_table, $from_union    if $sf->{o}{enable}{union};
        my $info = $sf->{d}{main_info};
        my $prompt = 'Build the ' . ( $caller eq 'cte' ? 'CTE statement:' : 'subquery:' );
        # Choose
        my $idx_tbl = $tc->choose(
            $menu_table,
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => $prompt, index => 1, default => $old_idx_tbl, undef => '<=' }
        );
        if ( defined $idx_tbl ) {
            $table_key = $menu_table->[$idx_tbl];
        }
        if ( ! defined $table_key ) {
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx_tbl == $idx_tbl && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx_tbl = 0;
                next TABLE;
            }
            $old_idx_tbl = $idx_tbl;
        }
        require App::DBBrowser::From; ##
        my $fr = App::DBBrowser::From->new( $sf->{i}, $sf->{o}, $sf->{d} );
        my $sql = $fr->from_sql( $table_key =~ s/[-\ ]\ //r );
        if ( ! defined $sql ) {
            next TABLE;
        }
        $ax->print_sql_info( $ax->get_sql_info( $sql ) ); ##
        require App::DBBrowser::Table; ##
        my $tbl = App::DBBrowser::Table->new( $sf->{i}, $sf->{o}, $sf->{d} );
        my $statement = $tbl->browse_the_table( $sql, 1 );
        if ( ! defined $statement ) {
            next TABLE;
        }
        return $statement;
    }
}


1;


__END__
