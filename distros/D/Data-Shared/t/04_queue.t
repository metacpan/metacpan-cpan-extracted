use strict;
use warnings;
use Test::More;
use Data::Shared qw(shared_push shared_pop shared_call shared_get
                    shared_compile sharedc_push sharedc_get);

# plan skip_all inside a subtest ends it, so this does not return on a missing backend.
sub root_or_skip {
    my ($name, @spec) = @_;
    my $root = Data::Shared->new;
    eval { $root->mount($name, @spec) };
    plan skip_all => "backend unavailable: $@" if $@;
    return $root;
}

subtest 'queue Int' => sub {
    my $r = root_or_skip('jobs', 'queue:int', undef, 1024);
    shared_push($r, '/jobs', 42);
    shared_push($r, '/jobs', 43);
    is shared_pop($r, '/jobs'), 42, 'fifo 1';
    is shared_pop($r, '/jobs'), 43, 'fifo 2';
    is shared_call($r, '/jobs', 'size'), 0, 'size via call';
    ok !eval { shared_get($r, '/jobs'); 1 }, 'queue get croaks honestly';
    like $@, qr/use shared_push, shared_pop or shared_call/, 'guidance';
};

subtest 'stack Str' => sub {
    my $r = root_or_skip('s', 'stack:str', undef, 50, 256);
    shared_push($r, '/s', 'hello');
    shared_push($r, '/s', 'world');
    is shared_pop($r, '/s'), 'world', 'lifo 1';
    is shared_pop($r, '/s'), 'hello', 'lifo 2';
};

subtest 'deque Int' => sub {
    my $r = root_or_skip('dq', 'deque:int', undef, 100);
    shared_push($r, '/dq', 1);
    shared_push($r, '/dq', 2);
    shared_call($r, '/dq', 'push_front', 0);
    is shared_pop($r, '/dq'), 0, 'pop_front after push sugar';
};

subtest 'heap priority' => sub {
    my $r = root_or_skip('tasks', 'heap', undef, 100);
    shared_push($r, '/tasks', 3, 300);
    shared_push($r, '/tasks', 1, 100);
    my ($pri, $val) = shared_pop($r, '/tasks');
    is $pri, 1, 'lowest priority first';
    is $val, 100, 'value';
};

subtest 'log append only' => sub {
    my $r = root_or_skip('audit', 'log', undef, 100000);
    shared_push($r, '/audit', 'first');
    is shared_call($r, '/audit', 'entry_count'), 1, 'entry_count';
    ok !eval { shared_pop($r, '/audit'); 1 }, 'log pop croaks';
};

subtest 'ringbuffer' => sub {
    my $r = root_or_skip('ring', 'ringbuffer:int', undef, 100);
    shared_push($r, '/ring', 42);
    shared_push($r, '/ring', 99);
    is shared_get($r, '/ring'), 99, 'latest via get without index';
    my $seq = shared_call($r, '/ring', 'write', 777);
    is shared_get($r, "/ring/$seq"), 777, 'read_seq via get with index';
};

subtest 'pubsub publish' => sub {
    my $r = root_or_skip('ev', 'pubsub:int', undef, 1024);
    my $sub = shared_call($r, '/ev', 'subscribe');
    shared_push($r, '/ev', 42);
    is $sub->poll, 42, 'subscriber sees published value';
    ok !eval { shared_pop($r, '/ev'); 1 }, 'pubsub pop croaks (needs subscriber)';
};

subtest 'a queue path takes no key component' => sub {
    my $root = Data::Shared->new;
    my @mounted;
    for my $spec (['queue', 'queue:int', 1024], ['stack', 'stack:int', 1024],
                  ['heap', 'heap', 1024], ['log', 'log', 1024]) {
        my ($name, $type, @args) = @$spec;
        unless (eval { $root->mount($name, $type, undef, @args); 1 }) {
            fail "mounting '$type' failed: $@"
                unless $@ =~ /is not available; install the|Can't locate \S+\.pm/;
            next;
        }
        push @mounted, [$name, $type];
    }
    plan skip_all => 'no queue-family backend available' unless @mounted;
    for my $m (@mounted) {
        my ($name, $type) = @$m;
        ok !eval { shared_push($root, "/$name/5", 42); 1 }, "$type refuses a push with a component";
        like $@, qr/\Qpath too long\E.*pass the value/, "$type says the path is too long, and where the value goes";
        next if $type eq 'log';
        ok !eval { shared_pop($root, "/$name/5"); 1 }, "$type refuses a pop with a component";
        like $@, qr/\Qpath too long\E/, "$type: because the path is too long";
        unlike $@, qr/pass the value/, "$type: and asks for no value a pop does not take";
    }
    # ringbuffer's get is the one verb in the family that reads a component.
    my $rb_ok = eval { $root->mount('rb', 'ringbuffer', undef, 64); 1 };
    my $rb_why = $@;
    if ($rb_ok) {
        shared_push($root, '/rb', 11);
        is shared_get($root, '/rb/0'), 11, 'a ringbuffer get reads its sequence number';
        is sharedc_get($root, shared_compile('/rb/0')), 11, 'and through a compiled path';
        ok !eval { shared_get($root, '/rb/0/1'); 1 }, 'but two components are refused';
        unlike $@, qr/pass the value/, 'without asking for a value a get does not take';
        ok !eval { shared_push($root, '/rb/5', 9); 1 }, 'and a keyed push is still refused';
    }
    else {
        like $rb_why, qr/is not available/, 'the ringbuffer case needs an absent backend'
            or diag $rb_why;
    }

    my $compiled = shared_compile("/$mounted[0][0]/5");
    ok $compiled, 'compiling an over-long queue path is allowed';
    ok !eval { sharedc_push($root, $compiled, 42); 1 },
        'the compiled tier refuses it at bind time';
    like $@, qr/\Qpath too long\E/, 'with the same reason as the string tier';

    # A composite child address is consumed by the composite, not a remainder.
    my $comp = Data::Shared->new;
    my $composite_ok = eval { $comp->mount('q', ['hashmap:ss', 64, ['queue:int', 8]]); 1 };
    my $why = $@;
    if ($composite_ok) {
        ok eval { shared_push($comp, '/q/a', 42); 1 }, 'a push into a composite child still works';
        is shared_pop($comp, '/q/a'), 42, 'and pops back';
    }
    else {
        like $why, qr/is not available/, 'the composite case needs an absent backend'
            or diag $why;
    }
};

done_testing;
