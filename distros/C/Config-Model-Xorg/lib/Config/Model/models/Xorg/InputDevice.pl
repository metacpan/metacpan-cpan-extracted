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
      'Driver',
      {
        'choice' => [
          'kbd',
          'mouse'
        ],
        'description' => 'name of the driver to use for this input device',
        'mandatory' => 1,
        'replace' => {
          'keyboard' => 'kbd'
        },
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'SendCoreEvents',
      {
        'description' => 'when enabled cause the input  device  to  always report core events.  This can be used, for example, to allow an additional pointer device  to  generate core pointer events (like moving the cursor, etc).',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'HistorySize',
      {
        'description' => 'when enabled cause the input  device  to  always report core events.  This can be used, for example, to allow an additional pointer device  to  generate core pointer events (like moving the cursor, etc).',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'Option',
      {
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'f1' => '- Driver'
          },
          'rules' => [
            '$f1 eq \'kbd\'',
            {
              'config_class_name' => 'Xorg::InputDevice::KeyboardOpt'
            },
            '$f1 eq \'mouse\'',
            {
              'config_class_name' => 'Xorg::InputDevice::MouseOpt'
            }
          ]
        }
      }
    ],
    'name' => 'Xorg::InputDevice'
  }
]
;

