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
      'Screen',
      {
        'auto_create_ids' => 1,
        'cargo' => {
          'config_class_name' => 'Xorg::ServerLayout::Screen',
          'type' => 'node'
        },
        'description' => 'One of these entries must be given for each screen
              being used in a session.  The screen-id field is
              mandatory, and specifies the Screen section being
              referenced. ',
        'type' => 'list'
      },
      'InputDevice',
      {
        'allow_keys_from' => '! InputDevice',
        'cargo' => {
          'config_class_name' => 'Xorg::ServerLayout::InputDevice',
          'type' => 'node'
        },
        'default_keys' => [
          'kbd',
          'mouse'
        ],
        'description' => 'One of these entries should be given for each
      input device being used in a session.  Normally at least two are
      required, one each for the core pointer and keyboard devices.',
        'index_type' => 'string',
        'type' => 'hash'
      }
    ],
    'name' => 'Xorg::ServerLayout'
  },
  {
    'element' => [
      'screen_id',
      {
        'refer_to' => '! Screen',
        'type' => 'leaf',
        'value_type' => 'reference'
      },
      'position',
      {
        'config_class_name' => 'Xorg::ServerLayout::ScreenPosition',
        'type' => 'node'
      }
    ],
    'name' => 'Xorg::ServerLayout::Screen'
  },
  {
    'element' => [
      'relative_screen_location',
      {
        'choice' => [
          'Absolute',
          'RightOf',
          'LeftOf',
          'Above',
          'Below',
          'Relative'
        ],
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'screen_id',
      {
        'level' => 'hidden',
        'refer_to' => '! Screen',
        'type' => 'leaf',
        'value_type' => 'reference',
        'warp' => {
          'follow' => {
            'f1' => '- relative_screen_location'
          },
          'rules' => [
            '$f1 eq \'RightOf\' or $f1 eq \'LeftOf\' or $f1 eq \'Above\' or $f1 eq \'Below\' or $f1 eq \'Relative\'',
            {
              'level' => 'normal',
              'mandatory' => 1
            }
          ]
        }
      },
      'x',
      {
        'level' => 'hidden',
        'type' => 'leaf',
        'value_type' => 'integer',
        'warp' => {
          'follow' => {
            'f1' => '- relative_screen_location'
          },
          'rules' => [
            '$f1 eq \'Absolute\' or $f1 eq \'Relative\'',
            {
              'level' => 'normal',
              'mandatory' => 1
            }
          ]
        }
      },
      'y',
      {
        'level' => 'hidden',
        'type' => 'leaf',
        'value_type' => 'integer',
        'warp' => {
          'follow' => {
            'f1' => '- relative_screen_location'
          },
          'rules' => [
            '$f1 eq \'Absolute\' or $f1 eq \'Relative\'',
            {
              'level' => 'normal',
              'mandatory' => 1
            }
          ]
        }
      }
    ],
    'name' => 'Xorg::ServerLayout::ScreenPosition'
  },
  {
    'class_description' => 'Specifies InputDevice options',
    'element' => [
      'SendCoreEvents',
      {
        'type' => 'leaf',
        'value_type' => 'boolean'
      }
    ],
    'name' => 'Xorg::ServerLayout::InputDevice'
  }
]
;




