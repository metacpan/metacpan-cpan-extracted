#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Deep;

use Future::AsyncAwait 0.47;
use Future::IO;
use Object::Pad 0.57;

my $run_f;

class TestFutureIO
{
   method alarm { return Test::Future::Deferred->done_later }
}

Future::IO->override_impl( TestFutureIO->new );

class TestApp :isa(App::Device::Chip::sensor)
{
   method output_readings ( $, $sensors, $values )
   {
      $self->print_readings( $sensors, $values );
      $run_f->cancel;
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

   declare_sensor agauge =>
      ;

   async method read_agauge
   {
      await Test::Future::Deferred->done_later;
      return 123;
   }

   declare_sensor_counter acounter =>
      ;

   async method read_acounter
   {
      await Test::Future::Deferred->done_later;
      return 4;
   }
}
$INC{"Device/Chip/TestChip.pm"} = __FILE__;

my $app = TestApp->new;
$app->parse_argv( [ "-A", "TestAdapter", "TestChip" ] );

# Test the ->print_readings method
{
   open my $outh, ">", \my $output;
   {
      local *STDOUT = $outh;

      $run_f = $app->run;
      $run_f->await;
   }

   is( $output, <<'EOF',
TestChip/  agauge: 123
TestChip/acounter: 0/sec
EOF
      'Output from ->print_readings' );
}

done_testing;
