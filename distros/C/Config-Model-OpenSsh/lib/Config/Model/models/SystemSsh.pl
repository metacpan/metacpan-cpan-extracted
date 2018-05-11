#
# This file is part of Config-Model-OpenSsh
#
# This software is Copyright (c) 2008-2018 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
[
  {
    'author' => [
      'Dominique Dumont'
    ],
    'class_description' => 'Configuration class used by L<Config::Model> to edit or 
validate /etc/ssh/ssh_config (as root)
',
    'copyright' => [
      '2013 Dominique Dumont'
    ],
    'include' => [
      'Ssh'
    ],
    'license' => 'LGPL2',
    'name' => 'SystemSsh',
    'rw_config' => {
      'backend' => 'OpenSsh::Ssh',
      'config_dir' => '/etc/ssh',
      'file' => 'ssh_config',
      'os_config_dir' => {
        'darwin' => '/etc'
      }
    }
  }
]
;

