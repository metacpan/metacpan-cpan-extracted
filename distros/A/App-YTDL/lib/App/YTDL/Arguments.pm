package # hide from PAUSE
App::YTDL::Arguments;

use warnings;
use strict;
use 5.010000;

use Exporter qw( import );
our @EXPORT_OK = qw( from_arguments_to_choices );

use List::MoreUtils qw( minmax );
use Term::Choose    qw( choose );

use App::YTDL::ChooseVideos qw( choose_videos );
use App::YTDL::GetData      qw( get_download_info );
use App::YTDL::ExtractData  qw( extract_data_list extract_data_single );


sub from_arguments_to_choices {
    my ( $set, $opt, $data, @args ) = @_;
    my $chosen = {};
    my $default_message = "** GET download info: ";
    URL: for my $webpage_url ( @args ) {
        $set->{video_count} = 1;
        my $message = $default_message . $webpage_url;
        my $h_ref = get_download_info( $set, $opt, $webpage_url, $message, 1 );
        my ( $ex, $up, $ids ) = extract_data_list( $set, $opt, $data, $h_ref );
        $ids = [
            sort { $data->{$ex}{$up}{$a}{video_order} <=> $data->{$ex}{$up}{$b}{video_order} } @$ids
        ];
        if ( @$ids == 1 ) {
            my $id = $ids->[0];
            push @{$chosen->{$ex}{$up}}, $id;
        }
        else {
            $set->{video_count} = 1;
            if ( $opt->{entries_with_info} ) {
                my ( $min, $max ) = minmax( $opt->{entries_with_info}, scalar @$ids );
                my $w = length $min;
                for my $i ( 0 .. $min - 1 ) {
                    my $id = $ids->[$i];
                    next if exists $data->{$ex}{$up}{$id}{fmt_to_info};
                    my $url = $data->{$ex}{$up}{$id}{url};
                    my $message = $default_message . sprintf "%*d/%*d", $w, $i + 1, $w, $min;
                    my $h_ref = get_download_info( $set, $opt, $url, $message, 0 );
                    extract_data_single( $set, $opt, $data, $h_ref );
                }
            }
            my $prompt = $data->{$ex}{$up}{$ids->[0]}{uploader} || $webpage_url;
            my $upurl_chosen = choose_videos( $set, $opt, $data, $ex, $up, $ids, $prompt );
            if ( ! defined $upurl_chosen ) {
                next URL;
            }
            push @{$chosen->{$ex}{$up}}, @$upurl_chosen;
        }
    }
    return $chosen;
}




1;


__END__
