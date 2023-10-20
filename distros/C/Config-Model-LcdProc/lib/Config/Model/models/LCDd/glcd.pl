#
# This file is part of Config-Model-LcdProc
#
# This software is Copyright (c) 2013-2023 by Dominique Dumont.
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
        'description' => 'Set brightness of the backlight if the backlight is switched \'on\'.',
        'max' => '1000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '800',
        'value_type' => 'integer'
      },
      'CellSize',
      {
        'description' => 'Width and height of a character cell in pixels. This value is only used if
the driver has been compiled with FreeType and it is enabled. Otherwise the
default 6x8 cell is used.',
        'type' => 'leaf',
        'upstream_default' => '12x16',
        'value_type' => 'uniline'
      },
      'ConnectionType',
      {
        'default' => 't6963',
        'description' => 'Select what type of connection. See documentation for types.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Contrast',
      {
        'description' => 'Set the initial contrast if supported by connection type.',
        'max' => '1000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '600',
        'value_type' => 'integer'
      },
      'KeyMap_A',
      {
        'default' => 'Up',
        'description' => 'Assign key strings to keys. There may be up to 16 keys numbered \'A\' to \'Z\'.
By default keys \'A\' to \'F\' are assigned Up, Down, Left, Right, Enter, Escape.',
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
        'description' => 'Time (ms) from first key report to first repeat. Set to 0 to disable repeated
key reports. ',
        'max' => '3000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '500',
        'value_type' => 'integer'
      },
      'KeyRepeatInterval',
      {
        'description' => 'Time (ms) between repeated key reports. Ignored if KeyRepeatDelay is disabled
(set to zero). ',
        'max' => '3000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '300',
        'value_type' => 'integer'
      },
      'OffBrightness',
      {
        'description' => 'Set brightness of the backlight if the backlight is switched \'off\'. Set this
to zero to completely turn off the backlight. ',
        'max' => '1000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '100',
        'value_type' => 'integer'
      },
      'Port',
      {
        'description' => '--- t6963 options ---
Parallel port to use 
legal: 0x200-0x400 ',
        'type' => 'leaf',
        'upstream_default' => '0x378',
        'value_type' => 'uniline'
      },
      'Size',
      {
        'description' => 'Width and height of the display in pixel. The supported sizes may depend on
the ConnectionType. 
legal: 1x1-640x480 ',
        'type' => 'leaf',
        'upstream_default' => '128x64',
        'value_type' => 'uniline'
      },
      'bidirectional',
      {
        'description' => 'Use LPT port in bi-directional mode. This should work on most LPT port
and is required for proper timing! ',
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
        'description' => 'Insert additional delays into reads / writes. ',
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
        'description' => 'Some fonts miss the Unicode characters used to represent icons. In this case
the built-in 5x8 font can used if this option is turned off. ',
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
        'description' => 'Path to font file to use for FreeType rendering. This font must be monospace
and should contain some special Unicode characters like arrows (Andale Mono
is recommended and can be fetched at http://corefonts.sf.net).',
        'type' => 'leaf',
        'upstream_default' => '/usr/local/lib/X11/fonts/TTF/andalemo.ttf',
        'value_type' => 'uniline'
      },
      'picolcdgfx_Inverted',
      {
        'choice' => [
          'yesorno'
        ],
        'description' => 'Inverted: Inverts the pixels. ',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'enum'
      },
      'picolcdgfx_KeyTimeout',
      {
        'description' => '--- picolcdgfx options ---
Time in ms for usb_read to wait on a key press. ',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '125',
        'value_type' => 'integer'
      },
      'serdisp_device',
      {
        'default' => '/dev/ppi0',
        'description' => 'The display device to use, e.g. serraw:/dev/ttyS0,
parport:/dev/parport0 or USB:07c0/1501.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'serdisp_name',
      {
        'default' => 't6963',
        'description' => '--- serdisplib options ---
Name of the underlying serdisplib driver, e.g. ctinclud. See
serdisplib documentation for details.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'serdisp_options',
      {
        'description' => 'Options string to pass to serdisplib during initialization. Use
this to set any display related options (e.g. wiring). The display size is
always set based on the Size configured above! By default, no options are
set.
Important: The value must be quoted as it contains equal signs!',
        'type' => 'leaf',
        'upstream_default' => 'INVERT=1',
        'value_type' => 'uniline'
      },
      'useFT2',
      {
        'description' => 'If LCDproc has been compiled with FreeType 2 support this option can be used
to turn if off intentionally. ',
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
        'description' => 'BacklightColor: The color of the backlight as full brightness.',
        'type' => 'leaf',
        'upstream_default' => '0x80FF80',
        'value_type' => 'uniline'
      },
      'x11_Border',
      {
        'description' => 'Border: Adds a border (empty space) around the LCD portion of X11 window.',
        'type' => 'leaf',
        'upstream_default' => '20',
        'value_type' => 'uniline'
      },
      'x11_Inverted',
      {
        'description' => 'Inverted: inverts the pixels ',
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
        'description' => 'Colors are in RRGGBB format prefixed with "0x".
PixelColor: The color of each dot at full contrast. ',
        'type' => 'leaf',
        'upstream_default' => '0x000000',
        'value_type' => 'uniline'
      },
      'x11_PixelSize',
      {
        'description' => '--- x11 options ---
PixelSize is size of each dot in pixels + a pixel gap. ',
        'type' => 'leaf',
        'upstream_default' => '3+1',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::glcd'
  }
]
;

