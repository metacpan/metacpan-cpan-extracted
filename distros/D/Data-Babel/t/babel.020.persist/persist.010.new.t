########################################
# starting with a fresh database, make new Babel
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

# open AutoDB database
my $autodb=new Class::AutoDB(database=>'test'); 
isa_ok($autodb,'Class::AutoDB','sanity test - $autodb');

# expect 'old' to return undef, because database is empty
my $name='test';
my $babel=old Data::Babel(name=>$name,autodb=>$autodb);
ok(!$babel,'old on empty database returned undef');

$babel=new Data::Babel
  (name=>$name,
   idtypes=>File::Spec->catfile(scriptpath,'handcrafted.idtype.ini'),
   masters=>File::Spec->catfile(scriptpath,'handcrafted.master.ini'),
   maptables=>File::Spec->catfile(scriptpath,'handcrafted.maptable.ini'));
isa_ok($babel,'Data::Babel','Babel created from config files');

# test simple attributes
is($babel->name,$name,'Babel attribute: name');
is($babel->id,"babel:$name",'Babel attribute: id');
is($babel->autodb,$autodb,'Babel attribute: autodb');
#is($babel->log,$log,'Babel attribute: log');
# test component-object attributes
check_handcrafted_idtypes($babel->idtypes,'mature','Babel attribute: idtypes');
check_handcrafted_masters($babel->masters,'mature','Babel attribute: masters');
check_handcrafted_maptables($babel->maptables,'mature','Babel attribute: maptables');

# test name2xxx & related methods
check_handcrafted_name2idtype($babel);
check_handcrafted_name2master($babel);
check_handcrafted_name2maptable($babel);
check_handcrafted_id2object($babel);
check_handcrafted_id2name($babel);

done_testing();
