use t::lib;
use strict;
use Carp;
use Test::More;
use Class::AutoDB;
use autodbUtil;

use Person;
my $autodb=new Class::AutoDB(database=>testdb); # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

# make some objects and put them. call 'em all $joe since that's what's in docs
my @joes;
my $joe=new Person(name=>'Joe',sex=>'M',id=>id_next());
ok_newoid($joe,"Joe's oid before \$joe->put",qw(Person));
$joe->put;               # store one object (deprecated form)
remember_oids($joe);
ok_oldoid($joe,"Joe's oid after \$joe->put",qw(Person));
ok_collection($joe,"Joe's Person after \$joe->put",'Person',[qw(name sex id)]);
push(@joes,$joe);

my $joe=new Person(name=>'Joe',sex=>'M',id=>id_next());
ok_newoid($joe,"Joe's oid before \$autodb->put(\$joe)",qw(Person));
$autodb->put($joe);      # store one object (preferred form)
remember_oids($joe);
ok_oldoid($joe,"Joe's oid after \$autodb->put(\$joe)",qw(Person));
ok_collection($joe,"Joe's Person after \$autodb->put(\$joe)",'Person',[qw(name sex id)]);
push(@joes,$joe);

my $joe=new Person(name=>'Joe',sex=>'M',id=>id_next());
ok_newoid($joe,"Joe's oid before \$autodb->put_objects",qw(Person));
$autodb->put_objects;    # store all objects
remember_oids($joe);
ok_oldoid($joe,"Joe's oid after \$autodb->put_objects",qw(Person));
ok_collection($joe,"Joe's Person after \$autodb->put_objects",'Person',[qw(name sex id)]);
push(@joes,$joe);

ok_oldoids(\@joes,"all oids after \$autodb->put_objects",qw(Person));
ok_collections(\@joes,"all Person after \$autodb->put_objects",
	       {Person=>[[qw(name sex id)],[]]});

done_testing();

