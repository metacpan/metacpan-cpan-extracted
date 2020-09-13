package # hide from PAUSE
App::YTDL::Arguments;

use warnings;
use strict;
use 5.010000;

use Exporter qw( import );
our @EXPORT_OK = qw( from_arguments_to_choices );

use List::MoreUtils       qw( minmax );
use Parallel::ForkManager qw();
use Term::ANSIScreen      qw( :screen );
use Term::Choose          qw( choose );

use App::YTDL::ChooseVideos qw( choose_videos );
use App::YTDL::GetData      qw( get_download_info );
use App::YTDL::ExtractData  qw( extract_data_list extract_data_single );


sub from_arguments_to_choices {
    my ( $set, $opt, $urls_data, $data, @args ) = @_;
    my $chosen = {};
    my @failed_download_list_info;
    my $total = @args;
    my $arg_count = 0;

    URL: for my $webpage_url ( @args ) {
        $arg_count++;
        print "\r", clline;
        my $progress = sprintf "%d|%d -", $arg_count, $total;
        printf "%s GET download info: %s ", $progress, $webpage_url;
        my ( $ex, $up, $ids );
        if ( ! exists $urls_data->{$webpage_url} ) {
            my $h_ref;
            if ( ! eval { $h_ref = get_download_info( $set, $opt, $webpage_url, 1 ); 1 } ) {
                push @failed_download_list_info, $webpage_url;
                next URL;
            }
            ( $ex, $up, $ids ) = extract_data_list( $set, $opt, $data, $h_ref );
            $urls_data->{$webpage_url} =  [ $ex, $up, $ids ];
        }
        else {
            ( $ex, $up, $ids ) = @{$urls_data->{$webpage_url}}
        }
        if ( @$ids == 1 ) {
            print "\n";
        }
        else {
            if ( $opt->{entries_with_info} ) {
                _get_video_data( $set, $opt, $data, $ex, $up, $ids, $progress );
            }
        }
    }

    URL_DATA: for my $webpage_url ( @args ) {
        my ( $ex, $up, $ids ) = @{$urls_data->{$webpage_url}};
        if ( @$ids > 1 ) {
            my $prompt = $data->{$ex}{$up}{$ids->[0]}{uploader} || $webpage_url;
            my $chosen_ids = choose_videos( $set, $opt, $data, $ex, $up, $ids, $prompt );
            if ( ! defined $chosen_ids ) {
                next URL_DATA;
            }
            push @{$chosen->{$ex}{$up}}, @$chosen_ids;
        }
        else {
            push @{$chosen->{$ex}{$up}}, @$ids;
        }
    }
    if ( @failed_download_list_info ) {
        my $prompt = 'List info - failed downloads:' . "\n";
        $prompt .= '  ' . join "\n  ", @failed_download_list_info;
        choose( [ 'Press "Enter" to continue.' ], { prompt => $prompt } );
    }
    return $chosen;
}



sub _get_video_data {
    my ( $set, $opt, $data, $ex, $up, $ids, $progress ) = @_;
    my ( $min, $max ) = minmax( $opt->{entries_with_info}, scalar @$ids );
    my $message = sprintf "%s GET video data: ", ' ' x length $progress;
    print "\n" . $message;
    my $pm = Parallel::ForkManager->new( $opt->{max_processes} );
    my $c = 1;
    $pm -> run_on_finish (
        sub {
            my ( $pid, $exit_code, $ident, $exit_signal, $core_dump, $data_structure_reference ) = @_;
            if ( defined $data_structure_reference ) {
                my ( $id, $single_data ) = @{${$data_structure_reference}};
                printf "\r%s%d/%d ", $message, $c++, $min;
                for my $key ( keys %$single_data ) {
                    $data->{$ex}{$up}{$id}{$key} = $single_data->{$key};
                }
            }
            else {  # problems occurring during storage or retrieval will throw a warning
                print "\nNo message received from child process $pid!";
            }
        }
    );

    DATA_LOOP: for my $i ( 0 .. $min - 1 ) {
        my $id = $ids->[$i];
        if ( exists $data->{$ex}{$up}{$id}{fmt_to_info} ) {
            next DATA_LOOP;
        }
        my $pid = $pm->start and next DATA_LOOP;
        my $url = $data->{$ex}{$up}{$id}{url};
        my $h_ref;
        my $single_data;
        if ( eval { $h_ref = get_download_info( $set, $opt, $url, 0 ); 1 } ) {
            $single_data = extract_data_single( $set, $opt, $h_ref );
        }
        else {
            $single_data = { description => $set->{failed_fetching_data} };
        }
        my $data_structure_reference = [ $id, $single_data ];
        $pm->finish( 0, \$data_structure_reference );
    }
    $pm->wait_all_children;
}


1;


__END__
