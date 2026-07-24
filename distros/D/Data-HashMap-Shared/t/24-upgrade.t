use strict;
use warnings;
use Test::More;
use Data::HashMap::Shared;
use File::Temp qw(tempdir);

# On-disk layout constant: SHM_READER_SLOTS(1024) * sizeof(ShmReaderSlot)(16).
# The v10 format inserts a 128-byte (SHM_OCC_BYTES) occupancy bitmap right after
# this reader-slot table; a v9 file is identical minus that region.
my $RSS = 1024 * 16;
my $OCC = 128;

# native-endian header field readers (x86-64 LE; module writes a raw struct)
sub slurp { open my $f, '<:raw', $_[0] or die "$_[0]: $!"; local $/; my $d = <$f>; close $f; $d }
sub ver_of { unpack 'L', substr slurp($_[0]), 4, 4 }

# Down-convert a current (v10) file to the previous on-disk format (v9): drop the
# occ region and patch version/total_size/arena_off. This emulates a file written
# by the last released version, so we can exercise the real upgrade path.
sub to_v9 {
    my ($src, $dst) = @_;
    my $d = slurp($src);
    die "source is not v10" unless unpack('L', substr($d, 4, 4)) == 10;
    my $total     = unpack 'Q', substr($d, 32, 8);
    my $arena_off = unpack 'Q', substr($d, 56, 8);
    my $rso       = unpack 'Q', substr($d, 80, 8);
    my $occ_off   = $rso + $RSS;
    my $v9 = substr($d, 0, $occ_off) . substr($d, $occ_off + $OCC);   # remove occ region
    substr($v9,  4, 4) = pack 'L', 9;
    substr($v9, 32, 8) = pack 'Q', $total - $OCC;
    substr($v9, 56, 8) = pack 'Q', ($arena_off ? $arena_off - $OCC : 0);
    open my $o, '>:raw', $dst or die "$dst: $!"; print $o $v9; close $o;
}

my $dir = tempdir(CLEANUP => 1);

# ---- II: integer values (no arena) ----
{
    my $v10 = "$dir/ii.v10";
    { my $h = Data::HashMap::Shared::II->new($v10, 64);
      $h->put(1, 100); $h->put(2, 200); $h->put(42, 4242); $h->sync; }
    my $f = "$dir/ii.mig";
    to_v9($v10, $f);
    is ver_of($f), 9, 'II: synthesized a v9 file';
    is +Data::HashMap::Shared->upgrade_file($f), 1, 'II: upgrade_file -> 1 (upgraded)';
    is ver_of($f), 10, 'II: file is now v10';
    is +Data::HashMap::Shared->upgrade_file($f), 0, 'II: idempotent (already current -> 0)';
    my $h = Data::HashMap::Shared::II->new($f, 64);
    is $h->get(1),  100,  'II: value preserved (1)';
    is $h->get(2),  200,  'II: value preserved (2)';
    is $h->get(42), 4242, 'II: value preserved (42)';
    is $h->size, 3,       'II: size preserved';
}

# ---- SS: string values (arena shift is exercised) ----
{
    my $v10 = "$dir/ss.v10";
    { my $h = Data::HashMap::Shared::SS->new($v10, 64);
      $h->put("alpha", "one"); $h->put("beta", "two"); $h->put("gamma", "three"); $h->sync; }
    my $f = "$dir/ss.mig";
    to_v9($v10, $f);
    is ver_of($f), 9, 'SS: synthesized a v9 file';
    is +Data::HashMap::Shared->upgrade_file($f), 1, 'SS: upgraded';
    is ver_of($f), 10, 'SS: file is now v10';
    my $h = Data::HashMap::Shared::SS->new($f, 64);
    is $h->get("alpha"), "one",   'SS: arena value preserved (alpha)';
    is $h->get("beta"),  "two",   'SS: arena value preserved (beta)';
    is $h->get("gamma"), "three", 'SS: arena value preserved (gamma)';
}

# ---- error paths ----
eval { Data::HashMap::Shared->upgrade_file("$dir/does-not-exist") };
like $@, qr/open .*(No such file|open)/, 'missing file croaks';

my $bad = "$dir/bad";
{ open my $b, '>:raw', $bad or die; print $b ("\0" x 4096); close $b; }
eval { Data::HashMap::Shared->upgrade_file($bad) };
like $@, qr/bad magic/, 'non-HashMap file croaks (bad magic)';

# ---- sharded map: each shard is a normal backing file (PREFIX.N); upgrade all ----
{
    my $prefix = "$dir/sharded";
    { my $h = Data::HashMap::Shared::II->new_sharded($prefix, 2, 64);
      $h->put($_, $_ * 10) for 1 .. 20; $h->sync; }
    my @shards = sort glob("$prefix.*");
    is scalar(@shards), 2, 'sharded: two shard files created (PREFIX.0, PREFIX.1)';
    to_v9($_, $_) for @shards;   # down-convert each shard in place
    is_deeply [ map { ver_of($_) } @shards ], [ 9, 9 ], 'sharded: both shards are v9';
    my $up = 0;
    $up += Data::HashMap::Shared->upgrade_file($_) for @shards;
    is $up, 2, 'sharded: both shard files upgraded';
    my $h = Data::HashMap::Shared::II->new_sharded($prefix, 2, 64);
    my $ok = 1; ($h->get($_) // -1) == $_ * 10 or $ok = 0 for 1 .. 20;
    ok $ok, 'sharded: all 20 keys preserved across shards after upgrade';
}

# already-current native file: no-op
{
    my $cur = "$dir/cur";
    { my $h = Data::HashMap::Shared::II->new($cur, 64); $h->put(7, 7); $h->sync; }
    is +Data::HashMap::Shared->upgrade_file($cur), 0, 'a current v10 file is left untouched (-> 0)';
}

# exact-version gate: a source that is neither current (v10) nor the supported
# predecessor (v9) is refused, not force-migrated.
{
    my $u = "$dir/unsupported";
    { my $h = Data::HashMap::Shared::II->new($u, 64); $h->put(1, 1); $h->sync; }
    my $d = slurp($u);
    substr($d, 4, 4) = pack 'L', 8;   # stamp an older, unsupported on-disk version
    { open my $o, '>:raw', $u or die; print $o $d; close $o; }
    eval { Data::HashMap::Shared->upgrade_file($u) };
    like $@, qr/unsupported source version 8 \(migrates 9 -> 10 only\)/,
        'exact-version gate: an unsupported source version is refused';
}

done_testing;
