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
      'level',
      {
        'choice' => [
          'important',
          'normal',
          'hidden'
        ],
        'description' => 'Used to highlight important parameter or to hide others. Hidden parameter are mostly used to hide features that are unavailable at start time. They can be made available later using warp mechanism',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'index_type',
      {
        'description' => 'Specify the type of allowed index for the hash. "String" means no restriction.',
        'level' => 'hidden',
        'type' => 'leaf',
        'value_type' => 'enum',
        'warp' => {
          'follow' => {
            'f1' => '?type'
          },
          'rules' => [
            '$f1 eq \'hash\'',
            {
              'choice' => [
                'string',
                'integer'
              ],
              'level' => 'important'
            }
          ]
        }
      }
    ],
    'include' => [
      'Itself::WarpableElement'
    ],
    'name' => 'Itself::WarpOnlyElement'
  }
]
;

