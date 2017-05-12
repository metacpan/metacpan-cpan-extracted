use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
use autodbUtil;

use Class::AutoDB;
use Person;
my $autodb=new Class::AutoDB(database=>testdb); # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

################################################################################
# this repeats the last test case of the previous test to make sure 'find' works
# without previous 'get'

# retrieve and process objects one-by-one
my @friends_strings;
my $cursor=$autodb->find(collection=>'Person'); 
my $i=0;
while (my $person=$cursor->get_next) {
  ok_oldoid($person,'person oid '.$i++,qw(Person));
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

