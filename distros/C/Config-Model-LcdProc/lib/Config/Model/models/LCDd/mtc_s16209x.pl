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
      'Brightness',
      {
        'description' => 'Set the initial brightness ',
        'max' => '255',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '255',
        'value_type' => 'integer'
      },
      'Device',
      {
        'description' => 'Select the output device to use ',
        'type' => 'leaf',
        'upstream_default' => '/dev/lcd',
        'value_type' => 'uniline'
      },
      'Reboot',
      {
        'description' => 'Reinitialize the LCD\'s BIOS ',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      }
    ],
    'name' => 'LCDd::mtc_s16209x'
  }
]
;

