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
      'Device' => 'Select the output device to use ',
      'Size' => 'Specifies the size of the LCD. If this driver is loaded as a secondary driver
it always adopts to the size of the primary driver. If loaded as the only
(or primary) driver, the size can be set. ',
      'Speed' => 'Serial port baudrate ',
      'UpdateRate' => 'How often to dump the LCD contents out the port, in Hertz (times per second)
1 = once per second, 4 is 4 times per second, 0.1 is once every 10 seconds.'
    },
    'element' => [
      'Device',
      {
        'type' => 'leaf',
        'upstream_default' => '/dev/cuaU0',
        'value_type' => 'uniline'
      },
      'Size',
      {
        'type' => 'leaf',
        'upstream_default' => '40x4',
        'value_type' => 'uniline'
      },
      'Speed',
      {
        'type' => 'leaf',
        'upstream_default' => '9600',
        'value_type' => 'uniline'
      },
      'UpdateRate',
      {
        'max' => '10',
        'min' => '0.0005',
        'type' => 'leaf',
        'upstream_default' => '1',
        'value_type' => 'number'
      }
    ],
    'name' => 'LCDd::rawserial'
  }
]
;
