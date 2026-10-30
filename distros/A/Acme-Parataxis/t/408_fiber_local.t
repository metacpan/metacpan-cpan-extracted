use v5.40;
use blib;
use Acme::Parataxis qw[async fiber yield await_sleep];
use Acme::Parataxis::Local;
use Test2::V1 -ipP;
#
my $DEFAULT = Acme::Parataxis::Local->new( default => 'fresh' );
sub stash_exists ($f) { exists $Acme::Parataxis::FIBER_LOCALS{ refaddr($f) } }
sub stash_keys ()     { scalar keys %Acme::Parataxis::FIBER_LOCALS }
subtest 'values are per-fiber and invisible to siblings' => sub {
    my $main = Acme::Parataxis::Local->new;
    async {
        $main->set('main');
        is $main->get, 'main', 'main fiber sees its own value';
        my $a = fiber {
            $main->set('A');
            is $main->get, 'A', 'child sees its own value, not the parent\'s';
            1;
        };
        my $b = fiber {
            $main->set('B');
            is $main->get, 'B', 'the other child sees its own value too';
            1;
        };
        $a->await;
        $b->await;
        is $main->get, 'main', 'main fiber still sees its own value after the children wrote';
        my $c = fiber { $main->get };
        ok !defined( $c->await ), 'a fiber that never set sees the unset state';
    };
};
subtest 'a default is returned until the slot is set' => sub {
    async {
        is $DEFAULT->get, 'fresh', 'default seen before any set';
        $DEFAULT->set('override');
        is $DEFAULT->get, 'override', 'stored value wins over the default';
        $DEFAULT->set(undef);
        ok !defined $DEFAULT->get, 'an explicit undef is stored, not replaced by the default';
        $DEFAULT->set('fresh');    # restore for the shared object
    };
};
subtest 'a value survives await and yield mid-block' => sub {
    async {
        my $w = fiber {
            $DEFAULT->set('kept');
            yield;
            my $gc = fiber { $DEFAULT->get };
            is $gc->await // '', 'fresh', 'a grandchild on its own fiber sees the default, not the parent\'s value';
            await_sleep(2);
            $DEFAULT->get;
        };
        is $w->await, 'kept', 'the value is intact after yield and a nested await_sleep';
    };
};
subtest 'a completed fiber releases its stash' => sub {
    async {
        my $before = stash_keys();
        my $f      = fiber { $DEFAULT->set('gone'); 1 };
        ok stash_exists($f), 'the running fiber has a stash entry';
        $f->await;
        ok !stash_exists($f), 'the stash is pruned once the fiber is done';
        is stash_keys(), $before, 'no stash entries leak for a completed fiber';
    };
};
subtest 'a recycled fiber id never inherits a dead fiber\'s values' => sub {
    async {
        my $poison = Acme::Parataxis::Local->new;
        {
            my $f = fiber { $poison->set('poison'); 1 };
            $f->await;
        }
        my $clean = 1;
        for ( 1 .. 1024 ) {
            my $g = fiber { $poison->get };
            my $v = $g->await;
            if ( defined $v ) {
                $clean = 0;
                last;
            }
        }
        ok $clean, 'no recycled fiber ever reads another fiber\'s value';
    };
};
subtest 'get/set croak outside the scheduler' => sub {
    my $vl = Acme::Parataxis::Local->new;
    like dies { $vl->get },    qr/must be called from inside a scheduled fiber/, 'get croaks outside a scheduled fiber';
    like dies { $vl->set(1) }, qr/must be called from inside a scheduled fiber/, 'set croaks outside a scheduled fiber';
};
#
done_testing;
