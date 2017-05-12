# Test file created outside of h2xs framework.
# Run this like so: `perl player.t'
#   pajas@ufal.mff.cuni.cz     2007/07/20 17:57:26

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
use Audio::aKodePlayer;

BEGIN { plan tests => 46 };

use warnings;
use strict;
$|=1;

ok(1); # If we made it this far, we're ok.

ok( my $player = Audio::aKodePlayer->new() );
ok( $player->isClosed(),'isClosed' );
ok( $player->open('auto'), 'open' );
ok( $player->isOpen(),'isOpen' );
$player->setVolume(0.73);
cmp_ok( abs($player->volume-0.73),'<',0.001, 'volume' );
for my $ext (qw(wav ogg mp3)) {
  my $file = 'example/sample.'.$ext;
  ok( -f $file, $file.' exists' );
 SKIP: {
    if ($player->load($file)) {
      ok(1,"load");
    } else {
      skip("MP3 failed to load - decoding plugin probably not installed ", 11);
    }
    ok( $player->isLoaded(),'isLoaded' );
    $player->play();
    ok( $player->isPlaying(),'isPlaying' );
    ok( $player->position()>=0, 'position>=0' );
    $player->pause();
    ok( $player->isPaused(),'isPaused' );
    $player->resume();
    ok( $player->isPlaying(),'isPlaying' );
    ok ($player->seekable);
  TODO: {
      local $TODO = "WAV reports length and position in seconds instead of milliseconds"
	if ($ext eq 'wav');
      my $length_ok = (abs($player->length()-850)<1);
      ok( $length_ok,'length of '.$ext);
    }
    sleep 1;
    ok( $player->eof(), 'eof '.$ext );
    $player->wait() if $ext eq 'wav'; # FIXME
    cmp_ok( $player->position(),'==',$player->length(), 'length' );
    $player->stop();
    ok( $player->isLoaded(),'isLoaded' );
    $player->unload();
  }
  ok( $player->isOpen(),'isOpen' );
}
$player->close();
ok( $player->isClosed(),'isClosed' );

#########################

# Insert your test code below, the Test::More module is used here so read
# its man page ( perldoc Test::More ) for help writing this test script.


