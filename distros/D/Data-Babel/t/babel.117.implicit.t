########################################
# implicit masters bug
# implicit master created in application and passed into Babel constructor not processed 
# by make_implicit_masters and thus not set up properly
########################################
use t::lib;
use t::utilBabel;
use Carp;
use Test::More;
use Test::Deep;
use Data::Babel;
use strict;

my $num_idtypes=5;
my $num_ids=2;
my $here;			# tells where Masters created here or in Babel

my $autodb=new Class::AutoDB(database=>'test',create=>1); 
isa_ok($autodb,'Class::AutoDB','sanity test - $autodb');
my $dbh=$autodb->dbh;
for $here (0,1) {
  cleanup_db($autodb);		# cleanup database from previous test
  # make component objects and Babel.
  my @idtypes=
    map {new Data::Babel::IdType(name=>"type_$_",sql_type=>'VARCHAR(255)')} (0..($num_idtypes-1));
  my @masters=$here?
    map {new Data::Babel::Master 
	   (name=>"type_${_}_master",idtype=>$idtypes[$_],explicit=>0)} (0..$#idtypes): ();
  my @maptables=map {new Data::Babel::MapTable
		       (name=>"maptable_$_",idtypes=>[@idtypes[$_,$_+1]])} (0..($#idtypes-1));
  my $babel=new Data::Babel
    (name=>'test',autodb=>$autodb,idtypes=>\@idtypes,masters=>\@masters,maptables=>\@maptables);
  isa_ok($babel,'Data::Babel','sanity test - $babel');
  # setup the database. all maptables have same data. masters, too, except for undefs
  for (my $i=0; $i<@maptables; $i++) {
    my $maptable="maptable_$i";
    my @data=((map {["a_$_","a_$_"]} (0..($num_ids-1))),["b_$i","b_$i"]);
    load_maptable($babel,$maptable,@data);
  }
  $babel->load_implicit_masters;

  # master 0 has a_0, a_1, b_0
  # for $i=1..3, master $i has  a_0, a_1, b_$i-1, b_$i
  # master 4 has a_0, a_1, b_3
  test_master(0,'b_0');
  test_master(1,qw(b_0 b_1));
  test_master(2,qw(b_1 b_2));
  test_master(3,qw(b_2 b_3));
  test_master(4,'b_3');
}
done_testing();

sub test_master {
  my $i=shift;
  my @as=map {"a_$_"} (0..($num_ids-1));
  my @bs=@_? @_: map {"b_$_"} ($i-1,$i);
  my @correct=(@as,@bs);
  my $sql=qq(SELECT type_$i FROM type_${i}_master);
  my $actual=$dbh->selectcol_arrayref($sql) ||
    confess "SELECT from master $i failed: ".$dbh->errstr;
  cmp_bag($actual,\@correct,"master $i created ".($here? 'here': 'in Babel'));
}

