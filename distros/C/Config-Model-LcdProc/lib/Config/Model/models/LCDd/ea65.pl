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
      'Brightness' => 'Device is fixed /dev/ttyS1
Width and Height are fixed 9x1
As the VFD is self luminescent we don\'t have a backlight
But we can use the backlight functions to control the front LEDs
Brightness 0 to 299 -> LEDs off
Brightness 300 to 699 -> LEDs half bright
Brightness 700 to 1000 -> LEDs full bright',
      'OffBrightness' => 'OffBrightness is the the value used for the \'backlight off\' state'
    },
    'element' => [
      'Brightness',
      {
        'default' => '500',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'OffBrightness',
      {
        'default' => '0',
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::ea65'
  }
]
;
