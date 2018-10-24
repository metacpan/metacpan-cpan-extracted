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
      'MergedFB',
      {
        'description' => 'This enables merged framebuffer mode.  In this mode you have a single  shared  framebuffer  with  two  viewports looking into it.  It is similar to Xinerama, but has some advantages.  It is faster than Xinerama, the DRI works on both heads, and it supports clone modes.',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'SWcursor',
      {
        'choice' => [
          'on',
          'off'
        ],
        'description' => 'Selects software cursor.',
        'type' => 'leaf',
        'upstream_default' => 'off',
        'value_type' => 'enum'
      },
      'NoAccel',
      {
        'choice' => [
          'on',
          'off'
        ],
        'description' => 'Enables or disables all hardware acceleration.',
        'type' => 'leaf',
        'upstream_default' => 'on',
        'value_type' => 'enum'
      },
      'Dac6Bit',
      {
        'choice' => [
          'on',
          'off'
        ],
        'description' => '
           Enables or disables the use of 6 bits per color component when in 8
           bpp mode (emulates VGA mode). By default, all 8 bits per color
           component are used. The default is: "off".',
        'type' => 'leaf',
        'upstream_default' => 'off',
        'value_type' => 'enum'
      },
      'VideoKey',
      {
        'description' => 'This overrides the default pixel value for the YUV video overlay key.
              The default value is 0x1E.
',
        'type' => 'leaf',
        'upstream_default' => '0x1E',
        'value_type' => 'uniline'
      },
      'ScalerWidth',
      {
        'description' => "This  sets the overlay scaler buffer width. Accepted values range from 1024 to 2048, divisible
              by 64, values other than 1536 and 1920 may not make sense though. Should be set automatically,
              but  noone  has  a  clue what the limit is for which chip. If you think quality is not optimal
              when playing back HD video (with horizontal resolution larger  than  this  setting),  increase
              this  value, if you get an empty area at the right (usually pink), decrease it. Note this only
              affects the \"true\" overlay via xv, it won\x{2019}t affect things like textured video.
              The default value is either 1536 (for most chips) or 1920.
",
        'max' => '2048',
        'min' => '1024',
        'type' => 'leaf',
        'value_type' => 'integer'
      },
      'AccelMethod',
      {
        'choice' => [
          'EXA',
          'XAA'
        ],
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'Monitor-DVI-0',
      {
        'refer_to' => '! Monitor',
        'type' => 'leaf',
        'value_type' => 'reference'
      },
      'Monitor-LVDS',
      {
        'refer_to' => '! Monitor',
        'type' => 'leaf',
        'value_type' => 'reference'
      },
      'IgnoreEDID',
      {
        'choice' => [
          'off',
          'on'
        ],
        'description' => 'Do not use EDID data for mode validation, but DDC is still used for monitor detection. This is different from Option "NoDDC". The default is: "off". If the server is ignoring your modlines, set this option to "on" and try again.',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'PanelSize',
      {
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'Xorg::Device::Radeon'
  }
]
;

