#!perl -w
use strict;
use Test::More tests => 4;
BEGIN {
    use_ok("Audio::SndFile");
}

$@=undef;

ok(Audio::SndFile->open(">","tmp.wav",
	  type => "wav",
	  subtype  => "pcm_16",
	  samplerate => 44100,
	  channels => 1,
     ),"no error");

eval {
     Audio::SndFile->open(">","tmp.wav",
     type => "wav",
     subtype => "pcm_16",
     # samplerate => 44100,
     channels => 1,
     );
};
ok($@ =~ /No samplerate/,"No samplerate specified");

eval {
    Audio::SndFile->open("<","t/empty.wav");
};
ok ($@ =~ /Error/,"Working exceptions on invalid files");

