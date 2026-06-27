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
      'Device' => 'Select the output device to use ',
      'Keypad' => 'If you have a keypad connected. Keypad layout is currently not
configureable from the config file.',
      'Model' => 'Select the LCD model ',
      'Reboot' => 'Reinitialize the LCD\'s BIOS 
normally you shouldn\'t need this',
      'Size' => 'Select the LCD size. Default depends on model:
12232: 20x4
12832: 21x4
1602: 16x2',
      'Speed' => 'Set the communication speed ',
      'keypad_test_mode' => 'If you have a non-standard keypad you can associate any keystrings to keys.
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
Default value is no'
    },
    'element' => [
      'Device',
      {
        'type' => 'leaf',
        'upstream_default' => '/dev/lcd',
        'value_type' => 'uniline'
      },
      'Keypad',
      {
        'default' => 'yes',
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
        'type' => 'leaf',
        'upstream_default' => '12232',
        'value_type' => 'enum'
      },
      'Reboot',
      {
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
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Speed',
      {
        'choice' => [
          '9600',
          '19200'
        ],
        'type' => 'leaf',
        'upstream_default' => '19200',
        'value_type' => 'enum'
      },
      'keypad_test_mode',
      {
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::CwLnx'
  }
]
;
