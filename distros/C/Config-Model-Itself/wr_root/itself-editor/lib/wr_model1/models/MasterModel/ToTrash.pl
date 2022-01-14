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
      }
    ],
    'name' => 'MasterModel::ToTrash'
  }
]
;

