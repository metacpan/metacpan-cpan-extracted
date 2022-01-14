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
      'host',
      {
        'cargo' => {
          'config_class_name' => 'MasterModel::References::Host',
          'type' => 'node'
        },
        'index_type' => 'string',
        'type' => 'hash'
      },
      'lan',
      {
        'cargo' => {
          'config_class_name' => 'MasterModel::References::Lan',
          'type' => 'node'
        },
        'index_type' => 'string',
        'type' => 'hash'
      },
      'host_and_choice',
      {
        'choice' => [
          'foo',
          'bar'
        ],
        'computed_refer_to' => {
          'formula' => '- host '
        },
        'type' => 'leaf',
        'value_type' => 'reference'
      },
      'dumb_list',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'type' => 'list'
      },
      'refer_to_list_enum',
      {
        'refer_to' => '- dumb_list',
        'type' => 'leaf',
        'value_type' => 'reference'
      }
    ],
    'name' => 'MasterModel::References'
  }
]
;

