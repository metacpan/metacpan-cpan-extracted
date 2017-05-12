use strict;

use Test::More tests => 25;

BEGIN {
    use_ok('DBD::Mock');  
    use_ok('DBI');  
}

{ # aliasing is off
    my $dbh;
    eval {
        $dbh = DBI->connect('dbi:Mock:mysql', '', '');
    };
    ok(!$@, '... got our non-mock DB successfully');    
    isa_ok($dbh, 'DBI::db');

    ok(!defined($dbh->{mock_attribute_aliases}), '... nothing here');
    ok(!$dbh->{mock_database_name}, '... nothing here');    
}

# now turn it on
$DBD::Mock::AttributeAliasing++;

{ # but without a dbname it does nothing
    my $dbh;
    eval {
        $dbh = DBI->connect('dbi:Mock:', '', '');
    };
    ok(!$@, '... got our non-mock DB successfully');    
    isa_ok($dbh, 'DBI::db');

    ok(!defined($dbh->{mock_attribute_aliases}), '... nothing here');
    ok(!$dbh->{mock_database_name}, '... nothing here');    
}

# now test the error

eval {
    DBI->connect('dbi:Mock:Fail', '', '');
};
like($@, qr/Attribute aliases not available for \'Fail\'/, '... got the error we expected');      

# test the MySQL mock db
{
    my $dbh;
    eval {
        $dbh = DBI->connect('dbi:Mock:mysql', '', '');
    };
    ok(!$@, '... got our mock DB successfully');
    isa_ok($dbh, 'DBI::db');

    is($dbh->{mock_database_name}, 'mysql', '... and its the name we expected');        

    ok(defined($dbh->{mock_attribute_aliases}), '... got something here');
    is(ref($dbh->{mock_attribute_aliases}), 'HASH', '... and its the hash we expected');   
    
    my $sth = $dbh->prepare('INSERT INTO Foo (bar) VALUES(NULL)');
    isa_ok($sth, 'DBI::st');
    
    $sth->execute();    
    
    is($dbh->{mysql_insertid}, 1, '... our alias works');
       
}

# and test it with the lowercasing
{
    my $dbh;
    eval {
        $dbh = DBI->connect('dbi:Mock:MySQL', '', '');
    };
    ok(!$@, '... got our mock DB successfully');
    isa_ok($dbh, 'DBI::db');

    is($dbh->{mock_database_name}, 'MySQL', '... and its the name we expected');        

    ok(defined($dbh->{mock_attribute_aliases}), '... got something here');
    is(ref($dbh->{mock_attribute_aliases}), 'HASH', '... and its the hash we expected');   
    
    my $sth = $dbh->prepare('INSERT INTO Foo (bar) VALUES(NULL)');
    isa_ok($sth, 'DBI::st');
    
    $sth->execute();    
    
    is($dbh->{mysql_insertid}, 1, '... our alias works');
       
}
