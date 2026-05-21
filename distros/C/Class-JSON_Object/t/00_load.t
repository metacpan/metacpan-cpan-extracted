#!perl -T

use v5.26;
use Test2::V0;

plan(2);

use ok 'Object::Pad';
use ok 'Class::JSON_Object';

diag( "Testing Class::JSON_Object $Class::JSON_Object::VERSION, ".
      "Object::Pad $Object::Pad::VERSION, Perl $], $^X" );
