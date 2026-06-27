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
      'Contrast' => 'Set the initial contrast ',
      'Device' => 'Port the device is connected to  (by default first USB serial port)',
      'Edition' => 'Edition level of the device (can be 1, 2 or 3) ',
      'OffBrightness' => 'Set the initial off-brightness 
This value is used when the display is normally
switched off in case LCDd is inactive',
      'Size' => 'set display size
Note: The size can be obtained directly from device for edition 2 & 3.'
    },
    'element' => [
      'Brightness',
      {
        'max' => '1000',
        'min' => '1',
        'type' => 'leaf',
        'upstream_default' => '480',
        'value_type' => 'integer'
      },
      'Contrast',
      {
        'max' => '1000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '480',
        'value_type' => 'integer'
      },
      'Device',
      {
        'default' => '/dev/ttyUSB0',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Edition',
      {
        'type' => 'leaf',
        'upstream_default' => '2',
        'value_type' => 'uniline'
      },
      'OffBrightness',
      {
        'max' => '1000',
        'min' => '1',
        'type' => 'leaf',
        'upstream_default' => '100',
        'value_type' => 'integer'
      },
      'Size',
      {
        'type' => 'leaf',
        'upstream_default' => '16x2',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::SureElec'
  }
]
;
