package # hide from PAUSE
App::YTDL::Merge;

use warnings;
use strict;
use 5.010000;

use Exporter qw( import );
our @EXPORT_OK = qw( search_and_merge );

use File::Copy            qw( move );
use File::Path            qw( make_path );
use File::Spec::Functions qw( catfile catdir );

use Term::Choose qw( choose );

use App::YTDL::Download qw( is_in_download_archive );
use App::YTDL::Helper   qw( get_filename timestamp_to_upload_date check_mapping_stdout encode_fs uni_capture uni_system );



sub search_and_merge {
    my ( $opt, $info ) = @_;
    return if ! merge_requirements_ok( $opt );
    my $first_line_out = 'Merged: ';

    EXTRACTOR: for my $ex ( keys %$info ) {
        VIDEO_ID: for my $video_id ( keys %{$info->{$ex}} ) {
            if ( keys %{$info->{$ex}{$video_id}{file_name}} == 2 ) {
                my ( $video, $audio );
                my $height = '';
                if ( ! eval {
                    for my $fmt ( keys %{$info->{$ex}{$video_id}{file_name}} ) {
                        if ( $opt->{skip_archived_videos} && is_in_download_archive( $opt, $info, $ex, $video_id, $fmt ) ) {
                            die "In download archive";
                        }
                        my $file = $info->{$ex}{$video_id}{file_name}{$fmt};
                        my $stream_info = _get_stream_info( $opt, $file );
                        if ( $stream_info =~ /^\s*codec_type=audio\s*$/m && $stream_info !~ /^\s*codec_type=video\s*$/m ) {
                            $audio = $file;
                        }
                        elsif ( $stream_info =~ /^\s*codec_type=video\s*$/m ) {
                            $video = $file;
                            if ( $stream_info =~ /^\s*height=(\S+)\s*$/m ) {
                                $height = $1;
                            }
                        }
                    }
                    1 }
                ) {
                    if ( $@ =~ /^In download archive/ ) {
                        say "$video_id in the download archive - skipped merge!";
                    }
                    else {
                        say "$video_id - Merge: ", check_mapping_stdout( $opt, $@ );
                        push @{$opt->{error_merge}}, $video_id;
                    }
                    next VIDEO_ID;
                }
                if ( ! $audio ) { #
                    say "$video_id: No file with audio-only stream!";
                    next VIDEO_ID;
                }
                if ( ! $video ) {
                    say "$video_id: No file with video stream!";
                    next VIDEO_ID;
                }
                if ( $first_line_out ) {
                    say $first_line_out;
                    $first_line_out = '';
                }
                my $video_dir = $info->{$ex}{$video_id}{video_dir};
                my $file_name = get_filename( $opt, $info->{$ex}{$video_id}{title_filename}, $opt->{merge_ext}, $height );
                my $out = catfile $video_dir, $file_name;
                if ( -f encode_fs( $opt, $out ) && ! $opt->{merge_overwrite} ) {
                    my $overwrite_ok = choose(
                        [ '  Skip', '  Overwrite' ],
                        { prompt => 'Already exists: ' . $file_name, layout => 3, index => 1 } #
                    );
                    next VIDEO_ID if ! $overwrite_ok;
                }
                if ( ! eval {
                    _merge_video_with_audio( $opt, $video, $audio, $out );
                    say '  ' .  check_mapping_stdout( $opt, $out );
                    if ( $opt->{merged_in_files} == 1 ) {
                        my $dir_orig_files = catdir $video_dir, $opt->{dir_stream_files};
                        make_path encode_fs( $opt, $dir_orig_files );
                        move encode_fs( $opt, $video ), encode_fs( $opt, $dir_orig_files ) or die encode_fs( $opt, $video ) . " $!";
                        move encode_fs( $opt, $audio ), encode_fs( $opt, $dir_orig_files ) or die encode_fs( $opt, $audio ) . " $!";
                    }
                    elsif ( $opt->{merged_in_files} == 2 ) {
                        unlink encode_fs( $opt, $video ) or die encode_fs( $opt, $video ) . " $!";
                        unlink encode_fs( $opt, $audio ) or die encode_fs( $opt, $audio ) . " $!";
                    }
                    timestamp_to_upload_date( $opt, $info, $ex, $video_id, $out ) if $opt->{modify_timestamp};
                    1 }
                ) {
                    say "$video_id - Merge: ", check_mapping_stdout( $opt, $@ );
                    push @{$opt->{error_merge}}, $video_id;
                }
            }
        }
    }
}


sub _merge_video_with_audio {
    my ( $opt, $video, $audio, $out ) = @_;
    my @cmd = ( $opt->{ffmpeg} );
    push @cmd, '-loglevel', $opt->{merge_loglevel};
    push @cmd, '-y';
    push @cmd, '-i', encode_fs( $opt, $video );
    push @cmd, '-i', encode_fs( $opt, $audio );
    push @cmd, '-codec', 'copy';
    push @cmd, '-map', '0:v:0';
    push @cmd, '-map', '1:a:0';
    push @cmd, encode_fs( $opt, $out );
    uni_system( @cmd );
}


sub _get_stream_info {
    my ( $opt, $file ) = @_;
    my @cmd = ( $opt->{ffprobe} );
    push @cmd, '-loglevel', 'warning';
    push @cmd, '-show_streams';
    push @cmd, encode_fs( $opt, $file );
    my $stream_info = uni_capture( @cmd );
    return $stream_info;
}


sub merge_requirements_ok {
    my ( $opt ) = @_;
    if ( ! $opt->{ffmpeg} ) {
        say "Could not find 'ffmpeg' - No merge.";
        return;
    }
    if ( ! $opt->{ffprobe} ) {
        say "Could not find 'ffprobe' - No merge.";
        return;
    }
    return 1;
}




1;


__END__
