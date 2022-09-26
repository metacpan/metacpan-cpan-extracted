#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Class::Plain;

use constant HAVE_DATA_DUMP => defined eval { require Data::Dump; };

class Counter {
   field count;
   
   method new : common {
     my $self = $class->SUPER::new(@_);
     
     $self->{count} //= 0;
     
     return $self;
   }

   method inc { $self->{count}++ }

   method describe { "Count is now $self->{count}" }
}

{
   my $counter = Counter->new;
   $counter->inc;
   $counter->inc;
   $counter->inc;

   is( $counter->describe, "Count is now 3",
      '$counter->describe after $counter->inc x 3' );

   # BEGIN-time initialised fields get private storage
   my $counter2 = Counter->new;
   is( $counter2->describe, "Count is now 0",
      '$counter2 field its own $count' );
}

{

   class AllTheTypes {
      field scalar;

     method new : common {
       my $self = $class->SUPER::new(@_);
       
       $self->{scalar} //= 123;
       
       return $self;
     }

      method test {
         Test::More::is( $self->{scalar}, 123, '$scalar field' );
      }
   }

   my $instance = AllTheTypes->new;

   $instance->test;
}

class AccessorBasic {
   field red : reader writer;
   field green : reader(get_green) :writer(set_green2);
   field blue : rw;
   field white : rw(get_set_white);

   method new : common {
     my $self = $class->SUPER::new(@_);
     
     return $self;
   }

   method rgbw {
      ( $self->{red}, $self->{green}, $self->{blue}, $self->{white} );
   }
}

# readers
{
   my $col = AccessorBasic->new(red => 50, green => 60, blue => 70, white => 80);

   is( $col->red,       50, '$col->red' );
   is( $col->get_green, 60, '$col->get_green' );
   is( $col->blue,      70, '$col->blue' );
   is( $col->get_set_white,     80, '$col->white' );
}

# writers
{
   my $col = AccessorBasic->new;

   $col->set_red( 80 );
   is( $col->set_green2( 90 ), $col, '->set_* writer returns invocant' );
   $col->blue(100);
   $col->get_set_white( 110 );

   is_deeply( [ $col->rgbw ], [ 80, 90, 100, 110 ],
      '$col->rgbw after writers' );
   
   $col->set_red(5)->blue(2)->get_set_white(7);
   is($col->red, 5);
   is($col->blue, 2);
   is($col->get_set_white, 7);
}


done_testing;
