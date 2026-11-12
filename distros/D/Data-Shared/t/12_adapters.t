use strict;
use warnings;
use Test::More;
use Data::Shared::Adapter::Map ();
use Data::Shared::Adapter::Set ();
use Data::Shared::Adapter::Indexed ();
use Data::Shared::Adapter::Queue ();
use Data::Shared::Adapter::Sketch ();
use Data::Shared::Adapter::Sync ();

package MockHandle {
    sub new { bless { v => {}, log => [] }, shift }
    sub get { my ($s, $k) = @_; return $s->{v}{$k} }
    sub put { my ($s, $k, $val) = @_; $s->{v}{$k} = $val; return $val }
    sub set { my $s = shift; return $s->put(@_) }
    sub remove { my ($s, $k) = @_; return delete $s->{v}{$k} }
    sub exists { my ($s, $k) = @_; return exists $s->{v}{$k} ? 1 : 0 }
    sub incr { my ($s, $k) = @_; return ++$s->{v}{$k} }
    sub incr_by { my ($s, $k, $d) = @_; return $s->{v}{$k} += $d }
    sub score { my ($s, $k) = @_; return $s->{v}{$k} }
    sub add { my ($s, $k, $val) = @_; $s->{v}{$k} = defined $val ? $val : ($s->{v}{$k} || 0) + 1; return $s->{v}{$k} }
    sub estimate { my ($s, $k) = @_; return $s->{v}{$k} || 0 }
    sub point { my ($s, @idx) = @_; return $s->{v}{join ',', @idx} }
    sub update { my ($s, @a) = @_; return $a[-1] }
    sub push { my ($s, @a) = @_; push @{ $s->{q} }, @a; return 1 }
    sub pop { my ($s) = @_; return shift @{ $s->{q} } }
    sub pair { return wantarray ? (7, 42) : 42 }
    sub publish { my ($s, @a) = @_; return $s->push(@a) }
}

package main;

sub check_adapter {
    my ($adapter, $entry, $verb, $rest, $args, $want, $label) = @_;
    my $h = MockHandle->new;
    $h->{v}{k} = 10;
    $h->{v}{'1,2'} = 7;
    my $via_perform = eval { $adapter->perform($verb, $h, $entry, $rest, @$args) };
    my $perform_err = $@;
    my $h2 = MockHandle->new; $h2->{v}{k} = 10; $h2->{v}{'1,2'} = 7;
    my $code = $adapter->make_verb($verb, $h2, $entry);
    ok $code, "$label make_verb" or diag $perform_err;
    my $via_code = $code ? $code->($rest, @$args) : undef;
    my $h3 = MockHandle->new; $h3->{v}{k} = 10; $h3->{v}{'1,2'} = 7;
    my $bound = $adapter->make_bound($verb, $h3, $entry, $rest);
    ok $bound, "$label make_bound" or diag $perform_err;
    my $via_bound = $bound ? $bound->(@$args) : undef;
    is $via_perform, $want, "$label perform";
    is $via_code, $want, "$label verb code";
    is $via_bound, $want, "$label bound";
}

my $map_entry = { key => 'mock', verbs => { get => 'get', set => 'put', delete => 'remove', exists => 'exists', incr => 'incr' } };
check_adapter('Data::Shared::Adapter::Map', $map_entry, 'get', ['k'], [], 10, 'map get');
check_adapter('Data::Shared::Adapter::Map', $map_entry, 'exists', ['k'], [], 1, 'map exists');
check_adapter('Data::Shared::Adapter::Map', $map_entry, 'incr', ['k'], [], 11, 'map incr');
check_adapter('Data::Shared::Adapter::Map', $map_entry, 'incr', ['k'], [5], 15, 'map incr_by');
my $map_code_entry = { key => 'mock', verbs => { set => sub { my ($h, $k, $v) = @_; return $h->put($k, $v * 2) } } };
check_adapter('Data::Shared::Adapter::Map', $map_code_entry, 'set', ['k'], [21], 42, 'map coderef set');
check_adapter('Data::Shared::Adapter::Set', { key => 'mock', verbs => { get => 'score', set => 'add' } }, 'get', ['k'], [], 10, 'set get');
check_adapter('Data::Shared::Adapter::Sketch', { key => 'mock', verbs => { get => 'estimate' } }, 'get', ['k'], [], 10, 'sketch get');
check_adapter('Data::Shared::Adapter::Indexed', { key => 'mock', verbs => { get => 'point', set => 'set' } }, 'get', ['1', '2'], [], 7, 'indexed get');
check_adapter('Data::Shared::Adapter::Set', { key => 'mock', verbs => { set => 'add', incr => 'incr' } }, 'set', ['k'], [99], 99, 'set set');
check_adapter('Data::Shared::Adapter::Set', { key => 'mock', verbs => { set => 'add', incr => 'incr' } }, 'incr', ['k'], [], 11, 'set incr');
check_adapter('Data::Shared::Adapter::Sketch', { key => 'mock', verbs => { set => sub { my ($h, $k, $v) = @_; return $h->add($k, $v) } } }, 'set', ['k'], [5], 5, 'sketch coderef set');
check_adapter('Data::Shared::Adapter::Indexed', { key => 'mock', verbs => { set => 'update', incr => 'update' } }, 'set', ['1', '2'], [5], 5, 'indexed set');
check_adapter('Data::Shared::Adapter::Queue', { key => 'mock', verbs => { get => 'get' } }, 'get', ['k'], [], 10, 'queue verb get');

for my $a (qw(Map Set Indexed Queue Sketch Sync)) {
    my $adapter = "Data::Shared::Adapter::$a";
    my $entry = { key => 'mock', verbs => {} };
    ok !defined $adapter->make_verb('get', MockHandle->new, $entry), "$a unknown verb undef";
    ok !eval { $adapter->perform('get', MockHandle->new, $entry, ['k']); 1 }, "$a perform unknown croaks";
    like $@, qr/not supported|no method|does not support/, "$a perform says the verb is unsupported";
    ok !defined $adapter->make_bound('get', MockHandle->new, $entry, ['k']), "$a unknown bound undef";
}

for my $a (qw(Map Set Indexed Queue Sketch)) {
    my $adapter = "Data::Shared::Adapter::$a";
    my $entry = { key => 'mock', verbs => { get => 'nosuch_method' } };
    my $code = $adapter->make_verb('get', MockHandle->new, $entry);
    ok !eval { $code->(['k']); 1 }, "$a croaks for a method the handle lacks";
    like $@, qr/\QMockHandle does not support 'nosuch_method'\E/,
        "$a names the handle's class and the method";
    like $@, qr/use shared_call/, "$a points at shared_call";
}

{
    my $entry = { key => 'mock', push => 'nosuch_push', pop => 'nosuch_pop' };
    for my $verb (qw(push pop)) {
        my $code = Data::Shared::Adapter::Queue->can("make_$verb")
            ->('Data::Shared::Adapter::Queue', MockHandle->new, $entry);
        ok !eval { $code->(1); 1 }, "queue $verb croaks for a method the handle lacks";
        like $@, qr/\QMockHandle does not support 'nosuch_$verb'\E/, "and names it for $verb";
    }
}

{
    my $entry = { key => 'mock', verbs => { get => 'nosuch_method' } };
    my $code = Data::Shared::Adapter::Map->make_verb('get', MockHandle->new, $entry);
    ok $code, 'missing method still returns code';
    ok !eval { $code->(['k']); 1 }, 'missing method code croaks on call';
    like $@, qr/does not support/, 'missing method error';
    my $bound = Data::Shared::Adapter::Map->make_bound('get', MockHandle->new, $entry, ['k']);
    ok !eval { $bound->(); 1 }, 'missing method bound croaks';
    ok !eval { Data::Shared::Adapter::Map->perform('get', MockHandle->new, $map_entry, []); 1 }, 'too short croaks';
    like $@, qr/no key/, 'too short error';
    ok !eval { Data::Shared::Adapter::Indexed->perform('get', MockHandle->new, { key => 'mock', verbs => { get => 'point' } }, []); 1 }, 'indexed too short croaks';
}

{
    my $h = MockHandle->new;
    my $entry = { key => 'mock', verbs => {}, push => 'push', pop => 'pop' };
    my $push = Data::Shared::Adapter::Queue->make_push($h, $entry);
    my $pop = Data::Shared::Adapter::Queue->make_pop($h, $entry);
    $push->([], 42);
    is $pop->([]), 42, 'queue push/pop codes';
    my $bp = Data::Shared::Adapter::Queue->make_bound_push($h, $entry, []);
    my $bo = Data::Shared::Adapter::Queue->make_bound_pop($h, $entry, []);
    $bp->(43);
    is $bo->(), 43, 'queue bound push/pop';
    is(Data::Shared::Adapter::Queue->perform_push($h, $entry, [], 44), 1, 'queue perform_push');
    is(Data::Shared::Adapter::Queue->perform_pop($h, $entry, []), 44, 'queue perform_pop');
    my $no_push = { key => 'mock', verbs => {} };
    is(Data::Shared::Adapter::Queue->make_push($h, $no_push), undef, 'queue no push undef');
    ok !eval { Data::Shared::Adapter::Queue->perform_push($h, $no_push, [], 1); 1 }, 'queue perform_push croaks';
    ok !eval { Data::Shared::Adapter::Map->perform_push($h, $map_entry, [], 1); 1 }, 'map perform_push croaks';
    ok !eval { Data::Shared::Adapter::Sync->perform_pop($h, $map_entry, []); 1 }, 'sync perform_pop croaks';
    is(Data::Shared::Adapter::Sync->make_push($h, $map_entry), undef, 'sync make_push undef');
    my $pair = Data::Shared::Adapter::Queue->make_bound_pop($h, { key => 'mock', pop => 'pair' }, []);
    is_deeply [$pair->()], [7, 42], 'bound pop preserves list context';
    is scalar($pair->()), 42, 'bound pop preserves scalar context';
}

subtest 'an indexed path is bounded by the family dimension' => sub {
    my $handle = MockHandle->new;
    my $one = { key => 'fenwick', key_int => 1, dims => 1,
                verbs => { set => 'set', get => 'point', exists => sub { 1 } } };
    my $two = { key => 'fenwick2d', key_int => 1, dims => 2,
                verbs => { set => 'set', get => 'point' } };

    for my $case ([$one, ['1', '99'], 'one index component'],
                  [$two, ['1', '2', '3'], '2 index components']) {
        my ($entry, $rest, $want) = @$case;
        my $set = Data::Shared::Adapter::Indexed->make_verb('set', $handle, $entry);
        ok !eval { $set->($rest, 5); 1 }, "$entry->{key}: a long path is refused";
        like $@, qr/path too long: \Q$entry->{key}\E takes \Q$want\E/, 'and says the shape';
        my $exists = Data::Shared::Adapter::Indexed->make_verb('exists', $handle, $entry);
        if ($entry->{verbs}{exists}) {
            ok !eval { $exists->($rest); 1 }, "$entry->{key}: exists too";
            like $@, qr/path too long/, 'for the same reason';
        }
        ok !eval { Data::Shared::Adapter::Indexed->make_bound('set', $handle, $entry, $rest); 1 },
            "$entry->{key}: and at bind time";
    }

    my $ok = Data::Shared::Adapter::Indexed->make_verb('set', $handle, $two);
    ok eval { $ok->(['1', '2'], 7); 1 }, 'the right number of indices still passes' or diag $@;

    my $nd = { key => 'ndarray', key_int => 1,
               verbs => { set => 'set', get => 'point' } };
    my $shaped = MockHandle->new;
    { no warnings 'once'; *MockHandle::ndim = sub { 2 } }
    my $ndset = Data::Shared::Adapter::Indexed->make_verb('set', $shaped, $nd);
    ok !eval { $ndset->(['0', '1', '2'], 5); 1 }, 'ndarray takes its bound from ndim';
    like $@, qr/takes 2 index components/, 'and reports it';
    ok eval { $ndset->(['0', '1'], 5); 1 }, 'two indices pass' or diag $@;
};

subtest 'a CODE incr spec still refuses an undef delta' => sub {
    my $handle = MockHandle->new;
    my $entry = { key => 'sortedset',
                  verbs => { incr => sub { my ($h, $k, @d) = @_; return $h->incr_by($k, $d[0]) } } };
    for my $adapter (qw(Map Set)) {
        my $class = "Data::Shared::Adapter::$adapter";
        my $verb = $class->make_verb('incr', $handle, $entry);
        ok !eval { $verb->(['m'], undef); 1 }, "$adapter: undef delta is refused";
        like $@, qr/incr delta must be a number, not undef/, "$adapter: says why";
        my $bound = $class->make_bound('incr', $handle, $entry, ['m']);
        ok !eval { $bound->(undef); 1 }, "$adapter: refused on the compiled path too";
        ok eval { $verb->(['m'], 3); 1 }, "$adapter: a real delta still passes" or diag $@;
    }
};

# The facade reads a maker's undef as "no fast path, use perform".
subtest 'every adapter answers the whole interface' => sub {
    my @makers = qw(make_verb make_bound make_push make_pop
                    make_bound_push make_bound_pop);
    my @perform = qw(perform perform_push perform_pop);
    for my $name (qw(Map Set Queue Indexed Sketch Sync)) {
        my $class = "Data::Shared::Adapter::$name";
        ok $class->can($_), "$name can $_" for @makers, @perform;
    }
    for my $maker (@makers) {
        is(Data::Shared::Adapter->$maker(), undef, "the base default for $maker is undef");
    }
    for my $verb (qw(push pop)) {
        my $method = "perform_$verb";
        ok !eval { Data::Shared::Adapter->$method(); 1 },
            "the base $method croaks rather than returning";
        like $@, qr/\Q$verb\E is not supported/, "and says which verb";
    }
};

done_testing;
