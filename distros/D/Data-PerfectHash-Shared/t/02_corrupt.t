use strict; use warnings; use Test::More;
use Data::PerfectHash::Shared;
use File::Temp 'tempdir';
use POSIX ();

# White-box test: pokes raw bytes of a built .phs image to simulate a
# crafted/corrupt file (dump/load invites loading a file from elsewhere,
# so this is a real trust boundary, not just belt-and-suspenders). Confirms
# load() rejects header-level corruption instead of SIGFPE/OOB, and that a
# corrupt individual str slot is reported not-present instead of reading
# outside the arena.

# Format v2: the 4th uint32 (v1's _pad) is now disp_width, the per-entry byte
# width (1..4) of the byte-packed disp[] array. Struct size/layout is unchanged,
# so the L4Q11 template and 104-byte size still hold.
my $HDR_TEMPLATE = 'L4Q11';
my $HDR_SIZE      = 104;
my @HDR_FIELDS    = qw(magic version key_type disp_width endian n bucket_count seed0
                        disp_off disp_len slots_off slots_len arena_off arena_len file_size);

sub slurp {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "open $path: $!";
    local $/;
    return scalar <$fh>;
}
sub spew {
    my ($path, $data) = @_;
    open my $fh, '>:raw', $path or die "open $path: $!";
    print $fh $data;
    close $fh;
}
sub header_of {
    my ($raw) = @_;
    my %h;
    @h{@HDR_FIELDS} = unpack($HDR_TEMPLATE, substr($raw, 0, $HDR_SIZE));
    return \%h;
}
sub with_header {
    my ($raw, %overrides) = @_;
    my $h = header_of($raw);
    $h->{$_} = $overrides{$_} for keys %overrides;
    return pack($HDR_TEMPLATE, @{$h}{@HDR_FIELDS}) . substr($raw, $HDR_SIZE);
}

my $dir = tempdir(CLEANUP => 1);

# --- header-level corruption: each of these must croak, never crash ---
my $good_path = "$dir/good.phs";
Data::PerfectHash::Shared->build_int($good_path, [map { $_ * 3 + 1 } 0 .. 49]);
my $good_raw = slurp($good_path);

my $set = Data::PerfectHash::Shared->load($good_path);
ok $set->has(1), 'sanity: an uncorrupted file loads and has() works';

# Confirm the v2 compact layout is actually in effect (not a silent regression
# to one uint32 bucket per key): 50 keys => ceil(50/6)=9 buckets, disp_width 1..4,
# disp_len == bucket_count*disp_width.
{
    my $h = header_of($good_raw);
    is $h->{version}, 2, 'format version is 2';
    is $h->{bucket_count}, 9, 'bucket_count == ceil(n/lambda) (50/6 => 9)';
    ok $h->{disp_width} >= 1 && $h->{disp_width} <= 4, 'disp_width in 1..4';
    is $h->{disp_len}, $h->{bucket_count} * $h->{disp_width}, 'disp_len == bucket_count*disp_width';
}

my %cases = (
    'bucket_count=0, n>0'   => { bucket_count => 0 },
    'key_type invalid'      => { key_type => 99 },
    'n huge (n*8 > slots_len)' => { n => 999_999_999 },
    # v2 byte-packed disp[]: disp_width must be 1..4, and
    # bucket_count*disp_width must fit disp_len (overflow-safe ph_mul_le).
    'disp_width=0 (below range)'  => { disp_width => 0 },
    'disp_width=5 (above range)'  => { disp_width => 5 },
    'disp_width huge'             => { disp_width => 0xFFFFFFFF },
    'bucket_count huge (r*width > disp_len)' => { bucket_count => 999_999_999 },
    'disp_len one byte too small' => { disp_len => 8 },   # good file: r=9, width=1 => needs 9
    # near-UINT64_MAX region offsets must fail the overflow-safe ph_region_ok,
    # never form (off+len) and wrap past the file-size bound into an OOB deref.
    # (~0 - 15) avoids a >32-bit hex literal (non-portable warning) and still
    # far exceeds any real file size.
    'disp_off near UINT64_MAX'    => { disp_off  => ~0 - 15 },
    'slots_off near UINT64_MAX'   => { slots_off => ~0 - 15 },
);
for my $name (sort keys %cases) {
    my $bad_path = "$dir/bad.phs";
    spew($bad_path, with_header($good_raw, %{ $cases{$name} }));
    my $set2 = eval { Data::PerfectHash::Shared->load($bad_path) };
    ok !$set2, "load() refuses a corrupt header ($name)";
    like $@, qr/corrupt PerfectHash image/, "  ...with the expected error ($name)";
}

# --- misaligned region offset: ph_open must reject before any unaligned load ---
{
    # slots_off is 8-byte aligned by the builder (slots[] is int64_t/PhStrSlot).
    # Shift it by one byte: [slots_off-1, slots_off-1+slots_len) is still a
    # strict subset of the original (already in-bounds) region, so this trips
    # only the alignment check, not the pre-existing bounds checks -- proving
    # the two are independent. Uses the named-field helpers above rather than
    # a hardcoded byte offset into the header (the offset of slots_off within
    # PhHeader is 64, not the 72 a naive magic(4)*3+pad(4)+endian..disp_len(6
    # quads) tally suggests -- 72 is actually slots_len's offset; see
    # phash.h's PhHeader field order. Always verify with offsetof(), don't
    # hand-add sizeof()s).
    my $h = header_of($good_raw);
    my $bad_path = "$dir/misaligned.phs";
    spew($bad_path, with_header($good_raw, slots_off => $h->{slots_off} - 1));
    my $set3 = eval { Data::PerfectHash::Shared->load($bad_path) };
    ok !$set3, 'load() refuses a misaligned slots_off';
    like $@, qr/misalign/, '  ...with the expected error (misaligned slots_off)';
}

# --- valid-but-inconsistent image (positive path): a structurally-valid header
# with GARBAGE disp[] and int slot[] content. load() must SUCCEED (ph_open
# validates structure/bounds, never content), and has()/each_key() must then
# stay in-bounds for every bucket -- a wrong answer is fine (it is the caller's
# own file), an OOB/SIGBUS is not. Complements the reject cases above; catches
# any regression that (re)introduces an unchecked disp/slot deref, and runs
# instrumented under xt/asan.t (which executes t/*.t under ASAN). ---
{
    my $raw = $good_raw;                 # 50-int image, structurally valid
    my $h   = header_of($raw);
    # Overwrite the whole disp and int-slot regions with a deterministic garbage
    # pattern; leave the header (offsets/sizes/disp_width/alignment) untouched so
    # the file still passes ph_open. Any bytes are a "valid" disp/slot value.
    my $scramble = sub {
        my ($off, $len) = @_;
        return if $len <= 0;
        substr($raw, $off, $len) = join('', map { chr(($_ * 173 + 47) & 0xFF) } 0 .. $len - 1);
    };
    $scramble->($h->{disp_off},  $h->{disp_len});
    $scramble->($h->{slots_off}, $h->{slots_len});
    my $garbage_path = "$dir/garbage.phs";
    spew($garbage_path, $raw);

    my $gset = eval { Data::PerfectHash::Shared->load($garbage_path) };
    is $@, '', 'load() accepts a structurally-valid image with garbage disp/slot content';
    SKIP: {
        skip 'load() unexpectedly failed', 2 unless $gset;
        # Hammer the disp+slot read path across many buckets (members and
        # non-members alike); every answer may be wrong, none may OOB.
        my $ok = eval { my $a = 0; $a += ($gset->has($_) ? 1 : 0) for -100 .. 20_000; 1 };
        ok $ok, 'has() over 20k keys on a garbage-content image never OOBs/crashes'
            or diag "died: $@";
        my $ok2 = eval { my $c = 0; $gset->each_key(sub { $c++ }); 1 };
        ok $ok2, 'each_key on a garbage-content image never OOBs/crashes'
            or diag "died: $@";
    }
}

# --- a single corrupt str slot must be not-present, never an OOB read ---
{
    my $str_path = "$dir/str.phs";
    my $b = Data::PerfectHash::Shared->new_builder(type => 'str');
    my @words = map { "word_$_" } 0 .. 19;
    $b->add_many(\@words);
    $b->build($str_path);

    my $raw   = slurp($str_path);
    my $h     = header_of($raw);
    my $n     = $h->{n};
    my $arena_len = $h->{arena_len};

    # Every PhStrSlot is 16 bytes: (off:Q, len:Q). Push every slot's len
    # far past the end of the arena so any lookup lands on a corrupt slot.
    my @pairs = unpack('Q*', substr($raw, $h->{slots_off}, $n * 16));
    for (my $i = 1; $i < @pairs; $i += 2) { $pairs[$i] = $arena_len + 999_999; }
    substr($raw, $h->{slots_off}, $n * 16) = pack('Q*', @pairs);

    my $corrupt_path = "$dir/str_corrupt.phs";
    spew($corrupt_path, $raw);

    my $cset = eval { Data::PerfectHash::Shared->load($corrupt_path) };
    is $@, '', 'load() accepts a file whose slot region is aggregate-valid (corruption is per-slot)';

    SKIP: {
        skip 'load() unexpectedly failed', 1 unless $cset;
        my $result = eval { $cset->has($words[0]) };
        ok !$@, 'has() on a member whose slot is corrupt does not crash'
            or diag "died instead: $@";
        ok !$result, 'has() on a member whose slot is corrupt reports not-present';
    }
}

# --- each_key must skip a corrupt slot, not SIGBUS / OOB-read the arena ---
{
    my $str_path = "$dir/str_ek.phs";
    my $b = Data::PerfectHash::Shared->new_builder(type => 'str');
    my @words = map { "ekword_$_" } 0 .. 19;
    $b->add_many(\@words);
    $b->build($str_path);

    my $raw = slurp($str_path);
    my $h   = header_of($raw);
    my $n   = $h->{n};
    my $arena_len = $h->{arena_len};

    # Corrupt exactly ONE slot's len (slot 0) far past the arena; leave the
    # other n-1 slots intact so we can confirm each_key still visits them.
    my @pairs = unpack('Q*', substr($raw, $h->{slots_off}, $n * 16));
    $pairs[1] = $arena_len + 999_999;   # slot 0's len field
    substr($raw, $h->{slots_off}, $n * 16) = pack('Q*', @pairs);

    my $corrupt_path = "$dir/str_ek_corrupt.phs";
    spew($corrupt_path, $raw);

    my $cset = eval { Data::PerfectHash::Shared->load($corrupt_path) };
    is $@, '', 'load() accepts a file whose slot region is aggregate-valid (single corrupt slot)';

    SKIP: {
        skip 'load() unexpectedly failed', 2 unless $cset;

        # A corrupt slot's (off,len) can drive an out-of-bounds mmap read at
        # the C level (SIGBUS) -- that is not a Perl exception eval{} can
        # trap, so isolate the call in a child process and inspect how it
        # died instead of trusting eval to catch it.
        my $result_file = "$dir/each_key_result";
        my $kid = fork;
        if (!defined $kid) {
            skip "fork failed: $!", 2;
        } elsif ($kid == 0) {
            my %seen;
            eval { $cset->each_key(sub { $seen{$_[0]}++ }) };
            if (open my $fh, '>', $result_file) {
                print $fh ($@ ? "died:$@" : "ok:" . scalar(keys %seen));
                close $fh;
            }
            POSIX::_exit($@ ? 1 : 0);   # skip END/DESTROY: don't touch the parent's tempdir
        }
        waitpid($kid, 0);
        my $sig = $? & 127;
        ok $sig == 0, "each_key on a set with one corrupt slot does not crash (signal=$sig)"
            or diag "child terminated by signal $sig (raw \$?=$?)";

        my $result = eval { slurp($result_file) } // '(no result file -- child likely crashed before writing)';
        is $result, 'ok:' . ($n - 1), 'each_key skips exactly the corrupt slot, visits the remaining n-1 keys';
    }
}

done_testing;
