use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::Heap::Shared;

my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.heap');
close $fh;

{
    my $h = Data::Heap::Shared->new($path, 16);
    undef $h;
}

open(my $w, '+<', $path) or die;
binmode $w;
seek($w, 4, 0);
print $w pack('V', 99);
close $w;

my $r = eval { Data::Heap::Shared->new($path, 16) };
ok !$r, "version-mismatched heap rejected";
like $@ || '', qr/invalid|version|incompatible/i, "meaningful error";

open(my $w2, '+<', $path) or die;
binmode $w2;
seek($w2, 0, 0);
print $w2 pack('V', 0x12345678);
close $w2;

my $r2 = eval { Data::Heap::Shared->new($path, 16) };
ok !$r2, "magic-mismatched heap rejected";

done_testing;
