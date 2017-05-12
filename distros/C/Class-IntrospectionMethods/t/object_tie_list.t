# -*- cperl -*-

use warnings FATAL => qw(all);

package myArray;
use Tie::Array ;

@ISA=qw/Tie::Array/ ;

use vars qw/$log/ ;

$log = 'log: ';

sub TIEARRAY {
  my $class = shift; 
  my $p = shift || '';
  #print "log $p ($log))\n";
  $log .= "tie $p,";
  return bless {data=> []}, $class ;
}

sub STORE { my ($self, $idx, $value) = @_ ; 
            #print "storing $idx, $value ...\n";
            $log .=  "store $idx,";
            $self->{data}[$idx]=$value;
            return $value;}
sub FETCH { my ($self, $idx) = @_ ; 
            return $self->{data}[$idx];}
sub FETCHSIZE
  {
    my $self = shift ;
    return scalar @{$self->{data}};
  }

sub CLEAR
  {
    my $self = shift ;
    return $self->{data} = [] ;
  }

sub EXTEND {}

sub STORESIZE { $#{$_[0]->{data}} = $_[1] -1 ;}

package myObj ;
use ExtUtils::testlib;

use Class::IntrospectionMethods qw/make_methods set_obsolete_behavior/;
set_obsolete_behavior('skip',1) ;

make_methods (get_set => [qw/a b c/]  );

sub new 
  {
    my $class = shift;

    bless { arg=> shift }, $class;
  }

sub all { 
  my $self = shift; 
  return $self->{arg} ;
}

package X ;
use ExtUtils::testlib;

use Class::IntrospectionMethods qw/make_methods set_obsolete_behavior/;
set_obsolete_behavior('skip',1) ;

make_methods
  (
  object_tie_list => 
  [
   {
    slot => 'a',
    tie_array => ['myArray', "a"],
    class => ['myObj', 'a_obj']
   }
  ],
  '-parent' ,
  object_tie_list => 
  [
   {
    slot =>['b','c'],
    tie_array => ['myArray', "bc"],
    class => ['myObj', 'b_obj']
   }
  ],
  new => 'new'
  );

package main;
use ExtUtils::testlib;

use Test::More tests => 14 ;
use Data::Dumper ;
my $o = new X;

ok( 1 );
# create a list of 2 object with default constructor arguments
#ok($o->a(1,2)) ;

my @a = $o->a ;
#print Dumper $o->a_index(0);

is($o->a->[0]->all , 'a_obj' , "autovivify [0]");
is($o->a->[1]->all , 'a_obj' , "autovivify [1]");

is($myArray::log , 'log: tie a,store 0,store 1,',
   "verify  that tied array was used") ;

is($o->b->[0]->all , 'b_obj', "autovivify b[0]" );

is($myArray::log , 'log: tie a,store 0,store 1,tie bc,store 0,',
  "verify  that tied array was used again");

# create 2 object and assign them
my @objs = (myObj->new('c1_obj'), myObj->new('c2_obj'));
ok($o->c(@objs), "assigned 2 object to c") ;
is($o->c->[0]->all , 'c1_obj' );
is($o->c->[1]->all , 'c2_obj' );

# test parent accessor
is($o->c->[0]->CMM_PARENT , $o, "check CMM_PARENT on [0]");
is($o->c->[1]->CMM_PARENT , $o, "check CMM_PARENT on [1]");
is($o->c->[1]->CMM_SLOT_NAME , "c", "check CMM_SLOT_NAME");
is($o->c_index(1)->CMM_INDEX_VALUE , 1 , "check CMM_INDEX_VALUE");

is( ref $o->a_index(32) , 'myObj' ,"test auto-vivification" ) ;


exit 0;

