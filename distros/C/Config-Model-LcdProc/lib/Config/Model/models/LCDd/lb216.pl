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
      'Device' => 'Select the output device to use ',
      'Reboot' => 'Reinitialize the LCD\'s BIOS ',
      'Speed' => 'Set the communication speed '
    },
    'element' => [
      'Brightness',
      {
        'max' => '255',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '255',
        'value_type' => 'integer'
      },
      'Device',
      {
        'type' => 'leaf',
        'upstream_default' => '/dev/lcd',
        'value_type' => 'uniline'
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
      'Speed',
      {
        'choice' => [
          '2400',
          '9600'
        ],
        'type' => 'leaf',
        'upstream_default' => '9600',
        'value_type' => 'enum'
      }
    ],
    'name' => 'LCDd::lb216'
  }
]
;
