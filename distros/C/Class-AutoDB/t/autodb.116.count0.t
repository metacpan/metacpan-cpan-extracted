# Regression test: count of 0

package Person;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name sex id friends);
%AUTODB=(collection=>'Person',keys=>qq(name string));
Class::AutoClass::declare;

package main;
use t::lib;
use strict;
use Carp;
use Test::More;
use Class::AutoDB;
use autodbUtil;

my $autodb=new Class::AutoDB(database=>testdb,create=>1); # create database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

# regression test starts here
my @actual_objects=$autodb->get(collection=>'Person');
is(scalar @actual_objects,0,'get 0');
my $count=$autodb->count(collection=>'Person');
is($count,0,'count 0');
my $cursor=$autodb->find(collection=>'Person');
my $count=$cursor->count;
is($count,0,'cursor count 0');


my $jack=new Person(name=>'Jack');
$autodb->put($jack);
my @actual_objects=$autodb->get(collection=>'Person');
is(scalar @actual_objects,1,'get 1');
my $count=$autodb->count(collection=>'Person');
is($count,1,'count 1');
my $cursor=$autodb->find(collection=>'Person');
my $count=$cursor->count;
is($count,1,'cursor count 1');

done_testing();
