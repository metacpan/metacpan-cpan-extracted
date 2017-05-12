#!/usr/bin/perl

package MyObj {

	use Moose;

	  has foo => ( is => 'rw' );
	  has bar => ( is => 'rw' );

	  no Moose;

};


use Bread::Board;
use Test::More qw(no_plan);

use App::Services::ObjStore::Container;

my $cntnr = App::Services::ObjStore::Container->new();

my $svc = $cntnr->resolve( service => 'obj_store_svc' );

ok( $svc, "Create object store service" );

$svc->delete_object_store;
$svc->init_object_store;

ok( $svc->kdb, "initialized obj store" );

my $obj1 = MyObj->new( foo => 1, bar => 2 );

ok( $obj1, "obj created" );

my $oid = $svc->add_object($obj1);
ok( $oid, "inserted obj, got id" );

my $obj2 = $svc->get_object($oid);
ok( ( ref($obj2) eq 'MyObj' ), 'got object by id' );

ok( $obj2->foo == 1, 'foo expected value' );
ok( $obj2->bar == 2, 'bar expected value' );
