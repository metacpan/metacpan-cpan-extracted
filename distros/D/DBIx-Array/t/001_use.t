# -*- perl -*-
use strict;
use warnings;
use Test::More tests => 7;

BEGIN { use_ok( 'DBIx::Array' ); }
BEGIN { use_ok( 'DBIx::Array::Export' ); }
BEGIN { use_ok( 'DBIx::Array::Session::Action' ); }

my $sdb = DBIx::Array->new (name=>"String");
isa_ok ($sdb, 'DBIx::Array');
is($sdb->name, "String", '$sdb->name');

$sdb = DBIx::Array::Export->new (name=>"String");
isa_ok ($sdb, 'DBIx::Array::Export');
is($sdb->name, "String", '$sdb->name');
