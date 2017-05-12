use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
use Class::AutoDB;
use autodbUtil;

# test cursor methods documented in METHODS
use Person;
# create database so we can start fresh
my $autodb=new Class::AutoDB(database=>testdb,create=>1);
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

# make some objects and put 'em in the database, so we'll have something to query
my $joe=new Person(name=>'Joe',sex=>'M',id=>id_next());
my $mary=new Person(name=>'Mary',sex=>'F',id=>id_next());
my $bill=new Person(name=>'Bill',sex=>'M',id=>id_next());
$joe->friends([$mary,$bill]);
$mary->friends([$joe,$bill]);
$bill->friends([$joe,$mary]);
$autodb->put_objects;

########################################
# get
my $form=1;
my $cursor=$autodb->find(collection=>'Person',name=>'Joe',sex=>'M');
my @males=$cursor->get;
cmp_deeply(\@males,[$joe],'get form '.$form++);
my $cursor=$autodb->find(collection=>'Person',name=>'Joe',sex=>'M');
my $males=$cursor->get;
cmp_deeply($males,[$joe],'get form '.$form++);

########################################
# get_next
my $cursor=$autodb->find(collection=>'Person',name=>'Joe',sex=>'M');
my @males;
while(my $object=$cursor->get_next) {
  push(@males,$object);
}
cmp_deeply(\@males,[$joe],'get_next');

########################################
# count
my $cursor=$autodb->find(collection=>'Person',name=>'Joe',sex=>'M');
my $count=$cursor->count;
is($count,1,'count');

########################################
# reset

my $cursor=$autodb->find(collection=>'Person',name=>'Joe',sex=>'M');
my $object=$cursor->get_next;
$cursor->reset;
my $object=$cursor->get_next;
is($object,$joe,'reset');

done_testing();

