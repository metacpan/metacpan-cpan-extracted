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
      'Backlight' => 'Switch on the backlight? ',
      'Cursor' => 'Switch on the cursor? ',
      'Device' => 'Select the output device to use 
Device=/dev/cua01',
      'LeftKey' => 'Enter Key is a \\r character, so it\'s hardcoded in the driver',
      'Size' => 'Set the display size ',
      'Speed' => 'Set the communication speed ',
      'keypad_test_mode' => 'You can find out which key of your display sends which
character by setting keypad_test_mode to yes and running
LCDd. LCDd will output all characters it receives.
Afterwards you can modify the settings above and set
keypad_set_mode to no again.'
    },
    'element' => [
      'Backlight',
      {
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'uniline'
      },
      'Cursor',
      {
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'uniline'
      },
      'Device',
      {
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
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::EyeboxOne'
  }
]
;
