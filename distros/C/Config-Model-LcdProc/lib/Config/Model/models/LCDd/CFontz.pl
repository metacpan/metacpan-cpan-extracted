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
        'description' => 'Set the initial contrast ',
        'max' => '1000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '560',
        'value_type' => 'integer'
      },
      'Device',
      {
        'description' => 'Select the output device to use ',
        'type' => 'leaf',
        'upstream_default' => '/dev/lcd',
        'value_type' => 'uniline'
      },
      'NewFirmware',
      {
        'description' => 'Set the firmware version (New means >= 2.0) ',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
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
        'description' => 'Select the LCD size ',
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
          '19200',
          '115200'
        ],
        'description' => 'Set the communication speed ',
        'type' => 'leaf',
        'upstream_default' => '9600',
        'value_type' => 'enum'
      }
    ],
    'name' => 'LCDd::CFontz'
  }
]
;

