use Test::More;
use strict;
use warnings;
use DBI;

my $dbh = DBI->connect( $ENV{ PERL_TEST_MYSQLPOOL_DSN } )
    or die $DBI::errstr;

# prepared
my $arrayref = $dbh->selectall_arrayref( 'SELECT * FROM t1', { Slice => {} } );

is_deeply( $arrayref, [
    { user_id => 1 },
]);

done_testing;
