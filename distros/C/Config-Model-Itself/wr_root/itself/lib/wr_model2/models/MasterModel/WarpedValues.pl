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
      'get_element',
      {
        'choice' => [
          'm_value_element',
          'compute_element'
        ],
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'where_is_element',
      {
        'choice' => [
          'get_element'
        ],
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'macro',
      {
        'choice' => [
          'A',
          'B',
          'C',
          'D'
        ],
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'macro2',
      {
        'level' => 'hidden',
        'type' => 'leaf',
        'value_type' => 'enum',
        'warp' => {
          'follow' => {
            'f1' => '- macro'
          },
          'rules' => [
            '$f1 eq \'B\'',
            {
              'choice' => [
                'A',
                'B',
                'C',
                'D'
              ],
              'level' => 'normal'
            }
          ]
        }
      },
      'm_value',
      {
        'type' => 'leaf',
        'value_type' => 'enum',
        'warp' => {
          'follow' => {
            'm' => '- macro'
          },
          'rules' => [
            '$m eq "A" or $m eq "D"',
            {
              'choice' => [
                'Av',
                'Bv'
              ],
              'help' => {
                'Av' => 'Av help'
              }
            },
            '$m eq "B"',
            {
              'choice' => [
                'Bv',
                'Cv'
              ],
              'help' => {
                'Bv' => 'Bv help'
              }
            },
            '$m eq "C"',
            {
              'choice' => [
                'Cv'
              ],
              'help' => {
                'Cv' => 'Cv help'
              }
            }
          ]
        }
      },
      'm_value_old',
      {
        'type' => 'leaf',
        'value_type' => 'enum',
        'warp' => {
          'follow' => {
            'f1' => '- macro'
          },
          'rules' => [
            '$f1 eq \'A\' or $f1 eq \'D\'',
            {
              'choice' => [
                'Av',
                'Bv'
              ],
              'help' => {
                'Av' => 'Av help'
              }
            },
            '$f1 eq \'B\'',
            {
              'choice' => [
                'Bv',
                'Cv'
              ],
              'help' => {
                'Bv' => 'Bv help'
              }
            },
            '$f1 eq \'C\'',
            {
              'choice' => [
                'Cv'
              ],
              'help' => {
                'Cv' => 'Cv help'
              }
            }
          ]
        }
      },
      'compute',
      {
        'compute' => {
          'formula' => 'macro is $m, my element is &element',
          'variables' => {
            'm' => '-  macro'
          }
        },
        'type' => 'leaf',
        'value_type' => 'string'
      },
      'var_path',
      {
        'compute' => {
          'formula' => 'get_element is $replace{$s}, indirect value is \'$v\'',
          'replace' => {
            'compute_element' => 'compute',
            'm_value_element' => 'm_value'
          },
          'variables' => {
            's' => '- $where',
            'v' => '- $replace{$s}',
            'where' => '- where_is_element'
          }
        },
        'mandatory' => '1',
        'type' => 'leaf',
        'value_type' => 'string'
      },
      'class',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'index_type' => 'string',
        'type' => 'hash'
      },
      'warped_out_ref',
      {
        'level' => 'hidden',
        'refer_to' => '- class',
        'type' => 'leaf',
        'value_type' => 'reference',
        'warp' => {
          'follow' => {
            'm' => '- macro',
            'm2' => '- macro2'
          },
          'rules' => [
            '$m eq "A" or $m2 eq "A"',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'bar',
      {
        'config_class_name' => 'MasterModel::Slave',
        'type' => 'node'
      },
      'foo',
      {
        'config_class_name' => 'MasterModel::Slave',
        'type' => 'node'
      },
      'foo2',
      {
        'config_class_name' => 'MasterModel::Slave',
        'type' => 'node'
      }
    ],
    'name' => 'MasterModel::WarpedValues'
  }
]
;

