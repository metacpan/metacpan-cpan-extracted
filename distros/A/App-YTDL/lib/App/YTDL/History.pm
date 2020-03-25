package # hide from PAUSE
App::YTDL::History;

use warnings;
use strict;
use 5.010000;

use Exporter qw( import );
our @EXPORT_OK = qw( read_history_files add_uploaders_to_history choose_videos_from_saved_uploaders edit_sticky_file );

use List::MoreUtils  qw( any none );
use LWP::UserAgent   qw();
use Term::ANSIScreen qw( :cursor :screen );
use Term::Choose     qw( choose );

use App::YTDL::Helper qw( read_json write_json );


sub read_history_files {
    my ( $set, $opt ) = @_;
    $set->{sticky}  = {};
    $set->{history} = {};
    if ( $opt->{max_size_history} ) {
        $set->{sticky}  = read_json( $set->{sticky_file} )  // {} if -e $set->{sticky_file};
        $set->{history} = read_json( $set->{history_file} ) // {} if -e $set->{history_file};
    }
}


sub choose_videos_from_saved_uploaders {
    my ( $set, $opt ) = @_;
    my $prompt = 'Chosen:' . "\n";
    my @ids;

    CHANNEL: while ( 1 ) {
        my ( $sticky,  $sticky_url ) = _get_sticky_name_and_url( $set->{sticky} );
        my ( $history, $history_url, $removed_next ) = _get_history_name_and_url( $opt, $set->{history} );

        my $mark = '*';
        my $confirm = '  CONFIRM';
        my $hidden  = 'Your choice:' . $mark;
        my @pre = ( $hidden, undef, $confirm );
        my $available_uploader = _available_uploader( $sticky, $history, $removed_next );
        my $menu = [ @pre, @$available_uploader ];
        # Choose
        my @indexes = choose(
            $menu,
            { prompt => $prompt, layout => 3, index => 1, default => 1,
                undef => '  BACK', meta_items => [ 0 .. $#pre ], include_highlighted => 2 }
        );
        if ( ! defined $indexes[0] || ! defined $menu->[$indexes[0]] ) {
            if ( @ids ) {
                $prompt = 'Channels:' . "\n";
                @ids = ();
                $mark = '*';
                next CHANNEL;
            }
            else {
                return;
                #next MENU;
            }
        }
        else {
            if ( $menu->[$indexes[0]] eq $hidden ) {
                $prompt = 'Chosen:' . "\n";
                @ids = ();
                for my $i ( 0 .. $#$sticky_url ) {
                    $prompt .= sprintf "= %s (%s)\n", $sticky->[$i], $set->{sticky}{$sticky_url->[$i]}{uploader_id};
                    push @ids, $sticky_url->[$i];
                }
                @$sticky_url = ();
                @$sticky     = ();
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
                    $prompt .= sprintf "= %s (%s)\n", $sticky->[$i], $set->{sticky}{$sticky_url->[$i]}{uploader_id};
                    push @ids, splice @$sticky_url, $i, 1;
                               splice @$sticky    , $i, 1;
                }
                else {
                    $i -= @$sticky;
                    $prompt .= sprintf "= %s (%s)\n", $history->[$i], $set->{history}{$history_url->[$i]}{uploader_id};
                    push @ids, splice @$history_url,  $i, 1;
                               splice @$history,      $i, 1;
                               splice @$removed_next, $i, 1;
                }
                $count++;
            }
            $mark = '*';
            return @ids if $confirmed;
        }
    }
}


sub edit_sticky_file {
    my ( $set, $opt ) = @_;
    my ( $sticky,  $sticky_url )  = _get_sticky_name_and_url( $set->{sticky} );
    my ( $history, $history_url ) = _get_history_name_and_url( $opt, $set->{history} );
    my $changed = 0;

    STICKY: while ( 1 ) {
        my @pre = ( undef );
        my $menu = [ @pre, map( "+ $_", @$sticky ), map( "- $_", @$history ) ];
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
                my $uploader_url = $history_url->[$idx];
                $set->{sticky}{$uploader_url} = delete $set->{history}{$uploader_url};
            }
            else {
                my $uploader_url = $sticky_url->[$idx];
                $set->{history}{$uploader_url} = delete $set->{sticky}{$uploader_url};
                $set->{history}{$uploader_url}{timestamp} = time();
            }
            ( $sticky,  $sticky_url )  = _get_sticky_name_and_url( $set->{sticky} );
            ( $history, $history_url ) = _get_history_name_and_url( $opt, $set->{history} );
        }
    }
}



sub _available_uploader {
    my ( $sticky, $history, $removed_next ) = @_;
    my $choices = [ map( "* $_", @$sticky ) ];
    for my $i ( 0 .. $#$history ) {
        push @$choices, "  $history->[$i]" if ! $removed_next->[$i];
        push @$choices, "| $history->[$i]" if   $removed_next->[$i];
    }
    return $choices;
}


sub _get_history_name_and_url {
    my ( $opt, $ref ) = @_;
    my $tmp_name = [];
    my $tmp_url  = [];
    my $tmp_removed_next = [];
    my $count = 0;
    for my $key ( sort { $ref->{$b}{timestamp} <=> $ref->{$a}{timestamp} } keys %$ref ) {
        $count++;
        push @$tmp_name, $ref->{$key}{uploader};
        push @$tmp_url, $key;
        push @$tmp_removed_next, $count >= $opt->{max_size_history} ? 1 : 0;
    }
    my $history_name = [];
    my $history_url  = [];
    my $removed_next = [];
    if ( ! $opt->{sort_history_by_timestamp} ) {
        for my $i ( sort { lc $tmp_name->[$a] cmp lc $tmp_name->[$b] } 0 .. $#$tmp_name ) {
            push @$history_name, $tmp_name->[$i];
            push @$history_url,  $tmp_url->[$i];
            push @$removed_next, $tmp_removed_next->[$i];
        }
    }
    else {
        $history_name = $tmp_name;
        $history_url  = $tmp_url;
        $removed_next = $tmp_removed_next;
    }
    return $history_name, $history_url, $removed_next;
}


sub _get_sticky_name_and_url {
    my ( $ref ) = @_;
    my $sticky_name = [];
    my $sticky_url  = [];
    for my $key ( sort { lc $ref->{$a}{uploader} cmp lc $ref->{$b}{uploader} } keys %$ref ) {
        push @$sticky_name, $ref->{$key}{uploader};
        push @$sticky_url, $key;
    }
    return $sticky_name, $sticky_url;
}


sub add_uploaders_to_history {
    my ( $set, $opt, $data ) = @_;
    for my $ex ( keys %$data ) {
        for my $video_id ( keys %{$data->{$ex}} ) {
            my $uploader    = $data->{$ex}{$video_id}{uploader};
            my $uploader_id = $data->{$ex}{$video_id}{uploader_id};
            return if ! length $uploader_id;
            my $uploader_url;
            if ( $ex eq 'youtube' ) {
                my $user_url    = sprintf 'https://www.youtube.com/user/%s', $uploader_id;
                my $channel_url = sprintf 'https://www.youtube.com/channel/%s', $uploader_id;
                return if any { $user_url eq $_ || $channel_url eq $_ } keys %{$set->{sticky}};
                return if any { $user_url eq $_ || $channel_url eq $_ } keys %{$set->{history}};
                my @type = ( length $uploader_id == 24 ? ( 'channel', 'user' ) : ( 'user', 'channel' ) );
                my $ua = LWP::UserAgent->new(
                    agent         => $opt->{useragent},
                    timeout       => $opt->{timeout},
                    show_progress => 1
                );
                $uploader_url = sprintf 'https://www.youtube.com/%s/%s', $type[0], $uploader_id;
                my $res = $ua->head( $uploader_url );
                print up( 1 ), cldown;
                if ( ! $res->is_success ) {
                    $uploader_url = sprintf 'https://www.youtube.com/%s/%s', $type[1], $uploader_id;
                    my $res = $ua->head( $uploader_url );
                    print up( 1 ), cldown;
                    $uploader_url = undef if ! $res->is_success;
                }
            }
            elsif ( $ex eq 'vimeo' ) {
                $uploader_url = 'https://vimeo.com/' . $uploader_id;
            }
            if ( defined $uploader_url ) {
                if ( none{ $uploader_url eq $_ } keys %{$set->{sticky}} ) {
                    $set->{history}{$uploader_url} = {
                        uploader     => $uploader,
                        uploader_id  => $uploader_id,
                        extractor    => $ex,
                        timestamp    => time(),
                    };
                }
            }
        }
    }
    my $c_hist = $set->{history};
    my @keys = sort { $c_hist->{$b}{timestamp} <=> $c_hist->{$a}{timestamp} } keys %$c_hist;
    while ( @keys > $opt->{max_size_history} ) {
        my $key = pop @keys;
        delete $c_hist->{$key};
        @keys = sort { $c_hist->{$b}{timestamp} <=> $c_hist->{$a}{timestamp} } keys %$c_hist;
    }
    write_json( $set->{history_file}, $c_hist );
}




1;


__END__
