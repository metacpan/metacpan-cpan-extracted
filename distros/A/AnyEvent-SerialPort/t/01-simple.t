#!/usr/bin/perl
#
# Copyright 2013 Mark Hindess

use strict;
use Test::More;
use lib 't/lib';
use File::Temp qw/tempfile/;

my ($fh, $filename) = tempfile();
END { unlink $filename if ($filename); }

use_ok 'AnyEvent::SerialPort';

my $hdl;

$hdl = AnyEvent::SerialPort->new(serial_port => $filename);
ok $hdl, 'Simple constructor';
is_deeply
  $hdl->serial_port->calls(),
  [
   [ 'Device::SerialPort::baudrate' => 9600 ],
   [ 'Device::SerialPort::databits' => 8 ],
   [ 'Device::SerialPort::parity' => 'none' ],
   [ 'Device::SerialPort::stopbits' => 1 ],
   [ 'Device::SerialPort::datatype' => 'raw' ],
   [ 'Device::SerialPort::write_settings' ],
  ], '... expected Device::SerialPort calls';

$hdl = AnyEvent::SerialPort->new(serial_port =>
                                 [
                                  $filename,
                                  [ baudrate => 4800 ],
                                 ]);
ok $hdl, 'constructor w/settings';
is_deeply
  $hdl->serial_port->calls(),
  [
   [ 'Device::SerialPort::baudrate' => 9600 ],
   [ 'Device::SerialPort::databits' => 8 ],
   [ 'Device::SerialPort::parity' => 'none' ],
   [ 'Device::SerialPort::stopbits' => 1 ],
   [ 'Device::SerialPort::datatype' => 'raw' ],
   [ 'Device::SerialPort::baudrate' => 4800 ],
   [ 'Device::SerialPort::write_settings' ],
  ], '... expected Device::SerialPort calls';

undef $hdl;

eval {
  $hdl = AnyEvent::SerialPort->new();
};
my $err = $@;
ok !$hdl, 'constructor w/o serial_port parameter';
like $err, qr!^Parameter serial_port is required!, '... correct error';

eval {
  $hdl = AnyEvent::SerialPort->new(serial_port => 't/does.not.exist');
};
$err = $@;
ok !$hdl, 'constructor w/o non-existent serial_port';
like $err, qr!^sysopen of 't/does\.not\.exist' failed:!,
  '... correct sysopen error';

done_testing;

