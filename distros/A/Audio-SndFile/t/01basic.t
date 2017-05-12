#!perl -w
use strict;
use Test::More tests => 17;
BEGIN {
    use_ok("Audio::SndFile");
}

isa_ok(my $sndfile = Audio::SndFile->open("+<","t/test.wav"),"Audio::SndFile","open for reading");

is($sndfile->type,"wav","read type");
is($sndfile->subtype,"pcm_16","read subtype");
is($sndfile->endianness,"file","endianness");
is($sndfile->channels,1,"channels");
is($sndfile->samplerate,44100,"samplerate");
is($sndfile->sections,1,"sections");
is($sndfile->seekable,1,"seekable");
is($sndfile->frames,71992,"frames");

my $buff = "";
is($sndfile->read_raw($buff,20),20,"read_raw length");
is($sndfile->read_raw($buff,20),20,"Read length");
is(length $buff,20,"buffer length");
is($sndfile->readf_float($buff,10),10,"Readf length");

my @vals = $sndfile->unpack_float(20);
is(scalar @vals, 20,"unpack length");

is($sndfile->comment,undef);
is($sndfile->artist,undef);

