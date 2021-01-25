#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;

use Object::Pad 0.19;

my $customarg;

class TestApp extends App::Device::Chip::sensor
{
   method OPTSPEC
   {
      return ( $self->SUPER::OPTSPEC,
         "custom=s" => \$customarg,
      );
   }
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
}

# --custom
{
   $app->parse_argv( [ "--custom", "abcde", "ACHIP" ] );

   is( $customarg, "abcde", 'custom arg parsing for app' );
}

my %adapterargs;
class Device::Chip::Adapter::_ATestAdapter implements Device::Chip::Adapter
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

   my $adapter = $app->adapter;
   isa_ok( $adapter, "Device::Chip::Adapter::_ATestAdapter", '$adapter' );
   is_deeply( \%adapterargs, { arg => "value" }, 'adapter constructor args' );
}

done_testing;
