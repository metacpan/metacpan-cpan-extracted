#!/usr/bin/perl -w

# test muting streams

use Test::More tests => 7;
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

is ($stream->getVolume(), 1, 'full volume');
is ($stream->setVolume(0), 0, 'silent');
is (sprintf("%0.1f",$stream->setVolume(0.5)), 0.5, 'half volume');

print "# You should not hear any audio output now:\n";

$stream->setMuted(1);
$stream->play();

sleep(2);

is (sprintf("%0.1f",$stream->getVolume()), 0.5, 'half volume');
$stream->stop();
$stream->setMuted(0);
is (sprintf("%0.1f",$stream->getVolume()), 0.5, 'half volume');

