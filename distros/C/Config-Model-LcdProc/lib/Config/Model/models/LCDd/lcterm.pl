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

