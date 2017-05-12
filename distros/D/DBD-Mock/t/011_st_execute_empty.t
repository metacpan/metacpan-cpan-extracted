use strict;

use Test::More tests => 15;

BEGIN {
    use_ok('DBD::Mock');  
    use_ok('DBI');
}

my $sql = 'SELECT * FROM foo WHERE bar = ? AND baz = ?';

{
    my $dbh = DBI->connect( 'DBI:Mock:', '', '' );
    my $sth = eval { $dbh->prepare( $sql ) };
    ok( ! $@, 'Statement handle prepared ok' );
    is( ref( $sth ), 'DBI::st',
        'Statement handle returned of the proper type' );
    is( $sth->{mock_my_history}->statement, $sql,
        'Statement handle stores SQL (method on tracker)' );
    is( $sth->{mock_statement}, $sql,
        'Statement handle stores SQL (attribute)' );
    is( $sth->{mock_is_executed}, 'no',
        'Execute flag not set yet' );
    my $rows = eval { $sth->execute() };
    ok( ! $@, 'Called execute() ok (no params)' );
    is($rows, '0E0', '... we got back 0E0 for num of rows');
    is( $sth->{mock_is_executed}, 'yes',
        'Execute flag set after execute()' );
    my $t_params = $sth->{mock_my_history}->bound_params;
    is( scalar @{ $t_params }, 0,
        'No parameters tracked (method on tracker)' );
    my $a_params = $sth->{mock_params};
    is( scalar @{ $a_params }, 0,
        'No parameters tracked (attribute)' );
    is( $sth->{mock_is_finished}, 'no',
        'Finished flag not set yet' );
    eval { $sth->finish };
    ok( ! $@, 'Called finish() ok' );
    is( $sth->{mock_is_finished}, 'yes',
        'Finished flag set after finish()' );
}
