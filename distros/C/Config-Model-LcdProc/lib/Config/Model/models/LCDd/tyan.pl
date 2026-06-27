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
      'Size' => 'set display size ',
      'Speed' => 'Set the communication speed '
    },
    'element' => [
      'Device',
      {
        'type' => 'leaf',
        'upstream_default' => '/dev/lcd',
        'value_type' => 'uniline'
      },
      'Size',
      {
        'type' => 'leaf',
        'upstream_default' => '16x2',
        'value_type' => 'uniline'
      },
      'Speed',
      {
        'choice' => [
          '4800',
          '9600'
        ],
        'type' => 'leaf',
        'upstream_default' => '9600',
        'value_type' => 'enum'
      }
    ],
    'name' => 'LCDd::tyan'
  }
]
;
