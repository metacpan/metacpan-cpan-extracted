#!perl
use strict;
use warnings;
use Audio::Extract::PCM;
use Test::More tests => 2;
use Compress::Zlib;
use bytes;

my @cleanups;
END {
    $_->() for @cleanups;
}

my $wav = Compress::Zlib::memGunzip (do {
    open my $fh, '<', 't/sine.wav.gz' or die "t/sine.wav.gz: $!";
    local $/;
    <$fh>;
});

open my $wavfh, '>', 'sine.wav' or die "sine.wav: $!";
push @cleanups, sub { unlink ('sine.wav') or warn "unlink: sine.wav: $!"; };
syswrite($wavfh, $wav) or die $!;
close $wavfh or die $!;

my $samples = substr($wav, 44);
my $freq = 44100;
my $samplesize = 2;
my $channels = 2;

my $extractor = Audio::Extract::PCM->new('sine.wav');
my $extracted = $extractor->pcm($freq, $samplesize, $channels)
    or die $extractor->error;

ok($samples eq $$extracted, 'extract ok');
diag('Tested data was '.length($samples).' bytes');

my $bad = Audio::Extract::PCM->new('no-such-file.wav');
$bad->pcm($freq, $samplesize, $channels);
like($bad->error, qr(Can't open input file)i, 'get sox\'s errors');
