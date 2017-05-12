
use InitShareDBI; 
use Test::More tests => 3;

my $dbh = InitShareDBI->dbh;

ok($dbh, 'got dbh ' . (getppid). ' ' . scalar($dbh));
ok($dbh->{Active}, 'it is active');
ok($dbh->do("SELECT LAST_DAY('2008-08-08')"), 'can select');
done_testing();

1;
