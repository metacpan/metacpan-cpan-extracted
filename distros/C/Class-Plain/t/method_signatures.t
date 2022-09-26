#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

BEGIN {
   $] >= 5.026000 or plan skip_all => "No parse_subsignature()";
}

use feature 'signatures';

use Class::Plain;

{
    
  class MyClassSignature {
    field foo : rw;
    field bar : rw;
    
    method set_fields ($foo, $bar = 3, @) {
      
      $self->{foo} = $foo;
      $self->{bar} = $bar;
    }
    
    my $outside = 10;
    
    method anon {
      return method ($foo, $bar = 7, @) {
        
        $self->{foo} = $foo;
        $self->{bar} = $bar;
        
        return $outside;
      };
    }
  }

  my $object = MyClassSignature->new;

  $object->set_fields(4);
  is($object->foo, 4);
  is($object->bar, 3);

  my $anon_ret = $object->anon->($object, 5);
  is($anon_ret, 10);
  is($object->foo, 5);
  is($object->bar, 7);
}

done_testing;
