# Regression test: programmatic registration of collections

package Register;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name sex id friends);
%AUTODB=1;
Class::AutoClass::declare;

package main;
use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
use Class::AutoDB;
use autodbUtil;

# create database and SDBM files so we start clean
my $autodb=new Class::AutoDB(database=>testdb,create=>1);
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
tie_oid('create');

# drop collection tables manually 'just in case'
my @correct_tables=qw(Register1 Register2 Register1_friends);
map {dbh->do(qq(DROP TABLE IF EXISTS $_))} @correct_tables;
is(scalar(actual_tables(@correct_tables)),0,'collection tables do not exist at start');

$autodb->register
  (collections=>{Register1=>qq(name string, sex string, id integer, friends list(object)),
		 Register2=>'name'});

my @actual_tables=actual_tables(@correct_tables);
cmp_bag(\@actual_tables,\@correct_tables,'collection tables exist after register');

$autodb->register(class=>'Register',collections=>'Register1, Register2');

my $joe=new Register name=>'Joe',sex=>'F',id=>id_next();
my $moe=new Register name=>'Moe',sex=>'M',id=>id_next();
$joe->friends([$joe,$moe]);
$moe->friends([$moe,$joe]);
ok_newoids([$joe,$moe],'Register oids before put',@correct_tables);
$autodb->put($joe,$moe);
remember_oids($joe,$moe);

# can't use ok_oldoid on list tables, since counts not always 1
ok_oldoids([$joe,$moe],'Register oids after put',qw(Register1 Register2));
ok_collections([$joe,$moe],'Register collections after put',
	       {Register1=>[[qw(name id sex)],[qw(friends)]],
		Register2=>[[qw(name)],[]]});

done_testing();

