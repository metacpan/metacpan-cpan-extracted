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
    'author' => [
      'Dominique Dumont <ddumon at cpan.org>'
    ],
    'class_description' => 'Configuration class used by L<Config::Model> to edit or 
validate ~/.ssh/config.
',
    'copyright' => [
      '2009-2013 Dominique Dumont'
    ],
    'element' => [
      'EnableSSHKeysign',
      {
        'description' => 'Setting this option to \'yes\' in the global client configuration file /etc/ssh/ssh_config enables the use of the helper program ssh-keysign(8) during HostbasedAuthentication.  See ssh-keysign(8)for more information.
',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean'
      },
      'Host',
      {
        'cargo' => {
          'config_class_name' => 'Ssh::HostElement',
          'type' => 'node'
        },
        'description' => 'The declarations make in \'parameters\' are applied only to the hosts that match one of the patterns given in pattern elements. A single \'*\' as a pattern can be used to provide global defaults for all hosts. The host is the hostname argument given on the command line (i.e. the name is not converted to a canonicalized host name before matching). Since the first obtained value for each parameter is used, more host-specific declarations should be given near the beginning of the hash (which takes order into account), and general defaults at the end.',
        'index_type' => 'string',
        'level' => 'important',
        'ordered' => '1',
        'type' => 'hash'
      },
      'IgnoreUnknown',
      {
        'description' => 'Specifies a pattern-list of unknown options to be ignored if they are encountered in configuration parsing. This may be used to suppress errors if ssh_config contains options that are unrecognised by ssh(1). It is recommended that IgnoreUnknown be listed early in the configuration file as it will not be applied to unknown options that appear before it.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'include' => [
      'Ssh::HostElement'
    ],
    'include_after' => 'Host',
    'license' => 'LGPL2',
    'name' => 'Ssh',
    'read_config' => [
      {
        'auto_create' => '1',
        'backend' => 'OpenSsh::Ssh',
        'config_dir' => '~/.ssh',
        'default_layer' => {
          'config_dir' => '/etc/ssh',
          'file' => 'ssh_config',
          'os_config_dir' => {
            'darwin' => '/etc'
          }
        },
        'file' => 'config'
      }
    ]
  }
]
;

