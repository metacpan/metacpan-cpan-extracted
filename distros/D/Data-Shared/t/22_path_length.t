use strict;
use warnings;
use Test::More;
use Data::Shared qw(shared_get shared_set shared_exists);

# A map- or set-like mount consumes exactly one component.
my $root = Data::Shared->new;
eval {
    $root->mount('cache', 'hashmap:ii', undef, 1024);
    $root->mount('seen',  'bitset',     undef, 128);
    1;
} or plan skip_all => "backend unavailable: $@";

shared_set($root, '/cache/1', 111);
is shared_get($root, '/cache/1'), 111, 'exact path reads';

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

ok !eval { shared_get($root, '/cache/1/2'); 1 },  'get with an extra component croaks';
like $@, qr/path too long/, 'croak names the problem';
ok !eval { shared_set($root, '/cache/1/9', 999); 1 }, 'set with an extra component croaks';
like $@, qr/path too long/, 'for the same reason';
is shared_get($root, '/cache/1'), 111, 'the record the path did not name is untouched';

ok !eval { shared_get($root, '/cache/1/x/y/z'); 1 }, 'several extra components croak';
like $@, qr/path too long/, 'still for the length, not for the shape';
ok !eval { shared_exists($root, '/seen/10/99'); 1 },  'set-like mount croaks on an extra component';
like $@, qr/path too long/, 'and the set family says it too';

is scalar @warnings, 0, 'no numeric-coercion warnings' or diag join '', @warnings;

SKIP: {
    my $ok = eval { $root->mount('cms', 'countminsketch', undef, 0.001, 0.001); 1 };
    skip 'countminsketch backend unavailable', 3 unless $ok;
    shared_set($root, '/cms/alpha', 5);
    ok !eval { shared_get($root, '/cms/alpha/beta'); 1 },
        'sketch mount croaks on an extra component';
    like $@, qr/path too long/, 'and the sketch family says it too';
    is shared_get($root, '/cms/alpha'), 5, 'the named sketch key is unchanged';
}

# key_join mounts legitimately consume every component.
SKIP: {
    my $ok = eval { $root->mount('tree', 'radixtree', undef, 4096); 1 };
    skip 'radixtree backend unavailable', 2 unless $ok;
    shared_set($root, '/tree/a/b/c', 7);
    is shared_get($root, '/tree/a/b/c'), 7, 'key_join mount joins components';
    isnt shared_get($root, '/tree/a/b') // -1, 7, 'a different joined key is a different record';
}

done_testing;
