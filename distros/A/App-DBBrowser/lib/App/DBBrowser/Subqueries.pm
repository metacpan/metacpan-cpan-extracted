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


sub __stmt_history {
    my ( $sf, $clause ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $db = $sf->{d}{db};
    my $print_history_keep   = [];
    my $print_history_filled = [];
    for my $ref ( @{$sf->{i}{history}{$db}{print}} ) {
        my $filled_stmt = $ax->stmt_placeholder_to_value( @$ref, 1 );
        if ( $filled_stmt =~ /^[^\(]+FROM\s*\(\s*(\S.+\S)\s*\)[^\)]*\z/ ) { # Union, Join
            $filled_stmt = $1;
        }
        if ( any { $_ eq $filled_stmt } @$print_history_filled ) {
            next;
        }
        if ( @$print_history_keep == 8 ) {
            $sf->{i}{history}{$db}{print} = $print_history_keep;
            last;
        }
        push @$print_history_keep, $ref;
        push @$print_history_filled, $filled_stmt;
    }
    my $sq_history = [ uniq @{$sf->{i}{history}{$db}{$clause}} ];
    $#{$sq_history} = 5 if @$sq_history > 6;
    my $history = [ uniq @$sq_history, @$print_history_filled ];
    if ( @$history > 12 ) {
        $#{$history} = 11;
    }
    return $history;
}


sub choose_subquery {
    my ( $sf, $sql, $stmt_type, $clause ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $db = $sf->{d}{db};
    my $h_ref = $ax->read_json( $sf->{subquery_file} );
    my $subqueries = $h_ref->{ $sf->{d}{driver} }{ $sf->{d}{db} }{ $clause } || [];
    my $history = $sf->__stmt_history( $clause );
    my $edit_sq_file = 'Choose SQ:';
    my $readline     = '  Read-Line';
    my @pre = ( $edit_sq_file, undef, $readline );
    my $old_idx = 1;
    my $prefix = '- ';

    SUBQUERY: while ( 1 ) {
        $ax->print_sql( $sql, [ $stmt_type ] ); ##
        my $choices = [
            @pre,
            map( $prefix . $_->[-1], @$subqueries ),
            map( $prefix . $_, @$history )
        ];
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
            my $any_change = $sf->edit_sq_file( $clause );
            if ( $any_change ) {
                $h_ref = $ax->read_json( $sf->{subquery_file} );
                $subqueries = $h_ref->{ $sf->{d}{driver} }{ $sf->{d}{db} }{ $clause } || [];
                $choices = [
                    @pre,
                    map( $prefix . $_->[-1], @$subqueries ),
                    map( $prefix . $_, @$history )
                ];
            }
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
            if ( $idx <= $#$subqueries ) {
                $default = $subqueries->[$idx][0];
            }
            else {
                $idx -= @$subqueries;
                $default = $history->[$idx];
            }
        }
        $ax->print_sql( $sql, [ $stmt_type ] ); ##
        my $tf = Term::Form->new();
        my $stmt = $tf->readline( $prompt, { default => $default, info => $info } );
        if ( defined $stmt && length $stmt ) {
            if ( $stmt =~ /^\s*\((.+)\)\s*\z/ ) {
                $stmt = $1;
            }
            unshift @{$sf->{i}{history}{$db}{$clause}}, $stmt;
            return "(" . $stmt . ")";
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
        my $top_lines = [ $db, sprintf( 'Stored Subqueries "%s"', ucfirst $clause ) ];
        my $h_ref = $ax->read_json( $sf->{subquery_file} );
        my $subqueries = $h_ref->{$driver}{$db}{$clause} || [];
        my @tmp_info = (
            @$top_lines,
            map( line_fold( $_->[-1], term_width(), '  ', '    ' ), @$subqueries ),
            ' '
        );
        my $info = join "\n", @tmp_info;
        # Choose
        my $choice = choose(
            [ @pre, $add, $edit, $remove ],
            { %{$sf->{i}{lyt_v_clear}}, undef => '  <=', info => $info }
        );
        my $changed = 0;
        if ( ! defined $choice ) {
            return $any_change;
        }
        elsif ( $choice eq $add ) {
            $changed = $sf->__add_subqueries( $subqueries, $top_lines, $clause );
        }
        elsif ( $choice eq $edit ) {
            $changed = $sf->__edit_subqueries( $subqueries, $top_lines, $clause );
        }
        elsif ( $choice eq $remove ) {
            $changed = $sf->__remove_subqueries( $subqueries, $top_lines, $clause );
        }
        if ( $changed ) {
            if ( @$subqueries ) {
                $h_ref->{$driver}{$db}{$clause} = $subqueries;
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
    my ( $sf, $subqueries, $top_lines, $clause ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $history = $sf->__stmt_history( $clause );
    my $used = [];
    my $readline = '  Read-Line';
    my @pre = ( undef, $sf->{i}{_confirm}, $readline );
    my $bu = [];
    my $tmp_new = [];

    while ( 1 ) {
        my @tmp_info = ( @$top_lines, map( line_fold( $_->[-1], term_width(), '  ', '    ' ), @$subqueries ) );
        if ( @$tmp_new ) {
            push @tmp_info, map( line_fold( $_->[-1], term_width(), '| ', '    ' ), @$tmp_new );
        }
        push @tmp_info, ' ';
        my $info = join "\n", @tmp_info;
        my $choices = [ @pre, map { '- ' . $_ } @$history ];
        # Choose
        my $idx = choose(
            $choices,
            { %{$sf->{i}{lyt_v_clear}}, prompt => 'Add:', info => $info, index => 1 }
        );
        if ( ! $idx ) {
            if ( @$bu ) {
                ( $tmp_new, $history, $used ) = @{pop @$bu};
                next;
            }
            return;
        }
        elsif ( $choices->[$idx] eq $sf->{i}{_confirm} ) {
            push @$subqueries, @$tmp_new;
            return 1;
        }
        elsif ( $choices->[$idx] eq $readline ) {
            my $tf = Term::Form->new();
            my $stmt = $tf->readline( 'Stmt: ', { info => $info, clear_screen => 1  } );
            if ( defined $stmt && length $stmt ) {
                if ( $stmt =~ /^\s*\((.+)\)\s*\z/ ) {
                    $stmt = $1;
                }
                push @$bu, [ [ @$tmp_new ], [ @$history ], [ @$used ] ];
                my $folded_stmt = "\n" . line_fold( 'Stmt: ' . $stmt, term_width(), '', ' ' x length( 'Stmt: ' ) );
                my $name = $tf->readline( 'Name: ', { info => $info . $folded_stmt } );
                push @$tmp_new, [ $stmt, length $name ? $name : () ];
            }
        }
        else {
            push @$bu, [ [ @$tmp_new ], [ @$history ], [ @$used ] ];
            push @$used, splice @$history, $idx-@pre, 1;
            my $stmt = $used->[-1];
            my $folded_stmt = "\n" . line_fold( 'Stmt: ' . $stmt, term_width(), '', ' ' x length( 'Stmt: ' ) );
            my $tf = Term::Form->new();
            my $name = $tf->readline( 'Name: ', { info => $info . $folded_stmt } );
            push @$tmp_new, [ $stmt, length $name ? $name : () ];
        }
    }
}


sub __edit_subqueries {
    my ( $sf, $subqueries, $top_lines, $clause ) = @_;
    if ( ! @$subqueries ) {
        return;
    }
    my $indexes = [];
    my @pre = ( undef, $sf->{i}{_confirm} );
    my $bu = [];
    my $old_idx = 0;
    my @unchanged_subqueries = @$subqueries;

    STMT: while ( 1 ) {
        my $info = join "\n", @$top_lines;
        my @available;
        for my $i ( 0 .. $#$subqueries ) {
            my $pre = ( any { $i == $_ } @$indexes ) ? '| ' : '- ';
            push @available, $pre . $subqueries->[$i][-1];
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
                ( $subqueries, $indexes ) = @{pop @$bu};
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
            for my $i ( 0 .. $#$subqueries ) {
                my $stmt = $subqueries->[$i][-1];
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
            my $stmt = $tf->readline( 'Stmt: ', { info => $info, clear_screen => 1, default => $subqueries->[$idx][0] } );
            if ( ! defined $stmt || ! length $stmt ) {
                if ( @$bu ) {
                    ( $subqueries, $indexes ) = @{pop @$bu};
                    next STMT; #
                }
                return;
            }
            my $folded_stmt = "\n" . line_fold( 'Stmt: ' . $stmt, term_width(), '', ' ' x length( 'Stmt: ' ) );
            my $name = $tf->readline( 'Name: ', { info => $info . $folded_stmt, default => $subqueries->[$idx][1] } );
            {
                no warnings 'uninitialized';
                if ( $stmt ne $subqueries->[$idx][0] || $name ne $subqueries->[$idx][1] ) {
                    push @$bu, [ [ @$subqueries ], [ @$indexes ] ];
                    $subqueries->[$idx] = [ $stmt, length $name ? $name : () ];;
                    push @$indexes, $idx;
                }
            }
        }
    }
}


sub __remove_subqueries {
    my ( $sf, $subqueries, $top_lines, $clause ) = @_;
    if ( ! @$subqueries ) {
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
        my $choices = [ @pre, map { '- ' . $_->[-1] } @$subqueries ];
        my $idx = choose(
            $choices,
            { mouse => $sf->{o}{table}{mouse}, index => 1, prompt => 'Choose:',
              layout => 3, info => $info, undef => '  BACK' }
        );
        if ( ! $idx ) {
            if ( @backup ) {
                $subqueries = pop @backup;
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
        push @backup, [ @$subqueries ];
        my $ref = splice( @$subqueries, $idx - @pre, 1 );
        push @remove, $ref->[-1];
    }
}





1;


__END__
