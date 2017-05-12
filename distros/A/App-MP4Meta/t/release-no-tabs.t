
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::NoTabsTests 0.05

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/mp4meta',
    'lib/App/MP4Meta.pm',
    'lib/App/MP4Meta/Base.pm',
    'lib/App/MP4Meta/Command/film.pm',
    'lib/App/MP4Meta/Command/musicvideo.pm',
    'lib/App/MP4Meta/Command/tv.pm',
    'lib/App/MP4Meta/Film.pm',
    'lib/App/MP4Meta/MusicVideo.pm',
    'lib/App/MP4Meta/Source/Base.pm',
    'lib/App/MP4Meta/Source/Data/Base.pm',
    'lib/App/MP4Meta/Source/Data/Film.pm',
    'lib/App/MP4Meta/Source/Data/TVEpisode.pm',
    'lib/App/MP4Meta/Source/OMDB.pm',
    'lib/App/MP4Meta/Source/TVDB.pm',
    'lib/App/MP4Meta/TV.pm'
);

notabs_ok($_) foreach @files;
done_testing;
