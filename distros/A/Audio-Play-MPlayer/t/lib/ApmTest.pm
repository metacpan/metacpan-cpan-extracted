package ApmTest;

use strict;
use warnings;
use Exporter; *import = \&Exporter::import;

use File::Spec;
use Time::HiRes qw(sleep);

use Audio::Play::MPlayer;

our @EXPORT = qw(get_player sleep);

BEGIN {
    require Test::More;

    my $found = 0;
    foreach my $dir ( File::Spec->path ) {
        if( -x File::Spec->catfile( $dir, 'mplayer' ) ) {
            $found = 1;
            last;
        }
    }

    Test::More->import( skip_all => "Can't find mplayer executable" )
        unless $found;
}

sub get_player {
    return Audio::Play::MPlayer->new
               ( mplayerargs => [ '-af', 'volume=-200' ] );
}

1;
