use Test::More tests => 3;

BEGIN { use_ok('Audio::Beep') };

my $beeper;

ok(defined($beeper = Audio::Beep->new()), 'New object');

ok(defined($beeper->player), 'Did we find a good player module?');

