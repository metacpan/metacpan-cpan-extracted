use v5.40;
use blib;
use Acme::Parataxis;
use Test2::V1 -ipP;
$|++;
#
diag '$Acme::Parataxis::VERSION = ' . $Acme::Parataxis::VERSION;
subtest 'Asymmetric Coroutines' => sub {
    diag 'Creating a new Acme::Parataxis object (Fiber)...';
    my $f = Acme::Parataxis->new(
        code => sub ($name) {
            diag "Inside fiber. Hello, $name!";
            is( $name, 'Alice', 'Received arg' );
            diag 'Yielding back to parent...';
            my $val = Acme::Parataxis->yield( 'Hello ' . $name );
            diag "Resumed in fiber. Received: $val";
            is( $val, 'Bob', 'Received resume arg' );
            return 'Goodbye ' . $name;
        }
    );
    diag "Calling fiber with 'Alice'...";
    my $res1 = $f->call('Alice');
    is( $res1, 'Hello Alice', 'First call result' );
    diag "First result: $res1";
    diag "Resuming fiber with 'Bob'...";
    my $res2 = $f->call('Bob');
    is( $res2, 'Goodbye Alice', 'Second call result' );
    diag "Final result: $res2";
    ok( $f->is_done, 'Parataxis finished' );
    diag 'Fiber finished successfully.';
};
done_testing();
