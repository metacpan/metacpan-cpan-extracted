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
  }
]
;

