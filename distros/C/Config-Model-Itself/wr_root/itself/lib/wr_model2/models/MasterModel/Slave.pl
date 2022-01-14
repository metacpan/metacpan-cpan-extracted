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
        'value_type' => 'enum',
        'warp' => {
          'follow' => {
            'f1' => '- - macro'
          },
          'rules' => [
            '$f1 eq \'B\'',
            {
              'default' => 'Bv'
            },
            '$f1 eq \'A\'',
            {
              'default' => 'Av'
            }
          ]
        }
      },
      'Y',
      {
        'choice' => [
          'Av',
          'Bv',
          'Cv'
        ],
        'type' => 'leaf',
        'value_type' => 'enum',
        'warp' => {
          'follow' => {
            'f1' => '- - macro'
          },
          'rules' => [
            '$f1 eq \'B\'',
            {
              'default' => 'Bv'
            },
            '$f1 eq \'A\'',
            {
              'default' => 'Av'
            }
          ]
        }
      },
      'Z',
      {
        'choice' => [
          'Av',
          'Bv',
          'Cv'
        ],
        'type' => 'leaf',
        'value_type' => 'enum',
        'warp' => {
          'follow' => {
            'f1' => '- - macro'
          },
          'rules' => [
            '$f1 eq \'B\'',
            {
              'default' => 'Bv'
            },
            '$f1 eq \'A\'',
            {
              'default' => 'Av'
            }
          ]
        }
      },
      'recursive_slave',
      {
        'cargo' => {
          'config_class_name' => 'MasterModel::RSlave',
          'type' => 'node'
        },
        'index_type' => 'string',
        'type' => 'hash'
      },
      'W',
      {
        'level' => 'hidden',
        'type' => 'leaf',
        'value_type' => 'enum',
        'warp' => {
          'follow' => {
            'f1' => '- - macro'
          },
          'rules' => [
            '$f1 eq \'B\'',
            {
              'choice' => [
                'Av',
                'Bv',
                'Cv'
              ],
              'default' => 'Bv',
              'level' => 'normal'
            },
            '$f1 eq \'A\'',
            {
              'choice' => [
                'Av',
                'Bv',
                'Cv'
              ],
              'default' => 'Av',
              'level' => 'normal'
            }
          ]
        }
      },
      'Comp',
      {
        'compute' => {
          'formula' => 'macro is $m',
          'variables' => {
            'm' => '- - macro'
          }
        },
        'type' => 'leaf',
        'value_type' => 'string'
      }
    ],
    'name' => 'MasterModel::Slave'
  }
]
;

