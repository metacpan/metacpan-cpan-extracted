#!perl
# 050-runnable.t: Tests of D::H::G::Runnable functions not covered elsewhere
use rlib 'lib';
use HopenTest;
use Test::Fatal;
use Data::Hopen::Scope::Hash;

{
    package DummyRunnable;
    use strict; use warnings;
    use Data::Hopen;
    use parent 'Data::Hopen::G::Runnable';
    use Class::Tiny { oops => !!0 };
    sub _run {
        my ($self, %args) = getparameters('self', [qw(*)], @_);
        return [] if $self->oops;
        # Copied from Data::Hopen::G::CollectOp
            return $self->passthrough(-nocontext => 1, -levels => 1)
                # -nocontext because Runnable::run() already hooked in the context
    }
}

my $dut = DummyRunnable->new;

like(exception { $dut->run(-context => 1, -nocontext => 1) },
    qr{Can't combine}, 'run: -context and -nocontext are mutually exclusive');
like(exception { $dut->passthrough(-context => 1, -nocontext => 1) },
    qr{Can't combine}, 'passthrough: -context and -nocontext are mutually exclusive');

my $scope = Data::Hopen::Scope::Hash->new;
$scope->put(foo => 42);

is_deeply($dut->passthrough(-context => $scope), {foo=>42}, 'passthrough');

$dut->oops(true);
like(exception { $dut->run(-nocontext => 1) }, qr{did not return a hashref},
    "run() checks _run()'s return type");

done_testing();
