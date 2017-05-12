#
# This file is part of Config-Model-LcdProc
#
# This software is Copyright (c) 2013-2016 by Dominique Dumont.
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
        'description' => 'Select the input device to use ',
        'type' => 'leaf',
        'upstream_default' => '/dev/js0',
        'value_type' => 'uniline'
      },
      'Map_Axis1neg',
      {
        'default' => 'Left',
        'description' => 'set the axis map',
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
        'description' => 'set the button map',
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

