#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Deep;

use Object::Pad 0.57;

my $customarg;

class TestApp :isa(App::Device::Chip::sensor)
{
   method OPTSPEC
   {
      return ( $self->SUPER::OPTSPEC,
         "custom=s" => \$customarg,
      );
   }
}

BEGIN {
   $INC{"Device/Chip/Adapter/_ATestAdapter.pm"} = __FILE__;
   $ENV{DEVICE_CHIP_ADAPTER} = "_ATestAdapter";
}

my $app = TestApp->new;

# defaults
{
   is( $app->interval, 10, 'default interval' );
}

# --interval
{
   $app->parse_argv( [ "--interval", 20, "ACHIP" ] );

   is( $app->interval, 20, 'interval after --interval argument' );

   cmp_deeply( [ $app->_chipconfigs ],
      [ { type => "ACHIP", adapter => Test::Deep::isa( "Device::Chip::Adapter::_ATestAdapter" ) } ],
      'chip configs'
   );
}

# chip args
{
   $app->parse_argv( [ "--interval", 20, "ACHIP", "BCHIP:-C:arg=value" ] );

   cmp_deeply( [ $app->_chipconfigs ],
      [ { type => "ACHIP", adapter => Test::Deep::isa( "Device::Chip::Adapter::_ATestAdapter" ) },
        { type => "BCHIP", adapter => Test::Deep::isa( "Device::Chip::Adapter::_ATestAdapter" ),
           config => { arg => "value" } } ],
      'chip configs'
   );
}

# --custom
{
   $app->parse_argv( [ "--custom", "abcde", "ACHIP" ] );

   is( $customarg, "abcde", 'custom arg parsing for app' );
}

my %adapterargs;
class Device::Chip::Adapter::_ATestAdapter :does(Device::Chip::Adapter)
{
   sub new_from_description { shift->new( @_ ) }

   BUILD
   {
      %adapterargs = @_;
   }
}
$INC{"Device/Chip/Adapter/_ATestAdapter.pm"} = __FILE__;

# --adapter
{
   $app->parse_argv( [ "--adapter", "_ATestAdapter:arg=value", "ACHIP" ] );

   is_deeply( \%adapterargs, { arg => "value" }, 'adapter constructor args' );
}

done_testing;
