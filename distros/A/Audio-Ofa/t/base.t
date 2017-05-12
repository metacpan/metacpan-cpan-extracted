#!perl
use strict;
use warnings;
use Audio::Ofa qw(ofa_get_version ofa_create_print OFA_LITTLE_ENDIAN);
use Test::More tests => 1;
use Compress::Zlib;
use bytes;

diag('libofa version is ' . ofa_get_version());
diag('OFA_LITTLE_ENDIAN is ' . OFA_LITTLE_ENDIAN);


my $samples = Compress::Zlib::memGunzip (do {
    open my $fh, '<', 't/sine.wav.gz' or die "t/sine.wav.gz: $!";
    local $/;
    <$fh>;
});
substr($samples, 0, 44, '');

my $freq = 44100;
my $channels = 2;
my $samplesize = 2;
my $size = length($samples) / $samplesize;

diag("size is $size");

my $print = ofa_create_print($samples, OFA_LITTLE_ENDIAN, $size, $freq, 1);

#diag("Fingerprint is $print");

#is($print, 'AQAGAAYABgAGAAcABwAIAAgACQAKAAsADAAOABAAEwAYACAAMABZRcZrTQAOAAcABAADAAMAAgACAAEAAQABAAEAAQABAAEAAQABAAEAAAAA3b/ebt844DHhF+IA4vjj1+So5XTmTecI57voeekb6bfqS+ro623o5A9OEPAOpgzhC3wKWwlrCKMH+gdiBu4GgQYjBcgFgQU+BP8ExgSVBGIvPCkDIlsbKRUnEDMKPQXzAgb+l/s++JX2QPP58izwle8z7d7s1uiJD1IYKhtNGQ8YYBdUFlAVNBQkE1kSXBF+EMsP8Q9iDtIOLQ2lDT8MvMpy3Djr+PnWA04KKA+OFGUUhBVjFZcVJhRSE2ERsBCTDpkMnQsvCrj43AGHCrUOkxIMFBgVfBYVFoAVPxZFFgEVvhSMFMYUvxPkEtYTJxM8OeERaPf56Pjix95f5UHleu789Kj6X/9MA94H1AvADCgRNhN+FPwZ4e8T6Bbbi/OP+f3/UgcOB3kIXAqaD40QfhF3D2sSVBRQE+USVBQNFubeRwJXE0QXaxpu/tcSqcwSCe0FWwHJ/vv8dP1X+OD72Pbb9Jz14PPXB/8JaZ5WBYcCygOdA2ADBQLRBHMCwARTAp3/eAOiBB0C6AN9AdEDugEJ/r79j/tR+zTq4/m8an73xvfU9+/2ufhl6qL5Ivhh+fP8ivrI+qQDjAKDxyYAnwmUAH/9EgDY/7cDtwHFAIAB7f5RAWoI5AKnAhQAX/sjPgAAAA==', 'Example fingerprint');

# The beginning seems to be more portable than the ending:
like($print, qr(^AQAGAAYAB));
