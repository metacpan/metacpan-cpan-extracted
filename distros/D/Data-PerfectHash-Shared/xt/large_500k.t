use strict; use warnings; use Test::More; use Config; use POSIX ();
use File::Temp 'tempdir';
use Data::PerfectHash::Shared;

# Convergence + exactness of the v2 compact index at the top of the tested
# range (n = 500k). This is the size the empirical lambda sweep proved
# converges on the first placement attempt (see the compact-index report), so
# it doubles as a regression guard: a build that failed to converge would
# croak here, and any index/lookup arithmetic mismatch would surface as a
# false negative or false positive over half a million keys.
#
# The image is built by the parent and then loaded + queried in a FRESH forked
# process that never saw the builder, proving the on-disk image is fully
# self-contained (the whole point of a shared, mmap'd artifact).
plan skip_all => 'set LARGE=1 to run (slow: builds 500k-key images)' unless $ENV{LARGE};
plan skip_all => 'fork required' unless $Config{d_fork};

my $dir = tempdir(CLEANUP => 1);
my $N   = 500_000;

# Read a handful of header fields straight off disk to confirm the compact
# layout (bucket_count = ceil(N/lambda), 1..4-byte packed disp) and to report
# the achieved index bits/key.
sub header {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "open $path: $!";
    read $fh, my $buf, 104; close $fh;
    my %h; @h{qw(magic version key_type disp_width endian n bucket_count seed0
                 disp_off disp_len slots_off slots_len arena_off arena_len file_size)}
        = unpack 'L4Q11', $buf;
    return \%h;
}

sub check_in_child {
    my ($path, $members, $nonmembers) = @_;
    my $rf = "$path.result";
    my $kid = fork; die "fork: $!" unless defined $kid;
    if (!$kid) {
        my $set = Data::PerfectHash::Shared->load($path);   # fresh mmap, never saw the builder
        my $hits = 0; $set->has($_) and $hits++ for @$members;
        my $fp   = 0; $set->has($_) and $fp++   for @$nonmembers;
        open my $w, '>', $rf or POSIX::_exit(3);
        print $w "$hits,$fp,", $set->count; close $w;
        POSIX::_exit(0);
    }
    waitpid $kid, 0;
    is $? & 127, 0, "child that loaded $path did not crash (signal ".($?&127).")";
    open my $r, '<', $rf or do { fail "no result from child for $path"; return };
    my ($hits, $fp, $count) = split /,/, <$r>; close $r;
    return ($hits, $fp, $count);
}

# ---------------- int: 500k distinct odd keys ----------------
{
    my $p = "$dir/big_int.phs";
    my @ids = map { $_ * 2 + 1 } 0 .. $N - 1;      # odd => even values are guaranteed non-members
    my $t0 = time;
    Data::PerfectHash::Shared->build_int($p, \@ids);
    my $secs = time - $t0;

    my $h = header($p);
    is $h->{version}, 2, 'int: on-disk format version 2';
    is $h->{n}, $N, 'int: n == 500k distinct keys';
    is $h->{bucket_count}, int(($N + 5) / 6), 'int: bucket_count == ceil(n/6)';
    ok $h->{disp_width} >= 1 && $h->{disp_width} <= 4, "int: disp_width in 1..4 (got $h->{disp_width})";
    is $h->{disp_len}, $h->{bucket_count} * $h->{disp_width}, 'int: disp_len == bucket_count*disp_width';
    my $bpk = $h->{disp_len} * 8 / $N;
    diag sprintf 'int: built 500k keys in %ds; index = %d bytes (%.2f bits/key), disp_width=%d, file=%d bytes',
        $secs, $h->{disp_len}, $bpk, $h->{disp_width}, $h->{file_size};

    my @non = map { $_ * 2 } 0 .. $N - 1;           # 500k even non-members
    my ($hits, $fp, $count) = check_in_child($p, \@ids, \@non);
    is $count, $N,   'int: loaded count == 500k';
    is $hits,  $N,   'int: every one of 500k members present (zero false negatives)';
    is $fp,    0,    'int: 500k non-members all absent (zero false positives)';
}

# ---------------- str: 500k distinct keys ----------------
{
    my $p = "$dir/big_str.phs";
    my @w   = map { "m:$_" } 0 .. $N - 1;           # members
    my @non = map { "x:$_" } 0 .. $N - 1;           # disjoint non-members
    my $t0 = time;
    Data::PerfectHash::Shared->build_str($p, \@w);
    my $secs = time - $t0;

    my $h = header($p);
    is $h->{bucket_count}, int(($N + 5) / 6), 'str: bucket_count == ceil(n/6)';
    ok $h->{disp_width} >= 1 && $h->{disp_width} <= 4, "str: disp_width in 1..4 (got $h->{disp_width})";
    my $bpk = $h->{disp_len} * 8 / $N;
    diag sprintf 'str: built 500k keys in %ds; index = %d bytes (%.2f bits/key), disp_width=%d',
        $secs, $h->{disp_len}, $bpk, $h->{disp_width};

    my ($hits, $fp, $count) = check_in_child($p, \@w, \@non);
    is $count, $N, 'str: loaded count == 500k';
    is $hits,  $N, 'str: every one of 500k members present (zero false negatives)';
    is $fp,    0,  'str: 500k non-members all absent (zero false positives)';
}

done_testing;
