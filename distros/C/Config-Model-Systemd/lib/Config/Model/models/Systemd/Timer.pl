#
# This file is part of Config-Model-Systemd
#
# This software is Copyright (c) 2008-2026 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
use strict;
use warnings;
use v5.20;
use utf8;

return [
  {
    'accept' => [
      '.*',
      {
        'type' => 'leaf',
        'value_type' => 'uniline',
        'warn' => 'Unexpected systemd parameter. Please contact cme author to update systemd model.'
      }
    ],
    'description' => {
      'disable' => 'When true, cme will disable a configuration file supplied by the vendor by placing place a symlink to /dev/null with the same filename as the vendor configuration file. See L<systemd-system.conf> for details.'
    },
    'element' => [
      'disable',
      {
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean'
      },
      'Timer',
      {
        'config_class_name' => 'Systemd::Section::Timer',
        'type' => 'warped_node'
      },
      'Unit',
      {
        'config_class_name' => 'Systemd::Section::TimerUnit',
        'type' => 'warped_node'
      },
      'Install',
      {
        'config_class_name' => 'Systemd::Section::Install',
        'type' => 'warped_node'
      }
    ],
    'generated_by' => 'parse-man.pl from systemd doc',
    'name' => 'Systemd::Timer',
    'rw_config' => {
      'auto_create' => '1',
      'auto_delete' => '1',
      'backend' => 'Systemd::Unit',
      'file' => '&index.timer'
    },
    'summary' => {
      'disable' => 'disable configuration file supplied by the vendor'
    },
    'warp' => {
      'Install' => {
        'follow' => {
          'disable' => '- disable'
        },
        'rules' => [
          {
            'apply' => {
              'level' => 'hidden'
            },
            'when' => '$disable'
          }
        ]
      },
      'Timer' => '*Install',
      'Unit' => '*Install'
    }
  }
]
;
