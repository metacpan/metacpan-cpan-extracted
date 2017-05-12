########################################
# update objects stored by previous test
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
use autodbTestObject;

use Class::AutoDB;
use putgetUtil; use Person; use Student; use Place; use School; use Thing;

my $autodb=new Class::AutoDB(database=>testdb); # open database

# retrieve Persons
my @persons=$autodb->get(collection=>'Person');

# grab Jane, Mike - not yet in anyone's friends lists.
my($jane)=grep {$_->name eq 'Jane'} @persons;
my($mike)=grep {$_->name eq 'Mike'} @persons;
my($barb)=grep {$_->name eq 'Barb'} @persons;
# make some new hobbies
id_restore();			# restore id to where we left off
my $cycling=new Thing(desc=>'cycling',id=>id_next());
my $baking=new Thing(desc=>'baking',id=>id_next());
# make a new school
my $osu=new School
  (name=>'OSU',address=>'Columbus',subjects=>[qw(Medicine Football)],id=>id_next());

# update everyone's friends and hobbies
for my $person (@persons) {
  push(@{$person->friends},$jane,$mike);
  push(@{$person->hobbies},$cycling,$baking);
}
# switch Mike's school
$mike->school($osu);

# %test_args, exported by putgetUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args);
$test->old_counts;		# remember table counts before update
$autodb->put_objects;
remember_oids($cycling,$baking,$osu);
my $actual_diffs=$test->diff_counts;
my $correct_diffs={_AutoDB=>3,Person_friends=>2*@persons,HasName=>1,Place=>1};
cmp_deeply($actual_diffs,$correct_diffs,'table counts');

done_testing();
