use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::BitSet::Shared;

my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.bs');
close $fh;

{
    my $b = Data::BitSet::Shared->new($path, 128);
    undef $b;
}

# Corrupt version field (offset 4)
open(my $w, '+<', $path) or die;
binmode $w;
seek($w, 4, 0);
print $w pack('V', 99);
close $w;

my $r = eval { Data::BitSet::Shared->new($path, 128) };
ok !$r, "version-mismatched bitset rejected";
like $@ || '', qr/invalid|version|incompatible/i, "meaningful error";

# Corrupt magic (offset 0)
open(my $w2, '+<', $path) or die;
binmode $w2;
seek($w2, 0, 0);
print $w2 pack('V', 0x12345678);
close $w2;

my $r2 = eval { Data::BitSet::Shared->new($path, 128) };
ok !$r2, "magic-mismatched bitset rejected";

done_testing;
