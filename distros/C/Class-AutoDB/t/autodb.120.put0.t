# Regression test: put value of 0

package Test;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name id izero izero_list szero szero_list fzero fzero_list ozero ozero_list);
%AUTODB=(collection=>'Test', 
	 keys=>qq(id integer, name string, 
                  izero integer, izero_list list(integer),
                  szero string, szero_list list(string),
                  fzero float, fzero_list list(float),
                  ozero object, ozero_list list(object),));
Class::AutoClass::declare;

sub _init_self {
 my ($self,$class,$args)=@_;
 return unless $class eq __PACKAGE__;    # to prevent subclasses from re-running this
 $self->izero(0); $self->izero_list([0,0,0]);
 $self->szero(''); $self->szero_list(['','','']);
 $self->fzero(0.0); $self->fzero_list([0.0,0.0,0.0]);
 my $ozero={};			         # anything except persistent object
 $self->ozero($ozero); $self->ozero_list([$ozero,$ozero,$ozero]);
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
# make and store some objects. zero set in _init_self
my @objects=map {new Test(name=>"test_zero $_",id=>id_next())} (0..2);
$autodb->put_objects;
my $dbh=$autodb->dbh;

test('izero',0);
test('szero','');
test('fzero',0.0);
my $ozero={};			         # anything except persistent object
test('ozero',$ozero,undef);

done_testing();

sub test {
  my($case,$value)=splice(@_,0,2); # shift 1st two args
  my $sql_value=@_? shift: $value;
  my $sql_cond=defined $sql_value? ' = '.$dbh->quote($sql_value): ' IS NULL';
  my $case_list=$case.'_list';

  # check the data using SQL
  my $qvalue=$dbh->quote($value);
  my($actual_count)=$dbh->selectrow_array(qq(SELECT COUNT(*) FROM Test WHERE $case $sql_cond));
  is($actual_count,scalar @objects,"count via SQL: $case");
  my($actual_count)=$dbh->selectrow_array
    (qq(SELECT COUNT(DISTINCT Test.oid) FROM Test,Test_$case_list 
      WHERE Test.oid=Test_$case_list.oid AND $case_list $sql_cond));
  is($actual_count,scalar @objects,"count via SQL: $case_list");
  
  # check the data using AutoDB
  my $actual_count=$autodb->count(collection=>'Test',$case=>$value);
  is($actual_count,scalar @objects,"count via AutoDB: $case");
  my @actual_objects=$autodb->get(collection=>'Test',$case=>$value);
  cmp_bag(\@actual_objects,\@objects,"objects via AutoDB: $case");
  my $actual_count=$autodb->count(collection=>'Test',$case_list=>$value);
  is($actual_count,scalar @objects,"count via AutoDB: $case_list");
  my @actual_objects=$autodb->get(collection=>'Test',$case_list=>$value);
  cmp_bag(\@actual_objects,\@objects,"objects via AutoDB: $case_list");
}
