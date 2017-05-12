#!/usr/bin/perl

use Test::More ;
BEGIN { plan tests => 39 } ;

########################################################################
use strict ;
use warnings FATAL => qw(all);
use lib qw/t/ ;

use ExtUtils::testlib;
use Data::Dumper ;
use Class::IntrospectionMethods::Catalog 
  qw/set_global_catalog set_method_info/;


ok(1);

########################################################################

my %struct = 
  (
   name    => 'my_meta_catalog',
   list    => [
	       abba => [qw/catalog_a catalog_b/],
	       [qw/ati radeon/] => 'catalog_a',
	       bof => [qw/catalog_b catalog_c/]
	      ],
   isa => { catalog_a => 'catalog_b' },
   help    => { catalog_a => 'list all slots that ...',
		catalog_b => 'likewise ;-)' } ) ;

my %meth = set_global_catalog( 'Test::Class', %struct );

ok(1,"called set_global_catalog") ;

is_deeply([sort keys %meth], [qw/my_meta_catalog/ ], "test created methods") ;

my $info = { foo => 'bar' } ;

# store construction info in catalog
set_method_info("Test::Class",'ati',$info) ;

ok(1,"set_method_in_catalog done");

my $dummy_obj = {} ;
bless $dummy_obj, "Test::Class" ;

my $catalog_obj = $meth{my_meta_catalog}->($dummy_obj) ;

#print Dumper($catalog_obj) ;

foreach ( #[''],             [qw/catalog_a catalog_b catalog_c/],] ,
	  [['all_catalog'],     [qw/catalog_a catalog_b catalog_c/],],
	  [[catalog => 'ati'],  [qw/catalog_a/]],
	  [[catalog => 'abba'], [qw/catalog_a catalog_b/]],
	  [[catalog => 'ati'],  [qw/catalog_a/]],
	  [[slot    => 'catalog_a'],  [qw/abba ati radeon bof/]],
	  [[slot    => 'catalog_b'],  [qw/abba bof/]],
	  [[slot    => 'catalog_c'],  [qw/bof/]],
	  [[help    => 'catalog_a'],  [$struct{help}{catalog_a}] ],
	  [[help    => 'catalog_c'],  [''] ],
	  [[catalog_isa     => 'catalog_a'],  [$struct{isa}{catalog_a}] ],
	  [[info    => 'ati'],  [foo => 'bar']],
	) 
  {
    my $command =  $_->[0][0] ;
    my $args = $_->[0][1] ;
    my @res = $catalog_obj->$command($args) ;
    # looks like is_deeply does not make a difference between '' and
    # undef. So we must test this specifically
    ok(defined $res[0],"$command result is defined");
    is_deeply(\@res, $_->[1],
	      "call my_meta_catalog->('".join("','",@{$_->[0]})."')") ;
  }

is_deeply ([$catalog_obj->change(ati => 'catalog_c')], ['catalog_c'], "test change");

is_deeply([$catalog_obj->slot('catalog_c')],
	  ['ati', 'bof'], "test change => ati => 'catalog_c' 1") ;

is_deeply([$catalog_obj->catalog('ati') ],
	 ['catalog_c'], "test change => ati => 'catalog_c' 2" );

is_deeply ([$catalog_obj->change( ati => ['catalog_b','catalog_c'])],
	   [ 'catalog_b','catalog_c'], 'test change 2');

is_deeply([$catalog_obj->slot('catalog_c')],
	  ['ati', 'bof'], "test change => ati => 'catalog_c' 1") ;

is_deeply([$catalog_obj->slot('catalog_b')],
	  ['abba','ati', 'bof'], "test change => ati => 'catalog_c' 2") ;

is_deeply([$catalog_obj->catalog('ati') ],
	 ['catalog_b','catalog_c'], "test change => ati => 'catalog_c' 3" );

my @res = $catalog_obj->reset('ati') ;

is_deeply(\@res,['catalog_a'],"test reset sur ati") ;


$catalog_obj->add( raba => [qw/catalog_a catalog_c/]) ;

foreach ( 
	  [['all_catalog'],     [qw/catalog_a catalog_b catalog_c/],],
	  [[catalog => 'raba'], [qw/catalog_a catalog_c/]],
	  [[slot    => 'catalog_a'],  [qw/abba ati radeon bof raba/]],
	  [[slot    => 'catalog_b'],  [qw/abba bof/]],
	  [[slot    => 'catalog_c'],  [qw/bof raba/]],
	) 
  {
    my $command =  $_->[0][0] ;
    my $args = $_->[0][1] ;
    is_deeply([$catalog_obj->$command($args)], $_->[1],
	      "after add call my_meta_catalog->('".join("','",@{$_->[0]})."')") ;
  }

1;
