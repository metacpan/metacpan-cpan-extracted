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
      'Size',
      {
        'default' => '20x4',
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::yard2LCD'
  }
]
;

