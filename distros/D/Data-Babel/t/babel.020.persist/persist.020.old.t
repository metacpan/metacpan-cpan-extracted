########################################
# fetch old Babel from database
########################################
use t::lib;
use t::utilBabel;
use Test::More;
use Test::Deep;
use File::Spec;
use Class::AutoDB;
use Data::Babel;
use Data::Babel::Config;
use strict;

# create AutoDB database
my $autodb=new Class::AutoDB(database=>'test'); 
isa_ok($autodb,'Class::AutoDB','sanity test - $autodb');

# expect 'old' to return the babel
my $name='test';
my $babel=old Data::Babel(name=>$name,autodb=>$autodb);
ok($babel,'old');

# now test it to make sure it came back correctly
isa_ok($babel,'Data::Babel','old returned Data::Babel object');

# test attributes
is($babel->name,$name,'Babel attribute: name');
is($babel->id,"babel:$name",'Babel attribute: id');
# is($babel->idtypes,$idtypes,'Babel attribute: idtypes');
# is($babel->masters,$masters,'Babel attribute: masters');
# is($babel->maptables,$maptables,'Babel attribute: maptables');
is($babel->autodb,$autodb,'Babel attribute: autodb');
#is($babel->log,$log,'Babel attribute: log');
# test component-object attributes
check_handcrafted_idtypes($babel->idtypes,'mature','Babel attribute: idtypes');
check_handcrafted_masters($babel->masters,'mature','Babel attribute: masters');
check_handcrafted_maptables($babel->maptables,'mature','Babel attribute: maptables');

# check_schema: should be true.
my @errstrs=$babel->check_schema;
ok(!@errstrs,'check_schema array context');
ok(scalar($babel->check_schema),'check_schema boolean context');

# test name2xxx & related methods
check_handcrafted_name2idtype($babel);
check_handcrafted_name2master($babel);
check_handcrafted_name2maptable($babel);
check_handcrafted_id2object($babel);
check_handcrafted_id2name($babel);

done_testing();
