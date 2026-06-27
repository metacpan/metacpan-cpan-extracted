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
      'Font' => 'X font to use, in XLFD format, as given by "xfontsel"',
      'Offset' => 'Offset in pixels from the top-left corner of the monitor ',
      'Size' => 'set display size '
    },
    'element' => [
      'Font',
      {
        'default' => '-*-terminus-*-r-*-*-*-320-*-*-*-*-*',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Offset',
      {
        'type' => 'leaf',
        'upstream_default' => '0x0',
        'value_type' => 'uniline'
      },
      'Size',
      {
        'type' => 'leaf',
        'upstream_default' => '20x4',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::xosd'
  }
]
;
