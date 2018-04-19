package # hide from PAUSE
App::DBBrowser::Subqueries;

use warnings;
use strict;
use 5.008003;
no warnings 'utf8';

our $VERSION = '2.013';

use File::Spec::Functions qw( catfile );

use List::MoreUtils qw( any );

use Term::Choose           qw( choose );
use Term::Choose::LineFold qw( print_columns );
use Term::Choose::Util     qw( choose_a_subset term_width );
use Term::Form             qw();

use if $^O eq 'MSWin32', 'Win32::Console::ANSI'; #

use App::DBBrowser::Auxil;


sub new {
    my ( $class, $info, $options, $data ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $data,
        sq_file => catfile $info->{app_dir}, 'saved_subqueries.json',
    };
    bless $sf, $class;
}


sub choose_subquery {
    my ( $sf, $sql, $tmp, $stmt_type ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my @pre = ( undef );
    my $h_ref = $ax->read_json( $sf->{sq_file} );
    my $driver = $sf->{d}{driver};
    my $db = $sf->{d}{db};
    my $saved_subqueries = $h_ref->{$driver}{$db} || []; # reverse
    my $tmp_subqueries;
    for my $stmt ( @{$sf->{i}{stmt_history}} ) {
        my $filled = $ax->fill_stmt( @$stmt, 1 );
        push @$tmp_subqueries, $filled if defined $filled;
    }
    my $choices = [ @pre, map( '  ' . $_, @$saved_subqueries ), map( 't ' . $_, @$tmp_subqueries ) ];
    my $idx = $sf->__choose_see_long( $choices, $sql, $tmp, $stmt_type  );
    if ( ! $idx ) {
        return;
    }
    else {
        $idx -= @pre;
        if ( $idx <= $#$saved_subqueries ) {
            return $saved_subqueries->[$idx];
        }
        else {
            $idx -= @$saved_subqueries;
            return $tmp_subqueries->[$idx];
        }
    }
}


sub __choose_see_long {
    my ( $sf, $choices, $sql, $tmp, $stmt_type  ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );

    HIST: while ( 1 ) {
        $ax->print_sql( $sql, [ $stmt_type ], $tmp );
        my $idx = choose( $choices, { %{$sf->{i}{lyt_stmt_v}}, index => 1 } );
        if ( ! $idx ) {
            return;
        }
        if ( print_columns( $choices->[$idx] ) > term_width() ) {
            my $stmt = $choices->[$idx];
            $stmt =~ s/^[\ t]\ //;
            $ax->print_sql( $sql, [ $stmt_type ], $tmp );
            my $ok = choose(
                [ undef, $sf->{i}{ok} ],
                { %{$sf->{i}{lyt_stmt_h}}, prompt => $stmt, undef => '<<' }
            );
            if ( ! $ok ) {
                next HIST;
            }
        }
        return $idx;
    }
}


sub edit_sq_file {
    my ( $sf ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my ( $add, $edit, $remove ) = ( 'Add', 'Edit', 'Remove' );
    my @pre = ( undef );
    my $driver = $sf->{d}{driver};
    my $db = $sf->{d}{db};

    while ( 1 ) {
        my $h_ref = $ax->read_json( $sf->{sq_file} );
        my $subqueries = $h_ref->{$driver}{$db} || [];
        my @tmp = ( $sf->{d}{db_string}, 'Saved stmts:', map( '  ' . $_, @$subqueries ), ' ' );
        my $info = join "\n", @tmp;
        my $choice = choose(
            [ @pre, $add, $edit, $remove ],
            { %{$sf->{i}{lyt_m}}, prompt => 'Choose:', info => $info }
        );
        my $ok;
        if ( ! defined $choice ) {
            return;
        }
        elsif ( $choice eq $add ) {
            $subqueries = $sf->__add_subqueries( $subqueries );
        }
        elsif ( $choice eq $edit ) {
            $subqueries = $sf->__edit_subqueries( $subqueries );
        }
        elsif ( $choice eq $remove ) {
            $subqueries = $sf->__remove_subqueries( $subqueries );
        }
        if ( defined $subqueries ) {
            if ( @$subqueries ) {
                $h_ref->{$driver}{$db} = $subqueries;
            }
            else {
                delete $h_ref->{$driver}{$db};
            }
            $ax->write_json( $sf->{sq_file}, $h_ref );
        }
    }
}


sub __add_subqueries {
    my ( $sf, $subqueries ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $available;
    for my $stmt ( @{$sf->{i}{stmt_history}} ) {
        my $filled = $ax->fill_stmt( @$stmt, 1 );
        push @$available, $filled if defined $filled;
    }
    my $readline = '  readline';
    my @pre = ( undef, $sf->{i}{_confirm}, $readline );
    my $bu = [];

    while ( 1 ) {
        my @tmp = ( $sf->{d}{db_string}, 'Saved stmts:', map( '  ' . $_, @$subqueries ), ' ' );
        my $info = join "\n", @tmp;
        my $choices = [ @pre, map { '  ' . $_ } @$available ];
        my $idx = choose(
            $choices,
            { %{$sf->{i}{lyt_3}}, prompt => 'Add:', info => $info, index => 1, undef => $sf->{i}{_back} }
        );
        if ( ! $idx ) {
            if ( @$bu ) {
                ( $subqueries, $available ) = @{pop @$bu};
                next; #
            }
            return;
        }
        elsif ( $choices->[$idx] eq $sf->{i}{_confirm} ) {
            return $subqueries;
        }
        elsif ( $choices->[$idx] eq $readline ) {
            my $tf = Term::Form->new();
            my $stmt = $tf->readline( 'Stmt: ', { info => $info, clear_screen => 1  } );
            if ( ! defined $stmt || ! length $stmt ) {
                if ( @$bu ) {
                    ( $subqueries, $available ) = @{pop @$bu};
                    next; #
                }
                return 0;
            }
            push @$bu, [ [ @$subqueries ], [ @$available ] ];
            push @$subqueries, $stmt;
        }
        else {
            push @$bu, [ [ @$subqueries ], [ @$available ] ];
            push @$subqueries, splice @$available, $idx-@pre, 1;
        }
    }
}


sub __edit_subqueries {
    my ( $sf, $subqueries ) = @_;
    my $indexes = [];
    my @pre = ( undef, $sf->{i}{_confirm} );
    my $bu = [];
    my $old_idx = 0;

    STMT: while ( 1 ) {
        my @tmp = ( $sf->{d}{db_string} );
        my $info = join "\n", @tmp;
        my @available;
        for my $i ( 0 .. $#$subqueries ) {
            my $pre = ( any { $i == $_ } @$indexes ) ? '| ' : '  ';
            push @available, $pre . $subqueries->[$i];
        }
        my $choices = [ @pre, @available ];
        $ENV{TC_RESET_AUTO_UP} = 0;
        # Choose
        my $idx = choose(
            $choices,
            { %{$sf->{i}{lyt_3}}, prompt => 'Choose stmt:', info => $info, index => 1, default => $old_idx }
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
            return $subqueries;
        }
        else {
            $idx -= @pre;
            my @tmp = ( $sf->{d}{db_string}, 'Choose stmt:', '  BACK', '  CONFIRM' );
            for my $i ( 0 .. $#$subqueries ) {
                my $pre = '  ';
                if ( $i == $idx ) {
                    $pre = '> ';
                }
                elsif ( any { $i == $_ } @$indexes ) {
                    $pre = '| ';
                }
                push @tmp, $pre . $subqueries->[$i];
            }
            push @tmp, ' ';
            my $info = join "\n", @tmp;
            my $tf = Term::Form->new();
            my $stmt = $tf->readline( 'Stmt: ', { info => $info, clear_screen => 1, default => $subqueries->[$idx]  } );
            if ( ! defined $stmt || ! length $stmt ) {
                if ( @$bu ) {
                    ( $subqueries, $indexes ) = @{pop @$bu};
                    next STMT; #
                }
                return;
            }
            if ( $stmt ne $subqueries->[$idx] ) {
                push @$bu, [ [ @$subqueries ], [ @$indexes ] ];
                $subqueries->[$idx] = $stmt;
                push @$indexes, $idx;
            }
        }
    }
}


sub __remove_subqueries {
    my ( $sf, $subqueries ) = @_;
    if ( ! @$subqueries ) {
        return;
    }
    my @tmp = ( $sf->{d}{db_string}, 'Stmts to remove:' );
    my $info = join "\n", @tmp;
    my $prompt = "\n" . 'Choose:';
    my $idx = choose_a_subset(
        $subqueries,
        { mouse => $sf->{o}{table}{mouse}, index => 1, fmt_chosen => 1, remove_chosen => 1, prompt => $prompt,
          info => $info, back => '  BACK', confirm => '  CONFRIM', prefix => '- ' }
    );
    if ( ! defined $idx || ! @$idx ) {
        return;
    }
    for my $i ( sort { $b <=> $a } @$idx ) {
        my $ref = splice( @$subqueries, $i, 1 );
    }
    return $subqueries;
}





1;


__END__
