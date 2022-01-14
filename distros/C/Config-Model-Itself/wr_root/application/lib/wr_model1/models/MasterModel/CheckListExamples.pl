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
      'my_hash',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'index_type' => 'string',
        'type' => 'hash'
      },
      'my_hash2',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'index_type' => 'string',
        'type' => 'hash'
      },
      'my_hash3',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'index_type' => 'string',
        'type' => 'hash'
      },
      'choice_list',
      {
        'choice' => [
          'A',
          'B',
          'C',
          'D',
          'E',
          'F',
          'G',
          'H',
          'I',
          'J',
          'K',
          'L',
          'M',
          'N',
          'O',
          'P',
          'Q',
          'R',
          'S',
          'T',
          'U',
          'V',
          'W',
          'X',
          'Y',
          'Z'
        ],
        'help' => {
          'A' => 'A help',
          'E' => 'E help'
        },
        'type' => 'check_list'
      },
      'choice_list_with_default',
      {
        'choice' => [
          'A',
          'B',
          'C',
          'D',
          'E',
          'F',
          'G',
          'H',
          'I',
          'J',
          'K',
          'L',
          'M',
          'N',
          'O',
          'P',
          'Q',
          'R',
          'S',
          'T',
          'U',
          'V',
          'W',
          'X',
          'Y',
          'Z'
        ],
        'default_list' => [
          'A',
          'D'
        ],
        'help' => {
          'A' => 'A help',
          'E' => 'E help'
        },
        'type' => 'check_list'
      },
      'choice_list_with_upstream_default_list',
      {
        'choice' => [
          'A',
          'B',
          'C',
          'D',
          'E',
          'F',
          'G',
          'H',
          'I',
          'J',
          'K',
          'L',
          'M',
          'N',
          'O',
          'P',
          'Q',
          'R',
          'S',
          'T',
          'U',
          'V',
          'W',
          'X',
          'Y',
          'Z'
        ],
        'help' => {
          'A' => 'A help',
          'E' => 'E help'
        },
        'type' => 'check_list',
        'upstream_default_list' => [
          'A',
          'D'
        ]
      },
      'macro',
      {
        'choice' => [
          'AD',
          'AH'
        ],
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'warped_choice_list',
      {
        'type' => 'check_list',
        'warp' => {
          'follow' => {
            'f1' => '- macro'
          },
          'rules' => [
            '$f1 eq \'AD\'',
            {
              'choice' => [
                'A',
                'B',
                'C',
                'D'
              ],
              'default_list' => [
                'A',
                'B'
              ]
            },
            '$f1 eq \'AH\'',
            {
              'choice' => [
                'A',
                'B',
                'C',
                'D',
                'E',
                'F',
                'G',
                'H'
              ]
            }
          ]
        }
      },
      'refer_to_list',
      {
        'refer_to' => '- my_hash',
        'type' => 'check_list'
      },
      'refer_to_2_list',
      {
        'refer_to' => '- my_hash + - my_hash2   + - my_hash3',
        'type' => 'check_list'
      },
      'refer_to_check_list_and_choice',
      {
        'choice' => [
          'A1',
          'A2',
          'A3'
        ],
        'computed_refer_to' => {
          'formula' => '- refer_to_2_list + - $var',
          'variables' => {
            'var' => '- indirection '
          }
        },
        'type' => 'check_list'
      },
      'indirection',
      {
        'type' => 'leaf',
        'value_type' => 'string'
      }
    ],
    'name' => 'MasterModel::CheckListExamples'
  }
]
;

