#
# This file is part of Config-Model-LcdProc
#
# This software is Copyright (c) 2013-2016 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
[
  {
    'class_description' => 'generated from LCDd.conf',
    'element' => [
      'Device',
      {
        'description' => 'Select the output device to use ',
        'type' => 'leaf',
        'upstream_default' => '/dev/cuaU0',
        'value_type' => 'uniline'
      },
      'Size',
      {
        'description' => 'Specifies the size of the LCD. If this driver is loaded as a secondary driver
it always adopts to the size of the primary driver. If loaded as the only
(or primary) driver, the size can be set. ',
        'type' => 'leaf',
        'upstream_default' => '40x4',
        'value_type' => 'uniline'
      },
      'Speed',
      {
        'description' => 'Serial port baudrate ',
        'type' => 'leaf',
        'upstream_default' => '9600',
        'value_type' => 'uniline'
      },
      'UpdateRate',
      {
        'description' => 'How often to dump the LCD contents out the port, in Hertz (times per second)
1 = once per second, 4 is 4 times per second, 0.1 is once every 10 seconds.',
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

