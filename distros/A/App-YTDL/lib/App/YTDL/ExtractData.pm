package # hide from PAUSE
App::YTDL::ExtractData;

use warnings;
use strict;
use 5.010000;

use Exporter qw( import );
our @EXPORT_OK = qw( extract_data_list extract_data_single );

use Term::Choose::Util qw( insert_sep );

use App::YTDL::Helper qw( sec_to_time );


sub extract_data_list {
    my ( $set, $opt, $data, $h_ref ) = @_;
    my $ex;
    my $up = $h_ref->{uploader_id} // 'no_up_id';
    my $ids = [];
    if ( exists $h_ref->{entries} ) {
        $ex = $h_ref->{entries}[0]{ie_key} // 'no_ex_key';
        ENTRY: for my $entry ( @{$h_ref->{entries}} ) {
            my $id = $entry->{id};
            my @keys = qw(url title ie_key);
            for my $key ( @keys ) {
                $data->{$ex}{$up}{$id}{$key} = $entry->{$key} if defined $entry->{$key};
            }
            $data->{$ex}{$up}{$id}{uploader_url} = $h_ref->{uploader_url};
            $data->{$ex}{$up}{$id}{uploader} = $h_ref->{uploader};
            $data->{$ex}{$up}{$id}{title} ||= sprintf 'no_title_%s', $id;
            $data->{$ex}{$up}{$id}{video_order} = $set->{video_count}++;
            push @$ids, $id;
        }
    }
    else {
        $ex = $h_ref->{extractor_key} // 'no_ex_key';
        my $id = $h_ref->{id};
        extract_data_single( $set, $opt, $data, $h_ref );
        $data->{$ex}{$up}{$id}{title} ||= sprintf 'no_title_%s', $id;
        $data->{$ex}{$up}{$id}{video_order} = $set->{video_count}++;
        $ids = [ $id ];
    }
    return $ex, $up, $ids;
}


sub extract_data_single {
    my ( $set, $opt, $data, $h_ref ) = @_;
    my $ex = $h_ref->{extractor_key} // 'no_ex_key';
    my $up = $h_ref->{uploader_id} // 'no_up_id';
    my $id = $h_ref->{id};
    my $fmt_to_info = {};
    my $c = 1;
    for my $format ( @{$h_ref->{formats}} ) {
        my $fmt = $format->{format_id} // 'no_fmt_' . $c++;
        $fmt_to_info->{$fmt}{ext}         = $format->{ext};
        $fmt_to_info->{$fmt}{format}      = $format->{format};
        $fmt_to_info->{$fmt}{format_note} = $format->{format_note};
        $fmt_to_info->{$fmt}{height}      = $format->{height};
        $fmt_to_info->{$fmt}{width}       = $format->{width};
        $fmt_to_info->{$fmt}{url}         = $format->{url};
    }
    my @keys = qw(uploader uploader_url description format_id like_count dislike_count average_rating
                  raters duration extractor extractor_key title upload_date view_count webpage_url); # age_limit annotations categories
    for my $key ( @keys ) {
        $data->{$ex}{$up}{$id}{$key} = $h_ref->{$key} if defined $h_ref->{$key};
    }
    $data->{$ex}{$up}{$id}{fmt_to_info} = $fmt_to_info;
    _prepare_data( $data, $ex, $up, $id );
    $data->{$ex}{$up}{$id}{video_order} = $set->{video_count}++;
    return;
}


sub _prepare_data {
    my ( $data, $ex, $up, $id ) = @_;
    $data->{$ex}{$up}{$id}{url} = $data->{$ex}{$up}{$id}{webpage_url};
    if ( $data->{$ex}{$up}{$id}{upload_date} ) {
        if ( $data->{$ex}{$up}{$id}{upload_date} =~ /^(\d{4})(\d{2})(\d{2})\z/ ) {
            $data->{$ex}{$up}{$id}{upload_date}     = $1 . '-' . $2 . '-' . $3;
            $data->{$ex}{$up}{$id}{upload_datetime} = $1 . '-' . $2 . '-' . $3 . 'T00:00:00';
        }
        if ( $data->{$ex}{$up}{$id}{upload_date} =~ /^(\d\d\d\d-\d\d-\d\d)T(\d\d:\d\d:\d\d)/ ) {
            $data->{$ex}{$up}{$id}{upload_date} = $1;
            $data->{$ex}{$up}{$id}{upload_datetime} = $1 . 'T' . $2;
        }
    }
    if ( ! $data->{$ex}{$up}{$id}{upload_date} && $data->{$ex}{$up}{$id}{upload_date_rel} ) {
        $data->{$ex}{$up}{$id}{upload_date} = $data->{$ex}{$up}{$id}{upload_date_rel};
    }
    $data->{$ex}{$up}{$id}{duration}        ||= '-:--:--';
    $data->{$ex}{$up}{$id}{upload_date}     ||= '';
    $data->{$ex}{$up}{$id}{upload_datetime} ||= '0000-00-00T00:00:00';
    if ( $data->{$ex}{$up}{$id}{duration} =~ /^[0-9]+\z/ ) {
        $data->{$ex}{$up}{$id}{duration} = sec_to_time( $data->{$ex}{$up}{$id}{duration}, 1 );
    }
    if ( $data->{$ex}{$up}{$id}{like_count} && $data->{$ex}{$up}{$id}{dislike_count} ) {
        $data->{$ex}{$up}{$id}{raters}         ||= $data->{$ex}{$up}{$id}{like_count} + $data->{$ex}{$up}{$id}{dislike_count};
        $data->{$ex}{$up}{$id}{average_rating}
        ||= ( $data->{$ex}{$up}{$id}{like_count} * 5 + $data->{$ex}{$up}{$id}{dislike_count} ) / $data->{$ex}{$up}{$id}{raters}; #
    }
    if ( $data->{$ex}{$up}{$id}{average_rating} ) {
        $data->{$ex}{$up}{$id}{average_rating} = sprintf "%.2f", $data->{$ex}{$up}{$id}{average_rating};
    }
    if ( $data->{$ex}{$up}{$id}{raters} ) {
        $data->{$ex}{$up}{$id}{raters} = insert_sep( $data->{$ex}{$up}{$id}{raters} );
    }
    if ( $data->{$ex}{$up}{$id}{view_count} ) {
        $data->{$ex}{$up}{$id}{view_count_raw} = $data->{$ex}{$up}{$id}{view_count};
        $data->{$ex}{$up}{$id}{view_count} = insert_sep( $data->{$ex}{$up}{$id}{view_count} );
    }
    else {
        $data->{$ex}{$up}{$id}{view_count} = 0;
    }
}




1;


__END__
