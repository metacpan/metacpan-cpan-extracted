use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use File::Temp ();
use File::Spec ();

use Data::HashMap::Shared::I16;
use Data::HashMap::Shared::I32;
use Data::HashMap::Shared::II;
use Data::HashMap::Shared::I16S;
use Data::HashMap::Shared::I32S;
use Data::HashMap::Shared::IS;
use Data::HashMap::Shared::SI16;
use Data::HashMap::Shared::SI32;
use Data::HashMap::Shared::SI;
use Data::HashMap::Shared::SS;

sub tmpfile { File::Temp::tempnam(File::Spec->tmpdir, 'shm_addttl') . '.shm' }

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 30);

    ok(shm_ii_add_ttl $map, 1, 100, 120, 'II add_ttl kw: succeeds on new key');
    is($map->get(1), 100, 'II add_ttl: value stored');
    my $rem = shm_ii_ttl_remaining $map, 1;
    ok($rem > 30, "II add_ttl: TTL > default (rem=$rem)");
    ok($rem <= 120, "II add_ttl: TTL within explicit value (rem=$rem)");

    ok(!(shm_ii_add_ttl $map, 1, 999, 5), 'II add_ttl: fails on existing key');
    is($map->get(1), 100, 'II add_ttl: existing value unchanged on collision');
    my $rem2 = shm_ii_ttl_remaining $map, 1;
    ok($rem2 > 30, "II add_ttl collision: TTL unchanged (rem=$rem2)");

    ok(shm_ii_add_ttl $map, 2, 200, 0, 'II add_ttl: succeeds with ttl=0');
    my $perm = shm_ii_ttl_remaining $map, 2;
    is($perm, 0, 'II add_ttl: ttl=0 → permanent');

    ok($map->add_ttl(3, 300, 90), 'II add_ttl: method form');
    is($map->get(3), 300, 'II add_ttl method: value stored');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SI->new($path, 1000, 0, 30);
    ok(shm_si_add_ttl $map, "k", 10, 60, 'SI add_ttl: succeeds');
    ok(!(shm_si_add_ttl $map, "k", 20, 60), 'SI add_ttl: fails on existing');
    is($map->get("k"), 10, 'SI add_ttl: value unchanged on collision');
    my $rem = shm_si_ttl_remaining $map, "k";
    ok($rem > 30 && $rem <= 60, "SI add_ttl: TTL applied (rem=$rem)");
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::IS->new($path, 1000, 0, 30);
    ok(shm_is_add_ttl $map, 1, "hello", 60, 'IS add_ttl: succeeds');
    is($map->get(1), "hello", 'IS add_ttl: value stored');
    ok(!(shm_is_add_ttl $map, 1, "world", 60), 'IS add_ttl: fails on existing');
    is($map->get(1), "hello", 'IS add_ttl: value unchanged on collision');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 1000, 0, 30);
    ok(shm_ss_add_ttl $map, "k", "v1", 60, 'SS add_ttl: succeeds');
    is($map->get("k"), "v1", 'SS add_ttl: value stored');
    ok(!(shm_ss_add_ttl $map, "k", "v2", 60), 'SS add_ttl: fails on existing');
    is($map->get("k"), "v1", 'SS add_ttl: value unchanged on collision');
    my $rem = shm_ss_ttl_remaining $map, "k";
    ok($rem > 30 && $rem <= 60, "SS add_ttl: per-key TTL applied (rem=$rem)");
    unlink $path;
}

# smoke test per remaining variant; the logic is shared templated C
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::I16->new($path, 1000, 0, 30);
    ok($map->add_ttl(1, 10, 90), 'I16 add_ttl: succeeds');
    ok(!$map->add_ttl(1, 20, 90), 'I16 add_ttl: fails on existing');
    is($map->get(1), 10, 'I16 add_ttl: value unchanged on collision');
    my $rem = shm_i16_ttl_remaining $map, 1;
    ok($rem > 30 && $rem <= 90, "I16 add_ttl: per-key TTL applied (rem=$rem)");
    unlink $path;
}
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::I32->new($path, 1000, 0, 30);
    ok($map->add_ttl(1, 100, 90), 'I32 add_ttl: succeeds');
    ok(!$map->add_ttl(1, 200, 90), 'I32 add_ttl: fails on existing');
    is($map->get(1), 100, 'I32 add_ttl: value unchanged');
    unlink $path;
}
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SI16->new($path, 1000, 0, 30);
    ok($map->add_ttl("k", 10, 90), 'SI16 add_ttl: succeeds');
    ok(!$map->add_ttl("k", 20, 90), 'SI16 add_ttl: fails on existing');
    is($map->get("k"), 10, 'SI16 add_ttl: value unchanged');
    unlink $path;
}
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SI32->new($path, 1000, 0, 30);
    ok($map->add_ttl("k", 100, 90), 'SI32 add_ttl: succeeds');
    ok(!$map->add_ttl("k", 200, 90), 'SI32 add_ttl: fails on existing');
    is($map->get("k"), 100, 'SI32 add_ttl: value unchanged');
    unlink $path;
}
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::I16S->new($path, 1000, 0, 30);
    ok($map->add_ttl(1, "hello", 90), 'I16S add_ttl: succeeds');
    ok(!$map->add_ttl(1, "world", 90), 'I16S add_ttl: fails on existing');
    is($map->get(1), "hello", 'I16S add_ttl: value unchanged');
    unlink $path;
}
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::I32S->new($path, 1000, 0, 30);
    ok($map->add_ttl(1, "hello", 90), 'I32S add_ttl: succeeds');
    ok(!$map->add_ttl(1, "world", 90), 'I32S add_ttl: fails on existing');
    is($map->get(1), "hello", 'I32S add_ttl: value unchanged');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 100);
    eval { $map->add_ttl(1, 1, 60) };
    like($@, qr/TTL-enabled/, 'add_ttl croaks on non-TTL map');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 100, 0, 30);
    shm_ii_put_ttl $map, 1, 100, 1;
    Time::HiRes::sleep(1.2);
    ok(shm_ii_add_ttl $map, 1, 200, 60, 'II add_ttl: succeeds when prior entry expired');
    is($map->get(1), 200, 'II add_ttl: re-added value visible');
    unlink $path;
}

# a ttl of 2**32 would wrap to 0 (permanent) if cast to uint32 unchecked
{
    my $path = tmpfile();
    my $map  = Data::HashMap::Shared::II->new($path, 100, 0, 30);
    $map->put(1, 1);

    for my $method (qw(put_ttl add_ttl update_ttl)) {
        my $ok = eval { $map->$method(2, 2, 2**32); 1 };
        ok !$ok, "$method rejects a ttl of 2**32 instead of truncating it";
        like $@, qr/ttl .* exceeds the maximum/, "  ...with a range error";
    }
    my $ok = eval { $map->set_ttl(1, 2**32); 1 };
    ok !$ok, 'set_ttl rejects a ttl of 2**32';

    ok !eval { $map->flush_expired_partial(2**32); 1 },
        'flush_expired_partial rejects a limit of 2**32 instead of scanning one slot';

    ok eval { $map->put_ttl(3, 3, 120); 1 }, 'an in-range ttl still works';
    cmp_ok $map->ttl_remaining(3), '>=', 119, '  ...and is stored (allowing one coarse-clock tick)';
    cmp_ok $map->ttl_remaining(3), '<=', 120, '  ...and not rounded up';
    unlink $path;
}

# expiry is compared in several independent places (SHM_IS_EXPIRED, get,
# ttl_remaining, flush_expired_partial, get_multi's inline copies); sample all
# of them across the whole boundary so they cannot drift apart by a second
{
    my $dir  = File::Temp::tempdir(CLEANUP => 1);
    my $path = File::Spec->catfile($dir, 'boundary.shm');
    my $map  = Data::HashMap::Shared::II->new($path, 64, 0, 1);
    # get_multi inlines its own check per variant file, so watch a string-key
    # one too
    my $spath = File::Spec->catfile($dir, 'boundary-ss.shm');
    my $smap  = Data::HashMap::Shared::SS->new($spath, 64, 0, 1);
    # flush_expired_partial's verdict is destructive, so give every reading its
    # own map
    my @fmaps = map {
        my $m = Data::HashMap::Shared::II->new(
            File::Spec->catfile($dir, "boundary-flush-$_.shm"), 64, 0, 1);
        $m->put(7, 70);
        $m;
    } 1 .. 200;

    # the watched entries go in last so they cannot die before the first sample
    $map->put(7, 70);
    $smap->put('seven', 'seventy');

    # an entry can die between two readings of one sample; re-read at once and
    # count only a disagreement that persists
    my $sample = sub {
        my $by_get = defined($map->get(7)) ? 1 : 0;
        my ($wv)   = $map->get_with_ttl(7);
        my ($mv)   = $map->get_multi(7);
        my $n = grep { $_ != $by_get }
            (($map->exists(7) ? 1 : 0),
             ((grep { $_ == 7 } $map->keys) ? 1 : 0),
             (defined($map->ttl_remaining(7)) ? 1 : 0),
             (defined($wv) ? 1 : 0),
             (defined($mv) ? 1 : 0));
        my $s_get  = defined($smap->get('seven')) ? 1 : 0;
        my ($s_mv) = $smap->get_multi('seven');
        $n++ if $s_get != (defined($s_mv) ? 1 : 0);
        if (my $fmap = shift @fmaps) {
            my $f_get = defined($fmap->get(7)) ? 1 : 0;
            $fmap->flush_expired_partial($fmap->capacity);
            $n++ if $f_get != ($fmap->size ? 1 : 0);
        }
        return ($by_get, $n);
    };

    my ($disagreements, $samples, $saw_live, $saw_dead) = (0, 0, 0, 0);
    my $deadline = Time::HiRes::time() + 2.2;
    while (Time::HiRes::time() < $deadline) {
        my ($by_get, $n) = $sample->();
        $n = ($sample->())[1] if $n;
        $disagreements++ if $n;
        $saw_live++ if $by_get;
        $saw_dead++ unless $by_get;
        $samples++;
        select undef, undef, undef, 0.05;
    }
    cmp_ok($samples, '>', 20, 'sampled the expiry boundary repeatedly');
    ok($saw_live,  '  ... saw the entry alive');
    ok($saw_dead,  '  ... and saw it expire');
    is($disagreements, 0,
       'every accessor agrees about liveness at every instant');
}

done_testing;
