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
      'plain_hash',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'index_type' => 'integer',
        'type' => 'hash'
      },
      'hash_with_auto_created_id',
      {
        'auto_create_keys' => [
          'yada'
        ],
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'index_type' => 'string',
        'type' => 'hash'
      },
      'hash_with_several_auto_created_id',
      {
        'auto_create_keys' => [
          'x',
          'y',
          'z'
        ],
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'index_type' => 'string',
        'type' => 'hash'
      },
      'hash_with_default_id',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'default_keys' => [
          'yada'
        ],
        'index_type' => 'string',
        'type' => 'hash'
      },
      'hash_with_default_id_2',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'default_keys' => [
          'yada'
        ],
        'index_type' => 'string',
        'type' => 'hash'
      },
      'hash_with_several_default_keys',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'default_keys' => [
          'x',
          'y',
          'z'
        ],
        'index_type' => 'string',
        'type' => 'hash'
      },
      'hash_follower',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'follow_keys_from' => '- hash_with_several_auto_created_id',
        'index_type' => 'string',
        'type' => 'hash'
      },
      'hash_with_allow',
      {
        'allow_keys' => [
          'foo',
          'bar',
          'baz'
        ],
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'index_type' => 'string',
        'type' => 'hash'
      },
      'hash_with_allow_from',
      {
        'allow_keys_from' => '- hash_with_several_auto_created_id',
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'index_type' => 'string',
        'type' => 'hash'
      },
      'ordered_hash',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'index_type' => 'string',
        'ordered' => 1,
        'type' => 'hash'
      }
    ],
    'name' => 'MasterModel::HashIdOfValues'
  }
]
;

