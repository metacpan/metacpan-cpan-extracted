use strict;
use warnings;

use Test::More;
use Test::Warn;
use Test::Exception;
use DBIO::SQLite::Test;
my $schema = DBIO::SQLite::Test->init_schema();

my $art = $schema->resultset("Artist")->find(4);
ok(!defined($art), 'Find on primary id: artist not found');
my @cd = $schema->resultset("CD")->find(6);
cmp_ok(@cd, '==', 1, 'Return something even in array context');
ok(@cd && !defined($cd[0]), 'Array contains an undef as only element');

$art = $schema->resultset("Artist")->find({artistid => '4'});
ok(!defined($art), 'Find on unique constraint: artist not found');
@cd = $schema->resultset("CD")->find({artist => '2', title => 'Lada-Di Lada-Da'});
cmp_ok(@cd, '==', 1, 'Return something even in array context');
ok(@cd && !defined($cd[0]), 'Array contains an undef as only element');

$art = $schema->resultset("Artist")->search({name => 'The Jesus And Mary Chain'});
isa_ok($art, 'DBIO::ResultSet', 'get a DBIO::ResultSet object');
my $next = $art->next;
ok(!defined($next), 'Nothing next in ResultSet');
my $cd = $schema->resultset("CD")->search({title => 'Rubbersoul'});
@cd = $cd->next;
cmp_ok(@cd, '==', 1, 'Return something even in array context');
ok(@cd && !defined($cd[0]), 'Array contains an undef as only element');

$art = $schema->resultset("Artist")->single({name => 'Bikini Bottom Boys'});
ok(!defined($art), 'Find on primary id: artist not found');
@cd = $schema->resultset("CD")->single({title => 'The Singles 1962-2006'});
cmp_ok(@cd, '==', 1, 'Return something even in array context');
ok(@cd && !defined($cd[0]), 'Array contains an undef as only element');

$art = $schema->resultset("Artist")->search({name => 'Random Girl Band'});
isa_ok($art, 'DBIO::ResultSet', 'get a DBIO::ResultSet object');
$next = $art->single;
ok(!defined($next), 'Nothing next in ResultSet');
$cd = $schema->resultset("CD")->search({title => 'Call of the West'});
@cd = $cd->single;
cmp_ok(@cd, '==', 1, 'Return something even in array context');
ok(@cd && !defined($cd[0]), 'Array contains an undef as only element');

$cd = $schema->resultset("CD")->first;
my $artist_rs = $schema->resultset("Artist")->search({ artistid => $cd->artist->artistid });
for my $key ('', 'primary') {
  my $kind = $key ? 'explicit' : 'implicit';
  my $art = $artist_rs->find({}, { $key ? (key => $key) : () });
  is($art->artistid, $cd->get_column('artist'), "Artist found through $kind key locked in the resultset");

  # find looks up exactly the row described (ADR 0070): the whole condition
  # is one AND, a name that is not the locked artist's name matches nothing
  is($artist_rs->find({ name => 'some other name' }, { $key ? (key => $key) : () }), undef, "Extra column contradicting the locked row finds nothing ($kind key)");
}

# collapsing and non-collapsing are separate codepaths, thus the separate tests


$artist_rs = $schema->resultset("Artist");

warnings_exist {
  $artist_rs->search({})->single
} qr/\QQuery returned more than one row.  SQL that returns multiple rows is DEPRECATED for ->find and ->single/
    =>  "Non-unique single generated a cursor inexhaustion warning";

# find never runs a non-unique condition (ADR 0070)
throws_ok {
  $artist_rs->find({})
} qr/find\(\) needs a condition that gives every column of one unique constraint of source 'Artist' a concrete value/;

throws_ok {
  $artist_rs->find({}, { key => 'primary' })
} qr/Unable to satisfy requested constraint 'primary'/;

# a NULL in the requested constraint does not cover it: find throws where it
# used to warn and run a query that cannot match (ADR 0070)
throws_ok {
  $artist_rs->find({ artistid => undef }, { key => 'primary' })
} qr/find\(\) with key 'primary': column\(s\) 'artistid' is undef; a unique constraint is covered by defined values/,
  'NULL condition on the requested constraint throws';


$artist_rs = $schema->resultset("Artist")->search({}, { prefetch => 'cds' });

# single() is refused on a collapsing resultset, find() on a non-unique
# condition throws: the collapsing path no longer has a cursor inexhaustion
# warning to test, the refusal takes its place
throws_ok {
  $artist_rs->search({})->single
} qr/single\(\) can not be used on resultsets collapsing a has_many/;

throws_ok {
  $artist_rs->find({})
} qr/find\(\) needs a condition that gives every column of one unique constraint of source 'Artist' a concrete value/;

throws_ok {
  $artist_rs->find({}, { key => 'primary' })
} qr/Unable to satisfy requested constraint 'primary'/;

done_testing;
