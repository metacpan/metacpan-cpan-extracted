# -*- cperl -*-

use Test::More ;
BEGIN { plan tests => 14 } ;

########################################################################
use strict ;
use warnings FATAL => qw(all);
use lib qw/t/ ;

use ExtUtils::testlib;
use Data::Dumper ;
use Class::IntrospectionMethods::Parent 
  qw(set_parent_method_name graft_parent_method set_obsolete_behavior) ;


ok(1);

########################################################################

set_obsolete_behavior('skip',1) ;

set_parent_method_name( 'foo_bar') ;

ok(1,"called set_parent_method_name") ;

my $parent = bless {}, "Test";
my $parent2 = bless {}, "Test";
my $child = bless {} ,"TestChild" ;

graft_parent_method($child,$parent, "a_slot", "an_index" ) ;

ok(1,"called graft_parent_method") ;

is($child->foo_bar->slot_name, "a_slot", 
   "tested slot_name" );
is($child->foo_bar->index_value, "an_index", 
   "tested index_value" );
is($child->foo_bar->parent, $parent, 
   "tested parent") ;

is($child->foo_bar->parent($parent2), $parent2, 
   "tested change of parent") ;

is($child->{CMM_SLOT_NAME}, "a_slot", "tested CMM_SLOT_NAME") ;
is($child->{CMM_INDEX_VALUE}, "an_index", "tested CMM_INDEX_VALUE") ;
is($child->CMM_SLOT_NAME, "a_slot", "tested CMM_SLOT_NAME method") ;
is($child->CMM_INDEX_VALUE, "an_index", "tested CMM_INDEX_VALUE method") ;
is($child->CMM_PARENT, $parent2, "tested CMM_PARENT method") ;

is($child->CMM_PARENT($parent), $parent, "tested change with CMM_PARENT method") ;

my $parent3 = bless {}, "Test3";

my $child2 = bless {} ,"TestChild" ;

graft_parent_method($child2,$parent3, "a_slot2", "an_index2" ) ;
is($child2->foo_bar->slot_name, "a_slot2", 
   "tested foo_bar on another child" );
