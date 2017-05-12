
use Test::More tests => 4;
BEGIN { use_ok('Compress::PPMd') };


my $encoder=eval {Compress::PPMd::Encoder->new(25)};
ok($@, "die by bad encoder param");

my $decoder=eval {Compress::PPMd::Decoder->new()};
is ($@, "", "decoder allocated");

my $decoded=eval {$decoder->decode("rubish") };
ok($@, "die by bad encoded data");

