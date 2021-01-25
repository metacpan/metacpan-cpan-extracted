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
      'Model',
      {
        'choice' => [
          '533',
          '631',
          '633',
          '635'
        ],
        'description' => 'Select the LCD model ',
        'type' => 'leaf',
        'upstream_default' => '633',
        'value_type' => 'enum'
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
      'OldFirmware',
      {
        'description' => 'Very old 633 firmware versions do not support partial screen updates using
\'Send Data to LCD\' command (31). For those devices it may be necessary to
enable this flag. ',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'Reboot',
      {
        'description' => 'Reinitialize the LCD\'s BIOS on driver start. ',
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
        'description' => 'Override the LCD size known for the selected model. Usually setting this
value should not be necessary.',
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
        'description' => 'Override the default communication speed known for the selected model.
Default value depends on model ',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'USB',
      {
        'description' => 'Enable the USB flag if the device is connected to an USB port. For
serial ports leave it disabled. ',
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

