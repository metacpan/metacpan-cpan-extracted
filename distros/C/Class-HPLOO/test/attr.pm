#!/usr/bin/perl

use Class::HPLOO ;

class Foo {
  
  attr( name , int age , float size , array list , ref array &mytype special , sub call) ;

  sub mytype {
    my $val = shift ;
    $val =~ s/(.)\1+/$1/gs ;
    return $val ;
  }
  
  sub call {
    return "CAL<". ref($this) ."> [@_]" ;
  }

}


