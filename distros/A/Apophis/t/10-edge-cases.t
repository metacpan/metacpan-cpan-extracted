use strict;
use warnings;
use Test::More tests => 8;
use File::Temp qw(tempdir);
use Apophis;

my $dir = tempdir(CLEANUP => 1);
my $ca = Apophis->new(namespace => 'test-edge', store_dir => $dir);

# Empty content round-trip
my $empty = '';
my $id1 = $ca->store(\$empty);
like($id1, qr/^[0-9a-f]{8}-/, 'empty content stores OK');
my $fetched1 = $ca->fetch($id1);
is($$fetched1, '', 'empty content fetches back as empty');

# Binary with null bytes round-trip
my $binary = "foo\x00bar\x00\x01\x02\xff";
my $id2 = $ca->store(\$binary);
my $fetched2 = $ca->fetch($id2);
is($$fetched2, $binary, 'binary with nulls round-trips correctly');

# Unicode content (UTF-8 bytes)
my $unicode = "caf\xc3\xa9 \xe2\x98\x83";  # cafe + snowman in UTF-8
my $id3 = $ca->store(\$unicode);
my $fetched3 = $ca->fetch($id3);
is($$fetched3, $unicode, 'UTF-8 bytes round-trip correctly');

# Large content
my $large = 'A' x 500_000;
my $id4 = $ca->store(\$large);
ok($ca->exists($id4), 'large content (500KB) stored');
ok($ca->verify($id4), 'large content verifies');

# Constructor requires namespace
eval { Apophis->new() };
like($@, qr/namespace/, 'new without namespace croaks');

# identify requires scalar ref
eval { $ca->identify('not a ref') };
like($@, qr/scalar reference/, 'identify without ref croaks');
