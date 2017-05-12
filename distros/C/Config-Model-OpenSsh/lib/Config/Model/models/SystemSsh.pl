#
# This file is part of Config-Model-OpenSsh
#
# This software is Copyright (c) 2014 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
[
  {
    'class_description' => 'Configuration class used by L<Config::Model> to edit or 
validate /etc/ssh/ssh_config (as root)
',
    'name' => 'SystemSsh',
    'include' => [
      'Ssh'
    ],
    'copyright' => [
      '2013 Dominique Dumont'
    ],
    'author' => [
      'Dominique Dumont'
    ],
    'license' => 'LGPL2',
    'read_config' => [
      {
        'backend' => 'OpenSsh::Ssh',
        'config_dir' => '/etc/ssh',
        'file' => 'ssh_config',
	'os_config_dir' => { 'darwin' => '/etc' },
      }
    ]
  }
]
;

