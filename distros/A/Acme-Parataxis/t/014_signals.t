use v5.40;
use Test2::V1 -ipP;
use blib;
use Acme::Parataxis;
use experimental 'class';
$|++;
#
skip_all 'Signals on Windows? Ha!', 2 if $^O eq 'MSWin32';
diag 'Testing signal handling during fiber execution...';
subtest 'Signal handled inside coroutine' => sub {
    diag 'Case 1: Sending signal while inside a fiber...';
    my $signaled = 0;
    local $SIG{INT} = sub {
        diag 'Parent SIGINT handler reached';
        $signaled++;
    };
    my $fiber = Acme::Parataxis->new(
        code => sub {
            diag "Inside fiber: About to kill 'INT' self ($$)...";
            kill 'INT', $$;
            diag 'Inside fiber: Signal sent. Continuing...';
            return 'Done';
        }
    );
    diag 'Calling fiber...';
    $fiber->call();
    is $signaled, 1, 'Signal was caught and handled by Perl';
    diag 'Signal count: ' . $signaled;
};
subtest 'Signal during yield/resume' => sub {
    diag 'Case 2: Sending signal while fiber is suspended...';
    my $signaled = 0;
    local $SIG{INT} = sub {
        diag 'Parent SIGINT handler reached during suspension';
        $signaled++;
    };
    my $fiber = Acme::Parataxis->new(
        code => sub {
            diag 'Inside fiber: Yielding READY...';
            Acme::Parataxis->yield('READY');
            diag 'Inside fiber: Resumed after signal delivery.';
            return 'Finished';
        }
    );
    diag 'Calling fiber (First step)...';
    my $y = $fiber->call();
    is $y, 'READY', 'Fiber suspended at yield';
    diag 'Sending signal to parent process...';
    kill 'INT', $$;
    diag 'Signal count before resume: ' . $signaled;
    diag 'Resuming fiber...';
    $fiber->call();
    is $signaled, 1, 'Signal handled between yield and resume';
    diag "Signal count final: $signaled";
};
done_testing();
