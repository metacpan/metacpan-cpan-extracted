use t::lib;
use strict;
use Carp;
use Test::More;
use Class::AutoDB;
use autodbUtil;

# create AutoDB database & SDBM files
my $autodb=new Class::AutoDB(database=>testdb,create=>1); 
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
tie_oid('create');

# %AUTODB unset. no base classes. therefore non-persistent
use PctAUTODB_unset;
my $object=new PctAUTODB_unset(name=>'PctAUTODB_unset',id=>id());
my $oid=$autodb->oid($object);	# nonperistent objects don't have oids
is($oid,undef,'PctAUTODB_unset oid');
eval {$autodb->put($object)};	# illegal - nonperistent objects can't be put
ok($@,'PctAUTODB_unset put');
my $count0=count_autodb();	# number of AutoDB objects before put_objects
$autodb->put_objects;		# shouldn't put anything
my $count1=count_autodb();	# number of AutoDB objects after put_objects
is($count1,$count0,'PctAUTODB_unset put_objects');

# %AUTODB unset. persistent base class
use Bottom; use Top;
my $bottom=new Bottom(name=>'bottom',id=>id_next());
my $top=new Top(name=>'top',id=>id_next());

my $test=new autodbTestObject(put_type=>'put');
$test->test_put
  (labelprefix=>'put:',
   label=>sub {my $test=shift; my $obj=$test->current_object; $obj && $obj->name;},
   objects=>[$bottom,$top],
   correct_colls=>['Person'],coll2basekeys=>{Person=>[qw(name id)]},correct_diffs=>1);

done_testing();

sub count_autodb {
  my($count)=dbh->selectrow_array(qq(SELECT COUNT(oid) FROM _AutoDB));
  $count;
}
