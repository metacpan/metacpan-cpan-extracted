use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Cwd qw(abs_path);
use File::Basename;
use File::Spec;
use Mojo::Util qw(slurp md5_sum);
use Mojo::IOLoop;

use Test::More;

use_ok 'App::Caoliu::Downloader';

my $url =
'http://www.rmdown.com/link.php?hash=132261048f5708fe12454617aed2d54a07312388d6d';
my $d = App::Caoliu::Downloader->new;

SKIP: {
    my $current_path = dirname( abs_path(__FILE__) );
    skip 'network problem or download file failed', 2
      unless my $file = $d->download_torrent( $url, $current_path );
    my $sample_torrent =
      File::Spec->catfile( dirname( abs_path(__FILE__) ), 'sample.torrent' );
    if ( -e $sample_torrent ) {
        is(
            md5_sum( slurp $sample_torrent),
            md5_sum( slurp (File::Spec->catfile( $current_path, $file )) ),
            'test download bt file md5sum'
        );
    }
}

done_testing();

