#!perl -w

use strict;
use warnings;
use lib 'lib';
use Carp;

use Benchmark;
use Test::More tests => 9;
my $t1 = new Benchmark;

package MyClass;

use Class::Builder {
    'name' => {
        string => 'Miliao',
      },
    'database' => {
        classdata => 'uper bound',
     },
     'username' => {
        classdata => 'Me'
      },
      died => {boolean => 1},
  };

1;

package ChildClass;

use base 'MyClass';

use Class::Builder {
    'database' => {
        classdata => 'other bound'
      }
  };

1;

package SystemUser;
  use Class::Builder {
    '-methods' => {
        initializer => ['init1', 'init2'],
      },
    name => {string => 'bethoven'},
  };

sub init1{shift->{name} = 'chopin';}
sub init2{shift->{name} = 'Walsh';}

1;

package main;

my $class = new MyClass;
ok($class->name eq 'Miliao', "assign default values");


ok($class->database eq 'uper bound', "assign default classdata.");

my $class3 = new MyClass {name => 'not tail'};
ok($class3->name eq 'not tail', "hash init assignment");
$class->database('changed');
ok($class3->database eq 'changed', "change class data");

ok($class->died, "boolean data");

$class->name = 'Blah';
ok($class->name eq 'Blah', "lvalue function assignment");

my $class2 = new ChildClass;
ok($class2->database eq 'other bound', "class data overriden");
ok($class2->username eq 'Me', "class data inheritage");

my $user = new SystemUser( {name => 'mozart'} );
ok($user->name eq 'Walsh', "initializer");

system 'perl t/t1';
system 'perl t/t2';

my $t2 = new Benchmark;
print "Total Time Spend: ", timestr(timediff($t2, $t1)), "\n";