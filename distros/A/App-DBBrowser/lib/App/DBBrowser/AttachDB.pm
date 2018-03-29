package # hide from PAUSE
App::DBBrowser::AttachDB;

use warnings;
use strict;
use 5.008003;
no warnings 'utf8';

our $VERSION = '2.009';

use File::Basename qw( basename );
use List::Util     qw( any );

use Term::Choose       qw( choose );
use Term::Choose::Util qw( choose_a_subset );
use Term::Form         qw();

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
    my $cur;
    if ( -s $sf->{i}{file_attached_db} ) {
        my $h_ref = $ax->read_json( $sf->{i}{file_attached_db} );
        $cur = $h_ref->{$sf->{d}{db}} || [];
    }
    my $choices = [ undef, @{$sf->{d}{user_dbs}}, @{$sf->{d}{sys_dbs}} ];
    my $new = [];
    my $root = 'DB: "' . basename( $sf->{d}{db} ) . "\"\n";

    ATTACH: while ( 1 ) {

        DB: while ( 1 ) {
            my $info = $root;
            for my $ref ( @$cur, @$new ) {
                $info .= sprintf "ATTACH DATABASE %s AS %s\n", @$ref;
            }
            my $prompt = $info;
            $prompt .= "\nATTACH DATABASE"; # \n
            my $db = choose(
                $choices,
                { %{$sf->{i}{lyt_3}}, prompt => $prompt , undef => $sf->{i}{back} } # <<
            );
            if ( ! defined $db ) {
                if ( @$new ) {
                    shift @$new;
                    next DB;
                }
                return;
            }
            my $tfr = Term::Form->new();
            $info .= "\nATTACH DATABASE $db AS";

            ALIAS: while ( 1 ) {
                my $alias = $tfr->readline( 'alias: ', { clear_screen => 1, info => $info } );
                if ( ! length $alias ) {
                    last ALIAS;
                }
                elsif ( any { $_->[1] eq $alias } @$cur, @$new ) {
                    my $prompt = $info . "\nalias '$alias' already used:";
                    my $retry = choose(
                        [ undef, 'New alias' ],
                        { %{$sf->{i}{lyt_m}}, prompt => $prompt, undef => 'Back', clear_screen => 1 }
                    );
                    last ALIAS if ! defined $retry;
                    next ALIAS;
                }
                else {
                    push @$new, [ $db, $alias ]; # 2 x $db with different $alias ?
                    last ALIAS;
                }
            }

            NO_OK: while ( 1 ) {
                $info = $root;
                $info .= join( "\n", map { "ATTACH DATABASE $_->[0] AS $_->[1]" } @$cur, @$new );
                my ( $ok, $more ) = ( 'OK', '++' );
                my $choice = choose(
                    [ undef, $ok, $more ],
                    { %{$sf->{i}{lyt_m}}, prompt => $info . "\n\nChoose:", undef => '<<', clear_screen => 1 }
                );
                if ( ! defined $choice ) {
                    if ( @$new > 1 ) {
                        pop @$new;
                        next NO_OK;
                    }
                    return;
                }
                elsif ( $choice eq $ok ) {
                    if ( ! @$new ) {
                        return;
                    }
                    my $h_ref = $ax->read_json( $sf->{i}{file_attached_db} );
                    $h_ref->{$sf->{d}{db}} = [ sort( @$cur, @$new  ) ];;
                    $ax->write_json( $sf->{i}{file_attached_db}, $h_ref );
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
    my $info = 'DB: "' . basename( $sf->{d}{db} ) . "\"";
    my $attached_db;
    if ( -s $sf->{i}{file_attached_db} ) {
        my $h_ref = $ax->read_json( $sf->{i}{file_attached_db} );
        $attached_db = $h_ref->{$sf->{d}{db}} || [];
    }
    my @choices;
    for my $elem ( @$attached_db ) {
        push @choices, sprintf 'DETACH DATABASE %s  (%s)', @$elem[1,0];
    }
    my $idx = choose_a_subset(
        [ @choices ],
        { mouse => $sf->{o}{table}{mouse}, info => $info, index => 1, show_fmt => 1, keep_chosen => 0 }
    ); # prompt
    if ( ! defined $idx || ! @$idx ) {
        return;
    }
    for my $i ( sort { $b <=> $a } @$idx ) {
        my $ref = splice( @$attached_db, $i, 1 );
    }
    my $h_ref = $ax->read_json( $sf->{i}{file_attached_db} );
    if ( @$attached_db ) {
        $h_ref->{$sf->{d}{db}} = $attached_db;
    }
    else {
        delete $h_ref->{$sf->{d}{db}};
    }
    $ax->write_json( $sf->{i}{file_attached_db}, $h_ref );
    return 1;
}





1;

__END__
