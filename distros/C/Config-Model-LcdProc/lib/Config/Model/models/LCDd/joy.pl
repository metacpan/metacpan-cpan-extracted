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
      'Device' => 'Select the input device to use ',
      'Map_Axis1neg' => 'set the axis map',
      'Map_Button1' => 'set the button map'
    },
    'element' => [
      'Device',
      {
        'type' => 'leaf',
        'upstream_default' => '/dev/js0',
        'value_type' => 'uniline'
      },
      'Map_Axis1neg',
      {
        'default' => 'Left',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Map_Axis1pos',
      {
        'default' => 'Right',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Map_Axis2neg',
      {
        'default' => 'Up',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Map_Axis2pos',
      {
        'default' => 'Down',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Map_Button1',
      {
        'default' => 'Enter',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Map_Button2',
      {
        'default' => 'Escape',
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::joy'
  }
]
;
