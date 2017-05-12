package # hide from PAUSE
App::YTDL::Download;

use warnings;
use strict;
use 5.010000;

use Exporter qw( import );
our @EXPORT_OK = qw( download_youtube is_in_download_archive );

use File::Basename        qw( basename );
use File::Spec::Functions qw( catfile );
use Time::HiRes           qw( gettimeofday tv_interval );

use Encode::Locale     qw();
use List::MoreUtils    qw( any );
use LWP::UserAgent     qw();
use Term::ANSIScreen   qw( :cursor :screen );
use Term::Choose::Util qw( insert_sep );

use if $^O eq 'MSWin32', 'Win32::Console::ANSI';

use App::YTDL::GetData qw( get_new_video_url );
use App::YTDL::Helper  qw( sec_to_time encode_fs check_mapping_stdout timestamp_to_upload_date HIDE_CURSOR SHOW_CURSOR
                           read_json write_json format_bytes_per_sec );

END { print SHOW_CURSOR }



sub download_youtube {
    my ( $opt, $info ) = @_;
    my $nr = 0;
    for my $ex ( sort keys %$info ) {
        for my $video_id ( sort { $info->{$ex}{$a}{count} <=> $info->{$ex}{$b}{count} } keys %{$info->{$ex}} ) {
            for my $fmt ( sort keys %{$info->{$ex}{$video_id}{file_name}} ) {
                my $file_name = $info->{$ex}{$video_id}{file_name}{$fmt};
                $nr++;
                if ( $opt->{skip_archived_videos} && is_in_download_archive( $opt, $info, $ex, $video_id, $fmt ) ) {
                    push @{$opt->{skipped_archived_videos}}, sprintf "%s - %s", $video_id, $info->{$ex}{$video_id}{title}; #
                    my $video_count = sprintf "%*s from %s", length $opt->{nr_videos}, $nr, $opt->{nr_videos};
                    printf "  %s\n", '-' x length $video_count if $nr > 1;
                    printf "  %s (%s)\n", check_mapping_stdout( $opt, basename $file_name ), $info->{$ex}{$video_id}{duration} // '?';
                    printf "  %s   Skipped (download archive)\n", $video_count;
                    next;
                }
                if ( ! eval {
                    unlink encode_fs( $opt, $file_name ) or die encode_fs( $opt, $file_name ) . " $!" if $opt->{overwrite} && -f encode_fs( $opt, $file_name );
                    my $ok = _download_video( $opt, $info, $ex, $video_id, $fmt, $nr );
                    timestamp_to_upload_date( $opt, $info, $ex, $video_id, $file_name )               if $opt->{modify_timestamp};
                    _archive_download(  $opt, $info, $ex, $video_id, $fmt )                           if $opt->{enable_download_archive} && $ok && $ok == 1;
                    1 }
                ) {
                    say "$video_id - ", check_mapping_stdout( $opt, $@ );
                }
            }
        }
    }
    return;
}


sub _download_video {
    my ( $opt, $info, $ex, $video_id, $fmt, $nr ) = @_;
    my $file_name = $info->{$ex}{$video_id}{file_name}{$fmt};
    my $ua = LWP::UserAgent->new(
        agent         => $opt->{useragent},
        timeout       => $opt->{timeout},
        show_progress => 0,
    );
    print HIDE_CURSOR;
    my $video_count = sprintf "%*s from %s", length $opt->{nr_videos}, $nr, $opt->{nr_videos};
    printf "  %s\n", '-' x length $video_count if $nr > 1;
    printf "  %s (%s)\n", check_mapping_stdout( $opt, basename $file_name ), $info->{$ex}{$video_id}{duration} // '?';
    local $SIG{INT} = sub {
        print cldown, "\n";
        print SHOW_CURSOR;
        exit( 1 );
    };
    my $ok; #
    my $p = {};
    my $try = 1;

    RETRY: while ( 1 ) {
        $p->{size}      = -s encode_fs( $opt, $file_name ) // 0;
        $p->{starttime} = gettimeofday;
        my $retries = sprintf "%*s/%s", length $opt->{retries}, $try, $opt->{retries};
        if ( $try > 1 ) {
            $video_count = ' ' x length $video_count;
        }
        else {
            $retries = ' ' x length $retries;
        }
        my $res;
        my $video_url = $info->{$ex}{$video_id}{video_url}{$fmt};
        if ( ! $p->{size} ) {
            my $at = '';
            printf _p_fmt( $opt, "start" ), $video_count, $retries, $at;
            open my $fh, '>:raw', encode_fs( $opt, $file_name ) or die encode_fs( $opt, $file_name ) . " $!";
            $res = $ua->get(
                $video_url,
                ':content_cb' => _return_callback( $opt, $fh, $p ),
            );
            close $fh or die $!;
        }
        elsif ( $p->{size} ) {
            my $at = sprintf "at %.2fM", $p->{size} / 1024 ** 2;
            printf _p_fmt( $opt, "start" ), $video_count, $retries, $at;
            open my $fh, '>>:raw', encode_fs( $opt, $file_name ) or die encode_fs( $opt, $file_name ) . " $!";
            $res = $ua->get(
                $video_url,
                'Range'       => "bytes=$p->{size}-",
                ':content_cb' => _return_callback( $opt, $fh, $p ),
            );
            close $fh or die $!;
        }
        $ok = _status( $opt, $info, $ex, $video_id, $fmt, $p, $res, $video_count, $try, $retries );
        if ( $ok ) {
            last RETRY;
        }
        $try++;
        if ( $try > $opt->{retries} ) {
            push @{$opt->{incomplete_download}}, "$video_id : $file_name";
            last RETRY;
        }
        sleep 4 * $try;
    }
    print SHOW_CURSOR;
    return $ok;
}


sub _status {
    my ( $opt, $info, $ex, $video_id, $fmt, $p, $res, $video_count, $try, $retries ) = @_;
    my $file_name = $info->{$ex}{$video_id}{file_name}{$fmt};
    my $dl_time = sec_to_time( int( tv_interval( [ $p->{starttime} ] ) ), 1 );
    my $status = $res->code;
    print up;
    print cldown;
    if ( $status && $status =~ /^(200|206|416)/ ) {
        my $file_size = -s encode_fs( $opt, $file_name ) // -1;
        my $avg_speed = format_bytes_per_sec( $p->{avg_bytes_per_sec} );
        my ( $size, $at, $incomplete ) = ( '' ) x 4;
        if ( $p->{total} ) {
            my $len_total_mb = length( int( $p->{total} / 1024 ** 2 ) );
            $size = sprintf "%*.2fM",  $len_total_mb + 3, $file_size / 1024 ** 2;
            $at   = sprintf "@%*.2fM", $len_total_mb + 3, $p->{size} / 1024 ** 2;
            if ( $file_size != $p->{total} ) {
                my $should_size = sprintf "%.2fM", $p->{total} / 1024 ** 2;
                my $is_size     = sprintf "%.2fM", $file_size  / 1024 ** 2;
                if ( $should_size eq $is_size ) {
                    $should_size = insert_sep( $p->{total} );
                    $is_size     = insert_sep( $file_size );
                }
                $incomplete = sprintf " Incomplete: %*s/%s ", length( $should_size ), $is_size, $should_size;
                $retries    = sprintf "%*s/%s", length $opt->{retries}, $try, $opt->{retries};
            }
        }
        if ( $status == 416 ) {
            my $pr_status = 'status ' . $status;
            $dl_time   = ' ' x length '0:00:00';
            printf _p_fmt( $opt, "status_416" ), $video_count, $retries, $dl_time, $at, $pr_status;
            return 2;
        }
        elsif ( $status == 200 ) {
            my $at        = ' ' x length $at;
            printf _p_fmt( $opt, "status" ), $video_count, $retries, $dl_time, $size, $avg_speed, $at, $incomplete;
            return 1 if $p->{total} && $p->{total} == $file_size;
        }
        else {
            printf _p_fmt( $opt, "status" ), $video_count, $retries, $dl_time, $size, $avg_speed, $at, $incomplete;
            return 1 if $p->{total} && $p->{total} == $file_size;
        }
    }
    else {
        my $retries = sprintf "%*s/%s", length $opt->{retries}, $try, $opt->{retries};
        my $pr_status = sprintf 'status %s', $res->status_line // $status;
        my $webpage_url = $info->{$ex}{$video_id}{webpage_url};
        if ( $webpage_url ) {
            $pr_status .= ' - Fetching new video url ...';
            my $new_video_url = get_new_video_url( $opt, $info, $ex, $webpage_url, $fmt );
            if ( ! $new_video_url ) {
                $pr_status .=  ' failed!';
            }
            else {
                $info->{$ex}{$video_id}{video_url}{$fmt} = $new_video_url;
            }
        }
        printf _p_fmt( $opt, "status_err" ), $video_count, $retries, $pr_status;
    }
    return;
}


sub _p_fmt {
    my ( $opt, $key ) = @_;
    my %hash = (
        start        => "  %s  %s  %9s\n",
        status_416   => "  %s  %s  %s  %9s   %s\n",
        status       => "  %s  %s  %s  %9s  %11s   %s   %s\n",
        status_err   => "  %s  %s      %s\n",
        info_row1    => "%9.*f %s %36s %9s\n",
        info_row2    => "%9.*f %s %6.1f%% %38s\n",
        info_nt_row1 => " %34s %24sk/s\n",
        info_nt_row2 => "%9.*f %s %48sk/s\n",
    );
    return $hash{$key};
}


sub _return_callback {
    my ( $opt, $fh, $p ) = @_;
    my $time = $p->{starttime};
    my ( $interval, $bytes_per_sec, $chunk_size, $download, $eta ) = ( 0 ) x 5;
    my $resume_size = $p->{size} // 0;
    return sub {
        my ( $chunk, $res, $proto ) = @_;
        $interval += tv_interval( [ $time ] );
        print $fh $chunk;
        my $received = tell $fh;
        $chunk_size += length $chunk;
        $download = $received - $resume_size;
        $p->{total} = $res->header( 'Content-Length' ) // 0;
        if ( $download > 0 && $interval > 2 ) {
            $p->{avg_bytes_per_sec} = $download / tv_interval[ $p->{starttime} ];
            $eta = sec_to_time( int( ( $p->{total} - $download ) / $p->{avg_bytes_per_sec} ), 1 );
            $eta = undef if ! $p->{avg_bytes_per_sec};
            $bytes_per_sec = $chunk_size / $interval;
            $interval = 0;
            $chunk_size = 0;
        }
        my ( $info1, $info2 );
        my $avg_speed = format_bytes_per_sec( $p->{avg_bytes_per_sec} );
        my $speed     = format_bytes_per_sec( $bytes_per_sec );
        my $exp       = { 'M' => 2, 'G' => 3 };
        if ( $p->{total} ) {
            $p->{total} += $resume_size if $resume_size;
            my $percent = ( $received / $p->{total} ) * 100;
            my $unit = length $p->{total} <= 10 ? 'M' : 'G';
            my $prec = 2;
            $info1 = sprintf _p_fmt( $opt, "info_row1" ),
                                $prec, $p->{total} / 1024 ** $exp->{$unit}, $unit,
                                'ETA ' . ( $eta || '-:--:--' ),
                                $avg_speed;
            $info2 = sprintf _p_fmt( $opt, "info_row2" ),
                                $prec, $received / 1024 ** $exp->{$unit}, $unit,
                                $percent,
                                $speed;
        }
        else {
            my $unit = length $received <= 10 ? 'M' : 'G';
            my $prec = 2;
            $info1 = sprintf _p_fmt( $opt, "info_nt_row1" ), 'Could not fetch total file-size!', $avg_speed;
            $info2 = sprintf _p_fmt( $opt, "info_nt_row2" ), $prec, $received / 1024 ** $exp->{$unit}, $unit, $speed;
        }
        print "\r", clline, $info1;
        print "\r", clline, $info2;
        print "\n", up( 3 );
        $time = gettimeofday;
    };
}


sub _archive_download {
    my ( $opt, $info, $ex, $video_id, $fmt ) = @_;
    my $filename = catfile $opt->{archive_dir}, sprintf 'downloads_%s.json', $ex;
    my $archive = read_json( $opt, $filename ) // [];
    if ( $opt->{enable_download_archive} == 2 ) {
        my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime;
        push @$archive, {
            video_id    => $video_id,
            title       => $info->{$ex}{$video_id}{title},
            datetime    => sprintf( "%04d-%02d-%02dT%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min ),
            upload_date => $info->{$ex}{$video_id}{upload_date},
            uploader    => sprintf( "%s (%s)", $info->{$ex}{$video_id}{uploader}, $info->{$ex}{$video_id}{uploader_id} ),
            fmt         => $fmt,
        };
    }
    else {
        push @$archive, { video_id => $video_id};
    }
    write_json( $opt, $filename, $archive );
}


sub is_in_download_archive{
    my ( $opt, $info, $ex, $video_id, $fmt ) = @_;
    my $filename = catfile $opt->{archive_dir}, sprintf 'downloads_%s.json', $ex;
    return   if ! -f encode_fs( $opt, $filename );
    my $archive = read_json( $opt, $filename );
    return 1 if any { ( $_->{video_id} // '' ) eq $video_id } @$archive;
    return;
}





1;


__END__
