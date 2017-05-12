# Regression test: put and get undefs

package Test;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name id undef_integer undef_string undef_float undef_object list);
%AUTODB=(collection=>'Test', 
	 keys=>qq(id integer, name string, 
                  undef_integer integer, undef_string string, undef_float float, 
                  undef_object object, list list(integer)));
Class::AutoClass::declare;

sub _init_self {
 my ($self,$class,$args)=@_;
 return unless $class eq __PACKAGE__;    # to prevent subclasses from re-running this
 $self->undef_integer(undef);
 $self->undef_string(undef);
 $self->undef_float(undef);
 $self->undef_object(undef);
 $self->list([undef,undef]);
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
# make and store some objects. undef set in _init_self
my @objects=map {new Test(name=>"test_undef $_",id=>id_next())} (0..2);
$autodb->put_objects;
my $dbh=$autodb->dbh;

test('integer');
test('string');
test('float');
# do list key here
# test using SQL
my($actual_count)=$dbh->selectrow_array
  (qq(SELECT COUNT(DISTINCT Test.oid) FROM Test,Test_list 
      WHERE Test.oid=Test_list.oid AND list IS NULL));
is($actual_count,scalar @objects,'count via SQL: list key');
# test using AutoDB
my $actual_count=$autodb->count(collection=>'Test',list=>undef);
is($actual_count,scalar @objects,'count via AutoDB: list key');
my @actual_objects=$autodb->get(collection=>'Test',list=>undef);
cmp_bag(\@actual_objects,\@objects,'objects via AutoDB: list key');

done_testing();

sub test {
  my($case)=@_;
  my $undef_case="undef_$case";
  # check the data using SQL
  my($actual_count)=$dbh->selectrow_array
    (qq(SELECT COUNT(DISTINCT Test.oid) FROM Test WHERE $undef_case IS NULL));
  is($actual_count,scalar @objects,"count via SQL: base key $undef_case");

  # check the data using AutoDB
  my $actual_count=$autodb->count(collection=>"Test",$undef_case=>undef);
  is($actual_count,scalar @objects,"count via AutoDB: base key $undef_case");
  my @actual_objects=$autodb->get(collection=>"Test",$undef_case=>undef);
  cmp_bag(\@actual_objects,\@objects,"objects via AutoDB: base key $undef_case");
}
