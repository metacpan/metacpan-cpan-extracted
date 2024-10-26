use Test2::V0 -target => DBIx::QuickORM::SQLAbstract;

use ok $CLASS;

my $sql = $CLASS->new;

my $A = bless(["a"], 'A');
my $B = bless(["b"], 'B');
my $X1 = bless(["x1"], 'X');
my $X2 = bless(["x2"], 'X');

my $where = [{a => $A, b => $B}, {x => { '-in' => [$X1, $X2]}}];

subtest select => sub {
    my ($stmt, $bind, $bind_names) = $sql->select(
        'foo',
        ['a', 'b'],
        $where,
    );

    is($stmt, 'SELECT a, b FROM foo WHERE ( ( a = ? AND b = ? ) OR x IN ( ?, ? ) )', "Got correct statement");
    is(
        $bind,
        [$A, $B, $X1, $X2],
        "Got expected binds in correct order"
    );
    is(
        $bind_names,
        [qw/a b x x/],
        "Got the column names of all the binds in order"
    );
};

subtest where => sub {
    my ($stmt, $bind, $bind_names) = $sql->where($where);

    # Not sure why, but these WHERE has one extra set of parens compared to the select() version
    is($stmt, ' WHERE ( ( ( a = ? AND b = ? ) OR x IN ( ?, ? ) ) )', "Got correct statement");
    is(
        $bind,
        [$A, $B, $X1, $X2],
        "Got expected binds in correct order"
    );
    is(
        $bind_names,
        [qw/a b x x/],
        "Got the column names of all the binds in order"
    );
};

done_testing;
