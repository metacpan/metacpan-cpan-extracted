# Regression test: get multiple terms from base - illegal

package Test;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name id multi);
%AUTODB=(collection=>'Test',keys=>qq(id integer, name string, multi string));
Class::AutoClass::declare;

sub _init_self {
 my ($self,$class,$args)=@_;
 return unless $class eq __PACKAGE__;    # to prevent subclasses from re-running this
 my $i=$args->i;
 $self->multi($i);
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
# attempt query. should be illegal
my $actual_count=eval {$autodb->count(collection=>'Test',multi=>1,multi=>2)};
like($@,qr/repeated/,'count illegal as expected');
my @actual_objects=eval {$autodb->get(collection=>'Test',multi=>1,multi=>2)};
like($@,qr/repeated/,'get illegal as expected');
my $cursor=eval {$autodb->find(collection=>'Test',multi=>1,multi=>2)};
like($@,qr/repeated/,'find illegal as expected');

done_testing();
