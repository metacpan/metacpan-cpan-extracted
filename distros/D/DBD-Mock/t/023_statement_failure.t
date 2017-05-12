use strict;

use Test::More tests => 28;

BEGIN {
    use_ok('DBD::Mock');  
    use_ok('DBI');  
}

# test misc. attributes

{
    my $dbh = DBI->connect('DBI:Mock:', 'user', 'pass');
    isa_ok($dbh, 'DBI::db'); 
    
    $dbh->{mock_add_resultset} = {
        sql => 'SELECT foo FROM bar',
        results => DBD::Mock->NULL_RESULTSET,
        failure => [ 5, 'Ooops!' ],
    };

    $dbh->{PrintError} = 0;
    $dbh->{RaiseError} = 1;

    my $sth = eval { $dbh->prepare('SELECT foo FROM bar') };
    ok(!$@, '$sth handle prepared correctly');
    isa_ok($sth, 'DBI::st');

    eval { $sth->execute() };
    ok( $@, '$sth handled executed and died' );
    
    $dbh->{mock_add_resultset} = {
        sql     => 'SELECT bar FROM foo',
        results => [
            [ 'bar' ],
            [1], [2], [3], [4], [5], [6], [7], [8], [9], [10]
        ]
    };
    #test new error generators
    $dbh->{mock_can_prepare} = 0;
    $dbh->{mock_can_execute} = 1;
    $dbh->{mock_can_fetch}   = 1;
    eval {
        my $sth = $dbh->prepare("SELECT bar FROM foo");
        $sth->execute;
        while (my $row = $sth->fetchrow_arrayref) {
            1;
        }
    };
    ok($@ =~ /Cannot prepare/, '$sth handle failed to prepare');
    
    $dbh->{mock_can_prepare} = -3;
    $dbh->{mock_can_execute} = 1;
    $dbh->{mock_can_fetch}   = 1;
    my $i = 0;
    for (1 .. 10) {
        $i++;
        eval {
            my $sth = $dbh->prepare("SELECT bar FROM foo");
            $sth->execute;
            while (my $row = $sth->fetchrow_arrayref) {
                1;
            }
        };
        last if $@;
    }
    ok($@ =~ /Cannot prepare/, "$@ should contain 'Cannot prepare'");
    ok($i == 4, "$i should be 4");
    
    $dbh->{mock_can_prepare} = 1;
    $dbh->{mock_can_execute} = 0;
    $dbh->{mock_can_fetch}   = 1;
    eval {
        my $sth = $dbh->prepare("SELECT bar FROM foo");
        $sth->execute;
        while (my $row = $sth->fetchrow_arrayref) {
            1;
        }
    };
    ok($@ =~ /Cannot execute/, '$sth handle failed to execute');
    
    $dbh->{mock_can_prepare} = 1;
    $dbh->{mock_can_execute} = -3;
    $dbh->{mock_can_fetch}   = 1;
    $i = 0;
    for (1 .. 10) {
        $i++;
        eval {
            my $sth = $dbh->prepare("SELECT bar FROM foo");
            $sth->execute;
            while (my $row = $sth->fetchrow_arrayref) {
                1;
            }
        };
        last if $@;
    }
    ok($@ =~ /Cannot execute/, "$@ should contain 'Cannot execute'");
    ok($i == 4, "$i should be 4");
    
    $dbh->{mock_can_prepare} = 1;
    $dbh->{mock_can_execute} = 1;
    $dbh->{mock_can_fetch}   = 0;
    eval {
        my $sth = $dbh->prepare("SELECT bar FROM foo");
        $sth->execute;
        while (my $row = $sth->fetchrow_arrayref) {
            1;
        }
    };
    ok($@ =~ /Cannot fetch/, '$sth handle failed to fetch');
    
    $dbh->{mock_can_prepare} = 1;
    $dbh->{mock_can_execute} = 1;
    $dbh->{mock_can_fetch}   = 0;
    eval {
        my $sth = $dbh->prepare("SELECT bar FROM foo");
        $sth->execute;
        while (my @row = $sth->fetchrow_array) {
            1;
        }
    };
    ok($@ =~ /Cannot fetch/, '$sth handle failed to fetch');
    
    $dbh->{mock_can_prepare} = 1;
    $dbh->{mock_can_execute} = 1;
    $dbh->{mock_can_fetch}   = 0;
    eval {
        my $sth = $dbh->prepare("SELECT bar FROM foo");
        $sth->execute;
        while (my $row = $sth->fetchrow_hashref) {
            1;
        }
    };
    ok($@ =~ /Cannot fetch/, '$sth handle failed to fetch');
    
    $dbh->{mock_can_prepare} = 1;
    $dbh->{mock_can_execute} = 1;
    $dbh->{mock_can_fetch}   = 0;
    eval {
        my $sth = $dbh->prepare("SELECT bar FROM foo");
        $sth->execute;
        my @row = $sth->fetchall_arrayref;
    };
    ok($@ =~ /Cannot fetch/, '$sth handle failed to fetch');
    
    $dbh->{mock_can_prepare} = 1;
    $dbh->{mock_can_execute} = 1;
    $dbh->{mock_can_fetch}   = -100;
    {
        my $sth;
        eval {
            $sth = $dbh->prepare("select bar from foo");
            $sth->execute;
        };
        ok(!$@, "prepare and execute should work");
        isa_ok($sth, 'DBI::st');
    
        eval { my $row = $sth->fetch };
        ok(!$@, "fetch should work");
        ok($dbh->{mock_can_fetch}==-99, "$dbh->{mock_can_fetch} should be -99");
    
        eval { my $row = $sth->fetchrow_arrayref };
        ok(!$@, "fetch should work");
        ok($dbh->{mock_can_fetch}==-98, "$dbh->{mock_can_fetch} should be -98");
    
        eval { my @row = $sth->fetchrow_array };
        ok(!$@, "fetch should work");
        ok($dbh->{mock_can_fetch}==-97, "$dbh->{mock_can_fetch} should be -97");
    
        eval { my $row = $sth->fetchrow_hashref };
        ok(!$@, "fetch should work");
        ok($dbh->{mock_can_fetch}==-96, "$dbh->{mock_can_fetch} should be -96");
    
        eval { my @rows = $sth->fetchall_arrayref };
        ok(!$@, "fetch should work");
        ok($dbh->{mock_can_fetch}==-95, "$dbh->{mock_can_fetch} should be -95");
    }    
}
