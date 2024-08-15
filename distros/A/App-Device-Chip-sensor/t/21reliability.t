#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

use Future::AsyncAwait 0.47;
use Future::IO;
use Object::Pad 0.800;

my $run_count;
my $run_f;
my @saw_values;

class TestFutureIO
{
   method alarm { return Test::Future::Deferred->done_later }
}

Future::IO->override_impl( TestFutureIO->new );

my $okcount = 0;
my $failcount = 0;

class TestApp :isa(App::Device::Chip::sensor)
{
   method output_readings ( $, $sensors, $values )
   {
      push @saw_values, @$values;

      --$run_count or $run_f->cancel;
   }

   method on_sensor_ok ( $sensor )
   {
      $okcount++;
   }

   method on_sensor_fail ( $sensor, $failure )
   {
      $failcount++;
   }
}

class Device::Chip::Adapter::TestAdapter :does(Device::Chip::Adapter)
{
   async method make_protocol_GPIO { return $self }

   async method power ( $on ) {}
}
$INC{"Device/Chip/Adapter/TestAdapter.pm"} = __FILE__;

my $FAILURE;

class Device::Chip::TestChip :isa(Device::Chip)
{
   use Device::Chip::Sensor -declare;
   use Test::Future::Deferred;

   use constant PROTOCOL => "GPIO";

   declare_sensor asensor =>
      units => "";

   async method read_asensor
   {
      await Test::Future::Deferred->done_later;

      die $FAILURE if $FAILURE;
      return 123;
   }
}
$INC{"Device/Chip/TestChip.pm"} = __FILE__;

my $app = TestApp->new;
$app->parse_argv( [ "-A", "TestAdapter", "--best-effort", "TestChip" ] );

{
   $run_count = 3;
   @saw_values = ();

   $FAILURE = "It failed\n";

   $run_f = $app->run;
   $run_f->failure and $run_f->get;

   is( \@saw_values, [ undef, undef, undef ], '--best-effort turns failures into undef' );
   is( $failcount, 3, 'on_sensor_fail is invoked' );

   undef $FAILURE;

   $run_count = 1;

   $run_f = $app->run;
   $run_f->failure and $run_f->get;
   $run_f->await;

   is( \@saw_values, [ undef, undef, undef, 123 ], 'attempts again after failure is cleared' );
   is( $okcount, 1, 'on_sensor_ok is invoked' );
}

done_testing;
