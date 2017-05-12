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
      'FontPath',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'path name for the RGB color database',
        'type' => 'list'
      },
      'RGBPath',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'path name for the RGB color database',
        'type' => 'list'
      },
      'ModulePath',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'path name for the RGB color database',
        'type' => 'list'
      }
    ],
    'name' => 'Xorg::Files'
  }
]
;

