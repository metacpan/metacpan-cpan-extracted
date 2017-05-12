########################################
# fetch old Babel, then recreate it. 
# make sure the recreation works and the object frames are reused
########################################
use t::lib;
use t::utilBabel;
use Test::More;
use Test::Deep;
use File::Spec;
use Scalar::Util qw(refaddr);
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
isa_ok($babel,'Data::Babel','sanity test - $babel');

# hang onto existing objects' oids
my @old_objects=($babel,@{$babel->idtypes},@{$babel->masters},@{$babel->maptables});
my %id2refaddr=map {$_->id=>refaddr($_)} @old_objects;
my %id2oid=map {$_->id=>$autodb->oid($_)} @old_objects;
# and zero out the old objects -- very naughty!
map {%$_=()} @old_objects;

# remake Babel
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

# finally, check reuse of objects
my @new_objects=($babel,@{$babel->idtypes},@{$babel->masters},@{$babel->maptables});
my $ok=1;
for my $object (@new_objects) {
  my $id=$object->id;
  $ok&=report_fail($autodb->oid($object)==$id2oid{$id},"oid object $id");
  $ok&=report_fail(refaddr($object)==$id2refaddr{$id},"refaddr object $id");
  last unless $ok;
}
report_pass($ok,'object frames reused');

done_testing();
