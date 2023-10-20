#
# This file is part of Config-Model-LcdProc
#
# This software is Copyright (c) 2013-2023 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
use strict;
use warnings;

return [
  {
    'class_description' => 'generated from LCDd.conf',
    'element' => [
      'Contrast',
      {
        'description' => 'set the initial contrast value ',
        'max' => '1000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '560',
        'value_type' => 'integer'
      },
      'Device',
      {
        'description' => 'select the serial device to use ',
        'type' => 'leaf',
        'upstream_default' => '/dev/lcd',
        'value_type' => 'uniline'
      },
      'Speed',
      {
        'choice' => [
          '9600',
          '19200',
          '38400'
        ],
        'description' => 'set the serial port speed ',
        'type' => 'leaf',
        'upstream_default' => '19200',
        'value_type' => 'enum'
      }
    ],
    'name' => 'LCDd::glk'
  }
]
;

