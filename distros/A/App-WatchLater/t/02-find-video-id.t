use 5.016;
use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;

my $module = 'App::WatchLater::YouTube';
use_ok $module or BAIL_OUT;
can_ok $module, 'find_video_id' or BAIL_OUT;

my $video_id = 'J6wgG-I0N6w';

is find_video_id("https://www.youtube.com/watch?v=$video_id"), $video_id,
  'normal YouTube URL';
is find_video_id("https://youtu.be/$video_id"), $video_id, 'short youtu.be URL';
is find_video_id($video_id), $video_id, 'just the ID';

dies_ok { find_video_id('https://www.youtube.com/') } 'no ID';
