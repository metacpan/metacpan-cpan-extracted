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
      'Backlight' => 'Does the device have a backlight? ',
      'Hostname' => 'IRTrans device to connect to ',
      'Size' => 'display dimensions'
    },
    'element' => [
      'Backlight',
      {
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'Hostname',
      {
        'type' => 'leaf',
        'upstream_default' => 'localhost',
        'value_type' => 'uniline'
      },
      'Size',
      {
        'default' => '16x2',
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::irtrans'
  }
]
;
