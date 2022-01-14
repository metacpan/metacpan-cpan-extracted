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
      'if',
      {
        'cargo' => {
          'config_class_name' => 'MasterModel::References::If',
          'type' => 'node'
        },
        'index_type' => 'string',
        'type' => 'hash'
      },
      'trap',
      {
        'type' => 'leaf',
        'value_type' => 'string'
      }
    ],
    'name' => 'MasterModel::References::Host'
  },
  {
    'element' => [
      'ip',
      {
        'type' => 'leaf',
        'value_type' => 'string'
      }
    ],
    'name' => 'MasterModel::References::If'
  },
  {
    'element' => [
      'node',
      {
        'cargo' => {
          'config_class_name' => 'MasterModel::References::Node',
          'type' => 'node'
        },
        'index_type' => 'string',
        'type' => 'hash'
      }
    ],
    'name' => 'MasterModel::References::Lan'
  },
  {
    'element' => [
      'host',
      {
        'refer_to' => '- host',
        'type' => 'leaf',
        'value_type' => 'reference'
      },
      'if',
      {
        'computed_refer_to' => {
          'formula' => '  - host:$h if ',
          'variables' => {
            'h' => '- host'
          }
        },
        'type' => 'leaf',
        'value_type' => 'reference'
      },
      'ip',
      {
        'compute' => {
          'formula' => '$ip',
          'variables' => {
            'card' => '- if',
            'h' => '- host',
            'ip' => '- host:$h if:$card ip'
          }
        },
        'type' => 'leaf',
        'value_type' => 'string'
      }
    ],
    'name' => 'MasterModel::References::Node'
  },
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





