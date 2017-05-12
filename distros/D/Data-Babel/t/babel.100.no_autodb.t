########################################
# regression test for calling 'new' before setting autodb
########################################
use t::lib;
use t::utilBabel;
use Test::More;
use Test::Deep;
use Class::AutoDB;
use Data::Babel;
use Data::Babel::IdType;
use Data::Babel::Master;
use Data::Babel::MapTable;
use strict;

my $idtype=eval {new Data::Babel::IdType name=>'idtype_000'};
is($@,'','new IdType');
my $master=eval {new Data::Babel::Master name=>'idtype_000_master',idtype=>$idtype};
is($@,'','new Master');
my $maptable=eval {new Data::Babel::MapTable name=>'maptable_000',idtypes=>[$idtype]};
is($@,'','new MapTable');
my $babel=eval {new Data::Babel name=>'test'};
is($@,'','new Babel without components');
my $babel=eval {
  new Data::Babel name=>'test',idtypes=>[$idtype],masters=>[$master],maptables=>[$maptable]};
is($@,'','new Babel with components');

# now create AutoDB database and for sanity sake, make sure autodb can't fetch the objects
my $autodb=new Class::AutoDB(database=>'test',create=>1); 
isa_ok($autodb,'Class::AutoDB','sanity test - $autodb');
cleanup_db($autodb);		# cleanup database from previous test

my($idtype_from_db)=$autodb->get(collection=>'IdType',name=>'idtype_000');
ok(!$idtype_from_db,'idtype not in database before setting autodb');
my($master_from_db)=$autodb->get(collection=>'Master',name=>'idtype_000_master');
ok(!$master_from_db,'master not in database before setting autodb');
my($maptable_from_db)=$autodb->get(collection=>'MapTable',name=>'maptable_000');
ok(!$maptable_from_db,'maptable not in database before setting autodb');
my($babel_from_db)=$autodb->get(collection=>'Babel',name=>'test');
ok(!$babel_from_db,'babel not in database before setting autodb');

# set autodb in babel. remake the babel, and make sure everything gets put
my $babel=eval {
  new Data::Babel 
    name=>'test',autodb=>$autodb,idtypes=>[$idtype],masters=>[$master],maptables=>[$maptable]};
is($@,'','new Babel with components after setting autodb');

my($idtype_from_db)=$autodb->get(collection=>'IdType',name=>'idtype_000');
is($idtype_from_db,$idtype,'idtype in database after setting autodb');
my($master_from_db)=$autodb->get(collection=>'Master',name=>'idtype_000_master');
is($master_from_db,$master,'master in database after setting autodb');
my($maptable_from_db)=$autodb->get(collection=>'MapTable',name=>'maptable_000');
is($maptable_from_db,$maptable,'maptable in database after setting autodb');
my($babel_from_db)=$autodb->get(collection=>'Babel',name=>'test');
is($babel_from_db,$babel,'babel in database after setting autodb');



done_testing();
