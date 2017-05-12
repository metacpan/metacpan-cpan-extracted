use strict;
use warnings;
use lib 'lib';
use AnyEvent;
use AnyEvent::DAAP::Server;
use AnyEvent::DAAP::Server::Track::File::MP3;
use AnyEvent::DAAP::Server::Playlist;
use File::Find::Rule;
use File::Basename qw(dirname);

my $daap = AnyEvent::DAAP::Server->new(port => 23689);

my %playlist;
my $w; $w = AE::timer 1, 0, sub {
    foreach my $file (find name => "*.mp3", in => '.') {
        my $dir = dirname $file;
        my $playlist = $playlist{$dir} ||= do {
            my $playlist = AnyEvent::DAAP::Server::Playlist->new(
                dmap_itemname => $dir,
            );
            $daap->add_playlist($playlist);
            $playlist;
        };
        my $track = AnyEvent::DAAP::Server::Track::File::MP3->new(file => $file);
        $daap->add_track($track);
        $playlist->add_track($track);
    }
    $daap->database_updated;
    undef $w;
};

$daap->setup;

AE::cv->wait;
