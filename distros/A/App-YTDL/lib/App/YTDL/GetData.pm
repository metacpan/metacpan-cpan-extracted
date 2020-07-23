package # hide from PAUSE
App::YTDL::GetData;

use warnings;
use strict;
use 5.010000;

use Exporter qw( import );
our @EXPORT_OK = qw( get_download_info );

use JSON             qw( decode_json );
use Term::ANSIScreen qw( :screen );

use App::YTDL::Helper qw( uni_capture HIDE_CURSOR SHOW_CURSOR );


sub get_download_info {
    my ( $set, $opt, $webpage_url, $message, $flat ) = @_;
    my @cmd = @{$set->{youtube_dl}};
    push @cmd, '--youtube-skip-dash-manifest';
    push @cmd, '--dump-single-json';
    push @cmd, '--flat-playlist' if $flat;
    push @cmd, '--', $webpage_url;
    my $json_all;
    my $count = 0;

    RETRY: while ( 1 ) {
        $count++;
        if ( eval {
            print HIDE_CURSOR;
            print $message;
            $json_all = uni_capture( @cmd );
            print "\r", clline;
            print SHOW_CURSOR;
            die $webpage_url . ' - no JSON!' if ! $json_all;
            1 }
        ) {
            last RETRY;
        }
        else {
            print SHOW_CURSOR;
            if ( $count > $opt->{retries} ) {
                push @{$set->{error_get_download_infos}}, $webpage_url;
                return;
            }
            say "$count/$opt->{retries}  $webpage_url: $@";
            sleep $opt->{retries} * 3;
        }
    }
    my $h_ref = decode_json( $json_all );
    return $h_ref;
}




1;


__END__
