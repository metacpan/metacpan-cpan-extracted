#
# This file is part of Config-Model-LcdProc
#
# This software is Copyright (c) 2013-2023, 2026 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
use strict;
use warnings;
use v5.20;
use utf8;

return [
  {
    'class_description' => 'generated from LCDd.conf',
    'description' => {
      'Brightness' => 'Set the initial brightness ',
      'Device' => 'device where the VFD is. Usual values are /dev/ttyS0 and /dev/ttyS1',
      'OffBrightness' => 'Set the initial off-brightness 
This value is used when the display is normally
switched off in case LCDd is inactive',
      'Parity' => 'Set serial data parity 
Meaning: 0(=none), 1(=odd), 2(=even)',
      'Reboot' => 're-initialize the VFD ',
      'Size' => 'Specifies the size of the LCD.',
      'Speed' => 'set the serial port speed '
    },
    'element' => [
      'Brightness',
      {
        'max' => '1000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '1000',
        'value_type' => 'integer'
      },
      'Device',
      {
        'type' => 'leaf',
        'upstream_default' => '/dev/lcd',
        'value_type' => 'uniline'
      },
      'OffBrightness',
      {
        'max' => '1000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'integer'
      },
      'Parity',
      {
        'max' => '2',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'integer'
      },
      'Reboot',
      {
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'Size',
      {
        'default' => '20x4',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Speed',
      {
        'type' => 'leaf',
        'upstream_default' => '9600,legal:1200,2400,9600,19200,115200',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::NoritakeVFD'
  }
]
;
