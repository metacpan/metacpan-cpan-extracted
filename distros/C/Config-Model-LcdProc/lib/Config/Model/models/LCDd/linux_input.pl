#
# This file is part of Config-Model-LcdProc
#
# This software is Copyright (c) 2013-2017 by Dominique Dumont.
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
        'description' => 'Select the input device to use ',
        'type' => 'leaf',
        'upstream_default' => '/dev/input/event0',
        'value_type' => 'uniline'
      },
      'key',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'type' => 'list'
      }
    ],
    'name' => 'LCDd::linux_input'
  }
]
;

