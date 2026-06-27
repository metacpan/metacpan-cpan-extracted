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
      'Device' => 'device to use ',
      'OffBrightness' => 'Set the initial off-brightness 
This value is used when the display is normally
switched off in case LCDd is inactive',
      'Size' => 'display size '
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
        'upstream_default' => '/dev/ttyS1',
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
      'Size',
      {
        'type' => 'leaf',
        'upstream_default' => '16x2',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::MD8800'
  }
]
;
