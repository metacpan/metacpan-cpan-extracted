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
set_obsolete_behavior('skip',1) ;

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
set_obsolete_behavior('skip',1) ;

make_methods
  (
   '-catalog' => 'foo_cat',
   get_set => [qw/foo bar baz/],
   object_tie_hash => 
   [
    {
     slot => 'a',
     tie_hash => ['MyHash', dummy => 'booh'],
     class => ['MyObj', 'a' => 'foo']
    },
    {
     slot =>['b','c'],
     tie_hash => ['MyHash'],
     class => ['MyObj', 'b' => 'bar']
    }
   ],
   '-nocatalog',
   object_tie_hash =>
   [
    {
     slot => 'named',
     tie_hash => ['MyHash'],
     class => ['MyObj', 'a' => 'foo']
    },
   ],
   '-catalog' => 'my_cat',
   object_tie_hash => 
   [
    {
     slot => 'stdhash',
     class => ['MyObj', 'a' => 'foo']
    }
   ],
   object => [ 'MyObj' => 'my_object' ],
   tie_scalar => [ 'my_scalar' => ['MyScalar' , foo => 'bar' ]] ,
   new => 'new' 
  );

package main;

use ExtUtils::testlib;
use Test::More tests => 30 ;

use Data::Dumper ;

ok(1);

# test class tree catalog
#print "catalog:", Dumper \@X::CMM_CATALOG ;
#print "name:",Dumper \%X::CMM_CATALOG_NAME ;
#print "list:",Dumper \%X::CMM_CATALOG_LIST ;
#print "detail:",Dumper \%X::CMM_SLOT_DETAIL ;


is( join(' ',sort &X::CMM_CATALOG_LIST()), 'foo_cat my_cat',
  "test &X::CMM_CATALOG_LIST()") ;
#print join(' ',sort &X::CMM_CATALOG('my_cat')),"\n" ;

is( join(' ',&X::CMM_CATALOG('my_cat')),
    'stdhash my_object my_scalar', "test &X::CMM_CATALOG('my_cat')") ;

is( join(' ',&X::CMM_CATALOG('foo_cat')), 'foo bar baz a b c',
  "test &X::CMM_CATALOG('foo_cat')") ;

is( join(' ',&X::CMM_SLOT_DETAIL(qw/my_object/)), 
    'slot_type scalar class MyObj', "test &X::CMM_SLOT_DETAIL(qw/my_object/)" ) ;

my @result = &X::CMM_SLOT_DETAIL('a') ;
#print Dumper \@result ;
is(scalar @result,10, "test X::CMM_SLOT_DETAIL('a')") ;
is( join(' ', @result[0..4]), 'slot_type hash class MyObj class_args' ) ;
is( join(' ', @{$result[5]}), 'a foo' ) ;
is( join(' ', @result[6,7,8]), 'tie_index MyHash tie_index_args' ) ;
is( join(' ', @{$result[9]}), 'dummy booh' ) ;

@result = &X::CMM_SLOT_DETAIL('my_scalar') ;
#print Dumper \@result ;

# tie will disapear
is(scalar @result,6, "test &X::CMM_SLOT_DETAIL('my_scalar')") ;
is( join(' ', @result[0..4]), 
    'slot_type scalar tie_scalar MyScalar tie_scalar_args' ) ;
is( join(' ', @{$result[5]}), 'foo bar' ) ;

#test object tree catalog

my $o = new X;

# create a hash of 2 object with default constructor arguments

#print join(' ',$o->CMM_CATALOG_LIST),"\n" ;
#print join(' ',$o->CMM_CATALOG()),"\n" ;

is( join(' ',sort $o->CMM_CATALOG_LIST), 'foo_cat my_cat' ,
  "test \$o->CMM_CATALOG_LIST") ;
is( join(' ',$o->CMM_CATALOG('my_cat')), 'stdhash my_object my_scalar',
  "test \$o->CMM_CATALOG('my_cat')") ;
is( join(' ',$o->CMM_CATALOG('foo_cat')), 'foo bar baz a b c',
  "test \$o->CMM_CATALOG('foo_cat')") ;

is( join(' ',$o->CMM_CATALOG()), 
    'foo bar baz a b c stdhash my_object my_scalar',
    "test \$o->CMM_CATALOG()") ;

my $cat = $o->CMM_CATALOG('foo_cat') ;
ok($cat, "run \$o->CMM_CATALOG('foo_cat') in scalar context");
is($cat->[3], 'a');

my $cat2 = $o->CMM_CATALOG('my_cat') ;
ok($cat2, "run \$o->CMM_CATALOG('my_cat') in scalar context");
is($cat2->[0], 'stdhash');


# test SLOT_CATALOG and translucent properties (See man perltootc)
@result =  &X::CMM_SLOT_CATALOG('stdhash') ;
is_deeply( \@result, ['my_cat'],
	   "test &X::CMM_SLOT_CATALOG('stdhash')") ;

is_deeply([$o->CMM_SLOT_CATALOG('stdhash')], ['my_cat'],
   "test \$o->CMM_SLOT_CATALOG('stdhash')") ;

# legacy must accept to change to a non-existing catalog
ok($o->CMM_SLOT_CATALOG('stdhash' => 'dummy_cat'),
  "change object catalog" );

is_deeply([&X::CMM_SLOT_CATALOG('stdhash')], ['my_cat'],
	 "class catalog has not changed");

# test CMM_CATALOG translucent properties
is( join(' ',&X::CMM_CATALOG('my_cat')), 'stdhash my_object my_scalar',
  "test &X::CMM_CATALOG('my_cat')") ;
is( join(' ',$o->CMM_CATALOG('my_cat')), 'my_object my_scalar',
  "test \$o->CMM_CATALOG('my_cat')") ;
is( join(' ',$o->CMM_CATALOG('foo_cat')), 'foo bar baz a b c',
  "test \$o->CMM_CATALOG('foo_cat')") ;
is( join(' ',$o->CMM_CATALOG('dummy_cat')), 'stdhash',
  "test \$o->CMM_CATALOG('foo_cat')") ;

is_deeply([$o->CMM_SLOT_CATALOG('stdhash')], ['dummy_cat'],
	 "test check object catalog");


exit 0 ;

