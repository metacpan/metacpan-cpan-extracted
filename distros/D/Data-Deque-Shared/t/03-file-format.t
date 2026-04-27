use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Deque::Shared;

# v2 files created by this release must reject v1 magic ("DEQ1") on reopen,
# preventing silent data corruption if an older on-disk deque is encountered.

my $dir = tempdir(CLEANUP => 1);
my $path = "$dir/v1.deq";

# Fabricate a minimal v1-ish header: 128 bytes + some data, magic = "DEQ1".
# (Actual v1 size doesn't matter; we only need the magic to mismatch v2.)
open my $fh, '>', $path or die "open: $!";
my $header = "\x31\x51\x45\x44"          # magic = 0x44455131 LE = "DEQ1"
           . pack('V', 1)                # version = 1
           . pack('V', 8)                # elem_size
           . pack('V', 0)                # variant_id
           . pack('Q<', 16)              # capacity
           . pack('Q<', 128 + 16*8)      # total_size
           . pack('Q<', 128)             # data_off
           . "\0" x (128 - 40);          # pad
syswrite $fh, $header;
syswrite $fh, "\0" x (16 * 8);           # dummy data
close $fh;

my $err;
my $dq = eval { Data::Deque::Shared::Int->new($path, 16) };
$err = $@;
ok !$dq, 'v1 file rejected (no handle returned)';
like $err, qr/invalid deque file|magic|version|variant|total_size/i,
    'croak message names the validation failure';

done_testing;
