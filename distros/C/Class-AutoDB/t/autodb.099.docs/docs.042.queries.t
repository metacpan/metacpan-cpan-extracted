use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
use Class::AutoDB;
use autodbUtil;

# test queries documented in METHODS
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
my @males=$autodb->get(collection=>'Person',name=>'Joe',sex=>'M');
cmp_deeply(\@males,[$joe],'get form '.$form++);
my $males=$autodb->get(collection=>'Person',name=>'Joe',sex=>'M');
cmp_deeply($males,[$joe],'get form '.$form++);
my @males=$autodb->get(collection=>'Person',query=>{name=>'Joe',sex=>'M'});
cmp_deeply(\@males,[$joe],'get form '.$form++);
my $males=$autodb->get(collection=>'Person',query=>{name=>'Joe',sex=>'M'});
cmp_deeply($males,[$joe],'get form '.$form++);

my @all_objects=$autodb->get;
cmp_deeply(\@all_objects,bag($joe,$mary,$bill),'get form '.$form++);
my $all_objects=$autodb->get;
cmp_deeply($all_objects,bag($joe,$mary,$bill),'get form '.$form++);
my @joe_bill=$autodb->get(sql=>qq(SELECT oid FROM Person WHERE name='Joe' OR name='Bill'));
cmp_deeply(\@joe_bill,bag($joe,$bill),'get form '.$form++);
my $joe_bill=$autodb->get(sql=>qq(SELECT oid FROM Person WHERE name='Joe' OR name='Bill'));
cmp_deeply($joe_bill,bag($joe,$bill),'get form '.$form++);

########################################
# find
my $form=1;
my $cursor=$autodb->find(collection=>'Person',name=>'Joe',sex=>'M');
my $males=$cursor->get;
cmp_deeply($males,[$joe],'find form '.$form++);
my $cursor=$autodb->find(collection=>'Person',query=>{name=>'Joe',sex=>'M'});
my $males=$cursor->get;
cmp_deeply($males,[$joe],'find form '.$form++);

my $cursor=$autodb->find;
my $all_objects=$cursor->get;
cmp_deeply($all_objects,bag($joe,$mary,$bill),'find form '.$form++);
my $cursor=$autodb->find(sql=>qq(SELECT oid FROM Person WHERE name='Joe' OR name='Bill'));
my $joe_bill=$cursor->get;
cmp_deeply($joe_bill,bag($joe,$bill),'find form '.$form++);

########################################
# count
my $form=1;
my $count=$autodb->count(collection=>'Person',name=>'Joe',sex=>'M');
is($count,1,'count form '.$form++);
my $count=$autodb->count(collection=>'Person',query=>{name=>'Joe',sex=>'M'});
is($count,1,'count form '.$form++);

my $count=$autodb->count;
cmp_deeply($count,3,'count form '.$form++);
my $count=$autodb->count(sql=>qq(SELECT oid FROM Person WHERE name='Joe' OR name='Bill'));
cmp_deeply($count,2,'count form '.$form++);

########################################
# oid
my $object=$joe;
my $oid=$autodb->oid($object);
ok($oid>1,'oid');

done_testing();

