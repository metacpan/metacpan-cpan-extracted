# Regression test: futile put - put of Oid that has not been fetched
# the '00' test stores Joe & Mary; Mary is a friend of Joe
# the '01' test gets Joe. Mary remains Oid. then puts both
#   01 also bodily deletes Joe & Mary from database so we can test whether
#   put really done

use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
use Class::AutoDB;
use autodbTestObject;
use autodbUtil;

use autodb_121;

my $autodb=new Class::AutoDB(database=>testdb); # open database

my @joes=$autodb->get(collection=>'Person',name=>'Joe');
is(scalar @joes,1,'get: Joe');
my $joe=$joes[0];
my $mary=$joe->friends->[0];
my $joe_oid=$autodb->oid($joe);
my $mary_oid=$autodb->oid($mary);
is(ref $mary,'Class::AutoDB::Oid','Mary still unthawed');

# bodily delete joe and mary from the database
my $dbh=$autodb->dbh;
$dbh->do(qq(DELETE FROM Person WHERE oid IN ($joe_oid,$mary_oid)));
$dbh->do(qq(DELETE FROM _AutoDB WHERE oid IN ($joe_oid,$mary_oid)));

# make sure it worked
my($count)=$dbh->selectrow_array
  (qq(SELECT COUNT(*) FROM Person WHERE oid IN ($joe_oid,$mary_oid)));
is($count,0,'delete from Person');
my($count)=$dbh->selectrow_array
  (qq(SELECT COUNT(*) FROM _AutoDB WHERE oid IN ($joe_oid,$mary_oid)));
is($count,0,'delete from _AutoDB');

# put objects back. should store new data for joe, but not mary
$autodb->put($joe,$mary);
my $rows=$dbh->selectall_arrayref
  (qq(SELECT oid,name,id FROM Person WHERE oid IN ($joe_oid,$mary_oid)));
cmp_deeply($rows,[[$joe_oid,'Joe',$joe->id]],'Joe (not Mary!) put back in Person');
my $rows=$dbh->selectall_arrayref
  (qq(SELECT oid,object FROM _AutoDB WHERE oid IN ($joe_oid,$mary_oid)));
cmp_deeply($rows,[[$joe_oid,re(qr/Joe/)]],'Joe (not Mary!) put back in _AutoDB');

eval{$mary->name};
like($@,qr/Trying to deserialize/,'Mary cannot be thawed as expected');

done_testing();
