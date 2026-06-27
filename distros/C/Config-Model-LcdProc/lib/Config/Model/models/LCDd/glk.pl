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
      'Contrast' => 'set the initial contrast value ',
      'Device' => 'select the serial device to use ',
      'Speed' => 'set the serial port speed '
    },
    'element' => [
      'Contrast',
      {
        'max' => '1000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '560',
        'value_type' => 'integer'
      },
      'Device',
      {
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
        'type' => 'leaf',
        'upstream_default' => '19200',
        'value_type' => 'enum'
      }
    ],
    'name' => 'LCDd::glk'
  }
]
;
