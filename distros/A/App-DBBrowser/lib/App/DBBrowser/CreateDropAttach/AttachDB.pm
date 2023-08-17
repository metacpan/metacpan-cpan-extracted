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
    my ( $class, $info, $options, $d ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $d
    }, $class;
}


sub attach_db {
    my ( $sf ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $attached_db;
    if ( -s $sf->{i}{f_attached_db} ) {
        my $h_ref = $ax->read_json( $sf->{i}{f_attached_db} ) // {};
        $attached_db = $h_ref->{$sf->{d}{db}} // {};
    }
    my $dbh = $sf->{d}{dbh};
    my $old_idx = 0;

    ATTACH: while ( 1 ) {
        my @tmp_info = ( $sf->{d}{db_string} );
        for my $key ( sort keys %$attached_db ) {
            push @tmp_info, __attach_stmt( $dbh, $attached_db->{$key}, $key );
        }
        push @tmp_info, '';
        my @pre = ( undef );
        my @choices = ( @{$sf->{d}{user_dbs}}, @{$sf->{d}{sys_dbs}} );
        my $menu = [ @pre, @choices ];
        my $info = join( "\n", @tmp_info );
        # Choose
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, prompt => "Add database:", info => $info,
                undef => '<=', index => 1, default => $old_idx }
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
        push @tmp_info, 'DB: ' . $db;
        my $bu_attached_db = { %$attached_db };

        ALIAS: while ( 1 ) {
            my $info = join( "\n", @tmp_info );
            $ax->print_sql_info( $info );
            # Readline
            my $alias = $tr->readline(
                'Alias: ',
                { info => $info, clear_screen => 1, history => [ 'a' .. 'z' ] }
            );
            $ax->print_sql_info( $info );
            if ( ! length $alias ) {
                next ATTACH;
            }
            else {
                $attached_db->{$alias} = $db;
                my @tmp_info = ( $sf->{d}{db_string} );
                push @tmp_info, map { __attach_stmt( $dbh, $attached_db->{$_}, $_ ) } sort keys %$attached_db;
                push @tmp_info, '';
                my $info = join( "\n", @tmp_info );
                # Choose
                my $confirm = $tc->choose(
                    [ undef, $sf->{i}{confirm} ],
                    { info => $info, clear_screen => 1, undef => $sf->{i}{back} }
                );
                $ax->print_sql_info( $info );
                if ( ! defined $confirm ) {
                    $attached_db = $bu_attached_db;
                    next ALIAS;
                }
                my $h_ref = $ax->read_json( $sf->{i}{f_attached_db} ) // {};
                $h_ref->{$sf->{d}{db}} = $attached_db;
                $ax->write_json( $sf->{i}{f_attached_db}, $h_ref );
                return 1;
            }
        }
    }
}



sub __attach_stmt {
    my ( $dbh, $db, $alias ) = @_;
    return sprintf "ATTACH DATABASE %s AS %s", $dbh->quote_identifier( $db ), $dbh->quote( $alias );
}


sub detach_db {
    my ( $sf ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $attached_db;
    if ( -s $sf->{i}{f_attached_db} ) {
        my $h_ref = $ax->read_json( $sf->{i}{f_attached_db} ) // {};
        $attached_db = $h_ref->{$sf->{d}{db}} // {};
    }
    if ( ! %$attached_db ) {
        my $info = $sf->{d}{db_string};
        my $prompt = 'No attached databases.';
        my $table = $tc->choose(
            [ undef ],
            { info => $info, prompt => $prompt, undef => '<<' }
        );
        return;
    }
    my $old_idx = 0;

    DETACH: while ( 1 ) {
        my $info = $sf->{d}{db_string};
        my @choices;
        my @aliases = ( sort keys %$attached_db );
        for my $key ( @aliases ) {
            push @choices, sprintf "%s  (%s)", $key, $attached_db->{$key};
        }
        my $prompt = 'Detach database:';
        my @pre = ( undef );
        # Choose
        my $idx = $tc->choose(
            [ @pre, @choices ],
            { %{$sf->{i}{lyt_v}}, prompt => $prompt, info => $info, index => 1, undef => '<=', default => $old_idx }
        );
        $ax->print_sql_info( $info );
        if ( ! $idx ) {
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx = 0;
                next DETACH;
            }
            $old_idx = $idx;
        }
        my $detached_alias = $aliases[$idx - @pre];
        my $detached_db = delete $attached_db->{$detached_alias};
        my $dbh = $sf->{d}{dbh};
        $prompt = sprintf "DETACH DATABASE %s  (%s)", $dbh->quote( $detached_alias ), $dbh->quote_identifier( $detached_db );
        # Choose
        my $confirm = $tc->choose(
            [ undef, 'YES' ],
            { info => $info, prompt => $prompt, clear_screen => 1, undef => 'NO' }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $confirm ) {
            $attached_db->{$detached_alias} = $detached_db;
            next DETACH;
        }
        my $h_ref = $ax->read_json( $sf->{i}{f_attached_db} ) // {};
        if ( %$attached_db ) {
            $h_ref->{$sf->{d}{db}} = $attached_db;
        }
        else {
            delete $h_ref->{$sf->{d}{db}};
        }
        $ax->write_json( $sf->{i}{f_attached_db}, $h_ref );
        return 1;
    }
}








1;

__END__
