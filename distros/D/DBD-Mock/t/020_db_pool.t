use strict;

use Test::More tests => 16;

BEGIN {
    use_ok( 'DBD::Mock' => qw(Pool) );
    use_ok('DBI');    
}

# check that the pool works
{

    my $dbh = DBI->connect("DBI:Mock:", '', '', {RaiseError => 1 });
    isa_ok($dbh, 'DBD::Mock::Pool::db');
    
    my $dbh2 = DBI->connect("DBI:Mock:", '', '', {RaiseError => 1 });
    isa_ok($dbh2, 'DBD::Mock::Pool::db');
    
    is($dbh, $dbh2, '... these handles should be the same');
    
    ok($dbh->disconnect(), '... this will not actually do anything just return true');
    ok($dbh2->disconnect(), '... this will not actually do anything just return true');

}

# check that the pool holds result sets
# in an scope indepenent manner

{
    # set up handle from pool
    my $dbh = DBI->connect("DBI:Mock:", '', '', {RaiseError => 1 });
    isa_ok($dbh, 'DBD::Mock::Pool::db');
    
    $dbh->{mock_add_resultset} = [[ 'foo', 'bar', 'baz' ], [ 1, 2, 3 ]];
    
    ok($dbh->disconnect(), '... not really disconnecting, just returning true');
}

{
    # execute a statement, and expect the results
    my $dbh = DBI->connect("DBI:Mock:", '', '', {RaiseError => 1 });
    isa_ok($dbh, 'DBD::Mock::Pool::db');
    
    my $sth = $dbh->prepare("SELECT foo, bar, baz FROM whatever");
    $sth->execute();
    is_deeply(
        $sth->fetchrow_arrayref(),
        [ 1, 2, 3 ],
        '... got our row correctly'
        );
    $sth->finish();
    
    ok($dbh->disconnect(), '... not really disconnecting, just returning true');
}

{
    # check our statement history
    my $dbh = DBI->connect("DBI:Mock:", '', '');
    isa_ok($dbh, 'DBD::Mock::Pool::db');
    
    my $history = $dbh->{mock_all_history};
    
    is(scalar @{$history}, 1, '... we executed 1 statement');    
    
    is( $history->[0]->statement(), 
        "SELECT foo, bar, baz FROM whatever", 
        '... this the statement we executed');
    
    ok($dbh->disconnect(), '... not really disconnecting, just returning true');
}
