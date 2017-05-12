# -*- cperl -*-
use warnings FATAL => qw(all);

package Y;
my $count = 0;
sub new { bless { id => $count++ }, shift; }
sub id { shift->{id}; }

package X;

use Class::IntrospectionMethods qw/make_methods set_obsolete_behavior/;
set_obsolete_behavior('skip',1) ;

make_methods
  (
   object_list  => [
		    'Y' => 'a' ,
		   ],
   '-parent' ,
   object_list  => [
		    'Y' => { slot => 'pa' },
		   ]
  );

sub new { bless {}, shift; }

package main ;

use Test::More tests => 59 ;
#$Class::IntrospectionMethods::Parent::trace = 1;

my $o = new X;

ok( $o, "X created" );

# TBD : a was never accessed so no tie was done
# solution: test $self->{name} for all array methods (likewise for hash)
# which means that create_foo must be an available method is you
# other sol: tie self .... Naah too complex

$o->a_storesize(2);
is( scalar(@{$o->a}) , 2 ,"size is 2 after store size");

my $elt = $o->a_index(0) ;
is (ref($elt),'Y',"check autotvivification") ;

is( $o->a_pop->id , 1 ,"pop" );
is( scalar(@{$o->a}) , 1 ,"size is 1 after pop");
ok( $o->a_push (Y->new),"push Y");


my $check = sub {
  my $size = shift ;
  is( scalar(@{$o->a}) , 2 ,"size is 2");
  foreach my $idx (0 .. $size-1)
    {
      ok( defined $o->a_index($idx), "\$a->[$idx] defined") ;
      ok( $o->a_index($idx)->isa('Y'),
	  "\$a->[$idx] contains only Y objects") ;
    }
} ;

$check->(2) ;

is( $o->a_shift->id , 0 );

ok( $o->a_unshift ( Y->new ) );

$check->(2) ;

is( ref($o->a_index(0)) , 'Y' );

ok( $o->a_set(0 => Y->new) );

is( $o->a_index(0)->id , 4);
$check->(2) ;

$o->a_clear; 
is($o->a_count , 0 ,"test clear");

# Backwards compatibility test
ok( $o->push_a (Y->new) );
ok( $o->push_a (Y->new) );
ok( $o->pop_a->id );

ok( $o->push_a (Y->new) );
$check->(2) ;

is( $o->shift_a->id , 5 );
ok( $o->unshift_a ( Y->new ) );

$check->(2) ;

is( ref($o->index_a(0)) , 'Y' );
ok( $o->set_a(0 => Y->new) );
is( $o->a_index(0)->id , 9);

$check->(2) ;

is( ref($o->pa_index(0)) , 'Y',"auto-vivify object with -parent") ;

is( $o->pa_index(0)->CMM_PARENT , $o, "test CMM_PARENT graft") ;

# test auto-vivification
is( ref $o->pa_index(32) , 'Y' ) ;
is( ref $o->pa_index(35) , 'Y' ) ;
is( $o->pa_index(32)->CMM_PARENT , $o) ;
is( $o->pa_index(32)->{CMM_SLOT_NAME} , 'pa') ;
is( $o->pa_index(32)->{CMM_INDEX_VALUE} , 32) ;



# test auto-vivification that may be too enthusiastic
is($o->pa_index(33) , $o->pa_index(33) ) ;

