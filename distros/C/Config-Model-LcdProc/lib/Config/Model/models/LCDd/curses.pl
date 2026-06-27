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
      'Background' => 'background color when "backlight" is off ',
      'Backlight' => 'background color when "backlight" is on ',
      'DrawBorder' => 'draw Border ',
      'Foreground' => 'color settings
foreground color ',
      'Size' => 'display size ',
      'TopLeftX' => 'What position (X,Y) to start the left top corner at...
Default: (7,7)',
      'UseACS' => 'use ASC symbols for icons & bars '
    },
    'element' => [
      'Background',
      {
        'type' => 'leaf',
        'upstream_default' => 'cyan',
        'value_type' => 'uniline'
      },
      'Backlight',
      {
        'type' => 'leaf',
        'upstream_default' => 'red',
        'value_type' => 'uniline'
      },
      'DrawBorder',
      {
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'Foreground',
      {
        'type' => 'leaf',
        'upstream_default' => 'blue',
        'value_type' => 'uniline'
      },
      'Size',
      {
        'type' => 'leaf',
        'upstream_default' => '20x4',
        'value_type' => 'uniline'
      },
      'TopLeftX',
      {
        'default' => '7',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'TopLeftY',
      '*TopLeftX',
      'UseACS',
      {
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      }
    ],
    'name' => 'LCDd::curses'
  }
]
;
