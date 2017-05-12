#
# This file is part of Config-Model-Xorg
#
# This software is Copyright (c) 2007-2016 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
[
  {
    'element' => [
      'Device',
      {
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Protocol',
      {
        'choice' => [
          'auto',
          'PS/2',
          'ImPS/2',
          'IntelliMouse'
        ],
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'Emulate3Buttons',
      {
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'ZAxisMapping',
      {
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SendCoreEvents',
      {
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'Buttons',
      {
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'Xorg::InputDevice::MouseOpt'
  }
]
;

