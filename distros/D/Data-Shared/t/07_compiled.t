use strict;
use warnings;
use Test::More;
use Data::Shared qw(shared_get shared_set shared_exists shared_delete
                    shareda_get shareda_set shareda_exists
                    shared_compile sharedc_get sharedc_set sharedc_exists sharedc_delete
                    sharedc_call shared_call);

my $r = Data::Shared->new;
eval { $r->mount('cache', 'hashmap:ss', undef, 1000) };
if ($@) { plan skip_all => "backend unavailable: $@"; }

shared_set($r, '/cache/42', 100);
my $cp = shared_compile('/cache/42');
isa_ok $cp, 'Data::Shared::Compiled';
is sharedc_get($r, $cp), 100, 'compiled get matches string';
is sharedc_exists($r, $cp), 1, 'compiled exists';

sharedc_set($r, $cp, 101);
is shared_get($r, '/cache/42'), 101, 'compiled set visible to string tier';
is shareda_get($r, ['cache', '42']), 101, 'array tier agrees';

my $cp_arr = shared_compile(['cache', '42']);
is sharedc_get($r, $cp_arr), 101, 'compiled from arrayref';

my @keys = ('a/b', '', 'x y');
for my $k (@keys) {
    shareda_set($r, ['cache', $k], 'v');
    is shareda_get($r, ['cache', $k]), 'v', "array tier key [$k]";
    my $c = shared_compile(['cache', $k]);
    is sharedc_get($r, $c), 'v', "compiled array key [$k]";
}

is shared_get($r, '/cache/missing'), undef, 'missing string';
is sharedc_get($r, shared_compile('/cache/missing')), undef, 'missing compiled';
is sharedc_exists($r, shared_compile('/cache/missing')), 0, 'missing exists 0';

shared_set($r, '/cache/7', 7);
sharedc_delete($r, shared_compile('/cache/7'));
is shared_exists($r, '/cache/7'), 0, 'compiled delete';

is sharedc_call($r, shared_compile('/cache'), 'size'), 4, 'compiled call to mount';

ok !eval { sharedc_get($r, '/cache/42'); 1 }, 'string is not a compiled path';
like $@, qr/not a compiled path/, 'compiled check';

my $r2 = Data::Shared->new;
$r2->mount('cache', 'hashmap:ss', undef, 1000);
shared_set($r2, '/cache/42', 999);
is sharedc_get($r2, $cp), 999, 'compiled reused across roots';

done_testing;
