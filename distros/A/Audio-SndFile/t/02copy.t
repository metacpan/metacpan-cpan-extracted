#!perl -w
use strict;
use Test::More tests => 10;
BEGIN {
    use_ok("Audio::SndFile");
}
use Config;
$|=1;
isa_ok(my $i = Audio::SndFile::Info->new(),"Audio::SndFile::Info","create info object");

$i->type("wav");
$i->subtype("pcm_16");
$i->endianness("cpu");

is($i->type,"wav","info type");
is($i->subtype,"pcm_16","info subtype");
is($i->endianness,"cpu","info endianness");

isa_ok(my $infile  = Audio::SndFile->open("<","t/test.wav"),"Audio::SndFile","open for reading");
isa_ok(my $outfile = Audio::SndFile->open(">","t/copy.wav",
    type    => "wav",
    subtype => "pcm_16",
    endianness => "file",
    channels => 1,
    samplerate => 44100,
),"Audio::SndFile","open for writing");

my $buffer = "";
while (my $len = $infile->read_int($buffer,1024)) {
    die "bufferlen (".length($buffer)." * $Config{intsize}) != $len" if length($buffer) != $len * $Config{intsize};
    $outfile->write_int($buffer);
}


$infile->close;
$outfile->close;

open my $orig,"<","t/test.wav" or die "Can't open test.wav: $!";
open my $copy,"<","t/copy.wav" or die "Can't open copy.wav: $!";
binmode $orig;
binmode $copy;
my $l = -s "t/test.wav";
my $l1 = read($orig,my $b1,$l) or die $!;
is ($l1,$l,"read length orig");
my $l2 = read($copy,my $b2,$l) or die $!;
is ($l2,$l,"read length copy");
ok($b1 eq $b2,"exact copy");


