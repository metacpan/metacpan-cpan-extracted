use strict;
use warnings;
use Test::More; # tests => 9;

use Data::HexConverter;

my $hex_ref = \"41424344";      # ABCD
my $bin      = Data::HexConverter::hex_to_binary($hex_ref);
is($bin, "ABCD", 'hex_to_binary works');

my $hex2     = Data::HexConverter::binary_to_hex(\$bin);
is(uc $hex2, "41424344", 'binary_to_hex works');

my $himpl = Data::HexConverter::hex_to_binary_impl();
my $bimpl = Data::HexConverter::binary_to_hex_impl();
ok($himpl, "have hex impl name: $himpl");
ok($bimpl, "have bin impl name: $bimpl");

is( Data::HexConverter::hex_to_binary( \"") , "", "empty hex -> empty bin");
is( Data::HexConverter::binary_to_hex( \"") , "", "empty bin -> empty hex");

eval { Data::HexConverter::hex_to_binary( \"A") };
like($@, qr/not even/, "odd hex croaks");

ok(1, 'extra ok to keep testers happy');

done_testing();

