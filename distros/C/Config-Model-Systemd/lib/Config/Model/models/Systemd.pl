#
# This file is part of Config-Model-Systemd
#
# This software is Copyright (c) 2008-2022 by Dominique Dumont.
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
      'service',
      {
        'cargo' => {
          'config_class_name' => 'Systemd::Service',
          'type' => 'node'
        },
        'index_type' => 'string',
        'type' => 'hash'
      },
      'socket',
      {
        'cargo' => {
          'config_class_name' => 'Systemd::Socket',
          'type' => 'node'
        },
        'index_type' => 'string',
        'type' => 'hash'
      },
      'timer',
      {
        'cargo' => {
          'config_class_name' => 'Systemd::Timer',
          'type' => 'node'
        },
        'index_type' => 'string',
        'type' => 'hash'
      }
    ],
    'generated_by' => 'parse-man.pl from systemd doc',
    'name' => 'Systemd',
    'rw_config' => {
      'auto_create' => '1',
      'auto_delete' => '1',
      'backend' => 'Systemd'
    }
  }
]
;

