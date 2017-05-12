#!/usr/bin/perl -w

# test streaming from files, and error in stream creation 

use Test::More tests => 24;
use strict;

BEGIN
  {
  $| = 1;
  use blib;
  unshift @INC, '../lib';
  unshift @INC, '../blib/arch';
  chdir 't' if -d 't';
  }

use Audio::Audiere qw/AUDIO_STREAM AUDIO_BUFFER/;

my $au = Audio::Audiere->new( );

my $stream = $au->addStream ('test.wav', AUDIO_STREAM);

is ($stream->error(), undef, 'no error');

is (ref($stream), 'Audio::Audiere::Stream', 'addStream seemed to work');

is ($au->getMasterVolume(), 1, 'master volume is 100%');
is (sprintf("%0.1f",$au->setMasterVolume(0.5)), 0.5, 'master volume is 50%');
is (sprintf("%0.1f",$au->getMasterVolume()), 0.5, 'master volume still 50%');

# repeat
is ($stream->getRepeat(0), 0, 'getRepeat is 0');
is ($stream->setRepeat(1), 1, 'repeat is now 1');
is ($stream->getRepeat(), 1, 'repeat is still 1');

$stream->setRepeat(0);

# Position
if ($stream->isSeekable())
  {
  is ($stream->getPosition(), 0, 'pos is 0');
  is ( $stream->setPosition(2), 2, 'pos is now 2');
  is ( $stream->getPosition(), 2, 'pos is still 2');
  }
else
  {
  for (1..3) { is (1,0,'stream is not seekable!'); }
  }

$stream->play();

my $i = 0;
while ($stream->isPlaying() && $i < 3)
  {
  sleep(1); $i++;
  } 

$stream->stop();

# Pan
is ($stream->getPan(), 0, 'pan is 0');
is ( sprintf("%0.1f", $stream->setPan(0.5)), '0.5', 'pan is now 0.5');
is ( sprintf("%0.1f", $stream->getPan()), '0.5', 'pan is stil 0.5');

# Pitch
is ($stream->getPitchShift(), 1, 'pitch is 1');
is ( sprintf("%0.1f", $stream->setPitchShift(0.5)), '0.5', 'pitch is now 0.5');
is ( sprintf("%0.1f", $stream->getPitchShift()), '0.5', 'pitch is stil 0.5');

# Volume
is ($stream->getVolume(), 1, 'volume is 1');
is ( sprintf("%0.1f", $stream->setVolume(0.3)), '0.3', 'volume is now 0.3');
is ( sprintf("%0.1f", $stream->getVolume()), '0.3', 'volume is still 0.3');

# getLength
is ($stream->getLength() != 1, 1, 'getlength is not 1');

# stream registered?
is ($au->{_streams}->{1}, $stream, 'stream registered'); 

##############################################################################
# error when creating stream

$stream = $au->addStream ('non-existing.wav', AUDIO_STREAM);

is (ref($stream), 'Audio::Audiere::Error', 'error returned');
is ($stream->error(), 
  "Could not create stream from 'non-existing.wav': No such file.", 
  'error' );

