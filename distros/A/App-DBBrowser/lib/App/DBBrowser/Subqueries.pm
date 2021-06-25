package # hide from PAUSE
App::DBBrowser::Subqueries;

use warnings;
use strict;
use 5.010001;

use File::Spec::Functions qw( catfile );

use List::MoreUtils qw( any uniq );

use Term::Choose           qw();
use Term::Choose::LineFold qw( line_fold );
use Term::Choose::Util     qw( get_term_width );
use Term::Form             qw();

use App::DBBrowser::Auxil;


sub new {
    my ( $class, $info, $options, $data ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $data,
    };
    bless $sf, $class;
}


sub __tmp_history {
    my ( $sf, $history_HD ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $db = $sf->{d}{db};
    my $keep = [];
    my @print_history;
    for my $ref ( @{$sf->{i}{history}{$db}{print}} ) {
        my $filled_stmt = $ax->stmt_placeholder_to_value( @$ref, 1 );
        if ( $filled_stmt =~ /^[^\(]+FROM\s*\(\s*([^)(]+)\s*\)[^\)]*\z/ ) { # Union, Join
            $filled_stmt = $1;
        }
        if ( any { $_ eq $filled_stmt } @print_history ) {
            next;
        }
        if ( @$keep == 7 ) {
            $sf->{i}{history}{$db}{print} = $keep;
            last;
        }
        push @$keep, $ref;
        push @print_history, $filled_stmt;
    }
    my @clause_history = uniq @{$sf->{i}{history}{$db}{substmt}};
    if ( @clause_history > 10 ) {
        $#clause_history = 9;
    }
    my $history_RAM = [];
    for my $tmp ( uniq( @clause_history, @print_history ) ) {
        if ( any { $tmp eq $_->[1] } @$history_HD ) {
            next;
        }
        push @$history_RAM, [ $tmp, $tmp ];
    }
    return $history_RAM;
}


sub __get_history {
    my ( $sf ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $h_ref = $ax->read_json( $sf->{i}{f_subqueries} ) // {};
    my $history_HD = $h_ref->{ $sf->{i}{driver} }{ $sf->{d}{db} }{substmt} // [];
    my $history_RAM = $sf->__tmp_history( $history_HD ) // [];
    return $history_HD, $history_RAM;
}


sub choose_subquery {
    my ( $sf, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my ( $history_HD, $history_RAM ) = $sf->__get_history();
    my $edit_sq_file = 'Choose SQ:';
    my $readline     = '  Read-Line';
    my @pre = ( $edit_sq_file, undef, $readline );
    my $old_idx = 1;

    SUBQUERY: while ( 1 ) {
        my $info = $ax->get_sql_info( $sql );
        my $menu = [ @pre, map( '- ' . $_->[1], @$history_HD ), map( '  ' . $_->[1], @$history_RAM ) ];
        # Choose
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => '', index => 1, default => $old_idx, undef => '  <=' }
        );
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
        if ( $menu->[$idx] eq $edit_sq_file ) {
            if ( $sf->__edit_sq_file() ) {
                ( $history_HD, $history_RAM ) = $sf->__get_history();
                $menu = [ @pre, map( '- ' . $_->[1], @$history_HD ), map( '  ' . $_->[1], @$history_RAM ) ];
            }
            $ax->print_sql_info( $sql );
            next SUBQUERY;
        }
        $info = $ax->get_sql_info( $sql );
        my ( $prompt, $default );
        if ( $menu->[$idx] eq $readline ) {
            $prompt = 'Enter SQ: ';
        }
        else {
            $prompt = 'Edit SQ: ';
            $idx -= @pre;
            $default = ( @$history_HD, @$history_RAM )[$idx][0];
        }
        my $tf = Term::Form->new( $sf->{i}{tf_default} );
        # Readline
        my $stmt = $tf->readline(
            $prompt,
            { default => $default, show_context => 1, info => $info }
        );
        if ( ! defined $stmt || ! length $stmt ) {
            $ax->print_sql_info( $sql );
            next SUBQUERY;
        }
        my $db = $sf->{d}{db};
        unshift @{$sf->{i}{history}{$db}{substmt}}, $stmt;
        if ( $stmt !~ /^\s*\([^)(]+\)\s*\z/ ) {
            $stmt = "(" . $stmt . ")";
        }
        return $stmt;
    }
}


sub __edit_sq_file {
    my ( $sf ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $driver = $sf->{i}{driver};
    my $db = $sf->{d}{db};
    my @pre = ( undef );
    my ( $add, $edit, $remove ) = ( '- Add', '- Edit', '- Remove' );
    my $any_change = 0;

    while ( 1 ) {
        my $top_lines = [ 'Stored Subqueries:' ];
        my $h_ref = $ax->read_json( $sf->{i}{f_subqueries} ) // {};
        my $history_HD = $h_ref->{$driver}{$db}{substmt} // [];
        my @info = (
            @$top_lines,
            map( line_fold( $_->[-1], get_term_width(), { init_tab => '  ', subseq_tab => '    ', join => 1 } ), @$history_HD ), #
            ' '
        );
        # Choose
        my $choice = $tc->choose(
            [ @pre, $add, $edit, $remove ],
            { %{$sf->{i}{lyt_v}}, info => join( "\n", @info ), undef => '  <=' }
        );
        my $changed = 0;
        if ( ! defined $choice ) {
            return $any_change;
        }
        elsif ( $choice eq $add ) {
            $changed = $sf->__add_subqueries( $history_HD, $top_lines );
        }
        elsif ( $choice eq $edit ) {
            $changed = $sf->__edit_subqueries( $history_HD, $top_lines );
        }
        elsif ( $choice eq $remove ) {
            $changed = $sf->__remove_subqueries( $history_HD, $top_lines );
        }
        if ( $changed ) {
            if ( @$history_HD ) {
                $h_ref->{$driver}{$db}{substmt} = $history_HD;
            }
            else {
                delete $h_ref->{$driver}{$db}{substmt};
            }
            $ax->write_json( $sf->{i}{f_subqueries}, $h_ref );
            $any_change++;
        }
    }
}


sub __add_subqueries {
    my ( $sf, $history_HD, $top_lines ) = @_;
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $history_RAM = $sf->__tmp_history( $history_HD );
    my $used = [];
    my $readline = '  Read-Line';
    my @pre = ( undef, $sf->{i}{_confirm}, $readline );
    my $bu = [];
    my $added_sq = [];

    while ( 1 ) {
        my @info = (
            @$top_lines,
            map( line_fold( $_->[1], get_term_width(), { init_tab => '  ', subseq_tab => '    ', join => 1 } ), @$history_HD ), #
        );
        if ( @$added_sq ) {
            push @info, map( line_fold( $_->[1], get_term_width(), { init_tab => '| ', subseq_tab => '    ', join => 1 } ), @$added_sq ); #
        }
        push @info, ' ';
        my $menu = [ @pre, map {  '- ' . $_->[1] } @$history_RAM ];
        # Choose
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, prompt => 'Add:', info => join( "\n", @info ), index => 1 }
        );
        if ( ! $idx ) {
            if ( @$bu ) {
                ( $added_sq, $history_RAM, $used ) = @{pop @$bu};
                next;
            }
            return;
        }
        elsif ( $menu->[$idx] eq $sf->{i}{_confirm} ) {
            push @$history_HD, @$added_sq;
            return 1;
        }
        elsif ( $menu->[$idx] eq $readline ) {
            # Readline
            my $stmt = $tf->readline(
                'Stmt: ',
                { info => join( "\n", @info ), show_context => 1, clear_screen => 1 }
            );
            if ( ! defined $stmt || ! length $stmt ) {
                    next;
            }
            if ( $stmt =~ /^\s*\(([^)(]+)\)\s*\z/ ) {
                $stmt = $1;
            }
            my $folded_stmt = "\n" . line_fold( 'Stmt: ' . $stmt, get_term_width(), { init_tab => '', subseq_tab => ' ' x length( 'Stmt: ' ), join => 1 } );
            # Readline
            my $name = $tf->readline(
                'Name: ',
                { info => join( "\n", @info ) . $folded_stmt, show_context => 1 }
            );
            if ( ! defined $name ) {
                next;
            }
            push @$bu, [ [ @$added_sq ], [ @$history_RAM ], [ @$used ] ];
            push @$added_sq, [ $stmt, length $name ? $name : $stmt ];

        }
        else {
            push @$bu, [ [ @$added_sq ], [ @$history_RAM ], [ @$used ] ];
            push @$used, splice @$history_RAM, $idx-@pre, 1;
            my $stmt = $used->[-1][0];
            my $folded_stmt = "\n" . line_fold( 'Stmt: ' . $stmt, get_term_width(), { init_tab => '', subseq_tab => ' ' x length( 'Stmt: ' ), join => 1 } );
            # Readline
            my $name = $tf->readline(
                'Name: ',
                { info => join( "\n", @info ) . $folded_stmt, show_context => 1 }
            );
            if ( ! defined $name ) {
                ( $added_sq, $history_RAM, $used ) = @{pop @$bu};
                next;
            }
            push @$added_sq, [ $stmt, length $name ? $name : $stmt ];
        }
    }
}


sub __edit_subqueries {
    my ( $sf, $history_HD, $top_lines ) = @_;
    if ( ! @$history_HD ) {
        return;
    }
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $indexes = [];
    my @pre = ( undef, $sf->{i}{_confirm} );
    my $bu = [];
    my $old_idx = 0;
    my @unchanged_saved_history = @$history_HD;

    STMT: while ( 1 ) {
        my $info = join "\n", @$top_lines;
        my @available;
        for my $i ( 0 .. $#$history_HD ) {
            my $pre = ( any { $i == $_ } @$indexes ) ? '| ' : '- ';
            push @available, $pre . $history_HD->[$i][1];
        }
        my $menu = [ @pre, @available ];
        # Choose
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, prompt => 'Edit:', info => $info, index => 1, default => $old_idx }
        );
        if ( ! $idx ) {
            if ( @$bu ) {
                ( $history_HD, $indexes ) = @{pop @$bu};
                next STMT;
            }
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx = 0;
                next STMT;
            }
            $old_idx = $idx;
        }
        if ( $menu->[$idx] eq $sf->{i}{_confirm} ) {
            return 1;
        }
        else {
            $idx -= @pre;
            my @tmp_info = ( @$top_lines, 'Edit:', $sf->{i}{_back}, $sf->{i}{_confirm} );
            for my $i ( 0 .. $#$history_HD ) {
                my $stmt = $history_HD->[$i][1];
                my $pre = '  ';
                if ( $i == $idx ) {
                    $pre = '> ';
                }
                elsif ( any { $i == $_ } @$indexes ) {
                    $pre = '| ';
                }
                my $folded_stmt = line_fold( $stmt, get_term_width(), { init_tab => $pre,  subseq_tab => $pre . ( ' ' x 2 ), join => 1 } );
                push @tmp_info, $folded_stmt;
            }
            push @tmp_info, ' ';
            my $info = join "\n", @tmp_info;
            my $tf = Term::Form->new( $sf->{i}{tf_default} );
            # Readline
            my $stmt = $tf->readline(
                'Stmt: ',
                { info => $info, default => $history_HD->[$idx][0], show_context => 1, clear_screen => 1 }
            );
            if ( ! defined $stmt || ! length $stmt ) {
                next STMT;
            }
            my $folded_stmt = "\n" . line_fold( 'Stmt: ' . $stmt, get_term_width(), { init_tab => '', subseq_tab => ' ' x length( 'Stmt: ' ), join => 1 } );
            my $default;
            if ( $history_HD->[$idx][0] ne $history_HD->[$idx][1] ) {
                $default = $history_HD->[$idx][1];
            }
            # Readline
            my $name = $tf->readline(
                'Name: ',
                { info => $info . $folded_stmt, default => $default, show_context => 1 }
            );
            if ( ! defined $name ) {
                next STMT;
            }
            if ( $stmt ne $history_HD->[$idx][0] || $name ne $history_HD->[$idx][1] ) {
                push @$bu, [ [ @$history_HD ], [ @$indexes ] ];
                $history_HD->[$idx] = [ $stmt, length $name ? $name : $stmt ];
                push @$indexes, $idx;
            }
        }
    }
}


sub __remove_subqueries {
    my ( $sf, $history_HD, $top_lines ) = @_;
    if ( ! @$history_HD ) {
        return;
    }
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $idxs = $tu->choose_a_subset(
        [ map { $_->[1] } @$history_HD ],
        {
            info => join( "\n", @$top_lines ),
            cs_label => "Remove:\n", cs_begin => "  ", cs_separator => "\n  ", cs_end => "\n",
            prompt => 'Choose:', back => $sf->{i}{_back}, confirm => $sf->{i}{_confirm},
            prefix => '- ', layout => 3, clear_screen => 1,
            index => 1, all_by_default => 0
        }
    );
    if ( ! defined $idxs || ! @$idxs ) {
        return;
    }
    splice @$history_HD, $_, 1 for sort { $b <=> $a } @$idxs;
    return 1;
}





1;


__END__
