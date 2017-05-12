use Test::Simple 'no_plan';
use Cwd;
use lib './lib';
use strict;
use Astroboy::AlbumDir;
$Astroboy::DEBUG = 1;
$Astroboy::ABS_MUSIC = cwd().'/t/userhome_tmp/music';
use Smart::Comments '###';



skipcond();

my $abs = './t/music/dir1';
-d $abs or die("missing $abs");

my $a = Astroboy::AlbumDir->new($abs);
ok( $a, "got album" ) or die;

my $percentage = $a->ls_mp3_percent;
ok($percentage, "percentage mp3s: $percentage");

ok $a->is_album,'is album';

my $trash = $a->ls_trash;
### $trash

my $music = $a->ls_mp3;
### $music

my $all = $a->ls;
### $all

my $count = $a->ls_count;
### $count

$count = $a->ls_mp3;
### $count




my $abs_music = $a->abs_music;

ok($abs_music, "abs music is $abs_music");


sub skipcond { 
   -d './t/music' and return 1;
   ok(1, 'skipped, missing ./t/music, must be distro');
   exit;
}

