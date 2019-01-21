package # hide from PAUSE
App::DBBrowser::Subqueries;

use warnings;
use strict;
use 5.008003;

use File::Spec::Functions qw( catfile );

use List::MoreUtils qw( any uniq );

use Term::Choose           qw( choose );
use Term::Choose::LineFold qw( print_columns line_fold );
use Term::Choose::Util     qw( choose_a_subset term_width );
use Term::Form             qw();

use App::DBBrowser::Auxil;


sub new {
    my ( $class, $info, $options, $data ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $data,
        subquery_file => catfile( $info->{app_dir}, 'subqueries.json' ),
    };
    bless $sf, $class;
}


sub __tmp_history {
    my ( $sf, $clause, $saved_history ) = @_;
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
    my @clause_history = uniq @{$sf->{i}{history}{$db}{$clause}};
    if ( @clause_history > 7 ) {
        $#clause_history = 6;
    }
    my $tmp_history = [];
    for my $tmp ( uniq( @clause_history, @print_history ) ) {
        if ( any { $tmp eq $_->[1] } @$saved_history ) {
            next;
        }
        push @$tmp_history, [ $tmp, $tmp ];
    }
    return $tmp_history;
}


sub __get_history {
    my ( $sf, $clause ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $h_ref = $ax->read_json( $sf->{subquery_file} );
    my $saved_history = $h_ref->{ $sf->{d}{driver} }{ $sf->{d}{db} }{ $clause } || [];
    my $tmp_history = $sf->__tmp_history( $clause, $saved_history );
    my $history = [ @$saved_history, @$tmp_history ];
    return $history;
}


sub choose_subquery {
    my ( $sf, $sql, $clause ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $history = $sf->__get_history( $clause );
    my $edit_sq_file = 'Choose SQ:';
    my $readline     = '  Read-Line';
    my @pre = ( $edit_sq_file, undef, $readline );
    my $old_idx = 1;

    SUBQUERY: while ( 1 ) {
        my $choices = [ @pre, map { '- ' . $_->[1] } @$history ];
        $ENV{TC_RESET_AUTO_UP} = 0;
        # Choose
        my $idx = choose(
            $choices,
            { %{$sf->{i}{lyt_stmt_v}}, index => 1, prompt => '', default => $old_idx, undef => '  <=' }
        );
        if ( ! defined $idx || ! defined $choices->[$idx] ) {
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx = 1;
                next SUBQUERY;
            }
            else {
                $old_idx = $idx;
            }
        }
        delete $ENV{TC_RESET_AUTO_UP};
        if ( $choices->[$idx] eq $edit_sq_file ) {
            if ( $sf->edit_sq_file( $clause ) ) {
                $history = $sf->__get_history( $clause );
                $choices = [ @pre, map { '- ' . $_->[1] } @$history ];
            }
            $ax->print_sql( $sql );
            next SUBQUERY;
        }
        my ( $prompt, $default, $info );
        if ( $choices->[$idx] eq $readline ) {
            $prompt = 'Stmt: ';
        }
        else {
            $info = "\nPress 'Enter'";
            $prompt = '';
            $idx -= @pre;
            if ( $history->[$idx][0] ne $history->[$idx][1] ) {
                return "(" . $history->[$idx][0] . ")";
            }
            $default = $history->[$idx][0];
        }
        my $tf = Term::Form->new();
        my $stmt = $tf->readline( $prompt, { default => $default, info => $info } );
        if ( defined $stmt && length $stmt ) {
            my $db = $sf->{d}{db};
            unshift @{$sf->{i}{history}{$db}{$clause}}, $stmt;
            if ( $stmt !~ /^\s*\([^)(]+\)\s*\z/ ) {
                $stmt = "(" . $stmt . ")";
            }
            return $stmt;
        }
    }
}


sub edit_sq_file {
    my ( $sf, $clause ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $driver = $sf->{d}{driver};
    my $db = $sf->{d}{db};
    my @pre = ( undef );
    my ( $add, $edit, $remove ) = ( '- Add', '- Edit', '- Remove' );
    my $any_change = 0;

    while ( 1 ) {
        my $top_lines = [ $db, sprintf( 'Stored Subqueries "%s":', ucfirst $clause ) ];
        my $h_ref = $ax->read_json( $sf->{subquery_file} );
        my $saved_history = $h_ref->{$driver}{$db}{$clause} || [];
        my @tmp_info = (
            @$top_lines,
            map( line_fold( $_->[-1], term_width(), '  ', '    ' ), @$saved_history ),
            ' '
        );
        my $info = join "\n", @tmp_info;
        # Choose
        my $choice = choose(
            [ @pre, $add, $edit, $remove ],
            { %{$sf->{i}{lyt_v_clear}}, prompt => 'Choose:', undef => '  <=', info => $info }
        );
        my $changed = 0;
        if ( ! defined $choice ) {
            return $any_change;
        }
        elsif ( $choice eq $add ) {
            $changed = $sf->__add_subqueries( $saved_history, $top_lines, $clause );
        }
        elsif ( $choice eq $edit ) {
            $changed = $sf->__edit_subqueries( $saved_history, $top_lines, $clause );
        }
        elsif ( $choice eq $remove ) {
            $changed = $sf->__remove_subqueries( $saved_history, $top_lines, $clause );
        }
        if ( $changed ) {
            if ( @$saved_history ) {
                $h_ref->{$driver}{$db}{$clause} = $saved_history;
            }
            else {
                delete $h_ref->{$driver}{$db}{$clause};
            }
            $ax->write_json( $sf->{subquery_file}, $h_ref );
            $any_change++;
        }
    }
}


sub __add_subqueries {
    my ( $sf, $saved_history, $top_lines, $clause ) = @_;
    my $tmp_history = $sf->__tmp_history( $clause, $saved_history );
    my $used = [];
    my $readline = '  Read-Line';
    my @pre = ( undef, $sf->{i}{_confirm}, $readline );
    my $bu = [];
    my $tmp_new = [];

    while ( 1 ) {
        my @tmp_info = (
            @$top_lines,
            map( line_fold( $_->[1], term_width(), '  ', '    ' ), @$saved_history ),
        );
        if ( @$tmp_new ) {
            push @tmp_info, map( line_fold( $_->[1], term_width(), '| ', '    ' ), @$tmp_new );
        }
        push @tmp_info, ' ';
        my $info = join "\n", @tmp_info;
        my $choices = [ @pre, map {  '- ' . $_->[1] } @$tmp_history ];
        # Choose
        my $idx = choose(
            $choices,
            { %{$sf->{i}{lyt_v_clear}}, prompt => 'Add:', info => $info, index => 1 }
        );
        if ( ! $idx ) {
            if ( @$bu ) {
                ( $tmp_new, $tmp_history, $used ) = @{pop @$bu};
                next;
            }
            return;
        }
        elsif ( $choices->[$idx] eq $sf->{i}{_confirm} ) {
            push @$saved_history, @$tmp_new;
            return 1;
        }
        elsif ( $choices->[$idx] eq $readline ) {
            my $tf = Term::Form->new();
            my $stmt = $tf->readline( 'Stmt: ', { info => $info, clear_screen => 1  } );
            if ( defined $stmt && length $stmt ) {
                if ( $stmt =~ /^\s*\(([^)(]+)\)\s*\z/ ) {
                    $stmt = $1;
                }
                push @$bu, [ [ @$tmp_new ], [ @$tmp_history ], [ @$used ] ];
                my $folded_stmt = "\n" . line_fold( 'Stmt: ' . $stmt, term_width(), '', ' ' x length( 'Stmt: ' ) );
                my $name = $tf->readline( 'Name: ', { info => $info . $folded_stmt } );
                push @$tmp_new, [ $stmt, length $name ? $name : $stmt ];
            }
        }
        else {
            push @$bu, [ [ @$tmp_new ], [ @$tmp_history ], [ @$used ] ];
            push @$used, splice @$tmp_history, $idx-@pre, 1;
            my $stmt = $used->[-1][0];
            my $folded_stmt = "\n" . line_fold( 'Stmt: ' . $stmt, term_width(), '', ' ' x length( 'Stmt: ' ) );
            my $tf = Term::Form->new();
            my $name = $tf->readline( 'Name: ', { info => $info . $folded_stmt } );
            push @$tmp_new, [ $stmt, length $name ? $name : $stmt ];
        }
    }
}


sub __edit_subqueries {
    my ( $sf, $saved_history, $top_lines, $clause ) = @_;
    if ( ! @$saved_history ) {
        return;
    }
    my $indexes = [];
    my @pre = ( undef, $sf->{i}{_confirm} );
    my $bu = [];
    my $old_idx = 0;
    my @unchanged_saved_history = @$saved_history;

    STMT: while ( 1 ) {
        my $info = join "\n", @$top_lines;
        my @available;
        for my $i ( 0 .. $#$saved_history ) {
            my $pre = ( any { $i == $_ } @$indexes ) ? '| ' : '- ';
            push @available, $pre . $saved_history->[$i][1];
        }
        my $choices = [ @pre, @available ];
        $ENV{TC_RESET_AUTO_UP} = 0;
        # Choose
        my $idx = choose(
            $choices,
            { %{$sf->{i}{lyt_v_clear}}, prompt => 'Edit:', info => $info, index => 1, default => $old_idx }
        );
        if ( ! $idx ) {
            if ( @$bu ) {
                ( $saved_history, $indexes ) = @{pop @$bu};
                next STMT;
            }
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx = 0;
                next STMT;
            }
            else {
                $old_idx = $idx;
            }
        }
        delete $ENV{TC_RESET_AUTO_UP};
        if ( $choices->[$idx] eq $sf->{i}{_confirm} ) {
            return 1;
        }
        else {
            $idx -= @pre;
            my @tmp_info = ( @$top_lines, 'Edit:', '  BACK', '  CONFIRM' );
            for my $i ( 0 .. $#$saved_history ) {
                my $stmt = $saved_history->[$i][1];
                my $pre = '  ';
                if ( $i == $idx ) {
                    $pre = '> ';
                }
                elsif ( any { $i == $_ } @$indexes ) {
                    $pre = '| ';
                }
                my $folded_stmt = line_fold( $stmt, term_width(), $pre,  $pre . ( ' ' x 2 ) );
                push @tmp_info, $folded_stmt;
            }
            push @tmp_info, ' ';
            my $info = join "\n", @tmp_info;
            my $tf = Term::Form->new();
            my $stmt = $tf->readline( 'Stmt: ', { info => $info, clear_screen => 1, default => $saved_history->[$idx][0] } );
            if ( ! defined $stmt || ! length $stmt ) {
                if ( @$bu ) {
                    ( $saved_history, $indexes ) = @{pop @$bu};
                    next STMT; #
                }
                return;
            }
            my $folded_stmt = "\n" . line_fold( 'Stmt: ' . $stmt, term_width(), '', ' ' x length( 'Stmt: ' ) );
            my $default;
            if ( $saved_history->[$idx][0] ne $saved_history->[$idx][1] ) {
                $default = $saved_history->[$idx][1];
            }
            my $name = $tf->readline( 'Name: ', { info => $info . $folded_stmt, default => $default } );
            {
                no warnings 'uninitialized';
                if ( $stmt ne $saved_history->[$idx][0] || $name ne $saved_history->[$idx][1] ) {
                    push @$bu, [ [ @$saved_history ], [ @$indexes ] ];
                    $saved_history->[$idx] = [ $stmt, length $name ? $name : $stmt ];
                    push @$indexes, $idx;
                }
            }
        }
    }
}


sub __remove_subqueries {
    my ( $sf, $saved_history, $top_lines, $clause ) = @_;
    if ( ! @$saved_history ) {
        return;
    }
    my @backup;
    my @pre = ( undef, $sf->{i}{_confirm} );
    my @remove;

    while ( 1 ) {
        my @tmp_info = (
            @$top_lines,
            'Remove:',,
            map( line_fold( $_, term_width(), '  ', '    ' ), @remove ),
            ' '
        );
        my $info = join "\n", @tmp_info;
        my $choices = [ @pre, map { '- ' . $_->[1] } @$saved_history ];
        my $idx = choose(
            $choices,
            { mouse => $sf->{o}{table}{mouse}, index => 1, prompt => 'Choose:',
              layout => 3, info => $info, undef => '  BACK' }
        );
        if ( ! $idx ) {
            if ( @backup ) {
                $saved_history = pop @backup;
                pop @remove;
                next;
            }
            return;
        }
        elsif ( $choices->[$idx] eq $sf->{i}{_confirm} ) {
            if ( ! @remove ) {
                return;
            }
            return 1;
        }
        push @backup, [ @$saved_history ];
        my $ref = splice( @$saved_history, $idx - @pre, 1 );
        push @remove, $ref->[1];
    }
}





1;


__END__
