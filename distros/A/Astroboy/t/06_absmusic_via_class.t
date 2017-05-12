use Test::Simple 'no_plan';
use lib './lib';
use strict;
use Astroboy;
use Smart::Comments '###';
use LEOCHARRE::Dir ':all';
use Cwd;





my $test_abs_music = cwd().'/t/userhome_tmp/music';
### $test_abs_music


system('rm -rf ./t/userhome_tmp');
system("mkdir -p '$test_abs_music'");
ok( -d $test_abs_music );

ok_part('instance 1');

my $a = Astroboy->new;
ok $a,'instanced';


my $r = $a->abs_music;
ok $r, 'abs_music returns';
### $r
### $Astroboy::ABS_MUSIC

ok $Astroboy::ABS_MUSIC eq $r,"$Astroboy::ABS_MUSIC eq $r";

ok $r ne $test_abs_music;







ok_part('change it.. via class..');
$Astroboy::ABS_MUSIC = $test_abs_music;

### $Astroboy::ABS_MUSIC
ok $Astroboy::ABS_MUSIC eq $test_abs_music;
ok( $r = $a->abs_music );
### $r
ok $r eq $test_abs_music, "$r eq $test_abs_music";


sub ok_part { print STDERR "\n\n---------------------------------------\n@_\n\n" }


