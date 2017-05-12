#!/usr/local/bin/perl
use warnings FATAL => qw(all);

package MyScalar;
require Tie::Scalar;

@ISA = (Tie::StdScalar);

package MyHash;
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

sub get_name
  {
    my $self = shift ;
    return $self->{name} ;
  }

package MyObj ;
use ExtUtils::testlib;

use Class::IntrospectionMethods qw/make_methods set_obsolete_behavior/;

# do not fool around
set_obsolete_behavior('croak',0) ;

make_methods(get_set => [qw/a b c/])  ;

sub new 
  {
    my $class = shift;

    bless { @_ }, $class;
  }

sub all { my $self = shift; return join (' ', values %{$self}) ;}

package X ;
use ExtUtils::testlib;

use Class::IntrospectionMethods qw/make_methods set_obsolete_behavior/;

make_methods
  (
   # slot order is important in global_catalog (and will be respected)
   global_catalog => 
   {
    name => 'metacat',
    list => [
	     [qw/foo bar baz/]                 => foo_cat,
	     [qw/a b z/] 		       => alpha_cat,
	     [qw/stdhash my_object my_scalar/] => my_cat
	    ],
    isa => { my_cat => 'alpha_cat'} # my_cat includes alpha_cat
   },

   get_set => [qw/bar foo baz/],

   hash => 
   [
    a => {
	  tie_hash      => ['MyHash', dummy => 'booh'],
	  class_storage => ['MyObj', 'a' => 'foo']
	 },
    [qw/z b/] => {
		  tie_hash => ['MyHash'],
		  class_storage => ['MyObj', 'b' => 'bar']
		 },
    stdhash => {
		class_storage => ['MyObj', 'a' => 'foo']
	       }
   ],

   object => [ 'my_object' => 'MyObj'  ],
   tie_scalar => [ 'my_scalar' => ['MyScalar' , foo => 'bar' ]] ,
   new => 'new' 
  );

package main;

use ExtUtils::testlib;
use Test::More tests => 24 ;

use Data::Dumper ;

ok(1);

 # Where to query class catalog ?

my $class_cat_obj = &X::metacat ;

is_deeply( [$class_cat_obj->all_catalog], [qw/alpha_cat foo_cat my_cat/],
  "metacat->all") ;

is_deeply( [$class_cat_obj->slot('foo_cat')], [qw/foo bar baz/],
  "metacat->slot('foo_cat')") ;

is_deeply( [$class_cat_obj->slot('alpha_cat')], [qw/a b z/],
  "metacat->slot('alpha_cat')") ;

is_deeply( [$class_cat_obj->slot('my_cat')], [qw/a b z stdhash my_object my_scalar/],
  "metacat->slot('my_cat')") ;

is_deeply( [$class_cat_obj->catalog('a')], [qw/alpha_cat/],
  "metacat->catalog('a')") ;

is_deeply( scalar $class_cat_obj->info('my_object'), 
	   [qw/slot_type scalar class MyObj/],
	   "metacat->info('my_object')") ;


my @result = $class_cat_obj->info('a') ;
is_deeply(\@result,
	  [
	   'slot_type', 'hash',
	   'class', 'MyObj',
	   'class_args', ['a', 'foo'],
	   'tie_index', 'MyHash',
	   'tie_index_args', ['dummy', 'booh']
	  ], 
	  "check class_cat_obj->info('a')") ;

@result = $class_cat_obj->info('my_scalar') ;

# tie will disapear
is_deeply(\@result, 
	  [
	   'slot_type', 'scalar',
	   'tie_scalar', 'MyScalar',
	   'tie_scalar_args', ['foo', 'bar']
	  ], "test class_cat_obj->info('my_scalar')") ;

#test object tree catalog

my $o = new X;

my $cat_obj = $o->metacat ;

is_deeply( [$cat_obj->all_catalog], [qw/alpha_cat foo_cat my_cat/],
  "metacat->all") ;

is_deeply( [$cat_obj->slot('foo_cat')], [qw/foo bar baz/],
  "metacat->slot('foo_cat')") ;

is_deeply( [$cat_obj->slot('alpha_cat')], [qw/a b z/],
  "metacat->slot('alpha_cat')") ;

is_deeply( [$cat_obj->slot('my_cat')], [qw/a b z stdhash my_object my_scalar/],
  "metacat->slot('my_cat')") ;

is_deeply( [$cat_obj->catalog('a')], [qw/alpha_cat/],
  "metacat->catalog('a')") ;

is( join(' ',$cat_obj->all_slot), 
    'foo bar baz a b z stdhash my_object my_scalar',
    "test cat_obj->all_slot()") ;

my $cat = $cat_obj->slot('foo_cat') ;
ok($cat, "run cat_obj->slot('foo_cat') in scalar context");
is_deeply($cat,[qw/foo bar baz/],"result ok" );

# test SLOT_CATALOG and translucent properties (See man perltootc)

@result =  $class_cat_obj->catalog('stdhash') ;
is_deeply( \@result, ['my_cat'],
	   "test class_cat_obj->catalog('stdhash')") ;

ok($cat_obj->change('stdhash' => 'foo_cat'),
  "change object catalog" );

is_deeply([$class_cat_obj->catalog('stdhash')], ['my_cat'],
	 "class catalog has not changed");

# test CMM_CATALOG translucent properties
is_deeply( scalar $class_cat_obj->slot('my_cat'),
	   [qw'a b z stdhash my_object my_scalar'],
	   "test class_cat_obj->slot('my_cat')") ;

is_deeply( scalar $cat_obj->slot('my_cat'), 
	   [qw'a b z my_object my_scalar'],
	   "test cat_obj->slot('my_cat')") ;

is_deeply( scalar $cat_obj->slot('foo_cat'), 
	   [qw'foo bar baz stdhash'],
	   "test cat_obj->slot('foo_cat')") ;

is_deeply([$cat_obj->catalog('stdhash')], ['foo_cat'],
	 "test check object catalog");


exit 0 ;

