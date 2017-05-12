use strict;

use Test::More tests => 29;

BEGIN {
    use_ok('DBD::Mock');
    use_ok('DBI');
}

{
    my $dbh = DBI->connect('dbi:Mock:', '', '', { RaiseError => 1, PrintError => 0 });
    isa_ok($dbh, 'DBI::db');
    
    my $session = DBD::Mock::Session->new((
        {
            statement    => 'SELECT foo FROM bar WHERE baz = ?',
            bound_params => [ 100 ],
            results      => [[ 'foo' ], [ 10 ]]
        },
        {
            statement    => 'SELECT bar FROM foo WHERE baz = ?',
            bound_params => [ 125 ],
            results      => [[ 'bar' ], [ 15 ]]
        },
    ));
    isa_ok($session, 'DBD::Mock::Session');
    
    $dbh->{mock_session} = $session;
    
    eval {
        my $sth = $dbh->prepare('SELECT foo FROM bar WHERE baz = ?');
        $sth->execute(100);
        my ($result) = $sth->fetchrow_array();
        is($result, 10, '... got the right value');        
    };
    ok(!$@, '... everything worked as planned');
    
    eval {
        my $sth = $dbh->prepare('SELECT bar FROM foo WHERE baz = ?');
        $sth->execute(125);
        my ($result) = $sth->fetchrow_array();
        is($result, 15, '... got the right value');
    };
    ok(!$@, '... everything worked as planned');

    # Shuts up warning when object is destroyed
    undef $dbh->{mock_session};
}

{
    my $dbh = DBI->connect('dbi:Mock:', '', '', { RaiseError => 1, PrintError => 0 });
    isa_ok($dbh, 'DBI::db');
    
    my $session = DBD::Mock::Session->new((
        {
            statement    => 'SELECT foo FROM bar WHERE baz = ?',
            bound_params => [ 100 ],
            results      => [[ 'foo' ], [ 10 ]]
        },
        {
            statement => 'SELECT bar FROM foo WHERE baz = 125',
            results   => [[ 'bar' ], [ 15 ]]
        },        
        {
            statement    => 'DELETE FROM bar WHERE baz = ?',
            results      => [[], [], []],
            bound_params => [ 100 ]            
        }
    ));
    isa_ok($session, 'DBD::Mock::Session');
    
    $dbh->{mock_session} = $session;
    
    eval {
        my $sth = $dbh->prepare('SELECT foo FROM bar WHERE baz = ?');
        $sth->execute(100);
        my ($result) = $sth->fetchrow_array();
        is($result, 10, '... got the right value');        
    };
    ok(!$@, '... first state worked as planned');
    
    eval {
        my $sth = $dbh->prepare('SELECT bar FROM foo WHERE baz = 125');
        $sth->execute();
        my ($result) = $sth->fetchrow_array();
        is($result, 15, '... got the right value');
    };
    ok(!$@, '... second state worked as planned');
        
    eval {
        my $sth = $dbh->prepare('DELETE FROM bar WHERE baz = ?');
        $sth->execute(100);
        is($sth->rows(), 2, '... got the right number of affected rows');
    };
    ok(!$@, '... third state worked as planned');

    # Shuts up warning when object is destroyed
    undef $dbh->{mock_session};
}

# check some errors

{
    my $dbh = DBI->connect('dbi:Mock:', '', '', { RaiseError => 1, PrintError => 0 });
    isa_ok($dbh, 'DBI::db');
    
    my $session = DBD::Mock::Session->new((
        {
            statement    => 'SELECT foo FROM bar WHERE baz = ?',
            bound_params => [ 100 ],
            results      => [[ 'foo' ], [ 10 ]]
        }
    ));
    isa_ok($session, 'DBD::Mock::Session');
    
    $dbh->{mock_session} = $session;
    
    eval {
        my $sth = $dbh->prepare('SELECT foo FROM bar WHERE baz = ?');
        $sth->execute(100, 200);
        my ($result) = $sth->fetchrow_array();
    };
    ok($@, '... everything failed as planned');
    like($@, 
        qr/Session Error\: Not the same number of bound params in current state in DBD\:\:Mock\:\:Session/, 
        '... everything failed as planned');    

    # Shuts up warning when object is destroyed
    undef $dbh->{mock_session};
}

{
    my $dbh = DBI->connect('dbi:Mock:', '', '', { RaiseError => 1, PrintError => 0 });
    isa_ok($dbh, 'DBI::db');
    
    my $session = DBD::Mock::Session->new((
        {
            statement    => 'SELECT foo FROM bar WHERE baz = ?',
            bound_params => [ 100 ],
            results      => [[ 'foo' ], [ 10 ]]
        }
    ));
    isa_ok($session, 'DBD::Mock::Session');
    
    $dbh->{mock_session} = $session;
    
    eval {
        my $sth = $dbh->prepare('SELECT foo FROM bar WHERE baz = ?');
        $sth->execute(200);
        my ($result) = $sth->fetchrow_array();
    };
    ok($@, '... everything failed as planned');
    like($@, 
        qr/Session Error\: Bound param 0 do not match in current state in DBD\:\:Mock\:\:Session/, 
        '... everything failed as planned');    

    # Shuts up warning when object is destroyed
    undef $dbh->{mock_session};
}

{ 
    my $dbh = DBI->connect('dbi:Mock:', '', '', { RaiseError => 1,  PrintError => 0 }); 
    isa_ok($dbh, 'DBI::db'); 
 
    my $session = DBD::Mock::Session->new(( 
        { 
            statement    => 'SELECT foo FROM bar WHERE baz = ?', 
            bound_params => [ 100 ], 
            results      => [[ 'foo' ], [ 10 ]] 
        }, 
        { 
            statement    => 'SELECT foo FROM bar WHERE baz = ?', 
            bound_params => [ 125 ], 
            results      => [[ 'foo' ], [ 15 ]] 
        }, 
    )); 
    isa_ok($session, 'DBD::Mock::Session'); 
 
    $dbh->{mock_session} = $session; 
 
    eval { 
        my $sth = $dbh->prepare('SELECT foo FROM bar WHERE baz = ?'); 
        $sth->execute(100); 
        my ($result) = $sth->fetchrow_array(); 
        is($result, 10, '... first execute got the right  value'); 
        $sth->execute(125); 
        ($result) = $sth->fetchrow_array(); 
        is($result, 15, '... second execute got the right value'); 
    }; 
    ok(!$@, '... everything worked as planned'); 

    # Shuts up warning when object is destroyed
    undef $dbh->{mock_session};
}
