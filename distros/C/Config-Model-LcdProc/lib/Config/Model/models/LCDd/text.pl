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
      'Size',
      {
        'description' => 'Set the display size ',
        'type' => 'leaf',
        'upstream_default' => '20x4',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::text'
  }
]
;

