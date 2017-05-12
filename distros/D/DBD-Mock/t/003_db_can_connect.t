use strict;

use Test::More tests => 22;

BEGIN {
    use_ok('DBD::Mock');  
    use_ok('DBI');
}

# test this as an exception
{
    my $dbh = DBI->connect('DBI:Mock:', '', '', { RaiseError => 1, PrintError => 0 });
    isa_ok($dbh, "DBI::db");
    # check to be sure this is set, otherwise 
    # the test wont be set up right
    is($dbh->{RaiseError}, 1, '... make sure RaiseError is set correctly');
        
    # check to see it is active in the first place
    ok($dbh->{Active}, '...our handle with the default settting is Active' );
    ok($dbh->ping(), '...and successfuly pinged handle' );
    
    $dbh->{mock_can_connect} = 0;
    
    # check our value is correctly set
    is($dbh->{mock_can_connect}, 0, '... can connect is set to 0');
    
    # and check the side effects of that
    ok(!$dbh->{Active}, '...our handle is no longer Active after setting mock_can_connect');
    ok(!$dbh->ping(), '...and unsuccessfuly pinged handle (good)');
    
    my $sth = eval { $dbh->prepare( "SELECT foo FROM bar" ) };
    ok($@, '... we should have an exception');
    
    like($@, 
        qr/No connection present/,
        'Preparing statement against inactive handle throws expected exception' );
        
    like($dbh->errstr, 
        qr/^No connection present/,
        'Preparing statement against inactive handle sets expected DBI error' );
     
    $dbh->disconnect();     
}

# and now test this as a warning
{
    
    my $dbh = DBI->connect('DBI:Mock:', '', '', { PrintError => 1 });
    isa_ok($dbh, "DBI::db");
    # check to be sure this is set, otherwise 
    # the test wont be set up right
    is($dbh->{PrintError}, 1, '... make sure PrintError is set correctly');
        
    # check to see it is active in the first place
    ok($dbh->{Active}, '...our handle with the default settting is Active' );
    ok($dbh->ping(), '...and successfuly pinged handle' );
    
    $dbh->{mock_can_connect} = 0;
    
    # check our value is correctly set
    is($dbh->{mock_can_connect}, 0, '... can connect is set to 0');
    
    # and check the side effects of that
    ok(!$dbh->{Active}, '...our handle is no longer Active after setting mock_can_connect');
    ok(!$dbh->ping(), '...and unsuccessfuly pinged handle (good)');    

    { # isolate the warn handler 
        local $SIG{__WARN__} = sub {
            my $msg = shift;
            like($msg, qr/No connection present/, '...got the expected warning');
        };
    
        my $sth = eval { $dbh->prepare( "SELECT foo FROM bar" ) };
        ok(!$@, '... we should not have an exception');
        ok(!defined($sth), '... and our statement should be undefined');
    }

    $dbh->disconnect();
}
