#
# This file is part of Config-Model-LcdProc
#
# This software is Copyright (c) 2013-2021 by Dominique Dumont.
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
      'Backlight',
      {
        'description' => 'Does the device have a backlight? ',
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
        'description' => 'IRTrans device to connect to ',
        'type' => 'leaf',
        'upstream_default' => 'localhost',
        'value_type' => 'uniline'
      },
      'Size',
      {
        'default' => '16x2',
        'description' => 'display dimensions',
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::irtrans'
  }
]
;

