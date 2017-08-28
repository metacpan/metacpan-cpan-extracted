#
# This file is part of Config-Model-LcdProc
#
# This software is Copyright (c) 2013-2017 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
[
  {
    'class_description' => 'generated from LCDd.conf',
    'element' => [
      'Backlight',
      {
        'description' => 'Switch on the backlight? ',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'uniline'
      },
      'Cursor',
      {
        'description' => 'Switch on the cursor? ',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'uniline'
      },
      'Device',
      {
        'description' => 'Select the output device to use 
Device=/dev/cua01',
        'type' => 'leaf',
        'upstream_default' => '/dev/ttyS1',
        'value_type' => 'uniline'
      },
      'DownKey',
      {
        'default' => 'B',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'EscapeKey',
      {
        'default' => 'P',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LeftKey',
      {
        'default' => 'D',
        'description' => 'Enter Key is a \\r character, so it\'s hardcoded in the driver',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RightKey',
      {
        'default' => 'C',
        'type' => 'leaf',
        'value_type' => 'uniline'
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
      'UpKey',
      {
        'default' => 'A',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'keypad_test_mode',
      {
        'default' => 'no',
        'description' => 'You can find out which key of your display sends which
character by setting keypad_test_mode to yes and running
LCDd. LCDd will output all characters it receives.
Afterwards you can modify the settings above and set
keypad_set_mode to no again.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::EyeboxOne'
  }
]
;

