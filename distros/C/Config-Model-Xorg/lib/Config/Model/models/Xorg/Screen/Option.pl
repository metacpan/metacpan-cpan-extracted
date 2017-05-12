#
# This file is part of Config-Model-Xorg
#
# This software is Copyright (c) 2007-2016 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
[
  {
    'element' => [
      'Accel',
      {
        'description' => 'Enables XAA (X Acceleration Architecture), a mechanism that makes video cards\' 2D hardware acceleration available to the __xservername__ server. This option is on by default, but it may be necessary to turn it off if there are bugs in the driver. There are many options to disable specific accelerated operations, listed below.  Note that disabling an operation will have no effect if the operation is not accelerated (whether due to lack of support in the hardware or in the driver).',
        'type' => 'leaf',
        'upstream_default' => 1,
        'value_type' => 'boolean'
      },
      'InitPrimary',
      {
        'description' => 'Disables accelerated dashed line draws between two arbitrary points.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'NoInt10',
      {
        'description' => 'Disables accelerated dashed line draws between two arbitrary points.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'NoMTRR',
      {
        'description' => 'Disables accelerated dashed line draws between two arbitrary points.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'XaaNoCPUToScreenColorExpandFill',
      {
        'description' => 'Disables accelerated dashed line draws between two arbitrary points.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'XaaNoColor8x8PatternFillRect',
      {
        'description' => 'Disables accelerated dashed line draws between two arbitrary points.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'XaaNoColor8x8PatternFillTrap',
      {
        'description' => 'Disables accelerated dashed line draws between two arbitrary points.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'XaaNoDashedBresenhamLine',
      {
        'description' => 'Disables accelerated dashed line draws between two arbitrary points.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'XaaNoDashedTwoPointLine',
      {
        'description' => 'Disables accelerated dashed line draws between two arbitrary points.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'XaaNoImageWriteRect',
      {
        'description' => 'Disables accelerated dashed line draws between two arbitrary points.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'XaaNoMono8x8PatternFillRect',
      {
        'description' => 'Disables accelerated dashed line draws between two arbitrary points.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'XaaNoMono8x8PatternFillTrap',
      {
        'description' => 'Disables accelerated dashed line draws between two arbitrary points.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'XaaNoOffscreenPixmaps',
      {
        'description' => 'Disables accelerated dashed line draws between two arbitrary points.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'XaaNoPixmapCache',
      {
        'description' => 'Disables accelerated dashed line draws between two arbitrary points.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'XaaNoScanlineCPUToScreenColorExpandFill',
      {
        'description' => 'Disables accelerated dashed line draws between two arbitrary points.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'XaaNoScanlineImageWriteRect',
      {
        'description' => 'Disables accelerated dashed line draws between two arbitrary points.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'XaaNoScreenToScreenColorExpandFill',
      {
        'description' => 'Disables accelerated dashed line draws between two arbitrary points.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'XaaNoScreenToScreenCopy',
      {
        'description' => 'Disables accelerated dashed line draws between two arbitrary points.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'XaaNoSolidBresenhamLine',
      {
        'description' => 'Disables accelerated dashed line draws between two arbitrary points.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'XaaNoSolidFillRect',
      {
        'description' => 'Disables accelerated dashed line draws between two arbitrary points.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'XaaNoSolidFillTrap',
      {
        'description' => 'Disables accelerated dashed line draws between two arbitrary points.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'XaaNoSolidHorVertLine',
      {
        'description' => 'Disables accelerated dashed line draws between two arbitrary points.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'XaaNoSolidTwoPointLine',
      {
        'description' => 'Disables accelerated dashed line draws between two arbitrary points.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'BiosLocation',
      {
        'description' => 'Set the location of the BIOS for the Int10 module. One may select a BIOS of another card for posting or the legacy V_BIOS range located at 0xc0000 or an alterna- tive address (BUS_ISA). This is only useful under very special circumstances and should be used with extreme care.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'Xorg::Screen::Option'
  }
]
;

