use 5.008;

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('DBD::Mock');  
    use_ok('DBI');
}


{
    my $dbh = DBI->connect('dbi:Mock:', '', '');
    isa_ok($dbh, 'DBI::db');

    $dbh->{mock_add_resultset} = {
        sql => 'SELECT baz FROM qux',
        prepare_attributes => {
            foo => 'bar'
        },
        results => [[ 'baz' ], [ 10 ]]
    };

    my $sth = $dbh->prepare('SELECT baz FROM qux');
    isa_ok($sth, 'DBI::st');

    is( $sth->{foo}, 'bar', "our custom prepare_attribute should be set after the prepare" );

    my $rows = $sth->execute();
    is($rows, '0E0', '... got back 0E0 for rows with a SELECT statement');

    is( $sth->{foo}, 'bar', "our custom prepare_attribute should persist after the execute if nothing's changed it" );
}

{
    my $dbh = DBI->connect('dbi:Mock:', '', '');
    isa_ok($dbh, 'DBI::db');

    $dbh->{mock_add_resultset} = {
        sql => 'SELECT baz FROM qux',
        execute_attributes => {
            foo => 'bar'
        },
        results => [[ 'baz' ], [ 10 ]]
    };

    my $sth = $dbh->prepare('SELECT baz FROM qux');
    isa_ok($sth, 'DBI::st');

    is( $sth->{foo}, undef, "our custom execute_attribute should be undefined until we execute the statement" );

    my $rows = $sth->execute();
    is($rows, '0E0', '... got back 0E0 for rows with a SELECT statement');

    is( $sth->{foo}, 'bar', "our custom execute_attribute should be present after the statements executed" );
}

{
    my $dbh = DBI->connect('dbi:Mock:', '', '');
    isa_ok($dbh, 'DBI::db');

    $dbh->{mock_add_resultset} = {
        sql => 'SELECT baz FROM qux',
        execute_attributes => {
            foo => 'should be overwritten',
        },
        callback => sub {
            my @bound_params = @_;

            my %result = (
                fields => [ 'baz'],
                rows => [],
                last_insert_id => 99,
                execute_attributes => {
                    foo => 'bar'
                },
            );

            return %result;
        },
        results => [[ 'baz' ], [ 10 ]]
    };

    my $sth = $dbh->prepare('SELECT baz FROM qux');
    isa_ok($sth, 'DBI::st');

    is( $sth->{foo}, undef, "our custom execute_attribute should be undefined until we execute the statement" );

    my $rows = $sth->execute();
    is($rows, '0E0', '... got back 0E0 for rows with a SELECT statement');

    is( $sth->{foo}, 'bar', "our custom execute_attribute should be present after the statements executed" );
}


{
    my $dbh = DBI->connect('dbi:Mock:', '', '');
    isa_ok($dbh, 'DBI::db');

    $dbh->{mock_add_resultset} = {
        sql => 'SELECT baz FROM qux',
        prepare_attributes => {
            foo => 'prepare_bar',
            qux => 'prepare_quz',
        },
        execute_attributes => {
            foo => 'execute_bar'
        },
        results => [[ 'baz' ], [ 10 ]]
    };

    my $sth = $dbh->prepare('SELECT baz FROM qux');
    isa_ok($sth, 'DBI::st');

    is( $sth->{foo}, 'prepare_bar', "our custom prepare_attribute should be present after the statement has been defined" );
    is( $sth->{qux}, 'prepare_quz', "our custom prepare_attribute should be present after the statement has been defined" );

    my $rows = $sth->execute();
    is($rows, '0E0', '... got back 0E0 for rows with a SELECT statement');

    is( $sth->{foo}, 'execute_bar', "our custom execute_attribute should take precedence over the the prepare one after the statements executed" );
    is( $sth->{qux}, 'prepare_quz', "our custom prepare_attribute should still be present after the statement has been executed if there's no matching execute_attributes entry" );
}

done_testing();
