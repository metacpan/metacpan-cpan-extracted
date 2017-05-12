use strict;

use Test::More tests => 9;

BEGIN {
    use_ok('DBD::Mock');  
    use_ok('DBI');
}

my $sql = 'SELECT * FROM foo WHERE bar = ? AND baz = ?';

{
    my $dbh = DBI->connect( 'DBI:Mock:', '', '' );
    my $sth = eval { $dbh->prepare( $sql ) };
    eval { $sth->execute( 'baz', 'bar' ) };
    ok( ! $@, 'Called execute() ok (inline params)' );
    my $t_params = $sth->{mock_my_history}->bound_params;
    is( scalar @{ $t_params }, 2,
        'Correct number of parameters bound (inline; method on tracker)' );
    is( $t_params->[0], 'baz',
        'Statement handle stored bound inline parameter (method on tracker)' );
    is( $t_params->[1], 'bar',
        'Statement handle stored bound inline parameter (method on tracker)' );
    my $a_params = $sth->{mock_my_history}->bound_params;
    is( scalar @{ $a_params }, 2,
        'Correct number of parameters bound (inline; attribute)' );
    is( $a_params->[0], 'baz',
        'Statement handle stored bound inline parameter (attribute)' );
    is( $a_params->[1], 'bar',
        'Statement handle stored bound inline parameter (attribute)' );
}
