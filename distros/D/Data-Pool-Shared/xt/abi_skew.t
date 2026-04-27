use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

# ABI-skew rejection: a file whose header version mismatches the runtime
# VERSION constant must be rejected cleanly, not crash or silently misread.

use Data::Pool::Shared;

my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.pool');
close $fh;

# Create a legitimate pool, then corrupt the version field.
{
    my $p = Data::Pool::Shared::I64->new($path, 8);
    undef $p;
}

# PoolHeader: magic(u32), version(u32) at offset 4.
open(my $w, '+<', $path) or die "open: $!";
binmode $w;
seek($w, 4, 0);
print $w pack('V', 99);   # bogus version
close $w;

my $err;
my $p = eval { Data::Pool::Shared::I64->new($path, 8) };
$err = $@ unless $p;
ok !$p, "version-mismatched pool rejected";
like $err || '', qr/invalid|version|incompatible/i, "meaningful error: $err";

# Similarly via new_from_fd
open(my $rh, '<', $path) or die;
my $fd = fileno($rh);
my $p2 = eval { Data::Pool::Shared::I64->new_from_fd($fd) };
ok !$p2, "new_from_fd rejects version skew";
close $rh;

# Corrupt magic (first 4 bytes)
open(my $w2, '+<', $path) or die;
binmode $w2;
seek($w2, 0, 0);
print $w2 pack('V', 0x12345678);
close $w2;

my $p3 = eval { Data::Pool::Shared::I64->new($path, 8) };
ok !$p3, "magic-mismatched pool rejected";

done_testing;
