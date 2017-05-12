#!/usr/local/bin/perl
use warnings FATAL => qw(all);

package MyScalar;

use Carp;
use strict;

require Tie::Scalar ;

sub TIESCALAR 
  {
    my $type = shift;
    my %args = @_ ;
    my $self={} ;
    print "Creating scalar\n";
    bless $self,$type;
  }

sub STORE
  {
    my ($self,$value) = @_ ;
    $self->{value} = $value ;
    no warnings "uninitialized" ;
    print "Storing $value\n";
    return $value;
  }

sub FETCH
  {
    my $self = shift ;
    no warnings "uninitialized" ;
    print "Fetching $self->{value}\n";
    return $self->{value} ;
  }

sub get_name
  {
    my $self = shift ;
    return $self->{CMM_SLOT_NAME} ;
  }

package MyHash;
use Tie::Hash ;
use vars qw/@ISA/;

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


package X ;
use ExtUtils::testlib;

use Class::IntrospectionMethods qw/make_methods set_obsolete_behavior/;
set_obsolete_behavior('skip',1) ;

make_methods
  (  -catalog => 'test',
  '-parent',
  tie_tie_hash =>
  [
   {
    slot => 'std_std',
   },
   {
    slot => 'tie_std',
    tie_hash => [ 'MyHash' ]
   },
   {
    slot => 'std_tie',
    tie_scalar => [ 'MyScalar']
   },
   {
    slot => 'tie_tie',
    tie_hash => [ 'MyHash' ],
    tie_scalar => [ 'MyScalar']
   }
  ],
  new => 'new');

package main;
use ExtUtils::testlib;

use Test::More tests => 25 ;
use Data::Dumper ;
my $o = new X;

ok($o,"new X") ;

# create a hash of 2 object with default constructor arguments
is( scalar keys %{$o->std_std},0 ,"empty hash");
ok( ! defined $o->std_std('foo') );
is( $o->std_std('foo', 'baz'), 'baz',"std_std assignement" );

# print Dumper $o ;
is( $o->std_std('foo') , 'baz' );
ok( $o->std_std('bar', 'baz2') );

ok( $o->std_std_set(qw / a b c d / ) );
is_deeply([sort keys %{$o->std_std}],
	  [qw/a c/],"test keys op");

ok( $o->tie_std('foo', 'baz'), "tie_std assignement" );
# print Dumper $o ;
is( $o->tie_std('foo') , 'baz' );

is($o->tied_hash_tie_std->{CMM_SLOT_NAME} , 'tie_std', "CMM_SLOT_NAME member") ;
is($o->tied_hash_tie_std->CMM_PARENT, $o,"CMM_PARENT method") ;

ok( $o->std_tie('foo', 'baz'),"std_tie assignement" );

is( $o->std_tie('foo'), 'baz' );

is(ref($o->tied_scalar_std_tie('foo')), 'MyScalar',
   "tied_scalar_std_tie type") ;

is($o->tied_scalar_std_tie('foo')->{CMM_SLOT_NAME}, 'std_tie',
   "tied_scalar_std_tie CMM_SLOT_NAME member") ;

is($o->tied_scalar_std_tie('foo')->{CMM_PARENT} ,$o,
   "tied_scalar_std_tie CMM_PARENT member");

ok( $o->tie_tie('foo', 'baz2'),"tie_tie assignement" );
# print Dumper $o ;
is( $o->tie_tie('foo') , 'baz2' );

is($o->tied_hash_tie_tie->{CMM_SLOT_NAME}, 'tie_tie',
   "tied_hash_tie_tie CMM_SLOT_NAME") ;
ok($o->tied_scalar_tie_tie('foo'));
is($o->tied_scalar_tie_tie('foo')->{CMM_SLOT_NAME}, 'tie_tie') ;
is($o->tied_scalar_tie_tie('foo')->{CMM_PARENT}, $o) ;

# test that we can assign an undef value

ok( not defined $o->tie_tie('foo', undef) );
ok( not defined $o->tie_tie('foo') );

exit 0 ;

