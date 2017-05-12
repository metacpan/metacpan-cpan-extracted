########################################
# this series tests handling of 'partially' deleted objects:
#  objects still exist in collections, but are NULL in _AutoDB
# not sure this can really happen, but...
# this script gets partially deleted object by running get, find, count queries
# objects created and stored by del.011.20.put
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbTestObject;

use Class::AutoDB;
use delUtil; use Person; use Student; use Place; use School; use Thing;

my $autodb=new Class::AutoDB(database=>testdb); # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

my($jane)=$autodb->get(collection=>'Person',name=>'Jane');
report_fail
  (ref $jane,'objects exist - probably have to rerun put script',__FILE__,__LINE__);

# test 'get' queries
my @places=$autodb->get(collection=>'Place');
is(scalar @places,0,'get Place');
my($mit)=$autodb->get(collection=>'Place',name=>'MIT');
ok(!defined($mit),'get MIT');

# test 'find/get' queries
my $cursor=$autodb->find(collection=>'Place');
my @places=$cursor->get;
is(scalar @places,0,'find/get Place');
my $cursor=$autodb->find(collection=>'Place',name=>'MIT');
my($mit)=$cursor->get;
ok(!defined($mit),'find/get MIT');

# test 'find/get_next' queries
my $cursor=$autodb->find(collection=>'Place');
my $place=$cursor->get_next;
ok(!defined($place),'find/get_next Place');
my $cursor=$autodb->find(collection=>'Place',name=>'MIT');
my $mit=$cursor->get_next;
ok(!defined($mit),'find/get_next MIT');

# test 'count' queries
my $count=$autodb->count(collection=>'Place');
is($count,0,'count Place');
my $count=$autodb->count(collection=>'Place',name=>'MIT');
is($count,0,'count MIT');

done_testing();
