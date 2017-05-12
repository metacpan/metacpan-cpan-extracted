use strict;
use Test::More 0.98;

use DBI;

my $dbh = DBI->connect('dbi:BlackHole:', undef, undef);
isa_ok $dbh, 'DBI::db';
ok $dbh->{Active}, 'should be Active';
ok $dbh->ping, 'should be ping successful';

$dbh->disconnect();
ok !$dbh->{Active}, 'should not be Active';
ok !$dbh->ping, 'should not be ping successful';

done_testing;

