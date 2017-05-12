#!/usr/bin/perl -w

# 3D sound example

my $VERSION = '0.01';

BEGIN { $|++; }

use strict;
use warnings;
use lib '../lib';
use lib '../blib/arch';
use Audio::Audiere qw/AUDIO_STREAM/;

print "Audiere::Audio 3D sound example v$VERSION (c) by Tels 2004.\n\n";

my $device = '';
my $volume = 1;

my $file = '../t/test.wav';

#############################################################################
# Create and open the sound device

my $au = Audio::Audiere->new( $device );

die ("Error: ". $au->error()) if $au->error();

print "Using ", $au->getVersion(),
      " with audio device '", $au->getName(),"'.\n\n";
print " File     : '$file'\n";

$au->set3DMasterVolume(1);		# set the 3D master volume to 100%

#############################################################################
# If everything went ok, create a sound stream from the file we want to play

my $stream = $au->addStream3D( $file, AUDIO_STREAM );
die ("Error: ".$stream->error()) if $stream->error();

#############################################################################
# set up the listener

$au->setListenerPosition ( 0, 1.75, 0 );	#
$au->setListenerRotation ( 0, 0, 0 );		# default unrotated

#############################################################################
# if everything is fine so far, set the volume and play the sound,

$stream->setVolume ( $volume );
$stream->setRepeat(1) if $stream->isSeekable();
$stream->play();
$stream->setOrigin( -2, 1, 0);		# left of listener

print " Stream ID: ", $stream->id(),"\n";
print " Length   : ", $stream->getLength()," frames\n";
print " Seekable : ", $stream->isSeekable() ? 'yes' : 'no',"\n\n";

print " Press CTRL-C to abort example\n\n";

#############################################################################
# and loop while the sound is playing and print out some info

my $time = 0;
while (3 < 5)
  {
  sleep(1); $time ++;
  if ($stream->isSeekable())
    {
    print "\r at frame ", $stream->getPosition();
    print ", current: pan ",$stream-> {_cur_pan}," (left: -1, right: +1)";
    print ", vol ",$stream-> {_cur_vol}," (0..1)";
    print ", pitch ",$stream-> {_cur_pitch},"   ";
    }
  $au->update_3D_sound();
  if ($time == 2)
    {
    $au->set3DMasterVolume(0.8);
    }
  if ($time == 3)
    {
    $au->set3DMasterVolume(0.6);
    }
  }

#############################################################################
# cleanup happens automatically

1;

