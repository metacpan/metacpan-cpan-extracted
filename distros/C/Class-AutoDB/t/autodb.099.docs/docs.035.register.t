use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
use Class::AutoDB;
use autodbUtil;

my $autodb=new Class::AutoDB(database=>testdb); 
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

# register 2 collections without class
$autodb->register(collections=>{Person=>qq(name string, sex string, id integer),
				HasName=>'name'});
my @actual_tables=actual_tables(qw(Person HasName));
cmp_bag(\@actual_tables,[qw(Person HasName)],'collection tables exist after register');

# associate Person class with collections
use Person;
$autodb->register(class=>'Person', collections=>'Person, HasName');
test_single('Person',qw(Person HasName));

done_testing();
