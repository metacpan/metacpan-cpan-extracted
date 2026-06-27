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
      'Brightness' => 'Set the initial brightness ',
      'Contrast' => 'Set the initial contrast ',
      'Device' => 'Select the output device to use ',
      'Model' => 'Select the LCD model ',
      'OffBrightness' => 'Set the initial off-brightness 
This value is used when the display is normally
switched off in case LCDd is inactive',
      'OldFirmware' => 'Very old 633 firmware versions do not support partial screen updates using
\'Send Data to LCD\' command (31). For those devices it may be necessary to
enable this flag. ',
      'Reboot' => 'Reinitialize the LCD\'s BIOS on driver start. ',
      'Size' => 'Override the LCD size known for the selected model. Usually setting this
value should not be necessary.',
      'Speed' => 'Override the default communication speed known for the selected model.
Default value depends on model ',
      'USB' => 'Enable the USB flag if the device is connected to an USB port. For
serial ports leave it disabled. '
    },
    'element' => [
      'Brightness',
      {
        'max' => '1000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '1000',
        'value_type' => 'integer'
      },
      'Contrast',
      {
        'max' => '1000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '560',
        'value_type' => 'integer'
      },
      'Device',
      {
        'type' => 'leaf',
        'upstream_default' => '/dev/lcd',
        'value_type' => 'uniline'
      },
      'Model',
      {
        'choice' => [
          '533',
          '631',
          '633',
          '635'
        ],
        'type' => 'leaf',
        'upstream_default' => '633',
        'value_type' => 'enum'
      },
      'OffBrightness',
      {
        'max' => '1000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'integer'
      },
      'OldFirmware',
      {
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'Reboot',
      '*OldFirmware',
      'Size',
      {
        'type' => 'leaf',
        'upstream_default' => '20x4',
        'value_type' => 'uniline'
      },
      'Speed',
      {
        'choice' => [
          '19200',
          '115200'
        ],
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'USB',
      {
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      }
    ],
    'name' => 'LCDd::CFontzPacket'
  }
]
;
