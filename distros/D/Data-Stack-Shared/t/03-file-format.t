use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Stack::Shared;

# v2 files created by this release must reject v1 magic ("STK1") on reopen.

my $dir = tempdir(CLEANUP => 1);
my $path = "$dir/v1.stk";

open my $fh, '>', $path or die "open: $!";
my $header = "\x31\x4B\x54\x53"          # magic = 0x53544B31 LE = "STK1"
           . pack('V', 1)                # version = 1
           . pack('V', 8)                # elem_size
           . pack('V', 0)                # variant_id
           . pack('Q<', 16)              # capacity
           . pack('Q<', 128 + 16*8)      # total_size
           . pack('Q<', 128)             # data_off
           . "\0" x (128 - 40);          # pad
syswrite $fh, $header;
syswrite $fh, "\0" x (16 * 8);
close $fh;

my $err;
my $s = eval { Data::Stack::Shared::Int->new($path, 16) };
$err = $@;
ok !$s, 'v1 stack file rejected (no handle returned)';
like $err, qr/invalid|incompatible|magic|version|variant/i,
    'croak message names the validation failure';

done_testing;
