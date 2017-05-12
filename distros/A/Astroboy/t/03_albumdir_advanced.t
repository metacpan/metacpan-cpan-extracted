use Test::Simple 'no_plan';
use Cwd;
use lib './lib';
use strict;
use Astroboy::AlbumDir;
$Astroboy::DEBUG = 1;
$Astroboy::ABS_MUSIC = cwd().'/t/userhome_tmp/music';
use Smart::Comments '###';
use LEOCHARRE::Dir 'lsf';

skipcond();

system('rm -rf ./t/music/album_tmp');

system('rm -rf ./t/userhome_tmp');
mkdir './t/userhome_tmp';

system('cp -R ./t/music/dir1 ./t/music/album_tmp');



my $abs = './t/music/album_tmp';
-d $abs or die("missing $abs");

my $a = Astroboy::AlbumDir->new($abs);
ok( $a, "got album" ) or die;

my $percentage = $a->ls_mp3_percent;
ok($percentage, "percentage mp3s: $percentage");

ok $a->is_album,'is album';


my $abs_music = $a->abs_music;

ok($abs_music, "abs music is $abs_music");


my $artist = $a->artist;
ok($artist, "got artist : $artist");

my $album = $a->album;
ok($album, "got album : $album");

my $rps = $a->rel_path_suggested;
ok( $rps, "rel path suggested: $rps");

my $refiled_to = $a->refile or die($a->errstr);

ok($refiled_to, "refiled to $refiled_to");

# there should be at least one non mp3 file..
my @lsf = grep { !/\.mp3$/i } lsf($refiled_to);

### @lsf

ok( ( @lsf and scalar @lsf) ,
   "there should be at least one non mp3 file. '@lsf'");



sub skipcond { 
   -d './t/music' and return 1;
   ok(1, 'skipped, missing ./t/music, must be distro');
   exit;
}

