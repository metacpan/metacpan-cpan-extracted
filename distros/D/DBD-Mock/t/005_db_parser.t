use strict;

use Test::More tests => 26;

BEGIN {
    use_ok('DBD::Mock');  
    use_ok('DBI');
}

{
    my $dbh = DBI->connect('DBI:Mock:', '', '', { RaiseError => 1, PrintError => 0 });
    isa_ok($dbh, "DBI::db");
    # check to be sure this is set, otherwise 
    # the test wont be set up right
    is($dbh->{RaiseError}, 1, '... make sure RaiseError is set correctly');
    
    # check parse sub-refs
    
    my $parser = sub {
        my ($sql) = @_;
        die "incorrect use of '*'\n" if $sql =~ /^SELECT \*/;
    };
    
    eval { 
        $dbh->{mock_add_parser} = $parser; 
    };
    ok(!$@, '... parser successfully added to dbh');
    
    is($dbh->{mock_parser}->[0], $parser, '... the same parser is stored');
    
    my $sth1 = eval { $dbh->prepare('SELECT myfield FROM mytable') };
    isa_ok($sth1, "DBI::st");
                        
    my $sth2 = eval { $dbh->prepare( 'SELECT * FROM mytable' ) };
    ok(!defined($sth2), '... we should get nothing back from here');
    
    like($@, 
        qr/Failed to parse statement\. Error\: incorrect use of \'\*\'\. Statement\: SELECT \* FROM mytable/, 
        '... parser failure generated correct error');
        
    $dbh->disconnect();
}

# parser class
{
    package MyParser;
    
    sub new { return bless {} }
    sub parse { 
        my ($self, $sql) = @_;
        die "incorrect use of '*'\n" if $sql =~ /^SELECT \*/;        
    }
}

{
    my $dbh = DBI->connect('DBI:Mock:', '', '', { PrintError => 1 });
    isa_ok($dbh, "DBI::db");
    # check to be sure this is set, otherwise 
    # the test wont be set up right
    is($dbh->{PrintError}, 1, '... make sure PrintError is set correctly'); 
    
    # check parse objects
    
    my $parser = MyParser->new();
    
    eval { 
        $dbh->{mock_add_parser} = $parser; 
    };
    ok(!$@, '... parser successfully added to dbh');
    
    is($dbh->{mock_parser}->[0], $parser, '... the same parser is stored');
    
    my $sth1 = eval { $dbh->prepare('SELECT myfield FROM mytable') };
    isa_ok($sth1, "DBI::st");
     
    { # isolate the warn handler 
        local $SIG{__WARN__} = sub {
            my $msg = shift;
            like($msg, 
                 qr/incorrect use of \'\*\'\. Statement\: SELECT \* FROM mytable/,  #'
                 '...got the expected warning');
        };                        
                                                              
        my $sth2 = eval { $dbh->prepare( 'SELECT * FROM mytable' ) };
        ok(!defined($sth2), '... we should get nothing back from here');
    }
    
    $dbh->disconnect();    
}


{ # pass in a bad parser
    my $dbh = DBI->connect('DBI:Mock:', '', '', { RaiseError => 1, PrintError => 0 });
    isa_ok($dbh, "DBI::db");
    # check to be sure this is set, otherwise 
    # the test wont be set up right
    is($dbh->{RaiseError}, 1, '... make sure RaiseError is set correctly');
    
    eval { 
        $dbh->{mock_add_parser} = "Fail"; 
    };
    like($@, qr/Parser must be a code reference or /, '... bad parser successfully not added to dbh');
    
    eval { 
        $dbh->{mock_add_parser} = []; 
    };
    like($@, qr/Parser must be a code reference or /, '... bad parser successfully not added to dbh');

}

{
    # check it with PrintError too
 
    my $dbh = DBI->connect('DBI:Mock:', '', '');
    isa_ok($dbh, "DBI::db");
    # check to be sure this is set, otherwise 
    # the test wont be set up right
    is($dbh->{PrintError}, 1, '... make sure PrintError is set correctly');
    
    { # isolate the warn handler 
        local $SIG{__WARN__} = sub {
            my $msg = shift;
            like($msg, 
                 qr/Parser must be a code reference or /, 
                 '... bad parser successfully not added to dbh');
        };                        

        ok(!defined($dbh->{mock_add_parser} = {}), '... this returns undef too'); 

        my $test = "Fail";
        
        ok(!defined($dbh->{mock_add_parser} = \$test), '... this returns undef too'); 

    }    
    
}
