use v5.40;
use Test2::V1 -ipP;
use blib;
use Acme::Parataxis;
use experimental 'class';
$|++;
#
subtest 'Die inside coroutine, catch outside' => sub {
    my $fiber = Acme::Parataxis->new(
        code => sub {
            pass 'Inside the sub. Hang on a sec while I die...';
            die 'Death in coro';
        }
    );
    like dies { $fiber->call(); }, qr/Death in coro/, 'Caught exception from coroutine';
    ok $fiber->is_done, 'Coroutine is marked as done after die';
};
subtest 'eval inside coroutine' => sub {
    my $fiber = Acme::Parataxis->new(
        code => sub {
            pass 'Inside the sub. Hang on a sec while I die inside an eval...';
            eval { die 'Inner death' };
            my $err = $@;
            return 'Survived: ' . $err;
        }
    );
    like $fiber->call(), qr/Survived: Inner death/, 'Inner eval caught the death';
    ok $fiber->is_done, 'Coroutine finished normally';
};
subtest 'try/catch inside coroutine' => sub {
    my $fiber = Acme::Parataxis->new(
        code => sub {
            diag 'Inside fiber: About to try/catch inner death...';
            try { die 'Inner death' } catch ($e) {
                return 'Survived: ' . $e;
            }
        }
    );
    like $fiber->call(), qr/Survived: Inner death/, 'Inner catch block executed';
    ok $fiber->is_done, 'Coroutine finished normally';
};
subtest 'Nested coroutines exceptions' => sub {
    my $fiber1 = Acme::Parataxis->new(
        code => sub {
            diag 'Coro1: Spawning Coro2...';
            my $fiber2 = Acme::Parataxis->new(
                code => sub {
                    diag 'Coro2: About to die...';
                    die 'Deep death';
                }
            );
            $fiber2->call();
            return 'Coro2 survived?';
        }
    );
    like dies { $fiber1->call() }, qr/Deep death/, 'Caught deep death in top-level parent';
};
done_testing();
