use t::lib;
use strict;
use Carp;
use Test::More;
use autodbUtil;

use Class::AutoDB;
use Person;
my $autodb=new Class::AutoDB(database=>testdb); # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

# make some objects. not yet stored in database
my $joe=new Person(name=>'Joe',sex=>'M',id=>1);
my $mary=new Person(name=>'Mary',sex=>'F',id=>2);
my $bill=new Person(name=>'Bill',sex=>'M',id=>3);
ok_newoid($joe,"Joe's oid before put",qw(Person));
ok_newoid($mary,"Mary's oid before put",qw(Person));
ok_newoid($bill,"Bill's oid before put",qw(Person));
remember_oids($joe,$mary,$bill);

# set up friends lists. each is a list of Person objects
$joe->friends([$mary,$bill]);
$mary->friends([$joe,$bill]);
$bill->friends([$joe,$mary]);

# store objects in database
$autodb->put_objects;
ok_oldoid($joe,"Joe's oid after put",qw(Person));
ok_oldoid($mary,"Mary's oid after put",qw(Person));
ok_oldoid($bill,"Bill's oid after put",qw(Person));
ok_collections([$joe,$mary,$bill],"everyone Person after put",
	       {Person=>[[qw(name sex id)],[]]});

done_testing();
