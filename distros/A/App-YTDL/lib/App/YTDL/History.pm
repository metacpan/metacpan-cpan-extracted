package # hide from PAUSE
App::YTDL::History;

use warnings;
use strict;
use 5.010000;

use Exporter qw( import );
our @EXPORT_OK = qw( read_history_files add_uploaders_to_history choose_videos_from_saved_uploaders edit_sticky_file );

use List::MoreUtils qw( any );
use Term::Choose    qw( choose );

use App::YTDL::Helper qw( read_json write_json );


sub read_history_files {
    my ( $set, $opt ) = @_;
    $set->{sticky}  = {};
    $set->{history} = {};
    if ( $opt->{max_size_history} ) {
        if ( -e $set->{sticky_file} ) {
            $set->{sticky}  = read_json( $set->{sticky_file} )  // {};

            # ### ############################################################ ### # remove that after a while
            my @keys = keys %{$set->{sticky}};                                     # added 0.401
            if ( @keys && $keys[0] =~ /^https?:/ ) {
                $set->{sticky} = _old_file_fmt_to_new_file_fmt( $set->{sticky} );
                write_json( $set->{sticky_file},  $set->{sticky} );
            }
            # ### ############################################################ ### #

        }
        if ( -e $set->{history_file} ) {
            $set->{history} = read_json( $set->{history_file} ) // {};

            # ### ############################################################ ### # remove that after a while
            my @keys = keys %{$set->{history}};                                    # added 0.401
            if ( @keys && $keys[0] =~ /^https?:/ ) {
                $set->{history} = _old_file_fmt_to_new_file_fmt( $set->{history} );
                write_json( $set->{history_file}, $set->{history} );
            }
            # ### ############################################################ ### #

        }
    }
}

sub _old_file_fmt_to_new_file_fmt { # ### # remove that after a while # added 0.401
    my ( $h_ref ) = @_;
    my $new_h_ref = {};
    for my $key ( keys %$h_ref ) {
        my $uploader_url  = $key;
        my $uploader_id   = $h_ref->{$uploader_url}{uploader_id};
        my $uploader      = $h_ref->{$uploader_url}{uploader};
        my $extractor_key = $h_ref->{$uploader_url}{extractor};
        my $timestamp     = $h_ref->{$uploader_url}{timestamp};
        $new_h_ref->{$uploader_id} = {
            uploader_url  => $uploader_url,
            uploader      => $uploader,
            extractor_key => $extractor_key,
            timestamp     => $timestamp,
        };
    }
    return $new_h_ref;
}


sub choose_videos_from_saved_uploaders {
    my ( $set, $opt ) = @_;
    my $truncated = _to_history_size_limit( $set, $opt );
    if ( $truncated ) {
        write_json( $set->{history_file}, $set->{history} );
    }
    my $prompt = 'Chosen:' . "\n";
    my @urls;
    my $sticky  = _get_sorted_sticky( $set->{sticky} );
    my $history = _get_sorted_history( $opt, $set->{history} );

    CHANNEL: while ( 1 ) {
        my $mark = '*';
        my $confirm = '  CONFIRM';
        my $hidden  = 'Your choice:' . $mark;
        my @pre = ( $hidden, undef, $confirm );
        my $available_uploader = _available_uploader( $set, $opt, $sticky, $history );
        my $menu = [ @pre, @$available_uploader ];
        # Choose
        my @indexes = choose(
            $menu,
            { prompt => $prompt, layout => 3, index => 1, default => 1,
                undef => '  BACK', meta_items => [ 0 .. $#pre ], include_highlighted => 2 }
        );
        if ( ! defined $indexes[0] || ! defined $menu->[$indexes[0]] ) {
            if ( @urls ) {
                $prompt = 'Channels:' . "\n";
                @urls = ();
                $sticky  = _get_sorted_sticky( $set->{sticky} );
                $history = _get_sorted_history( $opt, $set->{history} );
                $mark = '*';
                next CHANNEL;
            }
            else {
                return;
            }
        }
        elsif ( $menu->[$indexes[0]] eq $hidden ) {
            for my $i ( 0 .. $#$sticky ) {
                $prompt .= sprintf "= %s (%s)\n", $sticky->[$i]{uploader}, $sticky->[$i]{uploader_id};
                push @urls, $sticky->[$i]{uploader_url};
            }
            @$sticky = ();
            $mark = '';
            next CHANNEL;
        }
        my $confirmed;
        if ( $menu->[$indexes[0]] eq $confirm ) {
            shift @indexes;
            $confirmed = 1;
        }
        my $count = 0;
        for my $i ( @indexes ) {
            $i -= @pre + $count;
            if ( $i <= $#$sticky ) {
                $prompt .= sprintf "= %s (%s)\n", $sticky->[$i]{uploader}, $sticky->[$i]{uploader_id};
                push @urls, $sticky->[$i]{uploader_url};
                splice @$sticky, $i, 1;
            }
            else {
                $i -= @$sticky;
                $prompt .= sprintf "= %s (%s)\n", $history->[$i]{uploader}, $history->[$i]{uploader_id};
                push @urls, $history->[$i]{uploader_url};
                splice @$history, $i, 1;

            }
            $count++;
        }
        $mark = '*';
        if ( $confirmed ) {
            return @urls;
        }
    }
}


sub edit_sticky_file {
    my ( $set, $opt ) = @_;
    my $sticky  = _get_sorted_sticky( $set->{sticky} );
    my $history = _get_sorted_history( $opt, $set->{history} );
    my $changed = 0;

    STICKY: while ( 1 ) {
        my @pre = ( undef );
        my $menu = [ @pre, map( "+ $_->{uploader}", @$sticky ), map( "- $_->{uploader}", @$history ) ];
        # Choose
        my $idx = choose(
            $menu,
            { prompt => 'Stickify:', layout => 3, index => 1, undef => '  <<' }
        );
        if ( ! defined $idx || ! defined $menu->[$idx] ) {
            if ( $changed ) {
                write_json( $set->{sticky_file},  $set->{sticky} );
                write_json( $set->{history_file}, $set->{history} );
            }
            return;
        }
        else {
            $changed++;
            $idx-= @pre;
            if ( $idx > $#$sticky ) {
                $idx -= @$sticky;
                my $up = $history->[$idx]{uploader_id};
                $set->{sticky}{$up} = delete $set->{history}{$up};
            }
            else {
                my $up = $sticky->[$idx]{uploader_id};
                $set->{history}{$up} = delete $set->{sticky}{$up};
                $set->{history}{$up}{timestamp} = time();
            }
            $sticky  = _get_sorted_sticky( $set->{sticky} );
            $history = _get_sorted_history( $opt, $set->{history} );
        }
    }
}


sub _uploader_id_removed_next {
    my ( $set, $opt ) = @_;
    my $amount = 3;
    if ( ! $opt->{max_size_history} || $opt->{max_size_history} - $amount > keys %{$set->{history}} ) {
        return;
    }
    my $removed_next = [];
    my $last_added   = [];
    my $count = 0;
    for my $key ( sort { $set->{history}{$b}{timestamp} <=> $set->{history}{$a}{timestamp} } keys %{$set->{history}} ) {
        $count++;
        if ( $count > $opt->{max_size_history} - $amount ) {
            push @$removed_next, $key;
        }
    }
    return $removed_next;
}


sub _available_uploader {
    my ( $set, $opt, $sticky, $history ) = @_;
    my $choices = [ map( "* $_->{uploader}", @$sticky ) ];
    my $removed_next = _uploader_id_removed_next( $set, $opt );
    for my $i ( 0 .. $#$history ) {
        if ( any { $history->[$i]{uploader_id} eq $_ } @$removed_next ) {
            push @$choices, "| $history->[$i]{uploader}";
        }
        else {
            push @$choices, "  $history->[$i]{uploader}";
        }
    }
    return $choices;
}


sub _get_sorted_history {
    my ( $opt, $ref ) = @_;
    my $history = [];
    for my $key ( sort { $opt->{sort_history_by_timestamp} ?
                               $ref->{$b}{timestamp} <=>    $ref->{$a}{timestamp}
                          : lc $ref->{$a}{uploader}  cmp lc $ref->{$b}{uploader}  } keys %$ref
    ) {
        push @$history, {
            uploader_id  => $key,
            uploader     => $ref->{$key}{uploader},
            uploader_url => $ref->{$key}{uploader_url},
        };
    }
    return $history;
}


sub _get_sorted_sticky {
    my ( $ref ) = @_;
    my $sticky;
    for my $key ( sort { lc $ref->{$a}{uploader} cmp lc $ref->{$b}{uploader} } keys %$ref ) {
        push @$sticky, {
            uploader_id  => $key,
            uploader     => $ref->{$key}{uploader},
            uploader_url => $ref->{$key}{uploader_url},
        };
    }
    return $sticky;
}


sub add_uploaders_to_history {
    my ( $set, $opt, $data ) = @_;

    EXTRACTOR_KEY: for my $ex ( keys %$data ) {

        UPLOADER_ID: for my $up ( keys %{$data->{$ex}} ) {
            if ( $up eq 'no_up_id' ) {
                return;
            }
            if ( exists $set->{sticky}{$up} ) {
                return;
            }
            my @keys = ( keys %{$data->{$ex}{$up}} );
            my $id = $keys[0];
            $set->{history}{$up} = {
                uploader      => $data->{$ex}{$up}{$id}{uploader},
                uploader_url  => $data->{$ex}{$up}{$id}{uploader_url},
                extractor_key => $ex,
                timestamp     => time(),
            };
        }
    }
    _to_history_size_limit( $set, $opt );
    write_json( $set->{history_file}, $set->{history} );
}


sub _to_history_size_limit {
    my ( $set, $opt ) = @_;
    my @keys = sort { $set->{history}{$b}{timestamp} <=> $set->{history}{$a}{timestamp} } keys %{$set->{history}};
    my $truncated = 0;
    while ( @keys > $opt->{max_size_history} ) {
        my $key = pop @keys;
        delete $set->{history}{$key};
        @keys = sort { $set->{history}{$b}{timestamp} <=> $set->{history}{$a}{timestamp} } keys %{$set->{history}};
        $truncated++;
    }
    return $truncated;
}



1;


__END__
