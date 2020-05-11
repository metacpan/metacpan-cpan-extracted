#!perl
# t/124-dag-merge.t: test Data::Hopen::G::DAG's warnings on _run()
use rlib 'lib';
use HopenTest;
use Test::Fatal;

use Data::Hopen;
use Data::Hopen::Scope::Hash;
use Data::Hopen::Scope::Environment;
use Data::Hopen::G::Link;

$Data::Hopen::VERBOSE = 10;  # for coverage

run();
done_testing();

sub make_dag {  # See t/121-dag-single-goal.t for the explanation of this
    my ($link) = @_;

    my $dag = hnew DAG => 'dag';
    my $goal = $dag->goal('all');
    isa_ok($goal, 'Data::Hopen::G::Goal');

    # Make a first op
    my $op1 = hnew CollectOp => 'op1', levels => 3;
    isa_ok($op1,'Data::Hopen::G::CollectOp');
    $dag->connect($op1, $link, $goal);

    return wantarray ? ($dag, $op1, $goal) : $dag;
} #make_dag()

{ # Link with fixed output
    package FixedLink;
    use Data::Hopen;
    use parent 'Data::Hopen::G::Link';
    sub _run {
        my ($self, %args) = getparameters('self', [qw(; phase visitor)], @_);
        return { xyzzy => 'plugh' };
    }
}

{ # Link that adds to its inputs
    package AdditiveLink;
    use Data::Hopen;
    use parent 'Data::Hopen::G::Link';
    use Class::Tiny {to_add => sub { +{ xyzzy => 'plugh' } } };

    sub _run {
        my ($self, %args) = getparameters('self', [qw(; phase visitor)], @_);
        my $inputs = $self->scope->as_hashref(-levels => 3);
        return +{ %$inputs, %{$self->to_add} };
    }
}

{ # Link that modifies its inputs
    package MutantLink;
    use Data::Hopen;
    use parent 'Data::Hopen::G::Link';
    sub _run {
        my ($self, %args) = getparameters('self', [qw(; phase visitor)], @_);
        my $inputs = $self->scope->as_hashref;
        my $multiplier = $inputs->{multiplier} // 2;
        $inputs->{foo} *= $multiplier if exists $inputs->{foo};
        return $inputs;
    }
}

sub run {   # Run the tests
    my ($dag, $op, $goal, $hrOut);
    my $outermost_scope = Data::Hopen::Scope::Hash->new()->put(
        foo => 42, bar => 'Bar'
    );

    # no link: passthrough
    $dag = make_dag(undef);
    $hrOut = $dag->run(-context=>$outermost_scope);

    is_deeply($hrOut, { all => {
                foo => 42,
                bar => 'Bar',
            } }, 'no link => passthrough');

    # Fixed-output link
    $dag = make_dag(FixedLink->new());
    $hrOut = $dag->run(-context=>$outermost_scope);

    is_deeply($hrOut, { all => {
                xyzzy => 'plugh',
            } }, 'fixed link replaces values');

    # Additive link
    $dag = make_dag(AdditiveLink->new());
    $hrOut = $dag->run(-context=>$outermost_scope);

    is_deeply($hrOut, { all => {
                foo => 42,
                bar => 'Bar',
                xyzzy => 'plugh',
            } }, 'additive link adds values');

    # Mutator link
    $dag = make_dag(MutantLink->new());
    $hrOut = $dag->run(-context=>$outermost_scope);

    is_deeply($hrOut, { all => {
                foo => 84,
                bar => 'Bar',
            } }, 'mutator link changes values');

    # Test multiple independent links
    ($dag, $op, $goal) = make_dag(AdditiveLink->new());
    $dag->connect($op, MutantLink->new, $goal);
    $hrOut = $dag->run(-context=>$outermost_scope);

    is_deeply($hrOut, { all => {
                foo => 84,
                bar => 'Bar',
                xyzzy => 'plugh',
            } }, 'two links have independent effects');

    # Test multiple, order-dependent links
    ($dag, $op, $goal) = make_dag(AdditiveLink->new(to_add => {multiplier => 3}));
    $dag->connect($op, MutantLink->new, $goal);
    $hrOut = $dag->run(-context=>$outermost_scope);

    is_deeply($hrOut, { all => {
                foo => 42*3,
                bar => 'Bar',
                multiplier => 3,
            } }, 'two links - ordered effects 1/2');

    ($dag, $op, $goal) = make_dag(MutantLink->new);
    $dag->connect($op, AdditiveLink->new(to_add => {multiplier => 3}), $goal);
    $hrOut = $dag->run(-context=>$outermost_scope);

    is_deeply($hrOut, { all => {
                foo => 42*2,
                bar => 'Bar',
                multiplier => 3,
            } }, 'two links - ordered effects 2/2');
} #run()
