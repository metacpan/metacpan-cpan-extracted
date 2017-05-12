use strict;
use warnings;

use Test::More;
use Convert::BinHex qw(binhex_crc macbinary_crc);

# Random data
my $data = "U1SBdxdMHpA2wlW3TOgUHXZ00jvHnkyU/ndXnr9RMElXdQXUAGYrPpf4F8jO";

my $crc = binhex_crc($data);
is($crc, 35360);

my $mac_crc = macbinary_crc($data);
is($crc, 35360);

done_testing();