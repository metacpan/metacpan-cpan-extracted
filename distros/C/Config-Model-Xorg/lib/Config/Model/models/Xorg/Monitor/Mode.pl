#
# This file is part of Config-Model-Xorg
#
# This software is Copyright (c) 2007-2018 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
[
  {
    'element' => [
      'disp',
      {
        'type' => 'leaf',
        'value_type' => 'integer'
      },
      'syncstart',
      {
        'type' => 'leaf',
        'value_type' => 'integer'
      },
      'syncend',
      {
        'type' => 'leaf',
        'value_type' => 'integer'
      },
      'total',
      {
        'type' => 'leaf',
        'value_type' => 'integer'
      }
    ],
    'name' => 'Xorg::Monitor::Mode::Timing'
  },
  {
    'element' => [
      'Interlace',
      {
        'description' => 'be used to specify composite sync on hardware
      where this is supported.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'DoubleScan',
      {
        'description' => 'be used to specify composite sync on hardware
      where this is supported.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'Composite',
      {
        'description' => 'be used to specify composite sync on hardware
      where this is supported.',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean'
      },
      'HSyncPolarity',
      {
        'choice' => [
          'positive',
          'negative'
        ],
        'description' => 'used to select the polarity of the VSync signal.',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'VSyncPolarity',
      {
        'choice' => [
          'positive',
          'negative'
        ],
        'description' => 'used to select the polarity of the VSync signal.',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'CSyncPolarity',
      {
        'choice' => [
          'positive',
          'negative'
        ],
        'description' => 'used to select the polarity of the VSync signal.',
        'type' => 'leaf',
        'value_type' => 'enum'
      }
    ],
    'name' => 'Xorg::Monitor::Mode::Flags'
  },
  {
    'element' => [
      'DotClock',
      {
        'description' => 'is the dot (pixel) clock rate to be used for the
      mode.',
        'type' => 'leaf',
        'value_type' => 'number'
      },
      'HTimings',
      {
        'config_class_name' => 'Xorg::Monitor::Mode::Timing',
        'type' => 'node'
      },
      'VTimings',
      {
        'config_class_name' => 'Xorg::Monitor::Mode::Timing',
        'type' => 'node'
      },
      'Flags',
      {
        'config_class_name' => 'Xorg::Monitor::Mode::Flags',
        'type' => 'node'
      },
      'HSkew',
      {
        'description' => 'specifies the number of pixels (towards the right
      edge of the screen) by which the display enable signal is to be
      skewed.  Not all drivers use this information.  This option
      might become necessary to override the default value supplied by
      the server (if any).  "Roving" horizontal lines indicate this
      value needs to be increased.  If the last few pixels on a scan
      line appear on the left of the screen, this value should be
      decreased.',
        'type' => 'leaf',
        'value_type' => 'number'
      },
      'VScan',
      {
        'description' => 'specifies the number of pixels (towards the right
      edge of the screen) by which the display enable signal is to be
      skewed.  Not all drivers use this information.  This option
      might become necessary to override the default value supplied by
      the server (if any).  "Roving" horizontal lines indicate this
      value needs to be increased.  If the last few pixels on a scan
      line appear on the left of the screen, this value should be
      decreased.',
        'type' => 'leaf',
        'value_type' => 'number'
      }
    ],
    'name' => 'Xorg::Monitor::Mode'
  }
]
;



