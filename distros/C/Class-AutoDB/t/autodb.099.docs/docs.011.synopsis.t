use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
use autodbUtil;

########################################
# code that uses persistent class - retrieve existing objects
#
use Class::AutoDB;
use Person;
my $autodb=new Class::AutoDB(database=>testdb); # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

# retrieve list of objects
my @persons=$autodb->get(-collection=>'Person');	  # everyone
my @males=$autodb->get(-collection=>'Person',sex=>'M'); # just the boys  

is(scalar @persons,3,'number of persons');
ok_oldoids(\@persons,'persons oids',qw(Person));
my @names=map {$_->name} @persons;
cmp_deeply(\@names,bag(qw(Joe Mary Bill)),"persons names");

is(scalar @males,2,'number of males');
ok_oldoids(\@males,'males oids',qw(Person));
my @names=map {$_->name} @males;
cmp_deeply(\@names,bag(qw(Joe Bill)),"males names");

cmp_deeply(\@males,subbagof(@persons),'all males are persons');

my($joe)=grep {$_->name eq 'Joe'} @persons;
my($mary)=grep {$_->name eq 'Mary'} @persons;
my($bill)=grep {$_->name eq 'Bill'} @persons;
cmp_deeply($joe->friends,bag($mary,$bill),"Joe's friends");
cmp_deeply($mary->friends,bag($joe,$bill),"Mary's friends");
cmp_deeply($bill->friends,bag($mary,$joe),"Bill's friends");

# do something with the retrieved objects, for example, print friends lists
my @friends_strings;
for my $person (@persons) {
  my @friend_names=map {$_->name} @{$person->friends};
#  print $person->name,"'s friends are @friend_names\n";
  push(@friends_strings,$person->name."'s friends are @friend_names\n");
}
cmp_deeply(\@friends_strings,
	   bag("Joe's friends are Mary Bill\n",
	       "Mary's friends are Joe Bill\n",
	       "Bill's friends are Joe Mary\n"),'friends names');
 
# retrieve and process objects one-by-one
my @friends_strings;
my $cursor=$autodb->find(collection=>'Person'); 
while (my $person=$cursor->get_next) {
  # do what you want with $person, for example, print friends list
  my @friend_names=map {$_->name} @{$person->friends};
#  print $person->name,"'s friends are @friend_names\n";
  push(@friends_strings,$person->name."'s friends are @friend_names\n");
}
cmp_deeply(\@friends_strings,
	   bag("Joe's friends are Mary Bill\n",
	       "Mary's friends are Joe Bill\n",
	       "Bill's friends are Joe Mary\n"),'friends names one-by-one');

done_testing();

