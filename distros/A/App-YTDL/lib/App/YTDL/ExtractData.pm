package # hide from PAUSE
App::YTDL::ExtractData;

use warnings;
use strict;
use 5.010000;

use Exporter qw( import );
our @EXPORT_OK = qw( json_to_hash prepare_info );

use JSON               qw( decode_json );
use Term::Choose::Util qw( insert_sep );

use App::YTDL::Helper qw( sec_to_time );


sub json_to_hash {
    my ( $opt, $json_all ) = @_;
    my $tmp = {};
    for my $json ( split /\n+/, $json_all ) {
        my $h_ref = decode_json( $json );
        my $formats = {};
        my $c = 1;
        for my $format ( @{$h_ref->{formats}} ) {
            my $fmt = $format->{format_id} // 'unkown_fmt_' . $c++;
            $formats->{$fmt}{ext}         = $format->{ext};
            $formats->{$fmt}{format}      = $format->{format};
            $formats->{$fmt}{format_note} = $format->{format_note};
            $formats->{$fmt}{height}      = $format->{height};
            $formats->{$fmt}{width}       = $format->{width};
            $formats->{$fmt}{url}         = $format->{url};
        }
        my $ex = $h_ref->{extractor} // $h_ref->{extractor_key} // '';
        $ex = 'youtube'         if $ex =~ /^youtube\z/i;
        $ex = 'unkown_etractor' if ! length $ex;
        my $video_id = $h_ref->{id} // $h_ref->{title};
        my @keys = ( qw( uploader uploader_id description format_id like_count dislike_count average_rating raters
                        duration extractor extractor_key playlist_id title upload_date view_count webpage_url ) );
                        # age_limit annotations playlist stitle categories
        for my $key ( @keys ) {
            $tmp->{$ex}{$video_id}{$key} = $h_ref->{$key} if defined $h_ref->{$key};
        }
        $tmp->{$ex}{$video_id}{video_id}    = $video_id;
        $tmp->{$ex}{$video_id}{fmt_to_info} = $formats;
        prepare_info( $opt, $tmp, $ex, $video_id );
    }
    return $tmp;
}


sub prepare_info {
    my ( $opt, $info, $ex, $video_id ) = @_;
    if ( $info->{$ex}{$video_id}{upload_date} ) {
        if ( $info->{$ex}{$video_id}{upload_date} =~ /^(\d{4})(\d{2})(\d{2})\z/ ) {
            $info->{$ex}{$video_id}{upload_date}     = $1 . '-' . $2 . '-' . $3;
            $info->{$ex}{$video_id}{upload_datetime} = $1 . '-' . $2 . '-' . $3 . 'T00:00:00';
        }
        if ( $info->{$ex}{$video_id}{upload_date} =~ /^(\d\d\d\d-\d\d-\d\d)T(\d\d:\d\d:\d\d)/ ) {
            $info->{$ex}{$video_id}{upload_date} = $1;
            $info->{$ex}{$video_id}{upload_datetime} = $1 . 'T' . $2;
        }
    }
    if ( ! $info->{$ex}{$video_id}{upload_date} && $info->{$ex}{$video_id}{upload_date_rel} ) {
        $info->{$ex}{$video_id}{upload_date} = $info->{$ex}{$video_id}{upload_date_rel};
    }
    $info->{$ex}{$video_id}{title}           ||= sprintf 'no_title_%s', $video_id;
    $info->{$ex}{$video_id}{duration}        ||= '-:--:--';
    $info->{$ex}{$video_id}{upload_date}     ||= '';
    $info->{$ex}{$video_id}{upload_datetime} ||= $opt->{no_upload_datetime}; # '0000-00-00T00:00:00';
    $info->{$ex}{$video_id}{playlist_id} //= '';
    $info->{$ex}{$video_id}{uploader_id} //= $info->{$ex}{$video_id}{uploader} // '';
    $info->{$ex}{$video_id}{uploader}    //= $info->{$ex}{$video_id}{uploader_id};
    $info->{$ex}{$video_id}{title_filename} = $info->{$ex}{$video_id}{title};
    if ( $info->{$ex}{$video_id}{duration} =~ /^[0-9]+\z/ ) {
        $info->{$ex}{$video_id}{duration} = sec_to_time( $info->{$ex}{$video_id}{duration}, 1 );
    }
    if ( $info->{$ex}{$video_id}{like_count} && $info->{$ex}{$video_id}{dislike_count} ) {
        $info->{$ex}{$video_id}{raters}         ||= $info->{$ex}{$video_id}{like_count} + $info->{$ex}{$video_id}{dislike_count};
        $info->{$ex}{$video_id}{average_rating}
        ||= ( $info->{$ex}{$video_id}{like_count} * 5 + $info->{$ex}{$video_id}{dislike_count} ) / $info->{$ex}{$video_id}{raters}; #
    }
    if ( $info->{$ex}{$video_id}{average_rating} ) {
        $info->{$ex}{$video_id}{average_rating} = sprintf "%.2f", $info->{$ex}{$video_id}{average_rating};
    }
    if ( $info->{$ex}{$video_id}{raters} ) {
        $info->{$ex}{$video_id}{raters} = insert_sep( $info->{$ex}{$video_id}{raters} );
    }
    if ( $info->{$ex}{$video_id}{view_count} ) {
        $info->{$ex}{$video_id}{view_count_raw} = $info->{$ex}{$video_id}{view_count};
        $info->{$ex}{$video_id}{view_count} = insert_sep( $info->{$ex}{$video_id}{view_count} );
    }
    else {
        $info->{$ex}{$video_id}{view_count} = 0;
    }
}





1;


__END__
