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
    'class_description' => 'This optional entry specifies the virtual
  screen resolution to be used. xdim must be a multiple of either 8 or
  16 for most drivers, and a multiple of 32 when running in monochrome
  mode.  The given value will be rounded down if this is not the case.
  Video modes which are too large for the specified virtual size will
  be rejected. If this entry is not present, the virtual screen
  resolution will be set to accommodate all the valid video modes
  given in the Modes entry.  Some drivers/hardware combinations do not
  support virtual screens. Refer to the appropriate driver-specific
  documentation for details.',
    'element' => [
      'xdim',
      {
        'description' => 'xdim must be a multiple of either 8 or16 for most drivers, and a multiple of 32 when  running in monochrome mode.',
        'type' => 'leaf',
        'value_type' => 'integer'
      },
      'ydim',
      {
        'description' => 'xdim must be a multiple of either 8 or16 for most drivers, and a multiple of 32 when  running in monochrome mode.',
        'type' => 'leaf',
        'value_type' => 'integer'
      }
    ],
    'name' => 'Xorg::Screen::Display::Virtual'
  },
  {
    'element' => [
      'x0',
      {
        'type' => 'leaf',
        'value_type' => 'integer'
      },
      'y0',
      {
        'type' => 'leaf',
        'value_type' => 'integer'
      }
    ],
    'name' => 'Xorg::Screen::Display::ViewPort'
  },
  {
    'element' => [
      'red',
      {
        'type' => 'leaf',
        'value_type' => 'integer'
      },
      'green',
      {
        'type' => 'leaf',
        'value_type' => 'integer'
      },
      'blue',
      {
        'type' => 'leaf',
        'value_type' => 'integer'
      }
    ],
    'name' => 'Xorg::Screen::Display::Color'
  },
  {
    'element' => [
      'Depth',
      {
        'description' => 'This entry specifies what colour depth the Display subsection  is  to  be  used  for.   This entry is usually specified, but it may be omitted to create a  match-all Display  subsection  or  when  wishing  to  match  only against the FbBpp parameter.  The range of depth values that  are  allowed depends on the driver.  Most drivers support 8, 15, 16 and 24.  Some also support  1  and/or 4,  and some may support other values (like 30).  Note: depth means the number of bits  in  a  pixel  that  are actually used to determine the pixel colour.  32 is not a valid depth value.  Most hardware that uses  32  bits per  pixel  only  uses  24  of  them to hold the colour information, which means that the colour depth  is  24, not 32.',
        'max' => 24,
        'min' => 1,
        'type' => 'leaf',
        'value_type' => 'integer'
      },
      'FbBpp',
      {
        'description' => 'This  entry  specifies the framebuffer format this Display subsection is to be used for.  This entry is  only needed  when  providing  depth  24  configurations that allow a choice between a 24 bpp packed framebuffer format  and  a  32bpp  sparse framebuffer format.  In most cases this entry should not be used.',
        'type' => 'leaf',
        'value_type' => 'integer'
      },
      'Weight',
      {
        'description' => 'This  entry  specifies the framebuffer format this Display subsection is to be used for.  This entry is  only needed  when  providing  depth  24  configurations that allow a choice between a 24 bpp packed framebuffer format  and  a  32bpp  sparse framebuffer format.  In most cases this entry should not be used.',
        'type' => 'leaf',
        'value_type' => 'integer'
      },
      'Virtual',
      {
        'config_class_name' => 'Xorg::Screen::Display::Virtual',
        'description' => 'This optional entry specifies the virtual screen
              resolution to be used.',
        'type' => 'node'
      },
      'ViewPort',
      {
        'config_class_name' => 'Xorg::Screen::Display::ViewPort',
        'description' => 'This  optional  entry sets the upper left corner of the initial display.  This is only relevant when  the  virtual screen resolution is different from the resolution of the initial video mode.  If this entry is not given, then  the  initial display will be centered in the virtual display area.',
        'type' => 'node'
      },
      'Modes',
      {
        'choice' => [
          '1280x1024',
          '1280x800',
          '1024x768',
          '832x624',
          '800x600',
          '720x400',
          '640x480'
        ],
        'computed_refer_to' => {
          'formula' => '! Modes:"$my_monitor_use_modes" + ! Monitor:"$my_monitor" Mode ',
          'variables' => {
            'my_monitor' => '- - Monitor',
            'my_monitor_use_modes' => '! Monitor:"$my_monitor" UseModes'
          }
        },
        'description' => 'This optional entry specifies the list of video
       modes to use.  Each mode-name specified must be in double
       quotes.  They must correspond to those specified or referenced
       in the appropriate Monitor section (includ- ing implicitly
       referenced built-in VESA standard modes).  The server will
       delete modes from this list which don\'t satisfy various
       requirements.  The first valid mode in this list will be the
       default display mode for startup.  The list of valid modes is
       converted internally into a circular list.  It is possible to
       switch to the next mode with Ctrl+Alt+Keypad-Plus and to the
       previous mode with Ctrl+Alt+Keypad-Minus.  When this entry is
       omitted, the valid modes referenced by the appropriate Monitor
       section will be used.  If the Monitor section contains no
       modes, then the selection will be taken from the built-in VESA
       standard modes.',
        'type' => 'check_list'
      },
      'Visual',
      {
        'description' => 'This optional entry sets the default root visual
              type.  This may also be specified from the command line
              (see the Xserver(1) man page). Not all drivers support
              DirectColor at these depths 15 16 24.',
        'type' => 'leaf',
        'value_type' => 'enum',
        'warp' => {
          'follow' => {
            'f1' => '- Depth'
          },
          'rules' => [
            '$f1 eq \'8\'',
            {
              'choice' => [
                'StaticGray',
                'GrayScale',
                'StaticColor',
                'PseudoColor',
                'TrueColor',
                'DirectColor'
              ],
              'upstream_default' => 'PseudoColor'
            },
            '$f1 eq \'1\'',
            {
              'choice' => [
                'StaticGray'
              ],
              'upstream_default' => 'StaticGray'
            },
            '$f1 eq \'4\'',
            {
              'choice' => [
                'StaticGray',
                'GrayScale',
                'StaticColor',
                'PseudoColor'
              ],
              'upstream_default' => 'StaticColor'
            },
            '$f1 eq \'24\'',
            {
              'choice' => [
                'TrueColor',
                'DirectColor'
              ],
              'upstream_default' => 'TrueColor'
            },
            '$f1 eq \'16\'',
            {
              'choice' => [
                'TrueColor',
                'DirectColor'
              ],
              'upstream_default' => 'TrueColor'
            },
            '$f1 eq \'15\'',
            {
              'choice' => [
                'TrueColor',
                'DirectColor'
              ],
              'upstream_default' => 'TrueColor'
            }
          ]
        }
      },
      'Black',
      {
        'description' => '  red green blue
              This  optional  entry  allows  the "black" colour to be
              specified.  This is only supported  at  depth  1.   The
              default is black.',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'f1' => '- Depth'
          },
          'rules' => [
            '$f1 eq \'1\'',
            {
              'config_class_name' => 'Xorg::Screen::Display::Color'
            }
          ]
        }
      },
      'White',
      {
        'description' => '  red green blue
              This  optional  entry  allows  the "black" colour to be
              specified.  This is only supported  at  depth  1.   The
              default is black.',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'f1' => '- Depth'
          },
          'rules' => [
            '$f1 eq \'1\'',
            {
              'config_class_name' => 'Xorg::Screen::Display::Color'
            }
          ]
        }
      }
    ],
    'name' => 'Xorg::Screen::Display'
  }
]
;




