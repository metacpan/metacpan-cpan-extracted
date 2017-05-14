#!/usr/local/bin/perl

# Tests for interaction of get_set with new_hash_init

package Person;

use Class::MakeMethods::Emulator::MethodMaker
  new_hash_init =>      'new' ,
  get_set       => [ -java   => 'Status',
                     -eiffel => 'size', 'name', ]
  ;

package main;

my $p = Person->new(name   =>'Homer',
                    size   =>'54', 
                    Status =>'Comical Moron');

use lib qw ( ./t );
use Test;

TEST { 1 };
TEST { $p->name eq 'Homer'          };
TEST { $p->size == 54               };
TEST { $p->getStatus eq 'Comical Moron' };

exit 0;

