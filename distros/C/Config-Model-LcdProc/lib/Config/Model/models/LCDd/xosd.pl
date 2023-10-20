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
      'Font',
      {
        'default' => '-*-terminus-*-r-*-*-*-320-*-*-*-*-*',
        'description' => 'X font to use, in XLFD format, as given by "xfontsel"',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Offset',
      {
        'description' => 'Offset in pixels from the top-left corner of the monitor ',
        'type' => 'leaf',
        'upstream_default' => '0x0',
        'value_type' => 'uniline'
      },
      'Size',
      {
        'description' => 'set display size ',
        'type' => 'leaf',
        'upstream_default' => '20x4',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::xosd'
  }
]
;

