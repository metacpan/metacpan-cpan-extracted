#!/usr/local/bin/perl
use warnings FATAL => qw(all);

package myHash;
use Tie::Hash ;

@ISA=qw/Tie::StdHash/ ;

sub TIEHASH {
  my $class = shift; 
  my %args = @_ ;
  return bless \%args, $class ;
}

sub STORE 
  { 
    my ($self, $idx, $value) = @_ ; 
    $self->{$idx}=$value;
    return $value;
  }

package myObj ;
use ExtUtils::testlib;

our $nb = 0 ;

use Class::IntrospectionMethods qw/make_methods set_obsolete_behavior/;

set_obsolete_behavior('skip',1) ;

make_methods(get_set => [qw/a b c/] ) ;

sub new 
  {
    my $class = shift;

    bless { @_ }, $class;
  }

sub all { my $self = shift; return join (' ', values %{$self}) ;}

sub get_name
  {
    my $self = shift ;
    return $self->{CMM_SLOT_NAME} ;
  }

sub cim_init
  {
    my $self=shift ;
    $nb ++ ;
  }

package X ;
use ExtUtils::testlib;

use Class::IntrospectionMethods qw/make_methods set_obsolete_behavior/;

make_methods(
  '-parent' ,
  object_tie_hash => 
  [
   {
    slot => 'a',
    tie_hash => ['myHash'],
    class => ['myObj', 'a' => 'foo']
   },
   {
    slot =>['b','c'],
    tie_hash => ['myHash'],
    class => ['myObj', 'b' => 'bar']
   }
  ],
  object_tie_hash =>
  [
   {
    slot => 'named',
    tie_hash => ['myHash'],
    class => ['myObj', 'a' => 'foo']
   },
   {
    slot => 'named2',
    tie_hash => ['myHash' ], # , 'dummy'], # uncomment for error checking
    class => ['myObj', 'a' => 'foo']
   }
  ],
  object_tie_hash =>
  [
   {
    slot => 'stdhash',
    class => ['myObj', 'a' => 'foob']
   }
  ],
  new => 'new' );

package main;
use ExtUtils::testlib;

use Test::More;
BEGIN { plan tests => 33 } ;

use Data::Dumper ;
my $o = new X;

ok( 1 ,"compiled ok");
# create a hash of 2 object with default constructor arguments
ok($o->a('foo')) ;
ok($o->a('bar')) ;

#print Dumper $o ;
is($o->a->{bar}->a , 'foo') ;
is($o->a->{foo}->a , 'foo') ;

my $o2 = new X ;
# create a hash of 2 object with default constructor arguments
#10
ok($o2->a(qw/foo/)) ;
ok($o2->a(qw/bar/)) ;

#print Dumper $o2 ;
ok($o2->a) ;
is($o2->a->{foo}->a , 'foo') ;
is($o2->a->{bar}->a , 'foo') ;
is($o2->a('foo')->a , 'foo') ;
is($o2->a('bar')->a , 'foo') ;

# set value in myObj
# 17
ok($o2->a('foo')->b('bar2'));
ok($o2->a('foo')->a('bar'));
is($o2->a('foo')->a , 'bar') ;
is($o2->a('foo')->b ,'bar2');

#21
ok($o2->c('foo')->a('baz'));
is($o2->c('foo')->a() , 'baz');

is($myObj::nb, 5, "check that cim_init was called") ;

ok($o2->named('foo')->a('baz')) ;

#print Dumper $o2 ;
# 22
is($o2->named('foo')->get_name , 'named') ;

is($o2->stdhash('bar')->a , 'foob') ;

#use Class::IntrospectionMethods::Parent qw/set_/ ;
# disable legacy warnings
#set_warn(0) ;

# test parent accessor
# 24
is($o2->named('foo')->CMM_PARENT , $o2) ;
is($o2->stdhash('foo')->CMM_PARENT , $o2) ;
is($o->named('foo')->CMM_PARENT , $o) ;
is($o->stdhash('foo')->CMM_PARENT , $o) ;
is($o->stdhash('foo')->CMM_SLOT_NAME , 'stdhash',"check CMM_SLOT_NAME") ;
is($o->stdhash('foo')->CMM_INDEX_VALUE , 'foo',"check CMM_INDEX_VALUE") ;

ok($o->a ) ;
ok($o->a() ) ;

# 31
is($o->tied_named->{CMM_SLOT_NAME} , 'named') ;

is($o->tied_named->CMM_PARENT , $o) ;

my $o3 = new X ;
my $obj = $o3->tied_a ;
ok(defined $obj,"auto-create tied hashes through tied_xxx method") ;

exit 0 ;

