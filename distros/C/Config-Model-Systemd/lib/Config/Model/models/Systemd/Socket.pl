#
# This file is part of Config-Model-Systemd
#
# This software is Copyright (c) 2015-2016 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
[
  {
    'accept' => [
      '.*',
      {
        'type' => 'leaf',
        'value_type' => 'uniline',
        'warn' => 'Unknown parameter'
      }
    ],
    'element' => [
      'Socket',
      {
        'config_class_name' => 'Systemd::Section::Socket',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'disable' => '- disable'
          },
          'rules' => [
            '$disable',
            {
              'level' => 'hidden'
            }
          ]
        }
      }
    ],
    'include' => [
      'Systemd::CommonElements'
    ],
    'name' => 'Systemd::Socket',
    'read_config' => [
      {
        'auto_create' => '1',
        'auto_delete' => '1',
        'backend' => 'Systemd::Unit',
        'file' => '&index.socket'
      }
    ]
  }
]
;

