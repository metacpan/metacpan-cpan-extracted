package # hide from PAUSE
App::YTDL::GetData;

use warnings;
use strict;
use 5.010000;

use Exporter qw( import );
our @EXPORT_OK = qw( get_download_info );

use JSON qw( decode_json );

use App::YTDL::Helper qw( uni_capture );


sub get_download_info {
    my ( $set, $opt, $webpage_url, $flat ) = @_;
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
            $json_all = uni_capture( @cmd );
            die 'no JSON!' if ! $json_all;
            1 }
        ) {
            last RETRY;
        }
        else {
            if ( $count > $opt->{retries} ) {
                die "Error download info: $webpage_url!";
            }
            my $error = $@;
            chomp $error;
            print "  $count/$opt->{retries}  $webpage_url: $error\n";
            sleep $opt->{retries} * 2;
        }
    }
    my $h_ref = decode_json( $json_all );
    return $h_ref;
}




1;


__END__
