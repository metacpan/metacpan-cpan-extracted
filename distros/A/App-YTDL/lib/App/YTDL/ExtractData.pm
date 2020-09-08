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
            push @$ids, $id;
        }
    }
    else {
        $ex = $h_ref->{extractor_key} // 'no_ex_key';
        my $id = $h_ref->{id};
        my $single_data = extract_data_single( $set, $opt, $h_ref );
        for my $key ( keys %$single_data ) {
            $data->{$ex}{$up}{$id}{$key} = $single_data->{$key};
        }
        $data->{$ex}{$up}{$id}{title} ||= sprintf 'no_title_%s', $id;
        $ids = [ $id ];
    }
    return $ex, $up, $ids;
}


sub extract_data_single {
    my ( $set, $opt, $h_ref ) = @_;
    my $single_data = {};
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
        $single_data->{$key} = $h_ref->{$key} if defined $h_ref->{$key};
    }
    $single_data->{fmt_to_info} = $fmt_to_info;
    _prepare_data( $single_data );
    return $single_data;
}


sub _prepare_data {
    my ( $single_data ) = @_;
    $single_data->{url} = $single_data->{webpage_url};
    if ( $single_data->{upload_date} ) {
        if ( $single_data->{upload_date} =~ /^(\d{4})(\d{2})(\d{2})\z/ ) {
            $single_data->{upload_date}     = $1 . '-' . $2 . '-' . $3;
            $single_data->{upload_datetime} = $1 . '-' . $2 . '-' . $3 . 'T00:00:00';
        }
        if ( $single_data->{upload_date} =~ /^(\d\d\d\d-\d\d-\d\d)T(\d\d:\d\d:\d\d)/ ) {
            $single_data->{upload_date} = $1;
            $single_data->{upload_datetime} = $1 . 'T' . $2;
        }
    }
    if ( ! $single_data->{upload_date} && $single_data->{upload_date_rel} ) {
        $single_data->{upload_date} = $single_data->{upload_date_rel};
    }
    $single_data->{duration}        ||= '-:--:--';
    $single_data->{upload_date}     ||= '';
    $single_data->{upload_datetime} ||= '0000-00-00T00:00:00';
    if ( $single_data->{duration} =~ /^[0-9]+\z/ ) {
        $single_data->{duration} = sec_to_time( $single_data->{duration}, 1 );
    }
    if ( $single_data->{like_count} && $single_data->{dislike_count} ) {
        $single_data->{raters}         ||= $single_data->{like_count} + $single_data->{dislike_count};
        $single_data->{average_rating}
        ||= ( $single_data->{like_count} * 5 + $single_data->{dislike_count} ) / $single_data->{raters}; #
    }
    if ( $single_data->{average_rating} ) {
        $single_data->{average_rating} = sprintf "%.2f", $single_data->{average_rating};
    }
    if ( $single_data->{raters} ) {
        $single_data->{raters} = insert_sep( $single_data->{raters} );
    }
    if ( $single_data->{view_count} ) {
        $single_data->{view_count_raw} = $single_data->{view_count};
        $single_data->{view_count} = insert_sep( $single_data->{view_count} );
    }
    else {
        $single_data->{view_count} = 0;
    }
}




1;


__END__
