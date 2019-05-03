package # hide from PAUSE
App::DBBrowser::AttachDB;

use warnings;
use strict;
use 5.010001;

use List::MoreUtils qw( any );

use Term::Choose qw( choose );
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
    my $cur_attached;
    if ( -s $sf->{i}{f_attached_db} ) {
        my $h_ref = $ax->read_json( $sf->{i}{f_attached_db} );
        $cur_attached = $h_ref->{$sf->{d}{db}} || [];
    }
    my $choices = [ undef, @{$sf->{d}{user_dbs}}, @{$sf->{d}{sys_dbs}} ];
    my $new_attached = [];

    ATTACH: while ( 1 ) {

        DB: while ( 1 ) {
            my @tmp_info = ( $sf->{d}{db_string} );
            for my $ref ( @$cur_attached, @$new_attached ) {
                push @tmp_info, sprintf "ATTACH DATABASE %s AS %s", @$ref;
            }
            push @tmp_info, '';
            my $info = join( "\n", @tmp_info );
            my $prompt = "ATTACH DATABASE"; # \n
            my $db = choose(
                $choices,
                { %{$sf->{i}{lyt_v_clear}}, info => $info, prompt => $prompt, undef => $sf->{i}{back} }
            );
            if ( ! defined $db ) {
                if ( @$new_attached ) {
                    shift @$new_attached;
                    next DB;
                }
                return;
            }
            my $tfr = Term::Form->new();
            push @tmp_info, "ATTACH DATABASE $db AS";
            $info = join( "\n", @tmp_info );

            ALIAS: while ( 1 ) {
                my $alias = $tfr->readline( 'alias: ', { clear_screen => 1, info => $info } );
                if ( ! length $alias ) {
                    last ALIAS;
                }
                elsif ( any { $_->[1] eq $alias } @$cur_attached, @$new_attached ) {
                    my $prompt = "alias '$alias' already used:";
                    my $retry = choose(
                        [ undef, 'New alias' ],
                        { %{$sf->{i}{lyt_m}}, prompt => $prompt, info => $info, undef => 'Back', clear_screen => 1 }
                    );
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
                my $info = join( "\n", @tmp_info );
                my $prompt = 'Choose:';
                my ( $ok, $more ) = ( 'OK', '++' );
                my $choice = choose(
                    [ undef, $ok, $more ],
                    { %{$sf->{i}{lyt_m}}, prompt => $prompt, info => $info, undef => '<<', clear_screen => 1 }
                );
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
                    my $h_ref = $ax->read_json( $sf->{i}{f_attached_db} );
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
    my $attached_db;
    if ( -s $sf->{i}{f_attached_db} ) {
        my $h_ref = $ax->read_json( $sf->{i}{f_attached_db} );
        $attached_db = $h_ref->{$sf->{d}{db}} || [];
    }
    my @chosen;

    while ( 1 ) {
        my @tmp_info = ( $sf->{d}{db_string}, 'Detach:' );

        for my $detach ( @chosen ) {
            push @tmp_info, sprintf 'DETACH DATABASE %s (%s)', $detach->[1], $detach->[0];
        }
        my $info = join "\n", @tmp_info;
        my @choices;
        for my $elem ( @$attached_db ) {
            push @choices, sprintf '- %s  (%s)', @$elem[1,0];
        }
        my $prompt = "\n" . 'Choose:';
        my @pre = ( undef, $sf->{i}{_confirm} );
        # Choose
        my $idx = choose(
            [ @pre, @choices ],
            { %{$sf->{i}{lyt_v_clear}}, info => $info, index => 1, prompt => $prompt }
        );
        if ( ! $idx ) {
            return;
        }
        elsif ( $idx == $#pre ) {
            my $h_ref = $ax->read_json( $sf->{i}{f_attached_db} );
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
