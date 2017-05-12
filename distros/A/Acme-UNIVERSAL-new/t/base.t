#!perl

use strict;
use warnings;

use Test::More 'no_plan'; # tests => 1;
use Scalar::Util 'reftype';

use_ok( 'Acme::UNIVERSAL::new' );
can_ok( __PACKAGE__, 'new' );
is( __PACKAGE__->can( 'new' ), \&UNIVERSAL::new, 'new() should be UNIVERSAL' );

sub Foo::new {}

sub Foo::Bar::new {}

sub Foo::Bar::Baz::new {}

my @classes  = qw( Foo Foo::Bar Foo::Bar::Baz Test::Builder );
my @reftypes = qw( HASH SCALAR ARRAY GLOB );
my %objects  = map { $_ => [] } @classes;
my %reftypes = map { $_ => [] } @reftypes;

for ( 1 .. 100 )
{
	my $object = UNIVERSAL::new();
	push @{ $objects{  ref      $object   } }, $object;
	push @{ $reftypes{ reftype( $object ) } }, $object;
}

my $obj_total;

for my $class ( @classes )
{
	my $count   = @{ $objects{ $class } };
	$obj_total += $count;
	ok( $count, "UNIVERSAL::new() should create $class objects..." );
}

is( $obj_total, 100, '... but no other classes' );

my $ref_total;

for my $reftype (qw( HASH SCALAR ARRAY CODE GLOB ))
{
	my $count   = @{ $reftypes{ $reftype } };
	$ref_total += $count;
	ok( $count, "UNIVERSAL::new() should create $reftype objects..." );
}
is( $ref_total, 100, '... but only those types' );
