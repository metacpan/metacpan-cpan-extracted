package Example1; 

use strict;
use DBIx::DBObj; 

## Subclass DBIx::DBObj
our @ISA         = qw (DBIx::DBObj);  

## Always accept exceptions.
our $DBObjThrow  = 1;                 

## Database Table Name
our $DBObjTable  = "Example1";        

## Primary Key 
our @DBObjPKeys  = qw (Foo);          

## Enumerate our Tables Fields
our @DBObjFields = qw ( 
      Foo
      Bar
      Baz
);
1;
