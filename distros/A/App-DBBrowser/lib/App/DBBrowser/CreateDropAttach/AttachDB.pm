package # hide from PAUSE
App::DBBrowser::CreateDropAttach::AttachDB;

use warnings;
use strict;
use 5.014;

use List::MoreUtils qw( any );

use Term::Choose         qw();
use Term::Form::ReadLine qw();

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
    my $attached_db;
    if ( -s $sf->{i}{f_attached_db} ) {
        my $h_ref = $ax->read_json( $sf->{i}{f_attached_db} ) // {};
        $attached_db = $h_ref->{$sf->{d}{db}} // [];
    }
    my $old_idx = 1;

    ATTACH: while ( 1 ) {
        my @tmp_info = ( $sf->{d}{db_string} );
        for my $ref ( @$attached_db ) {
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
        my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
        push @tmp_info, "ATTACH DATABASE $db AS";

        ALIAS: while ( 1 ) {
            my $info = join( "\n", @tmp_info );
            $ax->print_sql_info( $info );
            # Readline
            my $alias = $tr->readline( ##
                'alias: ',
                { info => $info, clear_screen => 1 }
            );
            $ax->print_sql_info( $info );
            if ( ! length $alias ) {
                #last ALIAS;
                next ATTACH;
            }
            elsif ( $alias =~ /^(?:main|temp)\z/i ) {
                my $prompt = "Alias '$alias' not allowed.";
                # Choose
                my $retry = $tc->choose(
                    [ undef ],
                    { prompt => $prompt, info => $info, undef => 'Continue with ENTER', clear_screen => 1 }
                );
                next ALIAS;
            }
            elsif ( any { $_->[1] eq $alias } @$attached_db ) {
                my $prompt = "Alias '$alias' already used.";
                # Choose
                my $retry = $tc->choose(
                    [ undef ],
                    { prompt => $prompt, info => $info, undef => 'Continue with ENTER', clear_screen => 1 }
                );
                next ALIAS;
            }
            else {
                push @$attached_db, [ $db, $alias ]; # 2 x $db with different $alias ?
                my @tmp_info = ( $sf->{d}{db_string} );
                push @tmp_info, map { "ATTACH DATABASE $_->[0] AS $_->[1]" } @$attached_db;
                push @tmp_info, '';
                my $info = join( "\n", @tmp_info );
                # Choose
                my $confirm = $tc->choose(
                    [ undef, $sf->{i}{confirm} ],
                    { info => $info, clear_screen => 1, undef => $sf->{i}{back} }
                );
                $ax->print_sql_info( $info );
                if ( ! defined $confirm ) {
                    pop @$attached_db;
                    next ATTACH;
                }
                my $dbh = $sf->{d}{dbh};
                my $stmt = sprintf "ATTACH DATABASE %s AS %s", $dbh->quote_identifier( $db ), $dbh->quote( $alias );
                $dbh->do( $stmt );
                $sf->{i}{db_attached} = 1;
                my $h_ref = $ax->read_json( $sf->{i}{f_attached_db} ) // {};
                $h_ref->{$sf->{d}{db}} = [ sort( @$attached_db ) ];
                $ax->write_json( $sf->{i}{f_attached_db}, $h_ref );
                return 1;
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
    DB: while ( 1 ) {
        my $info = $sf->{d}{db_string};
        my @choices;
        for my $elem ( @$attached_db ) {
            push @choices, sprintf "DETACH DATABASE %s  (%s)", @$elem[1,0];
        }
        my $prompt = 'Your choice:';
        my @pre = ( undef );
        # Choose
        my $idx = $tc->choose(
            [ @pre, @choices ],
            { %{$sf->{i}{lyt_v}}, prompt => $prompt, info => $info, index => 1, undef => $sf->{i}{back} }
        );
        $ax->print_sql_info( $info );
        if ( ! $idx ) {
            return;
        }
        my $dbh = $sf->{d}{dbh};
        my $detached = splice( @$attached_db, $idx - @pre, 1 );
        my @tmp_info = ( $sf->{d}{db_string} );
        push @tmp_info, '';

        push @tmp_info,  sprintf "DETACH DATABASE %s  (%s)", $dbh->quote( $detached->[1] ), $dbh->quote( $detached->[0] );
        $info = join( "\n", @tmp_info );
        # Choose
        my $confirm = $tc->choose(
            [ undef, $sf->{i}{confirm} ],
            { info => $info, clear_screen => 1, undef => $sf->{i}{back} }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $confirm ) {
            $attached_db = [ sort @$attached_db, $detached ];
            next DB;
        }
        my $stmt = sprintf "DETACH DATABASE %s", $dbh->quote( $detached->[1] );
        $dbh->do( $stmt );
        my $h_ref = $ax->read_json( $sf->{i}{f_attached_db} ) // {};
        if ( @$attached_db ) {
            $h_ref->{$sf->{d}{db}} = $attached_db;
        }
        else {
            delete $h_ref->{$sf->{d}{db}};
            $sf->{i}{old_idx_cda} = 1; # no @$attached_db means no Detach-DB menu-entry to return to
            $sf->{i}{db_attached} = 0; # no more databases attached
        }
        $ax->write_json( $sf->{i}{f_attached_db}, $h_ref );
        return 1;
    }
}








1;

__END__
