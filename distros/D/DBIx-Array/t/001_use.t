# -*- perl -*-
use strict;
use warnings;
use Test::More tests => 14;

BEGIN { use_ok( 'DBIx::Array' ); }
BEGIN { use_ok( 'DBIx::Array::Export' ); }
BEGIN { use_ok( 'DBIx::Array::Session::Action' ); }

{
  my $sdb = DBIx::Array->new (name=>"String");
  isa_ok ($sdb, 'DBIx::Array');
  can_ok($sdb, 'name');
  is($sdb->name, "String", '$sdb->name');
  is($sdb->name('foo'), 'foo', 'name');
  is($sdb->name, 'foo', 'name');

  isa_ok($sdb->new, 'DBIx::Array');

  is($sdb->prepare_max_count, 128, 'prepare_max_count');
  is($sdb->prepare_max_count(5), 5, 'prepare_max_count');
  is($sdb->prepare_max_count, 5, 'prepare_max_count');
}

{
  my $sdb = DBIx::Array::Export->new (name=>"String");
  isa_ok ($sdb, 'DBIx::Array::Export');
  is($sdb->name, "String", '$sdb->name');
}
