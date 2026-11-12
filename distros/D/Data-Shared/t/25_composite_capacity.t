use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Shared qw(shared_set shared_push shared_pop shared_compile sharedc_pop);

my $probe = Data::Shared->new;
eval { $probe->mount('p', ['hashmap:ss', 8, ['hashmap:ss', 8], { max_children => 4 }]); 1 }
    or plan skip_all => "composite backends unavailable: $@";

# The child index stores 'a:<addr>' and 'c:<addr>' per child, each taking an
# arena block of next_pow2(2 + length addr).
for my $len (126, 200, 254) {
    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    $root->mount('u', ['hashmap:ss', 40, 0, 0, 0, 40 * 2048,
                       ['hashmap:ss', 8], { max_children => 40 }]);
    my $made = 0;
    for my $i (1 .. 40) {
        my $addr = sprintf '%0*d', $len, $i;
        last unless eval { shared_set($root, "/u/$addr/k", 1); 1 };
        $made++;
    }
    is $made, 40, "all 40 children fit with ${len}-byte addresses";
}

{
    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    ok !eval { $root->mount('s', ['hashmap:ss', 64, ['hashmap:ss', 8],
                                  { maxchildren => 5 }]); 1 },
        'a misspelled composite option croaks';
    like $@, qr/unknown composite option 'maxchildren'/, 'the croak names the key';
    ok eval { $root->mount('t', ['hashmap:ss', 64, ['hashmap:ss', 8],
                                 { max_children => 5 }]); 1 },
        'the correct option still mounts';
    is $root->mount_info('t')->{composite}, 1, 'and it really is composite';
    my $empty = eval { $root->mount('e', ['hashmap:ss', 64, ['hashmap:ss', 8], {}]); 1 };
    ok $empty, 'an empty options hash asks for the defaults' or diag $@;
    is eval { $root->mount_info('e')->{composite} }, 1, 'and still mounts a composite'
        if $empty;
}

subtest 'a composite cannot be remounted with a budget its storage cannot serve' => sub {
    my $spec = sub { ['hashmap:ss', 64, ['hashmap:ii', 16], { max_children => $_[0] }] };
    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    $root->mount('u', $spec->(3));
    shared_set($root, '/u/alice/5', 1);

    $root->unmount('u');
    ok !eval { $root->mount('u', $spec->(50)); 1 }, 'raising the budget is refused';
    like $@, qr/created for max_children=3 and cannot serve 50/, 'and names both';
    like $@, qr/unmount\(unlink => 1\)/, 'and the way out';

    ok eval { $root->mount('u', $spec->(3)); 1 }, 'the recorded budget still mounts' or diag $@;
    is Data::Shared::shared_get($root, '/u/alice/5'), 1, 'over the same children';
    $root->unmount('u');
    ok eval { $root->mount('u', $spec->(2)); 1 }, 'and so does a smaller one' or diag $@;

    my $fresh = Data::Shared->new(tempdir(CLEANUP => 1));
    $fresh->mount('u', $spec->(50));
    my $made = 0;
    for my $i (1 .. 60) {
        last unless eval { shared_set($fresh, "/u/u$i/5", $i); 1 };
        $made++;
    }
    is $made, 50, 'a budget of 50 really holds 50 children';
    like $@, qr/child limit exceeded \(max_children=50\)/, 'and stops on the budget, not the file';
};

# Unlike the top level, a nested one is opened from a read, so it is not refused.
subtest 'a nested level keeps serving the budget its storage was built for' => sub {
    my $spec = sub {
        ['hashmap:ss', 64, ['hashmap:ss', 64, ['hashmap:ii', 16], { max_children => $_[0] }],
         { max_children => 100 }];
    };
    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    $root->mount('u', $spec->(3));
    shared_set($root, '/u/eu/paris/5', 1);
    $root->unmount('u');
    ok eval { $root->mount('u', $spec->(50)); 1 },
        'raising only a nested budget is not refused at mount' or diag $@;
    is eval { Data::Shared::shared_get($root, '/u/eu/paris/5') }, 1,
        'and a deep read still works' or diag $@;

    my $made = 1;        # paris
    for my $i (1 .. 12) {
        last unless eval { shared_set($root, "/u/eu/city$i/5", $i); 1 };
        $made++;
    }
    is $made, 3, 'the nested level stops at what its index holds';
    like $@, qr/child limit exceeded \(max_children=3\)/,
        'and names that number, not the one the manifest published';
};

subtest 'a full parent leaf names itself as the ceiling' => sub {
    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    plan skip_all => 'sortedset or bloomfilter unavailable'
        unless eval { require Data::SortedSet::Shared; require Data::BloomFilter::Shared; 1 };
    $root->mount('l', ['sortedset', 4, ['bloomfilter', 10_000, 0.01]]);
    my $made = 0;
    for my $i (1 .. 8) {
        last unless eval { shared_set($root, "/l/$i/x", 1); 1 };
        $made++;
    }
    is $made, 4, 'the capacity-4 parent takes four children';
    like $@, qr/in the sortedset parent of 'l'/, 'the refusal names the parent';
    like $@, qr/parent holds 4 of 4/, 'and the resource that ran out';
    like $@, qr/bounds max_children=10000/, 'and the budget it bounds';
};

# 's:' is the child counter; 'p:' marks an unfinished mutation and calls for a recount.
{
    my $dir = tempdir(CLEANUP => 1);
    {
        my $root = Data::Shared->new($dir);
        $root->mount('u', ['hashmap:ss', 64, ['hashmap:ss', 8], { max_children => 64 }]);
        shared_set($root, "/u/c$_/k", 1) for 1 .. 5;
    }

    my $counted = 0;
    my $orig = \&Data::Shared::Composite::_count_addresses;
    no warnings 'redefine';
    local *Data::Shared::Composite::_count_addresses = sub { $counted++; $orig->(@_) };

    my $root = Data::Shared->open($dir);
    is $counted, 0, 'opening a settled composite does not recount';
    is $root->call('/u', 'child_count'), 5, 'and the counter it kept is right';

    my $index = $root->{mounts}{u}{composite}{index};
    $index->put('s:', 99);
    $index->put('p:', 1);
    undef $root;

    $counted = 0;
    my $after = Data::Shared->open($dir);
    is $counted, 1, 'an unfinished mutation marker does trigger the recount';
    is $after->call('/u', 'child_count'), 5, 'and the bogus counter is repaired';
    is $index->get('p:'), undef, 'the marker is cleared';
}

subtest 'retiring a missing child allocates nothing' => sub {
    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    $root->mount('t', ['hashmap:ss', 100, ['hashmap:si', 64], { max_children => 1 }]);
    shared_set($root, '/t/alice/hits', 1);
    is scalar(() = $root->children('/t')), 1, 'the budget of one is spent';
    for my $verb (qw(unlink destroy)) {
        ok eval { $root->call("/t/bob", $verb); 1 }, "$verb at a missing child is accepted";
        is scalar(() = $root->children('/t')), 1, "and registered no child for $verb";
    }
    ok !eval { shared_set($root, '/t/carol/hits', 1); 1 },
        'while a write at a missing child still wants one';
    like $@, qr/child limit exceeded/, 'and says the budget is spent';
};

subtest 'a sync_all walk leaves the eviction order alone' => sub {
    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    $root->mount('u', ['hashmap:ss', 64, ['hashmap:ss', 8], { cache_size => 2 }]);
    shared_set($root, "/u/$_/k", 1) for qw(z a);
    $root->sync_all;
    shared_set($root, '/u/c/k', 1);
    my $comp = $root->{mounts}{u}{composite};
    ok $comp->{cache}{ $comp->_reg_id('a') }, 'the most recent child stays cached';
    ok !$comp->{cache}{ $comp->_reg_id('z') }, 'and the least recent is the one evicted';
};

subtest 'retiring below a missing child allocates nothing' => sub {
    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    $root->mount('t', ['hashmap:ss', 100, ['hashmap:ss', 64, ['hashmap:si', 64]], { max_children => 1 }]);
    for my $verb (qw(unlink destroy)) {
        is $root->call('/t/alice/bob', $verb), undef, "$verb below a missing child finds nothing";
        is $root->node('/t')->call_at('carol/dave', $verb), undef, "and through a cursor";
    }
    is scalar(() = $root->children('/t')), 0, 'registered no child';
    ok eval { shared_set($root, '/t/erin/x/hits', 1); 1 }, 'so the budget is still whole'
        or diag $@;
};

subtest 'polling a missing child allocates nothing' => sub {
    plan skip_all => 'queue unavailable' unless eval { require Data::Queue::Shared; 1 };
    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    $root->mount('q', ['hashmap:ss', 100, ['queue:int', 8], { max_children => 2 }]);
    my $compiled = shared_compile('/q/carol');
    for my $user (qw(alice bob carol dave)) {
        is shared_pop($root, "/q/$user"), undef, "an empty poll for $user";
    }
    is sharedc_pop($root, $compiled), undef, 'and through a compiled path';
    is scalar(() = $root->children('/q')), 0, 'registered no child';
    ok eval { shared_push($root, "/q/$_", 1) for qw(alice bob); 1 }, 'so the budget is still whole'
        or diag $@;
    is shared_pop($root, '/q/alice'), 1, 'and a poll then finds the job';
};

done_testing;
