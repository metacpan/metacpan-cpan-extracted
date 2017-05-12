use strict;
use Test::Base::Less;
use Acme::Tategaki;
use Encode;
use utf8;

filters {
    input => [ qw/chomp/ ],
    expected => [ qw/chomp/ ],
};

for my $block (blocks) {
    is( tategaki_one_line(map {decode_utf8 $_} $block->input), decode_utf8 $block->expected );
}

done_testing;

__DATA__
===
--- input
ほげ、ふが。ほげ→
--- expected
ほ
げ
︑
ふ
が
︒
ほ
げ
↓
===
--- input
cpan
--- expected
c
p
a
n
===
--- input
ほげ
--- expected
ほ
げ
