#!/usr/local/bin/perl
use warnings FATAL => qw(all);

package myArray;
use Tie::Array ;

@ISA=qw/Tie::StdArray/ ;

use vars qw/$prefix/ ;

my @targs ;

sub TIEARRAY {
  my $class = shift; 
  push @targs , @_ ;
  return bless [], $class ;
}

sub FETCH { my ($self, $idx) = @_ ; 
            return $self->[$idx];}

sub STORE { my ($self, $idx, $value) = @_ ; 
            #print "storing $idx, $value ...\n";
            $self->[$idx]=$value;
            return $value;}

package myHArray;

sub TIEARRAY {
  my $class = shift; 
  return bless {data => []}, $class ;
}

sub FETCH { my ($self, $idx) = @_ ; 
            return $self->{data}[$idx];}

sub STORE { my ($self, $idx, $value) = @_ ; 
            $self->{data}[$idx]=$value;
            return $value;}

sub FETCHSIZE
  {
    my $self = shift ;
    return scalar @{$self->{data}};
  }

sub CLEAR
  {
    my $self = shift ;
    return $self->{data} = [] ;
  }

sub EXTEND {}

package X ;
use ExtUtils::testlib;

use Class::IntrospectionMethods qw/make_methods set_obsolete_behavior/;
set_obsolete_behavior('skip',1) ;

make_methods
  (
  '-catalog' => 'test',
  tie_list => 
  [
   a => ['myArray', "my"],
   ['b','c'] => ['myArray',"other"],
  ],
  '-parent',
  tie_list => [ h => 'myHArray' ],
  new => 'new'
  );

package main;
use ExtUtils::testlib;

#$::CMM_PARENT_TRACE =1 ;

use lib qw ( ./t );
use Test::More tests => 12;
use Data::Dumper ;

$Class::IntrospectionMethods::Parent::trace =1 ;

my $o = new X;

ok( 1 );
ok($o->a(qw/0 1 2/)) ;
ok($o->b(qw/1 2 3 4/)) ;
ok($o->c(qw/a s d f/)) ;

is_deeply(\@targs,[qw/my other other/],"tied array used") ;

my @r = $o->a ;

#print Dumper $o ;

is( $r[1] , "1" );

is($o->b_shift , 1); # SHIFT not overloaded in myArray

is($o->c_count , 4);

is(join(' ',$o->CMM_CATALOG()) , 'a b c h') ;

ok($o->h(1,2,3)) ;

is($o->tied_h->CMM_PARENT , $o) ;

is(join(' ',$o->h) , '1 2 3') ;

exit 0;

