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
      'Backlight' => 'Sets the initial state of the backlight upon start-up.',
      'Brightness' => 'Set the initial brightness . Works only
with the 20x4 device',
      'Contrast' => 'Set the initial contrast ',
      'Key0Light' => 'If Keylights is on, the you can unlight specific keys below:
Key0 is the directional pad.  Key1 - Key5 correspond to the F1 - F5 keys.
There is no LED for the +/- keys.  This is a handy way to indicate to users
which keys are disabled.  ',
      'KeyRepeatDelay' => 'Key auto repeat is only available if the picoLCD driver is built with
libusb-1.0. Use KeyRepeatDelay and KeyRepeatInterval to configure key auto
repeat.

Key auto repeat delay (time in ms from first key report to first repeat). Use
zero to disable auto repeat. ',
      'KeyRepeatInterval' => 'Key auto repeat interval (time in ms between repeat reports). Only used if
KeyRepeatDelay is not zero. ',
      'KeyTimeout' => 'KeyTimeout is only used if the picoLCD driver is built with libusb-0.1. When
built with libusb-1.0 key and IR data is input asynchronously so there is no
need to wait for the USB data.
KeyTimeout is the time in ms that LCDd spends waiting for a key press before
cycling through other duties.  Higher values make LCDd use less CPU time and
make key presses more detectable.  Lower values make LCDd more responsive
but a little prone to missing key presses.  500 (.5 second) is the default
and a balanced value. ',
      'Keylights' => 'Light the keys? ',
      'LinkLights' => 'Link the key lights to the backlight? ',
      'LircFlushThreshold' => 'Threshold in microseconds of the gap that triggers flushing the IR data
to lirc 
If LircTime_us is on values greater than 32.767ms will disable the flush
If LircTime_us is off values greater than 1.999938s will disable the flush',
      'LircHost' => 'Host name or IP address of the LIRC instance that is to receive IR codes
If not set, or set to an empty value, IR support is disabled.',
      'LircPort' => 'UDP port on which LIRC is listening ',
      'LircTime_us' => 'UDP data time unit for LIRC  
On:  times sent in microseconds (requires LIRC UDP driver that accepts this).
Off: times sent in \'jiffies\' (1/16384s) (supported by standard LIRC UDP driver).',
      'OffBrightness' => 'Set the brightness while the backlight is \'off\' .
Works only with the 20x4 device.'
    },
    'element' => [
      'Backlight',
      {
        'type' => 'leaf',
        'upstream_default' => 'on',
        'value_type' => 'boolean',
        'write_as' => [
          'off',
          'on'
        ]
      },
      'Brightness',
      {
        'max' => '1000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '1000',
        'value_type' => 'integer'
      },
      'Contrast',
      '*Brightness',
      'Key0Light',
      {
        'type' => 'leaf',
        'upstream_default' => 'on',
        'value_type' => 'boolean',
        'write_as' => [
          'off',
          'on'
        ]
      },
      'Key1Light',
      {
        'default' => 'on',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Key2Light',
      '*Key1Light',
      'Key3Light',
      '*Key1Light',
      'Key4Light',
      '*Key1Light',
      'Key5Light',
      '*Key1Light',
      'KeyRepeatDelay',
      {
        'max' => '3000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '300',
        'value_type' => 'integer'
      },
      'KeyRepeatInterval',
      {
        'max' => '3000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '200',
        'value_type' => 'integer'
      },
      'KeyTimeout',
      {
        'max' => '1000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '500',
        'value_type' => 'integer'
      },
      'Keylights',
      {
        'type' => 'leaf',
        'upstream_default' => 'on',
        'value_type' => 'boolean',
        'write_as' => [
          'off',
          'on'
        ]
      },
      'LinkLights',
      '*Keylights',
      'LircFlushThreshold',
      {
        'min' => '1000',
        'type' => 'leaf',
        'upstream_default' => '8000',
        'value_type' => 'integer'
      },
      'LircHost',
      {
        'type' => 'leaf',
        'upstream_default' => '127.0.0.1',
        'value_type' => 'uniline'
      },
      'LircPort',
      {
        'max' => '65535',
        'min' => '1',
        'type' => 'leaf',
        'upstream_default' => '8765',
        'value_type' => 'integer'
      },
      'LircTime_us',
      {
        'type' => 'leaf',
        'upstream_default' => 'off',
        'value_type' => 'boolean',
        'write_as' => [
          'off',
          'on'
        ]
      },
      'OffBrightness',
      {
        'max' => '1000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'integer'
      }
    ],
    'name' => 'LCDd::picolcd'
  }
]
;
