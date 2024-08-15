#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

use Future::AsyncAwait 0.47;
use Object::Pad 0.800;

my $after_sensors_arg;
class TestApp :isa(App::Device::Chip::sensor)
{
   async method after_sensors { $after_sensors_arg = [ @_ ]; }
}

my $app = TestApp->new;

class Device::Chip::Adapter::_ATestAdapter :does(Device::Chip::Adapter)
{
   async method make_protocol_GPIO { return $self }

   async method power ( $on ) {}
}
$INC{"Device/Chip/Adapter/_ATestAdapter.pm"} = __FILE__;

my $initialized;
class Device::Chip::_ATestChip :isa(Device::Chip)
{
   use Device::Chip::Sensor -declare;

   use constant PROTOCOL => "GPIO";

   async method initialize_sensors { $initialized++ }

   declare_sensor asensor =>
      units => "";

   async method read_asensor { return 1234; }
}
$INC{"Device/Chip/_ATestChip.pm"} = __FILE__;

# single chip
{
   $app->parse_argv( [ "--adapter", "_ATestAdapter", "_ATestChip" ] );

   my @chips = await $app->chips;

   is( scalar @chips, 1, '$app->chips yields one chip' );

   is( ref $chips[0], "Device::Chip::_ATestChip", '$chip isa TestChip' );

   ok( $initialized, 'Chip is initialized for sensors' );

   my @sensors = await $app->sensors;

   is( scalar @sensors, 1, '$app->sensors returns one sensor' );

   is( $sensors[0]->name, "asensor", '$sensors[0]->name' );

   is( await $sensors[0]->read, 1234, '$sensors[0]->read' );

   is( $after_sensors_arg, \@sensors,
      'List of sensors passed to $app->after_sensors' );
}

done_testing;
