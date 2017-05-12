# Regression test: futile put - put of Oid that has not been fetched
# the '00' test stores Joe & Mary; Mary is a friend of Joe
# the '01' test gets Joe. Mary remains Oid. then puts both
#   01 also bodily deletes Joe & Mary from database so we can test whether
#   put really done

use t::lib;
use strict;
use Carp;
use Test::More;
use Class::AutoDB;
use autodbTestObject;
use autodbUtil;

use autodb_121;

# create AutoDB database & SDBM files
my $autodb=new Class::AutoDB(database=>testdb,create=>1); 
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
tie_oid('create');

# make the objects. 
my($joe,$mary)=(new Person(name=>'Joe',id=>id_next()),new Person(name=>'Mary',id=>id_next()));
# connect friends. 
$joe->friends([$mary]);
$mary->friends([$joe]);

my %test_args=
  (class2colls=>{Person=>[qw(Person)]},
   coll2keys=>{Person=>[[qw(id name)],[]]},
   correct_diffs=>1,
   label=>sub {my $object=$_[0]->current_object; $object->name if $object;});

my $test=new autodbTestObject(%test_args);
$test->test_put(labelprefix=>'put:',objects=>[$joe,$mary]);

done_testing();
