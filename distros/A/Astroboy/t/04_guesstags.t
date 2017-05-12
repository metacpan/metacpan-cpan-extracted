use Test::Simple 'no_plan';
use lib './lib';
use strict;
use Astroboy;
use Smart::Comments '###';
use LEOCHARRE::Dir ':all';
use Cwd;

$Astroboy::DEBUG = 1;

skipcond();

ok(1,'test started');

-d  '/home/leo/music' or exit;



my $astro = Astroboy->new;


my $as = $astro->artists;
ok $as;
my $c =scalar @$as;
ok($c,"got $c");

for my $path ( 
'/home/leo/music/tom_waits/Tom Waits_misc/Tom Waits - Martha.mp3'


){
   my $guess = $astro->artist_guess($path);

   ok($guess,"arg $path: $guess");
}

sub skipcond { 
   -d './t/music' and return 1;
   ok(1, 'skipped, missing ./t/music, must be distro');
   exit;
}

