#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok('AnyEvent::Monitor::CPU');

throws_ok sub { AnyEvent::Monitor::CPU->new },
  qr/Required parameter 'cb' not found, /;

throws_ok sub { AnyEvent::Monitor::CPU->new(cb => 1) },
  qr/Parameter 'cb' must be a coderef, /;

done_testing();
