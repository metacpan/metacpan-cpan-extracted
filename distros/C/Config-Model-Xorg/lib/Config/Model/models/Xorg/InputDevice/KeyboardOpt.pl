#
# This file is part of Config-Model-Xorg
#
# This software is Copyright (c) 2007-2018 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
[
  {
    'element' => [
      'delay',
      {
        'description' => 'time in milliseconds before a key starts repeating',
        'type' => 'leaf',
        'upstream_default' => '500',
        'value_type' => 'integer'
      },
      'rate',
      {
        'description' => 'number of times a key repeats per second',
        'type' => 'leaf',
        'upstream_default' => '30',
        'value_type' => 'integer'
      }
    ],
    'name' => 'Xorg::InputDevice::KeyboardOpt::AutoRepeat'
  },
  {
    'element' => [
      'Protocol',
      {
        'choice' => [
          'Standard',
          'Xqueue'
        ],
        'description' => 'Specify the keyboard protocol. Not all protocols are supported on all platforms.',
        'type' => 'leaf',
        'upstream_default' => 'Standard',
        'value_type' => 'enum'
      },
      'AutoRepeat',
      {
        'config_class_name' => 'Xorg::InputDevice::KeyboardOpt::AutoRepeat',
        'description' => 'sets the auto repeat behaviour for the keyboard. This is not implemented on all platforms.',
        'type' => 'node'
      },
      'XLeds',
      {
        'cargo' => {
          'max' => 3,
          'min' => 1,
          'type' => 'leaf',
          'value_type' => 'integer'
        },
        'description' => 'makes the keyboard LEDs specified available for client  use instead of their traditional function (Scroll Lock, Caps Lock and Num Lock). The numbers are in the range 1 to 3.',
        'type' => 'list'
      },
      'XkbDisable',
      {
        'status' => 'deprecated',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      }
    ],
    'include' => [
      'Xorg::InputDevice::KeyboardOptRules'
    ],
    'name' => 'Xorg::InputDevice::KeyboardOpt'
  }
]
;


