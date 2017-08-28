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
        'default' => '/dev/ttyS1',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Size',
      {
        'default' => '16x2',
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::lcterm'
  }
]
;

