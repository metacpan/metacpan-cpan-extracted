package # hide from PAUSE
App::DBBrowser::CreateDropAttach;

use warnings;
use strict;
use 5.016;

use Term::Choose qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::CreateDropAttach::AttachDB;
use App::DBBrowser::CreateDropAttach::CreateTable;
use App::DBBrowser::CreateDropAttach::DropTable;
use App::DBBrowser::Opt::DBSet;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $d
    }, $class;
}


sub create_drop_or_attach {
    my ( $sf ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    state $old_idx_cda = 0;

    CREATE_DROP_ATTACH: while ( 1 ) {
        my ( $create_table,    $drop_table,      $create_view,    $drop_view,      $attach_databases, $detach_databases, $db_setting ) = (
             '- Create TABLE', '- Drop TABLE',   '- Create VIEV', '- Drop VIEW',   '- Attach DB',     '- Detach DB',     '  DB Settings'
        );
        my @entries;
        push @entries, $create_table if $sf->{o}{enable}{create_table};
        push @entries, $drop_table   if $sf->{o}{enable}{drop_table};
        push @entries, $create_view  if $sf->{o}{enable}{create_view};
        push @entries, $drop_view    if $sf->{o}{enable}{drop_view};
        if ( $sf->{i}{driver} eq 'SQLite' ) {
            push @entries, $attach_databases;
            push @entries, $detach_databases;
        }
        push @entries, $db_setting   if $sf->{o}{enable}{db_settings};
        if ( ! @entries ) {
            return;
        }
        my $prompt = $sf->{d}{db_string};
        my @pre = ( undef );
        my $menu = [ @pre, @entries ];
        # Choose
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, prompt => $prompt, index => 1, default => $old_idx_cda, undef => '  <=' }
        );
        if ( ! defined $idx || ! defined $menu->[$idx] ) {
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx_cda == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx_cda = 0;
                next CREATE_DROP_ATTACH;
            }
            $old_idx_cda = $idx;
        }
        my $choice = $menu->[$idx];
        if ( $choice =~ /^-\ Create/i ) {
            my $ct = App::DBBrowser::CreateDropAttach::CreateTable->new( $sf->{i}, $sf->{o}, $sf->{d} );
            if ( $choice eq $create_table ) {
                if ( ! eval { $ct->create_table(); 1 } ) {
                    $ax->print_error_message( $@ );
                }
            }
            elsif ( $choice eq $create_view ) {
                if ( ! eval { $ct->create_view(); 1 } ) {
                    $ax->print_error_message( $@ );
                }
            }
            return 1;
        }
        elsif ( $choice =~ /^-\ Drop/i ) {
            my $dt = App::DBBrowser::CreateDropAttach::DropTable->new( $sf->{i}, $sf->{o}, $sf->{d} );
            if ( $choice eq $drop_table ) {
                if ( ! eval { $dt->drop_table(); 1 } ) {
                    $ax->print_error_message( $@ );
                }
            }
            elsif ( $choice eq $drop_view ) {
                if ( ! eval { $dt->drop_view(); 1 } ) {
                    $ax->print_error_message( $@ );
                }
            }
            return 1;
        }
        elsif ( $choice =~ /^-\ (?:Attach|Detach)/ ) {
            my $att = App::DBBrowser::CreateDropAttach::AttachDB->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $changed;
            if ( $choice eq $attach_databases ) {
                if ( ! eval { $changed = $att->attach_db(); 1 } ) {
                    $ax->print_error_message( $@ );
                }
            }
            elsif ( $choice eq $detach_databases ) {
                if ( ! eval { $changed = $att->detach_db(); 1 } ) {
                    $ax->print_error_message( $@ );
                }
            }
            if ( $changed ) {
                return 2;
            }
        }
        elsif ( $choice eq $db_setting ) {
            my $changed;
            if ( ! eval {
                my $db_opt_set = App::DBBrowser::Opt::DBSet->new( $sf->{i}, $sf->{o} );
                $changed = $db_opt_set->database_setting( $sf->{d}{db} );
                1 }
            ) {
                $ax->print_error_message( $@ );
            }
            if ( $changed ) {
                return 3;
            }
        }
    }
}









1;


__END__
