#!/usr/bin/perl -w

# test noise generation

use Test::More tests => 32;
use strict;

BEGIN
  {
  $| = 1;
  use blib;
  unshift @INC, '../lib';
  unshift @INC, '../blib/arch';
  chdir 't' if -d 't';
  }

use Audio::Audiere;

my $au = Audio::Audiere->new( );

print "# testing tone with 450 Hz\n";
my $t = test_stream( $au->addTone(450) );

# any other test below segfaults (why?)

#print "# testing square wave with 450 Hz\n";
test_stream( $au->addSquareWave(450) );

#print "# testing white noise\n";
#test_stream( $au->addWhiteNoise() );
#print "# testing pink noise\n";
#test_stream( $au->addPinkNoise() );

1;

#############################################################################

sub test_stream
  {
  my $stream = shift;

  is ($stream->error(), undef, 'no error');

  is (ref($stream), 'Audio::Audiere::Stream', 'addStream seemed to work');

  # repeat
  is ($stream->getRepeat(0), 0, 'getRepeat is 0');
  is ($stream->setRepeat(1), 1, 'repeat is now 1');
  is ($stream->getRepeat(), 1, 'repeat is still 1');

  # Volume
  is ($stream->getVolume(), 1, 'volume is 1');
  is ( sprintf("%0.1f", $stream->setVolume(0.3)), '0.3', 'volume is now 0.3');
  is ( sprintf("%0.1f", $stream->getVolume()), '0.3', 'volume is still 0.3');

  # Position
  is ($stream->isSeekable(), '', 'noise is not seekable');

  $stream->setVolume(0.1);
  $stream->play();
  my $i = 0;
  while ($stream->isPlaying() && $i < 1)
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

  # getLength
  is ($stream->getLength() != 1, 1, 'getlength is not 1');

  $stream;
  }

