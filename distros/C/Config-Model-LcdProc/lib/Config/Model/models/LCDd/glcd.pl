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
      'Brightness' => 'Set brightness of the backlight if the backlight is switched \'on\'.',
      'CellSize' => 'Width and height of a character cell in pixels. This value is only used if
the driver has been compiled with FreeType and it is enabled. Otherwise the
default 6x8 cell is used.',
      'ConnectionType' => 'Select what type of connection. See documentation for types.',
      'Contrast' => 'Set the initial contrast if supported by connection type.',
      'KeyMap_A' => 'Assign key strings to keys. There may be up to 16 keys numbered \'A\' to \'Z\'.
By default keys \'A\' to \'F\' are assigned Up, Down, Left, Right, Enter, Escape.',
      'KeyRepeatDelay' => 'Time (ms) from first key report to first repeat. Set to 0 to disable repeated
key reports. ',
      'KeyRepeatInterval' => 'Time (ms) between repeated key reports. Ignored if KeyRepeatDelay is disabled
(set to zero). ',
      'OffBrightness' => 'Set brightness of the backlight if the backlight is switched \'off\'. Set this
to zero to completely turn off the backlight. ',
      'Port' => '--- t6963 options ---
Parallel port to use 
legal: 0x200-0x400 ',
      'Size' => 'Width and height of the display in pixel. The supported sizes may depend on
the ConnectionType. 
legal: 1x1-640x480 ',
      'bidirectional' => 'Use LPT port in bi-directional mode. This should work on most LPT port
and is required for proper timing! ',
      'delayBus' => 'Insert additional delays into reads / writes. ',
      'fontHasIcons' => 'Some fonts miss the Unicode characters used to represent icons. In this case
the built-in 5x8 font can used if this option is turned off. ',
      'normal_font' => 'Path to font file to use for FreeType rendering. This font must be monospace
and should contain some special Unicode characters like arrows (Andale Mono
is recommended and can be fetched at http://corefonts.sf.net).',
      'picolcdgfx_Inverted' => 'Inverted: Inverts the pixels. ',
      'picolcdgfx_KeyTimeout' => '--- picolcdgfx options ---
Time in ms for usb_read to wait on a key press. ',
      'serdisp_device' => 'The display device to use, e.g. serraw:/dev/ttyS0,
parport:/dev/parport0 or USB:07c0/1501.',
      'serdisp_name' => '--- serdisplib options ---
Name of the underlying serdisplib driver, e.g. ctinclud. See
serdisplib documentation for details.',
      'serdisp_options' => 'Options string to pass to serdisplib during initialization. Use
this to set any display related options (e.g. wiring). The display size is
always set based on the Size configured above! By default, no options are
set.
Important: The value must be quoted as it contains equal signs!',
      'useFT2' => 'If LCDproc has been compiled with FreeType 2 support this option can be used
to turn if off intentionally. ',
      'x11_BacklightColor' => 'BacklightColor: The color of the backlight as full brightness.',
      'x11_Border' => 'Border: Adds a border (empty space) around the LCD portion of X11 window.',
      'x11_Inverted' => 'Inverted: inverts the pixels ',
      'x11_PixelColor' => 'Colors are in RRGGBB format prefixed with "0x".
PixelColor: The color of each dot at full contrast. ',
      'x11_PixelSize' => '--- x11 options ---
PixelSize is size of each dot in pixels + a pixel gap. '
    },
    'element' => [
      'Brightness',
      {
        'max' => '1000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '800',
        'value_type' => 'integer'
      },
      'CellSize',
      {
        'type' => 'leaf',
        'upstream_default' => '12x16',
        'value_type' => 'uniline'
      },
      'ConnectionType',
      {
        'default' => 't6963',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Contrast',
      {
        'max' => '1000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '600',
        'value_type' => 'integer'
      },
      'KeyMap_A',
      {
        'default' => 'Up',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'KeyMap_B',
      {
        'default' => 'Down',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'KeyMap_C',
      {
        'default' => 'Enter',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'KeyMap_D',
      {
        'default' => 'Escape',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'KeyRepeatDelay',
      {
        'max' => '3000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '500',
        'value_type' => 'integer'
      },
      'KeyRepeatInterval',
      {
        'max' => '3000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '300',
        'value_type' => 'integer'
      },
      'OffBrightness',
      {
        'max' => '1000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '100',
        'value_type' => 'integer'
      },
      'Port',
      {
        'type' => 'leaf',
        'upstream_default' => '0x378',
        'value_type' => 'uniline'
      },
      'Size',
      {
        'type' => 'leaf',
        'upstream_default' => '128x64',
        'value_type' => 'uniline'
      },
      'bidirectional',
      {
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'delayBus',
      {
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'fontHasIcons',
      {
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'normal_font',
      {
        'type' => 'leaf',
        'upstream_default' => '/usr/local/lib/X11/fonts/TTF/andalemo.ttf',
        'value_type' => 'uniline'
      },
      'picolcdgfx_Inverted',
      {
        'choice' => [
          'yesorno'
        ],
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'enum'
      },
      'picolcdgfx_KeyTimeout',
      {
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '125',
        'value_type' => 'integer'
      },
      'serdisp_device',
      {
        'default' => '/dev/ppi0',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'serdisp_name',
      {
        'default' => 't6963',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'serdisp_options',
      {
        'type' => 'leaf',
        'upstream_default' => 'INVERT=1',
        'value_type' => 'uniline'
      },
      'useFT2',
      {
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'x11_BacklightColor',
      {
        'type' => 'leaf',
        'upstream_default' => '0x80FF80',
        'value_type' => 'uniline'
      },
      'x11_Border',
      {
        'type' => 'leaf',
        'upstream_default' => '20',
        'value_type' => 'uniline'
      },
      'x11_Inverted',
      {
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'x11_PixelColor',
      {
        'type' => 'leaf',
        'upstream_default' => '0x000000',
        'value_type' => 'uniline'
      },
      'x11_PixelSize',
      {
        'type' => 'leaf',
        'upstream_default' => '3+1',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::glcd'
  }
]
;
