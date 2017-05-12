# Regression test: get from list that has duplicates

package Test;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name id list);
%AUTODB=(collection=>'Test', 
	 keys=>qq(id integer, name string, list list(integer)));
Class::AutoClass::declare;

sub _init_self {
 my ($self,$class,$args)=@_;
 return unless $class eq __PACKAGE__;    # to prevent subclasses from re-running this
 $self->list([1,1,1]);
}

package main;
use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
use Class::AutoDB;
use autodbUtil;

my $autodb=new Class::AutoDB(database=>testdb,create=>1); # create database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

# regression test starts here
# make and store some objects. dups set in _init_self
my @objects=map {new Test(name=>"test_dups $_",id=>id_next())} (0..2);
$autodb->put_objects;

# check the data using SQL
my $dbh=$autodb->dbh;
my($actual_count)=$dbh->selectrow_array
  (qq(SELECT COUNT(DISTINCT Test.oid) FROM Test,Test_list 
      WHERE Test.oid=Test_list.oid AND list=1));
is($actual_count,scalar @objects,'count via SQL');

# check the data using AutoDB
my $actual_count=$autodb->count(collection=>'Test',list=>1);
is($actual_count,scalar @objects,'count via AutoDB');
my @actual_objects=$autodb->get(collection=>'Test',list=>1);
cmp_bag(\@actual_objects,\@objects,'objects via AutoDB');

done_testing();
