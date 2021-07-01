package # hide from PAUSE
App::DBBrowser::CreateDropAttach::AttachDB;

use warnings;
use strict;
use 5.010001;

use List::MoreUtils qw( any );

use Term::Choose qw();
use Term::Form   qw();

use App::DBBrowser::Auxil;


sub new {
    my ( $class, $info, $options, $data ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $data
    }, $class;
}


sub attach_db {
    my ( $sf ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $cur_attached;
    if ( -s $sf->{i}{f_attached_db} ) {
        my $h_ref = $ax->read_json( $sf->{i}{f_attached_db} ) // {};
        $cur_attached = $h_ref->{$sf->{d}{db}} // [];
    }
    my $new_attached = [];
    my $old_idx = 1;

    ATTACH: while ( 1 ) {

        DB: while ( 1 ) {
            my @tmp_info = ( $sf->{d}{db_string} );
            for my $ref ( @$cur_attached, @$new_attached ) {
                push @tmp_info, sprintf "ATTACH DATABASE %s AS %s", @$ref;
            }
            push @tmp_info, '';
            my @pre = ( undef );
            my @choices = ( @{$sf->{d}{user_dbs}}, @{$sf->{d}{sys_dbs}} );
            my $menu = [ @pre, @choices ];
            my $info = join( "\n", @tmp_info );
            # Choose
            my $idx = $tc->choose(
                $menu,
                { %{$sf->{i}{lyt_v}}, prompt => "ATTACH DATABASE", info => $info,
                  undef => $sf->{i}{back}, index => 1, default => $old_idx }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $idx || ! defined $menu->[$idx] ) {
                if ( @$new_attached ) {
                    shift @$new_attached;
                    next DB;
                }
                return;
            }
            if ( $sf->{o}{G}{menu_memory} ) {
                if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                    $old_idx = 0;
                    next ATTACH;
                }
                $old_idx = $idx;
            }
            my $db = $menu->[$idx];
            my $tf = Term::Form->new( $sf->{i}{tf_default} );
            push @tmp_info, "ATTACH DATABASE $db AS";

            ALIAS: while ( 1 ) {
                my $info = join( "\n", @tmp_info );
                # Readline
                my $alias = $tf->readline( ##
                    'alias: ',
                    { info => $info, clear_screen => 1 }
                );
                $ax->print_sql_info( $info );
                if ( ! length $alias ) {
                    last ALIAS;
                }
                elsif ( any { $_->[1] eq $alias } @$cur_attached, @$new_attached ) {
                    my $prompt = "alias '$alias' already used:";
                    my $info = join( "\n", @tmp_info );
                    # Choose
                    my $retry = $tc->choose(
                        [ undef, 'New alias' ],
                        { prompt => $prompt, info => $info, undef => $sf->{i}{back}, clear_screen => 1 }
                    );
                    $ax->print_sql_info( $info );
                    last ALIAS if ! defined $retry;
                    next ALIAS;
                }
                else {
                    push @$new_attached, [ $db, $alias ]; # 2 x $db with different $alias ?
                    last ALIAS;
                }
            }

            POP_ATTACHED: while ( 1 ) {
                my @tmp_info = ( $sf->{d}{db_string} );
                push @tmp_info, map { "ATTACH DATABASE $_->[0] AS $_->[1]" } @$cur_attached, @$new_attached;
                push @tmp_info, '';
                my ( $ok, $more ) = ( 'OK', '++' );
                my $info = join( "\n", @tmp_info );
                # Choose
                my $choice = $tc->choose(
                    [ undef, $ok, $more ],
                    { info => $info, clear_screen => 1 }
                );
                $ax->print_sql_info( $info );
                if ( ! defined $choice ) {
                    if ( @$new_attached > 1 ) {
                        pop @$new_attached;
                        next POP_ATTACHED;
                    }
                    return;
                }
                elsif ( $choice eq $ok ) {
                    if ( ! @$new_attached ) {
                        return;
                    }
                    my $h_ref = $ax->read_json( $sf->{i}{f_attached_db} ) // {};
                    $h_ref->{$sf->{d}{db}} = [ sort( @$cur_attached, @$new_attached  ) ];
                    $ax->write_json( $sf->{i}{f_attached_db}, $h_ref );
                    return 1;
                }
                elsif ( $choice eq $more ) {
                    next DB;
                }
            }
        }
    }
}


sub detach_db {
    my ( $sf ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $attached_db;
    if ( -s $sf->{i}{f_attached_db} ) {
        my $h_ref = $ax->read_json( $sf->{i}{f_attached_db} ) // {};
        $attached_db = $h_ref->{$sf->{d}{db}} // [];
    }
    my @chosen;

    while ( 1 ) {
        my @tmp_info = ( $sf->{d}{db_string}, 'Detach:' );
        for my $detach ( @chosen ) {
            push @tmp_info, sprintf 'DETACH DATABASE %s (%s)', $detach->[1], $detach->[0];
        }
        my @choices;
        for my $elem ( @$attached_db ) {
            push @choices, sprintf '- %s  (%s)', @$elem[1,0];
        }
        my $prompt = "\n" . 'Choose:';
        my @pre = ( undef, $sf->{i}{_confirm} );
        my $info = join "\n", @tmp_info;
        # Choose
        my $idx = $tc->choose(
            [ @pre, @choices ],
            { %{$sf->{i}{lyt_v}}, prompt => $prompt, info => $info, index => 1 }
        );
        $ax->print_sql_info( $info );
        if ( ! $idx ) {
            return;
        }
        elsif ( $idx == $#pre ) {
            my $h_ref = $ax->read_json( $sf->{i}{f_attached_db} ) // {};
            if ( @$attached_db ) {
                $h_ref->{$sf->{d}{db}} = $attached_db;
            }
            else {
                delete $h_ref->{$sf->{d}{db}};
            }
            $ax->write_json( $sf->{i}{f_attached_db}, $h_ref );
            return 1;
        }
        push @chosen, splice( @$attached_db, $idx - @pre, 1 );
    }
}








1;

__END__
