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
      'Background',
      {
        'description' => 'background color when "backlight" is off ',
        'type' => 'leaf',
        'upstream_default' => 'cyan',
        'value_type' => 'uniline'
      },
      'Backlight',
      {
        'description' => 'background color when "backlight" is on ',
        'type' => 'leaf',
        'upstream_default' => 'red',
        'value_type' => 'uniline'
      },
      'DrawBorder',
      {
        'description' => 'draw Border ',
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
        'description' => 'color settings
foreground color ',
        'type' => 'leaf',
        'upstream_default' => 'blue',
        'value_type' => 'uniline'
      },
      'Size',
      {
        'description' => 'display size ',
        'type' => 'leaf',
        'upstream_default' => '20x4',
        'value_type' => 'uniline'
      },
      'TopLeftX',
      {
        'default' => '7',
        'description' => 'What position (X,Y) to start the left top corner at...
Default: (7,7)',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'TopLeftY',
      {
        'default' => '7',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'UseACS',
      {
        'description' => 'use ASC symbols for icons & bars ',
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

