use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::RingBuffer::Shared;

my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.ring');
close $fh;

{
    my $r = Data::RingBuffer::Shared::Int->new($path, 16);
    undef $r;
}

open(my $w, '+<', $path) or die;
binmode $w;
seek($w, 4, 0);
print $w pack('V', 99);
close $w;

my $r = eval { Data::RingBuffer::Shared::Int->new($path, 16) };
ok !$r, "version-mismatched ring rejected";
like $@ || '', qr/invalid|version|incompatible/i, "meaningful error";

open(my $w2, '+<', $path) or die;
binmode $w2;
seek($w2, 0, 0);
print $w2 pack('V', 0x12345678);
close $w2;

my $r2 = eval { Data::RingBuffer::Shared::Int->new($path, 16) };
ok !$r2, "magic-mismatched ring rejected";

done_testing;
