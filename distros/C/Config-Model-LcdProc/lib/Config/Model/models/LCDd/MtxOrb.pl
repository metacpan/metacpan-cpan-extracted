#
# This file is part of Config-Model-LcdProc
#
# This software is Copyright (c) 2013-2021 by Dominique Dumont.
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
      'Brightness',
      {
        'description' => 'Set the initial brightness ',
        'max' => '1000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '1000',
        'value_type' => 'integer'
      },
      'Contrast',
      {
        'description' => 'Set the initial contrast 
NOTE: The driver will ignore this if the display
      is a vfd or vkd as they don\'t have this feature',
        'type' => 'leaf',
        'upstream_default' => '480',
        'value_type' => 'uniline'
      },
      'Device',
      {
        'description' => 'Select the output device to use ',
        'type' => 'leaf',
        'upstream_default' => '/dev/lcd',
        'value_type' => 'uniline'
      },
      'KeyMap_A',
      {
        'description' => 'The following table translates from MtxOrb key letters to logical key names.
By default no keys are mapped, meaning the keypad is not used at all.',
        'type' => 'leaf',
        'upstream_default' => 'Left',
        'value_type' => 'uniline'
      },
      'KeyMap_B',
      {
        'type' => 'leaf',
        'upstream_default' => 'Right',
        'value_type' => 'uniline'
      },
      'KeyMap_C',
      {
        'type' => 'leaf',
        'upstream_default' => 'Up',
        'value_type' => 'uniline'
      },
      'KeyMap_D',
      {
        'type' => 'leaf',
        'upstream_default' => 'Down',
        'value_type' => 'uniline'
      },
      'KeyMap_E',
      {
        'type' => 'leaf',
        'upstream_default' => 'Enter',
        'value_type' => 'uniline'
      },
      'KeyMap_F',
      {
        'type' => 'leaf',
        'upstream_default' => 'Escape',
        'value_type' => 'uniline'
      },
      'OffBrightness',
      {
        'description' => 'Set the initial off-brightness 
This value is used when the display is normally
switched off in case LCDd is inactive',
        'max' => '1000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'integer'
      },
      'Size',
      {
        'description' => 'Set the display size ',
        'type' => 'leaf',
        'upstream_default' => '20x4',
        'value_type' => 'uniline'
      },
      'Speed',
      {
        'choice' => [
          '1200',
          '2400',
          '9600',
          '19200'
        ],
        'description' => 'Set the communication speed ',
        'type' => 'leaf',
        'upstream_default' => '19200',
        'value_type' => 'enum'
      },
      'Type',
      {
        'choice' => [
          'lcd',
          'lkd',
          'vfd',
          'vkd'
        ],
        'description' => 'Set the display type ',
        'type' => 'leaf',
        'upstream_default' => 'lcd',
        'value_type' => 'enum'
      },
      'hasAdjustableBacklight',
      {
        'description' => 'Some old displays do not have an adjustable backlight but only can
switch the backlight on/off. If you experience randomly appearing block
characters, try setting this to false. ',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'keypad_test_mode',
      {
        'default' => 'no',
        'description' => 'See the [menu] section for an explanation of the key mappings
You can find out which key of your display sends which
character by setting keypad_test_mode to yes and running
LCDd. LCDd will output all characters it receives.
Afterwards you can modify the settings above and set
keypad_set_mode to no again.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::MtxOrb'
  }
]
;

