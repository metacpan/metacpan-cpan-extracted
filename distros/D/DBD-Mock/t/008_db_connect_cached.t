use strict;

use Test::More tests => 5;

BEGIN {
    use_ok('DBD::Mock');  
    use_ok('DBI');  
}

# test that connect cached works as expected.

{
    my $dbh = DBI->connect_cached('DBI:Mock:', 'user', 'pass');
    isa_ok($dbh, 'DBI::db'); 
        
    my $dbh2 = DBI->connect_cached('DBI:Mock:', 'user', 'pass');
    isa_ok($dbh2, 'DBI::db');
    
    is($dbh, $dbh2, '.. these should be the same handles');
}
