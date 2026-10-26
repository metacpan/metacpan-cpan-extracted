use v5.40;
use blib;
use Acme::Parataxis qw[async yield fiber nursery run with_timeout];
use Acme::Parataxis::Local;
use Acme::Parataxis::Actor;
use Test2::V1 -ipP;
$|++;

# Trace propagation. A Acme::Parataxis::Local created with inherit => 1 has its current
# value copied from the spawning fiber into the child the moment the child is spawned (a shallow
# copy; the child then owns it exclusively). Plain Locals keep strict per-fiber isolation.
subtest 'an inherit Local seeds the child before its first read' => sub {
    async {
        my $trace = Acme::Parataxis::Local->new( inherit => 1 );
        $trace->set('parent-id');
        my $seen;
        my $child = fiber {
            $seen = $trace->get;
            1;
        };
        $child->await;
        is $seen, 'parent-id', 'the child reads the parent value at birth';
    };
};
subtest 'child writes never leak back to the parent' => sub {
    async {
        my $trace = Acme::Parataxis::Local->new( inherit => 1 );
        $trace->set('parent-id');
        my $child = fiber {
            $trace->set('child-write');
            1;
        };
        $child->await;
        is $trace->get, 'parent-id', 'the parent value is untouched by the child write';
    };
};
subtest 'a plain Local stays strictly isolated' => sub {
    async {
        my $plain = Acme::Parataxis::Local->new;
        $plain->set('parent-only');
        my $child = fiber {
            my $v = $plain->get;
            $plain->set('child-write');
            defined $v ? $v : 'undefined';
        };
        $child->await;
        is $child->result, 'undefined',   'the child sees no parent value';
        is $plain->get,    'parent-only', 'and the parent write is still there';
    };
};
subtest 'the seed is captured at spawn time, not after' => sub {
    async {
        my $trace = Acme::Parataxis::Local->new( inherit => 1 );
        $trace->set('before');
        my $seen;
        my $child = fiber {
            $seen = $trace->get;
            1;
        };
        $trace->set('after');    # too late: the child is already born with the 'before' value
        $child->await;
        is $seen, 'before', 'post-spawn parent writes do not propagate';
    };
};
subtest 'inheritance chains down nested fibers' => sub {
    async {
        my $trace = Acme::Parataxis::Local->new( inherit => 1 );
        $trace->set('root-id');
        my $grand;
        my $mid = fiber {
            my $parent_val = $trace->get;
            my $kid        = fiber {
                $grand = "$parent_val/" . $trace->get;
                1;
            };
            $kid->await;
            1;
        };
        $mid->await;
        is $grand, 'root-id/root-id', 'a grandchild sees the value the middle fiber inherited';
    };
};
subtest 'values follow nursery children' => sub {
    async {
        my $trace = Acme::Parataxis::Local->new( inherit => 1 );
        $trace->set('nursery-id');
        my @seen;
        nursery(
            sub ($n) {
                $n->spawn( sub { push @seen, $trace->get; 1 } );
                $n->spawn( sub { push @seen, $trace->get; 1 } );
            }
        );
        is join( q{,}, sort @seen ), 'nursery-id,nursery-id', 'every nursery child inherited the value';
    };
};
subtest 'values follow actor fiber birth' => sub {
    async {
        my $trace = Acme::Parataxis::Local->new( inherit => 1 );
        $trace->set('actor-id');
        my $actor = Acme::Parataxis::Actor->spawn( sub ( $self, $msg ) { return $trace->get } );
        my $reply = $actor->ask('ping');
        is $reply->await, 'actor-id', 'the actor mailbox fiber inherited the parent value';
        $actor->stop;
    };
};
subtest 'an unset inherit Local seeds nothing and does not leak defaults' => sub {
    async {
        my $trace = Acme::Parataxis::Local->new( inherit => 1, default => 'n/a' );
        my $child = fiber {
            $trace->set('own');
            return $trace->get;
        };
        $child->await;
        is $child->result, 'own', 'a child of an unset Local just falls back to its default';
        is $trace->get,    'n/a', 'the parent still sees the default';
    };
};
subtest 'the spawn wrapper does not disturb spawn-level croaks or results' => sub {
    async {
        my $trace = Acme::Parataxis::Local->new( inherit => 1 );
        $trace->set('x');
        my $ok = fiber { return 42 };
        is $ok->await, 42, 'an inherited fiber still returns its value';
        my $bad = dies {
            fiber { die "boom\n" };
        };
        ok $bad, 'a dying inherited fiber still fails at spawn';
        like $bad, qr/boom/, 'with its own error, not a seeding artifact';
    };
};
done_testing();
