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
      'Device',
      {
        'description' => 'Select the output device to use ',
        'type' => 'leaf',
        'upstream_default' => '/dev/lcd',
        'value_type' => 'uniline'
      },
      'Keypad',
      {
        'default' => 'yes',
        'description' => 'If you have a keypad connected. Keypad layout is currently not
configureable from the config file.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Model',
      {
        'choice' => [
          '12232',
          '12832',
          '1602'
        ],
        'description' => 'Select the LCD model ',
        'type' => 'leaf',
        'upstream_default' => '12232',
        'value_type' => 'enum'
      },
      'Reboot',
      {
        'description' => 'Reinitialize the LCD\'s BIOS 
normally you shouldn\'t need this',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'Size',
      {
        'default' => '20x4',
        'description' => 'Select the LCD size. Default depends on model:
12232: 20x4
12832: 21x4
1602: 16x2',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Speed',
      {
        'choice' => [
          '9600',
          '19200'
        ],
        'description' => 'Set the communication speed ',
        'type' => 'leaf',
        'upstream_default' => '19200',
        'value_type' => 'enum'
      },
      'keypad_test_mode',
      {
        'description' => 'If you have a non-standard keypad you can associate any keystrings to keys.
There are 6 input keys in the CwLnx hardware that generate characters
from \'A\' to \'F\'.

The following is the built-in default mapping hardcoded in the driver.
You can leave those unchanged if you have a standard keypad.
You can change it if you want to report other keystrings or have a non
standard keypad.
KeyMap_A=Up
KeyMap_B=Down
KeyMap_C=Left
KeyMap_D=Right
KeyMap_E=Enter
KeyMap_F=Escape
keypad_test_mode permits one to test keypad assignment
Default value is no',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::CwLnx'
  }
]
;

