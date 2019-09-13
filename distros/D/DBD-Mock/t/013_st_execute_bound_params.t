use 5.008;

use strict;
use warnings;

use Test::More;
use DBI qw( :sql_types );

BEGIN {
    use_ok('DBD::Mock');  
}

my $sql = 'SELECT * FROM foo WHERE bar = ? AND baz = ?';

{
    my $dbh = DBI->connect( 'DBI:Mock:', '', '' );
    my $sth = eval { $dbh->prepare( $sql ) };
    eval {
        $sth->bind_param( 2, 'bar' );
        $sth->bind_param( 1, 'baz' );
    };
    ok( ! $@, 'Parameters bound to statement handle with bind_param()' );

    eval { $sth->execute() };

    ok( ! $@, 'Called execute() ok (empty, after bind_param calls)' );

    my $t_params = $sth->{mock_my_history}->bound_params;
    is( scalar @{ $t_params }, 2,
        'Correct number of parameters bound (method on tracker)' );
    is( $t_params->[0], 'baz',
        'Statement handle stored bound parameter from bind_param() (method on tracker)' );
    is( $t_params->[1], 'bar',
        'Statement handle stored bound parameter from bind_param() (method on tracker)' );

    my $param_attrs = $sth->{mock_my_history}->bound_param_attrs;

    is( scalar @{ $param_attrs }, 2,
        'bound_param_types length should match the number of bound parameters' );

    is( $param_attrs->[0], undef,
        "as we didn't specify any attributes/types for the first bound parameter then it should be undefined");
    is( $param_attrs->[1], undef,
        "as we didn't specify any attributes/types for the second bound parameter then it should be undefined");

    my $a_params = $sth->{mock_params};
    is( scalar @{ $a_params }, 2, 'Correct number of parameters bound (attribute)' );
    is( $a_params->[0], 'baz',
        'Statement handle stored bound parameter from bind_param() (attribute)' );
    is( $a_params->[1], 'bar',
        'Statement handle stored bound parameter from bind_param() (attribute)' );

    my $a_param_attrs = $sth->{mock_param_attrs};

    is( scalar @{ $a_param_attrs }, 2,
        'bound_param_types length should match the number of bound parameters' );

    is( $a_param_attrs->[0], undef,
        "as we didn't specify any attributes/types for the first bound parameter then it should be undefined");
    is( $a_param_attrs->[1], undef,
        "as we didn't specify any attributes/types for the second bound parameter then it should be undefined");
}

{
    my $dbh = DBI->connect( 'DBI:Mock:', '', '' );
    my $sth = eval { $dbh->prepare( $sql ) };
    eval {
        $sth->bind_param( 2, 'bar', SQL_VARCHAR );
        $sth->bind_param( 1, 'baz', { TYPE => SQL_VARCHAR } );
    };
    ok( ! $@, 'Parameters bound to statement handle with bind_param()' );
    eval { $sth->execute() };
    ok( ! $@, 'Called execute() ok (empty, after bind_param calls)' );

    my $t_params = $sth->{mock_my_history}->bound_params;
    is( scalar @{ $t_params }, 2,
        'Correct number of parameters bound (method on tracker)' );
    is( $t_params->[0], 'baz',
        'Statement handle stored bound parameter from bind_param() (method on tracker)' );
    is( $t_params->[1], 'bar',
        'Statement handle stored bound parameter from bind_param() (method on tracker)' );

    my $param_attrs = $sth->{mock_my_history}->bound_param_attrs;

    is( scalar @{ $param_attrs }, 2,
        'bound_param_types length should match the number of bound parameters' );

    is_deeply( $param_attrs->[0], { TYPE => SQL_VARCHAR },
        "the second bound parameter attribute should match our hashref");
    is( $param_attrs->[1], SQL_VARCHAR,
        "the first bound parameter attribute should match what we bound");

    my $a_params = $sth->{mock_params};
    is( scalar @{ $a_params }, 2, 'Correct number of parameters bound (attribute)' );
    is( $a_params->[0], 'baz',
        'Statement handle stored bound parameter from bind_param() (attribute)' );
    is( $a_params->[1], 'bar',
        'Statement handle stored bound parameter from bind_param() (attribute)' );

    my $a_param_attrs = $sth->{mock_param_attrs};

    is( scalar @{ $a_param_attrs }, 2,
        'bound_param_types length should match the number of bound parameters' );

    is_deeply( $a_param_attrs->[0], { TYPE => SQL_VARCHAR },
        "the second bound parameter attribute should match our hashref");
    is( $a_param_attrs->[1], SQL_VARCHAR,
        "the first bound parameter attribute should match what we bound");
}

{
    my $dbh = DBI->connect( 'DBI:Mock:', '', '' );
    my $sth = eval { $dbh->prepare( $sql ) };
    eval { $sth->execute( 'baz', 'bar' ) };
    ok( ! $@, 'Called execute() ok (empty, after bind_param calls)' );

    my $t_params = $sth->{mock_my_history}->bound_params;
    is( scalar @{ $t_params }, 2,
        'Correct number of parameters bound (method on tracker)' );
    is( $t_params->[0], 'baz',
        'Statement handle stored bound parameter from bind_param() (method on tracker)' );
    is( $t_params->[1], 'bar',
        'Statement handle stored bound parameter from bind_param() (method on tracker)' );

    my $param_attrs = $sth->{mock_my_history}->bound_param_attrs;

    is( scalar @{ $param_attrs }, 2,
        'bound_param_types length should match the number of bound parameters' );

    is( $param_attrs->[0], undef,
        "the first bound parameter attribute should be undef as the value was bound in the execute() call");
    is( $param_attrs->[1], undef,
        "the second bound parameter attribute should be undef as the value was bound in the execute() call");

    my $a_params = $sth->{mock_params};
    is( scalar @{ $a_params }, 2, 'Correct number of parameters bound (attribute)' );
    is( $a_params->[0], 'baz',
        'Statement handle stored bound parameter from bind_param() (attribute)' );
    is( $a_params->[1], 'bar',
        'Statement handle stored bound parameter from bind_param() (attribute)' );

    my $a_param_attrs = $sth->{mock_param_attrs};

    is( scalar @{ $a_param_attrs }, 2,
        'bound_param_types length should match the number of bound parameters' );

    is( $a_param_attrs->[0], undef,
        "the first bound parameter attribute should be undef as the value was bound in the execute() call");
    is( $a_param_attrs->[1], undef,
        "the second bound parameter attribute should be undef as the value was bound in the execute() call");
}
{
    my $dbh = DBI->connect( 'DBI:Mock:', '', '' );
    my $sth = eval { $dbh->prepare( 'begin dbms_output.get_line(?,?); end;' ) };
    my ($bar, $baz) = ('bar', 'baz');
    eval {
        $sth->bind_param_inout( 2, \$bar, 10 );
        $sth->bind_param_inout( 1, \$baz, 100 );
    };
    diag $@ if $@;
    ok(!$@, 'Parameters bound to statement handle with bind_param_inout()' );
    eval { $sth->execute() };
    ok( ! $@, 'Called execute() ok (empty, after bind_param_inout calls)' );
    my $t_params = $sth->{mock_my_history}->bound_params;
    is( scalar @{ $t_params }, 2, 'Correct number of parameters bound (method on tracker)' );
    is( $t_params->[0], \$baz,
        'Statement handle stored bound parameter from bind_param_inout() (method on tracker)' );
    is( $t_params->[1], \$bar,
        'Statement handle stored bound parameter from bind_param_inout() (method on tracker)' );
    my $a_params = $sth->{mock_params};
    is( scalar @{ $a_params }, 2,
        'Correct number of parameters bound (attribute)' );
    is( $a_params->[0], \$baz,
        'Statement handle stored bound parameter from bind_param_inout() (attribute)' );
    is( $a_params->[1], \$bar,
        'Statement handle stored bound parameter from bind_param_inout() (attribute)' );
}

{
    my $dbh = DBI->connect( 'DBI:Mock:', '', '' );
    my $sth = eval { $dbh->prepare( $sql ) };
    eval {
        $sth->bind_param( 2, 'bar' );
        $sth->bind_param( 1, 'baz', SQL_VARCHAR );
        $sth->execute();
    };
    ok( ! $@, 'Parameters bound to statement handle with bind_param() and executed' );

    eval {
        $sth->bind_param( 2, 'foo', { TYPE => SQL_VARCHAR } );
        $sth->bind_param( 1, 'qux' );
        $sth->execute();
    };
    ok( ! $@, 'Parameters bound to statement handle with bind_param() and executed' );

    my $executionHistory = $sth->{mock_execution_history};
    is_deeply(
        $executionHistory,
        [
            {
                params => [ 'baz', 'bar' ],
                attrs  => [ SQL_VARCHAR, undef ],
            }, {
                params => [ 'qux', 'foo' ],
                attrs  => [ undef, { TYPE => SQL_VARCHAR } ],
            }
        ],
        "mock_execution_history should list the parameters and their attributes for each execution"
    );
}

done_testing();
