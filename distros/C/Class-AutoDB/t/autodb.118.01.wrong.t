# Regression test: get values of wrong type stored by previous test
use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
use Class::AutoDB;
use autodbUtil;

use autodb_118;

my $autodb=new Class::AutoDB(database=>testdb); # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
my($p)=$autodb->get(collection=>'HasName');
is($p->name,'persistent','persistent object');

# regression test starts here
# make and store some objects
my $r={};			# any ref will do
# my $p=new Persistent(name=>'persistent',id=>id_next());
id_next();			# bump id since we're not making $p
my $np=new NonPersistent(name=>'nonpersistent',id=>id_next());
my @objects=
  (new Test(name=>"test_wrong string values",id=>id_next(),
	    iwrong=>'string', iwrong_list=>[qw(string string string)],
	    swrong=>'string', swrong_list=>[qw(string string string)],
	    fwrong=>'string', fwrong_list=>[qw(string string string)],
	    owrong=>'string', owrong_list=>[qw(string string string)],),
   new Test(name=>"test_wrong integer values",id=>id_next(),
	    iwrong=>123, iwrong_list=>[qw(123 123 123)],
	    swrong=>123, swrong_list=>[qw(123 123 123)],
	    fwrong=>123, fwrong_list=>[qw(123 123 123)],
	    owrong=>123, owrong_list=>[qw(123 123 123)],),
   new Test(name=>"test_wrong float values",id=>id_next(),
	    iwrong=>123.456, iwrong_list=>[qw(123.456 123.456 123.456)],
	    swrong=>123.456, swrong_list=>[qw(123.456 123.456 123.456)],
	    fwrong=>123.456, fwrong_list=>[qw(123.456 123.456 123.456)],
	    owrong=>123.456, owrong_list=>[qw(123.456 123.456 123.456)],),
   new Test(name=>"test_wrong ref values",id=>id_next(),
	    iwrong=>$r, iwrong_list=>[$r,$r,$r],
	    swrong=>$r, swrong_list=>[$r,$r,$r],
	    fwrong=>$r, fwrong_list=>[$r,$r,$r],
	    owrong=>$r, owrong_list=>[$r,$r,$r],),
   new Test(name=>"test_wrong persistent object values",id=>id_next(),
	    iwrong=>$p, iwrong_list=>[$p,$p,$p],
	    swrong=>$p, swrong_list=>[$p,$p,$p],
	    fwrong=>$p, fwrong_list=>[$p,$p,$p],
	    owrong=>$p, owrong_list=>[$p,$p,$p],),
  new Test(name=>"test_wrong nonpersistent object values",id=>id_next(),
	    iwrong=>$np, iwrong_list=>[$np,$np,$np],
	    swrong=>$np, swrong_list=>[$np,$np,$np],
	    fwrong=>$np, fwrong_list=>[$np,$np,$np],
	    owrong=>$np, owrong_list=>[$np,$np,$np],),
  );

my @basekeys=qw(iwrong swrong fwrong owrong);
# my @baseops=qw(= LIKE = =);
my @baseops=qw(= = = =);
my $p_oid=$p->oid;

for my $case (qw(string integer float ref),'persistent object','nonpersistent object') {
  test($case);
}
done_testing();

sub test {
  my($case)=@_;
  my $name="test_wrong $case values";
  my @basevals;			# must be in basekeys order
  if ($case eq 'string') {
    @basevals=(0,'string',0,undef);
  } elsif ($case eq 'integer') {
    @basevals=(123,123,123,undef);
  } elsif ($case eq 'float') {
    @basevals=(123,123.456,123.456,undef);
  } elsif ($case eq 'ref') {
    @basevals=(0,$r,0,undef);
  } elsif ($case eq 'persistent object') {
    @basevals=(0,$p,0,$p);
  } elsif ($case eq 'nonpersistent object') {
    @basevals=(0,$np,0,undef);
  }

  # test using AutoDB
  my @query=(name=>$name,map {$basekeys[$_]=>$basevals[$_]} (0..$#basekeys));
#   my $actual_count=$autodb->count(collection=>'Test',@query);
#   is($actual_count,1,"count via AutoDB: $case base");
  for(my $i=0; $i<@basekeys; $i++) {
    my $basekey=$basekeys[$i];
    my $listkey=$basekey.'_list';
    push(@query,$listkey=>$basevals[$i]);
  }
  my %query=@query;
  # string keys have unusable values in ref cases since they are stringifed refs from 'put' test
  delete $query{swrong} if $query{swrong}=~/HASH/;
  delete $query{swrong_list} if $query{swrong_list}=~/HASH/;
  my $actual_count=$autodb->count(collection=>'Test',%query);
  is($actual_count,1,"count via AutoDB: $case");
  my($actual_object)=$autodb->get(collection=>'Test',%query);
  my($correct_object)=grep {$_->name eq $name} @objects;
  cmp_deeply($actual_object,$correct_object,"contents via AutoDB: $case");
}
