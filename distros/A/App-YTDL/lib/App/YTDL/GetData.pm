package # hide from PAUSE
App::YTDL::GetData;

use warnings;
use strict;
use 5.010000;

use Exporter qw( import );
our @EXPORT_OK = qw( get_vimeo_list_info get_youtube_list_info get_download_info );

use JSON             qw( decode_json );
use LWP::UserAgent   qw();
use Mojo::DOM        qw();
use Term::ANSIScreen qw( :screen );

use App::YTDL::ExtractData  qw( json_to_hash );
use App::YTDL::Helper       qw( uni_capture HIDE_CURSOR SHOW_CURSOR );
use App::YTDL::LWPUserAgent qw();


sub get_youtube_list_info {
    my ( $opt, $url ) = @_;
    my $ua = App::YTDL::LWPUserAgent->new(
        agent         => $opt->{useragent},
        timeout       => $opt->{timeout},
        show_progress => 1
    );
    my $tmp = [];
    my $next;
    my $count = 0;

    RETRY: while ( 1 ) {
        $count++;
        if ( eval {
            $ua->{page} = 1;
            my $res = $ua->get( $url );
            die $res->status_line, ': ', $url if ! $res->is_success;
            my $content = $res->decoded_content;
            my $dom = Mojo::DOM->new( $content );
            my $uploader;
            my $el_uploader = $dom->at( 'meta[itemprop="name"][content]' );
            if ( $el_uploader ) {
                $uploader = $el_uploader->attr( 'content' );
            }
            _parse_yt_list_html( $content, $uploader, $tmp );
            my $load_more_widget_html;
            my $more_button = $dom->at( 'button[class*="browse-items-load-more-button"][data-uix-load-more-href]' );
            if ( $more_button ) {
                $load_more_widget_html = $more_button->to_string;
            }
            my $redo_count = {};

            PAGE: while ( $load_more_widget_html ) {
                my $url;
                if ( $load_more_widget_html =~ /data-uix-load-more-href="([^"]+)"/ ) {
                    $url = sprintf 'https://www.youtube.com%s', $1;
                }
                last PAGE if ! $url; # die "more_button: could not extract url!";
                $ua->{page}++;
                my $next_res = $ua->get( $url );
                my $h_ref = decode_json( $next_res->decoded_content );
                if ( ! defined $h_ref->{content_html} || $h_ref->{content_html} !~ /\S/ ) { # ?
                    my $page = $ua->{page};
                    $redo_count->{$page}++;
                    if ( $redo_count->{$page} > $opt->{retries} ) {
                        last PAGE;
                    }
                    sleep $redo_count->{$page};
                    redo PAGE;
                }
                my $content = '<!DOCTYPE html><html>' . $h_ref->{content_html} . '</html>';
                _parse_yt_list_html( $content, $uploader, $tmp );
                if ( $opt->{list_type_youtube} == 2 ) {
                   $#$tmp = 49 if @$tmp > 50;
                   last PAGE;
                }
                $load_more_widget_html = $h_ref->{load_more_widget_html};
            }
            1 }
        ) {
            print SHOW_CURSOR;
            return $tmp;
        }
        else {
            if ( $count > $opt->{retries} ) {
                return;
            }
            say "$count/$opt->{retries}  $@";
            sleep $opt->{retries} * 3;
        }
    }
}


sub _parse_yt_list_html {
    my ( $content, $uploader, $tmp ) = @_;
    my $date_sort = @$tmp;
    my $dom = Mojo::DOM->new( $content );
    $dom->find( 'li[class*="channels-content-item yt-shelf-grid-item"]' )
        ->each(
            sub {
                my $entry = {
                    uploader  => $uploader,
                    date_sort => ++$date_sort,
                };

                my $el_id_and_title = $_->at( 'h3[class*="yt-lockup-title"] > a[class]' );
                if ( ! defined $el_id_and_title ) {
                    die "\$el_id_and_title not defined!";
                }
                $entry->{video_id} = $el_id_and_title->attr( 'href' );
                if ( ! defined $entry->{video_id} ) {
                    die "1 \$entry->{video_id} not defined!";
                }
                if ( $entry->{video_id} =~ m/=([^=]{11})\z/ ) {
                    $entry->{video_id} = $1;
                }
                if ( ! defined $entry->{video_id} ) {
                    die "2 \$entry->{video_id} not defined!";
                }
                $entry->{title} = $el_id_and_title->attr( 'title' );
                my $el_duration = $_->at(  'span[class*="video-time"] > span' );
                if ( $el_duration ) {
                    my $duration = $el_duration->text;
                    if ( $duration && $duration =~ /^(?:\d\d?:){0,2}\d\d?\z/ ) {
                        my $seconds = 0;
                        my @u = ( 1, 60, 3600 );
                        my @parts = reverse split ':', $duration;
                        for my $i ( 0 .. $#parts ) {
                            $seconds += $parts[$i] * $u[$i];
                        }
                        $entry->{duration} = $seconds if $seconds;
                    }
                }
                my $el_view_count = $_->find( 'ul[class*="yt-lockup-meta-info"] > li' )->[0];
                if ( $el_view_count ) {
                    $entry->{view_count} = $el_view_count->text;
                    #$entry->{view_count} =~ s/^([0-9.,]+).+\z/$1/;
                    $entry->{view_count} =~ s/^(?:<li>)?([0-9.,]+).+\z/$1/;
                    $entry->{view_count} =~ s/[,.]//g;
                }
                my $el_upload_date_rel = $_->find( 'ul[class*="yt-lockup-meta-info"] > li' )->[1];
                if ( $el_upload_date_rel ) {
                    $entry->{upload_date_rel} = $el_upload_date_rel->text;
                }
                $entry->{webpage_url} = sprintf( 'https://www.youtube.com/watch?v=%s', $entry->{video_id} ) if $entry->{video_id};
                push @$tmp, $entry;
            }
        );
}


sub get_vimeo_list_info {
    my ( $opt, $url ) = @_;
    my $ua = LWP::UserAgent->new(
        agent         => $opt->{useragent},
        timeout       => $opt->{timeout},
        show_progress => 1
    );
    my $tmp = [];
    my $next;
    my $count = 0;

    RETRY: while ( 1 ) {
        $count++;
        if ( eval {
            my $res = $ua->get( $url );
            die $res->status_line, ': ', $url if ! $res->is_success;
            my $dom = Mojo::DOM->new( $res->decoded_content );
            my $uploader;
            my $el_uploader = $dom->at( 'a[class="user"]' );
            if ( $el_uploader ) {
                $uploader = $el_uploader->text;
            }
            $dom->find( 'div[id="browse_content"] > ol > li[id][data-position]' )
                ->each(
                    sub {
                        my $video_id = $_->attr( 'id' );
                        $video_id =~ s/^clip_//;
                        my $entry = {
                            video_id => $video_id,
                            uploader => $uploader,
                        };
                        $entry->{webpage_url} = sprintf( 'https://vimeo.com/%s', $video_id ) if $video_id;
                        my $el_title = $_->at( 'a' );
                        if ( $el_title ) {
                            $entry->{title} = $el_title->attr( 'title' );
                        }
                        my $el_upload_date = $_->at( 'time' );
                        if ( $el_upload_date ) {
                            $entry->{upload_date} = $el_upload_date->attr( 'datetime' );
                        }
                        push @$tmp, $entry;
                    }
                );
            $next = $dom->at( 'a[rel="next"]' ) ? 1 : 0;
            1 }
        ) {
            return $tmp, $next;
        }
        else {
            if ( $count > $opt->{retries} ) {
                return;
            }
            say "$count/$opt->{retries}  $@";
            sleep $opt->{retries} * 3;
        }
    }
}


sub get_download_info {
    my ( $set, $opt, $webpage_url, $message ) = @_;
    my @cmd = @{$set->{youtube_dl}};
    push @cmd, '--youtube-skip-dash-manifest';
    push @cmd, '--dump-json', '--', $webpage_url;
    my $json_all;
    my $count = 0;

    RETRY: while ( 1 ) {
        $count++;
        if ( eval {
            print HIDE_CURSOR;
            print $message . '...';
            $json_all = uni_capture( @cmd );
            print "\r", clline;
            print $message . "done.\n";
            print SHOW_CURSOR;
            die $webpage_url . ' - no JSON!' if ! $json_all;
            1 }
        ) {
            last RETRY;
        }
        else {
            print SHOW_CURSOR;
            if ( $count > $opt->{retries} ) {
                push @{$set->{error_get_download_infos}}, $webpage_url; # $ex
                return;
            }
            say "$count/$opt->{retries}  $webpage_url: $@";
            sleep $opt->{retries} * 3;
        }
    }
    $set->{up}++;
    my $tmp = json_to_hash( $json_all );
    return $tmp
}




1;


__END__
