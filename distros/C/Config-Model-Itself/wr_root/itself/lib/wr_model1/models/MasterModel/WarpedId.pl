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
      'X',
      {
        'choice' => [
          'Av',
          'Bv',
          'Cv'
        ],
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'Y',
      {
        'choice' => [
          'Av',
          'Bv',
          'Cv'
        ],
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'Z',
      {
        'choice' => [
          'Av',
          'Bv',
          'Cv'
        ],
        'type' => 'leaf',
        'value_type' => 'enum'
      }
    ],
    'name' => 'MasterModel::WarpedIdSlave'
  },
  {
    'element' => [
      'macro',
      {
        'choice' => [
          'A',
          'B',
          'C'
        ],
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'version',
      {
        'default' => 1,
        'type' => 'leaf',
        'value_type' => 'integer'
      },
      'warped_hash',
      {
        'cargo' => {
          'config_class_name' => 'MasterModel::WarpedIdSlave',
          'type' => 'node'
        },
        'index_type' => 'integer',
        'max_nb' => 3,
        'type' => 'hash',
        'warp' => {
          'follow' => {
            'f1' => '- macro'
          },
          'rules' => [
            '$f1 eq \'B\'',
            {
              'max_nb' => 2
            },
            '$f1 eq \'A\'',
            {
              'max_nb' => 1
            }
          ]
        }
      },
      'multi_warp',
      {
        'cargo' => {
          'config_class_name' => 'MasterModel::WarpedIdSlave',
          'type' => 'node'
        },
        'default_keys' => [
          0,
          1,
          2,
          3
        ],
        'index_type' => 'integer',
        'max_index' => 3,
        'min_index' => 0,
        'type' => 'hash',
        'warp' => {
          'follow' => {
            'f0' => '- version',
            'f1' => '- macro'
          },
          'rules' => [
            '$f0 eq \'2\' and $f1 eq \'C\'',
            {
              'default_keys' => [
                0,
                1,
                2,
                3,
                4,
                5,
                6,
                7
              ],
              'max_index' => 7
            },
            '$f0 eq \'2\' and $f1 eq \'A\'',
            {
              'default_keys' => [
                0,
                1,
                2,
                3,
                4,
                5,
                6,
                7
              ],
              'max_index' => 7
            }
          ]
        }
      },
      'hash_with_warped_value',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string',
          'warp' => {
            'follow' => {
              'f1' => '- macro'
            },
            'rules' => [
              '$f1 eq \'A\'',
              {
                'default' => 'dumb string'
              }
            ]
          }
        },
        'index_type' => 'string',
        'level' => 'hidden',
        'type' => 'hash',
        'warp' => {
          'follow' => {
            'f1' => '- macro'
          },
          'rules' => [
            '$f1 eq \'A\'',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'multi_auto_create',
      {
        'auto_create_keys' => [
          0,
          1,
          2,
          3
        ],
        'cargo' => {
          'config_class_name' => 'MasterModel::WarpedIdSlave',
          'type' => 'node'
        },
        'index_type' => 'integer',
        'max_index' => 3,
        'min_index' => 0,
        'type' => 'hash',
        'warp' => {
          'follow' => {
            'f0' => '- version',
            'f1' => '- macro'
          },
          'rules' => [
            '$f0 eq \'2\' and $f1 eq \'C\'',
            {
              'auto_create_keys' => [
                0,
                1,
                2,
                3,
                4,
                5,
                6,
                7
              ],
              'max_index' => 7
            },
            '$f0 eq \'2\' and $f1 eq \'A\'',
            {
              'auto_create_keys' => [
                0,
                1,
                2,
                3,
                4,
                5,
                6,
                7
              ],
              'max_index' => 7
            }
          ]
        }
      }
    ],
    'name' => 'MasterModel::WarpedId'
  }
]
;


