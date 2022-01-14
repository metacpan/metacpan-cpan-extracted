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
      'class',
      {
        'cargo' => {
          'config_class_name' => 'Itself::Class',
          'type' => 'node'
        },
        'description' => 'A configuration model is made of several configuration classes.',
        'index_type' => 'string',
        'ordered' => 1,
        'type' => 'hash'
      },
      'application',
      {
        'cargo' => {
          'config_class_name' => 'Itself::Application',
          'type' => 'node'
        },
        'description' => 'defines the application name provided by user to cme. E.g. cme edit <application>',
        'index_type' => 'string',
        'level' => 'important',
        'type' => 'hash'
      }
    ],
    'name' => 'Itself::Model'
  }
]
;

