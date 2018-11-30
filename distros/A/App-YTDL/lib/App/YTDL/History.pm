package # hide from PAUSE
App::YTDL::History;

use warnings;
use strict;
use 5.010000;

use Exporter qw( import );
our @EXPORT_OK = qw( read_history_files uploader_history_menu add_uploaders_to_history );

use List::MoreUtils  qw( any none );
use LWP::UserAgent   qw();
use Term::ANSIScreen qw( :cursor :screen );
use Term::Choose     qw( choose );

use App::YTDL::Helper qw( read_json write_json );


sub read_history_files {
    my ( $opt ) = @_;
    $opt->{sticky}  = {};
    $opt->{history} = {};
    if ( $opt->{max_size_history} ) {
        $opt->{sticky}  = read_json( $opt, $opt->{sticky_file} )  // {} if -e $opt->{sticky_file};
        $opt->{history} = read_json( $opt, $opt->{history_file} ) // {} if -e $opt->{history_file};
    }
}


sub uploader_history_menu {
    my ( $opt ) = @_;

    MENU : while ( 1 ) {
        #my @list_size = ( '  ALL', '  50' );
        #my $list_size_regexp = join '|', map { quotemeta } @list_size;
        my ( $uploader, $sticky ) = ( '- Uploader', '  Sticky' );
        # Choose
        my $choice = choose(
            [ undef, $uploader, $sticky ],                                        # , $list_size[$opt->{small_list_size}
            { prompt => 'Choose:', layout => 3, undef => '  QUIT' }
        );
        if ( ! defined $choice ) {
            exit;
        }
        elsif ( $choice eq $uploader ) {
            my ( $sticky,  $sticky_url ) = _sticky_name_and_url( $opt->{sticky} );
            my ( $history, $history_url, $removed_next ) = _history_name_and_url( $opt, $opt->{history} );
            my $prompt = 'Chosen:' . "\n";
            my @ids;
            my $mark = '*';

            CHANNEL: while ( 1 ) {
                my $confirm = '  CONFIRM';
                my $hidden  = 'Your choice:' . $mark;
                my @pre = ( $hidden, undef, $confirm );
                my $choices = _available_uploader( \@pre, $sticky, $history, $removed_next );
                # Choose
                my @indexes = choose(
                    $choices,
                    { prompt => $prompt, layout => 3, index => 1, default => 1,
                        undef => '  BACK', meta_items => [ 0 .. $#pre ], include_highlighted => 2 }
                );
                if ( ! defined $indexes[0] || ! defined $choices->[$indexes[0]] ) {
                    if ( @ids ) {
                        $prompt = 'Channels:' . "\n";
                        ( $sticky,  $sticky_url ) = _sticky_name_and_url( $opt->{sticky} );
                        ( $history, $history_url, $removed_next ) = _history_name_and_url( $opt, $opt->{history} );
                        @ids = ();
                        $mark = '*';
                        next CHANNEL;
                    }
                    else {
                        next MENU;
                    }
                }
                else {
                    if ( $choices->[$indexes[0]] eq $hidden ) {
                        $prompt = 'Chosen:' . "\n";
                        ( $sticky,  $sticky_url ) = _sticky_name_and_url( $opt->{sticky} );
                        ( $history, $history_url, $removed_next ) = _history_name_and_url( $opt, $opt->{history} );
                        @ids = ();
                        for my $i ( 0 .. $#$sticky_url ) {
                            $prompt .= sprintf "= %s (%s)\n", $sticky->[$i], $opt->{sticky}{$sticky_url->[$i]}{uploader_id};
                            push @ids, $sticky_url->[$i];
                        }
                        @$sticky_url = ();
                        @$sticky     = ();
                        $mark = '';
                        next CHANNEL;
                    }
                    my $confirmed;
                    if ( $choices->[$indexes[0]] eq $confirm ) {
                        shift @indexes;
                        $confirmed = 1;
                    }
                    my $count = 0;
                    for my $i ( @indexes ) {
                        $i -= @pre + $count;
                        if ( $i <= $#$sticky ) {
                            $prompt .= sprintf "= %s (%s)\n", $sticky->[$i], $opt->{sticky}{$sticky_url->[$i]}{uploader_id};
                            push @ids, splice @$sticky_url, $i, 1;
                                       splice @$sticky    , $i, 1;
                        }
                        else {
                            $i -= @$sticky;
                            $prompt .= sprintf "= %s (%s)\n", $history->[$i], $opt->{history}{$history_url->[$i]}{uploader_id};
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
        elsif ( $choice eq $sticky ) {
            my ( $sticky,  $sticky_url )  = _sticky_name_and_url( $opt->{sticky} );
            my ( $history, $history_url ) = _history_name_and_url( $opt, $opt->{history} );
            my $changed = 0;

            STICKY: while ( 1 ) {
                my @pre = ( undef );
                my $idx = choose(
                    [ @pre, map( "+ $_", @$sticky ), map( "- $_", @$history ) ],
                    { prompt => 'Stickify:', layout => 3, index => 1, undef => '  <<' }
                );
                if ( ! $idx ) {
                    if ( $changed ) {
                        write_json( $opt, $opt->{sticky_file},  $opt->{sticky} );
                        write_json( $opt, $opt->{history_file}, $opt->{history} );
                    }
                    next MENU;
                }
                else {
                    $changed++;
                    $idx-= @pre;
                    if ( $idx > $#$sticky ) {
                        $idx -= @$sticky;
                        my $uploader_url = $history_url->[$idx];
                        $opt->{sticky}{$uploader_url} = delete $opt->{history}{$uploader_url};
                    }
                    else {
                        my $uploader_url = $sticky_url->[$idx];
                        $opt->{history}{$uploader_url} = delete $opt->{sticky}{$uploader_url};
                        $opt->{history}{$uploader_url}{timestamp} = time();
                    }
                    ( $sticky,  $sticky_url )  = _sticky_name_and_url( $opt->{sticky} );
                    ( $history, $history_url ) = _history_name_and_url( $opt, $opt->{history} );
                }
            }
        }
        #if ( $choice =~ /^$list_size_regexp\z/ ) {
        #    $opt->{small_list_size}++;
        #    $opt->{small_list_size} = 0 if $opt->{small_list_size} > $#list_size;
        #    next MENU;
        #}
    }
}


sub _available_uploader {
    my ( $pre, $sticky, $history, $removed_next ) = @_;
    my $choices = [ @$pre, map( "* $_", @$sticky ) ];
    for my $i ( 0 .. $#$history ) {
        push @$choices, "  $history->[$i]" if ! $removed_next->[$i];
        push @$choices, "| $history->[$i]" if   $removed_next->[$i];
    }
    return $choices;
}


sub _history_name_and_url {
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


sub _sticky_name_and_url {
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
    my ( $opt, $info ) = @_;
    for my $ex ( keys %$info ) {
        for my $video_id ( keys %{$info->{$ex}} ) {
            my $uploader    = $info->{$ex}{$video_id}{uploader};
            my $uploader_id = $info->{$ex}{$video_id}{uploader_id};
            return if ! length $uploader_id;
            my $uploader_url;
            if ( $ex eq 'youtube' ) {
                my $user_url    = sprintf 'https://www.youtube.com/user/%s', $uploader_id;
                my $channel_url = sprintf 'https://www.youtube.com/channel/%s', $uploader_id;
                return if any { $user_url eq $_ || $channel_url eq $_ } keys %{$opt->{sticky}};
                return if any { $user_url eq $_ || $channel_url eq $_ } keys %{$opt->{history}};
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
                if ( none{ $uploader_url eq $_ } keys %{$opt->{sticky}} ) {
                    $opt->{history}{$uploader_url} = {
                        uploader     => $uploader,
                        uploader_id  => $uploader_id,
                        extractor    => $ex,
                        timestamp    => time(),
                    };
                }
            }
        }
    }
    my $c_hist = $opt->{history};
    my @keys = sort { $c_hist->{$b}{timestamp} <=> $c_hist->{$a}{timestamp} } keys %$c_hist;
    while ( @keys > $opt->{max_size_history} ) {
        my $key = pop @keys;
        delete $c_hist->{$key};
        @keys = sort { $c_hist->{$b}{timestamp} <=> $c_hist->{$a}{timestamp} } keys %$c_hist;
    }
    write_json( $opt, $opt->{history_file}, $c_hist );
}




1;


__END__
