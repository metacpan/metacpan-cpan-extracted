# Regression test: runtime use. 010, 011 test put & get
# all classes use the same collection. 
# the 'put' test stores objects of different classes in the collection 
# the 'get' test gets objects from the collection w/o first using their classes
#   some cases should be okay; others should fail 

use t::lib;
use strict;
use Carp;
use Test::More;
use Class::AutoDB;
use autodbTestObject;
use autodbUtil;
                    # do NOT use the 'RunTimeUse' classes. that's the whole point!
use CompileTimeUse; # use RunTimeUseOk; use RunTimeUseBad;

my $autodb=new Class::AutoDB(database=>testdb); # open database

my($ct)=eval{$autodb->get(collection=>'HasName',name=>'compile time use');};
is($@,'','compile time use');
my($rt_ok)=eval{$autodb->get(collection=>'HasName',name=>'runtime use okay');};
is($@,'','runtime use ok');
my($rt_bad)=eval{$autodb->get(collection=>'HasName',name=>'runtime use not okay');};
like($@,qr/Can't locate RunTimeUseNotOk/,'runtime use not okay failed as expected');

done_testing();
