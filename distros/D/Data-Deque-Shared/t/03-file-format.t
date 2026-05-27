use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Deque::Shared;

# v2 files created by this release must reject v1 magic ("DEQ1") on reopen,
# preventing silent data corruption if an older on-disk deque is encountered.

my $dir = tempdir(CLEANUP => 1);

# --- v1 magic rejected ---------------------------------------------
{
    my $path = "$dir/v1.deq";
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

    my $dq = eval { Data::Deque::Shared::Int->new($path, 16) };
    my $err = $@;
    ok !$dq, 'v1 file rejected (no handle returned)';
    like $err, qr/invalid deque file|magic|version|variant|total_size/i,
        'croak message names the validation failure';
}

# --- variant-specific elem_size: Str with too-small elem_size rejected ---
# A tampered file claiming variant=Str but elem_size < sizeof(uint32_t)+1
# would let the XS push path write a 4-byte length prefix into a smaller
# buffer. Hardening: validate the elem_size lower bound per variant.
{
    my $path = "$dir/tampered_str.deq";
    my $cap = 16;
    my $bad_elem_size = 3;  # less than sizeof(uint32_t)+1 = 5
    my $hdr_size = 128;
    my $data_end = $hdr_size + $cap * $bad_elem_size;
    my $ctl_off = ($data_end + 7) & ~7;
    my $total = $ctl_off + $cap * 8;

    open my $fh, '>', $path or die "open: $!";
    my $header = "\x32\x51\x45\x44"          # magic = "DEQ2"
               . pack('V', 2)                # version = 2
               . pack('V', $bad_elem_size)   # elem_size (illegal for Str)
               . pack('V', 1)                # variant_id = DEQ_VAR_STR
               . pack('Q<', $cap)            # capacity
               . pack('Q<', $total)          # total_size
               . pack('Q<', $hdr_size)       # data_off
               . pack('Q<', $ctl_off)        # ctl_off
               . "\0" x ($hdr_size - 48);    # pad to 128
    syswrite $fh, $header;
    syswrite $fh, "\0" x ($total - $hdr_size);
    close $fh;

    my $dq = eval { Data::Deque::Shared::Str->new($path, $cap, 8) };
    my $err = $@;
    ok !$dq, 'Str file with elem_size<5 rejected';
    like $err, qr/invalid deque/i, 'rejection croaks with validation message';
}

# --- variant-specific elem_size: Int with wrong elem_size rejected ---
{
    my $path = "$dir/tampered_int.deq";
    my $cap = 16;
    my $bad_elem_size = 4;  # Int requires exactly sizeof(int64_t) = 8
    my $hdr_size = 128;
    my $data_end = $hdr_size + $cap * $bad_elem_size;
    my $ctl_off = ($data_end + 7) & ~7;
    my $total = $ctl_off + $cap * 8;

    open my $fh, '>', $path or die "open: $!";
    my $header = "\x32\x51\x45\x44"          # magic = "DEQ2"
               . pack('V', 2)                # version = 2
               . pack('V', $bad_elem_size)   # elem_size (illegal for Int)
               . pack('V', 0)                # variant_id = DEQ_VAR_INT
               . pack('Q<', $cap)
               . pack('Q<', $total)
               . pack('Q<', $hdr_size)
               . pack('Q<', $ctl_off)
               . "\0" x ($hdr_size - 48);
    syswrite $fh, $header;
    syswrite $fh, "\0" x ($total - $hdr_size);
    close $fh;

    my $dq = eval { Data::Deque::Shared::Int->new($path, $cap) };
    my $err = $@;
    ok !$dq, 'Int file with elem_size != 8 rejected';
    like $err, qr/invalid deque/i, 'rejection croaks with validation message';
}

done_testing;
