use strict;
use warnings;
use Test::More;
use Test::LeakTrace;
use Hash::Util qw(lock_keys lock_hash);
use Scalar::Util qw(weaken isweak);
use Data::Path::XS qw(
    path_get path_set path_exists path_delete
    patha_get patha_set patha_exists patha_delete
    path_compile pathc_get pathc_set pathc_exists pathc_delete
);
use Data::Path::XS ':keywords';

my @apis = (
    [string => sub { path_get($_[0], $_[1]) },
               sub { path_set($_[0], $_[1], $_[2]) },
               sub { path_exists($_[0], $_[1]) },
               sub { path_delete($_[0], $_[1]) }],
    [array => sub { patha_get($_[0], [split m{/}, substr($_[1], 1)]) },
              sub { patha_set($_[0], [split m{/}, substr($_[1], 1)], $_[2]) },
              sub { patha_exists($_[0], [split m{/}, substr($_[1], 1)]) },
              sub { patha_delete($_[0], [split m{/}, substr($_[1], 1)]) }],
    [compiled => sub { pathc_get($_[0], path_compile($_[1])) },
                 sub { pathc_set($_[0], path_compile($_[1]), $_[2]) },
                 sub { pathc_exists($_[0], path_compile($_[1])) },
                 sub { pathc_delete($_[0], path_compile($_[1])) }],
    [keyword => sub { pathget $_[0], $_[1] },
                sub { pathset $_[0], $_[1], $_[2] },
                sub { pathexists $_[0], $_[1] },
                sub { pathdelete $_[0], $_[1] }],
);

for my $api (@apis) {
    my ($name, $get, $set, $exists, $delete) = @$api;
    subtest "$name value ownership" => sub {
        for my $array (0, 1) {
            my $key = $array ? 0 : 'slot';
            my $data = $array ? [] : {};
            my $payload = { id => 1 };
            $set->($data, "/$key", $payload);
            $payload->{id} = 2;
            is($get->($data, "/$key")->{id}, 2, 'referent remains shared');
            $payload = { id => 3 };
            is($get->($data, "/$key")->{id}, 2, 'reference variable is copied');

            my $target = { id => 4 };
            my $weak = $target;
            weaken $weak;
            $set->($data, "/$key", $weak);
            ok(isweak($weak), 'source remains weak');
            undef $target;
            is($get->($data, "/$key")->{id}, 4, 'stored reference owns the referent');

            if ($array) { weaken $data->[0] } else { weaken $data->{slot} }
            my $owner = { id => 5 };
            $set->($data, "/$key", $owner);
            if ($array) { weaken $data->[0] } else { weaken $data->{slot} }
            $set->($data, "/$key", $owner);
            ok($array ? !isweak($data->[0]) : !isweak($data->{slot}),
               'assigning the same referent strengthens a weak destination');

            $set->($data, "/$key", 'original');
            my $returned = $array
                ? $set->($data, "/$key", $data->[0])
                : $set->($data, "/$key", $data->{slot});
            is($returned, 'original', 'self-assignment returns a live value');
            is($get->($data, "/$key"), 'original', 'self-assignment preserves value');
        }
        my $data = { slot => 'old' };
        is($set->($data, '/slot/child', $data->{slot}), 'old',
           'value survives replacement of its parent slot');
        is_deeply($data, { slot => { child => 'old' } }, 'value stored after autovivification');
    };

    subtest "$name rejected writes do not leak" => sub {
        for my $path ('/blocked', '/blocked/child') {
            no_leaks_ok {
                my $data = { allowed => 1 };
                lock_keys(%$data);
                eval { $set->($data, $path, 'value') };
            } "$path on restricted hash";
        }
        no_leaks_ok {
            my $data = { allowed => 1 };
            lock_hash(%$data);
            eval { $set->($data, '/allowed', 'value') };
        } 'overwrite on locked hash';
        my $payload = {};
        my $locked = { allowed => $payload };
        lock_hash(%$locked);
        eval { $set->($locked, '/allowed', $payload) };
        like($@, qr/read-only/, 'same referent cannot bypass a locked slot');
    };
}

{
    package Production::Hash;
    sub TIEHASH { bless { data => $_[1], fetches => 0 }, $_[0] }
    sub FETCH { $_[0]->{fetches}++; my @work = (1 .. 256); $_[0]->{data}{$_[1]} }
    sub EXISTS { exists $_[0]->{data}{$_[1]} }
    sub DELETE { delete $_[0]->{data}{$_[1]} }
    package Production::Array;
    sub TIEARRAY { bless { data => $_[1], fetches => 0 }, $_[0] }
    sub FETCH { $_[0]->{fetches}++; my @work = (1 .. 256); $_[0]->{data}[$_[1]] }
    sub FETCHSIZE { scalar @{$_[0]->{data}} }
    sub EXISTS { exists $_[0]->{data}[$_[1]] }
    sub DELETE { delete $_[0]->{data}[$_[1]] }
    package Production::Scalar;
    sub TIESCALAR { bless { value => $_[1], fetches => 0 }, $_[0] }
    sub FETCH { $_[0]->{fetches}++; $_[0]->{value} }
}

subtest 'keyword results survive later operands' => sub {
    my $data = { leaf => 'value' };
    my @values = ((pathget $data, '/leaf'), do { $data = {}; 'next' });
    is_deeply(\@values, ['value', 'next'], 'get result outlives its container');
    $data = { leaf => { id => 1 } };
    @values = ((pathget $data, '/leaf'), do { $data = {}; 'next' });
    is_deeply(\@values, [{ id => 1 }, 'next'], 'reference result outlives its container');
};

subtest 'direct setter arguments survive replacement' => sub {
    my $data = { slot => 'value' };
    is(path_set($data, '/slot', $data->{slot}), 'value', 'string self-assignment');
    is(patha_set($data, ['slot'], $data->{slot}), 'value', 'array self-assignment');
    is(pathc_set($data, path_compile('/slot'), $data->{slot}), 'value',
       'compiled self-assignment');
    my $path = '/slot';
    is((pathset $data, $path, $data->{slot}), 'value', 'keyword self-assignment');
    is(path_set($data, '/slot/leaf', $data->{slot}), 'value',
       'string value survives parent replacement');
    $data = { slot => 'value' };
    is(patha_set($data, ['slot', 'leaf'], $data->{slot}), 'value',
       'array value survives parent replacement');
    $data = { slot => 'value' };
    is(pathc_set($data, path_compile('/slot/leaf'), $data->{slot}), 'value',
       'compiled value survives parent replacement');
    $data = { slot => 'value' };
    $path = '/slot/leaf';
    is((pathset $data, $path, $data->{slot}), 'value',
       'keyword value survives parent replacement');
    $data = { route => '/route/leaf//' };
    path_set($data, $data->{route}, 42);
    is_deeply($data, { route => { leaf => 42 } }, 'string path survives replacement');
    $data = { route => '/route/leaf//' };
    pathset $data, $data->{route}, 42;
    is_deeply($data, { route => { leaf => 42 } }, 'keyword path survives replacement');
    $data = { route => '/route//' };
    pathset $data, $data->{route}, 43;
    is_deeply($data, { route => 43 }, 'keyword stops parsing after final store');
};

{
    package Production::ResizeOnDestroy;
    sub DESTROY { push @{$_[0]->{array}}, 1 .. 80 }
}

subtest 'set returns survive destructor callbacks' => sub {
    for my $api (@apis) {
        my ($name, undef, $set) = @$api;
        my $data = [];
        $data->[0] = bless { array => $data }, 'Production::ResizeOnDestroy';
        is($set->($data, '/0', 99), 99, "$name returns the stored element");
        is($data->[0], 99, "$name stored the value");
        is(scalar @$data, 81, "$name destructor grew the array");
    }
};

subtest 'keyword arguments use scalar context' => sub {
    my @contexts;
    my $data = { leaf => 42 };
    my $data_arg = sub { push @contexts, scalar wantarray; return $data };
    my $path_arg = sub { push @contexts, scalar wantarray; return '/leaf' };
    my $value_arg = sub {
        push @contexts, scalar wantarray;
        return wantarray ? (11, 22) : 33;
    };
    my @values = (pathget $data_arg->(), $path_arg->());
    is_deeply(\@values, [42], 'get returns one value in list context');
    is_deeply(\@contexts, ['', ''], 'get arguments are scalar');
    @contexts = ();
    @values = (pathexists $data_arg->(), $path_arg->());
    is_deeply(\@values, [1], 'exists returns one value');
    is_deeply(\@contexts, ['', ''], 'exists arguments are scalar');
    @contexts = ();
    @values = (pathset $data_arg->(), $path_arg->(), $value_arg->());
    is_deeply(\@values, [33], 'set stores scalar result');
    is_deeply(\@contexts, ['', '', ''], 'set arguments are scalar');
    @contexts = ();
    @values = (pathdelete $data_arg->(), $path_arg->());
    is_deeply(\@values, [33], 'delete returns stored scalar result');
    is_deeply(\@contexts, ['', ''], 'delete arguments are scalar');
    @contexts = ();
    pathset $data_arg->(), $path_arg->(), $value_arg->();
    is_deeply(\@contexts, ['', '', ''], 'void set still evaluates scalar arguments');
    @contexts = ();
    pathget $data_arg->(), $path_arg->();
    is_deeply(\@contexts, ['', ''], 'void get still evaluates scalar arguments');
};

subtest 'tied array path components' => sub {
    tie my $index, 'Production::Scalar', 1;
    is(patha_get([10, 20], [$index]), 20, 'numeric tied component');
    tie my @path, 'Production::Array', ['node', 1, 'leaf'];
    my $data = { node => [{}, { leaf => 42 }] };
    is(patha_get($data, \@path), 42, 'tied path array');
    ok(patha_exists($data, \@path), 'exists with tied path array');
    is(patha_set($data, \@path, 43), 43, 'set with tied path array');
    is(patha_delete($data, \@path), 43, 'delete with tied path array');
};

subtest 'numeric caching preserves string path components' => sub {
    my $key = '01';
    my $number = 0 + $key;
    my $data = [10, 20];
    is(patha_get($data, [$key]), undef, 'cached leading-zero key is not an index');
    ok(!patha_exists($data, [$key]), 'cached leading-zero index does not exist');
    is(patha_delete($data, [$key]), undef, 'cached leading-zero key does not delete');
    eval { patha_set($data, [$key], 99) };
    like($@, qr/Invalid array index/, 'cached leading-zero key cannot set an array');
    is_deeply($data, [10, 20], 'array remains unchanged');
    $data = {};
    patha_set($data, ['node', $key], 99);
    is_deeply($data, { node => { '01' => 99 } }, 'autovivification uses string shape');
};

done_testing;
