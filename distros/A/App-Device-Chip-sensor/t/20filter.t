#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

use Future::AsyncAwait 0.47;
use Future::IO;
use Object::Pad 0.800;

my @sensor_values;
my $run_f;
my @saw_values;

class TestFutureIO
{
   method alarm { return Test::Future::Deferred->done_later }
}

Future::IO->override_impl( TestFutureIO->new );

class TestApp :isa(App::Device::Chip::sensor)
{
   method output_readings ( $, $sensors, $values )
   {
      push @saw_values, @$values;

      @sensor_values or $run_f->cancel;
   }
}

class Device::Chip::Adapter::TestAdapter :does(Device::Chip::Adapter)
{
   async method make_protocol_GPIO { return $self }

   async method power ( $on ) {}
}
$INC{"Device/Chip/Adapter/TestAdapter.pm"} = __FILE__;


class Device::Chip::TestChip :isa(Device::Chip)
{
   use Device::Chip::Sensor -declare;
   use Test::Future::Deferred;

   use constant PROTOCOL => "GPIO";

   declare_sensor asensor =>
      units => "";

   field $value = 0;

   async method read_asensor
   {
      await Test::Future::Deferred->done_later;
      return shift @sensor_values;
   }
}
$INC{"Device/Chip/TestChip.pm"} = __FILE__;

# mid3
{
   my $app = TestApp->new;
   $app->parse_argv( [ "-A", "TestAdapter", "--mid3", "TestChip" ] );

   @sensor_values = ( 100, 200, 300, 400, 200 );
   @saw_values = ();

   $run_f = $app->run;
   $run_f->failure and $run_f->get;

   is( \@saw_values, [ 100, 200, 200, 300, 300 ], 'mid3 filtering' );
}

# mid5
{
   my $app = TestApp->new;
   $app->parse_argv( [ "-A", "TestAdapter", "-F", "mid5", "TestChip" ] );

   @sensor_values = ( 100, 200, 300, 400, 500, 600, 700 );
   @saw_values = ();

   $run_f = $app->run;
   $run_f->failure and $run_f->get;

   is( \@saw_values, [ 100, 200, 300, 400, 300, 400, 500 ], 'mid5 filtering' );
}

# ravg2
{
   my $app = TestApp->new;
   $app->parse_argv( [ "-A", "TestAdapter", "-F", "ravg2", "TestChip" ] );

   @sensor_values = ( 100, 200, 200, 200 );
   @saw_values = ();

   $run_f = $app->run;
   $run_f->failure and $run_f->get;

   is( \@saw_values, [ 100, 125, 143.75, 157.8125 ], 'ravg2 filtering' );
}

done_testing;
