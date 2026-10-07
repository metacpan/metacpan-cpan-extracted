use strict;
use warnings;
use Test::More;
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

my $dir = File::Temp::tempdir(CLEANUP => 1);
sub path { File::Spec->catfile($dir, "$_[0].shm") }
sub maps_count {
    my ($re) = @_;
    open my $fh, '<', '/proc/self/maps' or die "no /proc/self/maps: $!";
    my $n = 0;
    $n++ while <$fh> =~ $re;
    return $n;
}

my @variants = qw(I16 I32 II I16S I32S IS SI16 SI32 SI SS);
sub kv { $_[0] =~ /^S/ ? 'k' : 1, $_[0] =~ /S$/ ? 'v' : 1 }

# Instance-form constructors bless into the object's class and return a
# working map, in every variant.  Blessing into the stringified invocant
# instead leaves an object whose methods all die and whose DESTROY guard
# never fires, leaking the handle and its mapping.
for my $v (@variants) {
    my $class = "Data::HashMap::Shared::$v";
    my ($k, $val) = kv($v);
    my $seed = $class->new(path("seed-$v"), 100);
    my $m = $seed->new(path("inst-$v"), 100);
    is ref($m), $class, "$v: instance-form new blesses into the variant class";
    ok $m->put($k, $val), "$v: ... and the map accepts puts";
    is $m->get($k), $val, "$v: ... and gets";
    my $anon = $seed->new(undef, 64);
    is ref($anon), $class, "$v: instance-form anonymous new blesses correctly";
}

{
    package My::InstII; our @ISA = ('Data::HashMap::Shared::II');
    package main;
    my $s = My::InstII->new(undef, 64);
    is ref($s->new(undef, 64)), 'My::InstII', 'instance-form new of a subclass object blesses into the subclass';
}

# The other constructors take the instance form too.
{
    my $seed = Data::HashMap::Shared::II->new(path('seed-sh'), 100);
    my $sh = $seed->new_sharded(path('inst-sh'), 2, 100);
    is ref($sh), 'Data::HashMap::Shared::II', 'instance-form new_sharded blesses correctly';
    ok $sh->put(1, 2) && $sh->get(1) == 2, '... and the sharded map works';
    my $mf = $seed->new_memfd(undef, 100);
    is ref($mf), 'Data::HashMap::Shared::II', 'instance-form new_memfd blesses correctly';
    ok $mf->put(3, 4) && $mf->get(3) == 4, '... and the memfd map works';
    my $fdup = $mf->new_from_fd($mf->memfd);
    is ref($fdup), 'Data::HashMap::Shared::II', 'instance-form new_from_fd blesses correctly';
    is $fdup->get(3), 4, '... and sees the memfd entries';
    $seed->put(7, 8);
    $seed->freeze;
    my $ro = $seed->new_readonly(path('seed-sh'));
    is ref($ro), 'Data::HashMap::Shared::II', 'instance-form new_readonly blesses correctly';
    is $ro->get(7), 8, '... and the frozen entries read back';
}

# Dropping instance-form maps unmaps them: no handle or mapping leak.
SKIP: {
    skip 'needs a readable /proc/self/maps', 1 unless -r '/proc/self/maps';
    my $seed = Data::HashMap::Shared::II->new(path('leak-seed'), 100);
    my $lp = path('leak');
    my $base = maps_count(qr/\Q$lp\E/);
    { my @o = map { $seed->new($lp, 100) } 1 .. 3; }
    is maps_count(qr/\Q$lp\E/), $base, 'dropped instance-form maps unmap';
}

# Negative sizes croak naming the problem, not a wrapped UV.
{
    my $neg = qr/must not be negative/;
    my $max = qr/exceeds the maximum of 4294967295/;
    ok !eval { Data::HashMap::Shared::II->new(path('n1'), -5); 1 }, 'new with negative max_entries croaks';
    like $@, $neg, '... saying it must not be negative';
    ok !eval { Data::HashMap::Shared::II->new(path('n2'), 100, -1); 1 }, 'new with negative lru_max croaks';
    like $@, $neg, '... saying it must not be negative';
    ok !eval { Data::HashMap::Shared::II->new(path('n3'), 100, 0, -1); 1 }, 'new with negative ttl_default croaks';
    like $@, $neg, '... saying it must not be negative';
    ok !eval { Data::HashMap::Shared::II->new(path('n4'), 100, 0, 0, -1); 1 }, 'new with negative lru_skip croaks';
    like $@, $neg, '... saying it must not be negative';
    ok !eval { Data::HashMap::Shared::II->new(path('n5'), 100, 0, 0, 0, -1); 1 }, 'new with negative arena_cap croaks';
    like $@, $neg, '... saying it must not be negative';
    ok !eval { Data::HashMap::Shared::II->new(path('n6'), 100, 0, 0, 0, 0, -1); 1 }, 'new with negative file_mode croaks';
    like $@, $neg, '... saying it must not be negative';
    ok !eval { Data::HashMap::Shared::II->new_sharded(path('n7'), -1, 100); 1 }, 'new_sharded with negative num_shards croaks';
    like $@, $neg, '... saying it must not be negative';

    my $m = Data::HashMap::Shared::II->new(path('neg'), 100, 0, 3600);
    for my $call (['set_ttl', sub { $m->set_ttl(1, -1) }],
                  ['put_ttl', sub { $m->put_ttl(1, 2, -1) }],
                  ['add_ttl', sub { $m->add_ttl(1, 2, -1) }],
                  ['update_ttl', sub { $m->update_ttl(1, 2, -1) }],
                  ['flush_expired_partial', sub { $m->flush_expired_partial(-1) }],
                  ['reserve', sub { $m->reserve(-1) }]) {
        ok !eval { $call->[1](); 1 }, "$call->[0] with a negative size croaks";
        like $@, $neg, '... saying it must not be negative';
    }
    my $s = Data::HashMap::Shared::SS->new(path('neg-ss'), 100, 0, 3600);
    ok !eval { $s->put_ttl('k', 'v', -1); 1 }, 'SS put_ttl with negative ttl croaks';
    like $@, $neg, '... saying it must not be negative';
    ok !eval { $s->reserve(-1); 1 }, 'SS reserve with negative target croaks';
    like $@, $neg, '... saying it must not be negative';

    ok !eval { Data::HashMap::Shared::II->new(path('o1'), 2**32 + 100); 1 }, 'oversized max_entries still croaks';
    like $@, $max, '... with the exceeds-the-maximum message';
    ok !eval { $m->reserve(2**40); 1 }, 'reserve above 2**32 still croaks';
    like $@, $max, '... with the exceeds-the-maximum message';
    ok !eval { Data::HashMap::Shared::II->new(path('o2'), 2**63); 1 }, 'max_entries above IV_MAX croaks';
    like $@, $max, '... with the exceeds-the-maximum message, not "must not be negative"';
    ok !eval { Data::HashMap::Shared::II->new(path('o3'), 1e20); 1 }, 'max_entries of 1e20 croaks';
    like $@, $max, '... with the exceeds-the-maximum message, not "must not be negative"';
    ok !eval { $m->put_ttl(1, 2, 2**63); 1 }, 'put_ttl with a ttl above IV_MAX croaks';
    like $@, $max, '... with the exceeds-the-maximum message';
    ok !eval { Data::HashMap::Shared::II->new(path('n8'), -0.5); 1 }, 'new with a negative fraction croaks';
    like $@, $neg, '... saying it must not be negative';
    ok !$m->reserve(1_000_000_000), 'reserve past the map maximum still returns false';
}

done_testing;
