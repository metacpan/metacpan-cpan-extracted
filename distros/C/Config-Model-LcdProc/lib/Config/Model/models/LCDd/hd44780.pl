#
# This file is part of Config-Model-LcdProc
#
# This software is Copyright (c) 2013-2016 by Dominique Dumont.
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
        'default' => 'no',
        'description' => 'If you have a switchable backlight.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Brightness',
      {
        'description' => 'Set brightness of the backlight (lcd2usb and usb4all):
Brightness is the brightness while the backlight is set to \'on\'.',
        'max' => '1000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '800',
        'value_type' => 'integer'
      },
      'CharMap',
      {
        'choice' => [
          'hd44780_default',
          'hd44780_euro',
          'ea_ks0073',
          'sed1278f_0b',
          'hd44780_koi8_r',
          'hd44780_cp1251',
          'hd44780_8859_5',
          'upd16314'
        ],
        'description' => 'Character map to to map ISO-8859-1 to the LCD\'s character set

(hd44780_koi8_r, hd44780_cp1251, hd44780_8859_5 and upd16314 are possible if
compiled with additional charmaps)',
        'type' => 'leaf',
        'upstream_default' => 'hd44780_default',
        'value_type' => 'enum'
      },
      'ConnectionType',
      {
        'default' => '4bit',
        'description' => 'Select what type of connection. See documentation for available types.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Contrast',
      {
        'description' => 'Set the initial contrast (bwctusb, lcd2usb, and usb4all)',
        'max' => '1000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '800',
        'value_type' => 'integer'
      },
      'DelayBus',
      {
        'default' => 'true',
        'description' => 'You can reduce the inserted delays by setting this to false.
On fast PCs it is possible your LCD does not respond correctly.
Default: true.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'DelayMult',
      {
        'description' => 'If your display is slow and cannot keep up with the flow of data from
LCDd, garbage can appear on the LCDd. Set this delay factor to 2 or 4
to increase the delays. Default: 1.',
        'type' => 'leaf',
        'upstream_default' => '2',
        'value_type' => 'uniline'
      },
      'Device',
      {
        'description' => 'Device of the serial, I2C, or SPI interface ',
        'type' => 'leaf',
        'upstream_default' => '/dev/lcd',
        'value_type' => 'uniline'
      },
      'ExtendedMode',
      {
        'description' => 'If you have an HD66712, a KS0073 or another controller with \'extended mode\',
set this flag to get into 4-line mode. On displays with just two lines, do
not set this flag.
As an additional restriction, controllers with and without extended mode
AND 4 lines cannot be mixed for those connection types that support more
than one display!',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'uniline'
      },
      'KeepAliveDisplay',
      {
        'description' => 'Some displays (e.g. vdr-wakeup) need a message from the driver to that it
is still alive. When set to a value bigger then null the character in the
upper left corner is updated every <KeepAliveDisplay> seconds. Default: 0.',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'uniline'
      },
      'KeyMatrix_4_1',
      {
        'default' => 'Enter',
        'description' => 'If you have a keypad you can assign keystrings to the keys.
See documentation for used terms and how to wire it.
For example to give directly connected key 4 the string "Enter", use:
  KeyDirect_4=Enter
For matrix keys use the X and Y coordinates of the key:
  KeyMatrix_1_3=Enter',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'KeyMatrix_4_2',
      {
        'default' => 'Up',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'KeyMatrix_4_3',
      {
        'default' => 'Down',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'KeyMatrix_4_4',
      {
        'default' => 'Escape',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Keypad',
      {
        'default' => 'no',
        'description' => 'If you have a keypad connected.
You may also need to configure the keypad layout further on in this file.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Lastline',
      {
        'description' => 'Specifies if the last line is pixel addressable (yes) or it controls an
underline effect (no). ',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'LineAddress',
      {
        'description' => 'In extended mode, on some controllers like the ST7036 (in 3 line mode)
the next line in DDRAM won\'t start 0x20 higher. ',
        'type' => 'leaf',
        'upstream_default' => '0x20',
        'value_type' => 'uniline'
      },
      'OffBrightness',
      {
        'description' => 'OffBrightness is the brightness while the backlight is set to \'off\'.',
        'max' => '1000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '300',
        'value_type' => 'integer'
      },
      'OutputPort',
      {
        'default' => 'no',
        'description' => 'If you have the additional output port ("bargraph") and you want to
be able to control it with the lcdproc OUTPUT command',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Port',
      {
        'default' => '0x378',
        'description' => 'I/O address of the LPT port. Usual values are: 0x278, 0x378 and 0x3BC.
For I2C connections this sets the slave address (usually 0x20).',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RefreshDisplay',
      {
        'description' => 'If you experience occasional garbage on your display you can use this
option as workaround. If set to a value bigger than null it forces a
full screen refresh <RefreshDiplay> seconds. Default: 0.',
        'type' => 'leaf',
        'upstream_default' => '5',
        'value_type' => 'uniline'
      },
      'Size',
      {
        'default' => '20x4',
        'description' => 'Specifies the size of the LCD.
In case of multiple combined displays, this should be the total size.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Speed',
      {
        'default' => '0',
        'description' => 'Bitrate of the serial port (0 for interface default)',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'vspan',
      {
        'description' => 'For multiple combined displays: how many lines does each display have.
Vspan=2,2 means both displays have 2 lines.',
        'type' => 'leaf',
        'upstream_default' => '2,2',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::hd44780'
  }
]
;

