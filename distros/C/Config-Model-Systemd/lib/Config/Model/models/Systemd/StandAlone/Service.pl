#
# This file is part of Config-Model-Systemd
#
# This software is Copyright (c) 2008-2025 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
use strict;
use warnings;

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
    'element' => [
      'Service',
      {
        'config_class_name' => 'Systemd::Section::Service',
        'type' => 'node'
      },
      'Unit',
      {
        'config_class_name' => 'Systemd::Section::ServiceUnit',
        'type' => 'node'
      },
      'Install',
      {
        'config_class_name' => 'Systemd::Section::Install',
        'type' => 'node'
      }
    ],
    'generated_by' => 'parse-man.pl from systemd doc',
    'name' => 'Systemd::StandAlone::Service',
    'rw_config' => {
      'auto_create' => '1',
      'auto_delete' => '1',
      'backend' => 'Systemd::Unit'
    }
  }
]
;

