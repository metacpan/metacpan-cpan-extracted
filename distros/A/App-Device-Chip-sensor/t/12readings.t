#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Deep;

use Future::AsyncAwait 0.47;
use Future::IO;
use Object::Pad 0.19;

my $run_count;
my $run_f;
my @saw_values;

class TestFutureIO
{
   method alarm { return Test::Future::Deferred->done_later }
}

Future::IO->override_impl( TestFutureIO->new );

class TestApp extends App::Device::Chip::sensor
{
   method output_readings ( $, $sensors, $values )
   {
      push @saw_values, @$values;

      --$run_count or $run_f->cancel;
   }
}

class Device::Chip::Adapter::TestAdapter implements Device::Chip::Adapter
{
   async method make_protocol_GPIO { return $self }

   async method power ( $on ) {}
}
$INC{"Device/Chip/Adapter/TestAdapter.pm"} = __FILE__;

class Device::Chip::TestChip extends Device::Chip
{
   use Device::Chip::Sensor -declare;
   use Test::Future::Deferred;

   use constant PROTOCOL => "GPIO";

   declare_sensor asensor =>
      ;

   async method read_asensor
   {
      await Test::Future::Deferred->done_later;
      return 1234;
   }
}
$INC{"Device/Chip/TestChip.pm"} = __FILE__;

my $app = TestApp->new;
$app->parse_argv( [ "-A", "TestAdapter", "TestChip" ] );

{
   $run_count = 1;
   @saw_values = ();

   $run_f = $app->run;
   $run_f->await;

   is_deeply( \@saw_values, [ 1234 ], 'values passed to ->output_readings' );
}

{
   $run_count = 3;
   @saw_values = ();

   $run_f = $app->run;
   $run_f->failure and $run_f->get;

   is_deeply( \@saw_values, [ 1234, 1234, 1234 ], 'values passed to ->output_readings 3 times' );
}

done_testing;
