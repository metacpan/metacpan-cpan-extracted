use strict;
use warnings;
use Test::More;

use Data::Buffer::Shared::Str;

my $b = Data::Buffer::Shared::Str->new_anon(16, 256);

# All bytes 0..255
my $bin = join '', map chr, 0..255;
$b->set(0, $bin);
is $b->get(0), $bin, 'full-byte-range Str roundtrip';

# NUL-containing
$b->set(1, "x\x00y\x00z");
is $b->get(1), "x\x00y\x00z", 'NUL-containing string';

# Empty
$b->set(2, "");
is $b->get(2), "", 'empty string';

# Binary bounds
$b->set(3, "\xFF\xFE\xFD\xFC");
is $b->get(3), "\xFF\xFE\xFD\xFC", 'high-byte bytes preserved';

done_testing;
