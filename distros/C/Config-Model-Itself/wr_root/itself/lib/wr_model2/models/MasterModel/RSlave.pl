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
      'recursive_slave',
      {
        'cargo' => {
          'config_class_name' => 'MasterModel::RSlave',
          'type' => 'node'
        },
        'index_type' => 'string',
        'type' => 'hash'
      },
      'big_compute',
      {
        'cargo' => {
          'compute' => {
            'formula' => 'macro is $m, my idx: &index, my element &element, upper element &element($up), up idx &index($up)',
            'variables' => {
              'm' => '!  macro',
              'up' => '-'
            }
          },
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'index_type' => 'string',
        'type' => 'hash'
      },
      'big_replace',
      {
        'compute' => {
          'formula' => 'trad idx $replace{&index($up)}',
          'replace' => {
            'l1' => 'level1',
            'l2' => 'level2'
          },
          'variables' => {
            'up' => '-'
          }
        },
        'type' => 'leaf',
        'value_type' => 'string'
      },
      'macro_replace',
      {
        'cargo' => {
          'compute' => {
            'formula' => 'trad macro is $replace{$m}',
            'replace' => {
              'A' => 'macroA',
              'B' => 'macroB',
              'C' => 'macroC'
            },
            'variables' => {
              'm' => '!  macro'
            }
          },
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'index_type' => 'string',
        'type' => 'hash'
      }
    ],
    'name' => 'MasterModel::RSlave'
  }
]
;

