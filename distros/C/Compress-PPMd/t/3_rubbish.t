
use Test::More tests => 28;
BEGIN { use_ok('Compress::PPMd') };


{
    my $decoder=eval Compress::PPMd::Decoder->new();
    my $rubbish=pack("C*", map { 255 } (1..100000));
    my $decoded=eval {$decoder->decode($rubbish) };
    ok(1, "do not crash by bad encoded data all bits 1");
}

{
    my $decoder=eval Compress::PPMd::Decoder->new();
    my $rubbish=pack("C*", map { 0 } (1..100000));
    my $decoded=eval {$decoder->decode($rubbish) };
    ok(1, "do not crash by bad encoded data all bits 0");
}

for (1..25) {	
    my $decoder=eval Compress::PPMd::Decoder->new();
    my $rubbish=pack("C*", map { int(rand 256) } (1..100000));
    my $decoded=eval {$decoder->decode($rubbish) };
    ok(1, "do not crash by bad encoded data");
}
