#
# This file is part of Config-Model-Itself
#
# This software is Copyright (c) 2007-2019 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
use strict;
use warnings;

return [
  {
    'element' => [
      'type',
      {
        'choice' => [
          'node',
          'warped_node',
          'leaf',
          'check_list'
        ],
        'description' => 'specify the type of the cargo.',
        'mandatory' => 1,
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'warp',
      {
        'description' => 'change the properties (i.e. default value or its value_type) dynamically according to the value of another Value object locate elsewhere in the configuration tree. ',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'elt_type' => '- type'
          },
          'rules' => [
            '$elt_type ne "node"',
            {
              'config_class_name' => 'Itself::WarpValue',
              'level' => 'normal'
            }
          ]
        }
      }
    ],
    'include' => [
      'Itself::NonWarpableElement',
      'Itself::WarpableCargoElement'
    ],
    'include_after' => 'type',
    'name' => 'Itself::CargoElement'
  }
]
;

