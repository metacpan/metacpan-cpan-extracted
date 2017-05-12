# Regression test: when invoking a UNIVERSAL method (isa, can, DOES, VERSION) on Oid or
# OidDelelted, the method was not redispatched to the real class

package main;
use t::lib;
use strict;
use Carp;
use Test::More;
use Class::AutoDB;
use autodbUtil;

use autodb_132;

my $autodb=new Class::AutoDB(database=>testdb,create=>1); # create database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
my $joe=new Person(-name=>'Joe',-sex=>'male');
my $mary=new Person(-name=>'Mary',-sex=>'female');
my $bill=new Person(-name=>'Bill',-sex=>'male');
# Set up friends lists
$joe->friends([$mary,$bill]);
$mary->friends([$joe,$bill]);
$bill->friends([$joe,$mary]);
$autodb->put_objects;           # store objects in database

ok(1,'end of test');

done_testing();
