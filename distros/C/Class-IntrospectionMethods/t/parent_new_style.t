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

use Class::IntrospectionMethods 
  qw/make_methods set_obsolete_behavior set_parent_method_name/;

set_parent_method_name('metadad') ;

make_methods
  (
   # slot order is important in global_catalog (and will be respected)
   'parent',
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
use Test::More tests => 8 ;

use Data::Dumper ;

ok(1);

my $o = new X;

my $obj = $o->a('foo') ;
is(ref $obj,'MyObj') ;

my $info = $obj->metadad ;
is(ref $info,'Class::IntrospectionMethods::ParentInfo',
   "called metadad") ;

is($info->parent, $o, "parent") ;
is($info->slot_name, 'a', "slot_name") ;
is($info->index_value, 'foo', "index_value") ;

# check parent method on object behind tied hash
my $tied_hash_obj = $o->tied_hash_a ;
ok($tied_hash_obj,"got obj hidden behind hash") ;

is($tied_hash_obj->metadad->parent, $o, " got parent through tied hash obj"); 

exit 0 ;

