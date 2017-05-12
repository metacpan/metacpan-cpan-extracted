# Regression test: programmatic registration of collections respecting alter=>0

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

# expects database to be setup by '00' test
my $autodb=new Class::AutoDB(database=>testdb,alter=>0);
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

# drop collection tables manually 'just in case'
my @correct_tables=qw(Register3 Register4 Register3_friends);
map {dbh->do(qq(DROP TABLE IF EXISTS $_))} @correct_tables;
is(scalar(actual_tables(@correct_tables)),0,'collection tables do not exist at start');

eval {
  $autodb->register
    (collections=>{Register3=>qq(name string, sex string, id integer, friends list(object)),
		   Register4=>'name'});};

ok($@,'register illegal as expected when alter=>0');
is(scalar(actual_tables(@correct_tables)),0,'collection tables do not exist at end');

done_testing();
