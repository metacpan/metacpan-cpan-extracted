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
      'VendorName',
      {
        'description' => 'optional entry for the monitor\'s manufacturer',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'ModelName',
      {
        'description' => 'optional entry for the monitor\'s manufacturer',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'HorizSync',
      {
        'description' => 'gives the range(s) of horizontal sync
              frequencies supported by the monitor.  horizsync-range
              may be a comma separated list of either discrete values
              or ranges of values.  A range of values is two values
              separated by a dash.  By default the values are in units
              of kHz.  They may be specified in MHz or Hz if MHz or Hz
              is added to the end of the line.  The data given here is
              used by the Xorg server to determine if video modes are
              within the spec- ifications of the monitor.  This
              information should be available in the monitor\'s
              handbook.  If this entry is omitted, a default range of
              28-33kHz is used.',
        'type' => 'leaf',
        'upstream_default' => '28-33kHz',
        'value_type' => 'uniline'
      },
      'VertRefresh',
      {
        'description' => 'gives the range(s) of vertical refresh
              frequencies supported by the monitor.  vertrefresh-range
              may be a comma separated list of either discrete values
              or ranges of values.  A range of values is two values
              separated by a dash.  By default the values are in units
              of Hz.  They may be specified in MHz or kHz if MHz or
              kHz is added to the end of the line.  The data given
              here is used by the Xorg server to determine if video
              modes are within the spec- ifications of the monitor.
              This information should be available in the monitor\'s
              handbook.  If this entry is omitted, a default range of
              43-72Hz is used.',
        'type' => 'leaf',
        'upstream_default' => '43-72Hz',
        'value_type' => 'uniline'
      },
      'DisplaySize',
      {
        'config_class_name' => 'Xorg::Monitor::DisplaySize',
        'description' => 'This optional entry gives the width and
              height, in millimetres, of the picture area of the
              monitor.  If given, this is used to calculate the
              horizontal and vertical pitch (DPI) of the screen.',
        'type' => 'node'
      },
      'Gamma',
      {
        'config_class_name' => 'Xorg::Monitor::Gamma',
        'type' => 'node'
      },
      'UseModes',
      {
        'description' => 'Include the set of modes listed in the Modes
              section.  This make all of the modes defined in that
              section available for use by this monitor.',
        'refer_to' => '! Modes ',
        'type' => 'leaf',
        'value_type' => 'reference'
      },
      'Mode',
      {
        'cargo' => {
          'config_class_name' => 'Xorg::Monitor::Mode',
          'type' => 'node'
        },
        'index_type' => 'string',
        'type' => 'hash'
      },
      'Option',
      {
        'config_class_name' => 'Xorg::Monitor::Option',
        'type' => 'node'
      }
    ],
    'name' => 'Xorg::Monitor'
  },
  {
    'element' => [
      'width',
      {
        'description' => 'in millimeters',
        'type' => 'leaf',
        'value_type' => 'integer'
      },
      'height',
      {
        'description' => 'in millimeters',
        'type' => 'leaf',
        'value_type' => 'integer'
      }
    ],
    'name' => 'Xorg::Monitor::DisplaySize'
  },
  {
    'element' => [
      'use_global_gamma',
      {
        'default' => 1,
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'gamma',
      {
        'level' => 'hidden',
        'type' => 'leaf',
        'upstream_default' => 1,
        'value_type' => 'number',
        'warp' => {
          'follow' => {
            'f1' => '- use_global_gamma'
          },
          'rules' => [
            '$f1 eq \'1\'',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'red_gamma',
      {
        'level' => 'hidden',
        'type' => 'leaf',
        'upstream_default' => 1,
        'value_type' => 'number',
        'warp' => {
          'follow' => {
            'f1' => '- use_global_gamma'
          },
          'rules' => [
            '$f1 eq \'0\'',
            {
              'level' => 'normal',
              'mandatory' => 1
            }
          ]
        }
      },
      'green_gamma',
      {
        'level' => 'hidden',
        'type' => 'leaf',
        'upstream_default' => 1,
        'value_type' => 'number',
        'warp' => {
          'follow' => {
            'f1' => '- use_global_gamma'
          },
          'rules' => [
            '$f1 eq \'0\'',
            {
              'level' => 'normal',
              'mandatory' => 1
            }
          ]
        }
      },
      'blue_gamma',
      {
        'level' => 'hidden',
        'type' => 'leaf',
        'upstream_default' => 1,
        'value_type' => 'number',
        'warp' => {
          'follow' => {
            'f1' => '- use_global_gamma'
          },
          'rules' => [
            '$f1 eq \'0\'',
            {
              'level' => 'normal',
              'mandatory' => 1
            }
          ]
        }
      }
    ],
    'name' => 'Xorg::Monitor::Gamma'
  }
]
;



