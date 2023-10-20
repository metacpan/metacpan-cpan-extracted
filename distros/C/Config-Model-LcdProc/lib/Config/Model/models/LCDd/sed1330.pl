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
      'CellSize',
      {
        'description' => 'Width x Height of a character cell in pixels legal: 6x7-8x16 ',
        'type' => 'leaf',
        'upstream_default' => '6x10',
        'value_type' => 'uniline'
      },
      'ConnectionType',
      {
        'choice' => [
          'classic',
          'bitshaker'
        ],
        'description' => 'Select what type of connection ',
        'type' => 'leaf',
        'upstream_default' => 'classic',
        'value_type' => 'enum'
      },
      'Port',
      {
        'default' => '0x378',
        'description' => 'Port where the LPT is. Common values are 0x278, 0x378 and 0x3BC',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Type',
      {
        'default' => 'G321D',
        'description' => 'Type of LCD module (legal: G321D, G121C, G242C, G191D, G2446, SP14Q002)
Note: Currently only tested with G321D & SP14Q002.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::sed1330'
  }
]
;

